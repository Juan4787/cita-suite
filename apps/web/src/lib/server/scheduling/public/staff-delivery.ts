import { BOOKING_MODALITIES } from '@cita-suite/shared/booking-integration';
import { isRecord, readBoolean, readChoice, readNullableText, readRecord, readText } from '$lib/contracts/json';
import { buildDepositRequestMessage, parseAppointmentDeposit } from '$lib/scheduling/deposits';
import { normalizeArgentineWhatsAppPhone } from '$lib/utils/phone';
import { resolveMapsUrl } from '$lib/sites/location';
import { buildWaMeUrl, buildWhatsAppWebUrl } from '$lib/utils/whatsapp';
import type { CitaSupabaseClient } from '$lib/types/database';
import { getPublicSiteUrl } from '$lib/server/integrations/public/messaging';
import { ManagementResultUncertainError, managementId, managementInstant, managementRevision } from '../internal/management-contract';
import { buildAppointmentActivationDelivery, buildReminderWhatsAppMessage, buildRescheduleWhatsAppMessage } from './reminders';

export const STAFF_DELIVERY_KINDS = ['activation', 'rescheduled', 'reminder', 'deposit'] as const;
export type StaffDeliveryKind = (typeof STAFF_DELIVERY_KINDS)[number];

export const staffDeliveryFailure = (cause: unknown) => {
 const code = cause instanceof Error ? cause.message : isRecord(cause) && typeof cause.message === 'string' ? cause.message : '';
 const known: Record<string, { status: number; message: string }> = {
  APPOINTMENT_MANAGEMENT_FORBIDDEN: { status: 403, message: 'Ya no tenés permiso para realizar esta acción sobre el turno. Revisá tu acceso.' },
  APPOINTMENT_NOT_FOUND: { status: 404, message: 'No encontramos ese turno en este consultorio. Actualizá la página antes de seguir.' },
  APPOINTMENT_LINK_UNAVAILABLE: { status: 409, message: 'El enlace de este turno ya no está disponible. Revisá la ficha del paciente y volvé a intentar.' },
  APPOINTMENT_MANAGEMENT_CHANGED: { status: 409, message: 'El turno o sus condiciones cambiaron. Actualizá la página y revisalo antes de seguir.' },
  APPOINTMENT_DELIVERY_CONTACT_CHANGED: { status: 409, message: 'El teléfono del paciente cambió o falta completarlo. Revisá su ficha y volvé a preparar el mensaje.' },
  APPOINTMENT_DELIVERY_UNAVAILABLE: { status: 409, message: 'Este turno ya no permite preparar ese mensaje. Actualizá la página para revisar su estado.' },
  APPOINTMENT_DELIVERY_INVALID: { status: 400, message: 'No pudimos leer esta acción. Actualizá la página y volvé a intentar.' },
  APPOINTMENT_REMINDER_ALREADY_OPENED: { status: 409, message: 'Ya se abrió un recordatorio para este turno. Revisalo antes de abrirlo otra vez.' }
 };
 return { code, ...(known[code] ?? { status: 503, message: 'No pudimos confirmar el resultado. Actualizá la página para revisar lo registrado antes de repetir la acción.' }) };
};

/** The result is a committed preparation, not evidence of an external send.
 * Parse the single SQL snapshot; never reread another recipient after minting. */
