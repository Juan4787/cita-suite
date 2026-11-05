import { InvalidDataContractError, readArray, readBoolean, readRecord } from '$lib/contracts/json';
import { parseDepositMoney } from '$lib/scheduling/reschedule-terms';
import type { StaffManagementFeedback } from '$lib/scheduling/staff-management';
import type { CitaSupabaseClient } from '$lib/types/database';
import { logServerFailure } from '$lib/server/platform/logging';
import { ManagementResultUncertainError, managementId, managementInstant, managementRevision } from '../internal/management-contract';
import { parseWholePesoInput } from './deposit-policy-form';

const invalid = (): never => { throw new InvalidDataContractError('appointment.lateDeposit'); };
const positiveAmount = (value: unknown) => {
 const amount = parseDepositMoney(value,true);
 return amount === '0' ? invalid() : amount;
};

/** Curated computed field, selected with its appointment/revision in one snapshot.
 * SQL owns allocation and net totals; no client-side accounting reconstruction. */
export const parseStaffDepositFinancials = (value: unknown) => {
 const raw = readRecord(value,'appointment.depositFinancials');
 const latePayments = readArray(raw.late_payments,'appointment.depositFinancials.late').map(value => {
  const row = readRecord(value,'appointment.depositFinancials.late');
  return { id: managementId(row.id), amount: positiveAmount(row.amount), recordedAt: managementInstant(row.recorded_at),
   corrected: readBoolean(row.corrected,'appointment.depositFinancials.corrected') };
 });
 if (latePayments.length > 50 || new Set(latePayments.map(row => row.id)).size !== latePayments.length) return invalid();
 return { appliedAmount: parseDepositMoney(raw.applied_amount), forfeitedAmount: parseDepositMoney(raw.forfeited_amount),
  unresolvedAmount: parseDepositMoney(raw.unresolved_amount), latePayments,
  latePaymentsTruncated: readBoolean(raw.late_payments_truncated,'appointment.depositFinancials.truncated') };
};

const messages: Record<string,string> = {
 DEPOSIT_FORBIDDEN: 'Ya no tenés permiso para registrar este dinero. Revisá tu acceso al consultorio.',
 DEPOSIT_NOT_FOUND: 'Este turno ya no tiene una seña propia para este registro. Actualizá el detalle antes de seguir.',
 DEPOSIT_LATE_INVALID: 'Revisá el importe en pesos sin centavos y confirmá el registro.',
 DEPOSIT_LATE_REQUIRES_CANCELLED: 'Esta opción corresponde a un turno cancelado. Actualizá el detalle para registrar la seña que corresponda.',
 DEPOSIT_LATE_RECORD_NOT_FOUND: 'No encontramos ese registro en este turno. Actualizá el detalle antes de corregirlo.',
 DEPOSIT_LATE_ALREADY_CORRECTED: 'Ese registro ya fue corregido. Actualizá el detalle para ver el resultado.',
 APPOINTMENT_MANAGEMENT_CHANGED: 'El turno o sus importes cambiaron. Actualizá el detalle y revisalos antes de confirmar de nuevo.',
 APPOINTMENT_OPERATION_CONFLICT: 'Este intento corresponde a otra acción o a datos anteriores. Actualizá el detalle y revisá el historial.'
};
const uncertainMessage = 'No pudimos comprobar el resultado. Reintentá esta misma acción para consultar si quedó guardada.';

/** One authenticated SQL command. No mutable preflight may block recovery of a
 * committed operation; the database checks actor, identity and expected revision.
 * An unreadable accepted response retains exactly the original request. */
export const submitLateDepositAction = async (client: CitaSupabaseClient,
 input: { businessId: string; appointmentId: string }, form: FormData): Promise<StaffManagementFeedback & { invalid?: boolean }> => {
 let fields: Record<string,string> | undefined;
 let dispatched = false;
 try {
  fields = Object.fromEntries(['operation_id','expected_revision','late_action','amount','corrects_event_id','note','confirm_late_deposit'].map(name => {
   const value = form.get(name);
   if (typeof value !== 'string' || form.getAll(name).length !== 1) return invalid();
   return [name,value];
  }));
  managementId(input.businessId); managementId(input.appointmentId); managementId(fields.operation_id); managementRevision(fields.expected_revision);
  if (!['record','correct'].includes(fields.late_action) || fields.confirm_late_deposit !== 'true' || fields.note.length > 300) return invalid();
  let amount: string | null = null;
  let target: string | null = null;
  if (fields.late_action === 'record') {
   const parsed = parseWholePesoInput(fields.amount);
   if (parsed === null || !Number.isSafeInteger(parsed) || parsed < 1 || parsed > 1_000_000_000_000 || fields.corrects_event_id !== '') return invalid();
   amount = String(parsed);
  } else {
   if (fields.amount !== '') return invalid();
   target = managementId(fields.corrects_event_id);
  }
  dispatched = true;
  const { data,error } = await client.rpc('record_late_appointment_deposit', { p_business_id: input.businessId,
   p_appointment_id: input.appointmentId, p_operation_id: fields.operation_id, p_expected_revision: fields.expected_revision,
   p_action: fields.late_action, p_amount: amount, p_corrects_event_id: target, p_note: fields.note.trim() || null });
  if (error) throw error;
  let replay: boolean;
  try {
   const result = readRecord(data,'appointment.lateDeposit.result');
   managementId(result.event_id); managementRevision(result.revision); parseDepositMoney(result.unresolved_amount);
   const recorded = positiveAmount(result.amount);
   if (result.corrects_event_id !== target || (amount !== null && recorded !== amount)) return invalid();
   replay = readBoolean(result.idempotent_replay,'appointment.lateDeposit.replay');
  } catch (cause) { throw new ManagementResultUncertainError(cause); }
  return { success: true, message: replay ? 'Esta acción ya estaba guardada. Revisá los importes actuales del turno.' :
   fields.late_action === 'record' ? 'El dinero quedó registrado por resolver. El turno sigue cancelado.' :
   'Se corrigió el registro erróneo. La corrección quedó en el historial; no registra una devolución.' };
 } catch (error) {
  logServerFailure('Error registrando dinero de un turno cancelado',error);
  const raw = error instanceof Error ? error.message : typeof error === 'object' && error !== null && 'message' in error ? String(error.message) : '';
  const code = typeof error === 'object' && error !== null && 'code' in error ? String(error.code) : '';
  const rejected = !(error instanceof ManagementResultUncertainError) &&
   (error instanceof InvalidDataContractError || /^(APPOINTMENT_|DEPOSIT_)/.test(raw) || ['P0001','23P01','23503','23505','23514','42501','22P02'].includes(code));
  return { success: false, invalid: !dispatched, message: !dispatched ?
   'Revisá el importe en pesos sin centavos, la nota y la confirmación antes de registrar.' :
   rejected ? (Object.hasOwn(messages,raw) ? messages[raw] : 'No se pudo guardar este registro. Actualizá el detalle y revisá tu acceso antes de seguir.') : uncertainMessage,
   retry: fields && !rejected ? { action: 'late_deposit',fields } : undefined,
   lateDepositDraft: fields?.late_action === 'record' ? { amount: fields.amount,note: fields.note } : undefined };
 }
};
