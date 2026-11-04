import type { RequestHandler } from '@sveltejs/kit';
import { createGoogleCalendarAuthorizationUrl } from './google-calendar';
import { loadAppointmentForManagementAccess } from '$lib/server/scheduling/public/appointment-token';
import { hashRateLimitSubject } from '$lib/server/platform/rate-limits';
import { logServerFailure } from '$lib/server/platform/logging';
import type { PatientManagementAccess } from '$lib/scheduling/public-appointment';

const privateHeaders = {
 'cache-control': 'no-store', 'referrer-policy': 'no-referrer',
 'x-content-type-options': 'nosniff', 'x-robots-tag': 'noindex, nofollow, noarchive'
};

/** The route owns the channel. Query/body input cannot turn a stable calendar
 * identity into management authority; SQL decides scope again at nonce creation.
 */
export const createPatientGoogleCalendarConnect = (legacy: boolean): RequestHandler => async event => {
 const access: PatientManagementAccess = {token:event.params.token ?? '', legacy};
 const returnPath = `/${legacy ? 'turno' : 'gestion'}/${encodeURIComponent(access.token)}?calendar=unavailable`;
 try {
  const {appointment,supabase,demo} = await loadAppointmentForManagementAccess(event.fetch,access);
  if (!demo && appointment && supabase && !appointment.is_past) {
   const {data:allowed,error} = await supabase.rpc('consume_booking_integration_read_limit', {
    p_subject_hash:hashRateLimitSubject(event.getClientAddress())
   });
   if (error) throw error;
   if (allowed === true) {
    const location = await createGoogleCalendarAuthorizationUrl(supabase,access,{
     forceConsent:event.url.searchParams.get('reauthorize') === '1'
    });
    return new Response(null,{status:303,headers:{...privateHeaders,location}});
   }
  }
 } catch(cause) {
  logServerFailure('google_calendar.authorization_begin_failed',cause);
 }
 return new Response(null,{status:303,headers:{...privateHeaders,location:returnPath}});
};
