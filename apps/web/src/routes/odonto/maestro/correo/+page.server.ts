import { error, fail, redirect } from '@sveltejs/kit';
import type { RequestEvent } from '@sveltejs/kit';
import {
	EmailOperationsFormError,
	emailOperationWarnings,
	emailOperationsErrorKind,
	loadEmailOperations,
	parseCreditForm,
	parseSendingForm,
	saveEmailOperations,
	type EmailOperations
} from '$lib/server/integrations/public/email-operations';
import { readBoundedBookingForm } from '$lib/server/platform/form-data';
import { logServerFailure } from '$lib/server/platform/logging';
import { createSupabaseAdminClient, isMasterEmail } from '$lib/server/platform/supabase';
import type { Actions, PageServerLoad } from './$types';

// Only the operator's verified account; the SQL functions additionally admit only the backend.
async function masterContext(event: RequestEvent) {
	const user = event.locals.verifiedUser;
	if (!event.locals.auth || !user) throw redirect(303, '/login');
	if (!isMasterEmail(user.email)) error(403, 'Tu usuario no puede administrar los correos de Cita Suite.');
	return { user, admin: await createSupabaseAdminClient('odonto', event.fetch) };
}

export const load: PageServerLoad = async (event) => {
	const { admin } = await masterContext(event);
	try {
		const ops = await loadEmailOperations(admin);
		return { ops, warnings: emailOperationWarnings(ops, new Date()) };
	} catch (cause) {
		logServerFailure('Error cargando la operación de correos', cause);
		error(503, 'No pudimos consultar el estado de los correos. Volvé a intentar.');
	}
};

const save = async (event: RequestEvent, form: 'sending' | 'credit') => {
	const { user, admin } = await masterContext(event);
	const body = await readBoundedBookingForm(event.request);
	let current: EmailOperations;
	try {
		current = await loadEmailOperations(admin);
	} catch (cause) {
		logServerFailure('Error cargando la operación de correos', cause);
		return fail(503, { form, message: 'No pudimos consultar el estado actual. No se guardó nada; volvé a intentar.' });
	}
	let change;
	try {
		change = form === 'sending' ? parseSendingForm(body, current) : parseCreditForm(body, current);
	} catch (cause) {
		if (cause instanceof EmailOperationsFormError) return fail(400, { form, message: cause.message });
		throw cause;
	}
	try {
		await saveEmailOperations(admin, user.id, change);
	} catch (cause) {
		const kind = emailOperationsErrorKind(cause);
		if (kind === 'changed') return fail(409, { form, message: 'Otra persona cambió esta configuración. Recargá para ver los valores actuales antes de guardar.' });
		if (kind === 'invalid') return fail(400, { form, message: 'Revisá los valores: alguno no es válido.' });
		logServerFailure('Error guardando la operación de correos', cause);
		return fail(503, { form, message: 'No pudimos confirmar el cambio. Recargá para comprobar si se guardó antes de repetirlo.' });
	}
	return { form, saved: true, message: form === 'sending' ? 'Se guardó la configuración del envío.' : 'Se registró el crédito.' };
};

export const actions: Actions = {
	sending: (event) => save(event, 'sending'),
	credit: (event) => save(event, 'credit')
};
