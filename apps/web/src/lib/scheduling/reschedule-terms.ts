import { InvalidDataContractError, readBoolean, readRecord } from '$lib/contracts/json';

const fail = (): never => { throw new InvalidDataContractError('appointment.financialTerms'); };
const member = <T extends string>(value: unknown, values: readonly T[]): T => {
 for (const candidate of values) if (value === candidate) return candidate;
 return fail();
};
const money = (value: unknown, bounded = false): string => {
 if (typeof value !== 'string' || value.length > 128 || !/^(?:0|[1-9]\d*)$/.test(value)) return fail();
 if (bounded && BigInt(value) > 1_000_000_000_000n) return fail();
 return value;
};
const nullableMoney = (value: unknown) => value === null ? null : money(value, true);
const integer = (value: unknown, minimum: number, maximum: number) => {
 if (value === null) return null;
 if (typeof value !== 'number' || !Number.isInteger(value) || value < minimum || value > maximum) return fail();
 return value;
};
const timestamp = (value: unknown): string | null => {
 if (value === null) return null;
 if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/.test(value)) return fail();
 const date = new Date(value);
 if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 19) !== value.slice(0, 19)) return fail();
 // Preserve the original microseconds in the returned/submitted SQL conditions.
 return value;
};

/** Validate the SQL DTO, retaining exact values. This never calculates fees,
 * allocates money, or converts an unknown quote into an accounting balance. */
export const parseRescheduleFinancialTerms = (value: unknown) => {
 const raw = readRecord(value, 'appointment.financialTerms');
 const result = {
  kind: member(raw.kind, ['none', 'unchanged', 'unavailable', 'reuse_pending', 'new_requirement']),
  unavailable_reason: raw.unavailable_reason === null ? null : member(raw.unavailable_reason,
   ['deposit_automation_paused', 'payment_unresolved', 'policy_change_pending']),
  required: readBoolean(raw.required, 'appointment.financialTerms.required'),
  amount: nullableMoney(raw.amount), base_amount: nullableMoney(raw.base_amount), currency: member(raw.currency, ['ARS']),
  previous_applicable_payment_amount: money(raw.previous_applicable_payment_amount, true),
  previous_payment_disposition: member(raw.previous_payment_disposition, ['none', 'credit', 'forfeit']),
  forfeit_amount: money(raw.forfeit_amount, true), credit_amount: money(raw.credit_amount),
  quote_amount: nullableMoney(raw.quote_amount), quote_remainder: nullableMoney(raw.quote_remainder),
  request_from: timestamp(raw.request_from), due_at: timestamp(raw.due_at),
  auto_cancel: readBoolean(raw.auto_cancel, 'appointment.financialTerms.autoCancel'),
  last_minute: readBoolean(raw.last_minute, 'appointment.financialTerms.lastMinute'),
  terms_informed: readBoolean(raw.terms_informed, 'appointment.financialTerms.informed'),
  current_deposit_status: raw.current_deposit_status === null ? null : member(raw.current_deposit_status, ['pending', 'paid', 'waived', 'expired']),
  current_deposit_amount: nullableMoney(raw.current_deposit_amount),
  current_payment_allocation: raw.current_payment_allocation === null ? null : member(raw.current_payment_allocation, ['none', 'applied', 'forfeited', 'unresolved']),
  request_days: integer(raw.request_days, 1, 60), deadline_hours: integer(raw.deadline_hours, 1, 720), min_payment_hours: integer(raw.min_payment_hours, 0, 168)
 };
 if (Object.keys(raw).length !== Object.keys(result).length || Object.keys(raw).some(key => !(key in result))) return fail();
 if (result.required !== (result.amount !== null) || (result.amount !== null &&
  (result.amount === '0' || result.base_amount === null || BigInt(result.amount) > BigInt(result.base_amount)))) return fail();
 if ((result.quote_amount === null) !== (result.quote_remainder === null)) return fail();
 if (result.kind === 'unavailable' && result.unavailable_reason === null) return fail();
 if (result.unavailable_reason !== null && result.kind !== 'unavailable' && result.kind !== 'unchanged') return fail();
 if (['none', 'unavailable'].includes(result.kind) && result.required) return fail();
 if (['new_requirement', 'reuse_pending'].includes(result.kind) && (!result.required || result.request_from === null || result.due_at === null ||
  result.request_days === null || result.deadline_hours === null || result.min_payment_hours === null)) return fail();
 if ((result.current_deposit_status === null) !== (result.current_deposit_amount === null) ||
  (result.current_deposit_status === null) !== (result.current_payment_allocation === null)) return fail();
 if (result.current_deposit_status !== null && result.current_deposit_status !== 'paid' && result.current_payment_allocation !== 'none') return fail();
 if (result.current_deposit_status === 'paid' && result.current_payment_allocation === 'none') return fail();
 if (!result.terms_informed && (result.previous_payment_disposition === 'forfeit' || result.forfeit_amount !== '0' || result.kind === 'new_requirement')) return fail();
 return result;
};
export type RescheduleFinancialTerms = ReturnType<typeof parseRescheduleFinancialTerms>;

/** BigInt keeps registered accumulated credits exact beyond Number.MAX_SAFE_INTEGER. */
export const formatDepositMoney = (amount: string): string => new Intl.NumberFormat('es-AR', {
 style: 'currency', currency: 'ARS', minimumFractionDigits: 0, maximumFractionDigits: 0
}).format(BigInt(money(amount)));
