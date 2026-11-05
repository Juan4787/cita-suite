import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
	resolveActiveBusiness: vi.fn(),
	writeAuditLog: vi.fn(),
	loadReminderList: vi.fn(),
	from: vi.fn(),
	rpc: vi.fn()
}));

vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({
	createSupabaseServerClient: vi.fn(async () => ({ from: mocks.from, rpc: mocks.rpc })),
	createSupabaseAdminClient: vi.fn(async () => ({ admin: true }))
}));
vi.mock('$lib/server/access/public/business', () => ({ resolveActiveBusiness: mocks.resolveActiveBusiness }));
vi.mock('$lib/server/platform/audit', () => ({ writeAuditLog: mocks.writeAuditLog }));
vi.mock('$lib/server/scheduling/public/reminders', () => ({ loadReminderList: mocks.loadReminderList }));

const { load, actions } = await import('./+page.server');

const BUSINESS_ID = '00000000-0000-4000-8000-0000000000b1';
const APPOINTMENT_ID = '00000000-0000-4000-8000-0000000000a1';
const REVISION = 'a'.repeat(64);

const event = (form?: Record<string, string>, search = '') =>
	({
		locals: { auth: { access_token: 'test-token' }, verifiedUser: { id: 'user-1' } },
		fetch: vi.fn(),
		cookies: { get: vi.fn() },
		url: new URL(`http://localhost/odonto/recordatorios${search}`),
		request: new Request('http://localhost/odonto/recordatorios?/mark_sent', {
			method: 'POST',
			body: new URLSearchParams(form ?? {})
		})
	}) as never;

beforeEach(() => {
	vi.clearAllMocks();
	mocks.rpc.mockResolvedValue({ data: true, error: null });
	mocks.resolveActiveBusiness.mockResolvedValue({
		business: { id: BUSINESS_ID, name: 'Consultorio', timezone: 'America/Argentina/Cordoba', address: null, maps_url: null },
		role: 'owner',
		canOperate: true,
		access: { canUseBusiness: true }
	});
});

describe('Recordatorios · carga', () => {
	it('muestra todos los turnos del día, también los que ya tienen aviso automático', async () => {
		const list = [
			{ appointment_id: 'a', coverage: 'sin_calendario' },
			{ appointment_id: 'b', coverage: 'aviso_automatico' },
			{ appointment_id: 'c', coverage: 'pendiente_actualizar' }
		];
		mocks.loadReminderList.mockResolvedValue(list);
		const result = (await load(event(undefined, '?dia=manana'))) as { candidates: unknown[]; remindersUnavailable: boolean };
		expect(result.candidates).toEqual(list);
		expect(result.remindersUnavailable).toBe(false);
		expect(mocks.loadReminderList).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ id: BUSINESS_ID }), {
			day: 'manana',
			pushSubscriptionsSupabase: { admin: true }
		});
	});

	it('si no puede comprobar la cobertura no muestra turnos, para no duplicar mensajes', async () => {
		mocks.loadReminderList.mockRejectedValue(new Error('timeout'));
		const result = (await load(event())) as { candidates: unknown[]; remindersUnavailable: boolean };
		expect(result).toMatchObject({ candidates: [], remindersUnavailable: true });
	});
});

describe('Recordatorios · marcar como enviado', () => {
	it('rechaza un identificador mal formado sin consultar la base ni auditar', async () => {
		const result = await actions.mark_sent(event({ appointment_id: 'no-es-un-uuid' }));
		expect(result).toMatchObject({ status: 404 });
		expect(mocks.from).not.toHaveBeenCalled();
		expect(mocks.writeAuditLog).not.toHaveBeenCalled();
	});

	it('un turno inexistente o de otro consultorio no se marca ni deja una auditoría falsa', async () => {
  mocks.rpc.mockResolvedValue({ data: null, error: { message: 'APPOINTMENT_NOT_FOUND', code: 'P0001' } });
  const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID, expected_revision: REVISION }));
  expect(result).toMatchObject({ status: 404 });
  expect(mocks.rpc).toHaveBeenCalledExactlyOnceWith('mark_appointment_whatsapp_reminder_sent', {
   p_business_id: BUSINESS_ID, p_appointment_id: APPOINTMENT_ID, p_expected_revision: REVISION
  });
  expect(mocks.from).not.toHaveBeenCalled();
  expect(mocks.writeAuditLog).not.toHaveBeenCalled();
 });

 it('marca el turno y delega su auditoría al mismo comando transaccional', async () => {
  const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID, expected_revision: REVISION }));
  expect(result).toEqual({ success: true });
  expect(mocks.rpc).toHaveBeenCalledExactlyOnceWith('mark_appointment_whatsapp_reminder_sent', {
   p_business_id: BUSINESS_ID, p_appointment_id: APPOINTMENT_ID, p_expected_revision: REVISION
  });
  expect(mocks.from).not.toHaveBeenCalled();
  expect(mocks.writeAuditLog).not.toHaveBeenCalled();
 });

 it('un reintento ya registrado devuelve éxito sin otra auditoría del servidor', async () => {
  mocks.rpc.mockResolvedValue({ data: false, error: null });
  const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID, expected_revision: REVISION }));
  expect(result).toEqual({ success: true }); expect(mocks.rpc).toHaveBeenCalledTimes(1);
  expect(mocks.writeAuditLog).not.toHaveBeenCalled();
 });

 it('exige la revisión mostrada antes de intentar registrar el envío', async () => {
  const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID }));
  expect(result).toMatchObject({ status: 400 }); expect(mocks.rpc).not.toHaveBeenCalled();
 });

 it('un cambio concurrente responde conflicto humano y no éxito', async () => {
  mocks.rpc.mockResolvedValue({ data: null, error: { message: 'APPOINTMENT_MANAGEMENT_CHANGED', code: 'P0001' } });
  const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID, expected_revision: REVISION }));
  expect(result).toMatchObject({ status: 409, data: { message: expect.stringMatching(/cambiaron/) } });
  expect(JSON.stringify(result)).not.toContain('APPOINTMENT_MANAGEMENT_CHANGED');
 });

 it('una respuesta ilegible conserva la incertidumbre sin afirmar que no se escribió', async () => {
  mocks.rpc.mockResolvedValue({ data: null, error: null });
  const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID, expected_revision: REVISION }));
  expect(result).toMatchObject({ status: 503, data: { message: expect.stringMatching(/revisar lo registrado/) } });
  expect(mocks.writeAuditLog).not.toHaveBeenCalled();
 });

	it('sin permiso para operar no toca la base', async () => {
		mocks.resolveActiveBusiness.mockResolvedValue({ business: { id: BUSINESS_ID }, canOperate: false });
		const result = await actions.mark_sent(event({ appointment_id: APPOINTMENT_ID }));
		expect(result).toMatchObject({ status: 403 });
		expect(mocks.from).not.toHaveBeenCalled();
	});
});
