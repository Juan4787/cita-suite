import { describe, expect, it } from 'vitest';
import { resolvePatientActions, resolveAppointmentEmailContext } from './patient-action-context';

const now = new Date('2026-11-10T12:00:00Z');
const turn = {
	status: 'reserved', startsAt: '2026-11-20T13:00:00Z', now,
	managementAccessValid: true, cancelAllowed: true, rescheduleAllowed: true,
	newBookingAllowed: true
};
const email = {
	...turn, purpose: 'booking_receipt' as const, depositStatus: null,
	showCancel: true, showReschedule: true
};

describe('acciones pertinentes al turno: AC01–AC09, RP01, UI06 y OP03', () => {
	it.each(['reserved', 'confirmed', 'reschedule_requested'])('permite gestionar un turno futuro %s con permiso efectivo', (status) => {
		expect(resolvePatientActions({ ...turn, status })).toEqual({ cancel: true, reschedule: true, bookNew: false });
	});
	it('un turno cancelado no se cancela ni se reprograma: sólo puede reservarse otro', () => {
		expect(resolvePatientActions({ ...turn, status: 'cancelled' })).toEqual({ cancel: false, reschedule: false, bookNew: true });
	});
	it('reserva pública apagada conserva cancelación pero no concede reprogramar ni nueva reserva', () => {
		expect(resolvePatientActions({ ...turn, rescheduleAllowed: false, newBookingAllowed: false })).toEqual({ cancel: true, reschedule: false, bookNew: false });
		expect(resolvePatientActions({ ...turn, status: 'cancelled', rescheduleAllowed: false, newBookingAllowed: false })).toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
	it.each([
		{ startsAt: '2026-11-10T11:59:59Z' },
		{ startsAt: '2026-11-10T12:00:00Z' },
		{ startsAt: 'no es una fecha' },
		{ now: new Date('invalid') },
		{ managementAccessValid: false },
		{ status: 'desconocido' }
	])('no ofrece acciones con tiempo, estado o capacidad inválidos: %j', (changed) => {
		expect(resolvePatientActions({ ...turn, ...changed })).toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
	it('no recupera permisos que el servidor retiró', () => {
		expect(resolvePatientActions({ ...turn, cancelAllowed: false })).toEqual({ cancel: false, reschedule: true, bookNew: false });
		expect(resolvePatientActions({ ...turn, cancelAllowed: false, rescheduleAllowed: false })).toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
});

describe('comprobantes, recordatorios y señas en su contexto: AC05, RM06–RM12 y SN17', () => {
	it.each(['booking_receipt', 'reschedule_receipt', 'reminder_72h', 'reminder_24h'] as const)('%s de turno vigente puede ofrecer ambos botones', (purpose) => {
		const result = resolveAppointmentEmailContext({ ...email, purpose });
		expect(result.send).toBe(true);
		expect(result.actions).toEqual({ cancel: true, reschedule: true, bookNew: false });
		expect(result.appointmentState).toBe('reserved');
	});
	it.each([null, 'pending', 'paid', 'waived', 'expired'] as const)('comprobante de cancelación con seña %s no ofrece Cancelar ni Reprogramar', (depositStatus) => {
		const result = resolveAppointmentEmailContext({ ...email, purpose: 'cancellation_receipt', status: 'cancelled', depositStatus });
		expect(result.send).toBe(true);
		expect(result.actions).toEqual({ cancel: false, reschedule: false, bookNew: true });
		expect(result.appointmentState).toBe('cancelled');
	});
	it('sin reserva pública, el comprobante de cancelación no ofrece ninguna acción de agenda', () => {
		expect(resolveAppointmentEmailContext({ ...email, purpose: 'cancellation_receipt', status: 'cancelled', newBookingAllowed: false }).actions)
			.toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
	it.each(['booking_receipt', 'reschedule_receipt', 'deposit_request', 'reminder_72h', 'reminder_24h'] as const)('descarta %s si el turno ya está cancelado', (purpose) => {
		const result = resolveAppointmentEmailContext({ ...email, purpose, status: 'cancelled', depositStatus: 'pending' });
		expect(result.send).toBe(false);
		expect(result.actions).toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
	it('descarta un evento de cancelación incompatible con el estado actual', () => {
		expect(resolveAppointmentEmailContext({ ...email, purpose: 'cancellation_receipt' }).send).toBe(false);
	});
	it.each([null, 'paid', 'waived', 'expired'] as const)('no pide seña que ya no está pendiente: %s', (depositStatus) => {
		expect(resolveAppointmentEmailContext({ ...email, purpose: 'deposit_request', depositStatus }).send).toBe(false);
	});
	it('una seña pendiente no se presenta como pago ni confirmación', () => {
		const result = resolveAppointmentEmailContext({ ...email, purpose: 'deposit_request', depositStatus: 'pending' });
		expect(result.send).toBe(true);
		expect(result.appointmentState).toBe('reserved');
		expect(result.depositState).toBe('pending');
	});
	it('rechaza una fotografía incoherente: Confirmado con seña pendiente', () => {
		expect(resolveAppointmentEmailContext({ ...email, status: 'confirmed', depositStatus: 'pending' }).send).toBe(false);
	});
	it.each(['reminder_72h', 'reminder_24h', 'deposit_request'] as const)('no envía %s de un turno ya iniciado', (purpose) => {
		expect(resolveAppointmentEmailContext({ ...email, purpose, startsAt: now.toISOString(), depositStatus: 'pending' }).send).toBe(false);
	});
	it('un comprobante consultado tarde conserva el hecho pero no ofrece acciones del turno pasado', () => {
		const result = resolveAppointmentEmailContext({ ...email, startsAt: '2026-11-09T13:00:00Z' });
		expect(result.send).toBe(true);
		expect(result.actions).toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
	it.each([
		[false, false], [true, false], [false, true], [true, true]
	])('preferencias del correo %s/%s filtran presentación sin retirar permisos de gestión', (showCancel, showReschedule) => {
		const result = resolveAppointmentEmailContext({ ...email, showCancel, showReschedule });
		expect(result.actions).toEqual({ cancel: showCancel, reschedule: showReschedule, bookNew: false });
		expect(resolvePatientActions(turn)).toEqual({ cancel: true, reschedule: true, bookNew: false });
	});
	it('una capacidad revocada no se reactiva por mantener botones habilitados', () => {
		const result = resolveAppointmentEmailContext({ ...email, managementAccessValid: false });
		expect(result.send).toBe(false);
		expect(result.actions).toEqual({ cancel: false, reschedule: false, bookNew: false });
	});
	it('un reloj inválido no produce un envío aparentemente válido', () => {
		expect(resolveAppointmentEmailContext({ ...email, now: new Date('invalid') }).send).toBe(false);
	});
});
