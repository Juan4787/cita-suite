import { isUuid } from '@cita-suite/shared/uuid';
import { BOOKING_THEMES, BOOKING_INTEGRATION_KEY_PATTERN, parseBookingModalityWindows } from '@cita-suite/shared/booking-integration';
import { InvalidDataContractError, readArray, readBoolean, readNullableText, readRecord, readText } from '$lib/contracts/json';
import { parsePriceQuote } from '$lib/scheduling/price-contracts';
import { parseAppointmentDeposit } from '$lib/scheduling/deposits';
import { parseRescheduleFinancialTerms } from '$lib/scheduling/reschedule-terms';
import { isAvailabilityDate } from '$lib/availability/windows';
import { sanitizePublicImageUrl } from '$lib/server/sites/public/public-image';
import { resolveMapsUrl } from '$lib/sites/location';
import { normalizeArgentineWhatsAppPhone } from '$lib/utils/phone';
import type { CitaSupabaseClient } from '$lib/types/database';
import { APPOINTMENT_STATUS_LABELS, isAppointmentStatus } from './appointments';
import { getAvailabilitySelection } from './availability';
import type { PublicAppointmentView } from './public-appointments';

export type PatientManagementAccess = { token: string; legacy: boolean };
const invalid = (): never => { throw new InvalidDataContractError('appointment.management'); };
const uuid = (value: unknown): string => typeof value === 'string' && isUuid(value) ? value : invalid();
const counter = (value: unknown, minimum = 1): number =>
 typeof value === 'number' && Number.isSafeInteger(value) && value >= minimum ? value : invalid();
const token = (value: unknown): string => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value) ? value : invalid();
const instant = (value: unknown): string => {
 if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/.test(value) || !Number.isFinite(Date.parse(value))) return invalid();
 return value;
};
const nullableInstant = (value: unknown): string | null => value === null ? null : instant(value);
const money = (value: unknown): string => typeof value === 'string' && /^(0|[1-9]\d{0,127})$/.test(value) ? value : invalid();

/** Validate the explicit SQL projection, then construct only the patient DTO.
 * Unexpected provider/clinical/contact fields are never forwarded to the page.
 * Authority and economic calculations stay in SQL, including its sampled clock.
 */
export const parsePatientManagementView = (value: unknown) => {
 const row = readRecord(value, 'appointment.management');
 if (row.schema_version !== 1 || !isAppointmentStatus(row.status) || !['legacy', 'capability'].includes(String(row.access_kind))) return invalid();
 const business = readRecord(row.business, 'appointment.management.business');
 const financial = readRecord(row.financial_summary, 'appointment.management.financialSummary');
 const professionalIds = readArray(row.professional_ids, 'appointment.management.professionals').map(uuid);
 if (professionalIds.length > 100 || new Set(professionalIds).size !== professionalIds.length) return invalid();
 const startsAt = instant(row.starts_at), endsAt = instant(row.ends_at), now = instant(row.now);
 if (Date.parse(endsAt) <= Date.parse(startsAt)) return invalid();
 const isPast = readBoolean(row.is_past, 'appointment.management.past');
 const canCancel = readBoolean(row.can_cancel, 'appointment.management.cancel');
 const canConfirm = readBoolean(row.can_confirm, 'appointment.management.confirm');
 const canReschedule = readBoolean(row.can_reschedule, 'appointment.management.reschedule');
 const isActive = ['reserved', 'confirmed', 'reschedule_requested'].includes(row.status);
 if (isPast !== (Date.parse(startsAt) <= Date.parse(now)) || ((!isActive || isPast) && (canCancel || canConfirm || canReschedule)) ||
  (canConfirm && row.status !== 'reserved')) return invalid();
 const isBusinessActive = readBoolean(business.is_active, 'appointment.management.business.active');
 const publicBookingEnabled = readBoolean(business.public_booking_enabled, 'appointment.management.business.publicBooking');
 const durationMinutes = row.reschedule_duration_minutes === null ? null : counter(row.reschedule_duration_minutes);
 if (canReschedule && (!professionalIds.length || !isBusinessActive || !publicBookingEnabled || durationMinutes === null)) return invalid();
 if (row.modality !== 'in_person' && row.modality !== 'video') return invalid();
 const integration = row.integration === null ? null : (() => {
  const raw = readRecord(row.integration, 'appointment.management.integration');
  const theme = BOOKING_THEMES.find(candidate => candidate === raw.theme_snapshot);
  if (!theme || typeof raw.public_key !== 'string' || !BOOKING_INTEGRATION_KEY_PATTERN.test(raw.public_key) || raw.modality !== row.modality) return invalid();
  return { id: uuid(raw.id), revision: raw.revision === null ? null : counter(raw.revision),
   isActive: readBoolean(raw.is_active, 'appointment.management.integration.active'), publicKey: raw.public_key,
   theme, modality: row.modality, videoInstructions: readNullableText(raw.video_instructions_snapshot, 'appointment.management.video'),
   modalityWindows: parseBookingModalityWindows(raw.modality_windows) };
 })();
 if (row.modality === 'video' && !integration) return invalid();
 const deposit = row.deposit === null ? null : parseAppointmentDeposit(row.deposit);
 if ((row.deposit !== null && !deposit) || (canConfirm && deposit?.status === 'pending')) return invalid();
 const context = integration ? { theme: integration.theme, modality: integration.modality, videoInstructions: integration.videoInstructions } : null;
 const appointment: PublicAppointmentView = {
  id: uuid(row.id), token: token(row.calendar_token), status: row.status, starts_at: startsAt, ends_at: endsAt,
  service_name_snapshot: readText(row.service_name_snapshot, 'appointment.management.service'),
  professional_name_snapshot: readText(row.professional_name_snapshot, 'appointment.management.professional'),
  professional_count: Math.max(1, professionalIds.length), is_joint: professionalIds.length > 1,
  calendar_action_status: readText(row.calendar_action_status, 'appointment.management.calendarStatus'),
  calendar_action_at: nullableInstant(row.calendar_action_at), calendar_action_count: counter(row.calendar_action_count, 0),
  calendar_sequence: counter(row.calendar_sequence, 0), calendar_update_required_at: nullableInstant(row.calendar_update_required_at),
  patient_name: readNullableText(row.patient_name, 'appointment.management.patientName'), booking_context: context,
  patient_instructions_snapshot: readNullableText(row.patient_instructions_snapshot, 'appointment.management.instructions'),
  public_reminder_description_snapshot: readNullableText(row.public_reminder_description_snapshot, 'appointment.management.reminderDescription'),
  price_quote_snapshot: parsePriceQuote(row.price_quote_snapshot), deposit,
  deposit_transfer_details: isActive && !isPast && deposit?.status === 'pending' ? readNullableText(row.deposit_transfer_details, 'appointment.management.transfer') : null,
  public_status_label: APPOINTMENT_STATUS_LABELS[row.status], public_actions_available: true,
  can_cancel: canCancel, can_confirm: canConfirm, can_request_reschedule: canReschedule, is_past: isPast,
  business: {
   id: uuid(business.id), name: readText(business.name, 'appointment.management.business.name'), slug: readText(business.slug, 'appointment.management.business.slug'),
   timezone: readText(business.timezone, 'appointment.management.timezone'), is_active: isBusinessActive,
   phone: readNullableText(business.phone, 'appointment.management.phone'), logo_url: sanitizePublicImageUrl(business.logo_url),
   address: row.modality === 'video' ? null : readNullableText(business.address, 'appointment.management.address'),
   address_instructions: row.modality === 'video' ? integration?.videoInstructions ?? null : readNullableText(business.address_instructions, 'appointment.management.placeInstructions'),
   maps_link: row.modality === 'video' ? null : resolveMapsUrl({ address: readNullableText(business.address, 'appointment.management.address'), maps_url: readNullableText(business.maps_url, 'appointment.management.maps') }),
   cancellation_policy: readNullableText(business.cancellation_policy, 'appointment.management.cancellationPolicy'),
   whatsapp_contact_phone: normalizeArgentineWhatsAppPhone(readNullableText(business.whatsapp_contact_phone, 'appointment.management.whatsapp'))
  }
 };
 return {
  appointment, revision: token(row.revision), generation: counter(row.generation), scheduleRevision: counter(row.schedule_revision),
  accessKind: row.access_kind === 'legacy' ? 'legacy' as const : 'capability' as const, now,
  serviceId: row.service_id === null ? null : uuid(row.service_id), professionalIds, durationMinutes, integration,
  newBookingAllowed: readBoolean(row.new_booking_allowed, 'appointment.management.newBooking'),
  rescheduleUnavailableReason: readNullableText(row.reschedule_unavailable_reason, 'appointment.management.reason'),
  financialTerms: row.financial_terms === null ? null : parseRescheduleFinancialTerms(row.financial_terms),
  financialSummary: { appliedAmount: money(financial.applied_amount), forfeitedAmount: money(financial.forfeited_amount), unresolvedAmount: money(financial.unresolved_amount) }
 };
};
export type PatientManagementView = ReturnType<typeof parsePatientManagementView>;

