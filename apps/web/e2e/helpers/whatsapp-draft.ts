import { expect, type BrowserContext, type Locator, type Route } from '@playwright/test';

/** The form opens a new tab and the server answers with a redirect to WhatsApp, which Playwright cannot route.
 * So the tab stops at that answer: the destination is read and WhatsApp itself is never contacted. */
export async function whatsappDraft(context: BrowserContext, button: Locator) {
	let destination: string | undefined;
	const stopAtRedirect = async (route: Route) => {
		const request = route.request();
		if (request.method() !== 'POST' || !request.isNavigationRequest()) return route.fallback();
		// The packaged release sets Secure cookies, and the request API leaves them out on plain HTTP.
		const cookie = (await context.cookies()).map(({ name, value }) => `${name}=${value}`).join('; ');
		const answer = await route.fetch({ headers: { ...request.headers(), cookie }, maxRedirects: 0 });
		destination = answer.headers().location;
		await route.fulfill({ status: 200, contentType: 'text/html', body: '<h1>Preparación comprobada. No se envió ningún mensaje.</h1>' });
	};
	await context.route('**/*', stopAtRedirect);
	try {
		const opened = context.waitForEvent('page');
		await button.click();
		const tab = await opened;
		await expect.poll(() => destination, { message: 'The form must answer with the WhatsApp address' }).toMatch(/^https:\/\/(?:wa\.me|web\.whatsapp\.com)\//);
		await tab.close();
		return new URL(destination!);
	} finally {
		await context.unroute('**/*', stopAtRedirect);
	}
}
