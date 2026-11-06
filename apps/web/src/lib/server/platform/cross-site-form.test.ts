import { describe, expect, it } from 'vitest';
import { isForbiddenCrossSiteForm } from './cross-site-form';

const origin = 'https://app.cita-suite.com.ar';
const post = (path: string, headers: Record<string, string>, method = 'POST') =>
	isForbiddenCrossSiteForm(new Request(origin + path, { method, headers }), new URL(origin + path));
const form = 'application/x-www-form-urlencoded';

describe('cross-site form protection', () => {
	it('rejects a form from another site or without an origin, for every write method', () => {
		for (const method of ['POST', 'PUT', 'PATCH', 'DELETE']) {
			expect(post('/odonto/agenda', { 'content-type': form, origin: 'https://evil.example' }, method)).toBe(true);
			expect(post('/odonto/agenda', { 'content-type': form }, method)).toBe(true);
		}
		expect(post('/login', { 'content-type': 'multipart/form-data; boundary=x', origin: 'https://evil.example' })).toBe(true);
		expect(post('/login', { 'content-type': 'TEXT/PLAIN; charset=utf-8' })).toBe(true);
	});

	it('accepts the same origin, reads and non-form bodies', () => {
		expect(post('/odonto/agenda', { 'content-type': form, origin })).toBe(false);
		expect(isForbiddenCrossSiteForm(new Request(origin + '/x'), new URL(origin + '/x'))).toBe(false);
		expect(post('/api/mercadopago/webhook', { 'content-type': 'application/json' })).toBe(false);
	});

	it('makes an exception only for the exact self-authenticated routes', () => {
		const token = 'a'.repeat(64);
		expect(post('/api/zoho/webhook', { 'content-type': form })).toBe(false);
		expect(post(`/correo/baja/${token}`, { 'content-type': form })).toBe(false);
		for (const path of ['/api/zoho/webhook/x', '/api/zoho', '/correo/baja/abc', `/correo/baja/${token}/x`, `/correo/baja/${'A'.repeat(64)}`])
			expect(post(path, { 'content-type': form })).toBe(true);
	});
});
