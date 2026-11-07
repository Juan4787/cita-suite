import type { APIResponse } from '@playwright/test';

// wrangler's proxy answers this by itself, without reaching the worker, when a POST finds a connection already closed.
// Its comparison only matches the root path, so the text says «restarted» even if nothing restarted. Production has no such proxy.
const DEV_PROXY_ANSWER = 'Your worker restarted mid-request.';

/** Sends again only that answer: the first attempt never reached the application, so nothing can run twice. */
export async function pastDevProxy(send: () => Promise<APIResponse>) {
	const response = await send();
	if (response.status() !== 503 || !(await response.text()).startsWith(DEV_PROXY_ANSWER)) return response;
	return send();
}
