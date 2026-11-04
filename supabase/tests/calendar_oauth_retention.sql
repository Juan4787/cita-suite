-- Expired, even consumed nonces are no longer grant authority. Cleanup must
-- be bounded and preserve live consent, Calendar connections and event links.
begin;
select extensions.plan(5);
create temporary table calendar_retention_fixture(label text primary key,value text not null);
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); professional uuid:=gen_random_uuid(); service uuid:=gen_random_uuid(); patient uuid; a uuid; connection uuid; begin
 insert into auth.users(id,email) values(u,'calendar-retention-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic OAuth retention',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(professional,b,'Synthetic retention professional');
 insert into public.services(id,business_id,name,duration_minutes) values(service,b,'Synthetic retention service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,professional,service);
 insert into public.patients(business_id,owner_id,full_name) values(b,u,'Synthetic retention patient') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,professional,service,clock_timestamp()+interval '20 days',clock_timestamp()+interval '20 days 1 hour','reserved','manual','Synthetic retention service','Synthetic retention professional',60) returning id into a;
 insert into public.google_calendar_connections(oauth_client_key,google_subject,refresh_token_ciphertext)
 values(repeat('c',64),'retention-'||b,repeat('r',40)) returning id into connection;
 insert into public.appointment_google_calendar_events(business_id,appointment_id,connection_id,sync_status) values(b,a,connection,'pending_create');
 insert into public.google_calendar_oauth_attempts(business_id,appointment_id,state_hash,code_verifier_ciphertext,created_at,expires_at,consumed_at)
 select b,a,encode(extensions.digest(b::text||i,'sha256'),'hex'),repeat('v',32),clock_timestamp()-interval '2 days',
  clock_timestamp()-interval '1 day'+make_interval(mins=>i),case when i=2 then clock_timestamp()-interval '1 day' end from generate_series(1,3) i;
 insert into public.google_calendar_oauth_attempts(business_id,appointment_id,state_hash,code_verifier_ciphertext,created_at,expires_at,consumed_at)
 values(b,a,encode(extensions.digest(b::text||'live','sha256'),'hex'),repeat('v',32),clock_timestamp(),clock_timestamp()+interval '10 minutes',clock_timestamp());
 insert into calendar_retention_fixture values('appointment',a::text),('connection',connection::text),('business',b::text);
end $$;
create temporary table calendar_retention_results(label text primary key,value integer);
insert into calendar_retention_results values('bounded',private.prune_calendar_oauth_attempts(2));
select extensions.ok((select value from calendar_retention_results where label='bounded')=2
 and (select count(*) from public.google_calendar_oauth_attempts where appointment_id=(select value::uuid from calendar_retention_fixture where label='appointment') and expires_at<clock_timestamp())=1,
 'Cleanup applies its row limit and leaves excess expired work for a later bounded run');
insert into calendar_retention_results values('rest',private.prune_calendar_oauth_attempts(500));
select extensions.ok(not exists(select 1 from public.google_calendar_oauth_attempts where appointment_id=(select value::uuid from calendar_retention_fixture where label='appointment') and expires_at<clock_timestamp())
 and (select count(*) from public.google_calendar_oauth_attempts where appointment_id=(select value::uuid from calendar_retention_fixture where label='appointment') and consumed_at is not null and expires_at>clock_timestamp())=1,
 'Expired consumed/unconsumed nonces disappear; a consumed but live final-grant nonce survives');
select extensions.ok(exists(select 1 from public.google_calendar_connections where id=(select value::uuid from calendar_retention_fixture where label='connection') and refresh_token_ciphertext=repeat('r',40))
 and exists(select 1 from public.appointment_google_calendar_events where appointment_id=(select value::uuid from calendar_retention_fixture where label='appointment') and sync_status='pending_create'),
 'Cleanup never retires an actual Calendar connection or its pending event');
select extensions.throws_ok($q$select private.prune_calendar_oauth_attempts(5001)$q$,'P0001','CALENDAR_OAUTH_RETENTION_LIMIT_INVALID','A caller cannot turn the bounded maintenance into an unlimited deletion');
select extensions.ok((select count(*) from cron.job where jobname='cita-suite-calendar-oauth-retention' and schedule='47 * * * *' and active)=1
 and not has_function_privilege('anon','private.prune_calendar_oauth_attempts(integer)','EXECUTE')
 and not has_function_privilege('authenticated','private.prune_calendar_oauth_attempts(integer)','EXECUTE')
 and not has_function_privilege('service_role','private.prune_calendar_oauth_attempts(integer)','EXECUTE'),
 'One private database-only hourly job cleans attempts independently of further page visits or Worker calls');
select * from extensions.finish();
rollback;
