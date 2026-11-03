import type { AppointmentStatus } from '@cita-suite/shared/appointment-status';
import type { BookingTheme, BookingModality } from '@cita-suite/shared/booking-integration';
import type { AppointmentDepositView } from './deposits';
import type { PriceQuote } from '$lib/booking/pricing';

export type PublicAppointmentView = {
	booking_context?: { theme: BookingTheme; modality: BookingModality; videoInstructions: string | null } | null;
	price_quote_snapshot?: PriceQuote | null;
	patient_instructions_snapshot?: string | null;
	public_reminder_description_snapshot?: string | null;
	id: string;
	token: string;
	status: AppointmentStatus;
	starts_at: string;
	ends_at: string;
	service_name_snapshot: string;
	professional_name_snapshot: string;
	professional_count: number;
	is_joint: boolean;
	calendar_action_status: string;
	calendar_action_at: string | null;
	calendar_action_count: number;
	calendar_sequence: number;
	calendar_update_required_at: string | null;
	business: {
		id: string;
		name: string;
		slug: string;
		phone: string | null;
		address: string | null;
		address_instructions: string | null;
		maps_link: string | null;
		logo_url: string | null;
		timezone: string;
		is_active: boolean;
		cancellation_policy: string | null;
		/** WhatsApp público del consultorio, normalizado; null si no lo habilitó o no se puede abrir. */
		whatsapp_contact_phone: string | null;
	};
	patient_name: string | null;
	/** The turn's deposit, or null when it asks for none (señas y avisos, stage B). */
	deposit: AppointmentDepositView | null;
	/** How to transfer, only while the deposit is pending. */
	deposit_transfer_details: string | null;
	public_status_label: string;
	public_actions_available: boolean;
	can_confirm: boolean;
	can_cancel: boolean;
	can_request_reschedule: boolean;
	is_past: boolean;
};

