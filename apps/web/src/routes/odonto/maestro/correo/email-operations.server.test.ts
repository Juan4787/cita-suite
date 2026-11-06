import { beforeEach, describe, expect, it, vi } from 'vitest';

// The operator page with its real parsers and messages; the database is a double. Proves who may
// enter, what each form sends and that a stale or concurrent change is refused. The SQL suite
// appointment_email_operations.sql proves the guard, the counting and the audit row.
const mocks = vi.hoisted(() => ({ createSupabaseAdminClient: vi.fn(), rpc: vi.fn() }));
vi.mock('$lib/server/platform/supabase', () => ({
	createSupabaseAdminClient: mocks.createSupabaseAdminClient,
	isMasterEmail: (email?: string | null) => email === 'master@example.test'
}));

const { load, actions } = await import('./+page.server');

const ops = { revision: 7, producer_enabled: true, producer_enabled_at: '2026-11-06T10:00:00Z', paused_until: null, pause_reason: null,
	daily_limit: 100, daily_reserve: 10, used_24h: 2, credit_messages: 10000, credit_started_at: '2026-11-05T03:00:00Z',
	credit_expires_at: '2099-12-04T02:59:59Z', credit_used: 2, uncertain: 0, failed_7d: 0, senders: [] };
const event = (email: string, body?: Record<string, string>, action = 'sending') => ({
	locals: { auth: { access_token: 'token' }, verifiedUser: { id: 'operator-1', email } }, fetch: vi.fn(), url: new URL('https://app.test/odonto/maestro/correo'),
	request: new Request(`https://app.test/odonto/maestro/correo?/${action}`, { method: 'POST', body: new URLSearchParams(body ?? {}) })
}) as never;
const saves = () => mocks.rpc.mock.calls.filter(([name]) => name === 'operator_set_email_operations').map(([, args]) => args);

beforeEach(() => {
	vi.clearAllMocks();
	vi.spyOn(console, 'error').mockImplementation(() => {});
	mocks.rpc.mockImplementation(async () => ({ data: ops, error: null }));
	mocks.createSupabaseAdminClient.mockResolvedValue({ rpc: mocks.rpc });
});

describe('correo de los turnos, panel del operador', () => {
	it('sólo entra la cuenta del operador verificada', async () => {
		await expect(load(event('owner@example.test'))).rejects.toMatchObject({ status: 403 });
		await expect(actions.sending!(event('owner@example.test', { expected_revision: '7', daily_limit: '100' }))).rejects.toMatchObject({ status: 403 });
		expect(mocks.rpc).not.toHaveBeenCalled();
	});

	it('muestra el estado y sus avisos', async () => {
		const data = await load(event('master@example.test'));
		expect(data).toMatchObject({ ops: { revision: 7, credit: { messages: 10000, used: 2 } }, warnings: [] });
	});

	it('el envío guarda interruptor, límite y pausa, con el crédito vigente y la revisión de la pantalla', async () => {
		await expect(actions.sending!(event('master@example.test', { expected_revision: '7', daily_limit: '250', lift_pause: 'true' }))).resolves.toMatchObject({ saved: true });
		expect(saves()).toEqual([{ p_actor_id: 'operator-1', p_expected_revision: 7, p_producer_enabled: false, p_daily_limit: 250, p_credit_messages: 10000,
			p_credit_started_at: '2026-11-05T03:00:00Z', p_credit_expires_at: '2099-12-04T02:59:59Z', p_lift_pause: true }]);
	});

	it('un crédito nuevo no toca el envío', async () => {
		await expect(actions.credit!(event('master@example.test', { expected_revision: '7', credit_messages: '20000', credit_started_on: '2026-12-01', credit_expires_on: '2027-01-01' }, 'credit')))
			.resolves.toMatchObject({ saved: true, message: 'Se registró el crédito.' });
		expect(saves()).toEqual([{ p_actor_id: 'operator-1', p_expected_revision: 7, p_producer_enabled: true, p_daily_limit: 100, p_credit_messages: 20000,
			p_credit_started_at: '2026-12-01T00:00:00-03:00', p_credit_expires_at: '2027-01-01T23:59:59-03:00', p_lift_pause: false }]);
	});

	it('un formulario mal armado no llega a guardar', async () => {
		await expect(actions.credit!(event('master@example.test', { expected_revision: '7', credit_messages: 'muchos', credit_started_on: '2026-12-01', credit_expires_on: '2027-01-01' }, 'credit')))
			.resolves.toMatchObject({ status: 400, data: { form: 'credit' } });
		expect(saves()).toEqual([]);
	});

	it('un cambio ajeno se informa como tal y una falla pide comprobar antes de repetir', async () => {
		mocks.rpc.mockImplementation(async (name: string) => name === 'operator_set_email_operations'
			? { data: null, error: { message: 'EMAIL_OPERATIONS_CHANGED' } } : { data: ops, error: null });
		await expect(actions.sending!(event('master@example.test', { expected_revision: '6', daily_limit: '100' }))).resolves.toMatchObject({ status: 409 });
		mocks.rpc.mockImplementation(async (name: string) => name === 'operator_set_email_operations'
			? { data: null, error: { message: 'canceling statement due to statement timeout' } } : { data: ops, error: null });
		await expect(actions.sending!(event('master@example.test', { expected_revision: '7', daily_limit: '100' }))).resolves.toMatchObject({ status: 503 });
	});

	it('si no puede leer el estado actual, no guarda nada', async () => {
		mocks.rpc.mockResolvedValue({ data: null, error: { message: 'unavailable' } });
		await expect(actions.sending!(event('master@example.test', { expected_revision: '7', daily_limit: '100' }))).resolves.toMatchObject({ status: 503 });
		expect(saves()).toEqual([]);
	});
});
