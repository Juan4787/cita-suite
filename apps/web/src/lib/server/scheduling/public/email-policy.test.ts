import { describe, expect, it, vi } from 'vitest';
import { DEFAULT_APPOINTMENT_EMAIL_PREFERENCES } from '$lib/scheduling/email-policy';
import { loadAppointmentEmailPolicy, parseAppointmentEmailPolicyForm, saveAppointmentEmailPolicy } from './email-policy';

const businessId = '11111111-1111-4111-8111-111111111111';
const policy = { ...DEFAULT_APPOINTMENT_EMAIL_PREFERENCES, email_enabled: false, revision: 7, sender_verified: false };
const form = () => {
 const result = new FormData(); result.set('expected_revision', '7');
 for (const [key, value] of Object.entries(DEFAULT_APPOINTMENT_EMAIL_PREFERENCES)) if (value === true) result.set(key, 'true');
 result.set('previous_deposit_disposition', 'forfeit'); return result;
};
describe('appointment email preferences', () => {
 it('keeps required email independent from disabled sending and readiness', async () => {
  const query = { select: vi.fn().mockReturnThis(), eq: vi.fn().mockReturnThis(), single: vi.fn().mockResolvedValue({ data: policy, error: null }) };
  const from = vi.fn().mockReturnValue(query);
  expect(await loadAppointmentEmailPolicy({ from } as never, businessId)).toEqual(policy);
  expect(query.eq).toHaveBeenCalledWith('business_id', businessId);
 });
 it.each([null, { ...policy, require_email: 'false' }, { ...policy, revision: 0 }, { ...policy, sender_verified: undefined }])('rejects an incomplete policy instead of enabling or disabling preferences by fallback', async data => {
  const query = { select: () => query, eq: () => query, single: async () => ({ data, error: null }) };
  await expect(loadAppointmentEmailPolicy({ from: () => query } as never, businessId)).rejects.toBeInstanceOf(Error);
 });
 it('parses unchecked controls independently without sending sender verification or an actor', () => {
  const input = form(); input.delete('email_enabled');
  expect(parseAppointmentEmailPolicyForm(input)).toEqual({ expectedRevision: 7, settings: { ...DEFAULT_APPOINTMENT_EMAIL_PREFERENCES, email_enabled: false } });
 });
 it.each(['false', 'on', '1'])('does not reinterpret a malformed checked value: %s', value => {
  const input = form(); input.set('require_email', value);
  expect(() => parseAppointmentEmailPolicyForm(input)).toThrow();
 });
 it('rejects duplicate fields and a missing economic decision', () => {
  const input = form(); input.append('expected_revision', '8');
  expect(() => parseAppointmentEmailPolicyForm(input)).toThrow();
  input.delete('expected_revision'); input.set('expected_revision', '7'); input.delete('previous_deposit_disposition');
  expect(() => parseAppointmentEmailPolicyForm(input)).toThrow();
 });
 it('uses one authenticated SQL command and preserves its revision conflict', async () => {
  const cause = { message: 'EMAIL_POLICY_CHANGED' }; const rpc = vi.fn().mockResolvedValue({ data: null, error: cause });
  const input = parseAppointmentEmailPolicyForm(form());
  await expect(saveAppointmentEmailPolicy({ rpc } as never, businessId, input)).rejects.toBe(cause);
  expect(rpc).toHaveBeenCalledExactlyOnceWith('save_appointment_email_policy', { p_business_id: businessId, p_expected_revision: 7, p_settings: input.settings });
 });
 it.each([null, '8', 0, 1.5])('does not treat a malformed acknowledgment as a saved preference: %j', async data => {
  await expect(saveAppointmentEmailPolicy({ rpc: async () => ({ data, error: null }) } as never, businessId, parseAppointmentEmailPolicyForm(form()))).rejects.toThrow();
 });
});
