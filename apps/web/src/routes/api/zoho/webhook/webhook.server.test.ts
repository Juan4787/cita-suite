import crypto from 'node:crypto';
import { beforeEach, describe, expect, it, vi } from 'vitest';

// The route with its real signature check, parser and body bound. Only the database is a double,
// so this proves what is stored and when the provider is told to retry; the real notification
// shape is confirmed separately with the panel's test send.
const envState = vi.hoisted(() => ({ privateEnv: {} as Record<string, string | undefined> }));
const mocks = vi.hoisted(() => ({ createSupabaseAdminClient: vi.fn(), rpc: vi.fn() }));

vi.mock('$env/dynamic/private', () => ({ env: envState.privateEnv }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseAdminClient: mocks.createSupabaseAdminClient }));

const { GET, POST } = await import('./+server');

const KEY = 'clave-de-webhook-de-prueba';
const REFERENCE = '0b6c6f3e-7f1d-4c55-9a39-2d8a5b0f1c11';
const URL_ = 'https://app.test/api/zoho/webhook';

const notification = (events = [{ object: 'delivered', time: '2026-11-06T10:00:00Z' }]) =>
	JSON.stringify({
		webhook_request_id: 'wh-1',
		event_name: ['email_delivered'],
		event_message: events.map((event) => ({
			email_info: { client_reference: REFERENCE },
			event_data: [{ object: event.object, details: [{ time: event.time }] }]
		}))
	});

const signature = (payload: string, key = KEY, ts = Date.now()) =>
	`ts=${ts};s=${encodeURIComponent(crypto.createHmac('sha256', key).update(payload).digest('base64'))};s-algorithm=HmacSHA256`;

const post = (body: string, headers: Record<string, string> = {}) =>
	POST({ request: new Request(URL_, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body }) } as never);

beforeEach(() => {
	vi.clearAllMocks();
	for (const key of Object.keys(envState.privateEnv)) delete envState.privateEnv[key];
	envState.privateEnv.ZOHO_CPAAS_WEBHOOK_KEY = KEY;
	mocks.rpc.mockResolvedValue({ data: { duplicate: false, outcome: 'delivered' }, error: null });
	mocks.createSupabaseAdminClient.mockResolvedValue({ rpc: mocks.rpc });
	vi.spyOn(console, 'warn').mockImplementation(() => {});
	vi.spyOn(console, 'error').mockImplementation(() => {});
});

describe('notificaciones de Zoho', () => {
	it('responde a la verificación del panel sin tocar la base', async () => {
		expect((await GET({} as never)).status).toBe(200);
		expect((await post('')).status).toBe(200);
		expect(mocks.createSupabaseAdminClient).not.toHaveBeenCalled();
	});

	it('guarda cada evento firmado antes de responder bien', async () => {
		const body = notification([{ object: 'delivered', time: '2026-11-06T10:00:00Z' }, { object: 'hardbounce', time: '2026-11-06T10:01:00Z' }]);
		const response = await post(body, { 'producer-signature': signature(body) });
		expect(response.status).toBe(200);
		expect(mocks.rpc.mock.calls).toEqual([
			['record_email_provider_event', { p_webhook_request_id: 'wh-1:0', p_client_reference: REFERENCE, p_event: 'delivered', p_occurred_at: '2026-11-06T10:00:00.000Z' }],
			['record_email_provider_event', { p_webhook_request_id: 'wh-1:1', p_client_reference: REFERENCE, p_event: 'hard_bounce', p_occurred_at: '2026-11-06T10:01:00.000Z' }]
		]);
	});

	it('acepta el mismo contenido enviado como formulario, con la firma sobre el JSON', async () => {
		const json = notification();
		// A literal `+` inside the JSON must survive: decoding the whole body first would break the signature.
		const withPlus = json.replace('wh-1', 'wh+1');
		const response = await post(`payload=${encodeURIComponent(withPlus)}`, {
			'content-type': 'application/x-www-form-urlencoded',
			'producer-signature': signature(withPlus)
		});
		expect(response.status).toBe(200);
		expect(mocks.rpc).toHaveBeenCalledWith('record_email_provider_event', expect.objectContaining({ p_webhook_request_id: 'wh+1:0' }));
	});

	it.each([
		['sin firma', () => ({})],
		['con otra clave', (body: string) => ({ 'producer-signature': signature(body, 'otra-clave') })],
		['con una firma vieja', (body: string) => ({ 'producer-signature': signature(body, KEY, Date.now() - 20 * 60 * 1000) })],
		['con otro algoritmo', (body: string) => ({ 'producer-signature': signature(body).replace('HmacSHA256', 'HmacSHA1') })]
	])('rechaza una notificación %s sin tocar la base', async (_label, headers) => {
		const body = notification();
		const response = await post(body, headers(body));
		expect(response.status).toBe(401);
		expect(mocks.createSupabaseAdminClient).not.toHaveBeenCalled();
	});

	it('rechaza un contenido firmado pero alterado', async () => {
		const body = notification();
		const response = await post(body.replace('delivered', 'hardbounce'), { 'producer-signature': signature(body) });
		expect(response.status).toBe(401);
		expect(mocks.rpc).not.toHaveBeenCalled();
	});

	it('pide reintentar si la base no guardó el evento', async () => {
		mocks.rpc.mockResolvedValue({ data: null, error: { message: 'unavailable' } });
		const body = notification();
		const response = await post(body, { 'producer-signature': signature(body) });
		expect(response.status).toBe(500);
	});

	it('no lee más de lo que una notificación necesita', async () => {
		const body = 'x'.repeat(65 * 1024);
		const response = await post(body, { 'producer-signature': signature(body) });
		expect(response.status).toBe(413);
		expect(mocks.createSupabaseAdminClient).not.toHaveBeenCalled();
	});

	it('sin clave configurada no acepta nada', async () => {
		delete envState.privateEnv.ZOHO_CPAAS_WEBHOOK_KEY;
		const body = notification();
		const response = await post(body, { 'producer-signature': signature(body) });
		expect(response.status).toBe(503);
		expect(mocks.createSupabaseAdminClient).not.toHaveBeenCalled();
	});

	it('da por recibida una notificación auténtica pero ilegible, para que no se repita en vano', async () => {
		const body = '{"webhook_request_id": ';
		const response = await post(body, { 'producer-signature': signature(body) });
		expect(response.status).toBe(200);
		expect(mocks.rpc).not.toHaveBeenCalled();
	});
});