export const loadPatientManagementView = async (client: CitaSupabaseClient, access: PatientManagementAccess, startsAt: string | null = null): Promise<PatientManagementView | null> => {
 token(access.token);
 if (typeof access.legacy !== 'boolean') return invalid();
 if (startsAt !== null) instant(startsAt);
 const { data, error } = await client.rpc('get_patient_appointment_management_view', { p_token: access.token, p_legacy: access.legacy, p_starts_at: startsAt });
 if (error?.message === 'APPOINTMENT_LINK_UNAVAILABLE') return null;
 if (error) throw error;
 const view = parsePatientManagementView(data);
 if (view.accessKind !== (access.legacy ? 'legacy' : 'capability')) return invalid();
 return view;
};

/** No patient-controlled tenant, excluded appointment, team, service or modality. */
export const listPatientManagementSlots = async (client: CitaSupabaseClient, view: PatientManagementView, fromDate: string, toDate: string) => {
 if (!view.appointment.can_request_reschedule || !view.serviceId) throw new Error('APPOINTMENT_RESCHEDULE_UNAVAILABLE');
 if (!isAvailabilityDate(fromDate) || !isAvailabilityDate(toDate) || fromDate > toDate ||
  Date.parse(toDate) - Date.parse(fromDate) > 13 * 86400000) throw new Error('APPOINTMENT_RESCHEDULE_TIME_INVALID');
 const selection = await getAvailabilitySelection(client, {
  business: { id: view.appointment.business.id, is_active: true, public_booking_enabled: true,
   timezone: view.appointment.business.timezone, min_booking_notice_minutes: 0, max_booking_days_ahead: 365 },
  readScope: 'public', publicOnly: true, serviceId: view.serviceId, professionalIds: view.professionalIds,
  excludeAppointmentId: view.appointment.id, ignoreBreak: false, fromDate, toDate,
  modality: view.appointment.booking_context?.modality ?? 'in_person', modalityWindows: view.integration?.modalityWindows,
  maxSlots: 1500, maxSlotsPerDate: 150
 });
 if (selection.availabilityRevision === null || selection.durationMinutes !== view.durationMinutes) throw new Error('APPOINTMENT_AVAILABILITY_CHANGED');
 return selection;
};
