import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
	canRegisterCalendarAction: vi.fn(),
	googleCalendarUrlFor: vi.fn(),
	icsForAppointment: vi.fn(),
	loadAppointmentForToken: vi.fn(),
 loadAppointmentForManagementAccess: vi.fn(),
 recordCalendarMetric: vi.fn(),
	recordCalendarAction: vi.fn(),
	uncachedRedirect: vi.fn()
}));

vi.mock('$lib/server/scheduling/public/appointment-token', () => ({
	loadAppointmentForToken: mocks.loadAppointmentForToken,
 loadAppointmentForManagementAccess: mocks.loadAppointmentForManagementAccess,
	uncachedRedirect: mocks.uncachedRedirect
}));
vi.mock('$lib/server/integrations/public/calendar-content', () => ({
	googleCalendarUrlFor: mocks.googleCalendarUrlFor,
	icsForAppointment: mocks.icsForAppointment,
 outlookUrlFor: mocks.googleCalendarUrlFor
}));
vi.mock('$lib/server/integrations/public/calendar-tracking', () => ({
	canRegisterCalendarAction: mocks.canRegisterCalendarAction,
	recordCalendarAction: mocks.recordCalendarAction,
 recordCalendarMetric: mocks.recordCalendarMetric
}));

const { GET: openGoogleCalendar } = await import('./ir/google/+server');
const { GET: openPhoneCalendar } = await import('./calendario.ics/+server');
const { createPatientCalendarOpening, createPatientCalendarIntentMetric } = await import('$lib/server/integrations/public/patient-calendar-openings');

const appointment = {
	id: 'appointment-id',
	is_past: false,
	status: 'reserved',
	business: { id: 'business-id' }
};

beforeEach(() => {
	vi.clearAllMocks();
	mocks.canRegisterCalendarAction.mockReturnValue(true);
 mocks.loadAppointmentForManagementAccess.mockResolvedValue({ appointment, supabase: { admin: true }, demo: false });
 mocks.recordCalendarMetric.mockResolvedValue(undefined);
	mocks.loadAppointmentForToken.mockResolvedValue({
		appointment,
		supabase: { admin: true },
		demo: false
	});
	mocks.googleCalendarUrlFor.mockReturnValue(
		'https://calendar.google.com/calendar/render?action=TEMPLATE'
	);
	mocks.icsForAppointment.mockReturnValue('BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n');
	mocks.recordCalendarAction.mockResolvedValue(undefined);
	mocks.uncachedRedirect.mockImplementation(
		(location: string) =>
			new Response(null, {
				status: 303,
				headers: { location, 'cache-control': 'no-store' }
			})
	);
});

describe('entrega observable a calendarios externos', () => {
	it('registra el inicio de Google antes de redirigir al editor prearmado', async () => {
		const response = await openGoogleCalendar({
			params: { token: 'public-token' },
			fetch: vi.fn(),
			url: new URL('https://app.test/turno/public-token/ir/google')
		} as unknown as Parameters<typeof openGoogleCalendar>[0]);

		expect(mocks.recordCalendarAction).toHaveBeenCalledWith(
			{ admin: true },
   { token: 'public-token', legacy: true },
			'clicked_google',
			{ source: null }
		);
		expect(mocks.recordCalendarAction.mock.invocationCallOrder[0]).toBeLessThan(
			mocks.uncachedRedirect.mock.invocationCallOrder[0]
		);
		expect(response.status).toBe(303);
		expect(response.headers.get('location')).toBe(
			'https://calendar.google.com/calendar/render?action=TEMPLATE'
		);
	});

	it('registra iPhone antes de entregar el evento inline al calendario', async () => {
		const response = await openPhoneCalendar({
			params: { token: 'public-token' },
			fetch: vi.fn(),
			url: new URL('https://app.test/turno/public-token/calendario.ics?p=phone')
		} as unknown as Parameters<typeof openPhoneCalendar>[0]);

		expect(mocks.recordCalendarAction).toHaveBeenCalledWith(
			{ admin: true },
   { token: 'public-token', legacy: true },
			'clicked_phone_calendar'
		);
		expect(mocks.recordCalendarAction.mock.invocationCallOrder[0]).toBeLessThan(
			mocks.icsForAppointment.mock.invocationCallOrder[0]
		);
		expect(response.status).toBe(200);
		expect(response.headers.get('content-type')).toContain('text/calendar');
		expect(response.headers.get('content-disposition')).toBe('inline; filename="turno.ics"');
	});

	it('no registra acciones de calendario en el modo demostración', async () => {
		mocks.loadAppointmentForToken.mockResolvedValueOnce({
			appointment,
			supabase: null,
			demo: true
		});

		await openPhoneCalendar({
			params: { token: 'public-token' },
			fetch: vi.fn(),
			url: new URL('https://app.test/turno/public-token/calendario.ics?p=phone')
		} as unknown as Parameters<typeof openPhoneCalendar>[0]);

		expect(mocks.recordCalendarAction).not.toHaveBeenCalled();
	});
});


