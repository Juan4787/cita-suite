import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { RequestEvent } from '@sveltejs/kit';
import { createPatientManagementPage } from './patient-management-page';
import { demoPublicAppointment } from './public-appointments';
const mock = vi.hoisted(() => ({
 client: { rpc: vi.fn() }, screen: vi.fn(), submit: vi.fn(), calendarState: vi.fn(), calendarSync: vi.fn(), mark: vi.fn()
}));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseAdminClient: async () => mock.client }));
vi.mock('./patient-management-flow', () => ({ loadPatientManagementScreen: mock.screen, submitPatientManagementAction: mock.submit }));
vi.mock('$lib/server/integrations/public/calendar-tracking', () => ({ canRegisterCalendarAction: () => false, markCalendarOffered: mock.mark }));
vi.mock('$lib/server/integrations/public/google-calendar', () => ({
 loadGoogleCalendarUiState: mock.calendarState, processAppointmentGoogleCalendarSync: mock.calendarSync,
 getGoogleCalendarPublicMessage: () => null, requestGoogleCalendarEventDeletion: vi.fn()
}));
vi.mock('$lib/server/platform/logging', () => ({ logServerFailure: vi.fn() }));
const token = 'a'.repeat(64);
const event = (): RequestEvent => ({ params: { token }, fetch: vi.fn(), url: new URL(`https://app.test/gestion/${token}`),
 request: new Request(`https://app.test/gestion/${token}`, { headers: { 'user-agent': 'Googlebot' } }), setHeaders: vi.fn(), getClientAddress: () => '192.0.2.4'
} as unknown as RequestEvent);
beforeEach(() => {
 vi.clearAllMocks(); mock.client.rpc.mockResolvedValue({ data: true, error: null });
 mock.calendarState.mockResolvedValue({ available: false, state: 'none', current: false, reminderLabel: 'antes del turno' });
 mock.screen.mockResolvedValue({ view: { appointment: demoPublicAppointment('b'.repeat(64)), newBookingAllowed: false }, panel: null });
});
describe('public appointment route delegation', () => {
 it.each([false, true])('uses the explicit legacy channel %s without guessing from identical token formats', async legacy => {
  const e = event(); await createPatientManagementPage(legacy).load(e);
  expect(mock.screen).toHaveBeenCalledExactlyOnceWith(mock.client, { token, legacy }, e.url);
  expect(e.setHeaders).toHaveBeenCalledWith(expect.objectContaining({ 'cache-control': 'no-store', 'referrer-policy': 'no-referrer', 'x-robots-tag': expect.stringContaining('noindex') }));
 });
 it('does not fall back to the stable calendar token after a revoked management link', async () => {
  mock.screen.mockResolvedValue(null);
  const loaded = await createPatientManagementPage(true).load(event());
  expect(loaded.appointment).toBeNull(); expect(mock.screen).toHaveBeenCalledTimes(1);
  expect(mock.calendarState).not.toHaveBeenCalled(); expect(mock.mark).not.toHaveBeenCalled();
 });
 it('keeps a rejected stale/expired operation as a failure with its original retry data', async () => {
  const feedback = { success: false, message: 'El turno cambió.', submitted: { expected_revision: 'old' }, retrySameOperation: false };
  mock.submit.mockResolvedValue(feedback);
  const action = createPatientManagementPage(false).actions.cancel;
  const result = await action!(event());
  expect(result).toMatchObject({ status: 409, data: feedback });
  expect(mock.submit).toHaveBeenCalledWith(mock.client, { token, legacy: false }, 'cancel', expect.any(Request));
  expect(mock.calendarSync).not.toHaveBeenCalled();
 });
 it('preserves a successful local command if the external calendar synchronization fails', async () => {
  mock.submit.mockResolvedValue({ success: true, message: 'La cancelación quedó registrada.', result: { appointmentId: 'owned-appointment', changed: true } });
  mock.calendarSync.mockRejectedValue(new Error('provider offline'));
  expect(await createPatientManagementPage(false).actions.cancel!(event())).toMatchObject({ success: true });
  expect(mock.calendarSync).toHaveBeenCalledWith(mock.client, 'owned-appointment', expect.anything());
 });
 it('does not let the legacy request-reschedule action create another manual request', async () => {
  const result = await createPatientManagementPage(true).actions.request_reschedule!(event());
  expect(result).toMatchObject({ status: 409 }); expect(mock.submit).not.toHaveBeenCalled();
 });
 it('blocks excess requests without attempting an agenda command', async () => {
  mock.client.rpc.mockResolvedValue({ data: false, error: null });
  const result = await createPatientManagementPage(false).actions.reschedule!(event());
  expect(result).toMatchObject({ status: 429 }); expect(mock.submit).not.toHaveBeenCalled();
 });
});
