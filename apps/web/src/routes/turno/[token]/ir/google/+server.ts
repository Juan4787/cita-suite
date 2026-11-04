import { createPatientCalendarOpening } from '$lib/server/integrations/public/patient-calendar-openings';
export const GET = createPatientCalendarOpening(true, 'google');
