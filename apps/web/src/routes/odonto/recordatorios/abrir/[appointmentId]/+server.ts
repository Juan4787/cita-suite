// Only an explicit POST prepares a current link and records its opening.
// WhatsApp still sends nothing until the person reviews and sends its message.
import { env } from '$env/dynamic/private';
import { redirect } from '@sveltejs/kit';
import { isUuid } from '@cita-suite/shared/uuid';
import { createSupabaseServerClient } from '$lib/server/platform/supabase';
import { resolveActiveBusiness } from '$lib/server/access/public/business';
import { logServerFailure } from '$lib/server/platform/logging';
import { readBoundedBookingForm } from '$lib/server/platform/form-data';
import { normalizeArgentineWhatsAppPhone } from '$lib/utils/phone';
import { classifyUserAgent, type DeviceClass, whatsappHrefFor } from '$lib/device';
import { prepareStaffDelivery, staffDeliveryFailure } from '$lib/server/scheduling/public/staff-delivery';
import type { RequestHandler } from './$types';

const backTo = (day: string | null, notice?: string) => {
 const params = new URLSearchParams();
 if (day === 'hoy') params.set('dia', 'hoy');
 if (notice) params.set('aviso', notice);
 return '/odonto/recordatorios' + (params.size ? '?' + params : '');
};
const requestedDevice = (value: string | null): DeviceClass | null =>
 value === 'android' || value === 'ios' || value === 'desktop' || value === 'unknown' ? value : null;

// Old bookmarks and prefetches do not mint credentials or alter coverage.
export const GET: RequestHandler = ({ locals, url }) => {
 if (!locals.auth) throw redirect(303, '/login');
 throw redirect(303, backTo(url.searchParams.get('dia'), 'actualizar'));
};

export const POST: RequestHandler = async ({ params, locals, fetch, cookies, url, request }) => {
 if (!locals.auth) throw redirect(303, '/login');
 const day = url.searchParams.get('dia');
 if (env.DEMO_MODE === 'true') throw redirect(303, backTo(day));
 if (!isUuid(params.appointmentId)) throw redirect(303, backTo(day, 'cambio'));
 let revision: FormDataEntryValue | null;
 try { revision = (await readBoundedBookingForm(request, [])).get('expected_revision'); }
 catch { throw redirect(303, backTo(day, 'actualizar')); }
 if (typeof revision !== 'string' || !/^[a-f0-9]{64}$/.test(revision)) throw redirect(303, backTo(day, 'actualizar'));
 const supabase = await createSupabaseServerClient('odonto', locals.auth, fetch);
 const context = await resolveActiveBusiness({ supabase, accessToken: locals.auth.access_token, cookies });
 if (!context?.canOperate) throw redirect(303, backTo(day, 'cambio'));
 // Reuse the established phone parser before any opening is recorded. The
 // command binds this exact stored value to the locked patient snapshot.
 const { data: appointment, error } = await supabase.from('appointments')
  .select('patients!inner(phone_e164)')
  .eq('business_id', context.business.id).eq('id', params.appointmentId).maybeSingle();
 if (error) { logServerFailure('Error revisando el teléfono del recordatorio', error); throw redirect(303, backTo(day, 'error')); }
 const storedPhone = appointment?.patients?.phone_e164;
 if (!normalizeArgentineWhatsAppPhone(storedPhone)) throw redirect(303, backTo(day, 'cambio'));
 let delivery;
 try {
  delivery = await prepareStaffDelivery(supabase, { businessId: context.business.id, appointmentId: params.appointmentId,
   expectedRevision: revision, kind: 'reminder', reopen: url.searchParams.get('confirmar') === '1', expectedPhone: storedPhone });
 } catch (error) {
  const failure = staffDeliveryFailure(error);
  if (failure.status === 503) logServerFailure('Error preparando el recordatorio manual', error);
  throw redirect(303, backTo(day, failure.code === 'APPOINTMENT_REMINDER_ALREADY_OPENED' ? 'ya_abierto' : failure.status === 503 ? 'error' : 'cambio'));
 }
 const device = requestedDevice(url.searchParams.get('dispositivo')) ?? classifyUserAgent(request.headers.get('user-agent'));
 const location = whatsappHrefFor(device, delivery.whatsappUrl, delivery.whatsappWebUrl);
 if (!location) throw redirect(303, backTo(day, 'error'));
 return new Response(null, { status: 302, headers: { location, 'cache-control': 'no-store', 'referrer-policy': 'no-referrer' } });
};
