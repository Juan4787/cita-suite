import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createFixtureClient } from './fixture-db';

export function ownedAppointmentFixture() {
	const path = process.env.E2E_LOCAL_BOOKING_FIXTURE_PATH;
	const api = process.env.ODONTO_SUPABASE_URL;
	const key = process.env.ODONTO_SUPABASE_SERVICE_ROLE_KEY;
	const businessId = process.env.CITA_SUITE_TEST_BUSINESS_ID;
	const email = process.env.E2E_EMAIL;
	const password = process.env.E2E_PASSWORD;
	if (process.env.CITA_E2E_ENVIRONMENT !== 'disposable' || !path || !api || !key || !businessId || !email || !password || new URL(api).hostname !== '127.0.0.1') {
		throw new Error('The deposit audit requires the explicit owned disposable environment.');
	}
	const runtime: unknown = JSON.parse(readFileSync(path, 'utf8'));
	if (typeof runtime !== 'object' || runtime === null || !('container' in runtime) || typeof runtime.container !== 'string' ||
		!/^cita-booking-test-[a-f0-9]{12}$/.test(runtime.container) || !('businessId' in runtime) || runtime.businessId !== businessId ||
		!('key' in runtime) || typeof runtime.key !== 'string' || !/^[a-f0-9]{32}$/.test(runtime.key)) {
		throw new Error('The prepared fixture identity does not match the deposit audit.');
	}
	const container = runtime.container;
	const sql = (source: string, variables: Record<string, string> = {}) => {
		const result = spawnSync('docker', ['exec', '-i', container, 'psql', '-X', '-U', 'supabase_admin', '-d', 'postgres',
			'-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose', '-qAt', '-v', `business=${businessId}`,
			...Object.entries(variables).flatMap(([name, value]) => ['-v', `${name}=${value}`])], {
			input: "set statement_timeout='10s';\n" + source,
			encoding: 'utf8', timeout: 20_000
		});
		if (result.error || result.status !== 0) {
			// Retain only bounded diagnostic metadata, never SQL text, row values,
			// connection arguments or a raw provider/error message in public CI.
			const diagnostic = typeof result.stderr === 'string' ? result.stderr : '';
			const state = /(?:^|\n)ERROR:\s+([A-Z0-9]{5}):/.exec(diagnostic)?.[1] ?? 'unknown';
			const constraint = /CONSTRAINT NAME:\s+([a-z0-9_]{1,128})(?:\s|$)/.exec(diagnostic)?.[1] ?? 'none';
			const reason = /(?:^|\n)ERROR:\s+[A-Z0-9]{5}:\s+([A-Z][A-Z0-9_]{1,100})(?:\s|$)/.exec(diagnostic)?.[1] ?? 'none';
			const line = /(?:^|\n)LINE (\d{1,5}):/.exec(diagnostic)?.[1] ?? 'unknown';
			const routine = /(?:^|\n)CONTEXT:\s+PL\/pgSQL function ([a-z0-9_.]{1,128})(?:\(|\s)/.exec(diagnostic)?.[1] ?? 'unknown';
			const phase = [...result.stdout.matchAll(/(?:^|\n)CITA_FIXTURE_PHASE ([a-z_]{1,80})(?:\r?\n|$)/g)].at(-1)?.[1] ?? 'unknown';
			throw new Error(`Owned deposit SQL failed (state=${state}, constraint=${constraint}, reason=${reason}, line=${line}, routine=${routine}, phase=${phase}); no credentials or row values are logged.`);
		}
		return result.stdout.trim();
	};
	return { admin: createFixtureClient(api, key), businessId, integrationKey: runtime.key, email, password, sql };
}

