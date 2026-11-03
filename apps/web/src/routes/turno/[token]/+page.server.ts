import { createPatientManagementPage } from '$lib/server/scheduling/public/patient-management-page';
const page = createPatientManagementPage(true);
export const load = page.load;
export const actions = page.actions;
