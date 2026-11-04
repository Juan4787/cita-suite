import type { PatientManagementAccess } from '$lib/scheduling/public-appointment';
import { loadPatientManagementView } from './patient-management';
// Carga del turno por token para los endpoints públicos de calendario/maps.
// En DEMO_MODE devuelve el turno de muestra sin tocar Supabase.

import { env } from '$env/dynamic/private';
import type { CitaSupabaseClient } from '$lib/types/database';
import { createSupabaseAdminClient } from '$lib/server/platform/supabase';
import {
	demoPublicAppointment,
	loadPublicAppointmentByToken,
	type PublicAppointmentView
} from '$lib/server/scheduling/public/public-appointments';

export type TokenAppointmentContext = {
	appointment: PublicAppointmentView | null;
	supabase: CitaSupabaseClient | null;
	demo: boolean;
};

export const loadAppointmentForToken = async (
	fetchFn: typeof fetch,
	token: string
): Promise<TokenAppointmentContext> => {
	if (env.DEMO_MODE === 'true') {
		return { appointment: demoPublicAppointment(token), supabase: null, demo: true };
	}
	const supabase = await createSupabaseAdminClient('odonto', fetchFn);
	const appointment = await loadPublicAppointmentByToken(supabase, token);
	return { appointment, supabase, demo: false };
};

/** Management endpoints use explicit authority, never the calendar-only lookup.
 * Missing/revoked access stays unavailable; there is no fallback to raw tokens.
 * The write RPC samples its own authority again after waits and before commit.
 */
export const loadAppointmentForManagementAccess = async (
 fetchFn: typeof fetch, access: PatientManagementAccess
): Promise<TokenAppointmentContext> => {
 if (env.DEMO_MODE === 'true') return { appointment: demoPublicAppointment(access.token), supabase: null, demo: true };
 if (!/^[a-f0-9]{64}$/.test(access.token) || typeof access.legacy !== 'boolean') {
  return { appointment: null, supabase: null, demo: false };
 }
 const supabase = await createSupabaseAdminClient('odonto', fetchFn);
 const view = await loadPatientManagementView(supabase, access);
 return { appointment: view?.appointment ?? null, supabase, demo: false };
};

// Redirect manual para poder fijar no-store: los redirects llevan el token en la URL
// y no deben quedar cacheados por CDN.
export const uncachedRedirect = (location: string) =>
	new Response(null, {
		status: 302,
		headers: { location, 'cache-control': 'no-store' }
	});
