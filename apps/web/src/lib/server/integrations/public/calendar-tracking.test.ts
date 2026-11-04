import { beforeEach, describe, expect, it, vi } from 'vitest';
const config = vi.hoisted(() => ({ env: {} as Record<string, string> }));
vi.mock('$env/dynamic/private', () => ({ env: config.env }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
import { recordCalendarAction, recordCalendarMetric, markCalendarOffered } from './calendar-tracking';
import { requestGoogleCalendarEventDeletion } from './google-calendar';

const access = { token: 'a'.repeat(64), legacy: false };
const appointmentId = '11111111-1111-4111-8111-111111111111';
const eventId = '22222222-2222-4222-8222-222222222222';
beforeEach(() => {
 Object.assign(config.env, { GOOGLE_CALENDAR_MANAGED_ENABLED: 'true', GOOGLE_CALENDAR_CLIENT_ID: 'synthetic-client',
  GOOGLE_CALENDAR_CLIENT_SECRET: 'synthetic-secret', GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64'),
  PUBLIC_SITE_URL: 'https://cita-suite.example' });
});

describe('patient Calendar commands carry authority through the final write', () => {
 it('records the exact original channel and delegates provider/audit decisions to one SQL command', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: true, error: null });
  await recordCalendarAction({ rpc } as never, access, 'clicked_google', { source: 'android_native_fallback' });
  expect(rpc).toHaveBeenCalledExactlyOnceWith('record_patient_calendar_action', {
   p_token: access.token, p_legacy: false, p_action: 'clicked_google', p_source: 'android_native_fallback'
  });
 });
 it('preserves a rejection after the earlier page read without any ID-only write or separate audit', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: null, error: { message: 'APPOINTMENT_LINK_UNAVAILABLE' } });
  await expect(recordCalendarAction({ rpc } as never, access, 'clicked_ics')).rejects.toMatchObject({ message: 'APPOINTMENT_LINK_UNAVAILABLE' });
  expect(rpc).toHaveBeenCalledTimes(1);
 });
 it.each([null, undefined, false, 'true'])('does not confirm a click from an unreadable completion: %j', async data => {
  const rpc = vi.fn().mockResolvedValue({ data, error: null });
  await expect(recordCalendarAction({ rpc } as never, access, 'clicked_ics')).rejects.toMatchObject({ name: 'InvalidDataContractError' });
  expect(rpc).toHaveBeenCalledTimes(1);
 });
 it('records offered through the current token without sending a browser clock or stale appointment status', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: false, error: null });
  await markCalendarOffered({ rpc } as never, access);
  expect(rpc).toHaveBeenCalledExactlyOnceWith('mark_patient_calendar_offered', { p_token: access.token, p_legacy: false });
 });
 it('keeps metrics separate from calendar coverage', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: true, error: null });
  await recordCalendarMetric({ rpc } as never, access, 'android_intent', 'data');
  expect(rpc).toHaveBeenCalledExactlyOnceWith('record_patient_calendar_metric', {
   p_token: access.token, p_legacy: false, p_kind: 'android_intent', p_variant: 'data'
  });
 });
 it('recovers an absent local link without asserting an unobserved provider deletion', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: { appointment_id: appointmentId, event_row_id: null, status: 'not_connected' }, error: null });
  const fetchFn = vi.fn();
  await expect(requestGoogleCalendarEventDeletion({ rpc } as never, access, fetchFn)).resolves.toEqual({ status: 'not_connected' });
  expect(rpc).toHaveBeenCalledExactlyOnceWith('request_patient_google_calendar_deletion', { p_token: access.token, p_legacy: false });
  expect(fetchFn).not.toHaveBeenCalled();
 });
 it.each([null, {}, { appointment_id: appointmentId, event_row_id: null, status: 'pending_delete' },
  { appointment_id: appointmentId, event_row_id: eventId, status: 'not_connected' }])('does not dispatch a malformed removal result: %j', async data => {
  const rpc = vi.fn().mockResolvedValue({ data, error: null }); const fetchFn = vi.fn();
  await expect(requestGoogleCalendarEventDeletion({ rpc } as never, access, fetchFn)).rejects.toMatchObject({ name: 'InvalidDataContractError' });
  expect(fetchFn).not.toHaveBeenCalled();
  expect(rpc).toHaveBeenCalledTimes(1);
 });
 it('dispatches an acknowledged removal only through the durable claimant, never through an unowned core', async () => {
  const rpc = vi.fn().mockResolvedValueOnce({ data: { appointment_id: appointmentId, event_row_id: eventId, status: 'pending_delete' }, error: null })
   .mockResolvedValueOnce({ data: null, error: null });
  const chain: any = { select: () => chain, eq: () => chain, maybeSingle: async () => ({ data: { sync_status: 'pending_delete' }, error: null }) };
  const fetchFn = vi.fn();
  await expect(requestGoogleCalendarEventDeletion({ rpc, from: () => chain } as never, access, fetchFn)).resolves.toEqual({ status: 'pending_delete' });
  expect(rpc.mock.calls.map(([name]) => name)).toEqual(['request_patient_google_calendar_deletion', 'claim_google_calendar_event_sync']);
  expect(rpc.mock.calls[1][1]).toMatchObject({ p_event_row_id: eventId });
  expect(fetchFn).not.toHaveBeenCalled();
 });
 it('does not call the provider after an unanswered local removal command', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: null, error: new Error('synthetic lost SQL reply') }); const fetchFn = vi.fn();
  await expect(requestGoogleCalendarEventDeletion({ rpc } as never, access, fetchFn)).rejects.toThrow('synthetic lost SQL reply');
  expect(rpc).toHaveBeenCalledTimes(1);
  expect(fetchFn).not.toHaveBeenCalled();
 });
});
