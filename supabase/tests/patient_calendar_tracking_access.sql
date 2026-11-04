-- Calendar clicks are observations, not proof that an external calendar saved.
-- Their telemetry/activity/audit must share the current management authority.
begin;
select extensions.plan(15);
create temporary table calendar_tracking_fixture(label text primary key,value text not null);
create function pg_temp.tv(p_label text) returns text language sql as $$ select value from calendar_tracking_fixture where label=p_label $$;
create function pg_temp.tid(p_label text) returns uuid language sql as $$ select pg_temp.tv(p_label)::uuid $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); professional uuid:=gen_random_uuid(); service uuid:=gen_random_uuid(); patient uuid; a uuid; token text; begin
 insert into auth.users(id,email) values(u,'calendar-tracking-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic calendar tracking',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(professional,b,'Synthetic tracking professional');
 insert into public.services(id,business_id,name,duration_minutes) values(service,b,'Synthetic tracking service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,professional,service);
 insert into public.patients(business_id,owner_id,full_name,email) values(b,u,'Synthetic tracking patient','tracking@example.test') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,professional,service,clock_timestamp()+interval '20 days',clock_timestamp()+interval '20 days 1 hour','reserved','manual','Synthetic tracking service','Synthetic tracking professional',60) returning id,confirmation_token into a,token;
 insert into calendar_tracking_fixture values('business',b::text),('owner',u::text),('patient',patient::text),('appointment',a::text),('legacy',token),('revision',private.appointment_semantic_revision(b,a));
end $$;
select extensions.is(public.mark_patient_calendar_offered(pg_temp.tv('legacy'),true),true,'Current legacy authority records an offer once');
select extensions.is(public.mark_patient_calendar_offered(pg_temp.tv('legacy'),true),false,'Repeated presentation does not overwrite a calendar action or manufacture another offer');
do $$ declare result boolean; begin
 result:=public.record_patient_calendar_action(pg_temp.tv('legacy'),true,'clicked_google','android_native_fallback');
 if result is not true or not exists(select 1 from public.appointments where id=pg_temp.tid('appointment') and calendar_action_status='clicked_google' and calendar_provider='google' and calendar_action_count=1)
  or (select count(*) from public.audit_logs where entity_id=pg_temp.tid('appointment') and action='appointment.calendar_action')<>1
  or private.appointment_semantic_revision(pg_temp.tid('business'),pg_temp.tid('appointment'))<>pg_temp.tv('revision') then raise exception 'CALENDAR_OBSERVATION_NOT_ATOMIC'; end if;
end $$;
select extensions.pass('Click telemetry and its audit commit without changing schedule, money or semantic revision');
do $$ declare before_a jsonb; begin
 select to_jsonb(a) into before_a from public.appointments a where id=pg_temp.tid('appointment');
 perform public.record_patient_calendar_metric(pg_temp.tv('legacy'),true,'android_intent','data');
 perform public.record_patient_calendar_metric(pg_temp.tv('legacy'),true,'maps',null);
 if (select to_jsonb(a) from public.appointments a where id=pg_temp.tid('appointment')) is distinct from before_a
  or (select count(*) from public.audit_logs where entity_id=pg_temp.tid('appointment') and action in ('appointment.calendar_intent_attempt','appointment.maps_opened'))<>2
 then raise exception 'CALENDAR_METRIC_CHANGED_COVERAGE'; end if;
end $$;
select extensions.pass('Android attempt and Maps remain audit-only metrics without changing coverage or activity');
do $$ declare event uuid; result jsonb; before_e jsonb; begin
 select event_row_id into event from public.authorize_google_calendar_event(pg_temp.tid('appointment'),repeat('c',64),'synthetic-tracking-subject',repeat('r',40),array['https://www.googleapis.com/auth/calendar.events.owned']);
 result:=public.request_patient_google_calendar_deletion(pg_temp.tv('legacy'),true);
 if result->>'event_row_id' is distinct from event::text or result->>'status'<>'pending_delete' then raise exception 'CALENDAR_REMOVAL_NOT_QUEUED'; end if;
 perform public.claim_google_calendar_event_sync(event,gen_random_uuid());
 select to_jsonb(e) into before_e from public.appointment_google_calendar_events e where id=event;
 result:=public.request_patient_google_calendar_deletion(pg_temp.tv('legacy'),true);
 if (select to_jsonb(e) from public.appointment_google_calendar_events e where id=event) is distinct from before_e
  or (select count(*) from public.audit_logs where entity_id=pg_temp.tid('appointment') and action='appointment.google_calendar_delete_requested')<>1 then raise exception 'CALENDAR_REMOVAL_RETRY_RESET_WORK'; end if;
 insert into calendar_tracking_fixture values('event',event::text);
end $$;
select extensions.pass('An explicit removal queues and audits once; repeating it preserves the existing live lease');
update public.patients set email='corrected-tracking@example.test' where id=pg_temp.tid('patient');
do $$ begin
 begin perform public.record_patient_calendar_action(pg_temp.tv('legacy'),true,'downloaded_ics',null); raise exception 'REVOKED_CALENDAR_CLICK_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 begin perform public.mark_patient_calendar_offered(pg_temp.tv('legacy'),true); raise exception 'REVOKED_CALENDAR_OFFER_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 begin perform public.record_patient_calendar_metric(pg_temp.tv('legacy'),true,'maps',null); raise exception 'REVOKED_CALENDAR_METRIC_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 begin perform public.request_patient_google_calendar_deletion(pg_temp.tv('legacy'),true); raise exception 'REVOKED_CALENDAR_REMOVAL_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
end $$;
select extensions.pass('A stable calendar identity cannot authorize any new observation or removal after contact correction');
insert into calendar_tracking_fixture values('access',public.issue_appointment_management_capability(pg_temp.tid('business'),pg_temp.tid('appointment'),1));
select extensions.is(public.record_patient_calendar_action(pg_temp.tv('access'),false,'downloaded_ics',null),true,'Fresh management authority records its own click without changing Calendar UID');
select extensions.throws_ok($q$select public.record_patient_calendar_action(pg_temp.tv('access'),true,'clicked_ics',null)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','A capability cannot impersonate the legacy channel');
update public.business_subscriptions set commercial_access_enabled=false where business_id=pg_temp.tid('business');
select extensions.throws_ok($q$select public.request_patient_google_calendar_deletion(pg_temp.tv('access'),false)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','The narrow suspended consultation/cancellation exception grants no auxiliary write');
update public.business_subscriptions set commercial_access_enabled=true where business_id=pg_temp.tid('business');
update public.businesses set public_booking_enabled=false where id=pg_temp.tid('business');
select extensions.is(public.record_patient_calendar_action(pg_temp.tv('access'),false,'clicked_outlook',null),true,'Online booking off preserves reminders for an existing appointment');
create function pg_temp.reject_calendar_audit() returns trigger language plpgsql as $$ begin
 if new.entity_id=pg_temp.tid('appointment') and new.action='appointment.calendar_action' then raise exception 'SYNTHETIC_CALENDAR_AUDIT_FAILURE'; end if;
 return new; end $$;
create trigger zz_reject_calendar_audit after insert on public.audit_logs for each row execute function pg_temp.reject_calendar_audit();
do $$ declare before_a jsonb; before_p jsonb; before_count bigint; begin
 select to_jsonb(a) into before_a from public.appointments a where id=pg_temp.tid('appointment');
 select to_jsonb(p) into before_p from public.patients p where id=pg_temp.tid('patient');
 select count(*) into before_count from public.audit_logs where entity_id=pg_temp.tid('appointment');
 begin perform public.record_patient_calendar_action(pg_temp.tv('access'),false,'clicked_ics',null); raise exception 'CALENDAR_AUDIT_FAILURE_IGNORED';
 exception when others then if sqlerrm is distinct from 'SYNTHETIC_CALENDAR_AUDIT_FAILURE' then raise; end if; end;
 if (select to_jsonb(a) from public.appointments a where id=pg_temp.tid('appointment')) is distinct from before_a
  or (select to_jsonb(p) from public.patients p where id=pg_temp.tid('patient')) is distinct from before_p
  or (select count(*) from public.audit_logs where entity_id=pg_temp.tid('appointment'))<>before_count then raise exception 'CALENDAR_AUDIT_PARTIAL_EFFECT'; end if;
end $$;
drop trigger zz_reject_calendar_audit on public.audit_logs;
select extensions.pass('A forced audit failure rolls back coverage, counter, patient activity and the audit itself');
create function pg_temp.expire_calendar_tracking_after_audit() returns trigger language plpgsql as $$ begin
 if new.entity_id=pg_temp.tid('appointment') and new.action='appointment.calendar_action' then
  perform pg_sleep_until((select expires_at+interval '25 milliseconds' from private.appointment_management_capabilities where token_hash=encode(extensions.digest(pg_temp.tv('access'),'sha256'),'hex')));
 end if; return new; end $$;
create trigger zz_expire_calendar_tracking after insert on public.audit_logs for each row execute function pg_temp.expire_calendar_tracking_after_audit();
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 second' where token_hash=encode(extensions.digest(pg_temp.tv('access'),'sha256'),'hex');
select extensions.throws_ok($q$select public.record_patient_calendar_action(pg_temp.tv('access'),false,'clicked_phone_calendar',null)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','Expiry after telemetry/audit effects aborts the whole command');
drop trigger zz_expire_calendar_tracking on public.audit_logs;
update private.appointment_management_capabilities set expires_at=clock_timestamp()+interval '1 day' where token_hash=encode(extensions.digest(pg_temp.tv('access'),'sha256'),'hex');
update public.appointments set status='cancelled' where id=pg_temp.tid('appointment');
select extensions.throws_ok($q$select public.record_patient_calendar_action(pg_temp.tv('access'),false,'clicked_ics',null)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE','A closed appointment cannot acquire new reminder coverage');
do $$ declare result jsonb; begin
 result:=public.request_patient_google_calendar_deletion(pg_temp.tv('access'),false);
 if result->>'status'<>'pending_delete' then raise exception 'CLOSED_CALENDAR_REMOVAL_NOT_RECOVERABLE'; end if;
 perform public.complete_google_calendar_event_delete(pg_temp.tid('event'),clock_timestamp());
 result:=public.request_patient_google_calendar_deletion(pg_temp.tv('access'),false);
 if result->>'status'<>'not_connected' or result->'event_row_id'<>'null'::jsonb
  or (select status from public.appointments where id=pg_temp.tid('appointment'))<>'cancelled' then raise exception 'CALENDAR_REMOVAL_REPLAY_INVENTED_EVENT'; end if;
end $$;
select extensions.pass('Removal remains useful after cancellation, and a lost-response retry observes no local link without claiming a new external deletion');
select extensions.ok(not has_function_privilege('anon','public.record_patient_calendar_action(text,boolean,text,text)','EXECUTE')
 and not has_function_privilege('authenticated','public.request_patient_google_calendar_deletion(text,boolean)','EXECUTE')
 and has_function_privilege('service_role','public.record_patient_calendar_action(text,boolean,text,text)','EXECUTE'),
 'Auxiliary commands are backend-only and require their own patient authority');
select * from extensions.finish();
rollback;
