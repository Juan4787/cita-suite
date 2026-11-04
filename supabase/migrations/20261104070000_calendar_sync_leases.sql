-- One lease protocol for immediate and scheduled Calendar work. A new OAuth
-- grant cannot retire an in-flight lease; a missing response is not a rejection.
begin;
create function private.normalize_calendar_sync_lease()
returns trigger language plpgsql set search_path=pg_catalog,pg_temp as $$
begin
 if new.sync_status='detached' then new.claimed_at:=null; end if;
 if tg_op='UPDATE' then
  if new.connection_id is distinct from old.connection_id then new.claimed_at:=null; end if;
 end if;
 if new.claimed_at is null then new.claim_token:=null; end if;
 return new;
end $$;
revoke all on function private.normalize_calendar_sync_lease() from public,anon,authenticated,service_role;
create trigger normalize_calendar_sync_lease before insert or update on public.appointment_google_calendar_events
 for each row execute function private.normalize_calendar_sync_lease();
update public.appointment_google_calendar_events set claim_token=null where claimed_at is null and claim_token is not null;
alter table public.appointment_google_calendar_events add constraint calendar_claim_token_requires_date
 check(claim_token is null or claimed_at is not null);

create function private.claim_calendar_sync_event_at(p_event_row_id uuid,p_claim_token uuid,p_now timestamptz)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare e public.appointment_google_calendar_events; c public.google_calendar_connections; v_recovered boolean:=false;
begin
 -- Claiming changes only this child and never waits for its appointment. The
 -- current parent/identity is checked again by the result transaction/consumer.
 select * into e from public.appointment_google_calendar_events where id=p_event_row_id for update skip locked;
 if not found then return null; end if;
 if e.claim_token=p_claim_token then
  -- Only the owning executor may recover its unanswered SQL claim. Never
  -- extend the lease, renew an expired owner or create another logical attempt.
  if e.claimed_at is null or e.claimed_at<p_now-interval '10 minutes'
   or e.sync_status not in ('pending_create','pending_update','pending_delete') then return null; end if;
  v_recovered:=true;
 else
  update public.appointment_google_calendar_events set claimed_at=p_now,claim_token=p_claim_token,last_attempt_at=p_now,updated_at=p_now
  where id=p_event_row_id and sync_status in ('pending_create','pending_update','pending_delete') and next_attempt_at<=p_now
   and (claimed_at is null or claimed_at<p_now-interval '10 minutes') returning * into e;
  if not found then return null; end if;
 end if;
 select * into c from public.google_calendar_connections where id=e.connection_id;
 return jsonb_build_object('claim_recovered',v_recovered,'event_row_id',e.id,'business_id',e.business_id,'appointment_id',e.appointment_id,
  'connection_id',e.connection_id,'calendar_id',e.calendar_id,'event_id',e.event_id,'sync_status',e.sync_status,
  'synced_sequence',e.synced_sequence,'attempt_count',e.attempt_count,'refresh_token_ciphertext',c.refresh_token_ciphertext,
  'connection_revoked_at',c.revoked_at);
end $$;
revoke all on function private.claim_calendar_sync_event_at(uuid,uuid,timestamptz) from public,anon,authenticated,service_role;

