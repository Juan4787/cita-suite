-- AC09: the OAuth nonce is bound to the exact original management authority.
-- No plaintext link is stored; existing calendar consent is not revoked by email edits.
begin;
select extensions.plan(18);
create temporary table calendar_access_fixture(label text primary key,value text not null);
create function pg_temp.cv(p_label text) returns text language sql as $$ select value from calendar_access_fixture where label=p_label $$;
create function pg_temp.cid(p_label text) returns uuid language sql as $$ select pg_temp.cv(p_label)::uuid $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); patient uuid; a uuid; token text; begin
 insert into auth.users(id,email) values(u,'calendar-access-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic calendar authority',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'Synthetic calendar professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Synthetic calendar service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(business_id,owner_id,full_name,email) values(b,u,'Synthetic calendar patient','initial-calendar@example.test') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,p,s,now()+interval '20 days',now()+interval '20 days 1 hour','reserved','manual','Synthetic calendar service','Synthetic calendar professional',60) returning id,confirmation_token into a,token;
 insert into calendar_access_fixture values('business',b::text),('owner',u::text),('appointment',a::text),('patient',patient::text),('legacy',token),('revision',private.appointment_semantic_revision(b,a));
end $$;
create function pg_temp.calendar_begin(p_label text,p_access text,p_legacy boolean) returns uuid language plpgsql as $$
declare result uuid; begin
 result:=public.begin_patient_google_calendar_authorization(pg_temp.cv(p_access),p_legacy,encode(extensions.digest(p_label,'sha256'),'hex'),repeat('v',32),repeat('e',40),false);
 insert into calendar_access_fixture values(p_label,result::text);
 return result;
end $$;
create function pg_temp.calendar_consume(p_label text,p_access text,p_legacy boolean) returns uuid language sql as $$
 select attempt_id from public.consume_patient_google_calendar_authorization(encode(extensions.digest(p_label,'sha256'),'hex'),pg_temp.cv(p_access),p_legacy)
$$;
create function pg_temp.calendar_authorize(p_label text,p_access text,p_legacy boolean,p_subject text default 'synthetic-subject') returns uuid language sql as $$
 select event_row_id from public.authorize_patient_google_calendar_event(pg_temp.cv(p_access),p_legacy,pg_temp.cid(p_label),'synthetic-client',p_subject,repeat('r',40),array['https://www.googleapis.com/auth/calendar.events.owned'])
$$;
select pg_temp.calendar_begin('initial','legacy',true);
select extensions.ok(exists(select 1 from public.google_calendar_oauth_attempts where id=pg_temp.cid('initial')
 and management_legacy and management_token_hash=encode(extensions.digest(pg_temp.cv('legacy'),'sha256'),'hex') and management_token_ciphertext=repeat('e',40)
 and expires_at>clock_timestamp() and expires_at<=created_at+interval '10 minutes' and authorized_at is null)
 and not exists(select 1 from public.appointment_google_calendar_events where appointment_id=pg_temp.cid('appointment')),
 'Begin binds one pending nonce to the explicit authority without creating consent or an external event');
select extensions.is(pg_temp.calendar_consume('initial','legacy',true),pg_temp.cid('initial'),'The original authority consumes its exact nonce once');
select extensions.throws_ok($q$select pg_temp.calendar_consume('initial','legacy',true)$q$,'P0001','GOOGLE_CALENDAR_OAUTH_STATE_INVALID','A replay cannot consume the OAuth nonce again');
insert into calendar_access_fixture values('event',pg_temp.calendar_authorize('initial','legacy',true)::text);
select extensions.ok(exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.cid('event') and appointment_id=pg_temp.cid('appointment') and sync_status='pending_create')
 and exists(select 1 from public.google_calendar_oauth_attempts where id=pg_temp.cid('initial') and authorized_at is not null)
 and (select count(*) from public.audit_logs where entity_id=pg_temp.cid('appointment') and action='appointment.google_calendar_authorized')=1
 and private.appointment_semantic_revision(pg_temp.cid('business'),pg_temp.cid('appointment'))=pg_temp.cv('revision'),
 'Grant, durable sync intent, completed nonce and audit commit together without changing agenda or money');
select extensions.throws_ok($q$select pg_temp.calendar_authorize('initial','legacy',true)$q$,'P0001','GOOGLE_CALENDAR_OAUTH_ALREADY_AUTHORIZED','Finalizing a one-shot nonce twice never reauthorizes or duplicates its audit');
insert into calendar_access_fixture values('capability',public.issue_appointment_management_capability(pg_temp.cid('business'),pg_temp.cid('appointment'),1));
select pg_temp.calendar_begin('contact-before-consume','capability',false);
update public.patients set email='corrected-calendar@example.test' where id=pg_temp.cid('patient');
select extensions.throws_ok($q$select pg_temp.calendar_consume('contact-before-consume','capability',false)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','Email correction invalidates the pending OAuth authority before consumption');
select extensions.ok((select consumed_at is null from public.google_calendar_oauth_attempts where id=pg_temp.cid('contact-before-consume'))
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.cid('event')),
 'Rejected consumption has no partial effect and preserves the previously authorized calendar connection');
