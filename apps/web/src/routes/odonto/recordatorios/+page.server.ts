import { logServerFailure } from '$lib/server/platform/logging';
import { env } from '$env/dynamic/private';
import { error as kitError, fail, redirect } from '@sveltejs/kit';
import { createSupabaseAdminClient, createSupabaseServerClient } from '$lib/server/platform/supabase';
import { resolveActiveBusiness } from '$lib/server/access/public/business';
import { readBoundedBookingForm } from '$lib/server/platform/form-data';
import { markStaffReminderSent, staffDeliveryFailure } from '$lib/server/scheduling/public/staff-delivery';
import {
	loadReminderList,
	type ReminderDay,
	type ReminderListItem
} from '$lib/server/scheduling/public/reminders';
import { isUuid } from '@cita-suite/shared/uuid';
import type { Actions, PageServerLoad } from './$types';

const parseDay = (raw: string | null): ReminderDay => (raw === 'hoy' ? 'hoy' : 'manana');

const demoCandidates = (day: ReminderDay): ReminderListItem[] => {
	const base = new Date();
	base.setHours(15, 30, 0, 0);
	if (day === 'manana') base.setDate(base.getDate() + 1);
	const at = (hour: number) => {
		const date = new Date(base);
		date.setHours(hour, hour === 15 ? 30 : 0);
		return date.toISOString();
	};
	return [
		{
			appointment_id: 'demo-reminder-1',
			management_revision: '0'.repeat(64),
			patient_id: 'demo-patient-1',
			starts_at: at(15),
			time_label: '15:30',
			status: 'reserved',
			service_name: 'Consulta',
			professional_name: 'Dra. Jazmin Lopez',
			patient_name: 'Juan Pérez',
			coverage: 'sin_calendario',
			phone_e164: '+5493510000001',

			whatsapp_opened_at: null,
			whatsapp_marked_sent_at: null
		},
		{
			appointment_id: 'demo-reminder-2',
			management_revision: '0'.repeat(64),
			patient_id: 'demo-patient-2',
			starts_at: at(16),
			time_label: '16:00',
			status: 'confirmed',
			service_name: 'Otro servicio',
			professional_name: 'Dr. Jorge Tamara',
			patient_name: 'María Gómez',
			coverage: 'pendiente_actualizar',
			phone_e164: null,

			whatsapp_opened_at: null,
			whatsapp_marked_sent_at: null
		},
		{
			appointment_id: 'demo-reminder-3',
			management_revision: '0'.repeat(64),
			patient_id: 'demo-patient-3',
			starts_at: at(17),
			time_label: '17:00',
			status: 'confirmed',
			service_name: 'Consulta',
			professional_name: 'Dra. Jazmin Lopez',
			patient_name: 'Laura Díaz',
			coverage: 'aviso_automatico',
			phone_e164: '+5493510000003',

			whatsapp_opened_at: null,
			whatsapp_marked_sent_at: null
		}
	];
};

export const load: PageServerLoad = async ({ locals, fetch, cookies, url }) => {
	if (!locals.auth) throw redirect(303, '/login');
	const day = parseDay(url.searchParams.get('dia'));

	if (env.DEMO_MODE === 'true') {
		return {
			demo: true,
			day,
			candidates: demoCandidates(day),
			restricted: false,
			remindersUnavailable: false,
			deliveryNotice: null
		};
	}

	const supabase = await createSupabaseServerClient('odonto', locals.auth, fetch);
	const context = await resolveActiveBusiness({
		supabase,
		accessToken: locals.auth.access_token,
		cookies,
		membershipCache: locals.membershipCache ?? 'fresh'
	});
	if (!context) throw kitError(500, 'No se pudo resolver el negocio activo');
	if (context.role === 'professional') throw redirect(303, '/odonto/mis-turnos');
	if (context.role === 'readonly') throw redirect(303, '/odonto/agenda');

	// Negocio restricted/archived: la sección no opera (§65 del documento madre).
	const restricted = !context.access.canUseBusiness;
	let candidates: ReminderListItem[] = [];
	let remindersUnavailable = false;
	if (!restricted) {
		try {
			const pushSubscriptionsSupabase = await createSupabaseAdminClient('odonto', fetch);
			candidates = await loadReminderList(supabase, context.business, {
				day,
				pushSubscriptionsSupabase
			});
		} catch (reminderError) {
			// Sin poder comprobar la cobertura de notificaciones y calendarios, no
			// mostramos turnos: es preferible a abrir un WhatsApp duplicado.
			logServerFailure('Error cargando cobertura de recordatorios', reminderError);
			remindersUnavailable = true;
		}
	}

	const notices: Record<string, string> = {
		actualizar: 'Usá el botón de la lista actualizada para preparar el recordatorio.',
		ya_abierto: 'Este recordatorio ya se abrió. Revisá lo registrado antes de abrirlo otra vez.',
		cambio: 'El turno, el teléfono o los permisos cambiaron. Revisá la lista actualizada antes de seguir.',
		error: 'No pudimos confirmar la preparación del mensaje. Revisá lo registrado antes de repetir la acción.'
	};
	return { demo: false, day, candidates, restricted, remindersUnavailable, deliveryNotice: notices[url.searchParams.get('aviso') ?? ''] ?? null };
};

export const actions: Actions = {
	mark_sent: async ({ request, locals, fetch, cookies }) => {
		if (!locals.auth) throw redirect(303, '/login');
		if (env.DEMO_MODE === 'true') return fail(400, { message: 'No disponible en modo demo.' });

		const supabase = await createSupabaseServerClient('odonto', locals.auth, fetch);
		const context = await resolveActiveBusiness({
			supabase,
			accessToken: locals.auth.access_token,
			cookies
		});
		if (!context?.canOperate) {
			return fail(403, { message: 'No tenés permisos para gestionar recordatorios.' });
		}

		let form: FormData;
		try { form = await readBoundedBookingForm(request, []); }
		catch { return fail(400, { message: 'No pudimos leer la acción. Actualizá la página y volvé a intentar.' }); }
		const appointmentId = String(form.get('appointment_id') ?? '').trim();
		// Un identificador mal formado nunca llega a PostgreSQL (respondería 22P02).
		if (!isUuid(appointmentId)) return fail(404, { message: 'No encontramos ese turno.' });

		const revision = form.get('expected_revision');
		if (typeof revision !== 'string' || !/^[a-f0-9]{64}$/.test(revision)) {
			return fail(400, { message: 'Actualizá la página para revisar el turno antes de marcar el mensaje.' });
		}
		try {
			await markStaffReminderSent(supabase, { businessId: context.business.id, appointmentId, expectedRevision: revision });
			return { success: true };
		} catch (error) {
			const failure = staffDeliveryFailure(error);
			if (failure.status === 503) logServerFailure('Error registrando el envío manual del recordatorio', error);
			return fail(failure.status, { message: failure.message });
		}
	}
};