describe('original patient authority at calendar boundaries', () => {
 it.each(['inline', 'download', 'google', 'outlook'] as const)('keeps the capability channel for %s without reading the stable-token fallback', async kind => {
  const handler = createPatientCalendarOpening(false, kind);
  const response = await handler({ params: { token: 'capability' }, fetch: vi.fn(), url: new URL('https://app.test/gestion/capability/calendar') } as never);
  expect(mocks.loadAppointmentForManagementAccess).toHaveBeenCalledWith(expect.any(Function), { token: 'capability', legacy: false });
  expect(mocks.loadAppointmentForToken).not.toHaveBeenCalled();
  expect(mocks.recordCalendarAction.mock.calls[0][1]).toEqual({ token: 'capability', legacy: false });
  expect(response.headers.get('referrer-policy')).toBe('no-referrer');
 });
 it('does not replace unavailable capability authority with a known calendar identity', async () => {
  mocks.loadAppointmentForManagementAccess.mockResolvedValueOnce({ appointment: null, supabase: { admin: true }, demo: false });
  const response = await createPatientCalendarOpening(false, 'google')({ params: { token: 'revoked' }, fetch: vi.fn(), url: new URL('https://app.test/gestion/revoked/ir/google') } as never);
  expect(response.headers.get('location')).toBe('/gestion/revoked');
  expect(mocks.loadAppointmentForToken).not.toHaveBeenCalled();
  expect(mocks.recordCalendarAction).not.toHaveBeenCalled();
 });
 it('preserves independently readable stable ICS when its tracking permission has been revoked', async () => {
  mocks.recordCalendarAction.mockRejectedValueOnce(new Error('APPOINTMENT_LINK_UNAVAILABLE'));
  const response = await openPhoneCalendar({ params: { token: 'stable-calendar-token' }, fetch: vi.fn(), url: new URL('https://app.test/turno/stable-calendar-token/calendario.ics') } as never);
  expect(response.status).toBe(200);
  expect(await response.text()).toBe('BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n');
  expect(mocks.recordCalendarAction).toHaveBeenCalledTimes(1);
  expect(mocks.recordCalendarAction.mock.calls[0][1]).toEqual({ token: 'stable-calendar-token', legacy: true });
 });
 it('bounds an intent beacon before reading authority or producing a metric', async () => {
  const response = await createPatientCalendarIntentMetric(false)({ params: { token: 'capability' }, fetch: vi.fn(), request: new Request('https://app.test/beacon', { method: 'POST', body: 'x'.repeat(1025) }) } as never);
  expect(response.status).toBe(204);
  expect(mocks.loadAppointmentForManagementAccess).not.toHaveBeenCalled();
  expect(mocks.recordCalendarMetric).not.toHaveBeenCalled();
 });
 it('ignores a client-supplied channel and preserves an intent metric as audit-only', async () => {
  const response = await createPatientCalendarIntentMetric(false)({ params: { token: 'capability' }, fetch: vi.fn(), request: new Request('https://app.test/beacon', { method: 'POST', body: JSON.stringify({ variant: 'data', legacy: true }) }) } as never);
  expect(response.status).toBe(204);
  expect(mocks.recordCalendarMetric).toHaveBeenCalledExactlyOnceWith({ admin: true }, { token: 'capability', legacy: false }, 'android_intent', 'data');
  expect(mocks.recordCalendarAction).not.toHaveBeenCalled();
 });
});
