import { fail, error, redirect } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import { getOdontoContext } from '$lib/server/odonto-context';
import { bookingInformationEnabled } from '$lib/server/booking-information';
import { bookingProfileConfig } from '$lib/server/booking-profile-config';
import { parseBookingIntakeFields } from '@turnos-saas/shared/booking-integration';
import { readBoundedBookingForm } from '$lib/server/public-booking-page';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async (event) => {
  const context = await getOdontoContext(event);
  if (!context.business.canManage && !(context.business.role === 'professional' && context.business.access.canUseBusiness)) error(403, 'Tu usuario no puede configurar las reservas.');
  if (!bookingInformationEnabled()) return { canManage: context.business.canManage, forms: [], enabled: false, profiles: [], professionals: [], services: [], baseURL: '', selectedId: '' };
  const businessId = context.business.business.id;
  let editableProfessionals: string[] | null = null;
  if (!context.business.canManage) {
    const own = await context.supabase.from('professional_users').select('professional_id').eq('business_id', businessId).eq('user_id', context.userId);
    if (own.error) error(503, 'No pudimos cargar tu perfil profesional. Volvé a intentar.');
    editableProfessionals = (own.data ?? []).map(item => item.professional_id);
  }
  const results = await Promise.all([
    context.business.canManage ? context.supabase.from('booking_integrations').select('*').eq('business_id', businessId).order('name').limit(20) : Promise.resolve({data: [], error: null}),
    context.supabase.from('professionals').select('id,name,is_public,is_active').eq('business_id', businessId).order('name'),
    context.supabase.from('services').select('id,name,is_public,is_active,duration_minutes,price_label').eq('business_id', businessId).order('name'),
    context.supabase.from('professional_booking_forms').select('professional_id,revision,fields').eq('business_id', businessId)
  ]);
  if (results.some(r => r.error)) error(503, 'No pudimos cargar la configuración. Esperá unos segundos y volvé a intentar.');
  return { canManage: context.business.canManage, forms: results[3].data ?? [], enabled: true, profiles: results[0].data ?? [], professionals: (results[1].data ?? []).filter(person => editableProfessionals === null || editableProfessionals.includes(person.id)), services: results[2].data ?? [], baseURL: env.PUBLIC_SITE_URL || event.url.origin, selectedId: event.url.searchParams.get('perfil') ?? '' };
};

export const actions: Actions = {
  save_form: async (event) => {
    if (!bookingInformationEnabled()) return fail(503, { message: 'La configuración de reservas todavía no está habilitada.' });
    const context = await getOdontoContext(event);
    try {
      const form = await readBoundedBookingForm(event.request);
      const fields = parseBookingIntakeFields(JSON.parse(String(form.get('fields') ?? '[]')));
      const { error: cause } = await context.supabase.rpc('save_professional_booking_form', {
        p_business_id: context.business.business.id, p_professional_id: String(form.get('professional_id') ?? ''),
        p_expected_revision: Number(form.get('revision')), p_fields: fields
      });
      if (cause) return fail(400, { message: cause.message.includes('BOOKING_INTEGRATION_CHANGED') ? 'Otra persona cambió estas preguntas. Recargá la página antes de guardar.' : cause.message.includes('ACCESS_DENIED') ? 'Tu usuario no puede cambiar las preguntas de esta profesional.' : 'Revisá las preguntas: cada dato del perfil debe aparecer una sola vez y edad y fecha deben ser respuestas cortas.' });
      return { formSaved: true, message: 'Las preguntas de la profesional quedaron guardadas.' };
    } catch { return fail(400, { message: 'Revisá los textos, las opciones y los límites de las preguntas antes de guardar.' }); }
  },
  save: async (event) => {
    if (!bookingInformationEnabled()) return fail(503, { message: 'La configuración de reservas todavía no está habilitada.' });
    const context = await getOdontoContext(event);
    if (!context.business.canManage) return fail(403, { message: 'Tu usuario no puede administrar los enlaces de reserva.' });
    const form = await readBoundedBookingForm(event.request);
    try {
      const config = bookingProfileConfig(form);
      const { data, error: cause } = await context.supabase.rpc('save_booking_integration', {
        p_business_id: context.business.business.id, p_integration_id: String(form.get('id') ?? '') || null,
        p_expected_revision: Number(form.get('revision')) || null, p_config: config
      });
      if (cause) {
        const message = cause.message.includes('BOOKING_CONFIG_INCOMPLETE') ? 'Antes de activar, elegí profesionales y prestaciones públicas, configurá sus horarios y habilitá la reserva del consultorio.'
          : cause.message.includes('BOOKING_INTEGRATION_CHANGED') ? 'Otro usuario actualizó este enlace. Recargá la página y revisá los cambios antes de guardar.'
          : 'No pudimos guardar el enlace. Revisá su configuración y volvé a intentar.';
        return fail(400, { message });
      }
      throw redirect(303, `?perfil=${data.id}&guardado=1`);
    } catch (cause) {
      if ((cause as any)?.status === 303) throw cause;
      return fail(400, { message: 'Revisá las preguntas y los campos del enlace antes de guardar.' });
    }
  }
};
