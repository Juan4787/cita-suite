import { logServerFailure } from '$lib/server/platform/logging';
// Vista pública mínima: muestra el detalle actual del turno autorizado
// (servicio · profesional · fecha y hora ·
// ubicación) y dos recordatorios (push / calendario). No expone acciones ni la página
// de gestión completa. Detrás del token → nunca cachear.

import { env } from '$env/dynamic/private';
import { createSupabaseAdminClient } from '$lib/server/platform/supabase';
import { demoPublicAppointment } from '$lib/server/scheduling/public/public-appointments';
import { loadPatientManagementView } from './patient-management';
import { isActiveAppointmentStatus } from '$lib/utils/appointment-visibility';
import type { RequestEvent } from '@sveltejs/kit';

export const createRescheduleNoticePage = (legacy: boolean) => async ({ params, fetch, setHeaders }: RequestEvent) => {
	setHeaders({ 'cache-control': 'no-store', 'referrer-policy': 'no-referrer', 'x-robots-tag': 'noindex, nofollow, noarchive' });

	if (env.DEMO_MODE === 'true') {
		const appointment = demoPublicAppointment(params.token ?? '');
		return { appointment, active: true, demo: true };
	}

	try {
		const supabase = await createSupabaseAdminClient('odonto', fetch);
		const appointment = (await loadPatientManagementView(supabase, { token: params.token ?? '', legacy }))?.appointment ?? null;
		const active = Boolean(
			appointment && !appointment.is_past && isActiveAppointmentStatus(appointment.status)
		);
		return { appointment, active, demo: false };
	} catch (error) {
		logServerFailure('Error cargando vista de reprogramación', error);
		return { appointment: null, active: false, demo: false };
	}
};
