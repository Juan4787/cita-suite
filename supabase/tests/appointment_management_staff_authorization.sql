-- OP02: a temporary assistance grant is authority only while actually active.
-- These are real actor/appointment/deposit calls, not a mocked authorization.
begin;
select extensions.plan(12);
create temporary table staff_clock_fixture(label text primary key,id uuid);
create function pg_temp.scid(p_label text) returns uuid language sql as $$ select id from staff_clock_fixture where label=p_label $$;
do $$ declare b uuid:=gen_random_uuid(); owner_id uuid:=gen_random_uuid(); support_id uuid:=gen_random_uuid();
 p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); patient uuid; a uuid; begin
 insert into auth.users(id,email) values(owner_id,'staff-clock-owner-'||owner_id||'@example.test'),(support_id,'staff-clock-support-'||support_id||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic staff clock',b::text,'other','UTC');
 update public.business_subscriptions set is_permanent=true,commercial_access_enabled=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,owner_id,'owner','active',now());
 insert into public.account_assistance_support_users(user_id,email,enabled) values(support_id,'staff-clock-support-'||support_id||'@example.test',true);
 insert into public.professionals(id,business_id,name) values(p,b,'Synthetic professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Synthetic service',30);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(business_id,owner_id,full_name) values(b,owner_id,'Synthetic staff clock patient') returning id into patient;
 update private.deposit_automation set enabled=true;
 insert into public.deposit_policies(business_id,enabled,amount_mode,fixed_amount,transfer_details) values(b,true,'fixed',40000,'Synthetic transfer');
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,p,s,now()+interval '20 days',now()+interval '20 days 30 minutes','reserved','manual','Synthetic service','Synthetic professional',30) returning id into a;
 insert into staff_clock_fixture values('business',b),('owner',owner_id),('support',support_id),('appointment',a),('operation',gen_random_uuid());
 insert into public.account_assistance_grants(business_id,requested_by_user_id,support_user_id,starts_at,expires_at)
 values(b,owner_id,support_id,now()-interval '1 minute',clock_timestamp()+interval '1 second');
 perform set_config('request.jwt.claim.sub',support_id::text,true);
end $$;
select extensions.is(private.deposit_actor(pg_temp.scid('business'),array['owner','admin','reception']),'admin',
 '1. A still-active independent assistance grant has the existing administration capability');
select pg_sleep(greatest(extract(epoch from ((select expires_at from public.account_assistance_grants where business_id=pg_temp.scid('business'))-clock_timestamp())),0)+0.025);
select extensions.is(private.deposit_actor(pg_temp.scid('business'),array['owner','admin','reception']),null::text,
 '2. After real expiry, transaction-start time does not preserve temporary staff authority');
select extensions.throws_ok($q$select public.revoke_appointment_management_access(pg_temp.scid('business'),pg_temp.scid('appointment'),
 pg_temp.scid('operation'),private.appointment_semantic_revision(pg_temp.scid('business'),pg_temp.scid('appointment')))$q$,
 'P0001','APPOINTMENT_MANAGEMENT_FORBIDDEN','3. Expired assistance cannot revoke a patient link');
select extensions.ok((select generation=1 and legacy_management_allowed from public.appointment_management_states where appointment_id=pg_temp.scid('appointment'))
 and not exists(select 1 from private.appointment_management_operations where business_id=pg_temp.scid('business')),
 '4. Rejected expired staff leaves generation, legacy access and receipts unchanged');
select extensions.throws_ok($q$select public.set_appointment_deposit(pg_temp.scid('business'),pg_temp.scid('appointment'),'paid',1,null)$q$,
 'P0001','DEPOSIT_FORBIDDEN','5. Expired assistance cannot register money or confirm attendance');
select extensions.ok((select status='pending' from public.appointment_deposits where appointment_id=pg_temp.scid('appointment'))
 and (select status='reserved' from public.appointments where id=pg_temp.scid('appointment'))
 and not exists(select 1 from public.appointment_deposit_requirements where appointment_id=pg_temp.scid('appointment') and status='paid'),
 '6. Rejected expired staff leaves the actual deposit and money history unchanged');
select extensions.throws_ok($q$select public.open_appointment_deposit_reminder(pg_temp.scid('business'),pg_temp.scid('appointment'),false)$q$,
 'P0001','DEPOSIT_FORBIDDEN','7. Expired assistance cannot open a deposit reminder');
select extensions.ok((select reminder_opened_at is null from public.appointment_deposits where appointment_id=pg_temp.scid('appointment'))
 and not exists(select 1 from public.audit_logs where entity_id=pg_temp.scid('appointment') and action='appointment.deposit_reminder_opened'),
 '8. Rejected reminder leaves its timestamp and audit unchanged');
select extensions.throws_ok($q$select public.save_deposit_policy(pg_temp.scid('business'),jsonb_build_object(
 'enabled',true,'auto_cancel_enabled',false,'amount_mode','fixed','fixed_amount',50000,'percentage',null,
 'request_days',7,'deadline_hours',48,'min_payment_hours',24,'transfer_details','Changed synthetic transfer',
 'applies_to_manual',true,'excluded_service_ids','[]'::jsonb),1)$q$,
 'P0001','DEPOSIT_POLICY_FORBIDDEN','9. Expired assistance cannot change financial policy');
select extensions.ok((select revision=1 and fixed_amount=40000 from public.deposit_policies where business_id=pg_temp.scid('business')),
 '10. Rejected policy change leaves the actual policy unchanged');
-- An independent active assistance grant has administration capability; it
-- must not require inventing a permanent business membership to create a turn.
update public.account_assistance_grants set starts_at=clock_timestamp()-interval '1 minute',expires_at=clock_timestamp()+interval '2 minutes'
 where business_id=pg_temp.scid('business');
select set_config('request.jwt.claim.sub','',true);
create function pg_temp.schelp_create() returns uuid language sql as $$
 select created.id from public.appointments original,
 lateral public.create_appointment_with_patient_identity(original.business_id,'existing',original.patient_id,null,null,null,null,
  false,pg_temp.scid('owner'),original.service_id,array[original.professional_id],original.starts_at+interval '2 days',
  null,pg_temp.scid('support'),false,'manual','unknown',false,pg_temp.scid('operation')::text,false) created
 where original.id=pg_temp.scid('appointment')
$$;
select extensions.lives_ok('select pg_temp.schelp_create()',
 '11. Active independent assistance can use the real backend manual-creation contract');
select extensions.ok(exists(select 1 from public.appointments a where a.business_id=pg_temp.scid('business')
 and a.created_by_user_id=pg_temp.scid('support') and exists(select 1 from public.audit_logs log where log.entity_id=a.id
 and log.user_id=pg_temp.scid('support') and log.action='appointment.created'))
 and not exists(select 1 from public.business_users where business_id=pg_temp.scid('business') and user_id=pg_temp.scid('support')),
 '12. Assisted creation records the actual actor atomically without creating a permanent membership');
select * from extensions.finish();
rollback;
