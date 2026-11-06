import { expect, test, type Page } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { must } from './helpers/fixture-db';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { loginWithSharedSession } from './helpers/shared-auth';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';

// The screens people really use, from a small phone to a large monitor, and not only the widths of
// the other specs: a table or a row of actions can hold at 390 and 1280 and break on a tablet or on
// a 1366 notebook. Each screen is loaded once and measured at every size, open states included.
const RESOLUTIONS = [
	[320, 568], [344, 882], [360, 740], [375, 667], [390, 844], [412, 915], [430, 932], [540, 720], [600, 960],
	[768, 1024], [820, 1180], [912, 1368], [1024, 768], [1180, 820],
	[1280, 720], [1366, 768], [1440, 900], [1536, 864], [1600, 900], [1920, 1080], [2560, 1440]
] as const;
const CONTROLS = ['a', 'button', 'input:not(.ux-native-source):not(.sr-only):not([type="hidden"])', 'textarea', '.ux-control-trigger']
	.map((control) => `main ${control}:visible`)
	.join(', ');
const openAll = (page: Page) => page.evaluate(() => { for (const details of document.querySelectorAll<HTMLDetailsElement>('main details')) details.open = true; });

test('@candidate-behavior every screen holds at the real resolutions of phones, tablets, notebooks and monitors', async ({ page }, info) => {
	test.setTimeout(900_000);
	const f = ownedAppointmentFixture();
	const link = await must(f.admin.from('professional_services').select('professional_id, service_id').eq('business_id', f.businessId).limit(1).single());
	const professional = await must(f.admin.from('professionals').select('name').eq('business_id', f.businessId).eq('id', link.professional_id).single());
	const service = await must(f.admin.from('services').select('name, duration_minutes').eq('id', link.service_id).eq('business_id', f.businessId).single());
	const owner = await must(f.admin.from('business_users').select('user_id').eq('business_id', f.businessId).eq('role', 'owner').single());
	const patientName = `María Eugenia Fernández de los Santos ${[...randomUUID().slice(0, 6)].map((char) => String.fromCharCode(97 + parseInt(char, 16))).join('')}`;
	let patientId: string | null = null;
	const issues: (LayoutIssue & { screen: string; viewport: string })[] = [];
	const measured: string[] = [];
	const at = (days: number) => new Date(Date.now() + days * 86_400_000).toISOString();
	try {
		const patient = await must(f.admin.from('patients').insert({ business_id: f.businessId, owner_id: owner.user_id, full_name: patientName,
			phone: '3415559988', phone_e164: '+5493415559988', email: 'maria.eugenia.fernandez.delossantos@example.test' }).select('id').single());
		patientId = patient.id;
		const appointment = (starts: string) => ({ business_id: f.businessId, patient_id: patient.id, service_id: link.service_id, professional_id: link.professional_id,
			starts_at: starts, ends_at: new Date(Date.parse(starts) + service.duration_minutes * 60_000).toISOString(),
			blocking_starts_at: starts, blocking_ends_at: new Date(Date.parse(starts) + service.duration_minutes * 60_000).toISOString(), status: 'reserved', source: 'manual',
			service_name_snapshot: service.name, professional_name_snapshot: professional.name, duration_minutes_snapshot: service.duration_minutes, patient_name_at_booking: patientName });
		const future = await must(f.admin.from('appointments').insert(appointment(at(9))).select('id').single());
		const past = await must(f.admin.from('appointments').insert(appointment(at(-2))).select('id').single());
		await loginWithSharedSession(page, { email: f.email, password: f.password });
		const p = `/odonto/pacientes/${patient.id}`, pro = `/odonto/profesionales/${link.professional_id}`;
		const open = async (name: string) => { await page.getByRole('button', { name, exact: true }).first().click(); };
		const screens: [string, ((page: Page) => Promise<unknown>)?][] = [
			['/odonto/agenda'], ['/odonto/agenda', () => open('Buscar')], ['/odonto/agenda', () => open('+ Nuevo turno')], ['/odonto/agenda/semana'],
			[`/odonto/turnos/${future.id}`], [`/odonto/turnos/${future.id}`, openAll], [`/odonto/turnos/${past.id}`], [`/odonto/turnos/${past.id}`, openAll],
			['/odonto/pacientes'], [p], [`${p}?tab=datos`], [`${p}?tab=radiografias`], ['/odonto/seguimientos'], ['/odonto/recordatorios'], ['/odonto/senas'],
			['/odonto/configuracion'], ['/odonto/configuracion/negocio'], ['/odonto/configuracion/usuarios'], ['/odonto/configuracion/usuarios', () => open('Agregar integrante')],
			['/odonto/configuracion/senas'], ['/odonto/configuracion/correo'], ['/odonto/configuracion/reserva-online'], ['/odonto/configuracion/documentos'],
			['/odonto/configuracion/suscripcion'], ['/odonto/configuracion/resena-google'], [pro], [`${pro}?tab=servicios`], [`${pro}?tab=horarios`], [`${pro}/preguntas`], [`${pro}/aranceles`],
			['/odonto/exportar-datos'], [`/reservar/${f.businessId}`]
		];
		for (const [route, prepare] of screens) {
			await page.setViewportSize({ width: 1280, height: 800 });
			await page.goto(route);
			await page.waitForLoadState('networkidle');
			await prepare?.(page);
			const screen = `${route.replace(/[0-9a-f]{8}-[0-9a-f-]{27}/g, 'id')}${prepare ? ' (abierto)' : ''}`;
			for (const [width, height] of RESOLUTIONS) {
				await page.setViewportSize({ width, height });
				const viewport = `${width}x${height}`;
				issues.push(...(await layoutIssues(page, CONTROLS, 'main')).map((issue) => ({ ...issue, screen, viewport })));
				measured.push(`${screen} ${viewport}`);
			}
		}
		await info.attach('resolutions', { body: JSON.stringify({ resolutions: RESOLUTIONS, measured: measured.length, issues }, null, 2), contentType: 'application/json' });
		expect(measured.length).toBe(screens.length * RESOLUTIONS.length);
		expect(issues).toEqual([]);
	} finally {
		f.sql(`begin;
			delete from public.audit_logs where business_id=:'business'::uuid and (entity_id=:'patient'::uuid or entity_id in (select id from public.appointments where business_id=:'business'::uuid and patient_id=:'patient'::uuid));
			delete from public.appointments where business_id=:'business'::uuid and patient_id=:'patient'::uuid;
			delete from public.patients where business_id=:'business'::uuid and id=:'patient'::uuid;
			commit;`, { patient: patientId ?? '00000000-0000-0000-0000-000000000000' });
		if (patientId) expect(await must(f.admin.from('patients').select('id').eq('business_id', f.businessId).eq('id', patientId))).toHaveLength(0);
	}
});
