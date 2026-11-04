-- AC09: clinical information retains its own active/future/commercial scope.
-- A stable calendar token is not replacement management authority.
begin;
select extensions.plan(15);
create temporary table information_access_fixture(label text primary key,value text not null);
create function pg_temp.iv(p_label text) returns text language sql as $$
 select value from information_access_fixture where label=p_label
$$;
create function pg_temp.iid(p_label text) returns uuid language sql as $$ select pg_temp.iv(p_label)::uuid $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid();
 s uuid:=gen_random_uuid(); patient uuid; a uuid; token text; begin
 insert into auth.users(id,email) values(u,'information-access-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone)
 values(b,'Synthetic document access',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'Synthetic information professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Synthetic information service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(business_id,owner_id,full_name,email)
 values(b,u,'Synthetic information patient','initial-information@example.test') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,p,s,now()+interval '20 days',now()+interval '20 days 1 hour','reserved','manual',
  'Synthetic information service','Synthetic information professional',60) returning id,confirmation_token into a,token;
 insert into public.appointment_patient_information_contexts(business_id,appointment_id,patient_id_snapshot,schema_snapshot)
 values(b,a,patient,'[{"id":"coverage","label":"Cobertura","kind":"text","required":false,"maxLength":100,"patientField":"insurance"}]');
 insert into information_access_fixture values('business',b::text),('owner',u::text),('appointment',a::text),('patient',patient::text),('legacy',token),
  ('schema_hash',public.get_public_booking_information(token)->>'schema_hash');
end $$;
select set_config('request.jwt.claim.role','service_role',true);
update public.clinical_storage_budget set uploads_enabled=true where singleton;
update public.clinical_business_storage_budget set uploads_enabled=true where business_id=pg_temp.iid('business');
update public.businesses set patient_documents_enabled=true where id=pg_temp.iid('business');
insert into information_access_fixture select 'legacy_file', (public.begin_public_patient_document_upload(
 pg_temp.iv('legacy'),gen_random_uuid(),'legacy.pdf','application/pdf',100,repeat('a',64))).id::text;
select extensions.is((public.get_public_patient_document_upload(pg_temp.iv('legacy'),pg_temp.iid('legacy_file'))).status,'uploading',
 'Legacy current access starts and recovers its own pending document');
do $$ begin
 perform set_config('request.jwt.claim.sub',pg_temp.iv('owner'),true);
 perform public.revoke_appointment_management_access(pg_temp.iid('business'),pg_temp.iid('appointment'),gen_random_uuid(),
  private.appointment_semantic_revision(pg_temp.iid('business'),pg_temp.iid('appointment')));
 perform set_config('request.jwt.claim.sub','',true);
end $$;
select extensions.throws_ok($q$select public.get_public_patient_document_upload(pg_temp.iv('legacy'),pg_temp.iid('legacy_file'))$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','Revoked legacy document reads do not bypass management');
do $$ begin
 begin
  perform public.complete_public_patient_document_upload(pg_temp.iv('legacy'),pg_temp.iid('legacy_file'),100,'application/pdf');
  raise exception 'REVOKED_LEGACY_DOCUMENT_COMPLETION_ALLOWED';
 exception when others then if sqlerrm is distinct from 'BOOKING_INFORMATION_UNAVAILABLE' then raise; end if; end;
 if (select status from public.patient_radiographs where id=pg_temp.iid('legacy_file')) is distinct from 'uploading'
  or exists(select 1 from public.audit_logs where entity_id=pg_temp.iid('legacy_file') and action='clinical_document.patient_upload_completed') then
  raise exception 'REVOKED_DOCUMENT_PARTIAL_COMPLETION'; end if;
end $$;
select extensions.pass('Revoked completion leaves pending file and clinical audit untouched');
insert into information_access_fixture values('capability',public.issue_appointment_management_capability(
 pg_temp.iid('business'),pg_temp.iid('appointment'),2));
select extensions.throws_ok($q$select public.get_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('legacy_file'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','A new management generation cannot complete a pending upload started by the former one');
insert into information_access_fixture select 'current_file', (public.begin_public_patient_document_upload(
 pg_temp.iv('capability'),gen_random_uuid(),'current.pdf','application/pdf',100,repeat('b',64),null,false)).id::text;
select extensions.is((public.get_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('current_file'),false)).status,'uploading',
 'Explicit capability can start and recover a new pending document');
-- Completion owns the preexisting grace; forms and new starts stay future-only.
update public.appointments set starts_at=clock_timestamp()-interval '1 minute',ends_at=clock_timestamp()+interval '59 minutes'
 where id=pg_temp.iid('appointment');
select extensions.is((public.get_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('current_file'),false)).id,pg_temp.iid('current_file'),
 'A valid upload lease permits finishing an already started upload after appointment start');
select extensions.throws_ok($q$select public.begin_public_patient_document_upload(pg_temp.iv('capability'),gen_random_uuid(),
 'late.pdf','application/pdf',100,repeat('c',64),null,false)$q$,'P0001','BOOKING_INFORMATION_UNAVAILABLE','The completion grace never permits a new upload');
select extensions.is(public.complete_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('current_file'),100,'application/pdf',false),
 pg_temp.iid('current_file'),'Completion during grace preserves the SQL file/profile/audit transaction (storage verification is separate)');
select extensions.is(public.complete_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('current_file'),100,'application/pdf',false),
 pg_temp.iid('current_file'),'A lost completion response recovers the existing ready file');
