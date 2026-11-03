-- E1: patient management and transactional email events. No sender/consumer is
-- enabled by this migration. Backend availability remains the shared TS engine.
begin;

create table private.appointment_management_runtime (
 singleton boolean primary key default true check(singleton),
 reschedule_enabled boolean not null default false,
 email_producer_enabled boolean not null default false
);
insert into private.appointment_management_runtime(singleton) values(true);
revoke all on private.appointment_management_runtime from public,anon,authenticated,service_role;

-- Only a change of the global financial switch conflicts with a management
-- command. The expiry worker updates heartbeat columns on the same row and
-- must remain free to SKIP LOCKED appointments. A row SHARE lock here would
-- stop that worker before it reaches its candidate query (race reproduced).
create function private.lock_deposit_automation_configuration() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 perform pg_advisory_xact_lock(hashtextextended('cita-suite:deposit-automation-configuration',0));
 return new;
end $$;
create trigger deposit_automation_configuration_lock before update of enabled on private.deposit_automation
 for each row when (new.enabled is distinct from old.enabled) execute function private.lock_deposit_automation_configuration();

alter table public.appointment_management_states add column schedule_revision bigint not null default 1 check(schedule_revision>0);
create table private.appointment_email_events (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null,
 appointment_id uuid not null,
 schedule_revision bigint not null check(schedule_revision>0),
 management_generation bigint not null check(management_generation>0),
 purpose text not null check(purpose in ('booking_receipt','reschedule_receipt','cancellation_receipt')),
 occurred_at timestamptz not null default clock_timestamp(),
 unique(business_id,appointment_id,schedule_revision,management_generation,purpose),
 foreign key(business_id,appointment_id) references public.appointments(business_id,id) on delete cascade
);
create index appointment_email_events_pending on private.appointment_email_events(occurred_at,id);
revoke all on private.appointment_email_events from public,anon,authenticated,service_role;

-- Payments/status telemetry do not rearm reminder coverage. This runs AFTER all
-- existing appointment triggers, so management state and allocations exist.
-- Only minimal event identity is captured: booking context is inserted later
-- by the outer booking RPC and must be loaded from committed state at dispatch.
create function private.record_appointment_email_event() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_revision bigint; v_generation bigint; v_purpose text; v_enabled boolean;
begin
 if tg_op='UPDATE' and (new.starts_at,new.ends_at,new.service_id,new.professional_id)
  is distinct from (old.starts_at,old.ends_at,old.service_id,old.professional_id) then
  update public.appointment_management_states set schedule_revision=schedule_revision+1
  where business_id=new.business_id and appointment_id=new.id returning schedule_revision into v_revision;
 end if;
 if v_revision is null then
  select schedule_revision into v_revision from public.appointment_management_states where business_id=new.business_id and appointment_id=new.id;
 end if;
 select email_producer_enabled into v_enabled from private.appointment_management_runtime where singleton for share;
 if v_enabled is not true then return null; end if;
 if tg_op='INSERT' and new.status in ('reserved','confirmed','reschedule_requested') then v_purpose:='booking_receipt';
 elsif tg_op='UPDATE' and new.status='cancelled' and old.status in ('reserved','confirmed','reschedule_requested') then v_purpose:='cancellation_receipt';
 elsif tg_op='UPDATE' and new.status in ('reserved','confirmed','reschedule_requested') and old.status in ('reserved','confirmed','reschedule_requested')
  and (new.starts_at,new.ends_at) is distinct from (old.starts_at,old.ends_at) then v_purpose:='reschedule_receipt';
 end if;
 if v_purpose is not null then
  select generation into v_generation from public.appointment_management_states where business_id=new.business_id and appointment_id=new.id;
  insert into private.appointment_email_events(business_id,appointment_id,schedule_revision,management_generation,purpose)
  values(new.business_id,new.id,v_revision,v_generation,v_purpose);
 end if;
 return null;
end $$;
create trigger zzzz_appointment_email_event after insert or update on public.appointments
 for each row execute function private.record_appointment_email_event();

