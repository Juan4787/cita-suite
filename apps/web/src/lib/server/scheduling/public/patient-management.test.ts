import { describe, expect, it, vi } from 'vitest';
import { loadPatientManagementView, parsePatientManagementView, listPatientManagementSlots } from './patient-management';
import { getAvailabilitySelection } from './availability';
vi.mock('./availability', () => ({ getAvailabilitySelection: vi.fn() }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));

const id = (n: number) => `a1000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const fixture = () => ({
 schema_version: 1, id: id(1), revision: 'a'.repeat(64), generation: 1, schedule_revision: 1, access_kind: 'capability',
 status: 'reserved', starts_at: '2026-12-01T12:00:00+00:00', ends_at: '2026-12-01T12:30:00+00:00', now: '2026-11-03T14:00:00+00:00',
 calendar_token: 'b'.repeat(64), patient_name: 'Paciente sintético', service_name_snapshot: 'Consulta', professional_name_snapshot: 'Profesional',
 service_id: id(2), professional_ids: [id(3)], reschedule_duration_minutes: 45, modality: 'in_person', integration: null,
 patient_instructions_snapshot: null, public_reminder_description_snapshot: null, price_quote_snapshot: null,
 calendar_action_status: 'not_offered', calendar_action_at: null, calendar_action_count: 0, calendar_sequence: 0, calendar_update_required_at: null,
 deposit: null, deposit_transfer_details: null, financial_terms: null,
 financial_summary: { applied_amount: '0', forfeited_amount: '0', unresolved_amount: '0' },
 can_cancel: true, can_confirm: true, can_reschedule: true, is_past: false, new_booking_allowed: false, reschedule_unavailable_reason: null,
 business: { id: id(4), name: 'Consultorio', slug: 'consultorio', timezone: 'America/Argentina/Cordoba', phone: null,
  address: 'Dirección', address_instructions: 'Timbre', maps_url: null, logo_url: null, is_active: true,
  public_booking_enabled: true, cancellation_policy: null, whatsapp_contact_phone: null }
});

describe('patient management snapshot boundary', () => {
 it('uses the server clock, fixed appointment/team identity and current duration without changing the scheduled interval', () => {
  const view = parsePatientManagementView(fixture());
  expect(view.appointment.id).toBe(id(1));
  expect(view.professionalIds).toEqual([id(3)]);
  expect(view.durationMinutes).toBe(45);
  expect(view.appointment.ends_at).toBe('2026-12-01T12:30:00+00:00');
  expect(view.now).toBe('2026-11-03T14:00:00+00:00');
 });
 it('does not serialize unexpected private fields from the response', () => {
  const row = { ...fixture(), patient_email: 'private@example.test', internal_note: 'private clinical note' };
  expect(JSON.stringify(parsePatientManagementView(row))).not.toContain('private');
 });
 it.each(['revision', 'generation', 'status', 'starts_at', 'can_cancel', 'professional_ids', 'schema_version'])(
  'rejects an absent required %s rather than inventing defaults', key => {
   const row: Record<string, unknown> = fixture(); delete row[key];
   expect(() => parsePatientManagementView(row)).toThrow();
  });
 it.each([0, -1, 1.5, Number.MAX_SAFE_INTEGER + 1, '1'])('rejects unsafe revision counters %s', value => {
  expect(() => parsePatientManagementView({ ...fixture(), generation: value })).toThrow();
 });
 it('rejects unknown financial amounts instead of treating them as zero', () => {
  expect(() => parsePatientManagementView({ ...fixture(), financial_summary: { applied_amount: null, forfeited_amount: '0', unresolved_amount: '0' } })).toThrow();
 });
 it('sanitizes public links/images and never shows a physical address for video', () => {
  const row = fixture();
  const view = parsePatientManagementView({ ...row, modality: 'video', integration: {
   id: id(5), revision: 3, is_active: true, public_key: 'a'.repeat(32), theme_snapshot: 'natalia', entry_point: 'public_page',
   modality: 'video', video_instructions_snapshot: 'Acceso virtual', modality_windows: []
  }, business: { ...row.business, logo_url: 'javascript:alert(1)', maps_url: 'javascript:alert(1)' } });
  expect(view.appointment.business.address).toBeNull(); expect(view.appointment.business.maps_link).toBeNull();
  expect(view.appointment.business.address_instructions).toBe('Acceso virtual'); expect(view.appointment.business.logo_url).toBeNull();
 });
 it('retains only the narrow cancellation permission when public booking is off', () => {
  const row = fixture();
  const view = parsePatientManagementView({ ...row, can_reschedule: false, can_confirm: false,
   business: { ...row.business, is_active: false, public_booking_enabled: false } });
  expect(view.appointment.can_cancel).toBe(true); expect(view.appointment.can_request_reschedule).toBe(false);
 });
 it('does not trust contradictory closed/past action permissions', () => {
  expect(() => parsePatientManagementView({ ...fixture(), status: 'cancelled' })).toThrow();
  expect(() => parsePatientManagementView({ ...fixture(), is_past: true })).toThrow();
 });
 it('reads capability and legacy channels explicitly through the one RPC without issuing another credential', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: fixture(), error: null });
  await loadPatientManagementView({ rpc } as never, { token: 'c'.repeat(64), legacy: false });
  expect(rpc).toHaveBeenCalledExactlyOnceWith('get_patient_appointment_management_view', {
   p_token: 'c'.repeat(64), p_legacy: false, p_starts_at: null
  });
 });
 it('returns unavailable uniformly for a revoked/unknown link, without a fallback raw-token query', async () => {
  const rpc = vi.fn().mockResolvedValue({ data: null, error: { message: 'APPOINTMENT_LINK_UNAVAILABLE' } });
  expect(await loadPatientManagementView({ rpc } as never, { token: 'c'.repeat(64), legacy: false })).toBeNull();
  expect(rpc).toHaveBeenCalledTimes(1);
 });
 it('preserves service failures as failures and never disguises them as a missing appointment', async () => {
  const error = { message: 'connection failed' }; const rpc = vi.fn().mockResolvedValue({ data: null, error });
  await expect(loadPatientManagementView({ rpc } as never, { token: 'c'.repeat(64), legacy: true })).rejects.toBe(error);
 });
 it('fixes exclusion, team, service and modality in the authorized snapshot; returns versions from the calculation', async () => {
  vi.mocked(getAvailabilitySelection).mockResolvedValue({ slots: [], configurationRevision: 4, availabilityRevision: 9, durationMinutes: 45 });
  const view = parsePatientManagementView(fixture());
  const selection = await listPatientManagementSlots({} as never, view, '2026-12-02', '2026-12-03');
  expect(selection.availabilityRevision).toBe(9);
  expect(getAvailabilitySelection).toHaveBeenLastCalledWith(expect.anything(), expect.objectContaining({
   excludeAppointmentId: id(1), professionalIds: [id(3)], serviceId: id(2), readScope: 'public', publicOnly: true, ignoreBreak: false
  }));
 });
 it('does not query availability for an unauthorized move or an unbounded date range', async () => {
  vi.mocked(getAvailabilitySelection).mockClear();
  const view = parsePatientManagementView({ ...fixture(), can_reschedule: false });
  await expect(listPatientManagementSlots({} as never, view, '2026-12-02', '2026-12-03')).rejects.toThrow();
  await expect(listPatientManagementSlots({} as never, parsePatientManagementView(fixture()), '2026-12-01', '2027-01-01')).rejects.toThrow();
  expect(getAvailabilitySelection).not.toHaveBeenCalled();
 });
 it('rejects a missing availability revision instead of fetching a newer unrelated version', async () => {
  vi.mocked(getAvailabilitySelection).mockResolvedValue({ slots: [], configurationRevision: 4, availabilityRevision: null, durationMinutes: 45 });
  await expect(listPatientManagementSlots({} as never, parsePatientManagementView(fixture()), '2026-12-02', '2026-12-03')).rejects.toThrow();
 });
});
