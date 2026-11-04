-- The immediate runner participates in the existing durable Calendar lease.
-- A prior read is not a reservation, and reauthorization is not lease recovery.
begin;
select extensions.plan(17);
create temporary table calendar_lease_fixture(label text primary key,value text not null);
create temporary table calendar_lease_results(label text primary key,result jsonb);
create function pg_temp.lv(p_label text) returns text language sql as $$ select value from calendar_lease_fixture where label=p_label $$;
create function pg_temp.lid(p_label text) returns uuid language sql as $$ select pg_temp.lv(p_label)::uuid $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); professional uuid:=gen_random_uuid(); service uuid:=gen_random_uuid(); patient uuid; a uuid; access text; nonce uuid; event uuid; begin
 insert into auth.users(id,email) values(u,'calendar-lease-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic calendar lease',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(professional,b,'Synthetic lease professional');
 insert into public.services(id,business_id,name,duration_minutes) values(service,b,'Synthetic lease service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,professional,service);
 insert into public.patients(business_id,owner_id,full_name,email) values(b,u,'Synthetic lease patient','lease@example.test') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,professional,service,clock_timestamp()+interval '20 days',clock_timestamp()+interval '20 days 1 hour','reserved','manual','Synthetic lease service','Synthetic lease professional',60) returning id into a;
 access:=public.issue_appointment_management_capability(b,a,1);
 nonce:=public.begin_patient_google_calendar_authorization(access,false,repeat('a',64),repeat('v',32),repeat('e',40),false);
 perform public.consume_patient_google_calendar_authorization(repeat('a',64),access,false);
 select event_row_id into event from public.authorize_patient_google_calendar_event(access,false,nonce,repeat('c',64),'synthetic-lease-subject',repeat('r',40),array['https://www.googleapis.com/auth/calendar.events.owned']);
 insert into calendar_lease_fixture values('business',b::text),('owner',u::text),('patient',patient::text),('appointment',a::text),('access',access),('event',event::text),('first_claim',gen_random_uuid()::text),('target_claim',gen_random_uuid()::text),('core_claim',gen_random_uuid()::text),('repair_claim',gen_random_uuid()::text),('delete_intent_claim',gen_random_uuid()::text),('context_claim',gen_random_uuid()::text),('context_delete_claim',gen_random_uuid()::text),('uncertain_claim',gen_random_uuid()::text),('unstarted_claim',gen_random_uuid()::text);
 nonce:=public.begin_patient_google_calendar_authorization(access,false,repeat('b',64),repeat('v',32),repeat('e',40),false);
 perform public.consume_patient_google_calendar_authorization(repeat('b',64),access,false);
 insert into calendar_lease_fixture values('pending_nonce',nonce::text);
 perform public.claim_google_calendar_sync_batch(clock_timestamp(),100,pg_temp.lid('first_claim'));
end $$;
select extensions.ok(exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and claim_token=pg_temp.lid('first_claim') and claimed_at is not null),
 'Positive control: the existing scheduled claimant owns this actual pending event');
-- This existing RPC must not silently replace an already-running lease even for
-- the same account. Use its own nonce; no nonexistent claim helper is called yet.
do $$ begin
 begin
  perform public.authorize_patient_google_calendar_event(pg_temp.lv('access'),false,pg_temp.lid('pending_nonce'),repeat('c',64),'synthetic-lease-subject',repeat('n',40),array['https://www.googleapis.com/auth/calendar.events.owned']);
  raise exception 'LIVE_CALENDAR_CLAIM_REPLACED_BY_NEW_GRANT';
 exception when others then if sqlerrm is distinct from 'GOOGLE_CALENDAR_SYNC_IN_PROGRESS' then raise; end if; end;
end $$;
select extensions.ok(exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and claim_token=pg_temp.lid('first_claim') and claimed_at is not null)
 and (select authorized_at is null from public.google_calendar_oauth_attempts where id=pg_temp.lid('pending_nonce')),
 'Reauthorization during a live lease leaves intent, nonce and original lease unchanged');
update public.appointment_google_calendar_events set claimed_at=clock_timestamp()-interval '11 minutes' where id=pg_temp.lid('event');
insert into calendar_lease_results values('target',public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('target_claim')));
select extensions.ok((select result->>'event_row_id' from calendar_lease_results where label='target')=pg_temp.lv('event')
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and claim_token=pg_temp.lid('target_claim')),
 'The targeted executor reclaims an expired lease durably through the same event row');
