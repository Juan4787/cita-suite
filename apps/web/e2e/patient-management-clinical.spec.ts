import { expect, test } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { ownedAppointmentFixture } from './helpers/owned-appointment-fixture';
import { must } from './helpers/fixture-db';
import { layoutIssues, type LayoutIssue } from './helpers/layout-usability';

// Real isolated SQL/PostgREST/Storage and browser; no external clinical data or
// provider email. Native form and unreadable response exercise the actual page.
for (const brand of ['cita-suite', 'natalia'] as const) {
 test(`@candidate-behavior isolated patient clinical management ${brand}: information, uncertain response, documents and revoked contact`, async ({ page, context, browser, request }, info) => {
  test.setTimeout(180_000);
  const f = ownedAppointmentFixture();
  const owner=randomUUID(), business=randomUUID(), patient=randomUUID(), professional=randomUUID(), service=randomUUID(), appointment=randomUUID();
  const integration=randomUUID(), integrationKey=randomUUID().replaceAll('-','');
  const origin=new URL(process.env.E2E_BASE_URL!).origin;
  if (!origin.startsWith('http://127.0.0.1:')) throw new Error('Clinical management audit requires its owned loopback app');
  const previous=f.sql('select uploads_enabled from public.clinical_storage_budget where singleton;');
  if (!['t','f'].includes(previous)) throw new Error('Missing clinical budget fixture state');
  const issues:LayoutIssue[]=[];
  const pageErrors:string[]=[];page.on('pageerror',cause=>pageErrors.push(cause.message));
  let phase='fixture';
  let primaryFailure:unknown;
  try {
   f.sql(`begin;
    insert into auth.users(id,email) values('${owner}','clinical-management-${owner}@example.test');
    insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled,patient_documents_enabled)
     values('${business}','Consultorio sintético clínico','clinical-management-${business}','other','UTC',true,false);
    update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
     paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='${business}';
    insert into public.business_users(business_id,user_id,role,status,accepted_at) values('${business}','${owner}','owner','active',now());
    insert into public.professionals(id,business_id,name) values('${professional}','${business}','Profesional sintética');
    insert into public.services(id,business_id,name,duration_minutes) values('${service}','${business}','Consulta sintética',60);
    insert into public.professional_services(business_id,professional_id,service_id) values('${business}','${professional}','${service}');
    insert into public.patients(id,business_id,owner_id,full_name,email) values('${patient}','${business}','${owner}','Paciente sintético clínico','clinical-${patient}@example.test');
    insert into public.appointments(id,business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
     service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
     values('${appointment}','${business}','${patient}','${professional}','${service}',now()+interval '20 days',now()+interval '20 days 1 hour',
     'reserved','manual','Consulta sintética','Profesional sintética',60);
    insert into public.booking_integrations(id,business_id,public_key,name,is_active,theme,allowed_origins,allowed_service_ids,allowed_professional_ids)
     values('${integration}','${business}','${integrationKey}','Synthetic clinical management',true,'${brand}',array['${origin}'],array['${service}']::uuid[],array['${professional}']::uuid[]);
    insert into public.appointment_booking_contexts(appointment_id,business_id,integration_id,integration_revision,contract_version,theme_snapshot,entry_point,modality,context_fingerprint)
     values('${appointment}','${business}','${integration}',1,1,'${brand}','public_page','in_person',repeat('b',64));
    update public.clinical_storage_budget set uploads_enabled=true where singleton;
    update public.clinical_business_storage_budget set uploads_enabled=true where business_id='${business}';
    update public.businesses set patient_documents_enabled=true where id='${business}';
    do $$ begin
     perform set_config('request.jwt.claim.sub','${owner}',true);
     perform public.revoke_appointment_management_access('${business}','${appointment}','${randomUUID()}',private.appointment_semantic_revision('${business}','${appointment}'));
    end $$;
    commit;`);
   const legacy=f.sql(`select confirmation_token from public.appointments where id='${appointment}';`);
   const capability=f.sql(`select public.issue_appointment_management_capability('${business}','${appointment}',2);`);
   const path=`/gestion/${capability}`;
   phase='auxiliary_scope';
   await page.goto(path);
   await expect(page.getByRole('heading',{name:'Último paso: activá el recordatorio'})).toBeVisible();
   await expect(page.getByRole('link',{name:'Ver y ampliar mis datos'})).toHaveCount(0);
   expect((await request.get(`${path}/informacion`)).status()).toBe(404);
   f.sql(`insert into public.appointment_patient_information_contexts(business_id,appointment_id,patient_id_snapshot,schema_snapshot)
     values('${business}','${appointment}','${patient}','[{"id":"coverage","label":"Cobertura","kind":"text","required":false,"maxLength":100,"patientField":"insurance"}]');`);
   f.sql(`update public.businesses set public_booking_enabled=false where id='${business}';`);
   await page.goto(path);
   await expect(page.getByRole('heading',{name:'Último paso: activá el recordatorio'})).toBeVisible();
   await expect(page.getByRole('link',{name:'Ver y ampliar mis datos'})).toBeVisible();
   f.sql(`update public.business_subscriptions set commercial_access_enabled=false where business_id='${business}';`);
   await page.goto(path);
   await expect(page.getByRole('heading',{name:'Último paso: activá el recordatorio'})).toHaveCount(0);
   await expect(page.getByRole('link',{name:'Ver y ampliar mis datos'})).toHaveCount(0);
   expect((await request.get(`${path}/informacion`)).status()).toBe(404);
   f.sql(`update public.business_subscriptions set commercial_access_enabled=true where business_id='${business}';
    update public.businesses set public_booking_enabled=true where id='${business}';`);
   phase='calendar_and_receipt_authority';
   await page.goto(path);
   const receiptLink=page.getByRole('link',{name:'Guardar comprobante',exact:true});
   await expect(receiptLink).toHaveAttribute('href',`${path}/comprobante.pdf`);
   const [receiptDownload]=await Promise.all([page.waitForEvent('download'),receiptLink.click()]);
   const receiptPath=info.outputPath('synthetic-management-receipt.pdf');
   await receiptDownload.saveAs(receiptPath);
   expect((await readFile(receiptPath)).subarray(0,5).toString()).toBe('%PDF-');
   expect((await request.get(`/turno/${legacy}/comprobante.pdf`)).status()).toBe(404);
   const beforeCalendarRevision=f.sql(`select private.appointment_semantic_revision('${business}','${appointment}');`);
   const calendarResponse=await request.get(`${path}/calendario.ics?p=phone`);
   expect(calendarResponse.status()).toBe(200);
   expect(calendarResponse.headers()['referrer-policy']).toBe('no-referrer');
   const calendarText=await calendarResponse.text();
   const calendarUid=calendarText.match(/^UID:([^\r\n]+)/m)?.[1];
   expect(calendarUid).toBeTruthy();
   const savedCalendarCount=f.sql(`select calendar_action_count from public.appointments where id='${appointment}';`);
   expect(savedCalendarCount).toBe('1');
   const stableCalendar=await request.get(`/turno/${legacy}/calendario.ics`);
   expect(stableCalendar.status()).toBe(200);
   expect((await stableCalendar.text()).match(/^UID:([^\r\n]+)/m)?.[1]).toBe(calendarUid);
   expect(f.sql(`select calendar_action_count from public.appointments where id='${appointment}';`)).toBe(savedCalendarCount);
   expect((await request.get(`${path}/calendario-descargar.ics`)).headers()['content-disposition']).toContain('attachment');
   // Do not follow an external editor redirect; this verifies our route/SQL,
   // not a new Google or Microsoft account operation.
   const googleOpening=await request.get(`${path}/ir/google?source=android_native_fallback`,{maxRedirects:0});
   expect(googleOpening.status()).toBe(302);expect(googleOpening.headers().location).toContain('https://calendar.google.com/');
   const outlookOpening=await request.get(`${path}/ir/outlook`,{maxRedirects:0});
   expect(outlookOpening.status()).toBe(302);expect(outlookOpening.headers().location).toContain('https://outlook.live.com/');
   expect(f.sql(`select calendar_action_count from public.appointments where id='${appointment}';`)).toBe('4');
   expect((await request.post(`${path}/calendario-intent`,{data:{variant:'data',legacy:true}})).status()).toBe(204);
   expect(f.sql(`select calendar_action_count from public.appointments where id='${appointment}';`)).toBe('4');
   expect(f.sql(`select count(*) from public.audit_logs where entity_id='${appointment}' and action='appointment.calendar_intent_attempt';`)).toBe('1');
   expect(f.sql(`select count(*) from public.audit_logs where entity_id='${appointment}' and action='appointment.calendar_action';`)).toBe('4');
   expect(f.sql(`select private.appointment_semantic_revision('${business}','${appointment}');`)).toBe(beforeCalendarRevision);
   phase='read_and_navigation';
   const response=await request.get(`${path}/informacion`);
   expect(response.status()).toBe(200);expect(response.headers()['cache-control']).toContain('no-store');
   expect(response.headers()['referrer-policy']).toBe('same-origin');expect(response.headers()['x-robots-tag']).toContain('noindex');
   expect((await request.get(`/turno/${legacy}/informacion`)).status()).toBe(404);
   await page.goto(path);
   await expect(page.getByRole('link',{name:'Ver y ampliar mis datos'})).toHaveAttribute('href',`${path}/informacion`);
   await page.getByRole('link',{name:'Ver y ampliar mis datos'}).click();
   await expect(page.getByRole('link',{name:'Volver a mi turno'})).toHaveAttribute('href',path);
   phase='visual_matrix';
   for(const theme of ['light','dark']) {
    await context.addCookies([{name:'cita-theme',value:theme,url:origin}]);
    await page.goto(`${path}/informacion?color_mode=${theme}`);
    if(brand==='natalia') await expect(page.locator('[data-booking-color-mode]').first()).toHaveAttribute('data-booking-color-mode',theme);
    else expect(await page.locator('html').evaluate(el=>el.classList.contains('dark'))).toBe(theme==='dark');
    for(const width of [320,390,768,1280,1600]) {
     await page.setViewportSize({width,height:900});
     issues.push(...await layoutIssues(page,'main a:visible, main button:visible, main input:visible, main textarea:visible','main'));
     await page.screenshot({path:info.outputPath(`clinical-${theme}-${width}.jpg`),type:'jpeg',quality:65});
    }
   }
   phase='native_form';
   const native=await browser.newContext({javaScriptEnabled:false,baseURL:origin});
   try {
    const nativePage=await native.newPage();await nativePage.goto(`${path}/informacion`);
    await nativePage.getByLabel('Cobertura (opcional)',{exact:true}).fill('Native coverage');
    await nativePage.getByRole('button',{name:'Guardar información',exact:true}).click();
    await expect(nativePage.getByRole('status')).toContainText('La información quedó guardada');
   } finally { await native.close(); }
   expect(f.sql(`select insurance from public.patients where id='${patient}';`)).toBe('Native coverage');
   phase='uncertain_form_response';
   await page.goto(`${path}/informacion`);
   const coverage=page.getByLabel('Cobertura (opcional)',{exact:true});
   // Native behavior is checked above. This case deliberately exercises the
   // enhanced handler: removal of SSR value is evidence that binding hydrated.
   await expect(coverage).not.toHaveAttribute('value');
   await coverage.fill('Uncertain response coverage');
   await expect(coverage).toHaveValue('Uncertain response coverage');
   const key=await page.locator('input[name=request_key]').inputValue();
   let consumed=false;
   await page.route(url=>url.pathname===`${path}/informacion`,async route=>{
    if(route.request().method()!=='POST'||consumed) return route.continue();
    expect(route.request().headers()['x-sveltekit-action']).toBe('true');
    consumed=true;
    const committed=await route.fetch();expect(committed.status()).toBe(200);
    await route.fulfill({status:200,contentType:'application/json',body:'unreadable committed action response'});
   });
   await page.getByRole('button',{name:'Guardar información',exact:true}).click();
   await expect.poll(()=>consumed,{message:'The actual enhanced POST must be intercepted after committing'}).toBe(true);
   await expect(page.getByRole('alert')).toContainText('No pudimos comprobar el envío');
   await expect(page.getByRole('alert')).toBeFocused();
   await expect(page.locator('input[name=request_key]')).toHaveValue(key);
   await expect(page.getByLabel('Cobertura (opcional)',{exact:true})).toHaveValue('Uncertain response coverage');
   expect(f.sql(`select count(*) from public.appointment_intake_submissions where appointment_id='${appointment}';`)).toBe('2');
   await page.getByRole('button',{name:'Guardar información',exact:true}).click();
   await expect(page.getByRole('status')).toContainText('La información quedó guardada');
   expect(f.sql(`select count(*) from public.appointment_intake_submissions where appointment_id='${appointment}';`)).toBe('2');
   phase='upload_document';
   await page.getByLabel('Documento',{exact:true}).setInputFiles({name:'synthetic.png',mimeType:'image/png',
    buffer:Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==','base64')});
   await page.getByRole('button',{name:'Adjuntar documento',exact:true}).click();
   await expect(page.getByRole('status').filter({hasText:'El documento quedó guardado'})).toBeVisible();
   phase='stored_file_readback';
   const file=await must(f.admin.from('patient_radiographs').select('id,status').eq('business_id',business).single());
   expect(file.status).toBe('ready');
   expect((await request.post(`/turno/${legacy}/documentos/${file.id}/complete`)).status()).toBe(404);
   phase='contact_revocation';
   f.sql(`update public.patients set email='corrected-clinical-${patient}@example.test' where id='${patient}';`);
   expect((await request.get(`${path}/informacion`)).status()).toBe(404);
   expect((await request.post(`${path}/documentos/${file.id}/complete`)).status()).toBe(404);
   expect((await request.get(`${path}/comprobante.pdf`)).status()).toBe(404);
   expect((await request.get(`${path}/calendario.ics`)).status()).toBe(404);
   expect((await request.post(`${path}/calendario-intent`,{data:{variant:'type'}})).status()).toBe(204);
   const stillReadableCalendar=await request.get(`/turno/${legacy}/calendario.ics`);
   expect(stillReadableCalendar.status()).toBe(200);
   expect((await stillReadableCalendar.text()).match(/^UID:([^\r\n]+)/m)?.[1]).toBe(calendarUid);
   expect(f.sql(`select calendar_action_count from public.appointments where id='${appointment}';`)).toBe('4');
   expect(f.sql(`select count(*) from public.audit_logs where entity_id='${appointment}' and action='appointment.calendar_intent_attempt';`)).toBe('1');
   const fresh=f.sql(`select public.issue_appointment_management_capability('${business}','${appointment}',2);`);
   const currentReceipt=await request.get(`/gestion/${fresh}/comprobante.pdf`);
   expect(currentReceipt.status()).toBe(200);expect((await currentReceipt.body()).subarray(0,5).toString()).toBe('%PDF-');
   expect((await request.get(`/gestion/${fresh}/informacion`)).status()).toBe(200);
   expect((await request.post(`/gestion/${fresh}/documentos/${file.id}/complete`)).status()).toBe(200);
   expect(f.sql(`select count(*) from public.audit_logs where entity_id='${file.id}' and action='clinical_document.patient_upload_completed';`)).toBe('1');
   phase='layout_and_browser_errors';
   expect(issues).toEqual([]);expect(pageErrors).toEqual([]);
   await info.attach('clinical-management-proof',{body:JSON.stringify({brand,themes:['light','dark'],widths:[320,390,768,1280,1600],
    auxiliaryScope:true,calendarObservations:true,stableCalendarUid:true,receiptDownload:true,receiptRevocation:true,auditOnlyIntent:true,nativeForm:true,unreadableCommittedResponse:true,replayWithoutDuplicate:true,realIsolatedStorage:true,revocation:true,issues,pageErrors}),contentType:'application/json'});
  } catch(cause) {
   primaryFailure=cause;
   await info.attach('clinical-failure-phase',{body:JSON.stringify({phase}),contentType:'application/json'});
   throw cause;
  } finally {
   try {
   const files=await must(f.admin.from('patient_radiographs').select('storage_path').eq('business_id',business));
   const paths=files.map(file=>file.storage_path).filter((path):path is string=>typeof path==='string');
   if(paths.length) await must(f.admin.storage.from('patient-clinical-files').remove(paths));
   f.sql(`begin;
    select private.clinical_budget_lock();
    update public.clinical_upload_slots set expires_at=clock_timestamp()-interval '1 second' where business_id='${business}';
    select private.release_expired_clinical_reservations();
    delete from public.clinical_upload_slots where business_id='${business}';
    delete from public.patient_radiographs where business_id='${business}';
    delete from public.appointments where business_id='${business}';
    delete from public.booking_integrations where business_id='${business}';
    delete from public.businesses where id='${business}' and slug='clinical-management-${business}';
    delete from auth.users where id='${owner}' and email='clinical-management-${owner}@example.test';
    update public.clinical_storage_budget set uploads_enabled='${previous}'::boolean where singleton;
    commit;`);
   expect(f.sql(`select count(*) from public.businesses where id='${business}';`)).toBe('0');
   expect(f.sql(`select count(*) from auth.users where id='${owner}';`)).toBe('0');
   } catch(cleanupFailure) {
    if(primaryFailure) throw new AggregateError([primaryFailure,cleanupFailure], 'Clinical browser operation and fixture cleanup both failed');
    throw cleanupFailure;
   }
  }
 });
}
