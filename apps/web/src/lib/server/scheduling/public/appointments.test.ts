import { describe, expect, it, vi } from 'vitest';


import {
	APPOINTMENT_STATUSES,
	assertCanTransitionAppointment,
	createJointAppointment,
	createManualAppointment,
	findAppointmentCreationReplay,
	getHumanAppointmentErrorMessage,
	getAppointmentCreationErrorStatus,
	rescheduleAppointment,
	updateAppointmentStatus
} from '$lib/server/scheduling/public/appointments';


const pastStart = new Date('2026-05-13T10:00:00.000Z');
const pastEnd = new Date('2026-05-13T11:00:00.000Z');
const now = new Date('2026-05-13T12:00:00.000Z');

describe('appointment transitions', () => {
	it('allows active appointments to be confirmed or cancelled', () => {
		expect(() =>
			assertCanTransitionAppointment({
				currentStatus: 'reserved',
				nextStatus: 'confirmed',
				startsAt: pastStart,
				endsAt: pastEnd,
				now
			})
		).not.toThrow();

		expect(() =>
			assertCanTransitionAppointment({
				currentStatus: 'confirmed',
				nextStatus: 'cancelled',
				startsAt: pastStart,
				endsAt: pastEnd,
				now
			})
		).not.toThrow();
	});

	it('blocks terminal appointments from returning to active states', () => {
		expect(() =>
			assertCanTransitionAppointment({
				currentStatus: 'cancelled',
				nextStatus: 'confirmed',
				startsAt: pastStart,
				endsAt: pastEnd,
				now
			})
		).toThrow('APPOINTMENT_TERMINAL_STATUS');
	});

	it('el paso natural del tiempo no cierra ni agrega un estado al turno', () => {
		expect(APPOINTMENT_STATUSES).toEqual([
			'reserved',
			'confirmed',
			'cancelled',
			'reschedule_requested'
		]);
		expect(() =>
			assertCanTransitionAppointment({
				currentStatus: 'reserved',
				nextStatus: 'reschedule_requested',
				startsAt: pastStart,
				endsAt: pastEnd,
				now
			})
		).not.toThrow();
	});
});

describe('appointment error messages', () => {
	it('reports a changed actor as forbidden while preserving overlap and unexpected failure statuses', () => {
		expect(getAppointmentCreationErrorStatus(new Error('APPOINTMENT_CREATOR_INVALID'))).toBe(403);
		expect(getAppointmentCreationErrorStatus({ code: 'P0001', message: 'PATIENT_OWNER_INVALID' })).toBe(403);
		expect(getAppointmentCreationErrorStatus({ code: '23P01' })).toBe(409);
		expect(getAppointmentCreationErrorStatus(null)).toBe(500);
		expect(getAppointmentCreationErrorStatus({ message: {} })).toBe(500);
		expect(getAppointmentCreationErrorStatus(new Error('Unexpected provider failure'))).toBe(500);
	});

	it('maps overlap and domain errors to human messages', () => {
		const overlapMessage = getHumanAppointmentErrorMessage({ code: '23P01' });
		expect(overlapMessage).toContain('al menos uno de los profesionales');
		expect(overlapMessage).toContain('No se reservó a ningún integrante');
		expect(overlapMessage).toContain('elegí otra opción disponible');
		expect(getHumanAppointmentErrorMessage(new Error('PROFESSIONAL_SERVICE_NOT_ASSIGNED'))).toBe(
			'Al menos uno de los profesionales seleccionados no está habilitado para este procedimiento. Volvé al paso del equipo, quitá a ese profesional o asignale el procedimiento desde su configuración.'
		);
		expect(getHumanAppointmentErrorMessage(new Error('PATIENT_BLOCKED'))).toContain(
			'Revisá su ficha'
		);
		expect(getHumanAppointmentErrorMessage(new Error('APPOINTMENT_CREATOR_INVALID'))).toContain(
			'Recargá la agenda'
		);
	});
});

const requestKey = 'a1000000-0000-4000-8000-000000000001';

