import { afterEach, beforeEach, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({ create: vi.fn(), context: vi.fn(), rebook: vi.fn(), from: vi.fn(), log: vi.fn(), select: vi.fn(),
 filters: [] as Array<[string,unknown]>, row: { data: null as unknown, error: null as unknown } }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseServerClient: mocks.create }));
vi.mock('$lib/server/access/public/business', () => ({ resolveActiveBusiness: mocks.context }));
vi.mock('$lib/server/platform/logging', () => ({ logServerFailure: mocks.log }));
vi.mock('$lib/server/scheduling/public/public-appointments', () => ({ loadRebookUrl: mocks.rebook }));
vi.mock('$lib/server/integrations/public/messaging', () => ({ getPublicSiteUrl: () => 'https://app.example.test' }));
const { GET, POST } = await import('./+server');
const businessId = 'b1000000-0000-4000-8000-000000000001', appointmentId = 'b2000000-0000-4000-8000-000000000001';
const revision = 'a'.repeat(64);
const snapshot = () => ({ appointment_id: appointmentId, status: 'expired', amount: 40000, currency: 'ARS',
 request_from: '2026-10-28T03:00:00Z', due_at: '2026-11-03T12:00:00Z', auto_cancel: true,
 waived_reason: null, recorded_at: null, reminder_opened_at: null, expired_at: '2026-11-03T12:05:00Z', revision: 2,
 appointments: { status: 'cancelled', starts_at: '2026-11-10T12:00:00Z', appointment_management_revision: revision,
  patients: { full_name: 'Persona actual', phone_e164: '+5493425048209', blocked: false, archived_at: null },
  businesses: { name: 'Consultorio actual', timezone: 'America/Argentina/Cordoba', slug: 'actual' } } });
const event = (fields: Record<string,string> = { expected_revision: revision }, method = 'POST') => ({
 params: { appointmentId }, locals: { auth: { access_token: 'synthetic' } }, fetch: vi.fn(), cookies: {},
 request: new Request('https://app.example.test/odonto/senas/avisar/' + appointmentId, { method,
  ...(method === 'POST' ? { body: new URLSearchParams(fields) } : {}), headers: { 'user-agent': 'Mozilla/5.0 (Linux; Android 14)' } })
}) as never;
const redirected = async (callback: () => unknown) => {
 try { await callback(); } catch (error) { return error as { status: number; location: string }; }
 throw new Error('Expected review redirect');
};
beforeEach(() => {
 vi.clearAllMocks(); vi.useFakeTimers({ toFake: ['Date'] }); vi.setSystemTime(new Date('2026-11-05T12:00:00Z'));
 mocks.filters.length = 0; mocks.row = { data: snapshot(), error: null };
 mocks.create.mockResolvedValue({ from: mocks.from });
 mocks.context.mockResolvedValue({ business: { id: businessId }, role: 'reception', canOperate: true });
 mocks.rebook.mockResolvedValue('/embed/v1/0123456789abcdef0123456789abcdef');
 const builder = { select: (value: string) => { mocks.select(value); return builder; },
  eq: (key: string,value: unknown) => { mocks.filters.push([key,value]); return builder; }, maybeSingle: async () => mocks.row };
 mocks.from.mockReturnValue(builder);
});
afterEach(() => vi.useRealTimers());

it('GET does not read a recipient or issue any credential', async () => {
 expect(await redirected(() => GET(event({},'GET')))).toEqual({ status: 303, location: '/odonto/senas?aviso=actualizar' });
 expect(mocks.create).not.toHaveBeenCalled();
});
it.each(['android','desktop'])('prepares a current closed-turn %s draft, without management actions or trusting submitted identity', async device => {
 const reply = await POST(event({ expected_revision: revision, device, patient_name: 'forged', phone: '+5491111111111' }));
 expect(reply.status).toBe(302); expect(reply.headers.get('cache-control')).toBe('no-store');
 expect(reply.headers.get('referrer-policy')).toBe('no-referrer');
 const location = new URL(reply.headers.get('location')!), message = location.searchParams.get('text')!;
 expect(location.hostname).toBe(device === 'desktop' ? 'web.whatsapp.com' : 'wa.me');
 expect(location.searchParams.get('phone') ?? location.pathname.slice(1)).toBe('5493425048209');
 expect(message).toContain('Hola Persona actual.'); expect(message).toContain('se canceló');
 expect(message).toContain('https://app.example.test/embed/v1/0123456789abcdef0123456789abcdef');
 expect(message).not.toMatch(/\/gestion\/|\/turno\/|forged|reprogramar|confirmar turno/i);
 expect(mocks.filters).toEqual([['business_id',businessId],['appointment_id',appointmentId]]);
 expect(mocks.select).toHaveBeenCalledWith(expect.not.stringContaining('confirmation_token'));
});
it('missing review or readonly context does not read the appointment', async () => {
 await redirected(() => POST(event({}))); expect(mocks.create).not.toHaveBeenCalled();
 mocks.context.mockResolvedValue({ business: { id: businessId }, role: 'readonly', canOperate: true });
 expect((await redirected(() => POST(event()))).location).toContain('cambio'); expect(mocks.from).not.toHaveBeenCalled();
});
it('a changed, active, started or blocked turn cannot produce the closed-turn notice', async () => {
 const base = snapshot();
 for (const appointments of [ { ...base.appointments, appointment_management_revision: 'b'.repeat(64) },
  { ...base.appointments, status: 'reserved' }, { ...base.appointments, starts_at: '2026-11-05T12:00:00Z' },
  { ...base.appointments, patients: { ...base.appointments.patients, blocked: true } } ]) {
  mocks.row = { data: { ...base, appointments }, error: null };
  expect((await redirected(() => POST(event()))).location).toContain('cambio');
 }
 expect(mocks.rebook).not.toHaveBeenCalled();
});
it('optional rebooking failure leaves an accurate cancellation/contact draft', async () => {
 mocks.rebook.mockRejectedValue(new Error('unavailable'));
 const reply = await POST(event());
 const message = new URL(reply.headers.get('location')!).searchParams.get('text')!;
 expect(message).toContain('se canceló'); expect(message).toContain('respondé este mensaje'); expect(message).not.toContain('reservarlo acá');
});
it('unknown/missing data or invalid current phone returns to review without guessing a recipient', async () => {
 for (const [data, notice] of [ [null,'no_encontrado'], [{ ...snapshot(), appointments: { ...snapshot().appointments,
  patients: { ...snapshot().appointments.patients, phone_e164: '1234' } } },'sin_telefono'] ] as const) {
  mocks.row = { data, error: null }; expect((await redirected(() => POST(event()))).location).toContain(notice);
 }
});
