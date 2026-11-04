import { logServerFailure } from '$lib/server/platform/logging';
// Tracking honesto de acciones de calendario. La app registra que el paciente TOCÓ
// una opción ("acción de calendario registrada"), nunca certeza de guardado.
// La transición corre en la RPC record_calendar_action (un solo UPDATE atómico:
// dos clicks concurrentes no se pisan y el contador no pierde incrementos).

import type { CitaSupabaseClient } from '$lib/types/database';
import { InvalidDataContractError, readBoolean } from '$lib/contracts/json';
import type { PatientManagementAccess } from '$lib/scheduling/public-appointment';
import type { PublicAppointmentView } from '$lib/server/scheduling/public/public-appointments';

export const CALENDAR_CLICK_ACTIONS = [
	'clicked_google',
	'clicked_ics',
	'downloaded_ics',
	'clicked_outlook',
	'clicked_phone_calendar'
] as const;
export type CalendarClickAction = (typeof CALENDAR_CLICK_ACTIONS)[number];

const activeStatuses = new Set(['reserved', 'confirmed', 'reschedule_requested']);

// Solo turnos vigentes generan acciones nuevas: pasados/cancelados/cerrados no.
export const canRegisterCalendarAction = (appointment: PublicAppointmentView): boolean =>
	!appointment.is_past && activeStatuses.has(appointment.status);

export const recordCalendarAction = async (
	supabase: CitaSupabaseClient,
	access: PatientManagementAccess,
	action: CalendarClickAction,
	options: { source?: string | null } = {}
) => {
	const { data, error } = await supabase.rpc('record_patient_calendar_action', {
  p_token: access.token, p_legacy: access.legacy,
		p_action: action,
  p_source: options.source ?? null
	});
	if (error) throw error;
 if (data !== true) throw new InvalidDataContractError('calendarObservation.result');
};

// Marca "ofrecido" la primera vez que el paciente ve la pantalla con el CTA.
// Best-effort y solo desde not_offered: nunca pisa una acción real ya registrada.
export const markCalendarOffered = async (
	supabase: CitaSupabaseClient,
	access: PatientManagementAccess
) => {
	try {
  const { data, error } = await supabase.rpc('mark_patient_calendar_offered', {
   p_token: access.token, p_legacy: access.legacy
  });
  if (error) throw error;
  readBoolean(data, 'calendarObservation.offered');
	} catch (error) {
		logServerFailure('Error marcando calendario ofrecido', error);
	}
};

export const recordCalendarMetric = async (supabase: CitaSupabaseClient, access: PatientManagementAccess,
 kind: 'android_intent' | 'maps', variant: 'data' | 'type' | null = null) => {
 const { data, error } = await supabase.rpc('record_patient_calendar_metric', {
  p_token: access.token, p_legacy: access.legacy, p_kind: kind, p_variant: variant
 });
 if (error) throw error;
 if (data !== true) throw new InvalidDataContractError('calendarObservation.metric');
};
