-- E1: staff agenda writes, their audit and operation receipt share a transaction.
-- No consumer, email or staff UI is activated by installing this migration.
begin;

-- The same authority supports an authenticated RPC (auth.uid) and a backend
-- command whose actor was verified by the route. This helper has no API grant.
create function private.business_operation_actor(p_business_id uuid,p_allowed text[],p_actor uuid) returns text
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_role text; v_grant public.account_assistance_grants; v_now timestamptz;
begin
 if p_actor is null then return null; end if;
 select bu.role into v_role from public.business_users bu
 where bu.business_id=p_business_id and bu.user_id=p_actor
  and coalesce(bu.status,'active')='active' and bu.accepted_at is not null and bu.disabled_at is null for share;
 select grants.* into v_grant
 from public.account_assistance_support_users support
 join public.account_assistance_grants grants on grants.support_user_id=support.user_id
 where support.user_id=p_actor and support.enabled and grants.business_id=p_business_id
  and grants.status='active' and grants.revoked_at is null for share of support,grants;
 if v_role is null and v_grant.id is null then return null; end if;
 perform 1 from public.business_subscriptions bs where bs.business_id=p_business_id for share;
 v_now:=clock_timestamp();
 if v_grant.id is not null and v_grant.starts_at<=v_now and v_grant.expires_at>v_now
  and v_role is distinct from 'owner' then v_role:='admin'; end if;
 if (v_role=any(p_allowed)) is not true then return null; end if;
 if private.appointment_business_allows_operation_at(p_business_id,v_now) is not true then return null; end if;
 return v_role;
end $$;
create or replace function private.deposit_actor(p_business_id uuid,p_allowed text[]) returns text
language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select private.business_operation_actor(p_business_id,p_allowed,auth.uid())
$$;

-- A computed field: same SELECT snapshot as the displayed appointment and its
-- embeds. Read the actual row, not a caller-fabricated composite. The existing
-- set-based appointment visibility applies even to a direct SQL invocation.
-- An unnamed composite argument prevents PostgREST exposing it under /rpc.
create function public.appointment_management_revision(public.appointments) returns text
language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select private.appointment_semantic_revision(a.business_id,a.id)
 from public.appointments a
 where auth.uid() is not null and a.business_id=($1).business_id and a.id=($1).id
  and (a.business_id=any((select public.user_appointment_reader_business_ids())::uuid[])
   or (a.business_id,a.id) in (select scope.business_id,scope.appointment_id from public.user_allocated_appointment_ids() scope))
$$;

-- Backend-only because the shared availability calculator is an explicit part
-- of the command boundary. A signed-in client cannot skip that preflight.
-- replay_only returns an existing authorized receipt or NULL, never a new write;
-- it shares validation/fingerprinting with execution instead of a second rule.
create function public.apply_staff_appointment_management(p_business_id uuid,p_actor_id uuid,p_appointment_id uuid,
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

revoke all on function private.business_operation_actor(uuid,text[],uuid),private.deposit_actor(uuid,text[]),
 public.appointment_management_revision(public.appointments),
 public.apply_staff_appointment_management(uuid,uuid,uuid,uuid,text,text,timestamptz,boolean,bigint,text,boolean)
 from public,anon,authenticated,service_role;
grant execute on function public.appointment_management_revision(public.appointments) to authenticated;
grant execute on function public.apply_staff_appointment_management(uuid,uuid,uuid,uuid,text,text,timestamptz,boolean,bigint,text,boolean) to service_role;
notify pgrst,'reload schema';
commit;
