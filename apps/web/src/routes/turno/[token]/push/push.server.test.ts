import { beforeEach, describe, expect, it, vi } from 'vitest';

const envState = vi.hoisted(() => ({
	privateEnv: {} as Record<string, string | undefined>
}));
const mocks = vi.hoisted(() => ({
	loadAppointmentForManagementAccess: vi.fn(),
	getLatestPushTestStatus: vi.fn(),
	getPushDeliveryStatus: vi.fn(),
	isPushConfigured: vi.fn(),
	isValidPushDeliveryId: vi.fn(),
	isValidPushTestRequestKey: vi.fn(),
	isValidSubscriptionPayload: vi.fn(),
	recordPushTestFeedback: vi.fn(),
	saveAppointmentPushSubscription: vi.fn(),
	sendTestPushNotification: vi.fn()
}));

vi.mock('$env/dynamic/private', () => ({ env: envState.privateEnv }));
vi.mock('$lib/server/scheduling/public/appointment-token', () => ({
	loadAppointmentForManagementAccess: mocks.loadAppointmentForManagementAccess
}));
vi.mock('$lib/server/integrations/public/push', () => ({
	getLatestPushTestStatus: mocks.getLatestPushTestStatus,
	getPushDeliveryStatus: mocks.getPushDeliveryStatus,
	isPushConfigured: mocks.isPushConfigured,
	isValidPushDeliveryId: mocks.isValidPushDeliveryId,
	isValidPushTestRequestKey: mocks.isValidPushTestRequestKey,
	isValidSubscriptionPayload: mocks.isValidSubscriptionPayload,
	recordPushTestFeedback: mocks.recordPushTestFeedback,
	saveAppointmentPushSubscription: mocks.saveAppointmentPushSubscription,
	sendTestPushNotification: mocks.sendTestPushNotification
}));

const { POST } = await import('./+server');
const { createPatientPushHandlers } = await import('$lib/server/integrations/public/patient-push');
const { InvalidDataContractError } = await import('$lib/contracts/json');
const token='a'.repeat(64);
const subscriptionId='70000000-0000-4000-8000-000000000001';
const deliveryId='70000000-0000-4000-8000-000000000002';
const appointment = {
	id: 'appointment-id',
	is_past: false,
	status: 'reserved'
};
const subscription = {
	endpoint: 'https://push.example/subscription',
	expirationTime: null,
	keys: {
		p256dh: 'p256dh-value',
		auth: 'auth-value'
	}
};

const callPost = (body: unknown, handler=POST, legacy=true) =>
	handler({
		params: { token },
		request: new Request(`https://app.test/${legacy?'turno':'gestion'}/${token}/push`, {
			method: 'POST',
			headers: {
				'content-type': 'application/json',
				'user-agent': 'SamsungBrowser/28.0'
			},
			body: JSON.stringify(body)
		}),
		fetch: vi.fn(),
		setHeaders: vi.fn()
	} as unknown as Parameters<typeof POST>[0]);

beforeEach(() => {
	vi.clearAllMocks();
	for (const key of Object.keys(envState.privateEnv)) delete envState.privateEnv[key];
	mocks.isPushConfigured.mockReturnValue(true);
	mocks.isValidSubscriptionPayload.mockReturnValue(true);
	mocks.isValidPushTestRequestKey.mockImplementation((key: string) =>
		/^push:session-[a-z0-9-]+:(initial|recovery|refresh)$/.test(key)
	);
	mocks.loadAppointmentForManagementAccess.mockResolvedValue({
		appointment,
		supabase: { admin: true }
	});
	mocks.saveAppointmentPushSubscription.mockResolvedValue({
		id: subscriptionId,
		endpoint: subscription.endpoint,
		verifiedAt: null, providerGone:false
	});
	mocks.sendTestPushNotification.mockResolvedValue({
		accepted: true,
		deliveryId: deliveryId
	});
	mocks.getPushDeliveryStatus.mockResolvedValue({
		id: deliveryId,
		status: 'displayed'
	});
});

