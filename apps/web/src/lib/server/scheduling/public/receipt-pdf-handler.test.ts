import { beforeEach, describe, expect, it, vi } from 'vitest';
const mocks = vi.hoisted(() => ({ managed: vi.fn(), stable: vi.fn(), build: vi.fn() }));
vi.mock('$lib/server/scheduling/public/appointment-token', () => ({
 loadAppointmentForManagementAccess: mocks.managed, loadAppointmentForToken: mocks.stable
}));
vi.mock('$lib/server/scheduling/public/receipt-pdf', () => ({ buildAppointmentReceiptPdf: mocks.build }));
import { GET } from '../../../../routes/turno/[token]/comprobante.pdf/+server';
import { GET as capabilityPdf } from '../../../../routes/gestion/[token]/comprobante.pdf/+server';

const appointment = { service_name_snapshot: 'Own service', professional_name_snapshot: 'Own professional',
 starts_at: '2026-11-20T12:00:00Z', is_joint: false, public_status_label: 'Reservado',
 business: { name: 'Own clinic', timezone: 'UTC', address: null, address_instructions: null } };
const event = () => ({ params: { token: 'original-token' }, fetch: vi.fn() } as never);
beforeEach(() => {
 vi.clearAllMocks();
 mocks.managed.mockResolvedValue({ appointment });
 mocks.stable.mockResolvedValue({ appointment });
 mocks.build.mockResolvedValue(new Uint8Array([37, 80, 68, 70]));
});
describe('expanded appointment receipt uses current management authority', () => {
 it('requires the original legacy channel and never borrows the stable Calendar reader', async () => {
  await GET(event());
  expect(mocks.managed).toHaveBeenCalledWith(expect.any(Function), { token: 'original-token', legacy: true });
  expect(mocks.stable).not.toHaveBeenCalled();
 });
 it('does not reveal a service/professional from a revoked link that remains a readable Calendar identity', async () => {
  mocks.managed.mockResolvedValueOnce({ appointment: null });
  await expect(GET(event())).rejects.toMatchObject({ status: 404 });
  expect(mocks.build).not.toHaveBeenCalled();
  expect(mocks.stable).not.toHaveBeenCalled();
 });
 it('renders authorized current receipt fields with the actual clinic identity', async () => {
  const response = await GET(event());
  expect(response.headers.get('content-type')).toBe('application/pdf');
  expect([...new Uint8Array(await response.arrayBuffer())]).toEqual([37, 80, 68, 70]);
  expect(mocks.build).toHaveBeenCalledWith(expect.objectContaining({ businessName: 'Own clinic', statusLabel: 'Reservado',
   fields: expect.arrayContaining([{ label: 'Servicio', value: 'Own service' }, { label: 'Profesional', value: 'Own professional' }]) }));
 });
});


it('preserves the capability channel and keeps receipt tokens out of referrer/cache metadata', async () => {
 const response = await capabilityPdf(event());
 expect(mocks.managed).toHaveBeenCalledWith(expect.any(Function), { token: 'original-token', legacy: false });
 expect(mocks.stable).not.toHaveBeenCalled();
 expect(response.headers.get('referrer-policy')).toBe('no-referrer');
 expect(response.headers.get('cache-control')).toBe('no-store');
});
