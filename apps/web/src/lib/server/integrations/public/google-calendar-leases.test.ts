import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { PublicAppointmentView } from '$lib/server/scheduling/public/public-appointments';

const fixture = vi.hoisted(() => ({ env: {} as Record<string, string>, appointment: {} as PublicAppointmentView }));
vi.mock('$env/dynamic/private', () => ({ env: fixture.env }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
vi.mock('$lib/server/scheduling/public/public-appointments', () => ({
 loadPublicAppointmentByToken: vi.fn(async () => fixture.appointment),
 publicAppointmentPlace: vi.fn()
}));
import { processGoogleCalendarEvent } from './google-calendar';
import { JobBudgetExhaustedError } from '$lib/server/integrations/internal/job-budget';

const eventId = '11111111-1111-4111-8111-111111111111';
const appointmentId = '22222222-2222-4222-8222-222222222222';
const connectionId = '33333333-3333-4333-8333-333333333333';
const now = new Date('2026-08-09T12:00:00Z');
beforeEach(() => {
 Object.assign(fixture.env, {
  GOOGLE_CALENDAR_MANAGED_ENABLED: 'true', GOOGLE_CALENDAR_CLIENT_ID: 'dedicated-client',
  GOOGLE_CALENDAR_CLIENT_SECRET: 'synthetic-secret', GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64'),
  PUBLIC_SITE_URL: 'https://cita-suite.example'
 });
 fixture.appointment = {
  id: appointmentId, token: 'stable-calendar-token', status: 'reserved', starts_at: '2026-08-10T15:00:00Z',
  ends_at: '2026-08-10T16:00:00Z', calendar_sequence: 4, professional_name_snapshot: 'Professional',
  business: { name: 'Synthetic practice', timezone: 'UTC', address: null, maps_link: null }
 } as PublicAppointmentView;
});
afterEach(() => vi.restoreAllMocks());

// This model verifies the consumer boundary, not SQL isolation. Actual lease
// exclusion, recovery and persisted transitions are covered by the SQL suite.
const database = (options: { unavailable?: boolean; completionError?: boolean; malformedCompletion?: boolean; recovered?: boolean; wrongConnection?: boolean; afterRead?: () => void } = {}) => {
 let owner: string | null = null;
 let committed = false;
 const rpc = vi.fn(async (name: string, args: any): Promise<any> => {
  if (name === 'claim_google_calendar_event_sync') {
   if (options.unavailable || owner) return { data: null, error: null };
   owner = args.p_claim_token;
   return { data: { event_row_id: eventId, business_id: 'business', appointment_id: appointmentId, connection_id: connectionId,
    calendar_id: 'primary', event_id: null, sync_status: 'pending_create', attempt_count: 0,
    refresh_token_ciphertext: null, connection_revoked_at: null, claim_recovered: options.recovered ?? false }, error: null };
  }
  if (name === 'complete_google_calendar_sync_batch') {
   committed = true;
   if (options.completionError) return { data: null, error: { message: 'synthetic lost reply after commit' } };
   if (options.malformedCompletion) return { data: { results: [], released: 0 }, error: null };
   const result = args.p_results[0];
   return { data: { results: [{ event_row_id: eventId, status: result.outcome === 'synced' ? 'active' : 'pending_create', removed_connection_id: null }], released: 0 }, error: null };
  }
  throw new Error(`Unexpected unowned write: ${name}`);
 });
 const from = vi.fn((table: string) => {
  const chain: any = { select: () => chain, eq: () => chain, maybeSingle: async () => {
   options.afterRead?.();
   return { data: table === 'appointment_google_calendar_events'
    ? { id: eventId, business_id: 'business', appointment_id: appointmentId,
     connection_id: options.wrongConnection ? 'another-connection' : connectionId, calendar_id: 'primary', event_id: null,
     sync_status: 'pending_create', synced_sequence: -1, attempt_count: 0, claimed_at: now.toISOString(), claim_token: owner }
    : table === 'google_calendar_connections' ? { id: connectionId, refresh_token_ciphertext: null, revoked_at: null }
     : { confirmation_token: fixture.appointment.token }, error: null };
  } };
  return chain;
 });
 return { client: { rpc, from } as any, rpc, committed: () => committed,
  completion: () => rpc.mock.calls.find(([name]) => name === 'complete_google_calendar_sync_batch')?.[1] };
};
const provider = () => vi.fn(async () => Response.json({ id: 'stable-provider-event' }));
const execute = (db: ReturnType<typeof database>, fetchFn = provider()) =>
 processGoogleCalendarEvent(db.client, eventId, fetchFn as typeof fetch, { now, accessToken: 'access' });

describe('immediate calendar work owns the durable lease', () => {
 it('does not dispatch work owned by another executor', async () => {
  const db = database({ unavailable: true }); const fetchFn = provider();
  await expect(execute(db, fetchFn)).resolves.toEqual({ status: 'pending_create' });
  expect(fetchFn).not.toHaveBeenCalled();
  expect(db.rpc.mock.calls.map(([name]) => name)).toEqual(['claim_google_calendar_event_sync']);
 });
 it('excludes another immediate executor before either external write', async () => {
  const db = database(); const fetchFn = provider();
  const results = await Promise.all([execute(db, fetchFn), execute(db, fetchFn)]);
  expect(fetchFn).toHaveBeenCalledTimes(1);
  expect(results.map(result => result.status).sort()).toEqual(['active', 'pending_create']);
  const claims = db.rpc.mock.calls.filter(([name]) => name === 'claim_google_calendar_event_sync');
  expect(new Set(claims.map(([, args]) => args.p_claim_token)).size).toBe(2);
  expect(db.completion()).toMatchObject({ p_claim_token: claims[0][1].p_claim_token, p_finish: false });
 });
 it('uses a recovered SQL claim only once, retaining its original owner', async () => {
  const db = database({ recovered: true }); const fetchFn = provider();
  await expect(execute(db, fetchFn)).resolves.toEqual({ status: 'active' });
  expect(fetchFn).toHaveBeenCalledTimes(1);
  expect(db.completion()?.p_claim_token).toBe(db.rpc.mock.calls[0][1].p_claim_token);
 });
 it('rejects a changed connection before any provider operation', async () => {
  const db = database({ wrongConnection: true }); const fetchFn = provider();
  await expect(execute(db, fetchFn)).rejects.toThrow();
  expect(fetchFn).not.toHaveBeenCalled();
  expect(db.completion()).toBeUndefined();
 });
 it('never writes another failure by ID after a committed completion loses its response', async () => {
  const db = database({ completionError: true }); const fetchFn = provider();
  await expect(execute(db, fetchFn)).rejects.toMatchObject({ message: 'synthetic lost reply after commit' });
  expect(db.committed()).toBe(true);
  expect(fetchFn).toHaveBeenCalledTimes(1);
  expect(db.rpc.mock.calls.map(([name]) => name)).toEqual(['claim_google_calendar_event_sync', 'complete_google_calendar_sync_batch']);
 });
 it('does not invent success from an empty completion', async () => {
  const db = database({ malformedCompletion: true });
  await expect(execute(db)).rejects.toMatchObject({ name: 'InvalidDataContractError' });
  expect(db.rpc).toHaveBeenCalledTimes(2);
 });
 it('quarantines a possibly accepted mutation, carrying the exact context used', async () => {
  const db = database();
  const fetchFn = vi.fn(async () => { throw new TypeError('synthetic network after dispatch'); });
  await expect(execute(db, fetchFn)).resolves.toMatchObject({ status: 'pending_create', errorCode: 'calendar_network' });
  expect(db.completion()?.p_results).toEqual([expect.objectContaining({ event_row_id: eventId, outcome: 'uncertain',
   error_code: 'calendar_network', observed_sequence: 4, observed_sync_status: 'pending_create' })]);
  expect(fetchFn).toHaveBeenCalledTimes(1);
 });
 it('classifies provider budget refusal before dispatch as released work, not a remote failure', async () => {
  const db = database();
  const fetchFn = vi.fn(async () => { throw new JobBudgetExhaustedError('calls'); });
  await execute(db, fetchFn);
  expect(db.completion()?.p_results).toEqual([{ event_row_id: eventId, outcome: 'released' }]);
 });
 it('stops before external dispatch when SQL reads have used the work deadline', async () => {
  let elapsed = 0; vi.spyOn(performance, 'now').mockImplementation(() => elapsed);
  const db = database({ afterRead: () => { elapsed = WORK_LIMIT; } }); const fetchFn = provider();
  await execute(db, fetchFn);
  expect(fetchFn).not.toHaveBeenCalled();
  expect(db.completion()?.p_results).toEqual([{ event_row_id: eventId, outcome: 'released' }]);
 });
});
const WORK_LIMIT = 16_001;
