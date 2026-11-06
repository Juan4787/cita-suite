import { fail } from '@sveltejs/kit';
import { readBoolean, readRecord, readText } from '$lib/contracts/json';
import { logServerFailure } from '$lib/server/platform/logging';
import { createSupabaseAdminClient } from '$lib/server/platform/supabase';
import type { Actions, PageServerLoad } from './$types';

const readUnsubscribe = (value: unknown) => {
	const row = readRecord(value, 'email.unsubscribe');
	return { businessName: readText(row.business_name, 'email.unsubscribe.business'), unsubscribed: readBoolean(row.unsubscribed, 'email.unsubscribe.state') };
};

// Opening this page changes nothing: mail scanners follow links. Only the POST below unsubscribes.
export const load: PageServerLoad = async ({ params, setHeaders }) => {
	setHeaders({ 'cache-control': 'no-store', 'referrer-policy': 'no-referrer', 'x-robots-tag': 'noindex, nofollow, noarchive' });
	const supabase = await createSupabaseAdminClient('odonto');
	const { data, error } = await supabase.rpc('get_email_unsubscribe', { p_token: params.token });
	if (error) {
		logServerFailure('email.unsubscribe_read_failed', error);
		return { available: false as const, unavailableReason: 'error' as const };
	}
	if (data === null) return { available: false as const, unavailableReason: 'expired' as const };
	return { available: true as const, ...readUnsubscribe(data) };
};

// Also the target of one-click unsubscribe, which mail clients post from their servers.
export const actions: Actions = {
	default: async ({ params }) => {
		const supabase = await createSupabaseAdminClient('odonto');
		const { data, error } = await supabase.rpc('apply_email_unsubscribe', { p_token: params.token });
		if (error) {
			logServerFailure('email.unsubscribe_failed', error);
			return fail(400, { message: 'No pudimos registrar tu pedido. Volvé a intentar o respondé uno de los correos del consultorio.' });
		}
		return { done: true, ...readUnsubscribe(data) };
	}
};
