import { expect, test } from '@playwright/test';
import { observeRenderHealth, pageErrorCollector } from './helpers/render-health';
import { fixtureRealtimeDiagnostic } from './helpers/realtime-diagnostics';

// Firefox says «interrupted» for a native close while connecting, the same words it uses when a page is left.
const nativeCloseMessage = (text: string, apiOrigin: string) =>
	['fixture-realtime-cancelled', 'fixture-realtime-interrupted'].includes(fixtureRealtimeDiagnostic(text, 'disposable', apiOrigin) ?? '');

async function openSocketProbe(page: import('@playwright/test').Page) {
	// A generated document on our own origin: no application code, login layout,
	// Supabase SDK or navigation lifecycle can cause the warning under study.
	await page.route('**/__e2e__/render-health', (route) => route.fulfill({
		status: 200, contentType: 'text/html',
		body: '<!doctype html><title>Socket lifecycle probe</title><main>Native socket diagnostic</main>'
	}));
	await page.goto('/__e2e__/render-health');
	await expect(page.getByRole('main')).toBeVisible();
}

test.describe('render health socket evidence', () => {
	test.beforeEach(() => {
		if (process.env.CITA_E2E_ENVIRONMENT !== 'disposable') throw new Error('Requires the owned disposable fixture.');
	});

	test('a native close in the already loaded document is observed without requiring another navigation', async ({ page }, info) => {
		const api = new URL(process.env.PUBLIC_ODONTO_SUPABASE_URL ?? '');
		await openSocketProbe(page);
		const health = await observeRenderHealth(page);
		const warning = page.waitForEvent('console', {
			predicate: message => nativeCloseMessage(message.text(), api.origin)
		});
		const beforeClose = await page.evaluate(async socketUrl => {
			const socket = new WebSocket(socketUrl);
			const closed = new Promise<void>(resolve => socket.addEventListener('close', () => resolve(), { once: true }));
			const before = socket.readyState; socket.close(); await closed; return before;
		}, api.origin.replace('http:', 'ws:') + '/realtime/v1/websocket');
		expect(beforeClose).toBe(0); await warning;
		const report = await health.assertAndAttach(info, 'current-document-native-close-render-health');
		expect(report.fixtureSocketCloseStates[0]).toBe(1);
	});

	test('a style refused during a capture does not count, and one refused outside it still does', async ({ page }, info) => {
		await page.route('**/__e2e__/render-health-policy', (route) => route.fulfill({
			status: 200, contentType: 'text/html', headers: { 'content-security-policy': "style-src 'self'" },
			body: '<!doctype html><title>Style policy probe</title><main>Style policy diagnostic</main>'
		}));
		await page.goto('/__e2e__/render-health-policy');
		const health = await observeRenderHealth(page);
		await page.screenshot();
		await health.duringCapture(() => page.getByRole('main').screenshot());
		await health.assertAndAttach(info, 'capture-style-render-health');
		const refused = page.waitForEvent('console', { predicate: (message) => message.type() === 'error' });
		await page.evaluate(() => {
			const style = document.createElement('style');
			style.textContent = 'main { color: red; }';
			document.head.append(style);
		});
		await refused;
		await expect(health.assertAndAttach(info, 'refused-style-render-health')).rejects.toThrow(/unclassified/);
	});

	test('a fetch refused while leaving only passes for the own origin', async ({ page, browserName }) => {
		const errors = pageErrorCollector();
		errors.watch(page);
		await openSocketProbe(page);
		await page.evaluate(() => addEventListener('pagehide', () => {
			void fetch('/__e2e__/refused').catch(() => {});
			void fetch('http://127.0.0.1:9/refused').catch(() => {});
		}));
		await page.goto('/__e2e__/render-health');
		await expect(page.getByRole('main')).toBeVisible();
		// Only WebKit refuses them, and it reports no request for either.
		expect(errors.unexpected()).toHaveLength(browserName === 'webkit' ? 1 : 0);
	});

	test('a forged cancellation in the current document still has no native evidence', async ({ page }, info) => {
		const api = new URL(process.env.PUBLIC_ODONTO_SUPABASE_URL ?? '');
		await openSocketProbe(page);
		const health = await observeRenderHealth(page);
		await page.evaluate(socketUrl => {
			console.warn(`WebSocket connection to '${socketUrl}' failed: WebSocket is closed before the connection is established.`);
		}, api.origin.replace('http:', 'ws:') + '/realtime/v1/websocket');
		await expect(health.assertAndAttach(info, 'current-document-forged-close-render-health')).rejects.toThrow(/observed native close/);
	});

	test('a native close while connecting emits the fixture warning without application code', async ({ page }, info) => {
		const api = new URL(process.env.PUBLIC_ODONTO_SUPABASE_URL ?? '');
		const health = await observeRenderHealth(page);
		await openSocketProbe(page);
		const warning = page.waitForEvent('console', {
			predicate: (message) => nativeCloseMessage(message.text(), api.origin)
		});
		const beforeClose = await page.evaluate(async (socketUrl) => {
			const socket = new WebSocket(socketUrl);
			const closed = new Promise<void>((resolve) => socket.addEventListener('close', () => resolve(), { once: true }));
			const before = socket.readyState;
			socket.close();
			await closed;
			return before;
		}, api.origin.replace('http:', 'ws:') + '/realtime/v1/websocket');
		expect(beforeClose).toBe(0);
		await warning;
		const report = await health.assertAndAttach(info, 'native-socket-close-render-health');
		expect(report.fixtureSocketCloseStates[0]).toBe(1);
	});

	test('a cancellation message with no observed native close cannot certify console health', async ({ page }, info) => {
		const api = new URL(process.env.PUBLIC_ODONTO_SUPABASE_URL ?? '');
		const health = await observeRenderHealth(page);
		await openSocketProbe(page);
		await page.evaluate((socketUrl) => {
			console.warn(`WebSocket connection to '${socketUrl}' failed: WebSocket is closed before the connection is established.`);
		}, api.origin.replace('http:', 'ws:') + '/realtime/v1/websocket');
		await expect(health.assertAndAttach(info, 'unobserved-socket-close-render-health')).rejects.toThrow(/observed native close/);
	});
});
