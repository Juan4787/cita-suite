-- AC09: clinical information retains its own active/future/commercial scope.
-- A stable calendar token is not replacement management authority.
begin;
select extensions.plan(13);
create temporary table information_access_fixture(label text primary key,value text not null);
create function pg_temp.iv(p_label text) returns text language sql as $$
 select value from information_access_fixture where label=p_label
$$;
create function pg_temp.iid(p_label text) returns uuid language sql as $$ select pg_temp.iv(p_label)::uuid $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid();
 s uuid:=gen_random_uuid(); patient uuid; a uuid; token text; begin
 insert into auth.users(id,email) values(u,'information-access-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone)
 values(b,'Synthetic clinical access',b::text,'other','UTC');
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
select extensions.ok(public.get_public_booking_information(pg_temp.iv('legacy'))->>'version'='initial',
 '1. Positive control: the existing legacy link reads this own active future questionnaire');
do $$ begin
 perform set_config('request.jwt.claim.sub',pg_temp.iv('owner'),true);
 perform public.revoke_appointment_management_access(pg_temp.iid('business'),pg_temp.iid('appointment'),gen_random_uuid(),
  private.appointment_semantic_revision(pg_temp.iid('business'),pg_temp.iid('appointment')));
 perform set_config('request.jwt.claim.sub','',true);
end $$;
select extensions.throws_ok($q$select public.get_public_booking_information(pg_temp.iv('legacy'))$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','2. A revoked legacy link cannot bypass management through clinical information');
do $$ begin
 begin
  perform public.submit_public_booking_information(pg_temp.iv('legacy'),gen_random_uuid(),pg_temp.iv('schema_hash'),'initial',
   '{"coverage":"Must not be saved"}','Revoked legacy link');
  raise exception 'REVOKED_LEGACY_INFORMATION_WRITE_ALLOWED';
 exception when others then if sqlerrm is distinct from 'BOOKING_INFORMATION_UNAVAILABLE' then raise; end if; end;
 if exists(select 1 from public.appointment_intake_submissions where appointment_id=pg_temp.iid('appointment'))
  or (select insurance from public.patients where id=pg_temp.iid('patient')) is not null then
  raise exception 'REVOKED_INFORMATION_LEFT_PROFILE_OR_HISTORY'; end if;
end $$;
select extensions.pass('3. Revoked legacy submission leaves clinical history and mapped patient profile untouched');
insert into information_access_fixture values('capability',public.issue_appointment_management_capability(
 pg_temp.iid('business'),pg_temp.iid('appointment'),2));
select extensions.is(public.get_public_booking_information(pg_temp.iv('capability'),false)->>'schema_hash',pg_temp.iv('schema_hash'),
 '4. Explicit capability channel opens the same questionnaire without restoring a revoked calendar token');
do $$ declare submission uuid; begin
 submission:=public.submit_public_booking_information(pg_temp.iv('capability'),gen_random_uuid(),pg_temp.iv('schema_hash'),'initial',
  '{"coverage":"Current authorized coverage"}','Authorized capability',false);
 if not exists(select 1 from public.appointment_intake_submissions where id=submission and patient_id=pg_temp.iid('patient'))
  or (select insurance from public.patients where id=pg_temp.iid('patient')) is distinct from 'Current authorized coverage' then
  raise exception 'CAPABILITY_INFORMATION_SCOPE_OR_MAPPING'; end if;
end $$;
select extensions.pass('5. Capability submission preserves the original clinical/profile atomic contract');
-- Replays recover the same committed submission; changed input is a conflict.
do $$ declare request uuid:=gen_random_uuid(); first uuid; second uuid; version text; begin
 version:=public.get_public_booking_information(pg_temp.iv('capability'),false)->>'version';
 first:=public.submit_public_booking_information(pg_temp.iv('capability'),request,pg_temp.iv('schema_hash'),version,
  '{"coverage":"Replay coverage"}','Replay',false);
 second:=public.submit_public_booking_information(pg_temp.iv('capability'),request,'outdated schema','outdated version',
  '{"coverage":"Replay coverage"}','Replay',false);
 if first is distinct from second then raise exception 'INFORMATION_REPLAY_DUPLICATED'; end if;
 begin
  perform public.submit_public_booking_information(pg_temp.iv('capability'),request,pg_temp.iv('schema_hash'),version,
   '{"coverage":"Different payload"}','Replay',false);
  raise exception 'INFORMATION_REPLAY_PAYLOAD_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'BOOKING_INFORMATION_REQUEST_CONFLICT' then raise; end if; end;
end $$;
select extensions.pass('Committed clinical submission replays once and rejects different answers');

-- Expiry after the actual mapped profile effect must undo submission/profile.
create function pg_temp.expire_information_after_mapping() returns trigger language plpgsql as $$
begin
 if new.appointment_id=pg_temp.iid('appointment') then
  perform pg_sleep_until((select expires_at+interval '25 milliseconds' from private.appointment_management_capabilities
   where token_hash=encode(extensions.digest(pg_temp.iv('capability'),'sha256'),'hex')));
 end if;
 return new;
end $$;
create trigger expire_information_after_mapping after update of profile_changes on public.appointment_intake_submissions
 for each row execute function pg_temp.expire_information_after_mapping();
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 second'
 where token_hash=encode(extensions.digest(pg_temp.iv('capability'),'sha256'),'hex');
do $$ declare before_patient jsonb; before_submissions jsonb; version text; begin
 select to_jsonb(p) into before_patient from public.patients p where id=pg_temp.iid('patient');
 select jsonb_agg(to_jsonb(s) order by sequence_no) into before_submissions from public.appointment_intake_submissions s
  where appointment_id=pg_temp.iid('appointment');
 version:=public.get_public_booking_information(pg_temp.iv('capability'),false)->>'version';
 begin
  perform public.submit_public_booking_information(pg_temp.iv('capability'),gen_random_uuid(),pg_temp.iv('schema_hash'),version,
   '{"coverage":"Expired mapped value"}','Must roll back',false);
  raise exception 'EXPIRED_INFORMATION_COMMITTED';
 exception when others then if sqlerrm is distinct from 'BOOKING_INFORMATION_UNAVAILABLE' then raise; end if; end;
 if (select to_jsonb(p) from public.patients p where id=pg_temp.iid('patient')) is distinct from before_patient
  or (select jsonb_agg(to_jsonb(s) order by sequence_no) from public.appointment_intake_submissions s
   where appointment_id=pg_temp.iid('appointment')) is distinct from before_submissions then
  raise exception 'EXPIRED_INFORMATION_PARTIAL_EFFECTS'; end if;
end $$;
drop trigger expire_information_after_mapping on public.appointment_intake_submissions;
select extensions.pass('Expiry during the mapped profile effect rolls back profile and submission history');
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 day'
 where token_hash=encode(extensions.digest(pg_temp.iv('capability'),'sha256'),'hex');
select extensions.throws_ok($q$select public.get_public_booking_information(pg_temp.iv('capability'),true)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','A capability is never implicitly accepted as the stable legacy token');

update public.patients set email='corrected-information@example.test' where id=pg_temp.iid('patient');
select extensions.throws_ok($q$select public.get_public_booking_information(pg_temp.iv('capability'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','6. Correcting email also revokes clinical information access from its former capability');
insert into information_access_fixture values('current_capability',public.issue_appointment_management_capability(
 pg_temp.iid('business'),pg_temp.iid('appointment'),2));
update public.business_subscriptions set commercial_access_enabled=false where business_id=pg_temp.iid('business');
select extensions.throws_ok($q$select public.get_public_booking_information(pg_temp.iv('current_capability'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','7. The minimal management exception for cancellation does not open clinical information on suspension');
update public.business_subscriptions set commercial_access_enabled=true where business_id=pg_temp.iid('business');
update public.appointments set status='cancelled' where id=pg_temp.iid('appointment');
select extensions.throws_ok($q$select public.get_public_booking_information(pg_temp.iv('current_capability'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','8. A cancelled appointment retains history without exposing an active clinical form');
update public.appointments set status='reserved',starts_at=clock_timestamp()-interval '2 hours',ends_at=clock_timestamp()-interval '1 hour'
 where id=pg_temp.iid('appointment');
select extensions.throws_ok($q$select public.get_public_booking_information(pg_temp.iv('current_capability'),false)$q$,
 'P0001','BOOKING_INFORMATION_UNAVAILABLE','9. Clinical form scope stays future-only independently from management read scope');
select extensions.ok(not has_function_privilege('anon','public.get_public_booking_information(text,boolean)','EXECUTE')
 and not has_function_privilege('authenticated','public.get_public_booking_information(text,boolean)','EXECUTE')
 and has_function_privilege('service_role','public.get_public_booking_information(text,boolean)','EXECUTE')
 and not has_function_privilege('authenticated','public.submit_public_booking_information(text,uuid,text,text,jsonb,text,boolean)','EXECUTE'),
 '10. Explicit clinical access overloads remain backend-only and do not grant public direct writes');
select * from extensions.finish();
rollback;