const createAtomicAppointmentMock = (options: { replayData?: Record<string, unknown> | null } = {}) => {
	const rpcCalls: Array<{ name: string; payload: Record<string, unknown> }> = [];
	const headers: Array<[string, string]> = [];
	let tableReads = 0;
	const supabase = {
		from: () => {
			tableReads += 1;
			throw new Error('La creación atómica no debe leer ni escribir tablas desde la aplicación');
		},
		rpc: (name: string, payload: Record<string, unknown>) => {
			rpcCalls.push({ name, payload });
			const generated = {
				id: `appointment-${rpcCalls.length}`,
				patient_id: `patient-${rpcCalls.length}`,
				professional_name_snapshot: 'Dra. Uno, Dr. Dos',
				patient_created: payload.p_patient_mode !== 'existing',
				idempotent_replay: false
			};
			const builder = {
				setHeader: (name: string, value: string) => { headers.push([name, value]); return builder; },
				single: async () => ({
					data: generated,
					error: null
				}),
				maybeSingle: async () => ({
					data: Object.hasOwn(options, 'replayData') ? options.replayData : generated,
					error: null
				})
			};
			return builder;
		}
	};
	return {
		supabase: supabase as never,
		rpcCalls,
		headers,
		getTableReads: () => tableReads
	};
};

describe('patient identity during appointment creation', () => {
	it('envía las condiciones de seña en la petición atómica, también sin el módulo de cuestionarios', async () => {
		const { supabase, headers } = createAtomicAppointmentMock();
		const terms = { amount: 40000, dueAt: '2026-07-28T13:00:00.000Z', autoCancel: true };
		await createManualAppointment(supabase, {
			businessId: 'business-1', patient: { mode: 'public', name: 'Ana Prueba', phone: '3425048209' },
			serviceId: 'service-1', professionalId: 'professional-1', startsAt: new Date('2026-07-30T13:00:00Z'),
			source: 'public_booking', idempotencyKey: requestKey, depositTerms: terms
		});
		expect(headers).toEqual([['x-cita-deposit-terms', JSON.stringify(terms)]]);
	});
    it('commits required declarations with the public reservation through the information wrapper', async () => {
        const {supabase, rpcCalls} = createAtomicAppointmentMock();
        await createManualAppointment(supabase, {
            businessId: 'business-1', patient: {mode:'public', name:'Ana Prueba', phone:'3425048209'},
            serviceId:'service-1', professionalId:'professional-1', startsAt:new Date('2026-07-30T13:00:00Z'),
            source:'public_booking', idempotencyKey:requestKey, internalNote:'Comentario clínico',
            bookingInformation:{schemaHash:'a'.repeat(64),answers:{profile_insurance:'Particular'}}
        });
        expect(rpcCalls[0]).toMatchObject({name:'create_public_booking_with_information',payload:{p_replay_only:false,p_input:{business_id:'business-1',schema_hash:'a'.repeat(64),answers:{profile_insurance:'Particular'},comment:'Comentario clínico',integration_id:null,professional_ids:['professional-1']}}});
    });
	it('consulta la idempotencia sin crear nada y recupera sólo una coincidencia previa', async () => {
		const absent = createAtomicAppointmentMock({ replayData: null });
		const input = {
			businessId: 'business-1',
			ownerId: 'owner-1',
			patient: { mode: 'new' as const, name: 'Juan Pedro', phone: '342 504 8209' },
			serviceId: 'service-1',
			professionalIds: ['professional-1'],
			startsAt: new Date('2026-07-30T13:00:00.000Z'),
			idempotencyKey: requestKey
		};
		await expect(findAppointmentCreationReplay(absent.supabase, input)).resolves.toBeNull();
		expect(absent.rpcCalls[0]?.payload).toMatchObject({ p_replay_only: true });

		const previous = createAtomicAppointmentMock({
			replayData: {
				id: 'appointment-existing',
				patient_id: 'patient-existing',
				confirmation_token: 'token-existing',
				idempotent_replay: true
			}
		});
		await expect(findAppointmentCreationReplay(previous.supabase, input)).resolves.toMatchObject({
			id: 'appointment-existing',
			idempotent_replay: true
		});
	});

	it('dos altas explícitas con el mismo teléfono siguen siendo dos personas distintas', async () => {
		const { supabase, rpcCalls, getTableReads } = createAtomicAppointmentMock();
		await createManualAppointment(supabase, {
			businessId: 'business-1',
			ownerId: 'owner-1',
			patient: { mode: 'new', name: 'Juan Pedro', phone: '342 504 8209' },
			serviceId: 'service-1',
			professionalId: 'professional-1',
			startsAt: new Date('2026-07-30T13:00:00.000Z'),
			idempotencyKey: requestKey
		});
		await createManualAppointment(supabase, {
			businessId: 'business-1',
			ownerId: 'owner-1',
			patient: { mode: 'new', name: 'Carlos', phone: '342 504 8209' },
			serviceId: 'service-1',
			professionalId: 'professional-1',
			startsAt: new Date('2026-07-30T14:00:00.000Z'),
			idempotencyKey: 'a1000000-0000-4000-8000-000000000002'
		});

		expect(getTableReads()).toBe(0);
		expect(rpcCalls.map((call) => call.payload)).toEqual([
			expect.objectContaining({
				p_patient_mode: 'new',
				p_replay_only: false,
				p_patient_id: null,
				p_patient_name: 'Juan Pedro',
				p_patient_phone_e164: '+5493425048209'
			}),
			expect.objectContaining({
				p_patient_mode: 'new',
				p_patient_id: null,
				p_patient_name: 'Carlos',
				p_patient_phone_e164: '+5493425048209'
			})
		]);
	});

	it('una ficha existente se asocia exclusivamente por el patient_id elegido', async () => {
		const { supabase, rpcCalls } = createAtomicAppointmentMock();
		await createManualAppointment(supabase, {
			businessId: 'business-1',
			patient: {
				mode: 'existing',
				patientId: 'patient-selected',
				phone: '342 504 8209',
				updatePhone: true
			},
			serviceId: 'service-1',
			professionalId: 'professional-1',
			startsAt: new Date('2026-07-30T13:00:00.000Z'),
			idempotencyKey: requestKey
		});

		expect(rpcCalls[0]).toMatchObject({
			name: 'create_appointment_with_patient_identity',
			payload: {
				p_patient_mode: 'existing',
				p_patient_id: 'patient-selected',
				p_patient_name: null,
				p_update_existing_phone: true
			}
		});
	});

	it('rechaza antes del RPC mezclar el modo público con una fuente interna', async () => {
		const { supabase, rpcCalls } = createAtomicAppointmentMock();

		await expect(
			createManualAppointment(supabase, {
				businessId: 'business-1',
				patient: { mode: 'public', name: 'Ana Gomez', phone: '351 555 0000' },
				serviceId: 'service-1',
				professionalId: 'professional-1',
				startsAt: new Date('2026-07-30T13:00:00.000Z'),
				idempotencyKey: requestKey
			})
		).rejects.toThrow('PATIENT_MODE_SOURCE_MISMATCH');
		expect(rpcCalls).toHaveLength(0);
	});
});