update public.clinical_upload_slots set expires_at=clock_timestamp()-interval '1 second' where file_id=pg_temp.iid('current_file');
update public.patient_radiographs set ready_at=clock_timestamp()-interval '16 minutes' where id=pg_temp.iid('current_file');
select extensions.throws_ok($q$select public.get_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('current_file'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','Completion grace is bounded and does not expose past documents indefinitely');
update public.appointments set starts_at=now()+interval '20 days',ends_at=now()+interval '20 days 1 hour' where id=pg_temp.iid('appointment');
insert into information_access_fixture select 'contact_pending', (public.begin_public_patient_document_upload(
 pg_temp.iv('capability'),gen_random_uuid(),'contact.pdf','application/pdf',100,repeat('c',64),null,false)).id::text;
create function pg_temp.expire_document_during_audit() returns trigger language plpgsql as $$
begin
 if new.entity_id=pg_temp.iid('contact_pending') and new.action='clinical_document.patient_upload_completed' then
  perform pg_sleep_until((select expires_at+interval '25 milliseconds' from private.appointment_management_capabilities
   where token_hash=encode(extensions.digest(pg_temp.iv('capability'),'sha256'),'hex')));
 end if;
 return new;
end $$;
create trigger expire_document_during_audit before insert on public.audit_logs for each row execute function pg_temp.expire_document_during_audit();
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 second'
 where token_hash=encode(extensions.digest(pg_temp.iv('capability'),'sha256'),'hex');
do $$ declare before_file jsonb; before_patient jsonb; before_slots jsonb; before_budget jsonb; audit_count bigint; begin
 select to_jsonb(f) into before_file from public.patient_radiographs f where id=pg_temp.iid('contact_pending');
 select to_jsonb(p) into before_patient from public.patients p where id=pg_temp.iid('patient');
 select jsonb_agg(to_jsonb(s)) into before_slots from public.clinical_upload_slots s where file_id=pg_temp.iid('contact_pending');
 select to_jsonb(b) into before_budget from public.clinical_storage_budget b where singleton;
 select count(*) into audit_count from public.audit_logs where entity_id=pg_temp.iid('contact_pending');
 begin
  perform public.complete_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('contact_pending'),100,'application/pdf',false);
  raise exception 'EXPIRED_DOCUMENT_COMPLETION_COMMITTED';
 exception when others then if sqlerrm is distinct from 'BOOKING_INFORMATION_UNAVAILABLE' then raise; end if; end;
 if (select to_jsonb(f) from public.patient_radiographs f where id=pg_temp.iid('contact_pending')) is distinct from before_file
  or (select to_jsonb(p) from public.patients p where id=pg_temp.iid('patient')) is distinct from before_patient
  or (select jsonb_agg(to_jsonb(s)) from public.clinical_upload_slots s where file_id=pg_temp.iid('contact_pending')) is distinct from before_slots
  or (select to_jsonb(b) from public.clinical_storage_budget b where singleton) is distinct from before_budget
  or (select count(*) from public.audit_logs where entity_id=pg_temp.iid('contact_pending'))<>audit_count then
  raise exception 'EXPIRED_DOCUMENT_COMPLETION_PARTIAL_EFFECTS'; end if;
end $$;
drop trigger expire_document_during_audit on public.audit_logs;
select extensions.pass('Expiry during completion audit rolls back Ready, patient activity, upload lease, budget and audit');
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 day'
 where token_hash=encode(extensions.digest(pg_temp.iv('capability'),'sha256'),'hex');
update public.patients set email='changed-document@example.test' where id=pg_temp.iid('patient');
select extensions.throws_ok($q$select public.get_public_patient_document_upload(pg_temp.iv('capability'),pg_temp.iid('current_file'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','An old capability loses ready/pending document access on contact correction');
insert into information_access_fixture values('fresh_capability',public.issue_appointment_management_capability(
 pg_temp.iid('business'),pg_temp.iid('appointment'),2));
select extensions.throws_ok($q$select public.complete_public_patient_document_upload(pg_temp.iv('fresh_capability'),pg_temp.iid('contact_pending'),100,'application/pdf',false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','A fresh contact cannot validate bytes left pending by the former contact');
select extensions.is((public.get_public_patient_document_upload(pg_temp.iv('fresh_capability'),pg_temp.iid('current_file'),false)).status,'ready',
 'Ready clinical history survives correction and remains recoverable with current authorized access');
select extensions.ok(not has_table_privilege('service_role','private.patient_document_upload_authority','SELECT,INSERT,UPDATE,DELETE')
 and not has_function_privilege('authenticated','public.complete_public_patient_document_upload(text,uuid,bigint,text,boolean)','EXECUTE')
 and has_function_privilege('service_role','public.complete_public_patient_document_upload(text,uuid,bigint,text,boolean)','EXECUTE'),
 'Upload authority is private and explicit completion remains backend-only');
select * from extensions.finish();
rollback;
