import { expect, test } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { loginWithSharedSession } from './helpers/shared-auth';
import { observeRenderHealth } from './helpers/render-health';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';
import { applyThemeInPage } from './helpers/theme';

test('@candidate-behavior isolated email preferences: independent settings, stale saves and native recovery', async ({ page, context, browser }, info) => {
 test.setTimeout(120_000);
 const f = ownedAppointmentFixture(), businessId = randomUUID();
 const health = await observeRenderHealth(page), issues: LayoutIssue[] = [];
 let pageErrors = 0;
 page.on('pageerror', () => { pageErrors++; });
 const base = new URL(process.env.E2E_BASE_URL!).origin;
 const policy = () => JSON.parse(f.sql(`select to_jsonb(p) from public.appointment_email_policies p where business_id='${businessId}';`));
 const audits = () => Number(f.sql(`select count(*) from public.audit_logs where business_id='${businessId}' and action='business.appointment_email_policy_updated';`));
 let native: Awaited<ReturnType<typeof browser.newContext>> | null = null;
 try {
  f.sql(`begin;
   insert into public.businesses(id,name,slug,industry) values('${businessId}','Preferencias sintéticas','email-${businessId}','other');
   update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='${businessId}';
   insert into public.business_users(business_id,user_id,role,status,accepted_at)
    select '${businessId}',id,'owner','active',now() from auth.users where email=:'owner_email'; commit;`, { owner_email: f.email });
  await loginWithSharedSession(page, { email: f.email, password: f.password });
  await context.addCookies([{ name: 'active-business-id', value: businessId, url: base }]);
  const before = policy();
  await page.goto('/odonto/configuracion/correo');
  await expect(page.getByRole('heading', { name: 'Correo y autogestión', exact: true })).toBeVisible();
  await expect(page.getByRole('status')).toContainText('Falta completar el remitente');
  expect(policy()).toEqual(before);
  await expect(page.getByLabel('Enviar comprobantes y recordatorios por email')).toBeChecked();
  await expect(page.getByLabel('Pedir email obligatorio al reservar online')).toBeChecked();
  for (const theme of ['light', 'dark'] as const) {
   await applyThemeInPage(page, theme);
   for (const width of [320, 390, 768, 1280, 1600]) {
    await page.setViewportSize({ width, height: 900 });
    issues.push(...await layoutIssues(page, 'main input:visible, main button:visible, main a:visible', 'main'));
    await page.screenshot({ path: info.outputPath(`email-preferences-${theme}-${width}.jpg`), type: 'jpeg', quality: 65, fullPage: true });
   }
  }
  await page.getByLabel('Enviar comprobantes y recordatorios por email').uncheck();
  await page.getByRole('button', { name: 'Guardar preferencias', exact: true }).click();
  await expect(page.getByRole('status').filter({ hasText: 'Se guardaron' })).toBeVisible();
  expect(policy()).toMatchObject({ email_enabled: false, require_email: true, sender_verified: false, revision: before.revision + 1 });
  const afterSave = policy();
  expect(audits()).toBe(1);
  // A second writer changes the same policy after this page observed it.
  f.sql(`begin; select set_config('request.jwt.claim.sub',user_id::text,true) from public.business_users where business_id='${businessId}' and role='owner';
   select public.save_appointment_email_policy('${businessId}',jsonb_build_object('email_enabled',false,'require_email',false,'show_cancel',true,'show_reschedule',true,'require_deposit_on_reschedule',true,'previous_deposit_disposition','forfeit'),${afterSave.revision}); commit;`);
  await page.getByLabel('Mostrar Cancelar', { exact: true }).uncheck();
  await page.getByRole('button', { name: 'Guardar preferencias', exact: true }).click();
  await expect(page.getByRole('status').filter({ hasText: 'Otra persona cambió' })).toBeVisible();
  await expect(page.getByLabel('Mostrar Cancelar', { exact: true })).not.toBeChecked();
  await expect(page.getByRole('button', { name: 'Guardar preferencias', exact: true })).toBeDisabled();
  expect(policy()).toMatchObject({ email_enabled: false, require_email: false, show_cancel: true, revision: afterSave.revision + 1 });
  expect(audits()).toBe(2);
  await page.getByRole('link', { name: 'Recargar configuración', exact: true }).click();
  await expect(page.getByLabel('Mostrar Cancelar', { exact: true })).toBeChecked();
  native = await browser.newContext({ javaScriptEnabled: false });
  await native.addCookies(await context.cookies());
  const noJsPage = await native.newPage();
  await noJsPage.goto(base + '/odonto/configuracion/correo');
  await noJsPage.getByLabel('Pedir email obligatorio al reservar online').check();
  await noJsPage.getByRole('button', { name: 'Guardar preferencias', exact: true }).click();
  await expect(noJsPage.getByRole('status').filter({ hasText: 'Se guardaron' })).toBeVisible();
  expect(policy()).toMatchObject({ email_enabled: false, require_email: true, sender_verified: false });
  expect(audits()).toBe(3);
  expect(issues).toEqual([]);
  expect(pageErrors).toBe(0);
  await health.assertAndAttach(info, 'email-preferences-render-health');
  await info.attach('email-preferences-proof', { contentType: 'application/json', body: Buffer.from(JSON.stringify({ independentSettings: true, currentReadiness: true, conflictPreservesDraft: true, nativeSave: true, issues, pageErrors })) });
 } finally {
  await native?.close();
  f.sql(`delete from public.businesses where id='${businessId}';`);
  expect(f.sql(`select count(*) from public.businesses where id='${businessId}';`)).toBe('0');
 }
});
