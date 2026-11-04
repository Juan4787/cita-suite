-- AC09: new push enrollment/test/feedback use current management authority.
-- Independent device receipts retain their own authenticated scope.
begin;
select extensions.plan(20);
create temporary table push_access_fixture(label text primary key,value text not null);
create function pg_temp.iv(p_label text) returns text language sql as $$
 select value from push_access_fixture where label=p_label
$$;
create function pg_temp.iid(p_label text) returns uuid language sql as $$ select pg_temp.iv(p_label)::uuid $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid();
 s uuid:=gen_random_uuid(); patient uuid; a uuid; token text; begin
 insert into auth.users(id,email) values(u,'push-access-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone)
 values(b,'Synthetic push access',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'Synthetic push professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Synthetic push service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(business_id,owner_id,full_name,email)
 values(b,u,'Synthetic push patient','initial-push@example.test') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,p,s,now()+interval '20 days',now()+interval '20 days 1 hour','reserved','manual',
  'Synthetic push service','Synthetic push professional',60) returning id,confirmation_token into a,token;
 insert into push_access_fixture values('business',b::text),('owner',u::text),('appointment',a::text),('patient',patient::text),('legacy',token);
end $$;
-- This new contract is intentionally absent before the push access migration.
-- All provider effects are simulated facts in owned SQL; no Web Push is sent.
create function pg_temp.save_push(p_label text,p_legacy boolean,p_suffix text default 'primary') returns uuid language sql as $$
 select subscription_id from public.save_patient_appointment_push_subscription(pg_temp.iv(p_label),p_legacy,
  'https://fcm.googleapis.com/management-test/'||pg_temp.iv('appointment')||'/'||p_suffix,
  replace(replace(trim(trailing '=' from replace(encode(decode('04'||repeat('01',64),'hex'),'base64'),E'\n','')),'+','-'),'/','_'),
  'AQEBAQEBAQEBAQEBAQEBAQ','Synthetic management browser')
$$;
insert into push_access_fixture select 'subscription',pg_temp.save_push('legacy',true)::text;
select extensions.is((select count(*) from public.push_subscriptions where appointment_id=pg_temp.iid('appointment')),1::bigint,
 'Current legacy access can enroll its own appointment without any clinical questionnaire context');
select extensions.is(pg_temp.save_push('legacy',true),pg_temp.iid('subscription'),
 'Repeated enrollment recovers the natural appointment/device association');
insert into push_access_fixture select 'delivery',delivery_id::text from public.begin_patient_push_test(
 pg_temp.iv('legacy'),true,pg_temp.iid('subscription'),repeat('a',64),repeat('b',64));
select extensions.ok(exists(select 1 from public.push_delivery_attempts where id=pg_temp.iid('delivery')
 and appointment_id=pg_temp.iid('appointment') and subscription_id=pg_temp.iid('subscription') and accepted_at is null),
 'Test preparation commits one owned pending attempt without claiming provider acceptance');
select extensions.is((select delivery_id from public.begin_patient_push_test(pg_temp.iv('legacy'),true,pg_temp.iid('subscription'),repeat('c',64),repeat('b',64))),
 pg_temp.iid('delivery'),'The same request recovers its committed preparation without another delivery');
select extensions.is((select delivery_id from public.begin_patient_push_test(pg_temp.iv('legacy'),true,pg_temp.iid('subscription'),repeat('c',64),repeat('d',64))),
 pg_temp.iid('delivery'),'Different tab keys reuse the same recent test under the appointment gate');
update public.push_delivery_attempts set accepted_at=clock_timestamp(),push_service_status=201 where id=pg_temp.iid('delivery');
do $$ begin
 perform set_config('request.jwt.claim.sub',pg_temp.iv('owner'),true);
 perform public.revoke_appointment_management_access(pg_temp.iid('business'),pg_temp.iid('appointment'),gen_random_uuid(),
  private.appointment_semantic_revision(pg_temp.iid('business'),pg_temp.iid('appointment')));
 perform set_config('request.jwt.claim.sub','',true);
end $$;
select extensions.throws_ok($q$select pg_temp.save_push('legacy',true,'revoked')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 'A revoked stable token cannot enroll another device');
select extensions.throws_ok($q$select public.begin_patient_push_test(pg_temp.iv('legacy'),true,pg_temp.iid('subscription'),repeat('c',64),repeat('e',64))$q$,
 'P0001','APPOINTMENT_LINK_UNAVAILABLE','Revoked management cannot prepare a new provider test');
select extensions.throws_ok($q$select public.record_patient_push_test_feedback(pg_temp.iv('legacy'),true,pg_temp.iid('delivery'),true)$q$,
 'P0001','APPOINTMENT_LINK_UNAVAILABLE','Management feedback also revalidates the current credential');
select extensions.is(public.record_push_notification_click(pg_temp.iid('appointment'),pg_temp.iid('delivery'),repeat('a',64),clock_timestamp()),true,
 'An independently authenticated encrypted device receipt remains valid after management revocation');
insert into push_access_fixture values('capability',public.issue_appointment_management_capability(pg_temp.iid('business'),pg_temp.iid('appointment'),2));
select extensions.is(pg_temp.save_push('capability',false),pg_temp.iid('subscription'),
 'Current capability reuses the existing device without erasing its real confirmation');
select extensions.is(public.record_patient_push_test_feedback(pg_temp.iv('capability'),false,pg_temp.iid('delivery'),true),true,
 'A current management capability can finish accepted test feedback');
update public.patients set email='corrected-push@example.test' where id=pg_temp.iid('patient');
select extensions.throws_ok($q$select pg_temp.save_push('capability',false,'former-contact')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 'Correcting email revokes enrollment from its former capability');
select extensions.throws_ok($q$select public.begin_patient_push_test(pg_temp.iv('capability'),false,pg_temp.iid('subscription'),repeat('f',64),repeat('e',64))$q$,
 'P0001','APPOINTMENT_LINK_UNAVAILABLE','Former contact cannot create a test even for a still legitimate device');
insert into push_access_fixture values('fresh',public.issue_appointment_management_capability(pg_temp.iid('business'),pg_temp.iid('appointment'),2));
update public.business_subscriptions set commercial_access_enabled=false where business_id=pg_temp.iid('business');
select extensions.throws_ok($q$select pg_temp.save_push('fresh',false,'suspended')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 'Minimal cancellation access on suspension does not grant new notification enrollment');
update public.business_subscriptions set commercial_access_enabled=true where business_id=pg_temp.iid('business');
update public.businesses set public_booking_enabled=false where id=pg_temp.iid('business');
select extensions.is(pg_temp.save_push('fresh',false),pg_temp.iid('subscription'),
 'Turning off new online bookings preserves notification management of an existing valid appointment');
update public.appointments set status='cancelled' where id=pg_temp.iid('appointment');
select extensions.throws_ok($q$select pg_temp.save_push('fresh',false,'closed')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 'A closed appointment cannot enroll a new reminder');
select extensions.is(public.record_patient_push_test_feedback(pg_temp.iv('fresh'),false,pg_temp.iid('delivery'),true),true,
 'Feedback about an already accepted device test is separate from creating reminders for a closed appointment');
update public.appointments set status='reserved' where id=pg_temp.iid('appointment');
-- Reuse a genuine owned subscription from another appointment: the token, not
-- a supplied appointment ID, decides the delivery's only allowed parent.
do $$ declare other_appointment uuid; other_subscription uuid; begin
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 select business_id,patient_id,professional_id,service_id,starts_at+interval '1 day',ends_at+interval '1 day','reserved','manual',
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot from public.appointments where id=pg_temp.iid('appointment') returning id into other_appointment;
 select subscription_id into other_subscription from public.save_appointment_push_subscription(pg_temp.iid('business'),other_appointment,
  'https://fcm.googleapis.com/management-test/'||other_appointment,'synthetic-key','synthetic-auth','Synthetic internal backend',clock_timestamp());
 begin
  perform public.begin_patient_push_test(pg_temp.iv('fresh'),false,other_subscription,repeat('f',64),repeat('f',64));
  raise exception 'FOREIGN_PUSH_SUBSCRIPTION_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'PUSH_SUBSCRIPTION_MISMATCH' then raise; end if; end;
end $$;
select extensions.pass('A current token never permits a subscription from a different appointment');
-- Expiry during the committed enrollment effects must roll back device,
-- subscription and audit together. The endpoint did not exist before the call.
create function pg_temp.expire_push_during_audit() returns trigger language plpgsql as $$
begin
 if new.entity_id=pg_temp.iid('appointment') and new.action='appointment.push_subscribed' then
  perform pg_sleep_until((select expires_at+interval '25 milliseconds' from private.appointment_management_capabilities
   where token_hash=encode(extensions.digest(pg_temp.iv('fresh'),'sha256'),'hex')));
 end if;
 return new;
end $$;
create trigger expire_push_during_audit before insert on public.audit_logs for each row execute function pg_temp.expire_push_during_audit();
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 second'
 where token_hash=encode(extensions.digest(pg_temp.iv('fresh'),'sha256'),'hex');
do $$ declare device_count bigint; subscription_count bigint; audit_count bigint; begin
 select count(*) into device_count from public.push_devices;
 select count(*) into subscription_count from public.push_subscriptions where appointment_id=pg_temp.iid('appointment');
 select count(*) into audit_count from public.audit_logs where entity_id=pg_temp.iid('appointment');
 begin
  perform pg_temp.save_push('fresh',false,'expiry');
  raise exception 'EXPIRED_PUSH_ENROLLMENT_COMMITTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 if (select count(*) from public.push_devices)<>device_count
  or (select count(*) from public.push_subscriptions where appointment_id=pg_temp.iid('appointment'))<>subscription_count
  or (select count(*) from public.audit_logs where entity_id=pg_temp.iid('appointment'))<>audit_count then
  raise exception 'EXPIRED_PUSH_ENROLLMENT_PARTIAL_EFFECTS'; end if;
end $$;
drop trigger expire_push_during_audit on public.audit_logs;
select extensions.pass('Expiry during enrollment audit rolls back the whole new device/association/audit');
select extensions.ok(not has_function_privilege('authenticated','public.save_patient_appointment_push_subscription(text,boolean,text,text,text,text)','EXECUTE')
 and not has_function_privilege('anon','public.begin_patient_push_test(text,boolean,uuid,text,text)','EXECUTE')
 and has_function_privilege('service_role','public.record_patient_push_test_feedback(text,boolean,uuid,boolean)','EXECUTE'),
 'Public management push entry points remain backend-only');
select * from extensions.finish();
rollback;
