import { InvalidDataContractError, readArray, readBoolean, readChoice, readRecord, readText } from '$lib/contracts/json';

export const EMAIL_POLICY_BOOLEAN_KEYS = ['email_enabled', 'require_email', 'show_cancel', 'show_reschedule', 'require_deposit_on_reschedule'] as const;
export type AppointmentEmailPreferences = Record<(typeof EMAIL_POLICY_BOOLEAN_KEYS)[number], boolean> & {
 previous_deposit_disposition: 'credit' | 'forfeit';
};
export const DEFAULT_APPOINTMENT_EMAIL_PREFERENCES: AppointmentEmailPreferences = {
 email_enabled: true, require_email: true, show_cancel: true, show_reschedule: true,
 require_deposit_on_reschedule: true, previous_deposit_disposition: 'forfeit'
};
/** Initial disclosure, distinct from the quote for an actual future move. */
export type BookingReschedulePolicy = {
 schema_version: 1;
 policy_revision: number;
 require_deposit_on_reschedule: boolean;
 previous_deposit_disposition: 'credit' | 'forfeit';
};
export const parseBookingReschedulePolicy = (value: unknown): BookingReschedulePolicy => {
 const row = readRecord(value, 'booking.reschedulePolicy');
 const keys = ['schema_version', 'policy_revision', 'require_deposit_on_reschedule', 'previous_deposit_disposition'];
 if (Object.keys(row).length !== keys.length || Object.keys(row).some(key => !keys.includes(key)) || row.schema_version !== 1 ||
  typeof row.policy_revision !== 'number' || !Number.isSafeInteger(row.policy_revision) || row.policy_revision < 1)
  throw new InvalidDataContractError('booking.reschedulePolicy');
 return { schema_version: 1, policy_revision: row.policy_revision,
  require_deposit_on_reschedule: readBoolean(row.require_deposit_on_reschedule, 'booking.reschedulePolicy.requireDeposit'),
  previous_deposit_disposition: readChoice(row.previous_deposit_disposition, ['credit', 'forfeit'] as const, 'booking.reschedulePolicy.disposition') };
};

export type ManualBookingReschedulePolicy = { policy: BookingReschedulePolicy; excludedServiceIds: string[] };
export const parseManualBookingReschedulePolicy = (value: unknown): ManualBookingReschedulePolicy | null => {
 if (value === null) return null;
 const row = readRecord(value, 'manualBooking.reschedulePolicy');
 return { policy: parseBookingReschedulePolicy(row.policy), excludedServiceIds: readArray(row.excludedServiceIds, 'manualBooking.excludedServices')
  .map(id => readText(id, 'manualBooking.excludedService')) };
};

export const bookingReschedulePolicyNotice = (policy: BookingReschedulePolicy): string => {
 const previous = policy.previous_deposit_disposition === 'forfeit'
  ? 'esa seña no se aplicará al nuevo turno.' : 'esa seña seguirá a cuenta del turno.';
 const next = policy.require_deposit_on_reschedule
  ? 'En ese caso se pedirá una nueva seña, salvo que las señas a cuenta ya cubran el arancel conocido.'
  : 'En ese caso no se pedirá una nueva seña por el cambio.';
 return `Si reprogramás por tu cuenta después de pagar, ${previous} ${next} Si todavía no pagaste, se mantiene una sola seña pendiente.`;
};

/** One message of an appointment as the practice sees it. No provider identifiers. */
export type AppointmentEmailDelivery = {
 id: string;
 purpose: 'booking_receipt' | 'reschedule_receipt' | 'cancellation_receipt' | 'deposit_request' | 'reminder_72h' | 'reminder_24h';
 state: 'pending' | 'sending' | 'retry' | 'accepted' | 'delivered' | 'uncertain' | 'failed' | 'bounced' | 'complained' | 'discarded';
 recipient: string | null;
 createdAt: string;
 acceptedAt: string | null;
 deliveredAt: string | null;
 discardReason: string | null;
};
