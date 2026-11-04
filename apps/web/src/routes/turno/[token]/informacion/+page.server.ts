import { createPublicInformationPage } from '$lib/server/patients/public/booking-information-page';
const page = createPublicInformationPage(true);
export const load = page.load;
export const actions = page.actions;