select extensions.is(public.claim_google_calendar_event_sync(pg_temp.lid('event'),gen_random_uuid()),null::jsonb,
 'A second immediate caller cannot execute the live lease');
select extensions.ok(not exists(select 1 from jsonb_array_elements(public.claim_google_calendar_sync_batch(clock_timestamp(),100,gen_random_uuid())) item where item->>'event_row_id'=pg_temp.lv('event')),
 'The scheduled runner cannot also claim an immediately owned event');
do $$ declare first jsonb; second jsonb; count_before integer; begin
 first:=public.complete_google_calendar_sync_batch(pg_temp.lid('target_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object('event_row_id',pg_temp.lid('event'),'outcome','synced','google_event_id','synthetic-stable-event','synced_sequence',0)),false);
 select calendar_action_count into count_before from public.appointments where id=pg_temp.lid('appointment');
 second:=public.complete_google_calendar_sync_batch(pg_temp.lid('target_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object('event_row_id',pg_temp.lid('event'),'outcome','synced','google_event_id','synthetic-stable-event','synced_sequence',0)),false);
 if first->'results'->0->>'status' is distinct from 'active' or second->'results'->0->>'status' is distinct from 'stale'
  or (select calendar_action_count from public.appointments where id=pg_temp.lid('appointment'))<>count_before then raise exception 'CALENDAR_LEASE_RESULT_REPLAY_MUTATED'; end if;
end $$;
select extensions.pass('A committed completion replay is stale without another telemetry or provider decision');
-- Standalone cores intentionally clear claimed_at. The token must leave with it,
-- rather than leaving a lease that a delayed callback can still present.
update public.appointment_google_calendar_events set sync_status='pending_update',next_attempt_at=clock_timestamp() where id=pg_temp.lid('event');
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('core_claim'));
select public.complete_google_calendar_event_sync(pg_temp.lid('event'),'synthetic-stable-event',0,clock_timestamp());
select extensions.ok((select claimed_at is null and claim_token is null from public.appointment_google_calendar_events where id=pg_temp.lid('event')),
 'The completion core cannot leave a token attached to a released lease');
-- Removing this calendar is independent from rescheduling the still active
-- appointment. A failure of that SAME deletion intent remains a real failure.
select public.request_google_calendar_event_deletion(pg_temp.lid('appointment'),clock_timestamp());
insert into calendar_lease_fixture values('observed_sequence',(select calendar_sequence::text from public.appointments where id=pg_temp.lid('appointment')));
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('delete_intent_claim'));
update public.appointments set starts_at=starts_at+interval '1 day',ends_at=ends_at+interval '1 day' where id=pg_temp.lid('appointment');
insert into calendar_lease_results values('same_delete',public.complete_google_calendar_sync_batch(pg_temp.lid('delete_intent_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object(
 'event_row_id',pg_temp.lid('event'),'outcome','failed','failure_category','permanent','error_code','same-delete-intent',
 'next_attempt_at',clock_timestamp()+interval '1 hour','observed_sequence',pg_temp.lv('observed_sequence')::integer,'observed_sync_status','pending_delete')),false));
select extensions.ok((select result from calendar_lease_results where label='same_delete')->'results'->0->>'status'='failed'
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and sync_status='failed' and claim_token is null and claimed_at is null and last_error_code='same-delete-intent'),
 'Moving the appointment does not invalidate an explicit calendar-removal intent or hide its actual failure');
-- Complete the previously rejected local grant after the lease has ended; the
-- exact nonce remains one-use and bound to its original authority.
select public.authorize_patient_google_calendar_event(pg_temp.lv('access'),false,pg_temp.lid('pending_nonce'),repeat('c',64),'synthetic-lease-subject',repeat('r',40),array['https://www.googleapis.com/auth/calendar.events.owned']);
select public.complete_google_calendar_event_sync(pg_temp.lid('event'),'synthetic-stable-event',(select calendar_sequence from public.appointments where id=pg_temp.lid('appointment')),clock_timestamp());
update public.appointment_google_calendar_events set sync_status='pending_update',next_attempt_at=clock_timestamp() where id=pg_temp.lid('event');
insert into calendar_lease_fixture values('repair_sequence',(select calendar_sequence::text from public.appointments where id=pg_temp.lid('appointment')));
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('repair_claim'));
do $$ declare replacement uuid; begin
 insert into public.patients(business_id,owner_id,full_name) values(pg_temp.lid('business'),pg_temp.lid('owner'),'Synthetic replacement') returning id into replacement;
 insert into calendar_lease_fixture values('replacement',replacement::text);
 perform set_config('request.jwt.claim.sub',pg_temp.lv('owner'),true);
 begin
  perform public.reassign_appointment_patient_safely(pg_temp.lid('business'),pg_temp.lid('appointment'),replacement,pg_temp.lid('owner'),'Synthetic lease guard');
  raise exception 'IDENTITY_REPAIR_BYPASSED_LIVE_CALENDAR_LEASE';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_REASSIGNMENT_CALENDAR_IN_FLIGHT' then raise; end if; end;
