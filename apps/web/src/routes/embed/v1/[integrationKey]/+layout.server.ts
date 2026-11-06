import { FORM_PAGE_REFERRER_POLICY } from '$lib/server/platform/cross-site-form';
import { resolveBookingIntegrationRequest } from '$lib/server/sites/public/booking-integration-request';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async (event) => {
	event.setHeaders({ 'referrer-policy': FORM_PAGE_REFERRER_POLICY });
	const { embed } = await resolveBookingIntegrationRequest(event);
	return { embed };
};
