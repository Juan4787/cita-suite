import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import { layoutIssues } from './helpers/layout-usability';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { chooseTheme, contrastViolations, expectRenderedTheme } from './helpers/theme';

// The two routes other servers post to, and the check they are excepted from. That check runs only
// in a production build, so the refusals are asserted on the packaged release. No provider is
// contacted, and no mail is sent.
type Fixture = ReturnType<typeof ownedAppointmentFixture>;

const issueToken = (f: Fixture, email: string) => {
	const token = randomBytes(32).toString('hex');
	const hash = createHash('sha256').update(token).digest('hex');
	f.sql(`insert into private.email_unsubscribe_tokens(token_hash,business_id,email_normalized,expires_at)
	 values('${hash}',:'business'::uuid,'${email}',now()+interval '1 day');`);
	return token;
};
const suppressions = (f: Fixture, email: string) =>
	f.sql(`select count(*) from private.email_suppressions where business_id=:'business'::uuid and email_normalized='${email}' and reason='unsubscribe' and lifted_at is null;`);

test('@candidate-behavior email routes: reading never unsubscribes, posts from other servers work and the exception stays exact', async ({ page, browser, request }, info) => {
	test.setTimeout(120_000);
	const f = ownedAppointmentFixture();
	const nativeEmail = `unsubscribe-native-${randomUUID()}@example.test`;
	const oneClickEmail = `unsubscribe-oneclick-${randomUUID()}@example.test`;
	const origin = new URL(process.env.E2E_BASE_URL ?? '').origin;
	try {
		const token = issueToken(f, nativeEmail);
		const path = `/correo/baja/${token}`;

		// A mail scanner follows the link: opening it changes nothing.
		const scanned = await request.get(path, { headers: { 'user-agent': 'Googlebot' } });
		expect(scanned.status()).toBe(200);
		expect(scanned.headers()['cache-control']).toContain('no-store');
		expect(scanned.headers()['x-robots-tag']).toContain('noindex');
		expect(suppressions(f, nativeEmail)).toBe('0');

		for (const theme of ['light', 'dark'] as const) {
			await page.setViewportSize({ width: 320, height: 800 });
			await page.goto(origin + path);
			await chooseTheme(page, theme);
			await page.reload();
			await expect(page.getByRole('heading', { name: '¿Dejar de recibir estos correos?' })).toBeVisible();
			await expectRenderedTheme(page, theme);
			expect((await contrastViolations(page)).violations).toEqual([]);
			expect(await layoutIssues(page, 'main button:visible', 'main')).toEqual([]);
			await page.screenshot({ path: info.outputPath(`baja-${theme}-320.jpg`), type: 'jpeg', quality: 60 });
		}
		expect(suppressions(f, nativeEmail)).toBe('0');

		// Without JavaScript the page's own form still works, under its no-referrer policy.
		const native = await browser.newContext({ javaScriptEnabled: false, baseURL: origin });
		try {
			const nativePage = await native.newPage();
			await nativePage.goto(path);
			await nativePage.getByRole('button', { name: 'Sí, dejar de recibirlos', exact: true }).click();
			await expect(nativePage.getByRole('status')).toContainText('No vas a recibir más correos');
		} finally {
			await native.close();
		}
		expect(suppressions(f, nativeEmail)).toBe('1');

		// One-click removal (RFC 8058): the mail provider's server posts, with no Origin at all.
		const oneClick = await request.post(`/correo/baja/${issueToken(f, oneClickEmail)}`, { form: { 'List-Unsubscribe': 'One-Click' } });
		expect(oneClick.status()).toBe(200);
		expect(suppressions(f, oneClickEmail)).toBe('1');

		// The provider's webhook reaches its own handler, which here has no key to accept anything.
		const webhook = await request.post('/api/zoho/webhook', { form: { payload: '{}' } });
		expect(webhook.status()).toBe(503);

		// The exception is exact: any other path and any other site are still refused. The development
		// server has no origin check, so only the packaged release can prove this.
		if (process.env.CITA_RELEASE_ARTIFACT) {
			for (const refused of [
				await request.post('/odonto/agenda?/create_appointment', { form: { a: '1' } }),
				await request.post('/odonto/agenda?/create_appointment', { headers: { origin: 'https://otro-sitio.example' }, form: { a: '1' } }),
				await request.post(`${path}/otra`, { form: { a: '1' } }),
				await request.post('/api/zoho/webhook/otra', { form: { a: '1' } })
			]) {
				expect(refused.status()).toBe(403);
				expect(await refused.text()).toBe('Cross-site POST form submissions are forbidden');
			}
		}
	} finally {
		f.sql(`begin;
		 delete from private.email_suppressions where business_id=:'business'::uuid and email_normalized in ('${nativeEmail}','${oneClickEmail}');
		 delete from private.email_unsubscribe_tokens where business_id=:'business'::uuid and email_normalized in ('${nativeEmail}','${oneClickEmail}');
		 commit;`);
	}
});