create function public.claim_google_calendar_event_sync(p_event_row_id uuid,p_claim_token uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare result jsonb; v_now timestamptz:=clock_timestamp();
begin
 if p_event_row_id is null or p_claim_token is null then raise exception 'GOOGLE_CALENDAR_EVENT_CLAIM_INVALID'; end if;
 result:=private.claim_calendar_sync_event_at(p_event_row_id,p_claim_token,v_now);
 if result is not null then
  if not (result->>'claim_recovered')::boolean then
   perform private.record_job_queue_turns('calendar',array[(result->>'business_id')::uuid],v_now);
  end if;
  result:=result||jsonb_build_object('business_turn',1);
 end if;
 return result;
end $$;
revoke all on function public.claim_google_calendar_event_sync(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.claim_google_calendar_event_sync(uuid,uuid) to service_role;

CREATE OR REPLACE FUNCTION public.claim_google_calendar_sync_batch(p_now timestamp with time zone, p_limit integer, p_claim_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare v record; v_item jsonb;
 v_items jsonb:='[]'::jsonb; v_claimed integer:=0; v_served uuid[]:='{}';
begin
 if p_now is null or p_claim_token is null or p_limit is null or p_limit not between 1 and 100 then
  raise exception 'GOOGLE_CALENDAR_BATCH_CLAIM_INVALID';
 end if;
 for v in
  select e.id,row_number() over(partition by e.business_id order by e.next_attempt_at,e.created_at,e.id)::integer as turn,
   e.next_attempt_at,e.created_at
  from public.appointment_google_calendar_events e
  left join private.job_queue_rotation r on r.queue='calendar' and r.business_id=e.business_id
  where e.sync_status in ('pending_create','pending_update','pending_delete') and e.next_attempt_at<=p_now
   and (e.claimed_at is null or e.claimed_at<p_now-interval '10 minutes')
  order by turn,r.last_claimed_at nulls first,e.next_attempt_at,e.created_at,e.id
  limit p_limit*2
 loop
  exit when v_claimed>=p_limit;
  v_item:=private.claim_calendar_sync_event_at(v.id,p_claim_token,p_now);
  if v_item is null then continue; end if;
  v_served:=v_served||(v_item->>'business_id')::uuid;
  v_claimed:=v_claimed+1;
  v_items:=v_items||jsonb_build_array(v_item||jsonb_build_object('business_turn',v.turn));
 end loop;
 perform private.record_job_queue_turns('calendar',v_served,p_now);
 return v_items;
end $function$
;

CREATE OR REPLACE FUNCTION public.authorize_patient_google_calendar_event(p_token text, p_legacy boolean, p_attempt_id uuid, p_oauth_client_key text, p_google_subject text, p_refresh_token_ciphertext text, p_granted_scopes text[])
 RETURNS TABLE(connection_row_id uuid, event_row_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare attempt public.google_calendar_oauth_attempts; result record;
begin
 attempt:=private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,p_attempt_id);
 if attempt.consumed_at is null then raise exception 'GOOGLE_CALENDAR_OAUTH_STATE_INVALID'; end if;
 if attempt.authorized_at is not null then raise exception 'GOOGLE_CALENDAR_OAUTH_ALREADY_AUTHORIZED'; end if;
 -- Retain the owned event while deciding: a child-only claimant may run
 -- even with our parent held. All completion writers retain their complete
 -- parent set first, and a claimant never waits for a parent/connection.
 perform 1 from public.appointment_google_calendar_events
 where (business_id,appointment_id)=(attempt.business_id,attempt.appointment_id) for update;
 if exists(select 1 from public.appointment_google_calendar_events
  where (business_id,appointment_id)=(attempt.business_id,attempt.appointment_id)
   and claimed_at>=clock_timestamp()-interval '10 minutes') then
  raise exception 'GOOGLE_CALENDAR_SYNC_IN_PROGRESS'; end if;
 -- The background worker may already be creating the previous account's event.
 -- Do not replace that connection just because Pending has no provider ID yet.
 if exists(select 1 from public.appointment_google_calendar_events e join public.google_calendar_connections c on c.id=e.connection_id
  where (e.business_id,e.appointment_id)=(attempt.business_id,attempt.appointment_id)
   and e.sync_status in ('active','pending_create','pending_update','pending_delete')
   and (c.oauth_client_key,c.google_subject) is distinct from (p_oauth_client_key,p_google_subject)) then
  raise exception 'GOOGLE_CALENDAR_ALREADY_CONNECTED'; end if;
 select * into result from public.authorize_google_calendar_event(attempt.appointment_id,p_oauth_client_key,p_google_subject,
  p_refresh_token_ciphertext,p_granted_scopes,clock_timestamp());
 if result.event_row_id is null or result.connection_row_id is null then raise exception 'GOOGLE_CALENDAR_EVENT_LINK_NOT_CREATED'; end if;
 update public.google_calendar_oauth_attempts set authorized_at=clock_timestamp() where id=attempt.id;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(attempt.business_id,null,'appointment.google_calendar_authorized','appointment',attempt.appointment_id,
  jsonb_build_object('event_id',result.event_row_id,'attempt_id',attempt.id));
 perform private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,attempt.id);
 return query select result.connection_row_id::uuid,result.event_row_id::uuid;
end $function$
;

CREATE OR REPLACE FUNCTION public.complete_google_calendar_sync_batch(p_claim_token uuid, p_now timestamp with time zone, p_results jsonb, p_finish boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare v_item jsonb; v_id uuid; v_outcome text; v_status text; v_removed uuid; v_appointment uuid; v_sync_status text; v_claimed_at timestamptz; v_same_context boolean;
 v_results jsonb:='[]'::jsonb; v_released integer:=0;
begin
 if p_claim_token is null or p_now is null or jsonb_typeof(coalesce(p_results,'[]'::jsonb))<>'array'
  or jsonb_array_length(coalesce(p_results,'[]'::jsonb))>100
 then raise exception 'GOOGLE_CALENDAR_BATCH_COMPLETE_INVALID'; end if;
 if exists(
  select 1 from jsonb_array_elements(coalesce(p_results,'[]'::jsonb)) item(value)
  where jsonb_typeof(item.value)<>'object'
   or coalesce(item.value->>'event_row_id','') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
   or coalesce(item.value->>'outcome','') not in ('synced','deleted','failed','delete_requested','uncertain','released')
   or (item.value->>'outcome'='synced' and (jsonb_typeof(item.value->'google_event_id') is distinct from 'string'
    or jsonb_typeof(item.value->'synced_sequence') is distinct from 'number'))
   or (item.value->>'outcome'='failed' and (jsonb_typeof(item.value->'failure_category') is distinct from 'string'
    or jsonb_typeof(item.value->'next_attempt_at') is distinct from 'string'))
   or (item.value->>'outcome'='uncertain' and (jsonb_typeof(item.value->'error_code') is distinct from 'string'
    or jsonb_typeof(item.value->'next_attempt_at') is distinct from 'string'))
   or ((item.value ? 'observed_sequence') is distinct from (item.value ? 'observed_sync_status'))
   or (item.value ? 'observed_sequence' and (jsonb_typeof(item.value->'observed_sequence') is distinct from 'number'
    or coalesce(item.value->>'observed_sequence','') !~ '^(0|[1-9][0-9]{0,9})$'
    or coalesce(item.value->>'observed_sync_status','') not in ('pending_create','pending_update','pending_delete')))
 ) then raise exception 'GOOGLE_CALENDAR_BATCH_RESULT_INVALID'; end if;
 -- Lock all target sets in stable order before the first result retains any child.
 perform private.lock_calendar_sync_events(array(select e.id from public.appointment_google_calendar_events e
  where e.claim_token=p_claim_token and e.id in(select (item.value->>'event_row_id')::uuid
   from jsonb_array_elements(coalesce(p_results,'[]'::jsonb)) item(value))));
 for v_item in select value from jsonb_array_elements(coalesce(p_results,'[]'::jsonb)) loop
  v_id:=(v_item->>'event_row_id')::uuid; v_outcome:=v_item->>'outcome'; v_removed:=null;
  select e.appointment_id,e.sync_status,e.claimed_at into v_appointment,v_sync_status,v_claimed_at from public.appointment_google_calendar_events e
  where e.id=v_id and e.claim_token=p_claim_token for update;
  if not found then
   v_results:=v_results||jsonb_build_array(jsonb_build_object('event_row_id',v_id,'status','stale'));
   continue;
  end if;
  v_same_context:=not (v_item ? 'observed_sequence') or
   ((v_item->>'observed_sync_status')=v_sync_status and (v_sync_status='pending_delete' or
    (v_item->>'observed_sequence')::integer=(select calendar_sequence from public.appointments where id=v_appointment)));
  if v_outcome='uncertain' then
   -- The HTTP mutation may have happened. Keep the existing ten-minute safety
   -- window, retire its owner token and leave the CURRENT useful intent queued.
   update public.appointment_google_calendar_events set claim_token=null,
    claimed_at=coalesce(v_claimed_at,p_now),attempt_count=attempt_count+1,
    next_attempt_at=greatest((v_item->>'next_attempt_at')::timestamptz,coalesce(v_claimed_at,p_now)+interval '10 minutes'),
    last_error_code='calendar_outcome_uncertain',last_error_at=p_now,updated_at=p_now where id=v_id;
   insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
   select business_id,null,'appointment.google_calendar_outcome_uncertain','appointment',v_appointment,
    jsonb_build_object('lease',p_claim_token,'reason',left(v_item->>'error_code',80))
   from public.appointment_google_calendar_events where id=v_id;
   v_status:=v_sync_status;
  elsif v_outcome='released' or (v_outcome='failed' and not v_same_context) then
   -- Unstarted work and a refusal of superseded fields are not a failure of
   -- today's request. In particular a removal intent survives a date change.
   update public.appointment_google_calendar_events set claimed_at=null,claim_token=null,
    next_attempt_at=case when v_outcome='released' then next_attempt_at else p_now end,updated_at=p_now where id=v_id;
   v_status:=v_sync_status;
  elsif v_outcome='synced' then
   v_status:=public.complete_google_calendar_event_sync(v_id,v_item->>'google_event_id',(v_item->>'synced_sequence')::integer,p_now);
  elsif v_outcome='deleted' then
   v_removed:=public.complete_google_calendar_event_delete(v_id,p_now);
   v_status:='deleted';
  elsif v_outcome='failed' then
   v_status:=public.fail_google_calendar_event_sync(v_id,v_item->>'failure_category',v_item->>'error_code',(v_item->>'next_attempt_at')::timestamptz,p_now);
  else
   -- Preserve the established backend command contract. This is an explicit
   -- deletion request, not a failure of a superseded create/update payload.
   perform public.request_google_calendar_event_deletion(v_appointment,p_now);
   update public.appointment_google_calendar_events set claimed_at=null where id=v_id;
   v_status:='pending_delete';
  end if;
  update public.appointment_google_calendar_events set claim_token=null where id=v_id;
  v_results:=v_results||jsonb_build_array(jsonb_build_object('event_row_id',v_id,'status',v_status,'removed_connection_id',v_removed));
 end loop;
 if p_finish then
  update public.appointment_google_calendar_events set claimed_at=null,claim_token=null,updated_at=p_now
  where claim_token=p_claim_token;
  get diagnostics v_released=row_count;
 end if;
 return jsonb_build_object('results',v_results,'released',v_released);
end $function$
;

notify pgrst,'reload schema';
commit;
