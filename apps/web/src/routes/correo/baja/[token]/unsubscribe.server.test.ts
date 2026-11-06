import { beforeEach, describe, expect, it, vi } from 'vitest';

// The page and its action against a database double: proves that reading never unsubscribes and
// what each answer becomes. The SQL suite proves the scope and permanence of the suppression.
const mocks = vi.hoisted(() => ({ createSupabaseAdminClient: vi.fn(), rpc: vi.fn() }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseAdminClient: mocks.createSupabaseAdminClient }));

const { load, actions } = await import('./+page.server');

const TOKEN = 'b'.repeat(64);

beforeEach(() => {
	vi.clearAllMocks();
	mocks.createSupabaseAdminClient.mockResolvedValue({ rpc: mocks.rpc });
	vi.spyOn(console, 'error').mockImplementation(() => {});
});

describe('baja de correos', () => {
	it('abrir el enlace sólo lee: los lectores automáticos de correo no dan de baja a nadie', async () => {
		mocks.rpc.mockResolvedValue({ data: { business_name: 'Consultorio de prueba', unsubscribed: false }, error: null });
		const setHeaders = vi.fn();
		const data = await load({ params: { token: TOKEN }, setHeaders } as never);
		expect(data).toEqual({ available: true, businessName: 'Consultorio de prueba', unsubscribed: false });
		expect(mocks.rpc.mock.calls).toEqual([['get_email_unsubscribe', { p_token: TOKEN }]]);
		expect(setHeaders).toHaveBeenCalledWith(expect.objectContaining({ 'cache-control': 'no-store', 'referrer-policy': 'no-referrer' }));
		expect(setHeaders.mock.calls[0][0]['x-robots-tag']).toContain('noindex');
	});

	it('un enlace vencido o desconocido no revela de qué consultorio era', async () => {
		mocks.rpc.mockResolvedValue({ data: null, error: null });
		expect(await load({ params: { token: TOKEN }, setHeaders: vi.fn() } as never)).toEqual({ available: false, unavailableReason: 'expired' });
	});

	it('una falla de lectura se distingue de un enlace vencido', async () => {
		mocks.rpc.mockResolvedValue({ data: null, error: { message: 'unavailable' } });
		expect(await load({ params: { token: TOKEN }, setHeaders: vi.fn() } as never)).toEqual({ available: false, unavailableReason: 'error' });
	});

	it('sólo el envío explícito da de baja', async () => {
		mocks.rpc.mockResolvedValue({ data: { business_name: 'Consultorio de prueba', unsubscribed: true }, error: null });
		const result = await actions.default({ params: { token: TOKEN } } as never);
		expect(result).toEqual({ done: true, businessName: 'Consultorio de prueba', unsubscribed: true });
		expect(mocks.rpc.mock.calls).toEqual([['apply_email_unsubscribe', { p_token: TOKEN }]]);
	});

	it('si no se pudo registrar, lo dice y deja reintentar', async () => {
		mocks.rpc.mockResolvedValue({ data: null, error: { message: 'unavailable' } });
		const result = await actions.default({ params: { token: TOKEN } } as never);
		expect(result).toMatchObject({ status: 400, data: { message: expect.stringContaining('No pudimos registrar tu pedido') } });
	});
});