-- Preserve the existing catalog/window configuration contract: dated exceptions
-- do NOT invalidate it. Mutations use the business's broader booking revision,
-- which already covers dated exceptions and their restricted service mappings.
-- Expose that version from the SAME catalog snapshot; never look it up after
-- calculating a slot. Integrations retain their own existing revision, checked
-- separately by the command without altering public booking revision semantics.
create or replace function public.get_availability_catalog(p_business_id uuid,p_public boolean)
returns jsonb language plpgsql stable security definer set search_path=pg_catalog,pg_temp as $$
declare business public.businesses%rowtype; revision bigint; result jsonb;
begin
  business:=private.require_availability_business(p_business_id,p_public);
  select v.revision into revision from private.availability_configuration_versions v where v.business_id=p_business_id;
  if revision is null then raise exception 'AVAILABILITY_CONFIGURATION_MISSING'; end if;
  result:=jsonb_build_object(
    'schema_version',2,'business_id',business.id,'scope',case when p_public then 'public' else 'internal' end,
    'configuration_revision',revision,'availability_revision',business.booking_availability_revision,'generated_at',statement_timestamp(),
    'business',jsonb_build_object('timezone',business.timezone,'max_booking_days_ahead',business.max_booking_days_ahead,
      'min_booking_notice_minutes',business.min_booking_notice_minutes,'is_active',business.is_active,'public_booking_enabled',business.public_booking_enabled),
    'services',coalesce((select jsonb_agg(to_jsonb(row) order by row.sort_order,row.name,row.id) from (
      select s.id,s.business_id,s.name,s.description,s.duration_minutes,s.buffer_before_minutes,s.buffer_after_minutes,
        s.price_label,s.is_public,s.is_active,s.sort_order from public.services s
      where s.business_id=p_business_id and s.is_active and (not p_public or s.is_public)) row),'[]'::jsonb),
    'professionals',coalesce((select jsonb_agg(to_jsonb(row) order by row.sort_order,row.name,row.id) from (
      select p.id,p.name,p.specialty,p.avatar_url,p.is_public,p.is_active,p.sort_order from public.professionals p
      where p.business_id=p_business_id and p.is_active and (not p_public or (p.is_public and length(trim(p.name))>0))) row),'[]'::jsonb),
    'assignments',coalesce((select jsonb_agg(to_jsonb(row) order by row.service_id,row.professional_id) from (
      select a.service_id,a.professional_id from public.professional_services a
      join public.services s on s.business_id=a.business_id and s.id=a.service_id
      join public.professionals p on p.business_id=a.business_id and p.id=a.professional_id
      where a.business_id=p_business_id and s.is_active and p.is_active
        and (not p_public or (s.is_public and p.is_public and length(trim(p.name))>0))) row),'[]'::jsonb),
    'rules',coalesce((select jsonb_agg(to_jsonb(row) order by row.professional_id,row.weekday,row.start_time,row.id) from (
      select r.id,r.professional_id,r.weekday,r.start_time,r.end_time,r.slot_interval_minutes,r.break_minutes,r.is_active,r.service_scope,
        array(select rs.service_id from public.availability_rule_services rs where rs.business_id=r.business_id and rs.rule_id=r.id order by rs.service_id) as allowed_service_ids
      from public.availability_rules r join public.professionals p on p.business_id=r.business_id and p.id=r.professional_id
      where r.business_id=p_business_id and r.is_active and p.is_active
        and (not p_public or (p.is_public and length(trim(p.name))>0))) row),'[]'::jsonb)
  );
  if octet_length(result::text)>5000000 then raise exception 'AVAILABILITY_RESPONSE_LIMIT'; end if;
  return result;
end $$;