describe('joint appointment creation', () => {
	it('envía paciente y equipo en una sola operación atómica e idempotente', async () => {
		const { supabase, rpcCalls } = createAtomicAppointmentMock();
		const created = await createJointAppointment(supabase, {
			businessId: 'business-1',
			createdByUserId: 'user-1',
			patient: { mode: 'existing', patientId: 'patient-1' },
			serviceId: 'service-1',
			professionalIds: ['professional-1', 'professional-2'],
			startsAt: new Date('2026-07-30T13:00:00.000Z'),
			ignoreBreak: true,
			idempotencyKey: requestKey
		});

		expect(created.id).toBe('appointment-1');
		expect(rpcCalls[0]).toEqual({
			name: 'create_appointment_with_patient_identity',
			payload: expect.objectContaining({
				p_business_id: 'business-1',
				p_patient_mode: 'existing',
				p_patient_id: 'patient-1',
				p_professional_ids: ['professional-1', 'professional-2'],
				p_ignore_break: true,
				p_source: 'manual',
				p_idempotency_key: requestKey
			})
		});
	});

	it('no llama a la base si falta aceptar la advertencia del teléfono', async () => {
		const { supabase, rpcCalls, getTableReads } = createAtomicAppointmentMock();
		await expect(
			createJointAppointment(supabase, {
				businessId: 'business-1',
				patient: { mode: 'existing', patientId: 'patient-1', phone: '123' },
				serviceId: 'service-1',
				professionalIds: ['professional-1', 'professional-2'],
				startsAt: new Date('2026-07-30T13:00:00.000Z'),
				phoneCommunicationStatus: 'invalid',
				idempotencyKey: requestKey
			})
		).rejects.toThrow('PHONE_WARNING_ACKNOWLEDGEMENT_REQUIRED');
		expect(getTableReads()).toBe(0);
		expect(rpcCalls).toHaveLength(0);
	});

	it('persiste la aceptación explícita y rechaza declarar válido un número inválido', async () => {
		const acknowledged = createAtomicAppointmentMock();
		await createJointAppointment(acknowledged.supabase, {
			businessId: 'business-1',
			patient: { mode: 'existing', patientId: 'patient-1', phone: '123' },
			serviceId: 'service-1',
			professionalIds: ['professional-1', 'professional-2'],
			startsAt: new Date('2026-07-30T13:00:00.000Z'),
			phoneCommunicationStatus: 'invalid',
			phoneWarningAcknowledged: true,
			idempotencyKey: requestKey
		});
		expect(acknowledged.rpcCalls[0]?.payload).toMatchObject({
			p_phone_communication_status: 'invalid',
			p_phone_warning_acknowledged: true
		});

		const forged = createAtomicAppointmentMock();
		await expect(
			createJointAppointment(forged.supabase, {
				businessId: 'business-1',
				patient: { mode: 'existing', patientId: 'patient-1', phone: '123' },
				serviceId: 'service-1',
				professionalIds: ['professional-1', 'professional-2'],
				startsAt: new Date('2026-07-30T13:00:00.000Z'),
				phoneCommunicationStatus: 'valid',
				idempotencyKey: requestKey
			})
		).rejects.toThrow('PHONE_COMMUNICATION_STATUS_MISMATCH');
		expect(forged.rpcCalls).toHaveLength(0);
	});

	it('la reserva pública declara su estrategia sin inferir por teléfono en TypeScript', async () => {
		const { supabase, rpcCalls } = createAtomicAppointmentMock();
		await createJointAppointment(supabase, {
			businessId: 'business-1',
			patient: {
				mode: 'public',
				name: 'Ana Gomez',
				phone: '+598 99 123 456'
			},
			serviceId: 'service-1',
			professionalIds: ['professional-1', 'professional-2'],
			startsAt: new Date('2026-07-30T13:00:00.000Z'),
			source: 'public_booking',
			idempotencyKey: requestKey
		});

		expect(rpcCalls[0]?.payload).toMatchObject({
			p_patient_mode: 'public',
			p_patient_id: null,
			p_source: 'public_booking',
			p_phone_communication_status: 'unknown',
			p_phone_warning_acknowledged: false
		});
	});
});

