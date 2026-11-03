-- Recovery runs before availability/UI preflight so a lost response can be
-- recovered even after policy, public-booking or appointment state changes.
begin;
select extensions.plan(7);
create temporary table recovery_fixture(b uuid,a uuid,t text,op uuid,rev text,result jsonb);
create function pg_temp.recover(p_revision text default null) returns jsonb language sql as $$
 select public.recover_patient_appointment_management(t,false,op,coalesce(p_revision,rev),'cancel',null,null,null,null) from recovery_fixture
$$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); patient uuid; a uuid; begin
 insert into auth.users(id,email) values(u,'recovery-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic recovery',b::text,'other','UTC');
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'Synthetic professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Synthetic service',30);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(owner_id,business_id,full_name) values(u,b,'Synthetic patient') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,p,s,now()+interval '10 days',now()+interval '10 days 30 minutes','reserved','manual','Synthetic service','Synthetic professional',30) returning id into a;
 insert into recovery_fixture values(b,a,public.issue_appointment_management_capability(b,a,1),gen_random_uuid(),private.appointment_semantic_revision(b,a),null);
end $$;
select extensions.is(pg_temp.recover(),null::jsonb,'1. Before commit there is no recovery and no operation is created');
update recovery_fixture set result=public.apply_patient_appointment_management(t,false,op,rev,'cancel');
select extensions.is(pg_temp.recover(),(select result||'{"idempotent_replay":true}'::jsonb from recovery_fixture),
 '2. Exact authorized retry recovers the committed result before any availability preflight');
update public.businesses set public_booking_enabled=false,is_active=false where id=(select b from recovery_fixture);
select extensions.ok(pg_temp.recover()->>'status'='cancelled','3. Changed appointment/business context does not erase a committed receipt');
select extensions.throws_ok($q$select pg_temp.recover(repeat('0',64))$q$,'P0001','APPOINTMENT_OPERATION_CONFLICT',
 '4. Another payload cannot borrow this operation result');
select extensions.is((select count(*) from private.appointment_management_operations where business_id=(select b from recovery_fixture)),1::bigint,
 '5. Recovery writes no new receipt, state, money, audit or event');
update private.appointment_management_capabilities set expires_at=now()-interval '1 minute' where appointment_id=(select a from recovery_fixture);
select extensions.throws_ok($q$select pg_temp.recover()$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 '6. An expired/revoked capability cannot recover a previous result');
select extensions.ok(has_function_privilege('service_role','public.recover_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint)','EXECUTE')
 and not has_function_privilege('anon','public.recover_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint)','EXECUTE')
 and not has_function_privilege('authenticated','public.recover_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint)','EXECUTE'),
 '7. Receipt lookup remains capability-bound and backend-only');
select * from extensions.finish();
rollback;
