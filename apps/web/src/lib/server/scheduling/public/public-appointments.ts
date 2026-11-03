import { parsePriceQuote } from '$lib/scheduling/price-contracts';
import type { CitaSupabaseClient } from '$lib/types/database';
import { BOOKING_INTEGRATION_KEY_PATTERN } from '@cita-suite/shared/booking-integration';
import { bookingContextsAvailable } from '$lib/server/sites/public/booking-integration-flags';
import { loadAppointmentBookingContext, type AppointmentBookingContext } from '$lib/server/sites/public/booking-integrations';
import { resolveMapsUrl } from '$lib/sites/location';
import {
	APPOINTMENT_STATUS_LABELS,
	isAppointmentStatus
} from '$lib/server/scheduling/public/appointments';
import {
	PUBLIC_BUSINESS_SELECT,
	canUsePublicBusiness
} from '$lib/server/scheduling/public/public-booking';
import { sanitizePublicImageUrl } from '$lib/server/sites/public/public-image';
import { normalizeArgentineWhatsAppPhone } from '$lib/utils/phone';
import { parseAppointmentDeposit } from '$lib/scheduling/deposits';

import type { PublicAppointmentView } from '$lib/scheduling/public-appointment';
export type { PublicAppointmentView } from '$lib/scheduling/public-appointment';

// Turno de muestra para DEMO_MODE: misma forma que la vista real para que páginas
// y endpoints públicos funcionen sin Supabase.
export const demoPublicAppointment = (token: string): PublicAppointmentView => ({
	id: 'demo-appointment',
	token,
	status: 'reserved',
	starts_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
	ends_at: new Date(Date.now() + 24 * 60 * 60 * 1000 + 30 * 60 * 1000).toISOString(),
	service_name_snapshot: 'Consulta',
	professional_name_snapshot: 'Dra. Pérez',
	professional_count: 1,
	is_joint: false,
	calendar_action_status: 'not_offered',
	calendar_action_at: null,
	calendar_action_count: 0,
	calendar_sequence: 0,
	calendar_update_required_at: null,
	business: {
		id: 'demo-business',
		name: 'Consultorio demo',
		slug: 'consultorio-demo',
		phone: '351 555 0101',
		address: 'Av. Demo 123',
		address_instructions: 'Timbre 2B. Presentarse 10 minutos antes.',
		maps_link: 'https://www.google.com/maps/search/?api=1&query=Av.%20Demo%20123',
		logo_url: null,
		timezone: 'America/Argentina/Cordoba',
		is_active: true,
		cancellation_policy: null,
		whatsapp_contact_phone: '+5493515550101'
	},
	patient_name: 'Paciente demo',
	deposit: null,
	deposit_transfer_details: null,
	public_status_label: 'Reservado',
	public_actions_available: true,
	can_confirm: true,
	can_cancel: true,
	can_request_reschedule: true,
	is_past: false
});

// The practice's WhatsApp is read only here, never in PUBLIC_BUSINESS_SELECT: that
// one also feeds the booking page, whose data reaches the browser even when the
// practice did not enable a public WhatsApp contact.
const appointmentSelect = `id,confirmation_token,status,starts_at,ends_at,service_name_snapshot,    price_quote_snapshot,patient_instructions_snapshot,public_reminder_description_snapshot,professional_name_snapshot,calendar_action_status,calendar_action_at,calendar_action_count,calendar_sequence,calendar_update_required_at,businesses!inner(${PUBLIC_BUSINESS_SELECT},whatsapp_phone,whatsapp_contact_enabled,deposit_policies(transfer_details)),patients(full_name),appointment_professionals(professional_id),appointment_deposits(appointment_id,status,amount,currency,request_from,due_at,auto_cancel,waived_reason,recorded_at,reminder_opened_at,expired_at,revision)` as const;

/** Where the appointment takes place: a video appointment shows its instructions, never the address. */
export const publicAppointmentPlace = (
	business: { address: string | null; address_instructions: string | null; maps_url: string | null },
	bookingContext: AppointmentBookingContext | null
) =>
	bookingContext?.modality === 'video'
		? { address: null, address_instructions: bookingContext.videoInstructions, maps_link: null }
		: {
				address: business.address ?? null,
				address_instructions: business.address_instructions ?? null,
				maps_link: resolveMapsUrl({ address: business.address ?? null, maps_url: business.maps_url ?? null })
			};

// A to-one relation as the generated types describe it: never a list.
type OneToOne<T> = T extends readonly unknown[] ? never : T;