export const parseStaffDelivery = (value: unknown, appointmentId: string, kind: StaffDeliveryKind) => {
 const row = readRecord(value, 'staff.delivery');
 if (managementId(row.appointment_id) !== managementId(appointmentId)) throw new Error('APPOINTMENT_LINK_UNAVAILABLE');
 const token = managementRevision(row.token);
 const business = readRecord(row.business, 'staff.delivery.business');
 const patientName = readText(row.patient_name, 'staff.delivery.patient');
 const phone = normalizeArgentineWhatsAppPhone(readNullableText(row.phone_e164, 'staff.delivery.phone'));
 if ((kind === 'reminder' || kind === 'deposit') && !phone) throw new Error('APPOINTMENT_DELIVERY_CONTACT_CHANGED');
 const startsAt = managementInstant(row.starts_at);
 readChoice(row.status, ['reserved', 'confirmed', 'reschedule_requested'], 'staff.delivery.status');
 const modality = readChoice(row.modality, BOOKING_MODALITIES, 'staff.delivery.modality');
 const businessName = readText(business.name, 'staff.delivery.business.name');
 const timezone = readText(business.timezone, 'staff.delivery.business.timezone');
 const base = `${getPublicSiteUrl()}/gestion/${token}`;
 if (kind === 'activation') return buildAppointmentActivationDelivery(phone, token, base);
 const publicUrl = kind === 'rescheduled' ? `${base}/reprogramado` : base;
 let message: string;
 if (kind === 'rescheduled') {
  message = buildRescheduleWhatsAppMessage({ patientName, startsAt, timezone, businessName, rescheduleUrl: publicUrl });
 } else if (kind === 'reminder') {
  const address = readNullableText(business.address, 'staff.delivery.business.address');
  const mapsUrl = readNullableText(business.maps_url, 'staff.delivery.business.maps');
  message = buildReminderWhatsAppMessage({ patientName, startsAt, timezone, businessName, modality, address,
   mapsLink: resolveMapsUrl({ address, maps_url: mapsUrl }), publicUrl });
 } else {
  const deposit = parseAppointmentDeposit(row.deposit);
  if (!deposit || deposit.appointment_id !== appointmentId || deposit.status !== 'pending') throw new Error('DEPOSIT_NOT_PENDING');
  const autoCancelEnabled = readBoolean(row.deposit_auto_cancel_enabled, 'staff.delivery.autoCancel');
  message = buildDepositRequestMessage({ patientName, startsAt, timezone, businessName, publicUrl,
   amount: deposit.amount, dueAt: deposit.due_at,
   transferDetails: readNullableText(row.transfer_details, 'staff.delivery.transfer'),
   autoCancel: deposit.auto_cancel && autoCancelEnabled });
 }
 return { publicUrl, message, phoneE164: phone,
  whatsappUrl: phone ? buildWaMeUrl(phone, message) : null,
  whatsappWebUrl: phone ? buildWhatsAppWebUrl(phone, message) : null };
};

export const prepareStaffDelivery = async (client: CitaSupabaseClient, input: {
 businessId: string; appointmentId: string; expectedRevision: string; kind: StaffDeliveryKind;
 reopen?: boolean; expectedPhone?: string | null;
}) => {
 managementId(input.businessId); managementId(input.appointmentId); managementRevision(input.expectedRevision);
 readChoice(input.kind, STAFF_DELIVERY_KINDS, 'staff.delivery.kind');
 if (input.reopen !== undefined) readBoolean(input.reopen, 'staff.delivery.reopen');
 // Reuse the established phone rule. SQL compares the exact stored input under
 // its patient lock, so this successful check cannot authorize another number.
 const needsPhone = input.kind === 'reminder' || input.kind === 'deposit';
 if (needsPhone && !normalizeArgentineWhatsAppPhone(input.expectedPhone)) throw new Error('APPOINTMENT_DELIVERY_CONTACT_CHANGED');
 const { data, error } = await client.rpc('prepare_staff_appointment_delivery', {
  p_business_id: input.businessId, p_appointment_id: input.appointmentId, p_expected_revision: input.expectedRevision,
  p_kind: input.kind, p_reopen: input.reopen ?? false, p_expected_phone: input.expectedPhone ?? null
 });
 if (error) throw error;
 try { return parseStaffDelivery(data, input.appointmentId, input.kind); }
 catch (cause) { throw new ManagementResultUncertainError(cause); }
};

export const markStaffReminderSent = async (client: CitaSupabaseClient, input: {
 businessId: string; appointmentId: string; expectedRevision: string;
}) => {
 managementId(input.businessId); managementId(input.appointmentId); managementRevision(input.expectedRevision);
 const { data, error } = await client.rpc('mark_appointment_whatsapp_reminder_sent', {
  p_business_id: input.businessId, p_appointment_id: input.appointmentId, p_expected_revision: input.expectedRevision
 });
 if (error) throw error;
 try { return readBoolean(data, 'staff.delivery.markedSent'); }
 catch (cause) { throw new ManagementResultUncertainError(cause); }
};