-- Target-independent readiness shared by the initial patient view and command.
-- It does not calculate slots, accept an excluded appointment or mutate money.
-- Slot notice/horizon, the catalog version and a locked integration revision
-- remain target-specific command preconditions.
create function private.appointment_reschedule_scope(p_business_id uuid,p_appointment_id uuid,p_now timestamptz)
returns jsonb language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 with scope as (
  select a.id,a.service_id,s.duration_minutes,team.ids,coalesce(c.modality,'in_person') as modality,
   c.integration_id,i.revision as integration_revision,coalesce(i.modality_windows,'[]'::jsonb) as modality_windows,
   case
    when a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=p_now then 'appointment_closed'
    when runtime.reschedule_enabled is not true then 'operations_paused'
    when b.is_active is not true or b.public_booking_enabled is not true or public.business_allows_operation(b.id) is not true then 'booking_unavailable'
    when s.id is null or s.is_active is not true or s.is_public is not true then 'service_unavailable'
    when coalesce(cardinality(team.ids),0) not between 1 and 16 or team.available is not true then 'professional_unavailable'
    when patient.blocked or patient.archived_at is not null then 'patient_unavailable'
    when c.appointment_id is not null and (i.id is null or i.is_active is not true or not (c.modality=any(i.allowed_modalities))
     or (cardinality(i.allowed_service_ids)>0 and not (a.service_id=any(i.allowed_service_ids)))
     or (cardinality(i.allowed_professional_ids)>0 and not (team.ids<@i.allowed_professional_ids))) then 'modality_unavailable'
   end as reason
  from public.appointments a join public.businesses b on b.id=a.business_id
  join public.patients patient on (patient.business_id,patient.id)=(a.business_id,a.patient_id)
  left join public.services s on (s.business_id,s.id)=(a.business_id,a.service_id)
  left join public.appointment_booking_contexts c on (c.business_id,c.appointment_id)=(a.business_id,a.id)
  left join public.booking_integrations i on (i.business_id,i.id)=(c.business_id,c.integration_id)
  cross join private.appointment_management_runtime runtime
  cross join lateral (
   select array_agg(ap.professional_id order by ap.professional_id) as ids,
    bool_and(p.id is not null and p.is_active and p.is_public and nullif(btrim(p.name),'') is not null
     and exists(select 1 from public.professional_services ps where (ps.business_id,ps.service_id,ps.professional_id)=(a.business_id,a.service_id,ap.professional_id))) as available
   from public.appointment_professionals ap left join public.professionals p on (p.business_id,p.id)=(ap.business_id,ap.professional_id)
   where ap.business_id=a.business_id and ap.appointment_id=a.id
  ) team
  where a.business_id=p_business_id and a.id=p_appointment_id and p_now is not null and isfinite(p_now)
 )
 select jsonb_build_object('can_select',reason is null,'reason',reason,'service_id',service_id,
  'duration_minutes',duration_minutes,'professional_ids',coalesce(to_jsonb(ids),'[]'::jsonb),'modality',modality,
  'integration_id',integration_id,'integration_revision',integration_revision,'modality_windows',modality_windows) from scope
$$;

create function private.patient_management_request_fingerprint(p_action text,p_appointment_id uuid,p_patient_id uuid,p_generation bigint,
 p_expected_revision text,p_starts_at timestamptz,p_availability_revision bigint,p_financial_terms jsonb,p_integration_revision bigint)
returns text language sql immutable set search_path=pg_catalog,pg_temp as $$
 select encode(extensions.digest(jsonb_build_object('action',p_action,'appointment_id',p_appointment_id,'patient_id',p_patient_id,
  'generation',p_generation,'expected_revision',p_expected_revision,'starts_at',extract(epoch from p_starts_at),
  'availability_revision',p_availability_revision,'integration_revision',p_integration_revision,'financial_terms',p_financial_terms)::text,'sha256'),'hex')
$$;