export const loadPublicAppointmentByToken = async (
	supabase: CitaSupabaseClient,
	token: string,
	now = new Date(),
	expectedIntegrationId?: string
): Promise<PublicAppointmentView | null> => {
  // Keep each select a literal so the SDK validates both relationships. An
  // optional inner join must not be replaced by a type override or a left join.
  const table = supabase.from('appointments');
  const { data, error } = expectedIntegrationId
    ? await table.select(`${appointmentSelect},appointment_booking_contexts!inner(integration_id)`)
      .eq('confirmation_token', token).eq('appointment_booking_contexts.integration_id', expectedIntegrationId).maybeSingle()
    : await table.select(appointmentSelect).eq('confirmation_token', token).maybeSingle();

	if (error) throw error;
	if (!data) return null;
	const bookingContext = bookingContextsAvailable()
		? await loadAppointmentBookingContext(supabase, String(data.id)) : null;

	const status = String(data.status);
	if (!isAppointmentStatus(status)) return null;
	const business = data.businesses;
	const startsAt = new Date(data.starts_at);
	const isPast = startsAt <= now;
	const isBusinessActive = Boolean(business?.is_active);
	const canUsePublicTokens = isBusinessActive
		? await canUsePublicBusiness(supabase, String(business.id), business.created_at ?? null)
		: false;
	const canAct = isBusinessActive && canUsePublicTokens && !isPast;
	// With the deposit pending, paying it is what confirms the turn (plan, section 4.2). The relation
	// is one-to-one: if the generated types ever read it as a list again, this stops compiling
	// instead of reading a list as a missing deposit.
	const depositRow: OneToOne<typeof data.appointment_deposits> = data.appointment_deposits;
	const deposit = parseAppointmentDeposit(depositRow ?? null);
	const depositPending = deposit?.status === 'pending';
	const professionalCount = Math.max(
		1,
		Array.isArray(data.appointment_professionals)
			? data.appointment_professionals.length
			: 0
	);

	return {
        price_quote_snapshot:parsePriceQuote(data.price_quote_snapshot),patient_instructions_snapshot:data.patient_instructions_snapshot??null,public_reminder_description_snapshot:data.public_reminder_description_snapshot??null,
		booking_context: bookingContext,
		id: String(data.id),
		token: String(data.confirmation_token),
		status,
		starts_at: String(data.starts_at),
		ends_at: String(data.ends_at),
		service_name_snapshot: String(data.service_name_snapshot),
		professional_name_snapshot: String(data.professional_name_snapshot),
		professional_count: professionalCount,
		is_joint: professionalCount > 1,
		calendar_action_status: String(data.calendar_action_status ?? 'not_offered'),
		calendar_action_at: data.calendar_action_at ?? null,
		calendar_action_count: Number(data.calendar_action_count ?? 0),
		calendar_sequence: Number(data.calendar_sequence ?? 0),
		calendar_update_required_at: data.calendar_update_required_at ?? null,
		business: {
			id: String(business.id),
			name: String(business.name),
			slug: String(business.slug),
			phone: business.phone ?? null,
			...publicAppointmentPlace(business, bookingContext),
			logo_url: sanitizePublicImageUrl(business.logo_url),
			timezone: String(business.timezone),
			is_active: Boolean(business.is_active),
			cancellation_policy: business.cancellation_policy ?? null,
			whatsapp_contact_phone:
				business.whatsapp_contact_enabled === true ? normalizeArgentineWhatsAppPhone(business.whatsapp_phone) : null
		},
		patient_name: data.patients?.full_name ?? null,
		deposit,
		deposit_transfer_details: depositPending ? (business.deposit_policies?.transfer_details ?? null) : null,
		public_status_label: APPOINTMENT_STATUS_LABELS[status],
		public_actions_available: canUsePublicTokens,
		can_confirm: canAct && status === 'reserved' && !depositPending,
		can_cancel: canAct && (status === 'reserved' || status === 'confirmed' || status === 'reschedule_requested'),
		can_request_reschedule: canAct && (status === 'reserved' || status === 'confirmed'),
		is_past: isPast
	};
};

/**
 * Where the person can book again after the automatic cancellation (plan, section 4.9): the
 * integration they booked through while it is active, or else the practice's public page if it
 * takes bookings. Null when there is neither; the WhatsApp button stays as the way back. Only
 * asked for that cancelled turn, so a normal visit does not pay for these reads.
 */
export const loadRebookUrl = async (
	supabase: CitaSupabaseClient,
	appointment: Pick<PublicAppointmentView, 'id'> & { business: Pick<PublicAppointmentView['business'], 'id' | 'slug'> }
): Promise<string | null> => (await loadRebookUrls(supabase, appointment.business, [appointment.id])).get(appointment.id) ?? null;

