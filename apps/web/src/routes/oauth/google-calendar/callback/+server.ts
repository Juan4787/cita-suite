import { logServerFailure } from '$lib/server/platform/logging';
import { isRecord } from '$lib/contracts/json';
import {
	authorizeGoogleCalendarAppointment,
	consumeGoogleCalendarOAuthAttempt,
	processGoogleCalendarEvent
} from '$lib/server/integrations/public/google-calendar';
import { createSupabaseAdminClient } from '$lib/server/platform/supabase';
import type { PatientManagementAccess } from '$lib/scheduling/public-appointment';
import type { RequestHandler } from './$types';

const redirectToAppointment = (access: PatientManagementAccess, status: string) =>
	new Response(null, {
		status: 303,
		headers: {
			location: `/${access.legacy ? 'turno' : 'gestion'}/${encodeURIComponent(access.token)}?calendar=${encodeURIComponent(status)}`,
			'cache-control': 'no-store',
			'referrer-policy': 'no-referrer'
		}
	});

export const GET: RequestHandler = async ({ url, fetch }) => {
	const state = url.searchParams.get('state') ?? '';
	let appointmentId: string | null = null;
	let appointmentAccess: PatientManagementAccess | null = null;
	try {
		const supabase = await createSupabaseAdminClient('odonto', fetch);
		const attempt = await consumeGoogleCalendarOAuthAttempt(supabase, state);
		appointmentId = attempt.appointmentId;
		appointmentAccess = attempt.access;

		const providerError = url.searchParams.get('error');
		if (providerError) {
			return redirectToAppointment(
				appointmentAccess,
				providerError === 'access_denied' ? 'cancelled' : 'unavailable'
			);
		}

		const code = url.searchParams.get('code') ?? '';
		const authorization = await authorizeGoogleCalendarAppointment(
			supabase,
			attempt,
			code,
			fetch
		);
		const sync = await processGoogleCalendarEvent(
			supabase,
			authorization.eventRowId,
			fetch,
			{ accessToken: authorization.accessToken }
		);
		const status =
			sync.status === 'active'
				? 'connected'
				: sync.status === 'needs_reconnect'
					? 'reconnect'
					: sync.status.startsWith('pending_')
						? 'preparing'
						: 'unavailable';
		return redirectToAppointment(appointmentAccess, status);
	} catch (error) {
		const code = error instanceof Error ? error.message : isRecord(error) ? String(error.message ?? error.code ?? 'unknown') : 'unknown';
		logServerFailure('No se pudo completar Google Calendar', {
			appointmentId,
			code: code.slice(0, 120)
		});
		if (appointmentAccess) {
			return redirectToAppointment(
				appointmentAccess,
				code.includes('REAUTH_REQUIRED') ? 'reconnect' : 'unavailable'
			);
		}
		return new Response('Este enlace ya no está disponible.', {
			status: 400,
			headers: {
				'content-type': 'text/plain; charset=utf-8',
				'cache-control': 'no-store',
				'referrer-policy': 'no-referrer'
			}
		});
	}
};
