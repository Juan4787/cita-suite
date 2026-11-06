import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
	createSupabaseAdminClient: vi.fn(),
	getEmailFromAccessToken: vi.fn(),
	getUserIdFromAccessToken: vi.fn(),
	listUsers: vi.fn()
}));

vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({
	createSupabaseAdminClient: mocks.createSupabaseAdminClient,
	getEmailFromAccessToken: mocks.getEmailFromAccessToken,
	getUserIdFromAccessToken: mocks.getUserIdFromAccessToken,
	isMasterEmail: (email?: string | null) => email === 'master@example.test'
}));

const { load } = await import('./+page.server');

// A query builder: every chained call returns it, and awaiting it gives `result`.
const query = (result: unknown) => {
	const builder: object = new Proxy({}, {
		get: (_target, key) =>
			key === 'then'
				? (resolve: (value: unknown) => unknown, reject: (reason: unknown) => unknown) => Promise.resolve(result).then(resolve, reject)
				: () => builder
	});
	return builder;
};

const failure = { data: null, error: { code: '57014', message: 'canceling statement due to statement timeout' } };

// The email operations of the operator: an expired credit, so the panel must warn about it.
const emailOperations = { revision: 1, producer_enabled: true, producer_enabled_at: '2026-11-06T10:00:00Z', paused_until: null, pause_reason: null,
	daily_limit: 100, daily_reserve: 10, used_24h: 0, credit_messages: 10000, credit_started_at: '2026-01-01T03:00:00Z',
	credit_expires_at: '2026-02-01T02:59:59Z', credit_used: 0, uncertain: 0, failed_7d: 0, senders: [] };

const tables = (overrides: Record<string, unknown> = {}, rpc: { data: unknown; error: unknown } = { data: emailOperations, error: null }) => {
	mocks.createSupabaseAdminClient.mockResolvedValue({
		from: (table: string) => query(overrides[table] ?? { data: [], error: null }),
		rpc: async () => rpc,
		auth: { admin: { listUsers: mocks.listUsers } }
	});
};

const event = (verifiedEmail: string) =>
	({
		locals: { auth: { access_token: 'test-token' }, verifiedUser: { id: 'user-1', email: verifiedEmail } },
		fetch: vi.fn()
	}) as never;

describe('master panel load', () => {
	beforeEach(() => {
		vi.clearAllMocks();
		mocks.getEmailFromAccessToken.mockReturnValue('master@example.test');
		mocks.getUserIdFromAccessToken.mockReturnValue('user-1');
		mocks.listUsers.mockResolvedValue({ data: { users: [] }, error: null });
	});

	it('opens for the master identity Auth verified, not for a token that only claims it', async () => {
		tables();
		await expect(load(event('professional@example.test'))).rejects.toMatchObject({ status: 303 });
	});

	it('fails explicitly instead of listing the practices without their commercial state', async () => {
		tables({ business_subscriptions: failure });
		const result = (await load(event('master@example.test'))) as { loadError: string | null };
		expect(result.loadError).toBeTruthy();
	});

	it('warns the operator about the email credit without opening the tools', async () => {
		tables();
		const result = (await load(event('master@example.test'))) as { emailWarnings: { level: string; message: string }[] | null };
		expect(result.emailWarnings).toEqual([{ level: 'critical', message: expect.stringContaining('El crédito venció el 31 de enero de 2026') }]);
	});

	it('a failure reading the email operations does not hide the panel', async () => {
		const log = vi.spyOn(console, 'error').mockImplementation(() => {});
		tables({}, { data: null, error: { message: 'unavailable' } });
		const result = (await load(event('master@example.test'))) as { emailWarnings: unknown; loadError: string | null };
		expect(result).toMatchObject({ emailWarnings: null, loadError: null });
		log.mockRestore();
	});

	it('fails explicitly instead of listing the accounts without their emails', async () => {
		tables();
		mocks.listUsers.mockResolvedValue({ data: null, error: { message: 'Auth unavailable' } });
		const result = (await load(event('master@example.test'))) as { loadError: string | null };
		expect(result.loadError).toBeTruthy();
	});
});
