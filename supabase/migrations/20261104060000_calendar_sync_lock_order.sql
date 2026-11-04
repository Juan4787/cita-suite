-- Calendar completion writes appointment telemetry and patient activity. Acquire
-- the final locks before any child, consistently for a single result and a batch.
-- Claim-only/queue-only operations retain their separate responsibilities.
begin;
create function private.lock_calendar_sync_events(p_event_ids uuid[])
returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if cardinality(p_event_ids)>100 then raise exception 'GOOGLE_CALENDAR_BATCH_COMPLETE_INVALID'; end if;
 perform 1 from public.appointments a
 where a.id in(select e.appointment_id from public.appointment_google_calendar_events e where e.id=any(p_event_ids))
 order by a.id for no key update;
 perform 1 from public.patients p
 where (p.business_id,p.id) in(select a.business_id,a.patient_id from public.appointments a
  join public.appointment_google_calendar_events e on e.appointment_id=a.id where e.id=any(p_event_ids))
 order by p.id for update;
 perform 1 from public.google_calendar_connections c
 where c.id in(select e.connection_id from public.appointment_google_calendar_events e where e.id=any(p_event_ids))
 order by c.id for update;
 perform 1 from public.appointment_google_calendar_events e where e.id=any(p_event_ids) order by e.id for update;
end $$;
revoke all on function private.lock_calendar_sync_events(uuid[]) from public,anon,authenticated,service_role;

-- Established body/ABI/ACL retained after acquiring the complete lock set.
CREATE OR REPLACE FUNCTION public.complete_google_calendar_event_sync(p_event_row_id uuid, p_google_event_id text, p_synced_sequence integer, p_now timestamp with time zone DEFAULT now())
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
	event_row public.appointment_google_calendar_events%rowtype;
	appointment_row public.appointments%rowtype;
	final_status text;
begin
	perform private.lock_calendar_sync_events(array[p_event_row_id]);
	select * into event_row
	from public.appointment_google_calendar_events
	where id = p_event_row_id
	for update;
	if not found then raise exception 'GOOGLE_CALENDAR_EVENT_LINK_NOT_FOUND'; end if;

	select * into appointment_row
	from public.appointments
	where id = event_row.appointment_id
	for no key update;
	if not found then raise exception 'GOOGLE_CALENDAR_APPOINTMENT_NOT_FOUND'; end if;

	final_status := case
		when event_row.sync_status = 'pending_delete' then 'pending_delete'
		when appointment_row.status = 'cancelled' then 'pending_delete'
		when appointment_row.calendar_sequence <> p_synced_sequence then 'pending_update'
		when appointment_row.status in ('reserved', 'confirmed', 'reschedule_requested') then 'active'
		else 'detached'
	end;

	update public.appointment_google_calendar_events
	set event_id = p_google_event_id,
		synced_sequence = p_synced_sequence,
		sync_status = final_status,
		claimed_at = null,
		attempt_count = 0,
		next_attempt_at = case when final_status in ('pending_update', 'pending_delete') then p_now else next_attempt_at end,
		last_synced_at = p_now,
		last_error_code = null,
		last_error_at = null,
		updated_at = p_now
	where id = event_row.id;

	if final_status = 'active' then
		update public.appointments
		set calendar_action_status = 'synced_google',
			calendar_provider = 'google',
			calendar_action_at = p_now,
			calendar_action_count = calendar_action_count
				+ case when calendar_action_status = 'synced_google' then 0 else 1 end,
			calendar_update_required_at = null,
			updated_at = greatest(updated_at, p_now)
		where id = appointment_row.id;
	end if;

	return final_status;
end;
$function$
;

-- Established body/ABI/ACL retained after acquiring the complete lock set.
CREATE OR REPLACE FUNCTION public.complete_google_calendar_event_delete(p_event_row_id uuid, p_now timestamp with time zone DEFAULT now())
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
	event_row public.appointment_google_calendar_events%rowtype;
	deleted_connection_id uuid;
begin
	perform private.lock_calendar_sync_events(array[p_event_row_id]);
	select * into event_row
	from public.appointment_google_calendar_events
	where id = p_event_row_id
	for update;
	if not found then raise exception 'GOOGLE_CALENDAR_EVENT_LINK_NOT_FOUND'; end if;

	update public.appointments
	set calendar_action_status = case
			when calendar_action_status = 'synced_google' then 'offered'
			else calendar_action_status
		end,
		calendar_provider = case
			when calendar_action_status = 'synced_google' then null
			else calendar_provider
		end,
		calendar_update_required_at = null,
		updated_at = greatest(updated_at, p_now)
	where id = event_row.appointment_id;

	delete from public.appointment_google_calendar_events
	where id = event_row.id;

	-- Si ya no queda ningún turno vinculado, la autorización deja de ser
	-- necesaria. La app conserva el token en memoria solo para revocarlo ante
	-- Google después de confirmar esta transacción.
	delete from public.google_calendar_connections connection
	where connection.id = event_row.connection_id
		and not exists (
			select 1
			from public.appointment_google_calendar_events remaining
			where remaining.connection_id = connection.id
		)
	returning connection.id into deleted_connection_id;

	return deleted_connection_id;
end;
$function$
;

-- Established body/ABI/ACL retained after acquiring the complete lock set.
CREATE OR REPLACE FUNCTION public.fail_google_calendar_event_sync(p_event_row_id uuid, p_failure_category text, p_error_code text, p_next_attempt_at timestamp with time zone, p_now timestamp with time zone DEFAULT now())
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
	event_row public.appointment_google_calendar_events%rowtype;
	final_status text;
