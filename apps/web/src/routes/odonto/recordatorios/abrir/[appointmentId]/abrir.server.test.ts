import { beforeEach, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({ context: vi.fn(), prepare: vi.fn(), create: vi.fn(), from: vi.fn(),
 filters: [] as Array<[string, unknown]>, phone: '+5493425048209' as string | null }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseServerClient: mocks.create }));
vi.mock('$lib/server/access/public/business', () => ({ resolveActiveBusiness: mocks.context }));
vi.mock('$lib/server/scheduling/public/staff-delivery', () => ({ prepareStaffDelivery: mocks.prepare,
 staffDeliveryFailure: (error: unknown) => ({ status: 409, code: error instanceof Error ? error.message : '' }) }));
const { GET, POST } = await import('./+server');
const businessId = 'b1000000-0000-4000-8000-000000000001', appointmentId = 'b2000000-0000-4000-8000-000000000001';
const revision = 'a'.repeat(64), mobile = 'https://wa.me/5493425048209?text=prepared', desktop = 'https://web.whatsapp.com/send?phone=5493425048209&text=prepared';
const client = { from: mocks.from };
const event = (method = 'POST', form = new URLSearchParams({ expected_revision: revision, phone: '+5491111111111' }), search = '') => ({
 params: { appointmentId }, locals: { auth: { access_token: 'synthetic-session' } }, fetch: vi.fn(), cookies: {},
 url: new URL('https://app.example.test/odonto/recordatorios/abrir/' + appointmentId + search),
 request: new Request('https://app.example.test/odonto/recordatorios/abrir/' + appointmentId + search,
  { method, ...(method === 'POST' ? { body: form } : {}), headers: { 'user-agent': 'Mozilla/5.0 (Linux; Android 14)' } })
}) as never;
const redirectOf = async (callback: () => unknown) => {
 try { await callback(); } catch (error) { return error as { status: number; location: string }; }
 throw new Error('Expected redirect');
};
beforeEach(() => {
 vi.clearAllMocks(); mocks.filters.length = 0; mocks.phone = '+5493425048209';
 mocks.create.mockResolvedValue(client);
 mocks.context.mockResolvedValue({ business: { id: businessId }, canOperate: true });
 mocks.prepare.mockResolvedValue({ whatsappUrl: mobile, whatsappWebUrl: desktop });
 const builder = { select: vi.fn(() => builder), eq: vi.fn((key: string, value: unknown) => { mocks.filters.push([key,value]); return builder; }),
  maybeSingle: vi.fn(async () => ({ data: { patients: { phone_e164: mocks.phone } }, error: null })) };
 mocks.from.mockReturnValue(builder);
});

it('GET is a read-only return to the current list and preserves Hoy', async () => {
 const result = await redirectOf(() => GET(event('GET', undefined, '?dia=hoy')));
 expect(result).toEqual({ status: 303, location: '/odonto/recordatorios?dia=hoy&aviso=actualizar' });
 expect(mocks.create).not.toHaveBeenCalled(); expect(mocks.prepare).not.toHaveBeenCalled();
});

it.each([['android',mobile],['desktop',desktop]])('POST opens only the prepared %s message with protected headers', async (device, location) => {
 const result = await POST(event('POST', undefined, `?dia=hoy&dispositivo=${device}&confirmar=1`));
 expect(result.status).toBe(302); expect(result.headers.get('location')).toBe(location);
 expect(result.headers.get('cache-control')).toBe('no-store'); expect(result.headers.get('referrer-policy')).toBe('no-referrer');
 expect(mocks.prepare).toHaveBeenCalledExactlyOnceWith(client, { businessId, appointmentId, expectedRevision: revision,
  kind: 'reminder', reopen: true, expectedPhone: '+5493425048209' });
 expect(mocks.filters).toContainEqual(['business_id',businessId]); expect(mocks.filters).toContainEqual(['id',appointmentId]);
});

it('does not mint from missing review, a readonly context or an invalid current phone', async () => {
 const invalid = await redirectOf(() => POST(event('POST', new URLSearchParams())));
 expect(invalid.location).toContain('aviso=actualizar'); expect(mocks.create).not.toHaveBeenCalled();
 mocks.context.mockResolvedValue({ business: { id: businessId }, canOperate: false });
 await redirectOf(() => POST(event())); expect(mocks.from).not.toHaveBeenCalled(); expect(mocks.prepare).not.toHaveBeenCalled();
 mocks.context.mockResolvedValue({ business: { id: businessId }, canOperate: true }); mocks.phone = null;
 await redirectOf(() => POST(event())); expect(mocks.prepare).not.toHaveBeenCalled();
});

it('a concurrent ordinary opening returns to review rather than silently reopening', async () => {
 mocks.prepare.mockRejectedValue(new Error('APPOINTMENT_REMINDER_ALREADY_OPENED'));
 const result = await redirectOf(() => POST(event()));
 expect(result).toEqual({ status: 303, location: '/odonto/recordatorios?aviso=ya_abierto' });
 expect(mocks.prepare).toHaveBeenCalledTimes(1);
});
