import { APPOINTMENT_STATUSES } from '@cita-suite/shared/appointment-status';
import { isUuid } from '@cita-suite/shared/uuid';
import { isAvailabilityDate } from '$lib/availability/windows';
import { InvalidDataContractError, readBoolean, readChoice, readRecord } from '$lib/contracts/json';

const invalid = (): never => { throw new InvalidDataContractError('appointment.management'); };
export const managementId = (value: unknown): string => typeof value === 'string' && isUuid(value) ? value : invalid();
export const managementRevision = (value: unknown): string =>
 typeof value === 'string' && /^[a-f0-9]{64}$/.test(value) ? value : invalid();
export const managementCounter = (value: unknown, minimum = 1): number =>
 typeof value === 'number' && Number.isSafeInteger(value) && value >= minimum ? value : invalid();
export const managementInstant = (value: unknown): string => {
 if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/.test(value) ||
  !isAvailabilityDate(value.slice(0, 10)) || !Number.isFinite(Date.parse(value))) return invalid();
 return value;
};
export const managementEpochMicroseconds = (value: string): bigint => {
 managementInstant(value);
 const fraction = /\.(\d+)(?:Z|[+-]\d{2}:\d{2})$/.exec(value)?.[1] ?? '';
 return BigInt(Date.parse(value)) * 1000n + BigInt(fraction.padEnd(6, '0').slice(3));
};
export const sameManagementInstant = (left: string, right: string): boolean =>
 managementEpochMicroseconds(left) === managementEpochMicroseconds(right);

/** An unreadable reply after command dispatch/recovery cannot prove rollback.
 * Keep this category explicit, independently of message prefixes or its cause. */
export class ManagementResultUncertainError extends Error {
 constructor(cause: unknown) { super('MANAGEMENT_RESULT_UNCERTAIN', { cause }); }
}

export const parseManagementResult = (value: unknown) => {
 try {
  const row = readRecord(value, 'appointment.management.result');
  return {
   appointmentId: managementId(row.appointment_id),
   status: readChoice(row.status, APPOINTMENT_STATUSES, 'appointment.management.result.status'),
   startsAt: managementInstant(row.starts_at), endsAt: managementInstant(row.ends_at),
   revision: managementRevision(row.revision), scheduleRevision: managementCounter(row.schedule_revision),
   changed: readBoolean(row.changed, 'appointment.management.result.changed'),
   idempotentReplay: readBoolean(row.idempotent_replay, 'appointment.management.result.replay')
  };
 } catch (cause) { throw new ManagementResultUncertainError(cause); }
};
export type ManagementResult = ReturnType<typeof parseManagementResult>;
