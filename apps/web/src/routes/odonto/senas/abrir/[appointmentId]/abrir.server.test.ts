import { beforeEach, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({ context: vi.fn(), prepare: vi.fn(), create: vi.fn(), from: vi.fn(), log: vi.fn(),
 filters: [] as Array<[string, unknown]>, phone: '+5493425048209' as string | null }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseServerClient: mocks.create }));
vi.mock('$lib/server/access/public/business', () => ({ resolveActiveBusiness: mocks.context }));
vi.mock('$lib/server/platform/logging', () => ({ logServerFailure: mocks.log }));
vi.mock('$lib/server/scheduling/public/staff-delivery', async importOriginal => ({
 ...(await importOriginal<typeof import('$lib/server/scheduling/public/staff-delivery')>()), prepareStaffDelivery: mocks.prepare
}));
const { GET, POST } = await import('./+server');
const businessId = 'b1000000-0000-4000-8000-000000000001', appointmentId = 'b2000000-0000-4000-8000-000000000001';
const revision = 'a'.repeat(64), mobile = 'https://wa.me/5493425048209?text=prepared', desktop = 'https://web.whatsapp.com/send?phone=5493425048209&text=prepared';
const client = { from: mocks.from };
const event = (method = 'POST', form = new URLSearchParams({ expected_revision: revision, phone: '+5491111111111' }), search = '', id = appointmentId) => ({
 params: { appointmentId: id }, locals: { auth: { access_token: 'synthetic-session' } }, fetch: vi.fn(), cookies: {},
 url: new URL('https://app.example.test/odonto/senas/abrir/' + id + search),
 request: new Request('https://app.example.test/odonto/senas/abrir/' + id + search,
  { method, ...(method === 'POST' ? { body: form } : {}), headers: { 'user-agent': 'Mozilla/5.0 (Linux; Android 14)' } })
}) as never;
const redirectOf = async (callback: () => unknown) => {
 try { await callback(); } catch (error) { return error as { status: number; location: string }; }
 throw new Error('Expected redirect');
};
beforeEach(() => {
 vi.clearAllMocks(); mocks.filters.length = 0; mocks.phone = '+5493425048209';
 mocks.create.mockResolvedValue(client); mocks.context.mockResolvedValue({ business: { id: businessId }, canOperate: true });
 mocks.prepare.mockResolvedValue({ whatsappUrl: mobile, whatsappWebUrl: desktop });
 const builder = { select: vi.fn(() => builder), eq: vi.fn((key: string, value: unknown) => { mocks.filters.push([key,value]); return builder; }),
  maybeSingle: vi.fn(async () => ({ data: { patients: { phone_e164: mocks.phone } }, error: null })) };
 mocks.from.mockReturnValue(builder);
});

it('GET and prefetch never prepare credentials or mark a deposit reminder', async () => {
 expect(await redirectOf(() => GET(event('GET')))).toEqual({ status: 303, location: '/odonto/senas?aviso=actualizar' });
 expect(mocks.create).not.toHaveBeenCalled(); expect(mocks.prepare).not.toHaveBeenCalled();
});
it.each([['android',mobile],['desktop',desktop]])('POST opens the committed %s message and binds the stored phone, never the submitted number', async (device, location) => {
 const result = await POST(event('POST', undefined, `?dispositivo=${device}&confirmar=1`));
 expect(result.status).toBe(302); expect(result.headers.get('location')).toBe(location);
 expect(result.headers.get('cache-control')).toBe('no-store'); expect(result.headers.get('referrer-policy')).toBe('no-referrer');
 expect(mocks.prepare).toHaveBeenCalledExactlyOnceWith(client, { businessId, appointmentId, expectedRevision: revision,
  kind: 'deposit', reopen: true, expectedPhone: '+5493425048209' });
 expect(mocks.filters).toEqual([['business_id',businessId],['id',appointmentId]]);
});
it('unreviewed, malformed, readonly or phone-less requests never issue or mark', async () => {
 await redirectOf(() => POST(event('POST', new URLSearchParams())));
 await redirectOf(() => POST(event('POST', undefined, '', 'bad-id')));
 expect(mocks.create).not.toHaveBeenCalled();
 mocks.context.mockResolvedValue({ business: { id: businessId }, canOperate: false });
 await redirectOf(() => POST(event())); expect(mocks.from).not.toHaveBeenCalled();
 mocks.context.mockResolvedValue({ business: { id: businessId }, canOperate: true }); mocks.phone = null;
 expect((await redirectOf(() => POST(event()))).location).toContain('sin_telefono'); expect(mocks.prepare).not.toHaveBeenCalled();
});
it.each([['DEPOSIT_REMINDER_ALREADY_OPENED','ya_abierto'],['DEPOSIT_NOT_PENDING','no_pendiente'],
 ['APPOINTMENT_MANAGEMENT_CHANGED','cambio'],['APPOINTMENT_MANAGEMENT_FORBIDDEN','cambio'],['network','error']])('classifies %s without claiming an uncertain rollback', async (code, notice) => {
 mocks.prepare.mockRejectedValue(new Error(code));
 expect(await redirectOf(() => POST(event()))).toEqual({ status: 303, location: '/odonto/senas?aviso=' + notice });
 if (code === 'network') expect(mocks.log).toHaveBeenCalled();
});
