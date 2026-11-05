import { describe, expect, it, vi } from 'vitest';
import type { CitaSupabaseClient } from '$lib/types/database';
import { parseStaffDepositFinancials, submitLateDepositAction } from './late-deposits';

const businessId = '00000000-0000-4000-8000-000000000001';
const appointmentId = '00000000-0000-4000-8000-000000000002';
const eventId = '00000000-0000-4000-8000-000000000003';
const operationId = '00000000-0000-4000-8000-000000000004';
const revision = 'a'.repeat(64);
const input = { businessId, appointmentId };
const form = (overrides: Record<string, string> = {}) => {
 const values = { operation_id: operationId, expected_revision: revision, late_action: 'record', amount: '40.000',
  corrects_event_id: '', note: 'Comprobante revisado', confirm_late_deposit: 'true', ...overrides };
 const result = new FormData();
 for (const [key,value] of Object.entries(values)) result.set(key,value);
 return result;
};
const accepted = { event_id: eventId, amount: '40000', corrects_event_id: null,
 unresolved_amount: '40000', revision: 'b'.repeat(64), idempotent_replay: false };
const setup = (reply: unknown = { data: accepted, error: null }) => {
 const rpc = vi.fn().mockResolvedValue(reply);
 return { rpc, client: { rpc } as unknown as CitaSupabaseClient };
};

describe('late deposit boundary and recovery', () => {
 it('uses the authenticated single command with canonical whole pesos and no browser actor or tenant', async () => {
  const { client,rpc } = setup();
  const posted = form(); posted.set('actor_id','another-actor'); posted.set('business_id','another-business');
  await expect(submitLateDepositAction(client,input,posted)).resolves.toMatchObject({ success: true });
  expect(rpc).toHaveBeenCalledExactlyOnceWith('record_late_appointment_deposit', { p_business_id: businessId,
   p_appointment_id: appointmentId, p_operation_id: operationId, p_expected_revision: revision,
   p_action: 'record', p_amount: '40000', p_corrects_event_id: null, p_note: 'Comprobante revisado' });
 });
 it.each(['1.5','1,5','-1','0','1e3','1000000000001',''])('rejects ambiguous/invalid amount %s before dispatch', async amount => {
  const { client,rpc } = setup();
  await expect(submitLateDepositAction(client,input,form({ amount }))).resolves.toMatchObject({ success: false, invalid: true, lateDepositDraft: { amount } });
  expect(rpc).not.toHaveBeenCalled();
 });
 const invalidFields: Record<string,string>[] = [{ confirm_late_deposit: '' }, { expected_revision: '' }, { operation_id: 'other' }, { late_action: 'refund' },
  { corrects_event_id: eventId }, { note: 'x'.repeat(301) }];
 it.each(invalidFields)('requires reviewed identity and explicit confirmation', async overrides => {
  const { client,rpc } = setup();
  await expect(submitLateDepositAction(client,input,form(overrides))).resolves.toMatchObject({ success: false, invalid: true });
  expect(rpc).not.toHaveBeenCalled();
 });
 it('corrects one recorded fact; amount comes from SQL instead of a posted correction amount', async () => {
  const { client,rpc } = setup({ data: { ...accepted, corrects_event_id: eventId }, error: null });
  await expect(submitLateDepositAction(client,input,form({ late_action: 'correct', amount: '', corrects_event_id: eventId }))).resolves.toMatchObject({ success: true });
  expect(rpc.mock.calls[0][1]).toMatchObject({ p_action: 'correct', p_amount: null, p_corrects_event_id: eventId });
 });
 it('retains the exact operation and raw fields after a lost response', async () => {
  const { client,rpc } = setup(); rpc.mockRejectedValueOnce(new TypeError('fetch failed'));
  const posted = form(); const fields = Object.fromEntries(posted);
  await expect(submitLateDepositAction(client,input,posted)).resolves.toMatchObject({ success: false, retry: { action: 'late_deposit', fields } });
 });
 it('retains correction identity after an unreadable accepted result, regardless of error prefixes', async () => {
  const { client } = setup({ data: { ...accepted, revision: null }, error: null });
  const posted = form({ late_action: 'correct', amount: '', corrects_event_id: eventId });
  await expect(submitLateDepositAction(client,input,posted)).resolves.toMatchObject({ success: false,
   retry: { action: 'late_deposit', fields: Object.fromEntries(posted) } });
 });
 it('recognizes explicit rejection without automatic retry, conserving the editable draft', async () => {
  const { client } = setup({ data: null, error: { code: 'P0001', message: 'APPOINTMENT_MANAGEMENT_CHANGED' } });
  const result = await submitLateDepositAction(client,input,form());
  expect(result).toMatchObject({ success: false, lateDepositDraft: { amount: '40.000', note: 'Comprobante revisado' } });
  expect(result.retry).toBeUndefined(); expect(result.message).not.toContain('APPOINTMENT_');
 });
 it('recovered success never claims reactivation, refund or a new confirmed appointment', async () => {
  const { client } = setup({ data: { ...accepted,idempotent_replay: true }, error: null });
  const result = await submitLateDepositAction(client,input,form());
  expect(result.success).toBe(true); expect(result.message).toContain('ya estaba guardada');
  expect(result.message).not.toMatch(/reactivad|reembols|Confirmado/);
 });
});

describe('curated staff financial snapshot', () => {
 const raw = { applied_amount: '9007199254740993', forfeited_amount: '40000', unresolved_amount: '25000',
  late_payments: [{ id: eventId, amount: '25000', recorded_at: '2026-11-05T13:00:00.123456+00:00', corrected: false }], late_payments_truncated: false };
 it('preserves accumulated exact decimal strings and only curated data', () => {
  expect(parseStaffDepositFinancials({ ...raw, private_note: 'not forwarded' })).toEqual({ appliedAmount: '9007199254740993', forfeitedAmount: '40000', unresolvedAmount: '25000',
   latePayments: [{ id: eventId, amount: '25000', recordedAt: '2026-11-05T13:00:00.123456+00:00', corrected: false }], latePaymentsTruncated: false });
 });
 it.each([null,{}, { ...raw, unresolved_amount: 25000 }, { ...raw, applied_amount: '-1' },
  { ...raw,late_payments: [{ ...raw.late_payments[0], amount: '0' }] },
  { ...raw,late_payments: [{ ...raw.late_payments[0], id: 'other' }] },
  { ...raw,late_payments: [raw.late_payments[0],raw.late_payments[0]] },
  { ...raw,late_payments_truncated: 'false' }])('rejects incomplete or impossible monetary snapshots', value => {
  expect(() => parseStaffDepositFinancials(value)).toThrow();
 });
});
