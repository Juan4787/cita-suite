// This prepares a human-reviewed draft, without issuing a management credential
// or recording a delivery. A single RLS read supplies the current closed turn and
// recipient. Unlike the pending-deposit command, it performs no database write.
import { env } from '$env/dynamic/private';
import { redirect } from '@sveltejs/kit';
import { isUuid } from '@cita-suite/shared/uuid';
import { createSupabaseServerClient } from '$lib/server/platform/supabase';
import { resolveActiveBusiness } from '$lib/server/access/public/business';
import { readBoundedBookingForm } from '$lib/server/platform/form-data';
import { logServerFailure } from '$lib/server/platform/logging';
import { getPublicSiteUrl } from '$lib/server/integrations/public/messaging';
import { loadRebookUrl } from '$lib/server/scheduling/public/public-appointments';
import { buildDepositCancellationMessage, parseAppointmentDeposit } from '$lib/scheduling/deposits';
import { normalizeArgentineWhatsAppPhone } from '$lib/utils/phone';
import { buildWaMeUrl, buildWhatsAppWebUrl } from '$lib/utils/whatsapp';
import { classifyUserAgent, whatsappHrefFor } from '$lib/device';
import type { RequestHandler } from './$types';

const back = (notice: string) => '/odonto/senas?aviso=' + notice;
export const GET: RequestHandler = ({ locals }) => {
 if (!locals.auth) throw redirect(303, '/login');
 throw redirect(303, back('actualizar'));
};

export const POST: RequestHandler = async ({ locals, request, params, fetch, cookies }) => {
 if (!locals.auth) throw redirect(303, '/login');
 if (env.DEMO_MODE === 'true') throw redirect(303, '/odonto/senas');
 if (!isUuid(params.appointmentId)) throw redirect(303, back('no_encontrado'));
 let form: FormData;
 try { form = await readBoundedBookingForm(request, []); }
 catch { throw redirect(303, back('actualizar')); }
 const revision = form.get('expected_revision');
 if (typeof revision !== 'string' || !/^[a-f0-9]{64}$/.test(revision)) throw redirect(303, back('actualizar'));
 const supabase = await createSupabaseServerClient('odonto', locals.auth, fetch);
 const context = await resolveActiveBusiness({ supabase, accessToken: locals.auth.access_token, cookies });
 if (!context?.canOperate || !['owner','admin','reception'].includes(context.role)) throw redirect(303, back('cambio'));
 const { data: row, error } = await supabase.from('appointment_deposits')
  .select('appointment_id,status,amount,currency,request_from,due_at,auto_cancel,waived_reason,recorded_at,reminder_opened_at,expired_at,revision,appointments!inner(status,starts_at,appointment_management_revision,patients!inner(full_name,phone_e164,blocked,archived_at),businesses!inner(name,timezone,slug))')
  .eq('business_id', context.business.id).eq('appointment_id', params.appointmentId).maybeSingle();
 if (error) { logServerFailure('Error revisando el aviso de cancelación por seña', error); throw redirect(303, back('error')); }
 if (!row) throw redirect(303, back('no_encontrado'));
 let deposit;
 try { deposit = parseAppointmentDeposit(row); }
 catch (error) { logServerFailure('Datos incompletos del aviso de cancelación', error); throw redirect(303, back('error')); }
 const appointment = row.appointments, patient = appointment.patients, business = appointment.businesses;
 if (!deposit || deposit.status !== 'expired' || appointment.status !== 'cancelled' ||
  appointment.appointment_management_revision !== revision || Date.parse(appointment.starts_at) <= Date.now() ||
  patient.blocked || patient.archived_at !== null) throw redirect(303, back('cambio'));
 const phone = normalizeArgentineWhatsAppPhone(patient.phone_e164);
 if (!phone) throw redirect(303, back('sin_telefono'));
 let bookingPath: string | null = null;
 try { bookingPath = await loadRebookUrl(supabase, { id: params.appointmentId, business: { id: context.business.id, slug: business.slug } }); }
 catch (error) { logServerFailure('Error resolviendo una nueva reserva para el aviso', error); }
 const message = buildDepositCancellationMessage({ patientName: patient.full_name, businessName: business.name,
  startsAt: appointment.starts_at, dueAt: deposit.due_at, timezone: business.timezone,
  bookingUrl: bookingPath ? getPublicSiteUrl() + bookingPath : null });
 const rawDevice = form.get('device');
 const device = rawDevice === 'desktop' || rawDevice === 'android' || rawDevice === 'ios' || rawDevice === 'unknown'
  ? rawDevice : classifyUserAgent(request.headers.get('user-agent'));
 const location = whatsappHrefFor(device, buildWaMeUrl(phone, message), buildWhatsAppWebUrl(phone, message))!;
 return new Response(null, { status: 302, headers: { location, 'cache-control': 'no-store', 'referrer-policy': 'no-referrer' } });
};
