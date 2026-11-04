import { beforeEach, describe, expect, it, vi } from 'vitest';
import { submitStaffManagementAction } from './staff-management-flow';
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
const id = (n: number) => `a1000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const fields = { operation_id: id(6), expected_revision: 'a'.repeat(64), status: 'cancelled', reason: 'Solicitado', confirm_cancel: 'true' };
const form = (patch: Record<string, string> = {}) => {
 const result = new FormData(); for (const [key,value] of Object.entries({ ...fields, ...patch })) result.set(key,value); return result;
};
const result = () => ({ appointment_id: id(2), status: 'cancelled', starts_at: '2026-12-01T12:00:00+00:00',
 ends_at: '2026-12-01T12:30:00+00:00', changed: true, revision: 'b'.repeat(64), schedule_revision: 2, idempotent_replay: false });
const rpc = vi.fn();
const input = { writer: { rpc } as never, business: { id: id(1), timezone: 'America/Argentina/Buenos_Aires',
 is_active: true, public_booking_enabled: false, min_booking_notice_minutes: 0, max_booking_days_ahead: 365 },
 appointmentId: id(2), userId: id(5) };
const reader = { from: vi.fn() };
beforeEach(() => { vi.clearAllMocks(); rpc.mockImplementation(async (_: string, args: { p_replay_only: boolean }) =>
 ({ data: args.p_replay_only ? null : result(), error: null })); });
describe('staff original form and outcome', () => {
 it('dispatches the verified actor rather than any form actor and requires explicit cancellation', async () => {
  const accepted = form({ actor_id: id(9) });
  expect((await submitStaffManagementAction(reader as never,input,'update_status',accepted)).success).toBe(true);
  expect(rpc).toHaveBeenLastCalledWith('apply_staff_appointment_management', expect.objectContaining({ p_actor_id: id(5), p_operation_id: id(6) }));
  rpc.mockClear();
  expect(await submitStaffManagementAction(reader as never,input,'update_status',form({ confirm_cancel: 'false' })))
   .toMatchObject({ success: false, retry: undefined });
  expect(rpc).not.toHaveBeenCalled();
 });
 it('preserves the exact original payload after a lost command response, then recovers it once', async () => {
  rpc.mockResolvedValueOnce({ data: null,error: null }).mockRejectedValueOnce(new TypeError('fetch failed'));
  const uncertain = await submitStaffManagementAction(reader as never,input,'update_status',form());
  expect(uncertain).toMatchObject({ success: false, retry: { action: 'update_status', fields } });
  expect(uncertain.message).not.toMatch(/no se guardó|fetch|SQL|RPC/);
  rpc.mockResolvedValueOnce({ data: { ...result(), idempotent_replay: true },error: null });
  const recovered = await submitStaffManagementAction(reader as never,input,'update_status',form(uncertain.retry!.fields));
  expect(recovered.result?.idempotentReplay).toBe(true); expect(rpc).toHaveBeenCalledTimes(3);
  expect(reader.from).not.toHaveBeenCalled();
 });
 it.each(['receipt','command'])('treats an unreadable %s reply as uncertain, without inventing rollback', async kind => {
  if (kind==='command') rpc.mockResolvedValueOnce({ data: null,error: null });
  rpc.mockResolvedValueOnce({ data: { appointment_id: id(2) },error: null });
  expect(await submitStaffManagementAction(reader as never,input,'update_status',form()))
   .toMatchObject({ success: false, retry: { fields } });
 });
 it.each(['APPOINTMENT_MANAGEMENT_CHANGED','DEPOSIT_FORBIDDEN','APPOINTMENT_OPERATION_CONFLICT'])('does not misclassify explicit %s as a lost response', async message => {
  rpc.mockResolvedValueOnce({ data: null,error: { message } });
  const rejected = await submitStaffManagementAction(reader as never,input,'update_status',form());
  expect(rejected).toMatchObject({ success: false, retry: undefined });
  expect(rejected.message).not.toContain(message);
 });
 it('rejects a generic confirmation, missing identity, or missing observed revision before dispatch', async () => {
  for (const patch of [{ status: 'confirmed' },{ operation_id: '' },{ expected_revision: '' }]) {
   expect(await submitStaffManagementAction(reader as never,input,'update_status',form(patch))).toMatchObject({ success: false,retry: undefined });
  }
  expect(rpc).not.toHaveBeenCalled();
 });
});
