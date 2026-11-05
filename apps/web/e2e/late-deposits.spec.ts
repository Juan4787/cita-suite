import { expect, test, type Locator } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { must } from './helpers/fixture-db';
import { loginWithSharedSession } from './helpers/shared-auth';
import { observeRenderHealth } from './helpers/render-health';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';
import { alignTaskForCapture } from './helpers/task-capture';

// Hosted Playwright fallback: no approved host browser is exposed. Actual Auth,
// POSTs and persisted money; intercepted responses never replace the SQL command.
test('@candidate-behavior late deposit: native recording, lost response recovery and contextual correction', async ({ page, context, browser }, info) => {
 test.setTimeout(180_000);
 const f = ownedAppointmentFixture(), appointmentId = randomUUID(), patientId = randomUUID();
 const path = `/odonto/turnos/${appointmentId}`;
 const owner = f.sql(`select user_id from public.business_users where business_id='${f.businessId}' and role='owner' and status='active' limit 1;`);
 expect(owner).toMatch(/^[a-f0-9-]{36}$/);
 const assignment = await must(f.admin.from('professional_services').select('service_id,professional_id').eq('business_id',f.businessId).limit(1).single());
 expect(f.sql(`select count(*) from public.deposit_policies where business_id='${f.businessId}';`)).toBe('0');
 const automation = f.sql('select enabled::text from private.deposit_automation where singleton;');
 expect(['true','false']).toContain(automation);
 const health = await observeRenderHealth(page), issues: LayoutIssue[] = [];
 const state = () => f.sql(`select jsonb_build_array(
  (select to_jsonb(a) from public.appointments a where id='${appointmentId}'),
  (select to_jsonb(d) from public.appointment_deposits d where appointment_id='${appointmentId}'),
  (select jsonb_agg(to_jsonb(r) order by ordinal) from public.appointment_deposit_requirements r where appointment_id='${appointmentId}'),
  (select count(*) from public.appointment_slot_releases where appointment_id='${appointmentId}'),
  (select count(*) from private.appointment_email_events where appointment_id='${appointmentId}'));`);
 const receipts = () => f.sql(`select jsonb_build_array(
  (select count(*) from public.appointment_deposit_events where appointment_id='${appointmentId}' and event_type='late_payment_recorded'),
  (select count(*) from public.appointment_deposit_events where appointment_id='${appointmentId}' and corrects_event_id is not null),
  (select count(*) from private.appointment_management_operations where appointment_id='${appointmentId}' and action like 'late_deposit_%'),
  (select count(*) from public.audit_logs where entity_id='${appointmentId}' and action in ('appointment.late_deposit_recorded','appointment.late_deposit_corrected')));`);
 await page.addInitScript(() => {
  const descriptor = Object.getOwnPropertyDescriptor(EventTarget.prototype,'addEventListener');
  if (!descriptor || typeof descriptor.value !== 'function') throw new Error('Missing native listener descriptor');
  const original = descriptor.value;
  Object.defineProperty(EventTarget.prototype,'addEventListener',{ ...descriptor,
   value: function(this: EventTarget,...args: Parameters<EventTarget['addEventListener']>) {
    const result = Reflect.apply(original,this,args);
    if (this instanceof HTMLFormElement && args[0] === 'submit' && this.getAttribute('action') === '?/late_deposit') this.dataset.fixtureEnhanced = 'true';
    return result;
   }
  });
 });
 const fields = (form: Locator) => form.evaluate(form => Object.fromEntries([...new FormData(form as HTMLFormElement)].map(([key,value]) => [key,String(value)])));
 const loseThenRecover = async (form: Locator, button: string) => {
  await expect(form).toHaveAttribute('data-fixture-enhanced','true');
  const original = await fields(form);
  const target = `**${path}?/late_deposit`;
  let intercepted = false;
  await page.route(target,async route => {
   if (intercepted || route.request().method() !== 'POST') return route.continue();
   intercepted = true;
   const accepted = await route.fetch();
   expect(accepted.status()).toBe(200);
   expect((await accepted.json()).type).toBe('success');
   await route.fulfill({ status: 200,contentType: 'text/plain',body: 'Respuesta interrumpida' });
  });
  try {
   await form.getByRole('button',{ name: button,exact: true }).click();
   await expect(page.getByRole('alert')).toContainText('No pudimos comprobar el resultado');
   expect(intercepted).toBe(true);
   const committed = receipts();
   const retry = page.getByRole('button',{ name: 'Reintentar la misma acción' }).locator('..');
   expect(await fields(retry)).toEqual(original);
   await expect(retry).toHaveAttribute('action','?/late_deposit');
   await retry.getByRole('button').click();
   await expect(page.getByRole('status')).toContainText('Esta acción ya estaba guardada');
   expect(receipts()).toBe(committed);
   return original;
  } finally { await page.unroute(target); }
 };
 try {
  f.sql(`begin;
   insert into public.patients(id,business_id,owner_id,full_name,phone_e164) values('${patientId}','${f.businessId}','${owner}','Paciente sintético de transferencia tardía','+5493425048272');
   insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details)
    values('${f.businessId}',true,true,'fixed',40000,'Alias sintético sin cuenta bancaria');
   update private.deposit_automation set enabled=true;
   insert into public.appointments(id,business_id,patient_id,service_id,professional_id,starts_at,ends_at,status,source,created_at,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
    select '${appointmentId}','${f.businessId}','${patientId}','${assignment.service_id}','${assignment.professional_id}',t.starts,t.starts+make_interval(mins=>s.duration_minutes),'reserved','manual',now()-interval '7 days','Consulta sintética','Profesional sintético',s.duration_minutes
    from public.businesses b,public.services s,lateral(select case when extract(hour from now() at time zone b.timezone)<15
     then ((now() at time zone b.timezone)::date+1+time '16:00') at time zone b.timezone
     else ((now() at time zone b.timezone)::date+2+time '09:00') at time zone b.timezone end as starts)t where b.id='${f.businessId}' and s.id='${assignment.service_id}';
   commit;
   select private.expire_unpaid_deposits();`);
  expect(f.sql(`select a.status||':'||d.status from public.appointments a join public.appointment_deposits d on d.appointment_id=a.id where a.id='${appointmentId}';`)).toBe('cancelled:expired');
  const closed = state();
  await loginWithSharedSession(page,{ email: f.email,password: f.password });
  const native = await browser.newContext({ javaScriptEnabled: false,storageState: await context.storageState() });
  try {
   const nativePage = await native.newPage();
   await nativePage.goto(path);
   await nativePage.getByText('Registrar dinero después de cancelar',{ exact: true }).click();
   await nativePage.getByLabel('Importe recibido, en pesos',{ exact: true }).fill('1,5');
   await nativePage.getByLabel('Nota del registro (opcional)',{ exact: true }).fill('Nota interna sintética conservada');
   await nativePage.getByRole('checkbox',{ name: 'Verifiqué el ingreso y que corresponde a este paciente' }).check();
   const rejected = nativePage.waitForResponse(response => response.request().method() === 'POST');
   await nativePage.getByRole('button',{ name: 'Registrar dinero recibido',exact: true }).click();
   expect((await rejected).status()).toBe(400);
   await expect(nativePage.getByRole('alert')).toContainText('pesos sin centavos');
   await expect(nativePage.getByLabel('Importe recibido, en pesos',{ exact: true })).toHaveValue('1,5');
   await expect(nativePage.getByLabel('Nota del registro (opcional)',{ exact: true })).toHaveValue('Nota interna sintética conservada');
   expect(receipts()).toBe('[0, 0, 0, 0]'); expect(state()).toBe(closed);
   await nativePage.getByLabel('Importe recibido, en pesos',{ exact: true }).fill('10.000');
   await nativePage.getByRole('checkbox',{ name: 'Verifiqué el ingreso y que corresponde a este paciente' }).check();
   await nativePage.getByRole('button',{ name: 'Registrar dinero recibido',exact: true }).click();
   await expect(nativePage.getByRole('status')).toContainText('El dinero quedó registrado por resolver');
   expect(receipts()).toBe('[1, 0, 1, 1]'); expect(state()).toBe(closed);
  } finally { await native.close(); }
  await page.goto(path);
  await page.getByText('Registrar dinero después de cancelar',{ exact: true }).click();
  const recordForm = page.locator('#late-deposit-record form');
  await recordForm.getByLabel('Importe recibido, en pesos',{ exact: true }).fill('25.000');
  await recordForm.getByLabel('Nota del registro (opcional)',{ exact: true }).fill('Segundo ingreso sintético');
  await recordForm.getByRole('checkbox').check();
  await loseThenRecover(recordForm,'Registrar dinero recibido');
  expect(receipts()).toBe('[2, 0, 2, 2]'); expect(state()).toBe(closed);
  const row = page.locator('section[aria-labelledby="deposit-financials-title"] li').filter({ hasText: /25\.000/ });
  await row.getByText('Corregir un error de carga',{ exact: true }).click();
  const correctForm = row.locator('form');
  await correctForm.getByRole('checkbox').check();
  const correction = await loseThenRecover(correctForm,'Sí, corregir este registro');
  expect(correction.late_action).toBe('correct'); expect(correction.amount).toBe('');
  expect(receipts()).toBe('[2, 1, 3, 3]'); expect(state()).toBe(closed);
  await expect(row).toContainText('Registro corregido');
  await expect(row.getByText('Corregir un error de carga',{ exact: true })).toHaveCount(0);
  expect(f.sql(`select private.appointment_deposit_summary('${f.businessId}','${appointmentId}','${patientId}')->>'unresolved_amount';`)).toBe('10000');
  const patientPage = await context.newPage();
  try {
   const token = f.sql(`select confirmation_token from public.appointments where id='${appointmentId}';`);
   await patientPage.goto('/turno/'+token);
   await expect(patientPage.getByText(/de dinero registrado por resolver con el consultorio/)).toContainText(/10\.000/);
   expect(await patientPage.locator('main').innerText()).not.toContain('Nota interna sintética');
   await expect(patientPage.locator('form[action="?/cancel"],form[action="?/reschedule"]')).toHaveCount(0);
  } finally { await patientPage.close(); }
  for (const theme of ['light','dark']) {
   await context.addCookies([{ name: 'cita-theme',value: theme,url: process.env.E2E_BASE_URL! }]);
   await page.goto(path);
   await page.getByText('Registrar dinero después de cancelar',{ exact: true }).click();
   for (const width of [320,390,768,1280,1600]) {
    await page.setViewportSize({ width,height: 900 });
    issues.push(...await layoutIssues(page,'main a:visible, main button:visible, main input:visible, main textarea:visible','main'));
    await alignTaskForCapture(page.locator('#late-deposit-record'));
    await page.screenshot({ path: info.outputPath(`late-money-${theme}-${width}.jpg`),type: 'jpeg',quality: 65 });
   }
  }
  expect(issues).toEqual([]);
  await health.assertAndAttach(info,'late-deposit-health');
  await info.attach('late-deposit-proof',{ body: JSON.stringify({ actualAuthAndSql: true,nativeValidationAndDraft: true,
   nativeMoneyRecorded: true,committedUnreadableRecordRecovered: true,committedUnreadableCorrectionRecovered: true,
   exactOperationFieldsPreserved: true,closedObligationAndAppointmentUnchanged: true,patientCurrentNetVisible: true,
   correctedFactRetained: true,issues,bankTransferVerified: false,emailDelivery: false }),contentType: 'application/json' });
 } finally {
  f.sql(`begin; delete from public.appointments where business_id='${f.businessId}' and id='${appointmentId}';
   delete from public.patients where business_id='${f.businessId}' and id='${patientId}';
   delete from public.deposit_policies where business_id='${f.businessId}'; update private.deposit_automation set enabled=${automation}; commit;`);
  expect(f.sql(`select count(*) from public.appointments where id='${appointmentId}';`)).toBe('0');
  expect(f.sql(`select count(*) from public.patients where id='${patientId}';`)).toBe('0');
 }
});
