import { createPatientPushHandlers } from '$lib/server/integrations/public/patient-push';
const handlers = createPatientPushHandlers(false);
export const POST = handlers.POST;
export const GET = handlers.GET;
export const PATCH = handlers.PATCH;
