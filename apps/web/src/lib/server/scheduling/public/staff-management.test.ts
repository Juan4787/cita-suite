import { beforeEach, describe, expect, it, vi } from 'vitest';
import { applyStaffManagementCommand, listStaffManagementSlots, loadStaffManagementSelection } from './staff-management';
import { getAvailabilitySelection } from './availability';
import { ManagementResultUncertainError } from '../internal/management-contract';
vi.mock('./availability', () => ({ getAvailabilitySelection: vi.fn() }));

const id = (n: number) => `a1000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const business = { id: id(1), timezone: 'America/Argentina/Buenos_Aires', is_active: true,
 public_booking_enabled: false, min_booking_notice_minutes: 0, max_booking_days_ahead: 365 };
const snapshot = () => ({ id: id(2), service_id: id(3), professional_id: id(4), status: 'reserved',
 starts_at: '2026-12-01T12:00:00+00:00', ends_at: '2026-12-01T12:30:00+00:00',
 appointment_management_revision: 'a'.repeat(64), appointment_professionals: [{ professional_id: id(4), position: 0 }] });
const move = () => ({ business, actorId: id(5), appointmentId: id(2), operationId: id(6),
 expectedRevision: 'a'.repeat(64), action: 'reschedule' as const, startsAt: '2026-12-02T12:00:00.000Z',
 availabilityRevision: 9, ignoreBreak: false });
const result = () => ({ appointment_id: id(2), status: 'reserved', starts_at: move().startsAt,
 ends_at: '2026-12-02T12:45:00+00:00', changed: true, revision: 'b'.repeat(64), schedule_revision: 2, idempotent_replay: false });
const reader = (data: unknown = snapshot()) => {
 const chain = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn().mockResolvedValue({ data, error: null }) };
 chain.select.mockReturnValue(chain); chain.eq.mockReturnValue(chain);
 return { from: vi.fn().mockReturnValue(chain), chain };
};
const writer = () => ({ rpc: vi.fn().mockImplementation(async (_: string, args: { p_replay_only: boolean }) =>
 ({ data: args.p_replay_only ? null : result(), error: null })) });
beforeEach(() => {
 vi.clearAllMocks();
 vi.mocked(getAvailabilitySelection).mockResolvedValue({ slots: [{ date: '2026-12-02', time: '09:00', starts_at: move().startsAt,
  ends_at: result().ends_at, professional_id: id(4), professional_name: 'Profesional' }],
  availabilityRevision: 9, configurationRevision: 3, durationMinutes: 45 });
});

describe('staff command trust and recovery boundary', () => {
 it('uses the authenticated reader and backend writer, keeping the original observed revision and selection version', async () => {
  const db = writer(), read = reader();
  await applyStaffManagementCommand(db as never, read as never, move());
  expect(read.from).toHaveBeenCalledExactlyOnceWith('appointments');
  expect(read.chain.select.mock.calls[0][0]).toContain('appointment_management_revision');
  expect(read.chain.select.mock.calls[0][0]).toContain('appointment_professionals');
  expect(db.rpc).toHaveBeenLastCalledWith('apply_staff_appointment_management', {
   p_business_id: id(1), p_actor_id: id(5), p_appointment_id: id(2), p_operation_id: id(6),
   p_expected_revision: move().expectedRevision, p_action: 'reschedule', p_starts_at: move().startsAt,
   p_ignore_break: false, p_availability_revision: 9, p_reason: null, p_replay_only: false
  });
  expect(getAvailabilitySelection).toHaveBeenCalledWith(read, expect.objectContaining({ publicOnly: false, readScope: 'internal',
   serviceId: id(3), professionalIds: [id(4)], excludeAppointmentId: id(2), ignoreBreak: false }));
 });
 it('recovers an authorized receipt before mutable availability, without another write', async () => {
  const read = reader(); const db = { rpc: vi.fn().mockResolvedValue({ data: { ...result(), idempotent_replay: true }, error: null }) };
  expect((await applyStaffManagementCommand(db as never, read as never, move())).idempotentReplay).toBe(true);
  expect(read.from).not.toHaveBeenCalled(); expect(getAvailabilitySelection).not.toHaveBeenCalled();
  expect(db.rpc).toHaveBeenCalledExactlyOnceWith('apply_staff_appointment_management', expect.objectContaining({ p_replay_only: true }));
 });
 it('does not execute after a denied or unreadable receipt', async () => {
  for (const reply of [{ data: null, error: { message: 'DEPOSIT_FORBIDDEN' } }, { data: {}, error: null }]) {
   const db = { rpc: vi.fn().mockResolvedValue(reply) }, read = reader();
   await expect(applyStaffManagementCommand(db as never, read as never, move())).rejects.toBeDefined();
   expect(db.rpc).toHaveBeenCalledTimes(1); expect(read.from).not.toHaveBeenCalled();
  }
 });
 it('rejects stale observed state without replacing it with a freshly read revision', async () => {
  const db = writer();
  await expect(applyStaffManagementCommand(db as never, reader() as never, { ...move(), expectedRevision: 'c'.repeat(64) }))
   .rejects.toThrow('APPOINTMENT_MANAGEMENT_CHANGED');
  expect(db.rpc).toHaveBeenCalledTimes(1); expect(getAvailabilitySelection).not.toHaveBeenCalled();
 });
 it('rejects a changed calculation version and a forged submillisecond slot', async () => {
  for (const input of [{ ...move(), availabilityRevision: 8 }, { ...move(), startsAt: '2026-12-02T12:00:00.000001Z' }]) {
   const db = writer();
   await expect(applyStaffManagementCommand(db as never, reader() as never, input)).rejects.toThrow();
   expect(db.rpc).toHaveBeenCalledTimes(1);
  }
 });
 it('leaves a same-instant operation to the SQL no-op without requiring new availability', async () => {
  const db = writer();
  await applyStaffManagementCommand(db as never, reader() as never, { ...move(), startsAt: '2026-12-01T09:00:00-03:00' });
  expect(getAvailabilitySelection).not.toHaveBeenCalled(); expect(db.rpc).toHaveBeenCalledTimes(2);
 });
 it('does not require booking to be enabled or mutable slot preflight to cancel', async () => {
  const db = writer(), read = reader();
  await applyStaffManagementCommand(db as never, read as never, { business, actorId: id(5), appointmentId: id(2),
   operationId: id(6), expectedRevision: 'a'.repeat(64), action: 'cancel', reason: 'Solicitado' });
  expect(read.from).not.toHaveBeenCalled(); expect(getAvailabilitySelection).not.toHaveBeenCalled();
  expect(db.rpc).toHaveBeenLastCalledWith('apply_staff_appointment_management', expect.objectContaining({ p_action: 'cancel', p_starts_at: null, p_reason: 'Solicitado' }));
 });
 it('retains the post-dispatch uncertainty category for a malformed command result', async () => {
  const db = { rpc: vi.fn().mockResolvedValueOnce({ data: null, error: null }).mockResolvedValueOnce({ data: {}, error: null }) };
  await expect(applyStaffManagementCommand(db as never, reader() as never, move())).rejects.toBeInstanceOf(ManagementResultUncertainError);
 });
 it.each([{ operationId: '' }, { expectedRevision: '' }, { actorId: 'actor' }, { ignoreBreak: 'true' }, { availabilityRevision: null },
  { action: 'cancel', startsAt: move().startsAt }])('rejects invalid input before dispatch %o', async patch => {
   const db = writer(); await expect(applyStaffManagementCommand(db as never, reader() as never, { ...move(), ...patch } as never)).rejects.toThrow();
   expect(db.rpc).not.toHaveBeenCalled();
  });
});

describe('staff coherent selection', () => {
 it.each([[], [{ professional_id: id(4), position: 0 }, { professional_id: id(4), position: 1 }]])(
  'does not silently replace an absent or corrupt team with the primary professional', async team => {
   await expect(loadStaffManagementSelection(reader({ ...snapshot(), appointment_professionals: team }) as never, id(1), id(2))).rejects.toThrow();
  });
 it('does not turn a missing revision into permission to change', async () => {
  await expect(loadStaffManagementSelection(reader({ ...snapshot(), appointment_management_revision: null }) as never, id(1), id(2))).rejects.toThrow();
 });
 it('does not offer slots for a cancelled appointment', async () => {
  const read = reader({ ...snapshot(), status: 'cancelled' });
  const selected = await loadStaffManagementSelection(read as never, id(1), id(2));
  await expect(listStaffManagementSlots(read as never, business, selected, '2026-12-02', false)).rejects.toThrow('APPOINTMENT_CANNOT_RESCHEDULE');
  expect(getAvailabilitySelection).not.toHaveBeenCalled();
 });
});