describe('POST /turno/[token]/push', () => {
	it('reutiliza una suscripción ya confirmada sin mandar otra prueba', async () => {
		mocks.saveAppointmentPushSubscription.mockResolvedValueOnce({
			id: subscriptionId,
			endpoint: subscription.endpoint,
			verifiedAt: '2026-08-04T20:00:00.000Z'
		});

		const response = await callPost({
			subscription,
			test: true,
			testRequestKey: 'push:session-1234567890:initial'
		});

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			ok: true,
			verified: true,
			delivery: null,
			verificationAvailable: true
		});
		expect(mocks.sendTestPushNotification).not.toHaveBeenCalled();
	});

	it('envía la clave estable de la prueba al mecanismo idempotente', async () => {
		const response = await callPost({
			subscription,
			test: true,
			testRequestKey: 'push:session-1234567890:recovery'
		});

		expect(response.status).toBe(200);
		expect(mocks.sendTestPushNotification).toHaveBeenCalledOnce();
		expect(mocks.sendTestPushNotification).toHaveBeenCalledWith(
			{ admin: true },
			expect.any(Function),
			{
				access:{token,legacy:true},
				appointment,
				requestKey: 'push:session-1234567890:recovery',
				subscription: {
					id: subscriptionId,
					endpoint: subscription.endpoint,
					p256dh: subscription.keys.p256dh,
					auth: subscription.keys.auth
				}
			}
		);
	});

	it('conserva la activación si falla la lectura posterior a una prueba ya aceptada', async () => {
		const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
		mocks.getPushDeliveryStatus.mockRejectedValueOnce(new Error('temporary read failure'));

		const response = await callPost({
			subscription,
			test: true,
			testRequestKey: 'push:session-1234567890:initial'
		});

		expect(response.status).toBe(200);
		await expect(response.json()).resolves.toEqual({
			ok: true,
			verified: false,
			deliveryId: deliveryId,
			delivery: null,
			verificationAvailable: true
		});
		expect(mocks.sendTestPushNotification).toHaveBeenCalledOnce();
		expect(consoleError).toHaveBeenCalledWith(
			'Error consultando estado de prueba push recién enviada',
			{}
		);
		consoleError.mockRestore();
	});

	it('rechaza una clave inválida antes de guardar o enviar', async () => {
		mocks.isValidPushTestRequestKey.mockReturnValueOnce(false);

		const response = await callPost({
			subscription,
			test: true,
			testRequestKey: 'repetir'
		});

		expect(response.status).toBe(400);
		await expect(response.json()).resolves.toMatchObject({
			ok: false,
			message: 'No pudimos preparar la prueba.'
		});
		expect(mocks.saveAppointmentPushSubscription).not.toHaveBeenCalled();
		expect(mocks.sendTestPushNotification).not.toHaveBeenCalled();
	});
});


describe('Explicit push management channel and uncertain writes',()=>{
 for(const legacy of [true,false])it(`fixes ${legacy?'legacy':'capability'} authority from the route, ignoring the body`,async()=>{
  const response=await callPost({subscription,test:true,testRequestKey:'push:session-1234567890:initial',p_legacy:!legacy,token:'b'.repeat(64)},createPatientPushHandlers(legacy).POST,legacy);
  expect(response.status).toBe(200);
  expect(mocks.loadAppointmentForManagementAccess).toHaveBeenCalledWith(expect.any(Function),{token,legacy});
  expect(mocks.saveAppointmentPushSubscription).toHaveBeenCalledWith({admin:true},{token,legacy},subscription,expect.any(String));
  expect(mocks.sendTestPushNotification).toHaveBeenCalledWith({admin:true},expect.any(Function),expect.objectContaining({access:{token,legacy}}));
 });
 it('does not enroll or send when the management projection is revoked',async()=>{
  mocks.loadAppointmentForManagementAccess.mockResolvedValueOnce({appointment:null,supabase:{admin:true}});
  const response=await callPost({subscription,test:true});
  expect(response.status).toBe(404);expect(mocks.saveAppointmentPushSubscription).not.toHaveBeenCalled();expect(mocks.sendTestPushNotification).not.toHaveBeenCalled();
 });
 it('preserves the SQL authority decision when it changes after the preliminary read',async()=>{
  mocks.saveAppointmentPushSubscription.mockRejectedValueOnce({message:'APPOINTMENT_LINK_UNAVAILABLE'});
  const response=await callPost({subscription,test:true});
  expect(response.status).toBe(404);expect(mocks.sendTestPushNotification).not.toHaveBeenCalled();
  expect(JSON.stringify(await response.json())).not.toContain('APPOINTMENT_LINK_UNAVAILABLE');
 });
 it('does not announce activation or send after an unreadable enrollment result',async()=>{
  mocks.saveAppointmentPushSubscription.mockRejectedValueOnce(new InvalidDataContractError('push.subscription'));
  const response=await callPost({subscription,test:true});
  expect(response.status).toBe(503);expect(mocks.sendTestPushNotification).not.toHaveBeenCalled();
  expect(await response.json()).toMatchObject({ok:false,message:expect.stringContaining('No pudimos comprobar')});
 });
});


it('cancels an oversized public push stream before reading its bounded remaining chunks',async()=>{
 let cancelled=false;let pulls=0;
 const stream=new ReadableStream<Uint8Array>({
  start(controller){controller.enqueue(new Uint8Array(16_385));},
  pull(controller){if(pulls++===0)controller.enqueue(new Uint8Array(4096));else controller.close();},
  cancel(){cancelled=true;}
 });
 const response=await POST({params:{token},request:new Request(`https://app.test/turno/${token}/push`,
  {method:'POST',body:stream,duplex:'half'} as RequestInit),fetch:vi.fn(),setHeaders:vi.fn()} as unknown as Parameters<typeof POST>[0]);
 expect(response.status).toBe(400);expect(cancelled).toBe(true);
 expect(mocks.saveAppointmentPushSubscription).not.toHaveBeenCalled();
});