// Calendar, money and competing writes now belong to the SQL command contract
// (staff_appointment_management.sql). These exports must only delegate once.
vi.mock('./staff-management', () => ({ applyStaffManagementCommand: vi.fn() }));
import { applyStaffManagementCommand } from './staff-management';
describe('existing staff exports delegate to the atomic command', () => {
 const reader = {} as never, writer = {} as never;
 const common = { writer, business: { id: 'business', timezone: 'UTC', is_active: true, public_booking_enabled: true,
  min_booking_notice_minutes: 0, max_booking_days_ahead: 365 }, appointmentId: 'appointment', userId: 'actor',
  operationId: 'original-operation', expectedRevision: 'original-revision' };
 it('keeps the original observation, operation and precise target for a move', async () => {
  const startsAt = '2026-12-01T12:00:00.000001Z';
  await rescheduleAppointment(reader, { ...common, startsAt, ignoreBreak: false, availabilityRevision: 9 });
  expect(applyStaffManagementCommand).toHaveBeenLastCalledWith(writer,reader,expect.objectContaining({
   actorId: 'actor', operationId: 'original-operation', expectedRevision: 'original-revision', action: 'reschedule', startsAt, availabilityRevision: 9 }));
 });
 it('retains the separate status export and original reason', async () => {
  await updateAppointmentStatus(reader, { ...common, status: 'cancelled',reason: 'Solicitado' });
  expect(applyStaffManagementCommand).toHaveBeenLastCalledWith(writer,reader,expect.objectContaining({ action: 'cancel',reason: 'Solicitado' }));
 });
 it('does not accept a transition back to reserved', async () => {
  await expect(updateAppointmentStatus(reader,{ ...common,status: 'reserved' })).rejects.toThrow('APPOINTMENT_INVALID_TRANSITION');
 });
 it('explains the pending-deposit guard without exposing a database error', () => {
  expect(getHumanAppointmentErrorMessage({ message: 'APPOINTMENT_DEPOSIT_PENDING',code: 'P0001' })).toContain('Confirmar seña');
 });
});
