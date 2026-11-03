import { describe, expect, it, vi } from 'vitest';
import { loadPatientManagementScreen, submitPatientManagementAction } from './patient-management-flow';
import { applyPatientManagementCommand, listPatientManagementSlots, loadPatientManagementView } from './patient-management';
vi.mock('./patient-management', async importOriginal => ({ ...await importOriginal<typeof import('./patient-management')>(),
 applyPatientManagementCommand: vi.fn(), listPatientManagementSlots: vi.fn(), loadPatientManagementView: vi.fn() }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
vi.mock('$lib/server/platform/logging', () => ({ logServerFailure: vi.fn() }));
const access = { token: 'a'.repeat(64), legacy: false };
const view = () => ({ appointment: { starts_at: '2026-12-01T12:00:00Z', can_cancel: true, can_request_reschedule: true, can_confirm: true,
 business: { timezone: 'America/Argentina/Cordoba' } }, now: '2026-11-03T14:00:00Z', revision: 'b'.repeat(64),
 financialTerms: null, financialSummary: { appliedAmount: '0', forfeitedAmount: '0', unresolvedAmount: '0' }, integration: null });
const request = (fields: Record<string, string>) => new Request('https://app.test/gestion/token?/cancel', { method: 'POST', body: new URLSearchParams(fields) });
const fields = () => ({ operation_id: 'a1000000-0000-4000-8000-000000000001', expected_revision: 'b'.repeat(64), confirm_cancel: 'true' });
describe('patient management screen/controller', () => {
 it('loads the selected financial preview and current presentation together once, never on a separate identity read', async () => {
  vi.mocked(loadPatientManagementView).mockResolvedValue(view() as never);
  vi.mocked(listPatientManagementSlots).mockResolvedValue({ slots: [{ starts_at: '2026-12-02T12:00:00Z', ends_at: '2026-12-02T12:45:00Z' }], availabilityRevision: 9 } as never);
  vi.mocked(loadPatientManagementView).mockClear();
  const screen = await loadPatientManagementScreen({} as never, access, new URL('https://app.test/gestion/token?accion=reprogramar&fecha=2026-12-02&horario=2026-12-02T12%3A00%3A00Z'));
  expect(loadPatientManagementView).toHaveBeenCalledExactlyOnceWith(expect.anything(), access, '2026-12-02T12:00:00Z');
  expect(screen?.panel.selectedStart).toBe('2026-12-02T12:00:00Z'); expect(screen?.panel.url).toBe(`/gestion/${access.token}`);
 });
 it('does not calculate slots in cancellation mode and never executes a command on GET', async () => {
  vi.mocked(loadPatientManagementView).mockResolvedValue(view() as never); vi.mocked(listPatientManagementSlots).mockClear(); vi.mocked(applyPatientManagementCommand).mockClear();
  const screen = await loadPatientManagementScreen({} as never, access, new URL('https://app.test/gestion/token?accion=cancelar'));
  expect(screen?.panel.mode).toBe('cancel'); expect(listPatientManagementSlots).not.toHaveBeenCalled(); expect(applyPatientManagementCommand).not.toHaveBeenCalled();
 });
 it('cannot select an injected unavailable time from a URL', async () => {
  vi.mocked(loadPatientManagementView).mockResolvedValue(view() as never);
  vi.mocked(listPatientManagementSlots).mockResolvedValue({ slots: [], availabilityRevision: 9 } as never);
  const screen = await loadPatientManagementScreen({} as never, access, new URL('https://app.test/gestion/token?accion=reprogramar&horario=2026-12-02T12%3A00%3A00Z'));
  expect(screen?.panel.selectedStart).toBeNull();
 });
 it('requires the explicit cancellation confirmation and does not call the command on an incomplete form', async () => {
  vi.mocked(applyPatientManagementCommand).mockClear();
  const result = await submitPatientManagementAction({} as never, access, 'cancel', request({ ...fields(), confirm_cancel: 'false' }));
  expect(result.success).not.toBe(true); expect(applyPatientManagementCommand).not.toHaveBeenCalled();
 });
 it('preserves the submitted revision/operation and returns the committed result without inventing a fresh expectation', async () => {
  vi.mocked(applyPatientManagementCommand).mockResolvedValue({ changed: true, status: 'cancelled' } as never);
  const result = await submitPatientManagementAction({} as never, access, 'cancel', request(fields()));
  expect(result.success).toBe(true);
  expect(applyPatientManagementCommand).toHaveBeenLastCalledWith(expect.anything(), access, expect.objectContaining({ operationId: fields().operation_id, expectedRevision: fields().expected_revision, action: 'cancel' }));
 });
 it('keeps the exact original fields for a transport-uncertain retry, with no false rollback statement', async () => {
  vi.mocked(applyPatientManagementCommand).mockRejectedValue(new Error('fetch failed'));
  const result = await submitPatientManagementAction({} as never, access, 'cancel', request(fields()));
  expect(result.retrySameOperation).toBe(true); expect(result.submitted).toEqual(fields()); expect(result.message).not.toMatch(/no se guardó|fetch/);
 });
 it('requires review instead of retrying a known stale revision without consent', async () => {
  vi.mocked(applyPatientManagementCommand).mockRejectedValue(new Error('APPOINTMENT_MANAGEMENT_CHANGED'));
  const result = await submitPatientManagementAction({} as never, access, 'cancel', request(fields()));
  expect(result.retrySameOperation).toBe(false); expect(result.submitted?.expected_revision).toBe(fields().expected_revision);
 });
 it('rejects duplicate fields and an oversized body before executing the command', async () => {
  vi.mocked(applyPatientManagementCommand).mockClear();
  const duplicates = new URLSearchParams(fields()); duplicates.append('operation_id', fields().operation_id);
  await submitPatientManagementAction({} as never, access, 'cancel', new Request('https://app.test', { method: 'POST', body: duplicates }));
  await submitPatientManagementAction({} as never, access, 'cancel', request({ ...fields(), note: 'x'.repeat(70000) }));
  expect(applyPatientManagementCommand).not.toHaveBeenCalled();
 });
});
