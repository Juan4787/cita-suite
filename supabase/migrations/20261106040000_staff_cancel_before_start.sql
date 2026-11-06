-- P1: an appointment that already started is not cancelled by the practice (plan 12.34). The page
-- already hid the action, but only for what it had read; this is the same rule at the only writer,
-- with the same lock and clock as the rest of the command. Rescheduling a past appointment stays.
-- Same signature and privileges: only the body changes.
begin;

create or replace function public.apply_staff_appointment_management(p_business_id uuid,p_actor_id uuid,p_appointment_id uuid,
 p_operation_id uuid,p_expected_revision text,p_action text,p_starts_at timestamptz default null,
 p_ignore_break boolean default false,p_availability_revision bigint default null,p_reason text default null,
 p_replay_only boolean default false) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; before_a public.appointments; b public.businesses; s public.services;
 prior private.appointment_management_operations; m public.appointment_management_states;
 v_fingerprint text; v_result jsonb; v_now timestamptz; v_teams uuid[]; v_locked_teams uuid[];
 v_professional uuid; v_deposit_status text; v_status text; v_changed boolean:=true; v_action text; v_revision bigint;
begin
 if p_business_id is null or p_actor_id is null or p_appointment_id is null or p_operation_id is null
  or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false)
  or not coalesce(p_action in ('cancel','confirm','request_reschedule','reschedule'),false)
  or p_ignore_break is null or p_replay_only is null then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 if p_reason is not null and char_length(p_reason)>500 then raise exception 'APPOINTMENT_REASON_INVALID'; end if;
 if p_action<>'reschedule' and (p_starts_at is not null or p_availability_revision is not null or p_ignore_break) then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 if p_action='reschedule' and (p_starts_at is null or not isfinite(p_starts_at) or p_reason is not null) then
  raise exception 'APPOINTMENT_RESCHEDULE_TIME_INVALID'; end if;
 perform pg_advisory_xact_lock(hashtextextended('appointment-management-operation:'||p_business_id::text||':'||p_operation_id::text,0));
 if p_action='reschedule' and not p_replay_only then
  select * into b from public.businesses where id=p_business_id for share;
 end if;
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_actor_id) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if p_action='reschedule' and not p_replay_only then
  select array_agg(professional_id order by professional_id) into v_teams from public.appointment_professionals
   where business_id=p_business_id and appointment_id=p_appointment_id;
  for v_professional in select unnest(v_teams) loop
   perform pg_advisory_xact_lock(hashtextextended(p_business_id::text||':'||v_professional::text,0));
  end loop;
 end if;
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_NOT_FOUND'; end if;
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_actor_id) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=a.id;
 if not found then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_fingerprint:=encode(extensions.digest(jsonb_build_object('contract','staff-agenda-1','actor_id',p_actor_id,
  'appointment_id',a.id,'patient_id',a.patient_id,'generation',m.generation,'action',p_action,
  'expected_revision',p_expected_revision,'starts_at',extract(epoch from p_starts_at),'ignore_break',p_ignore_break,
  'availability_revision',p_availability_revision,'reason',p_reason)::text,'sha256'),'hex');
 select * into prior from private.appointment_management_operations where business_id=p_business_id and operation_id=p_operation_id;
 if found then
  if prior.appointment_id is distinct from a.id or prior.actor_id is distinct from p_actor_id or prior.origin<>'staff'
   or prior.action is distinct from p_action or prior.request_fingerprint is distinct from v_fingerprint then
   raise exception 'APPOINTMENT_OPERATION_CONFLICT'; end if;
  return prior.result||jsonb_build_object('idempotent_replay',true);
 end if;
 if p_replay_only then return null; end if;
 if private.appointment_semantic_revision(p_business_id,a.id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_now:=clock_timestamp(); before_a:=a;
 if a.status not in ('reserved','confirmed','reschedule_requested') then raise exception 'APPOINTMENT_TERMINAL_STATUS'; end if;
 -- Decided by Juan on 6 November (plan 12.34). The clock is read under the appointment lock, so a
 -- page left open past the start time cannot cancel. Exact replays were answered above.
 if p_action='cancel' and a.starts_at<=v_now then raise exception 'APPOINTMENT_ALREADY_STARTED'; end if;
 if p_action='reschedule' then
  if p_starts_at=a.starts_at then v_changed:=false;
  else
   if p_starts_at<=v_now then raise exception 'APPOINTMENT_RESCHEDULE_TIME_INVALID'; end if;
   if p_availability_revision is null or p_availability_revision is distinct from b.booking_availability_revision then
    raise exception 'APPOINTMENT_AVAILABILITY_CHANGED'; end if;
   select array_agg(professional_id order by professional_id) into v_locked_teams from public.appointment_professionals
    where business_id=p_business_id and appointment_id=a.id;
   if v_teams is distinct from v_locked_teams then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
   select * into s from public.services where business_id=p_business_id and id=a.service_id and is_active;
   if not found then raise exception 'SERVICE_NOT_FOUND'; end if;
   select status into v_deposit_status from public.appointment_deposits where business_id=p_business_id and appointment_id=a.id;
   v_status:=case when v_deposit_status in ('paid','waived') then 'confirmed' else 'reserved' end;
   update public.appointments set starts_at=p_starts_at,ends_at=p_starts_at+make_interval(mins=>s.duration_minutes),
    status=v_status,confirmed_at=case when v_status='confirmed' then coalesce(a.confirmed_at,v_now) end,
    reschedule_requested_at=null,reminder_due_at=null,calendar_sequence=a.calendar_sequence+1,
    calendar_update_required_at=case when a.calendar_action_count>0 then v_now end,
    ignore_break=p_ignore_break,updated_by_user_id=p_actor_id,updated_at=v_now
   where business_id=p_business_id and id=a.id returning * into a;
   v_action:='appointment.rescheduled';
  end if;
 else
  v_status:=case p_action when 'cancel' then 'cancelled' when 'confirm' then 'confirmed' else 'reschedule_requested' end;
  if a.status=v_status then raise exception 'APPOINTMENT_STATUS_UNCHANGED'; end if;
  if (p_action='confirm' and a.status<>'reserved') or (p_action='request_reschedule' and a.status='reschedule_requested') then
   raise exception 'APPOINTMENT_INVALID_TRANSITION'; end if;
  update public.appointments set status=v_status,
   confirmed_at=case when p_action='confirm' then v_now else a.confirmed_at end,
   cancelled_at=case when p_action='cancel' then v_now else a.cancelled_at end,
   cancelled_by_user_id=case when p_action='cancel' then p_actor_id else a.cancelled_by_user_id end,
   cancelled_reason=case when p_action='cancel' then p_reason else a.cancelled_reason end,
   reschedule_requested_at=case when p_action='request_reschedule' then v_now else a.reschedule_requested_at end,
   calendar_sequence=a.calendar_sequence+case when p_action='cancel' then 1 else 0 end,
   calendar_update_required_at=case when p_action='cancel' and a.calendar_action_count>0 then v_now else a.calendar_update_required_at end,
   updated_by_user_id=p_actor_id,updated_at=v_now
  where business_id=p_business_id and id=a.id returning * into a;
  v_action:='appointment.'||v_status;
 end if;
 if v_changed then
  insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
  values(p_business_id,p_actor_id,v_action,'appointment',a.id,jsonb_build_object('origin','staff','operation_id',p_operation_id,
   'from_status',before_a.status,'to_status',a.status,'from_starts_at',before_a.starts_at,'from_ends_at',before_a.ends_at,
   'to_starts_at',a.starts_at,'to_ends_at',a.ends_at,'reason',p_reason,'ignore_break',a.ignore_break,
   'calendar_update_required',a.calendar_update_required_at is not null));
 end if;
 -- A trigger may have waited after the earlier check. An expired grant aborts
 -- the whole command, including audit/history/outbox and its future receipt.
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_actor_id) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 select schedule_revision into v_revision from public.appointment_management_states where business_id=p_business_id and appointment_id=a.id;
 v_result:=jsonb_build_object('appointment_id',a.id,'status',a.status,'starts_at',a.starts_at,'ends_at',a.ends_at,
  'changed',v_changed,'schedule_revision',v_revision,
  'revision',private.appointment_semantic_revision(p_business_id,a.id),'idempotent_replay',false);
 insert into private.appointment_management_operations(business_id,operation_id,appointment_id,actor_id,origin,action,request_fingerprint,result)
 values(p_business_id,p_operation_id,a.id,p_actor_id,'staff',p_action,v_fingerprint,v_result);
 return v_result;
end $$;

commit;
