import { error, type RequestHandler } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import { isRecord } from '$lib/contracts/json';
import { readBoundedBytes } from '$lib/server/platform/form-data';
import { logServerFailure } from '$lib/server/platform/logging';
import { loadAppointmentForManagementAccess, loadAppointmentForToken, uncachedRedirect } from '$lib/server/scheduling/public/appointment-token';
import { icsForAppointment, googleCalendarUrlFor, outlookUrlFor } from './calendar-content';
import { canRegisterCalendarAction, recordCalendarAction, recordCalendarMetric, type CalendarClickAction } from './calendar-tracking';
import { isAndroidCalendarIntentVariant } from './android-calendar-intent';
import type { PatientManagementAccess } from '$lib/scheduling/public-appointment';

const privateHeaders = { 'cache-control': 'no-store', 'referrer-policy': 'no-referrer',
 'x-content-type-options': 'nosniff', 'x-robots-tag': 'noindex, nofollow, noarchive' };
const redirect = (location: string) => {
 const response = uncachedRedirect(location);
 for (const [name, value] of Object.entries(privateHeaders)) response.headers.set(name, value);
 return response;
};
const accessFor = (legacy: boolean, token?: string): PatientManagementAccess => ({ token: token ?? '', legacy });
const baseFor = (access: PatientManagementAccess) => `/${access.legacy ? 'turno' : 'gestion'}/${encodeURIComponent(access.token)}`;
const loadCalendar = (fetchFn: typeof fetch, access: PatientManagementAccess) => access.legacy
 // Stable calendar readers keep their UID/content even after management is
 // revoked. Every observation still goes through the protected SQL command.
 ? loadAppointmentForToken(fetchFn, access.token) : loadAppointmentForManagementAccess(fetchFn, access);

export const createPatientCalendarOpening = (legacy: boolean, kind: 'inline' | 'download' | 'google' | 'outlook'): RequestHandler => async event => {
 const access = accessFor(legacy, event.params.token);
 const { appointment, supabase, demo } = await loadCalendar(event.fetch, access);
 const external = kind === 'google' || kind === 'outlook';
 if (!appointment || (external && !canRegisterCalendarAction(appointment))) {
  if (external) return redirect(baseFor(access));
  throw error(404, 'El enlace no es válido o ya no está disponible.');
 }
 const action: CalendarClickAction = kind === 'google' ? 'clicked_google' : kind === 'outlook' ? 'clicked_outlook'
  : kind === 'download' ? 'downloaded_ics' : event.url.searchParams.get('p') === 'phone' ? 'clicked_phone_calendar' : 'clicked_ics';
 if (!demo && supabase && canRegisterCalendarAction(appointment)) {
  try {
   if (kind === 'google') {
    const source = event.url.searchParams.get('source') === 'android_native_fallback' ? 'android_native_fallback' : null;
    await recordCalendarAction(supabase, access, action, { source });
   } else await recordCalendarAction(supabase, access, action);
  } catch (cause) { logServerFailure('calendar.observation_failed', cause); }
 }
 // Observation failure never prevents serving the independently authorized
 // stable calendar representation or opening an external calendar editor.
 if (kind === 'google') return redirect(googleCalendarUrlFor(appointment));
 if (kind === 'outlook') return redirect(outlookUrlFor(appointment));
 const method = appointment.status === 'cancelled' ? 'CANCEL' : 'PUBLISH';
 return new Response(icsForAppointment(appointment), { headers: { ...privateHeaders,
  'content-type': `text/calendar; charset=utf-8; method=${method}`,
  'content-disposition': `${kind === 'download' ? 'attachment' : 'inline'}; filename="turno.ics"`
 } });
};

export const createPatientMapsOpening = (legacy: boolean): RequestHandler => async event => {
 const access = accessFor(legacy, event.params.token);
 const { appointment, supabase, demo } = await loadCalendar(event.fetch, access);
 if (!appointment?.business.maps_link) return redirect(baseFor(access));
 if (!demo && supabase) {
  try { await recordCalendarMetric(supabase, access, 'maps'); }
  catch (cause) { logServerFailure('calendar.maps_metric_failed', cause); }
 }
 return redirect(appointment.business.maps_link);
};

export const createPatientCalendarIntentMetric = (legacy: boolean): RequestHandler => async event => {
 const noContent = () => new Response(null, { status: 204, headers: privateHeaders });
 if (env.DEMO_MODE === 'true') return noContent();
 try {
  const body = await readBoundedBytes(event.request, 1024);
  if (!body) return noContent();
  let variant: 'data' | 'type' | null = null;
  try {
   const raw: unknown = JSON.parse(new TextDecoder().decode(body));
   if (isRecord(raw) && typeof raw.variant === 'string' && isAndroidCalendarIntentVariant(raw.variant)) variant = raw.variant;
  } catch { /* Small unreadable beacon still represents an attempt, with no known variant. */ }
  const access = accessFor(legacy, event.params.token);
  const { appointment, supabase } = await loadCalendar(event.fetch, access);
  if (appointment && supabase && canRegisterCalendarAction(appointment)) await recordCalendarMetric(supabase, access, 'android_intent', variant);
 } catch (cause) { logServerFailure('calendar.intent_metric_failed', cause); }
 return noContent();
};
