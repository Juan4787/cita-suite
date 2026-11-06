import { expect, test, type BrowserContext, type Page } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { signInWithPassword } from './helpers/shared-auth';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';
import { applyThemeInPage, expectRenderedTheme } from './helpers/theme';
import { alignTaskForCapture } from './helpers/task-capture';

// P1 (plan 12.34). A real reception account against the real command: it cancels what has not
// started, the page explains what already happened, and every other actor is refused at the writer
// as well as on the screen. Synthetic practices only; no provider is contacted.
test('@candidate-behavior reception cancels a future appointment; past appointments, other roles and other practices cannot', async ({ page, browser, context }, info) => {
 test.setTimeout(240_000);
 const f = ownedAppointmentFixture();
 const businessId = randomUUID(), otherBusinessId = randomUUID(), professionalId = randomUUID(), serviceId = randomUUID(), patientId = randomUUID();
 const futureId = randomUUID(), pastId = randomUUID(), runningId = randomUUID(), withdrawnId = randomUUID();
 const password = `Owned-cancel-${randomUUID()}`;
 const people = ['owner', 'reception', 'professional', 'readonly', 'outsider'] as const;
 const email = Object.fromEntries(people.map(role => [role, `cancel-${role}-${randomUUID()}@example.test`])) as Record<(typeof people)[number], string>;
 const ids: Partial<Record<(typeof people)[number], string>> = {};
 const issues: LayoutIssue[] = [];
 const contexts: BrowserContext[] = [];
 let pageErrors = 0;
 page.on('pageerror', () => { pageErrors++; });
 const status = (id: string) => f.sql(`select status from public.appointments where id='${id}';`);
 const audits = (id: string) => f.sql(`select count(*) from public.audit_logs where entity_id='${id}' and action='appointment.cancelled';`);
 const revision = (id: string) => f.sql(`select private.appointment_semantic_revision('${businessId}','${id}');`);
 // The form's own action with the browser's session: what a stale or forged page would send.
 const cancelFrom = async (from: Page, id: string) => {
  const reply = await from.evaluate(async ({ id, fields }) => {
   const response = await fetch(`/odonto/turnos/${id}?/update_status`, { method: 'POST', credentials: 'same-origin',
    headers: { 'x-sveltekit-action': 'true', accept: 'application/json', 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(fields) });
   return response.text();
  }, { id, fields: { status: 'cancelled', reason: '', confirm_cancel: 'true', operation_id: randomUUID(), expected_revision: revision(id) } });
  return JSON.parse(reply) as { type: string; status?: number };
 };
 const signedIn = async (role: (typeof people)[number], business: string) => {
  const session = await browser.newContext({ baseURL: new URL(page.url()).origin });
  contexts.push(session);
  const other = await session.newPage();
  await signInWithPassword(other, email[role], password);
  await session.addCookies([{ name: 'active-business-id', value: business, url: new URL(other.url()).origin }]);
  return other;
 };
 const matrix = async (screen: string, anchor: string) => {
  for (const theme of ['light', 'dark'] as const) {
   await applyThemeInPage(page, theme); await expectRenderedTheme(page, theme);
   for (const width of [320, 390, 768, 1280, 1600]) {
    await page.setViewportSize({ width, height: 900 });
    await alignTaskForCapture(page.locator(anchor));
    issues.push(...await layoutIssues(page, 'main a:visible, main button:visible, main input:visible, main textarea:visible', 'main'));
    await page.screenshot({ path: info.outputPath(`${screen}-${theme}-${width}.jpg`), type: 'jpeg', quality: 65 });
   }
  }
  await applyThemeInPage(page, 'light');
  await page.setViewportSize({ width: 1280, height: 900 });
 };
 try {
  for (const role of people) {
   const created = await f.admin.auth.admin.createUser({ email: email[role], password, email_confirm: true });
   if (created.error || !created.data.user?.id) throw new Error('Could not create the owned cancellation account.');
   ids[role] = created.data.user.id;
  }
  f.sql(`begin;
   insert into public.businesses(id,name,slug,industry,timezone) values
    ('${businessId}','Cancelación sintética','reception-cancel-${businessId}','other','UTC'),
    ('${otherBusinessId}','Otro consultorio sintético','reception-cancel-${otherBusinessId}','other','UTC');
   update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null
    where business_id in ('${businessId}','${otherBusinessId}');
   insert into public.business_users(business_id,user_id,role,status,accepted_at) values
    ('${businessId}','${ids.owner}','owner','active',now()),('${businessId}','${ids.reception}','reception','active',now()),
    ('${businessId}','${ids.professional}','professional','active',now()),('${businessId}','${ids.readonly}','readonly','active',now()),
    ('${otherBusinessId}','${ids.outsider}','reception','active',now());
   insert into public.professionals(id,business_id,name) values('${professionalId}','${businessId}','Profesional sintético de cancelación');
   insert into public.services(id,business_id,name,duration_minutes) values('${serviceId}','${businessId}','Consulta sintética de cancelación',30);
   insert into public.professional_services(business_id,professional_id,service_id) values('${businessId}','${professionalId}','${serviceId}');
   insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes)
    select '${businessId}','${professionalId}',day,'08:00','18:00',30,0 from generate_series(0,6) day;
   insert into public.patients(id,business_id,owner_id,full_name,phone_raw,phone_e164) values('${patientId}','${businessId}','${ids.owner}','Paciente sintético de cancelación','3425048209','+5493425048209');
   insert into public.appointments(id,business_id,patient_id,service_id,professional_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
    select identifier,'${businessId}','${patientId}','${serviceId}','${professionalId}',starts,starts+interval '30 minutes','reserved','manual','Consulta sintética de cancelación','Profesional sintético de cancelación',30
    from (values
     ('${futureId}'::uuid,date_trunc('day',now())+interval '9 days 12 hours'),
     ('${withdrawnId}'::uuid,date_trunc('day',now())+interval '10 days 12 hours'),
     ('${pastId}'::uuid,now()-interval '3 hours'),
     ('${runningId}'::uuid,now()-interval '5 minutes')) t(identifier,starts);
   commit;`);

  await signInWithPassword(page, email.reception, password);
  const origin = new URL(page.url()).origin;
  await context.addCookies([{ name: 'active-business-id', value: businessId, url: origin }]);

  // A past appointment says so, and the writer agrees with the page.
  await page.goto(`/odonto/turnos/${pastId}`);
  await expect(page.locator('[data-started-badge]')).toHaveText('Turno pasado');
  await expect(page.locator('[data-started-notice]')).toContainText('Este turno ya pasó. Por eso no se puede cancelar.');
  await expect(page.locator('[data-cancel-panel]')).toHaveCount(0);
  await matrix('past-notice', '[data-started-notice]');
  expect(await cancelFrom(page, pastId)).toMatchObject({ type: 'failure', status: 409 });
  expect([status(pastId), audits(pastId)]).toEqual(['reserved', '0']);
  await page.goto(`/odonto/turnos/${runningId}`);
  await expect(page.locator('[data-started-badge]')).toHaveText('En curso');
  await expect(page.locator('[data-started-notice]')).toContainText('Este turno ya empezó.');
  expect(await cancelFrom(page, runningId)).toMatchObject({ type: 'failure', status: 409 });
  expect(status(runningId)).toBe('reserved');
  await page.goto(`/odonto/agenda?date=${f.sql(`select (starts_at at time zone 'UTC')::date from public.appointments where id='${pastId}';`)}`);
  await expect(page.getByRole('link', { name: /Paciente sintético de cancelación/ }).filter({ hasText: 'Turno pasado' }).first()).toBeVisible();

  // Other roles: no form on the page and no effect at the writer.
  for (const role of ['professional', 'readonly'] as const) {
   const other = await signedIn(role, businessId);
   await other.goto(`/odonto/turnos/${futureId}`);
   await expect(other.getByRole('heading', { level: 1 })).toBeVisible();
   await expect(other.locator('[data-cancel-panel]')).toHaveCount(0);
   expect(await cancelFrom(other, futureId)).toMatchObject({ type: 'failure', status: 403 });
  }
  // Reception of another practice cannot even read it, nor cancel it by its identifier.
  const outsider = await signedIn('outsider', otherBusinessId);
  expect((await outsider.goto(`/odonto/turnos/${futureId}`))?.status()).toBe(404);
  expect((await cancelFrom(outsider, futureId)).type).toBe('failure');
  expect([status(futureId), audits(futureId)]).toEqual(['reserved', '0']);

  // Reception cancels, and the result survives a reload.
  await page.goto(`/odonto/turnos/${futureId}`);
  const panel = page.locator('[data-cancel-panel]');
  await expect(panel).toBeInViewport();
  await panel.locator('summary').click();
  await expect(panel).toContainText('Vas a cancelar el turno de Paciente sintético de cancelación');
  await expect(panel).toContainText('El paciente no tiene correo cargado: avisale por otro medio.');
  await matrix('cancel-panel', '[data-cancel-panel]');
  await panel.getByRole('textbox', { name: 'Motivo (opcional)' }).fill('Lo pidió por teléfono');
  await panel.getByRole('checkbox', { name: 'Confirmo que quiero cancelar este turno.' }).check();
  await panel.getByRole('button', { name: 'Cancelar turno', exact: true }).click();
  await expect(page.getByRole('status')).toContainText('El turno quedó cancelado.');
  await expect(page.getByRole('status')).toBeFocused();
  expect([status(futureId), audits(futureId)]).toEqual(['cancelled', '1']);
  expect(f.sql(`select cancelled_by_user_id||' '||cancelled_reason from public.appointments where id='${futureId}';`)).toBe(`${ids.reception} Lo pidió por teléfono`);
  expect(f.sql(`select reason from public.appointment_slot_releases where appointment_id='${futureId}';`)).toBe('practice_cancelled');
  await page.reload();
  await expect(page.getByText('Cancelado', { exact: true }).first()).toBeVisible();
  await expect(page.getByText('Lo pidió por teléfono').first()).toBeVisible();
  await expect(page.locator('[data-cancel-panel]')).toHaveCount(0);

  // The permission goes away with the page already open.
  await page.goto(`/odonto/turnos/${withdrawnId}`);
  const stale = page.locator('[data-cancel-panel]');
  await stale.locator('summary').click();
  await stale.getByRole('checkbox', { name: 'Confirmo que quiero cancelar este turno.' }).check();
  f.sql(`update public.business_users set disabled_at=now() where business_id='${businessId}' and user_id='${ids.reception}';`);
  await stale.getByRole('button', { name: 'Cancelar turno', exact: true }).click();
  await expect(page.locator('[role="alert"], [role="status"]').first()).toBeVisible();
  expect([status(withdrawnId), audits(withdrawnId)]).toEqual(['reserved', '0']);

  expect(issues).toEqual([]);
  expect(pageErrors).toBe(0);
  await info.attach('reception-cancel-proof', { contentType: 'application/json', body: Buffer.from(JSON.stringify({ realReceptionRole: true,
   pastExplained: true, startedRefusedAtWriter: true, otherRolesRefused: ['professional', 'readonly'], otherPracticeRefused: true,
   resultPersisted: true, slotReleased: true, withdrawnPermissionRefused: true })) });
 } finally {
  for (const session of contexts) await session.close();
  f.sql(`begin; delete from public.appointments where business_id in ('${businessId}','${otherBusinessId}');
   delete from public.businesses where id in ('${businessId}','${otherBusinessId}'); commit;`);
  expect(f.sql(`select count(*) from public.businesses where id in ('${businessId}','${otherBusinessId}');`)).toBe('0');
  for (const id of Object.values(ids)) if (id) { const removed = await f.admin.auth.admin.deleteUser(id); expect(removed.error).toBeNull(); }
 }
});