end $$;
select extensions.is((select patient_id from public.appointments where id=pg_temp.lid('appointment')),pg_temp.lid('patient'),
 'The existing identity-repair guard recognizes a targeted live lease without a separate identity mechanism');
-- Model an actually expired history, including its consumed OAuth nonces. A live
-- nonce is deliberately a separate repair barrier in the existing contract.
update public.appointment_google_calendar_events set claimed_at=clock_timestamp()-interval '11 minutes' where id=pg_temp.lid('event');
update public.google_calendar_oauth_attempts set created_at=clock_timestamp()-interval '12 minutes',expires_at=clock_timestamp()-interval '2 minutes'
 where appointment_id=pg_temp.lid('appointment');
select public.reassign_appointment_patient_safely(pg_temp.lid('business'),pg_temp.lid('appointment'),pg_temp.lid('replacement'),pg_temp.lid('owner'),'Synthetic expired history');
select extensions.ok(exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and sync_status='pending_delete' and claimed_at is null and claim_token is null)
 and (select patient_id from public.appointments where id=pg_temp.lid('appointment'))=pg_temp.lid('replacement'),
 'Expired work can be repaired and enqueues old-account deletion with no former lease retained');
select extensions.is(public.complete_google_calendar_sync_batch(pg_temp.lid('repair_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object('event_row_id',pg_temp.lid('event'),'outcome','synced','google_event_id','late-old-resource','synced_sequence',pg_temp.lv('repair_sequence')::integer)),false)->'results'->0->>'status','stale',
 'A delayed result from the former lease cannot apply to the replacement identity');
insert into calendar_lease_fixture values('delete_claim',gen_random_uuid()::text);
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('delete_claim'));
select public.complete_google_calendar_sync_batch(pg_temp.lid('delete_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object('event_row_id',pg_temp.lid('event'),'outcome','deleted')),false);
select extensions.ok(not exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event'))
 and (select patient_id from public.appointments where id=pg_temp.lid('appointment'))=pg_temp.lid('replacement'),
 'Owned deletion completion removes the former account link while preserving the replacement appointment');
-- A failure of the OLD create/update payload cannot close or snooze the new
-- schedule/intent. Use a real new grant after the previous link was cleaned up.
do $$ declare access text; nonce uuid; event uuid; begin
 access:=public.issue_appointment_management_capability(pg_temp.lid('business'),pg_temp.lid('appointment'),
  (select generation from public.appointment_management_states where appointment_id=pg_temp.lid('appointment')));
 nonce:=public.begin_patient_google_calendar_authorization(access,false,repeat('d',64),repeat('v',32),repeat('e',40),false);
 perform public.consume_patient_google_calendar_authorization(repeat('d',64),access,false);
 select event_row_id into event from public.authorize_patient_google_calendar_event(access,false,nonce,repeat('c',64),'synthetic-lease-subject',repeat('r',40),array['https://www.googleapis.com/auth/calendar.events.owned']);
 update calendar_lease_fixture set value=event::text where label='event';
 update calendar_lease_fixture set value=(select calendar_sequence::text from public.appointments where id=pg_temp.lid('appointment')) where label='observed_sequence';
end $$;
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('context_claim'));
update public.appointments set starts_at=starts_at+interval '1 day',ends_at=ends_at+interval '1 day' where id=pg_temp.lid('appointment');
insert into calendar_lease_results values('schedule_context',public.complete_google_calendar_sync_batch(pg_temp.lid('context_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object(
 'event_row_id',pg_temp.lid('event'),'outcome','failed','failure_category','permanent','error_code','old-create-payload',
 'next_attempt_at',clock_timestamp()+interval '1 hour','observed_sequence',pg_temp.lv('observed_sequence')::integer,'observed_sync_status','pending_create')),false));
select extensions.ok((select result from calendar_lease_results where label='schedule_context')->'results'->0->>'status'='pending_create'
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and sync_status='pending_create' and claim_token is null
  and last_error_code is null and next_attempt_at<=clock_timestamp()+interval '1 second'),
 'A superseded payload failure preserves and promptly releases the new useful schedule for synchronization');
