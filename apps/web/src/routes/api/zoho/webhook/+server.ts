import { env } from '$env/dynamic/private';
import { json } from '@sveltejs/kit';
import { parseZohoEmailEvents, verifyZohoSignature, zohoSignedPayload } from '$lib/server/integrations/public/zoho-email';
import { readBoundedBytes } from '$lib/server/platform/form-data';
import { logServerFailure, logServerWarning } from '$lib/server/platform/logging';
import { createSupabaseAdminClient } from '$lib/server/platform/supabase';
import type { RequestHandler } from './$types';

// Notifications are small. A bound keeps an unauthenticated caller from making the Worker read more.
const ZOHO_WEBHOOK_MAX_BODY_BYTES = 64 * 1024;

// Answers a plain visit. The panel verifies the URL with a POST, handled below.
export const GET: RequestHandler = () => json({ ok: true });

// Receipts are stored before answering success, so a repeated notification changes nothing and a
// failed store is retried by the provider. Only a valid signature reaches the base.
export const POST: RequestHandler = async ({ request }) => {
	const key = env.ZOHO_CPAAS_WEBHOOK_KEY?.trim();
	if (!key) return json({ ok: false }, { status: 503 });
	const bytes = await readBoundedBytes(request, ZOHO_WEBHOOK_MAX_BODY_BYTES);
	if (!bytes) return json({ ok: false }, { status: 413 });
	const raw = new TextDecoder().decode(bytes);
	// The panel verifies the URL with an unsigned sample and accepts only a 200, and it offers the key
	// only once the webhook exists. So an unsigned request is answered with a 200 and never stored.
	if (!request.headers.get('producer-signature')) {
		if (raw.trim()) logServerWarning('Notificación de correo sin firma: no se guarda');
		return json({ ok: true });
	}
	const payload = zohoSignedPayload(raw);
	if (payload === null || !(await verifyZohoSignature(request.headers.get('producer-signature'), payload, key))) {
		logServerWarning('Notificación de correo sin firma válida');
		return json({ ok: false }, { status: 401 });
	}
	let parsed: unknown;
	try {
		parsed = JSON.parse(payload);
	} catch {
		logServerWarning('Notificación de correo ilegible');
		return json({ ok: true });
	}
	const events = parseZohoEmailEvents(parsed);
	if (!events.length) logServerWarning('Notificación de correo sin eventos reconocibles');
	try {
		const supabase = await createSupabaseAdminClient('odonto');
		for (const event of events) {
			const { error } = await supabase.rpc('record_email_provider_event', {
				p_webhook_request_id: event.webhookRequestId,
				p_client_reference: event.clientReference ?? '',
				p_event: event.event,
				...(event.occurredAt ? { p_occurred_at: event.occurredAt } : {})
			});
			if (error) throw error;
		}
	} catch (cause) {
		logServerFailure('email.webhook_store_failed', cause);
		return json({ ok: false }, { status: 500 });
	}
	return json({ ok: true });
};
