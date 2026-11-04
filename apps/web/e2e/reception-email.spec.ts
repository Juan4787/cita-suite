import { expect, test } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { loginWithSharedSession } from './helpers/shared-auth';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';
import { applyThemeInPage, expectRenderedTheme } from './helpers/theme';
import { alignTaskForCapture } from './helpers/task-capture';

test('@candidate-behavior isolated reception email: current contact, existing editor and explicit continuation', async ({ page, context }, info) => {
 test.setTimeout(180_000);
 const f = ownedAppointmentFixture(), businessId = randomUUID(), professionalId = randomUUID(), serviceId = randomUUID();
 const patientId = randomUUID(), withoutEmailId = randomUUID();
 const password = `Owned-email-${randomUUID()}`, ownerEmail = `email-owner-${randomUUID()}@example.test`, receptionEmail = `email-reception-${randomUUID()}@example.test`;
 let ownerId: string | null = null, receptionId: string | null = null;
 const issues: LayoutIssue[] = [];
 let pageErrors = 0;
 page.on('pageerror', () => { pageErrors++; });
 let popup: Awaited<ReturnType<typeof context.newPage>> | null = null;
 try {
  const owner = await f.admin.auth.admin.createUser({ email: ownerEmail, password, email_confirm: true });
  if (owner.error || !owner.data.user?.id) throw new Error('Could not create the owned email fixture owner.');
  ownerId = owner.data.user.id;
  const receptionist = await f.admin.auth.admin.createUser({ email: receptionEmail, password, email_confirm: true });
  if (receptionist.error || !receptionist.data.user?.id) throw new Error('Could not create the owned reception account.');
  receptionId = receptionist.data.user.id;
  f.sql(`begin;
   insert into public.businesses(id,name,slug,industry,timezone) values('${businessId}','Recepción sintética','reception-email-${businessId}','other','UTC');
   update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='${businessId}';
   insert into public.business_users(business_id,user_id,role,status,accepted_at) values('${businessId}','${ownerId}','owner','active',now()),('${businessId}','${receptionId}','reception','active',now());
   insert into public.professionals(id,business_id,name) values('${professionalId}','${businessId}','Profesional sintético de recepción');
   insert into public.services(id,business_id,name,duration_minutes) values('${serviceId}','${businessId}','Consulta sintética de recepción',30);
   insert into public.professional_services(business_id,professional_id,service_id) values('${businessId}','${professionalId}','${serviceId}');
   insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes)
    select '${businessId}','${professionalId}',day,'08:00','18:00',30,0 from generate_series(0,6) day;
   insert into public.patients(id,business_id,owner_id,full_name,phone_raw,phone_e164) values
    ('${patientId}','${businessId}','${ownerId}','Paciente Email Sintético','3425048209','+5493425048209'),
    ('${withoutEmailId}','${businessId}','${ownerId}','Paciente Sin Email Sintético','3425048210','+5493425048210'); commit;`);
  const date = f.sql("select (now() at time zone 'UTC')::date+30;");
  await loginWithSharedSession(page, { email: receptionEmail, password });
  const base = new URL(page.url()).origin;
  await context.addCookies([{ name: 'active-business-id', value: businessId, url: base }]);
  const openWizard = async (id: string, time: string) => {
   const query = new URLSearchParams({ date, professional_id: professionalId, service_id: serviceId, patient_id: id, hora: time });
   await page.goto('/odonto/agenda?' + query);
   await expect(page.getByRole('button', { name: 'Confirmar turno', exact: true })).toBeEnabled();
   return page.locator('form[action="?/create_appointment"] [name="idempotency_key"]').inputValue();
  };
  const key = await openWizard(patientId, '09:00');
  await page.getByRole('button', { name: 'Confirmar turno', exact: true }).click();
  const warning = page.getByRole('alert').filter({ hasText: 'Si no se registra el email' });
  await expect(warning).toBeVisible();
  expect(f.sql(`select count(*) from public.appointments where business_id='${businessId}';`)).toBe('0');
  for (const theme of ['light', 'dark'] as const) {
   await applyThemeInPage(page, theme);
   await expectRenderedTheme(page, theme);
   for (const width of [320, 390, 768, 1280, 1600]) {
    await page.setViewportSize({ width, height: 900 });
    await alignTaskForCapture(warning);
    const scope = 'form[action*="/create_appointment"] [role="alert"]';
    issues.push(...await layoutIssues(page, scope + ' button:visible, ' + scope + ' a:visible', scope));
    await page.screenshot({ path: info.outputPath(`reception-email-${theme}-${width}.jpg`), type: 'jpeg', quality: 65 });
   }
  }
  await page.setViewportSize({ width: 1280, height: 900 });
  await applyThemeInPage(page, 'light');
  const opening = page.waitForEvent('popup');
  await page.getByRole('link', { name: 'Agregar email', exact: true }).click();
  popup = await opening;
  popup.on('pageerror', () => { pageErrors++; });
  await expect(popup.getByRole('dialog', { name: 'Editar datos', exact: true })).toBeVisible();
  const email = popup.getByLabel('Correo electrónico (opcional)', { exact: true });
  await expect(email).toBeFocused();
  await expect(popup.getByLabel('Teléfono (opcional)', { exact: true })).toHaveValue('3425048209');
  await email.fill('Reception+Patient@Example.test');
  await popup.getByRole('button', { name: 'Guardar cambios', exact: true }).click();
  await expect(popup.getByRole('dialog', { name: 'Editar datos', exact: true })).toHaveCount(0);
  expect(f.sql(`select email from public.patients where id='${patientId}' and business_id='${businessId}';`)).toBe('Reception+Patient@Example.test');
  expect(f.sql(`select phone_e164 from public.patients where id='${patientId}' and business_id='${businessId}';`)).toBe('+5493425048209');
  await page.getByRole('button', { name: 'Confirmar turno', exact: true }).click();
  await expect(page).toHaveURL(/\/odonto\/turnos\/[0-9a-f-]{36}/);
  expect(f.sql(`select count(*) from public.appointments where business_id='${businessId}' and patient_id='${patientId}' and creation_request_key='${key}' and created_by_user_id='${receptionId}';`)).toBe('1');
  const noEmailKey = await openWizard(withoutEmailId, '11:00');
  await page.getByRole('button', { name: 'Confirmar turno', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Continuar sin email', exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Continuar sin email', exact: true }).click();
  await expect(page).toHaveURL(/\/odonto\/turnos\/[0-9a-f-]{36}/);
  expect(f.sql(`select count(*) from public.appointments where business_id='${businessId}' and patient_id='${withoutEmailId}' and creation_request_key='${noEmailKey}' and created_by_user_id='${receptionId}';`)).toBe('1');
  expect(f.sql(`select count(*) from public.patients where id='${withoutEmailId}' and email is null;`)).toBe('1');
  expect(f.sql(`select count(*) from public.appointments where business_id='${businessId}';`)).toBe('2');
  // The other branch adds email to the same unsaved patient/appointment draft.
  await openWizard(withoutEmailId, '13:00');
  await page.getByRole('button', { name: /Nuevo paciente/ }).click();
  await page.getByLabel('Nombre del paciente', { exact: true }).fill('Nuevo Paciente Sintético');
  await page.getByLabel('Teléfono', { exact: true }).fill('3425048211');
  const newKey = await page.locator('form[action="?/create_appointment"] [name="idempotency_key"]').inputValue();
  await page.getByRole('button', { name: 'Confirmar turno', exact: true }).click();
  await expect(page.getByRole('alert').filter({ hasText: 'Si no se registra el email' })).toBeVisible();
  expect(f.sql(`select count(*) from public.patients where business_id='${businessId}';`)).toBe('2');
  await page.getByRole('button', { name: 'Agregar email', exact: true }).click();
  const newEmail = page.getByLabel('Correo electrónico (opcional)', { exact: true });
  await expect(newEmail).toBeFocused();
  await newEmail.fill('New+Contact@Example.test');
  await page.getByRole('button', { name: 'Confirmar turno', exact: true }).click();
  await expect(page).toHaveURL(/\/odonto\/turnos\/[0-9a-f-]{36}/);
  expect(f.sql(`select count(*) from public.appointments a join public.patients p on p.business_id=a.business_id and p.id=a.patient_id where a.business_id='${businessId}' and a.creation_request_key='${newKey}' and p.email='New+Contact@Example.test';`)).toBe('1');
  expect(f.sql(`select count(*) from public.appointments where business_id='${businessId}';`)).toBe('3');
  expect(f.sql(`select count(*) from public.patients where business_id='${businessId}';`)).toBe('3');
  expect(issues).toEqual([]); expect(pageErrors).toBe(0);
  await info.attach('reception-email-proof', { contentType: 'application/json', body: Buffer.from(JSON.stringify({ realReceptionRole: true, warningBeforeCreation: true, existingEditor: true, currentSavedContact: true, sameAttempt: true, explicitContinuation: true, newPatientEmailFocused: true, duplicates: false, issues, pageErrors })) });
 } finally {
  await popup?.close();
  f.sql(`delete from public.appointments where business_id='${businessId}'; delete from public.businesses where id='${businessId}';`);
  expect(f.sql(`select count(*) from public.businesses where id='${businessId}';`)).toBe('0');
  for (const id of [receptionId, ownerId]) if (id) { const removed = await f.admin.auth.admin.deleteUser(id); expect(removed.error).toBeNull(); }
 }
});