select extensions.throws_ok($q$select pg_temp.calendar_begin('revoked-legacy','legacy',true)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','The stable calendar identity cannot start another grant after contact correction');
insert into calendar_access_fixture values('fresh',public.issue_appointment_management_capability(pg_temp.cid('business'),pg_temp.cid('appointment'),1));
select pg_temp.calendar_begin('contact-after-consume','fresh',false);
select pg_temp.calendar_consume('contact-after-consume','fresh',false);
update public.patients set email='initial-calendar@example.test' where id=pg_temp.cid('patient');
select extensions.throws_ok($q$select pg_temp.calendar_authorize('contact-after-consume','fresh',false,'must-not-exist')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','A→B→A during external exchange cannot grant the former authority a new connection');
insert into calendar_access_fixture values('current',public.issue_appointment_management_capability(pg_temp.cid('business'),pg_temp.cid('appointment'),1)),
 ('other-current',public.issue_appointment_management_capability(pg_temp.cid('business'),pg_temp.cid('appointment'),1));
select pg_temp.calendar_begin('exact-capability','current',false);
select extensions.throws_ok($q$select pg_temp.calendar_consume('exact-capability','other-current',false)$q$,'P0001','GOOGLE_CALENDAR_OAUTH_STATE_INVALID','Even another current capability cannot replace the authority bound to a nonce');
select extensions.throws_ok($q$select pg_temp.calendar_consume('exact-capability','current',true)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','A capability is never interpreted as legacy authority');
select pg_temp.calendar_consume('exact-capability','current',false);
select extensions.throws_ok($q$select pg_temp.calendar_authorize('exact-capability','current',false,'different-pending-account')$q$,'P0001','GOOGLE_CALENDAR_ALREADY_CONNECTED','A competing account cannot replace a pending existing event before background synchronization');
select extensions.ok(not exists(select 1 from public.google_calendar_connections where google_subject in ('must-not-exist','different-pending-account'))
 and (select count(*) from public.audit_logs where entity_id=pg_temp.cid('appointment') and action='appointment.google_calendar_authorized')=1,
 'Denied finalizations leave no new connection, replacement or success audit');
-- Expiry after the actual event/audit effects must roll back all local grant data.
create function pg_temp.expire_calendar_after_audit() returns trigger language plpgsql as $$ begin
 if new.action='appointment.google_calendar_authorized' and new.entity_id=pg_temp.cid('appointment') then
  perform pg_sleep_until((select expires_at+interval '25 milliseconds' from private.appointment_management_capabilities
   where token_hash=encode(extensions.digest(pg_temp.cv('current'),'sha256'),'hex')));
 end if; return new;
end $$;
create trigger expire_calendar_after_audit after insert on public.audit_logs for each row execute function pg_temp.expire_calendar_after_audit();
select pg_temp.calendar_begin('expires-during-grant','current',false);
select pg_temp.calendar_consume('expires-during-grant','current',false);
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 second' where token_hash=encode(extensions.digest(pg_temp.cv('current'),'sha256'),'hex');
do $$ declare before_event jsonb; before_connection jsonb; begin
 select to_jsonb(e) into before_event from public.appointment_google_calendar_events e where id=pg_temp.cid('event');
 select to_jsonb(c) into before_connection from public.google_calendar_connections c where id=(before_event->>'connection_id')::uuid;
 begin
  perform pg_temp.calendar_authorize('expires-during-grant','current',false);
  raise exception 'EXPIRED_CALENDAR_GRANT_COMMITTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 if (select to_jsonb(e) from public.appointment_google_calendar_events e where id=pg_temp.cid('event')) is distinct from before_event
  or (select to_jsonb(c) from public.google_calendar_connections c where id=(before_event->>'connection_id')::uuid) is distinct from before_connection
  or (select authorized_at from public.google_calendar_oauth_attempts where id=pg_temp.cid('expires-during-grant')) is not null
  or (select count(*) from public.audit_logs where entity_id=pg_temp.cid('appointment') and action='appointment.google_calendar_authorized')<>1 then
  raise exception 'EXPIRED_CALENDAR_GRANT_PARTIAL_EFFECT'; end if;
end $$;
drop trigger expire_calendar_after_audit on public.audit_logs;
select extensions.pass('Expiry during the authorization audit rolls back connection, event, nonce completion and audit');
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 day' where token_hash=encode(extensions.digest(pg_temp.cv('current'),'sha256'),'hex');
select pg_temp.calendar_begin('attempt-expiry','current',false);
select pg_temp.calendar_consume('attempt-expiry','current',false);
update public.google_calendar_oauth_attempts set created_at=clock_timestamp()-interval '11 minutes',expires_at=clock_timestamp()-interval '1 minute' where id=pg_temp.cid('attempt-expiry');
select extensions.throws_ok($q$select pg_temp.calendar_authorize('attempt-expiry','current',false)$q$,'P0001','GOOGLE_CALENDAR_OAUTH_STATE_INVALID','Attempt expiry is rechecked after the external exchange');
update public.businesses set public_booking_enabled=false where id=pg_temp.cid('business');
select pg_temp.calendar_begin('booking-off','current',false);
select extensions.ok(exists(select 1 from public.google_calendar_oauth_attempts where id=pg_temp.cid('booking-off')),'Online booking off preserves calendar enrollment for an existing appointment');
update public.business_subscriptions set commercial_access_enabled=false where business_id=pg_temp.cid('business');
select extensions.throws_ok($q$select pg_temp.calendar_consume('booking-off','current',false)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','Minimum cancellation scope does not grant calendar consent on suspension');
select extensions.ok(not has_function_privilege('anon','public.begin_patient_google_calendar_authorization(text,boolean,text,text,text,boolean)','EXECUTE')
 and not has_function_privilege('authenticated','public.consume_patient_google_calendar_authorization(text,text,boolean)','EXECUTE')
 and has_function_privilege('service_role','public.authorize_patient_google_calendar_event(text,boolean,uuid,text,text,text,text[])','EXECUTE'),
 'OAuth management boundaries remain backend-only');
select * from extensions.finish();
rollback;
