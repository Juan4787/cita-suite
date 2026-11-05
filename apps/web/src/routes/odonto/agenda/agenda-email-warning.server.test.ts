import { beforeEach, describe, expect, it, vi } from 'vitest';
const mocks = vi.hoisted(() => ({ context: vi.fn(), admin: vi.fn(), replay: vi.fn(), slots: vi.fn(), create: vi.fn() }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
vi.mock('$lib/server/access/public/odonto-context', () => ({ getOdontoContext: mocks.context }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseAdminClient: mocks.admin }));
vi.mock('$lib/server/scheduling/public/availability', async original => ({
 ...(await original<typeof import('$lib/server/scheduling/public/availability')>()), getAvailabilitySlots: mocks.slots
}));
vi.mock('$lib/server/scheduling/public/appointments', async original => ({
 ...(await original<typeof import('$lib/server/scheduling/public/appointments')>()), findAppointmentCreationReplay: mocks.replay,
 createManualAppointment: mocks.create, createJointAppointment: mocks.create
}));
import { actions } from './+page.server';
const patientId = '11111111-1111-4111-8111-111111111111', key = '22222222-2222-4222-8222-222222222222';
const event = (extra: Record<string, string> = {}) => ({ locals: { auth: { access_token: 'synthetic' } }, fetch: vi.fn(), cookies: {},
 request: new Request('http://localhost/odonto/agenda?/create_appointment', { method: 'POST', body: new URLSearchParams({
  service_id: '33333333-3333-4333-8333-333333333333', professional_id: '44444444-4444-4444-8444-444444444444',
  date: '2026-12-01', time: '09:00', patient_id: patientId, patient_mode: 'existing', patient_name: '',
  patient_phone: '', patient_email: '', idempotency_key: key, ...extra
 }) }) } as never);
let email: string | null;
beforeEach(() => {
 vi.clearAllMocks(); email = null;
 mocks.context.mockResolvedValue({ supabase: {}, business: { canOperate: true, business: { id: 'business', timezone: 'UTC' } }, userId: 'operator' });
 const query = { select: () => query, eq: () => query, maybeSingle: async () => ({ data: { id: patientId, email, phone_raw: '3425048209', phone_e164: '+5493425048209', blocked: false, archived_at: null }, error: null }) };
 mocks.admin.mockResolvedValue({ from: () => query }); mocks.replay.mockResolvedValue(null); mocks.slots.mockResolvedValue([]);
});
describe('reception email warning uses saved contact and preserves the creation attempt', () => {
 it('transports only an expressly attested financial summary after the replay check', async () => {
  email = 'Saved+Contact@Example.test';
  const policy = { schema_version: 1, policy_revision: 7, require_deposit_on_reschedule: true, previous_deposit_disposition: 'forfeit' };
  mocks.slots.mockResolvedValueOnce([{ starts_at: '2026-12-01T09:00:00.000Z', professional_id: '44444444-4444-4444-8444-444444444444' }]);
  mocks.create.mockResolvedValueOnce({ id: '55555555-5555-4555-8555-555555555555' });
  await expect(actions.create_appointment(event({ reschedule_policy_acknowledged: 'true', reschedule_policy_terms: JSON.stringify(policy) }))).rejects.toMatchObject({ status: 303 });
  expect(mocks.create).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ reschedulePolicyTerms: policy, idempotencyKey: key, createdByUserId: 'operator' }));
 });
 it('does not revalidate an old disclosure when recovering a completed creation', async () => {
  mocks.replay.mockResolvedValueOnce({ id: '55555555-5555-4555-8555-555555555555' });
  await expect(actions.create_appointment(event({ reschedule_policy_acknowledged: 'true', reschedule_policy_terms: '{broken' }))).rejects.toMatchObject({ status: 303 });
  expect(mocks.slots).not.toHaveBeenCalled(); expect(mocks.create).not.toHaveBeenCalled();
 });
 it('keeps malformed declared rules as a known failure before availability or writes', async () => {
  email = 'Saved+Contact@Example.test';
  const result = await actions.create_appointment(event({ reschedule_policy_acknowledged: 'true', reschedule_policy_terms: '{broken' }));
  expect(result).toMatchObject({ status: 400, data: { values: { idempotency_key: key }, message: expect.stringContaining('No pudimos leer las condiciones informadas') } });
  expect(mocks.slots).not.toHaveBeenCalled(); expect(mocks.create).not.toHaveBeenCalled();
 });
 it('warns before creation for an existing patient without email, regardless of a forged hidden address', async () => {
  const result = await actions.create_appointment(event({ patient_email: 'not-the-patient@example.test' }));
  expect(result).toMatchObject({ status: 422, data: { emailWarning: true, values: { patient_id: patientId, idempotency_key: key, email_warning_acknowledged: '' } } });
  expect(mocks.slots).not.toHaveBeenCalled(); expect(mocks.create).not.toHaveBeenCalled();
 });
 it('does not warn because the existing-patient form deliberately submits an empty email', async () => {
  email = 'Actual+Contact@Example.test';
  const result = await actions.create_appointment(event());
  expect(result).not.toMatchObject({ data: { emailWarning: true } }); expect(mocks.slots).toHaveBeenCalledOnce();
 });
 it('allows explicit continuation without email, with the same operation key', async () => {
  await actions.create_appointment(event({ email_warning_acknowledged: 'true' }));
  expect(mocks.slots).toHaveBeenCalledOnce();
  expect(mocks.replay).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ idempotencyKey: key }));
 });
 it('recovers a committed creation before showing a newly missing-contact warning', async () => {
  mocks.replay.mockResolvedValueOnce({ id: '55555555-5555-4555-8555-555555555555' });
  await expect(actions.create_appointment(event())).rejects.toMatchObject({ status: 303 });
  expect(mocks.slots).not.toHaveBeenCalled(); expect(mocks.create).not.toHaveBeenCalled();
 });
 it('retains a new patient draft without creating either the patient or an appointment', async () => {
  const result = await actions.create_appointment(event({ patient_mode: 'new', patient_id: '', patient_name: 'Synthetic New Patient', patient_phone: '3425048209' }));
  expect(result).toMatchObject({ status: 422, data: { emailWarning: true, values: { patient_name: 'Synthetic New Patient', idempotency_key: key } } });
  expect(mocks.create).not.toHaveBeenCalled();
 });
 it('continues normally with a supplied email for a new patient', async () => {
  await actions.create_appointment(event({ patient_mode: 'new', patient_id: '', patient_name: 'Synthetic New Patient', patient_phone: '3425048209', patient_email: 'new@example.test' }));
  expect(mocks.slots).toHaveBeenCalledOnce();
 });
});