update calendar_lease_fixture set value=(select calendar_sequence::text from public.appointments where id=pg_temp.lid('appointment')) where label='observed_sequence';
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('context_delete_claim'));
update public.appointments set status='cancelled' where id=pg_temp.lid('appointment');
insert into calendar_lease_results values('delete_context',public.complete_google_calendar_sync_batch(pg_temp.lid('context_delete_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object(
 'event_row_id',pg_temp.lid('event'),'outcome','failed','failure_category','authorization','error_code','old-work-authorization',
 'next_attempt_at',clock_timestamp()+interval '1 hour','observed_sequence',pg_temp.lv('observed_sequence')::integer,'observed_sync_status','pending_create')),false));
select extensions.ok((select result from calendar_lease_results where label='delete_context')->'results'->0->>'status'='pending_delete'
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and sync_status='pending_delete' and claim_token is null)
 and (select status from public.appointments where id=pg_temp.lid('appointment'))='cancelled',
 'A result of the former create intent cannot discard the now required cancellation cleanup');
-- An unanswered mutation retains the established safety window. Its owner is
-- retired, but neither a second caller nor p_finish can turn it into new work.
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('uncertain_claim'));
insert into calendar_lease_results values('uncertain',public.complete_google_calendar_sync_batch(pg_temp.lid('uncertain_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object(
 'event_row_id',pg_temp.lid('event'),'outcome','uncertain','error_code','calendar_network',
 'next_attempt_at',clock_timestamp()+interval '2 minutes')),true));
insert into calendar_lease_results values('uncertain_replay',public.complete_google_calendar_sync_batch(pg_temp.lid('uncertain_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object('event_row_id',pg_temp.lid('event'),'outcome','uncertain','error_code','calendar_network','next_attempt_at',clock_timestamp()+interval '2 minutes')),true));
select extensions.ok((select result from calendar_lease_results where label='uncertain')->'results'->0->>'status'='pending_delete'
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and sync_status='pending_delete'
  and claim_token is null and claimed_at is not null and next_attempt_at>=claimed_at+interval '10 minutes')
 and public.claim_google_calendar_event_sync(pg_temp.lid('event'),gen_random_uuid()) is null
 and (select result->'results'->0->>'status' from calendar_lease_results where label='uncertain_replay')='stale'
 and (select count(*) from public.audit_logs where entity_id=pg_temp.lid('appointment') and action='appointment.google_calendar_outcome_uncertain')=1,
 'An uncertain external mutation stays durable, bounded by the existing lease window, without claiming rejection or deletion');
update public.appointment_google_calendar_events set claimed_at=clock_timestamp()-interval '11 minutes',next_attempt_at=clock_timestamp() where id=pg_temp.lid('event');
select public.claim_google_calendar_event_sync(pg_temp.lid('event'),pg_temp.lid('unstarted_claim'));
insert into calendar_lease_fixture values('attempt_count',(select attempt_count::text from public.appointment_google_calendar_events where id=pg_temp.lid('event')));
insert into calendar_lease_results values('unstarted',public.complete_google_calendar_sync_batch(pg_temp.lid('unstarted_claim'),clock_timestamp(),jsonb_build_array(jsonb_build_object(
 'event_row_id',pg_temp.lid('event'),'outcome','released')),false));
select extensions.ok((select result from calendar_lease_results where label='unstarted')->'results'->0->>'status'='pending_delete'
 and exists(select 1 from public.appointment_google_calendar_events where id=pg_temp.lid('event') and claim_token is null and claimed_at is null
  and attempt_count=pg_temp.lv('attempt_count')::integer),
 'Undispatched work releases its lease without manufacturing another provider failure');
select extensions.ok(not has_function_privilege('anon','public.claim_google_calendar_event_sync(uuid,uuid)','EXECUTE')
 and not has_function_privilege('authenticated','public.claim_google_calendar_event_sync(uuid,uuid)','EXECUTE')
 and has_function_privilege('service_role','public.claim_google_calendar_event_sync(uuid,uuid)','EXECUTE'),
 'The targeted claimant is backend-only and grants no public appointment authority by ID');
select * from extensions.finish();
rollback;
