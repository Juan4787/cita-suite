import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
	loadAppointmentForManagementAccess: vi.fn(),
	createGoogleCalendarAuthorizationUrl: vi.fn()
}));
vi.mock('$lib/server/scheduling/public/appointment-token', () => ({
	loadAppointmentForManagementAccess: mocks.loadAppointmentForManagementAccess
}));
vi.mock('$lib/server/integrations/public/google-calendar', () => ({
	createGoogleCalendarAuthorizationUrl: mocks.createGoogleCalendarAuthorizationUrl
}));

const { GET } = await import('./+server');
const {createPatientGoogleCalendarConnect}=await import('$lib/server/integrations/public/patient-google-calendar');
const token='a'.repeat(64);
const client={rpc:vi.fn().mockResolvedValue({data:true,error:null})};

const callGet = (url = 'https://app.test/turno/token/google-calendar/connect') =>
	GET({
		params: { token }, getClientAddress:()=> '192.0.2.2',
		fetch: vi.fn(),
		url: new URL(url)
	} as unknown as Parameters<typeof GET>[0]);

beforeEach(() => {
	vi.clearAllMocks(); client.rpc.mockResolvedValue({data:true,error:null});
	mocks.loadAppointmentForManagementAccess.mockResolvedValue({
		appointment: { id: 'appointment', is_past: false },
		supabase: client,
		demo: false
	});
	mocks.createGoogleCalendarAuthorizationUrl.mockResolvedValue(
		'https://accounts.google.com/o/oauth2/v2/auth?state=opaque'
	);
});

describe('inicio público de Google Calendar', () => {
	it('sale del sitio únicamente hacia la URL OAuth creada por el servidor', async () => {
		const response = await callGet();
		expect(response.status).toBe(303);
		expect(response.headers.get('location')).toBe(
			'https://accounts.google.com/o/oauth2/v2/auth?state=opaque'
		);
		expect(response.headers.get('cache-control')).toBe('no-store');
		expect(mocks.createGoogleCalendarAuthorizationUrl).toHaveBeenCalledWith(
			client,
   {token,legacy:true},
			{ forceConsent: false }
		);
	});

	it('solo fuerza consentimiento después de una reconexión explícita', async () => {
		await callGet('https://app.test/turno/token/google-calendar/connect?reauthorize=1');
		expect(mocks.createGoogleCalendarAuthorizationUrl).toHaveBeenCalledWith(
			expect.anything(),
			expect.anything(),
			{ forceConsent: true }
		);
	});

	it('no inicia OAuth con un turno vencido, inexistente o de demostración', async () => {
		for (const context of [
			{ appointment: null, supabase: client, demo: false },
			{ appointment: { id: 'appointment', is_past: true }, supabase: client, demo: false },
			{ appointment: { id: 'appointment', is_past: false }, supabase: null, demo: true }
		]) {
			mocks.loadAppointmentForManagementAccess.mockResolvedValueOnce(context);
			const response = await callGet();
			expect(response.headers.get('location')).toBe(`/turno/${token}?calendar=unavailable`);
		}
		expect(mocks.createGoogleCalendarAuthorizationUrl).not.toHaveBeenCalled();
	});
 it('route owns the capability channel and rejects query attempts to switch it',async()=>{
  const event={params:{token},url:new URL(`https://app.test/gestion/${token}/google-calendar/connect?legacy=true`),fetch:vi.fn(),getClientAddress:()=> '192.0.2.3'};
  await createPatientGoogleCalendarConnect(false)(event as never);
  expect(mocks.loadAppointmentForManagementAccess).toHaveBeenCalledWith(event.fetch,{token,legacy:false});
  expect(mocks.createGoogleCalendarAuthorizationUrl).toHaveBeenCalledWith(client,{token,legacy:false},{forceConsent:false});
 });
 it('does not create an attempt after the rate limit is denied',async()=>{
  client.rpc.mockResolvedValue({data:false,error:null});await callGet();
  expect(mocks.createGoogleCalendarAuthorizationUrl).not.toHaveBeenCalled();
 });

});