begin
	if p_failure_category not in ('transient', 'authorization', 'missing', 'permanent') then
		raise exception 'GOOGLE_CALENDAR_FAILURE_CATEGORY_INVALID';
	end if;

	perform private.lock_calendar_sync_events(array[p_event_row_id]);
	select * into event_row
	from public.appointment_google_calendar_events
	where id = p_event_row_id
	for update;
	if not found then raise exception 'GOOGLE_CALENDAR_EVENT_LINK_NOT_FOUND'; end if;

	final_status := case p_failure_category
		when 'transient' then event_row.sync_status
		when 'authorization' then 'needs_reconnect'
		when 'missing' then 'deleted'
		else 'failed'
	end;

	update public.appointment_google_calendar_events
	set sync_status = final_status,
		event_id = case when p_failure_category = 'missing' then null else event_id end,
		claimed_at = null,
		attempt_count = attempt_count + 1,
		next_attempt_at = case
			when p_failure_category = 'transient' then p_next_attempt_at
			else next_attempt_at
		end,
		last_error_code = left(coalesce(p_error_code, 'unknown'), 80),
		last_error_at = p_now,
		updated_at = p_now
	where id = event_row.id;

	if p_failure_category = 'authorization' then
		update public.google_calendar_connections
		set refresh_token_ciphertext = null,
			revoked_at = p_now,
			last_error_code = left(coalesce(p_error_code, 'authorization'), 80),
			updated_at = p_now
		where id = event_row.connection_id;
	end if;

	if p_failure_category in ('authorization', 'missing', 'permanent') then
		update public.appointments
		set calendar_action_status = case
				when calendar_action_status = 'synced_google' then 'offered'
				else calendar_action_status
			end,
			calendar_provider = case
				when calendar_action_status = 'synced_google' then null
				else calendar_provider
			end,
			calendar_update_required_at = case
				when status in ('reserved', 'confirmed', 'reschedule_requested') then p_now
				else calendar_update_required_at
			end,
			updated_at = greatest(updated_at, p_now)
		where id = event_row.appointment_id;
	end if;

	return final_status;
end;
$function$
;

-- Established body/ABI/ACL retained after acquiring the complete lock set.
CREATE OR REPLACE FUNCTION public.complete_google_calendar_sync_batch(p_claim_token uuid, p_now timestamp with time zone, p_results jsonb, p_finish boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare v_item jsonb; v_id uuid; v_outcome text; v_status text; v_removed uuid; v_appointment uuid;
 v_results jsonb:='[]'::jsonb; v_released integer:=0;
begin
 if p_claim_token is null or p_now is null or jsonb_typeof(coalesce(p_results,'[]'::jsonb))<>'array'
  or jsonb_array_length(coalesce(p_results,'[]'::jsonb))>100
 then raise exception 'GOOGLE_CALENDAR_BATCH_COMPLETE_INVALID'; end if;
 if exists(
  select 1 from jsonb_array_elements(coalesce(p_results,'[]'::jsonb)) item(value)
  where jsonb_typeof(item.value)<>'object'
   or coalesce(item.value->>'event_row_id','') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
   or coalesce(item.value->>'outcome','') not in ('synced','deleted','failed','delete_requested')
   or (item.value->>'outcome'='synced' and (jsonb_typeof(item.value->'google_event_id') is distinct from 'string'
    or jsonb_typeof(item.value->'synced_sequence') is distinct from 'number'))
   or (item.value->>'outcome'='failed' and (jsonb_typeof(item.value->'failure_category') is distinct from 'string'
    or jsonb_typeof(item.value->'next_attempt_at') is distinct from 'string'))
 ) then raise exception 'GOOGLE_CALENDAR_BATCH_RESULT_INVALID'; end if;
 -- Lock all target sets in stable order before the first result retains any child.
 perform private.lock_calendar_sync_events(array(select e.id from public.appointment_google_calendar_events e
  where e.claim_token=p_claim_token and e.id in(select (item.value->>'event_row_id')::uuid
   from jsonb_array_elements(coalesce(p_results,'[]'::jsonb)) item(value))));
 for v_item in select value from jsonb_array_elements(coalesce(p_results,'[]'::jsonb)) loop
  v_id:=(v_item->>'event_row_id')::uuid; v_outcome:=v_item->>'outcome'; v_removed:=null;
  select e.appointment_id into v_appointment from public.appointment_google_calendar_events e
  where e.id=v_id and e.claim_token=p_claim_token for update;
  if not found then
   v_results:=v_results||jsonb_build_array(jsonb_build_object('event_row_id',v_id,'status','stale'));
   continue;
  end if;
  if v_outcome='synced' then
   v_status:=public.complete_google_calendar_event_sync(v_id,v_item->>'google_event_id',(v_item->>'synced_sequence')::integer,p_now);
  elsif v_outcome='deleted' then
   v_removed:=public.complete_google_calendar_event_delete(v_id,p_now);
   v_status:='deleted';
  elsif v_outcome='failed' then
   v_status:=public.fail_google_calendar_event_sync(v_id,v_item->>'failure_category',v_item->>'error_code',(v_item->>'next_attempt_at')::timestamptz,p_now);
  else
   perform public.request_google_calendar_event_deletion(v_appointment,p_now);
   -- The deletion runs on the next event instead of waiting for the claim to expire.
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