create function public.apply_patient_appointment_management(p_token text,p_legacy boolean,p_operation_id uuid,
 p_expected_revision text,p_action text,p_starts_at timestamptz default null,p_availability_revision bigint default null,
 p_financial_terms jsonb default null,p_integration_revision bigint default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare access jsonb; locked_access jsonb; a public.appointments; before_a public.appointments;
 b public.businesses; s public.services; context public.appointment_booking_contexts; integration public.booking_integrations;
 d public.appointment_deposits; r public.appointment_deposit_requirements; basis public.appointment_deposit_requirements;
 prior private.appointment_management_operations; v_business uuid; v_appointment uuid; v_now timestamptz;
 v_fingerprint text; v_result jsonb; v_terms jsonb; v_scope jsonb; v_requirement uuid; v_revision bigint; v_teams uuid[]; v_locked_teams uuid[];
 v_professional uuid; v_ends_at timestamptz; v_status text; v_changed boolean:=true; v_kind text;
 v_projection_revision bigint; v_snapshot jsonb; v_has_projection boolean; v_has_current boolean; v_previous_disposition text;
begin
 if p_legacy is null or p_operation_id is null or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false)
  or not coalesce(p_action in ('cancel','reschedule','confirm'),false) then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 if p_action<>'reschedule' and (p_starts_at is not null or p_availability_revision is not null or p_financial_terms is not null or p_integration_revision is not null) then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 if p_action='reschedule' and (p_starts_at is null or not isfinite(p_starts_at)) then raise exception 'APPOINTMENT_RESCHEDULE_TIME_INVALID'; end if;
 if p_financial_terms is not null and (jsonb_typeof(p_financial_terms)<>'object' or octet_length(p_financial_terms::text)>8192) then
  raise exception 'APPOINTMENT_FINANCIAL_TERMS_CHANGED'; end if;
 access:=public.resolve_appointment_management_access(p_token,p_legacy);
 v_business:=(access->>'business_id')::uuid; v_appointment:=(access->>'appointment_id')::uuid;
 perform pg_advisory_xact_lock(hashtextextended('appointment-management-operation:'||v_business::text||':'||p_operation_id::text,0));
 if p_action='reschedule' then
  -- Do not lock service/professional/integration rows after the business: their
  -- writers take the child first and then advance this business/config version.
  select * into b from public.businesses where id=v_business for share;
  perform 1 from public.business_subscriptions where business_id=v_business for share;
  perform pg_advisory_xact_lock_shared(hashtextextended('cita-suite:deposit-automation-configuration',0));
  perform 1 from public.deposit_policies where business_id=v_business for share;
  perform 1 from public.appointment_email_policies where business_id=v_business for share;
  perform 1 from private.appointment_management_runtime where singleton for share;
  select array_agg(professional_id order by professional_id) into v_teams from public.appointment_professionals
   where business_id=v_business and appointment_id=v_appointment;
  -- Match the deterministic locks of joint booking BEFORE taking the parent.
  for v_professional in select unnest(v_teams) loop
   perform pg_advisory_xact_lock(hashtextextended(v_business::text||':'||v_professional::text,0));
  end loop;
 end if;
 select * into a from public.appointments where business_id=v_business and id=v_appointment for no key update;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 -- Expiry/generation are checked again after waiting, including for a replay.
 locked_access:=public.resolve_appointment_management_access(p_token,p_legacy);
 if (locked_access->>'business_id',locked_access->>'appointment_id') is distinct from (v_business::text,v_appointment::text) then
  raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 v_fingerprint:=private.patient_management_request_fingerprint(p_action,a.id,a.patient_id,(locked_access->>'generation')::bigint,
  p_expected_revision,p_starts_at,p_availability_revision,p_financial_terms,p_integration_revision);
 select * into prior from private.appointment_management_operations where business_id=v_business and operation_id=p_operation_id;
 if found then
  if prior.appointment_id is distinct from a.id or prior.request_fingerprint is distinct from v_fingerprint
   or prior.origin<>'patient' or prior.action<>p_action then raise exception 'APPOINTMENT_OPERATION_CONFLICT'; end if;
  return prior.result||jsonb_build_object('idempotent_replay',true);
 end if;
 if private.appointment_semantic_revision(v_business,a.id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_now:=clock_timestamp(); before_a:=a;

 if p_action='cancel' then
  -- Narrow exception: a valid personal link may cancel its own future active
  -- appointment even if booking/commercial access was disabled. No other access.
  if a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=v_now then raise exception 'APPOINTMENT_CANNOT_CANCEL'; end if;
  update public.appointments set status='cancelled',cancelled_at=v_now,cancelled_by_user_id=null,
   cancelled_reason='Cancelado por el paciente',calendar_sequence=a.calendar_sequence+1,
   calendar_update_required_at=case when a.calendar_action_count>0 then v_now end,
   updated_by_user_id=null,updated_at=v_now where business_id=v_business and id=a.id returning * into a;
 elsif p_action='confirm' then
  if a.starts_at<=v_now or a.status<>'reserved' then raise exception 'APPOINTMENT_CANNOT_CONFIRM'; end if;
  if exists(select 1 from public.appointment_deposits where business_id=v_business and appointment_id=a.id and status='pending') then
   raise exception 'APPOINTMENT_DEPOSIT_PENDING'; end if;
  if not exists(select 1 from public.businesses where id=v_business and is_active) or not public.business_allows_operation(v_business) then
   raise exception 'APPOINTMENT_CANNOT_CONFIRM'; end if;
  update public.appointments set status='confirmed',confirmed_at=v_now,updated_by_user_id=null,updated_at=v_now
   where business_id=v_business and id=a.id returning * into a;
 else
  if a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=v_now then raise exception 'APPOINTMENT_CANNOT_RESCHEDULE'; end if;
  -- True no-op: no financial consequences or schedule reset. Authorization and
  -- observed semantic revision still apply, including for a technical pause.
  if p_starts_at=a.starts_at then v_changed:=false;
  else
   if p_availability_revision is null or p_availability_revision is distinct from
    (select booking_availability_revision from public.businesses where id=v_business) then raise exception 'APPOINTMENT_AVAILABILITY_CHANGED'; end if;
   v_now:=clock_timestamp();
   if p_starts_at<v_now+make_interval(mins=>b.min_booking_notice_minutes) or p_starts_at<=v_now
    or (p_starts_at at time zone b.timezone)::date>((v_now+make_interval(mins=>b.max_booking_days_ahead*1440)) at time zone b.timezone)::date then
    raise exception 'APPOINTMENT_RESCHEDULE_TIME_INVALID'; end if;
   select * into s from public.services where business_id=v_business and id=a.service_id and is_active and is_public;
   if not found then raise exception 'APPOINTMENT_RESCHEDULE_UNAVAILABLE'; end if;
   select array_agg(professional_id order by professional_id) into v_locked_teams from public.appointment_professionals where business_id=v_business and appointment_id=a.id;
   if v_teams is distinct from v_locked_teams then
    raise exception 'APPOINTMENT_RESCHEDULE_UNAVAILABLE'; end if;
   select * into context from public.appointment_booking_contexts where business_id=v_business and appointment_id=a.id;
   if found then
    -- Normal saves hold business -> integration. A privileged direct edit may
    -- hold only the integration; NOWAIT fails safely instead of introducing an
    -- inverse wait against an older integration -> business booking path.
    begin
     select * into integration from public.booking_integrations where business_id=v_business and id=context.integration_id for share nowait;
    exception when lock_not_available then raise exception 'APPOINTMENT_AVAILABILITY_CHANGED'; end;
    if integration.id is null then
     raise exception 'APPOINTMENT_RESCHEDULE_UNAVAILABLE'; end if;
    if p_integration_revision is distinct from integration.revision then raise exception 'APPOINTMENT_AVAILABILITY_CHANGED'; end if;
   elsif p_integration_revision is not null then raise exception 'APPOINTMENT_AVAILABILITY_CHANGED';
   end if;
   v_scope:=private.appointment_reschedule_scope(v_business,a.id,v_now);
   if (v_scope->>'can_select')::boolean is not true then raise exception 'APPOINTMENT_RESCHEDULE_UNAVAILABLE'; end if;
   v_ends_at:=p_starts_at+make_interval(mins=>s.duration_minutes);
   v_terms:=private.appointment_reschedule_financial_terms(v_business,a.id,p_starts_at,v_now);
   if v_terms->>'unavailable_reason' is not null or v_terms->>'kind'='unavailable' then raise exception 'APPOINTMENT_RESCHEDULE_UNAVAILABLE'; end if;
   if v_terms is distinct from p_financial_terms then raise exception 'APPOINTMENT_FINANCIAL_TERMS_CHANGED'; end if;
   select * into d from public.appointment_deposits where business_id=v_business and appointment_id=a.id for update;
   v_has_projection:=found;
   select * into r from public.appointment_deposit_requirements where business_id=v_business and appointment_id=a.id and is_current for update;
   v_has_current:=found;
   select * into basis from public.appointment_deposit_requirements where business_id=v_business and appointment_id=a.id and patient_id=a.patient_id order by ordinal desc limit 1;
   if v_has_current then basis:=r; end if;
   v_kind:=v_terms->>'kind';
   if v_kind<>'reuse_pending' and v_has_current then
    v_previous_disposition:=v_terms->>'previous_payment_disposition';
    update public.appointment_deposit_requirements set is_current=false,
     allocation=case when v_previous_disposition='forfeit' then 'forfeited' else allocation end,updated_at=v_now where id=r.id;
    insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,amount,metadata)
    values(v_business,a.id,r.id,case when v_previous_disposition='forfeit' then 'payment_forfeited'
     when v_previous_disposition='credit' then 'payment_applied' else 'requirement_updated' end,
     case when v_previous_disposition in ('forfeit','credit') then r.amount else 0 end,
     jsonb_build_object('origin','patient','operation_id',p_operation_id,'reason','rescheduled','closed',true));
    if v_kind<>'new_requirement' then delete from public.appointment_deposits where business_id=v_business and appointment_id=a.id; end if;
   end if;
   v_status:=case when v_kind in ('reuse_pending','new_requirement') then 'reserved'
    when a.status='confirmed' then 'confirmed' else 'reserved' end;
   update public.appointments set starts_at=p_starts_at,ends_at=v_ends_at,status=v_status,
    confirmed_at=case when v_status='confirmed' then a.confirmed_at end,reschedule_requested_at=null,reminder_due_at=null,
    calendar_sequence=a.calendar_sequence+1,calendar_update_required_at=case when a.calendar_action_count>0 then v_now end,
    ignore_break=false,updated_by_user_id=null,updated_at=v_now where business_id=v_business and id=a.id returning * into a;
   if context.appointment_id is not null then
    -- Same modality and team; check every member's complete occupied interval.
    for v_professional in select unnest(v_teams) loop
     if exists(select 1 from jsonb_array_elements(integration.modality_windows) w where w->>'modality'=context.modality
       and (not (w ? 'professionalId') or (w->>'professionalId')::uuid=v_professional)) and not exists(
      select 1 from jsonb_array_elements(integration.modality_windows) w
      join public.appointment_professionals ap on ap.business_id=v_business and ap.appointment_id=a.id and ap.professional_id=v_professional
      where w->>'modality'=context.modality and (not (w ? 'professionalId') or (w->>'professionalId')::uuid=v_professional)
       and (w->>'weekday')::integer=extract(dow from (p_starts_at at time zone b.timezone))::integer
       and ap.blocking_starts_at>=(((p_starts_at at time zone b.timezone)::date+(w->>'startTime')::time) at time zone b.timezone)
       and ap.blocking_ends_at<=(((p_starts_at at time zone b.timezone)::date+(w->>'endTime')::time) at time zone b.timezone)
     ) then raise exception 'APPOINTMENT_RESCHEDULE_UNAVAILABLE'; end if;
    end loop;
   end if;
   if v_kind='new_requirement' then
    -- Across delete/recreate, revision must never return to 1: stale staff
    -- forms must not record/undo money against a different obligation cycle.
    select coalesce(max(projection_revision),0)+1 into v_projection_revision from public.appointment_deposit_requirements where business_id=v_business and appointment_id=a.id;
    v_snapshot:=basis.terms_snapshot||jsonb_build_object('request_from',v_terms->'request_from','due_at',v_terms->'due_at','auto_cancel',v_terms->'auto_cancel','waived_reason',null);
    insert into public.appointment_deposit_requirements(business_id,appointment_id,patient_id,status,amount,base_amount,allocation,terms_snapshot,projection_revision)
    values(v_business,a.id,a.patient_id,'pending',(v_terms->>'amount')::bigint,(v_terms->>'base_amount')::bigint,'none',v_snapshot,v_projection_revision) returning id into v_requirement;
    insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,metadata)
    values(v_business,a.id,v_requirement,'requirement_created',jsonb_build_object('origin','patient','operation_id',p_operation_id));
    insert into public.appointment_deposits(business_id,appointment_id,status,amount,currency,percentage,reference_amount,request_days,deadline_hours,
     min_payment_hours,policy_revision,request_from,due_at,auto_cancel,revision)
    values(v_business,a.id,'pending',(v_terms->>'amount')::bigint,'ARS',(basis.terms_snapshot->>'percentage')::numeric,
     (basis.terms_snapshot->>'reference_amount')::bigint,(v_terms->>'request_days')::integer,(v_terms->>'deadline_hours')::integer,
     (v_terms->>'min_payment_hours')::integer,(basis.terms_snapshot->>'policy_revision')::bigint,(v_terms->>'request_from')::timestamptz,
     (v_terms->>'due_at')::timestamptz,(v_terms->>'auto_cancel')::boolean,v_projection_revision)
    on conflict(appointment_id) do update set status='pending',amount=excluded.amount,percentage=excluded.percentage,reference_amount=excluded.reference_amount,
     request_days=excluded.request_days,deadline_hours=excluded.deadline_hours,min_payment_hours=excluded.min_payment_hours,policy_revision=excluded.policy_revision,
     request_from=excluded.request_from,due_at=excluded.due_at,auto_cancel=excluded.auto_cancel,revision=excluded.revision,
     waived_reason=null,note=null,recorded_by=null,recorded_at=null,reminder_opened_at=null,reminder_opened_by=null,expired_at=null,updated_at=v_now;
   elsif v_kind='reuse_pending' then
    -- The legacy trigger recalculates using transaction-start time. Correct only
    -- a differing result with the post-lock clock already disclosed/revalidated.
    update public.appointment_deposits set request_from=(v_terms->>'request_from')::timestamptz,due_at=(v_terms->>'due_at')::timestamptz,
     auto_cancel=(v_terms->>'auto_cancel')::boolean,revision=revision+1,updated_at=v_now
    where business_id=v_business and appointment_id=a.id and (request_from,due_at,auto_cancel) is distinct from
     ((v_terms->>'request_from')::timestamptz,(v_terms->>'due_at')::timestamptz,(v_terms->>'auto_cancel')::boolean);
   end if;
  end if;
 end if;
 if v_changed then
  insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
  values(v_business,null,case p_action when 'cancel' then 'appointment.cancelled' when 'confirm' then 'appointment.confirmed' else 'appointment.rescheduled' end,
   'appointment',a.id,jsonb_build_object('origin','patient','operation_id',p_operation_id,'from_status',before_a.status,'to_status',a.status,
    'from_starts_at',before_a.starts_at,'to_starts_at',a.starts_at,'financial_terms',v_terms));
 end if;
 select schedule_revision into v_revision from public.appointment_management_states where business_id=v_business and appointment_id=a.id;
 v_result:=jsonb_build_object('appointment_id',a.id,'status',a.status,'starts_at',a.starts_at,'ends_at',a.ends_at,
  'changed',v_changed,'schedule_revision',v_revision,'revision',private.appointment_semantic_revision(v_business,a.id),'idempotent_replay',false);
 insert into private.appointment_management_operations(business_id,operation_id,appointment_id,origin,action,request_fingerprint,result)
 values(v_business,p_operation_id,a.id,'patient',p_action,v_fingerprint,v_result);
 return v_result;
end $$;

revoke all on function private.record_appointment_email_event(),private.lock_deposit_automation_configuration(),private.appointment_reschedule_scope(uuid,uuid,timestamptz),
 private.patient_management_request_fingerprint(text,uuid,uuid,bigint,text,timestamptz,bigint,jsonb,bigint),
 public.apply_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint) from public,anon,authenticated,service_role;
grant execute on function public.apply_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint) to service_role;
notify pgrst,'reload schema';
commit;
