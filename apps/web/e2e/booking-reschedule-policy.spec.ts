import { expect, test } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';
import { applyThemeInPage, expectRenderedTheme } from './helpers/theme';
import { alignTaskForCapture } from './helpers/task-capture';

// Existing sequential hosted Playwright fallback: no approved host browser.
// Actual public POST/SQL, no provider delivery or real recipients.
test('@candidate-behavior isolated informed booking: stale policy, atomic retry and responsive disclosure', async ({ page }, info) => {
 test.setTimeout(150_000);
 const f = ownedAppointmentFixture();
 const businessId = randomUUID(), ownerId = randomUUID(), serviceId = randomUUID(), professionalId = randomUUID();
 const slug = `informed-booking-${businessId}`;
 const original: unknown = JSON.parse(f.sql(`select jsonb_build_object('deposit',(select enabled from private.deposit_automation where singleton),
  'reschedule',(select reschedule_enabled from private.appointment_management_runtime where singleton));`));
 if (typeof original !== 'object' || original === null || !('deposit' in original) || typeof original.deposit !== 'boolean' ||
  !('reschedule' in original) || typeof original.reschedule !== 'boolean') throw new Error('Invalid informed booking switch snapshot');
 const issues: LayoutIssue[] = [];
 let pageErrors = 0;
 page.on('pageerror', () => { pageErrors++; });
 try {
  f.sql(`begin;
   insert into auth.users(id,email) values('${ownerId}','informed-owner-${ownerId}@example.test');
   insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled,max_booking_days_ahead)
    values('${businessId}','Consultorio de reserva informada','${slug}','other','UTC',true,90);
   update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='${businessId}';
   insert into public.business_users(business_id,user_id,role,status,accepted_at) values('${businessId}','${ownerId}','owner','active',now());
   insert into public.professionals(id,business_id,name,is_public) values('${professionalId}','${businessId}','Profesional de reserva informada',true);
   insert into public.services(id,business_id,name,duration_minutes,is_public) values('${serviceId}','${businessId}','Consulta de reserva informada',30,true);
   insert into public.professional_services(business_id,professional_id,service_id) values('${businessId}','${professionalId}','${serviceId}');
   insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes)
    select '${businessId}','${professionalId}',day,'08:00','18:00',30,0 from generate_series(0,6) day;
   insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details)
    values('${businessId}',true,true,'fixed',40000,'Alias sintético sin cuenta bancaria');
   update private.deposit_automation set enabled=true;
   update private.appointment_management_runtime set reschedule_enabled=true;
   update public.appointment_email_policies set require_deposit_on_reschedule=false,previous_deposit_disposition='credit',revision=revision+1 where business_id='${businessId}';
   commit;`);
  const date = f.sql("select (now() at time zone 'UTC')::date+25;");
  await page.goto(`/reservar/${slug}?service_id=${serviceId}&professional_id=${professionalId}&date=${date}`);
  await page.getByRole('link', { name: /^\d{2}:\d{2}$/ }).first().click();
  await page.getByLabel('Nombre y apellido', { exact: true }).fill('Paciente Reserva Informada');
  await page.getByLabel('Teléfono', { exact: true }).fill('3425048230');
  await page.getByLabel('Correo electrónico', { exact: true }).fill('Informed+Booking@Example.test');
  const confirm = page.getByRole('button', { name: 'Confirmar reserva', exact: true });
  const attempt = await page.locator('[name="idempotency_key"]').inputValue();
  const notice = page.locator('[data-reschedule-policy-notice]');
  await expect(notice).toContainText('seguirá a cuenta');
  await expect(notice).toContainText('no se pedirá una nueva');
  const initial = JSON.parse(await page.locator('[name="reschedule_policy_terms"]').inputValue());
  expect(initial).toMatchObject({ schema_version: 1, require_deposit_on_reschedule: false, previous_deposit_disposition: 'credit' });
  expect(await notice.evaluate((element) => {
   const submit = element.closest('form')?.querySelector('button[type="submit"]');
   return Boolean(submit && element.compareDocumentPosition(submit) & Node.DOCUMENT_POSITION_FOLLOWING);
  })).toBe(true);
  for (const theme of ['light', 'dark'] as const) {
   await applyThemeInPage(page, theme); await expectRenderedTheme(page, theme);
   for (const width of [320, 390, 768, 1280, 1600]) {
    await page.setViewportSize({ width, height: 900 });
    await alignTaskForCapture(notice);
    issues.push(...await layoutIssues(page, '.patient-booking-form button:visible, .patient-booking-form input:visible', '.patient-booking-form'));
    await page.screenshot({ path: info.outputPath(`informed-booking-${theme}-${width}.jpg`), type: 'jpeg', quality: 65 });
   }
  }
  await page.setViewportSize({ width: 1280, height: 900 });
  f.sql(`begin; select set_config('request.jwt.claim.sub','${ownerId}',true);
   select public.save_appointment_email_policy('${businessId}',jsonb_build_object('email_enabled',true,'require_email',true,'show_cancel',true,'show_reschedule',true,
    'require_deposit_on_reschedule',true,'previous_deposit_disposition','forfeit'),${initial.policy_revision}); commit;`);
  await confirm.click();
  await expect(page.getByText(/Las condiciones para reprogramar cambiaron mientras reservabas/)).toBeVisible();
  expect(f.sql(`select jsonb_build_array((select count(*) from public.patients where business_id='${businessId}'),(select count(*) from public.appointments where business_id='${businessId}'),
   (select count(*) from private.public_booking_email_contacts where business_id='${businessId}'),(select count(*) from public.audit_logs where business_id='${businessId}' and entity_type='appointment'));`)).toBe('[0, 0, 0, 0]');
  await expect(page.getByLabel('Nombre y apellido', { exact: true })).toHaveValue('Paciente Reserva Informada');
  await expect(page.getByLabel('Correo electrónico', { exact: true })).toHaveValue('Informed+Booking@Example.test');
  await expect(page.locator('[name="idempotency_key"]')).toHaveValue(attempt);
  // The failure refreshes only the offer; the filled fields and operation key
  // remain available for a deliberate second confirmation.
  await expect(notice).toContainText('no se aplicará'); await expect(notice).toContainText('se pedirá una nueva');
  const acceptedAttempt = await page.locator('[name="idempotency_key"]').inputValue();
  expect(acceptedAttempt).toBe(attempt);
  await confirm.click();
  await expect(page).toHaveURL(/\/turno\//);
  expect(f.sql(`select jsonb_build_array((select count(*) from public.appointments where business_id='${businessId}'),
   (select count(*) from public.appointment_management_states where business_id='${businessId}' and terms_acknowledged and require_deposit_on_reschedule and previous_deposit_disposition='forfeit'),
   (select count(*) from public.appointment_deposit_requirements where business_id='${businessId}' and is_current and status='pending' and amount=40000),
   (select count(*) from public.audit_logs where business_id='${businessId}' and action='appointment.reschedule_policy_informed'),
   (select count(*) from public.appointments where business_id='${businessId}' and creation_request_key='${acceptedAttempt}'));`)).toBe('[1, 1, 1, 1, 1]');
  // Exercise the consequence of the actual initial disclosure; do not seed
  // terms_acknowledged as the older management fixtures intentionally do.
  const appointmentId = f.sql(`select id from public.appointments where business_id='${businessId}';`);
  expect(appointmentId).toMatch(/^[a-f0-9-]{36}$/);
  f.sql(`begin; select set_config('request.jwt.claim.sub','${ownerId}',true);
   select public.set_appointment_deposit('${businessId}','${appointmentId}','paid',
    (select revision from public.appointment_deposits where appointment_id='${appointmentId}'),null); commit;`);
  await page.reload();
  const moneyState = () => f.sql(`select jsonb_build_array(a.starts_at,a.status,
   (select jsonb_agg(jsonb_build_array(status,amount,allocation,is_current) order by ordinal) from public.appointment_deposit_requirements where appointment_id=a.id))
   from public.appointments a where a.id='${appointmentId}';`);
  const beforeMove = moneyState();
  await page.getByRole('link', { name: 'Reprogramar turno', exact: true }).click();
  const targetDate = f.sql(`select to_char(starts_at::date+1,'YYYY-MM-DD') from public.appointments where id='${appointmentId}';`);
  await page.getByLabel('Día para el nuevo turno').fill(targetDate);
  await page.getByRole('button', { name: 'Ver horarios', exact: true }).click();
  await page.locator('[aria-label="Horarios disponibles"] a').first().click();
  await expect(page.getByText(/La seña anterior de.*dejará de aplicarse/)).toBeVisible();
  await expect(page.getByText(/Nueva seña pendiente/)).toBeVisible();
  expect(moneyState()).toBe(beforeMove);
  await page.getByRole('button', { name: 'Confirmar reprogramación', exact: true }).click();
  await expect(page.getByText('La reprogramación quedó registrada.', { exact: true })).toBeVisible();
  expect(f.sql(`select jsonb_build_array((select status from public.appointments where id='${appointmentId}'),
   (select count(*) from public.appointment_deposit_requirements where appointment_id='${appointmentId}' and status='paid' and allocation='forfeited'),
   (select count(*) from public.appointment_deposit_requirements where appointment_id='${appointmentId}' and is_current and status='pending' and amount=40000));`)).toBe('["reserved", 1, 1]');
  await page.getByRole('link', { name: 'Cancelar turno', exact: true }).click();
  await page.getByRole('button', { name: 'Sí, cancelar turno', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Turno cancelado', exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Cancelar turno', exact: true })).toHaveCount(0);
  await expect(page.getByRole('link', { name: 'Reprogramar turno', exact: true })).toHaveCount(0);
  expect(pageErrors).toBe(0); expect(issues).toEqual([]);
  await info.attach('informed-booking-proof', { body: JSON.stringify({ actualPublicPost: true, staleRejectedAtomically: true, attemptAndAliasPreserved: true, freshTermsPersisted: true,
   paymentRecordedBySqlCommand: true, actualInformedReschedule: true, originalPaymentRetainedAsForfeited: true, oneNewPendingDeposit: true, cancelledHasNeitherAction: true, issues, pageErrors }), contentType: 'application/json' });
 } finally {
  f.sql(`begin; delete from public.appointments where business_id='${businessId}'; delete from public.businesses where id='${businessId}'; delete from auth.users where id='${ownerId}';
   update private.deposit_automation set enabled=${original.deposit}; update private.appointment_management_runtime set reschedule_enabled=${original.reschedule}; commit;`);
  expect(f.sql(`select count(*) from public.businesses where id='${businessId}';`)).toBe('0');
 }
});