/** The same rebooking destinations for a bounded page, with at most three reads in total. */
export const loadRebookUrls = async (
	supabase: CitaSupabaseClient,
	business: Pick<PublicAppointmentView['business'], 'id' | 'slug'>,
	appointmentIds: readonly string[]
): Promise<Map<string, string | null>> => {
	const ids = [...new Set(appointmentIds)];
	if (ids.length > 300) throw new Error('REBOOK_WINDOW_INVALID');
	const paths = new Map<string, string | null>(ids.map(id => [id, null]));
	if (!ids.length) return paths;
	if (bookingContextsAvailable()) {
		const { data: contexts, error: contextError } = await supabase.from('appointment_booking_contexts')
			.select('appointment_id, integration_id').eq('business_id', business.id).in('appointment_id', ids).limit(ids.length);
		if (contextError) throw contextError;
		const integrationIds = [...new Set((contexts ?? []).map(row => row.integration_id))];
		if (integrationIds.length) {
			const { data: integrations, error: integrationError } = await supabase.from('booking_integrations')
				.select('id, public_key, is_active').eq('business_id', business.id).in('id', integrationIds).limit(integrationIds.length);
			if (integrationError) throw integrationError;
			const byId = new Map((integrations ?? []).map(row => [row.id, row]));
			for (const row of contexts ?? []) {
				const integration = byId.get(row.integration_id);
				if (paths.has(row.appointment_id) && integration?.is_active === true && BOOKING_INTEGRATION_KEY_PATTERN.test(integration.public_key)) {
					paths.set(row.appointment_id, `/embed/v1/${integration.public_key}`);
				}
			}
		}
	}
	if ([...paths.values()].some(path => path === null)) {
		const { data: row, error } = await supabase.from('businesses').select('public_booking_enabled').eq('id', business.id).maybeSingle();
		if (error) throw error;
		if (row?.public_booking_enabled === true) {
			for (const [id, path] of paths) if (path === null) paths.set(id, `/reservar/${encodeURIComponent(business.slug)}`);
		}
	}
	return paths;
};

export const getPublicAppointmentMessage = (appointment: PublicAppointmentView | null) => {
	if (!appointment) return 'El enlace no es válido o ya no está disponible.';
	if (!appointment.business.is_active) return 'Este turno no admite cambios online en este momento.';
	if (!appointment.public_actions_available) {
		return 'Este enlace no está disponible en este momento. Contactá al consultorio.';
	}
	if (appointment.is_past) return 'Este turno ya no admite cambios online.';
	if (appointment.status === 'cancelled') return 'Este turno ya fue cancelado.';
	if (appointment.status === 'confirmed') return 'Tu turno está confirmado.';
	if (appointment.status === 'reschedule_requested') {
		return 'Recibimos tu pedido de reprogramación. El consultorio lo gestionará.';
	}
	return 'Tu turno está reservado.';
};

export const getPublicTokenErrorMessage = (error: unknown) => {
	const raw = `${(error as { message?: string; details?: string })?.message ?? ''} ${(error as { details?: string })?.details ?? ''}`;
	if (raw.includes('PUBLIC_TOKEN_NOT_FOUND')) return 'El enlace no es válido o ya no está disponible.';
	if (raw.includes('PUBLIC_TOKEN_BUSINESS_DISABLED')) return 'Este turno no admite cambios online en este momento.';
	if (raw.includes('PUBLIC_TOKEN_COMMERCIAL_UNAVAILABLE')) {
		return 'Este enlace no está disponible en este momento. Contactá al consultorio.';
	}
	if (raw.includes('PUBLIC_TOKEN_APPOINTMENT_PAST')) return 'Este turno ya no admite cambios online.';
	if (raw.includes('PUBLIC_TOKEN_APPOINTMENT_CLOSED')) return 'Este turno ya está cerrado.';
	// The database rule is the last guard: it answers the same if the link raced a change.
	if (raw.includes('PUBLIC_TOKEN_DEPOSIT_PENDING') || raw.includes('APPOINTMENT_DEPOSIT_PENDING')) {
		return 'Tu turno se confirma cuando el consultorio recibe la seña. Si ya la transferiste, mandales el comprobante por WhatsApp.';
	}
	if (raw.includes('PUBLIC_TOKEN_CONFIRM_DENIED')) return 'Este turno no se puede confirmar desde este enlace.';
	if (raw.includes('PUBLIC_TOKEN_CANCEL_DENIED')) return 'Este turno no se puede cancelar desde este enlace.';
	if (raw.includes('PUBLIC_TOKEN_RESCHEDULE_DENIED')) {
		return 'Este turno no puede pedir reprogramación desde este enlace.';
	}
	if (raw.includes('PUBLIC_TOKEN_ACTION_CONFLICT')) {
		return 'Este turno cambió mientras lo actualizábamos. Volvé a abrir el enlace y revisá su estado.';
	}
	return 'No pudimos actualizar este turno desde el enlace. Volvé a abrirlo y revisá su estado antes de intentar de nuevo.';
};
