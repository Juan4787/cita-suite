// SvelteKit's own check runs before any hook and has no per-route exception, and two entry points
// are legitimately posted by other servers without an Origin: the provider's webhook and the mail
// client's one-click unsubscribe (RFC 8058). So the framework check is off and this one replaces it,
// with the same rule for everything else. Each exception authenticates itself: a signature, a token.
const FORM_CONTENT_TYPES = new Set(['application/x-www-form-urlencoded', 'multipart/form-data', 'text/plain']);
const WRITE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

const selfAuthenticated = (pathname: string) =>
	pathname === '/api/zoho/webhook' || /^\/correo\/baja\/[0-9a-f]{64}$/.test(pathname);

/**
 * For pages with forms whose address must not reach other sites, like a capability link. With
 * `no-referrer` a browser sends `Origin: null` on a native form post, which this check refuses, so
 * the form would work only with JavaScript. `same-origin` also sends nothing to other sites and
 * keeps the real origin on our own posts. Responses without forms can stay `no-referrer`.
 */
export const FORM_PAGE_REFERRER_POLICY = 'same-origin';

export const isForbiddenCrossSiteForm = (request: Request, url: URL): boolean => {
	if (!WRITE_METHODS.has(request.method)) return false;
	const contentType = (request.headers.get('content-type') ?? '').split(';', 1)[0]?.trim().toLowerCase() ?? '';
	if (!FORM_CONTENT_TYPES.has(contentType)) return false;
	if (request.headers.get('origin') === url.origin) return false;
	return !selfAuthenticated(url.pathname);
};
