-- Contact authority is independent from schedule, calendar and economic history.
-- No external sender or producer is enabled by this migration.
begin;

alter table public.patients add column email_contact_revision bigint not null default 1
 check(email_contact_revision>0);
alter table public.appointment_management_states add column legacy_contact_revision bigint;
update public.appointment_management_states m set legacy_contact_revision=p.email_contact_revision
 from public.appointments a join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 where (m.business_id,m.appointment_id)=(a.business_id,a.id);
alter table public.appointment_management_states alter column legacy_contact_revision set not null;
alter table public.appointment_management_states add check(legacy_contact_revision>0);

alter table private.appointment_management_capabilities add column patient_contact_revision bigint;
update private.appointment_management_capabilities c set patient_contact_revision=p.email_contact_revision
 from public.appointments a join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 where (c.business_id,c.appointment_id)=(a.business_id,a.id);
alter table private.appointment_management_capabilities alter column patient_contact_revision set not null;
alter table private.appointment_management_capabilities add check(patient_contact_revision>0);

-- A durable patient-scoped event avoids locking all its appointments from a
-- patient edit (the inverse of identity repair). The future mail worker reads
-- current useful appointments after this transaction, without reconstructing
-- old recipients or sending a historical bulk message on installation.
create table private.patient_email_contact_events (
 business_id uuid not null,
 patient_id uuid not null,
 contact_revision bigint not null check(contact_revision>0),
 created_at timestamptz not null default clock_timestamp(),
 processed_at timestamptz,
 primary key(business_id,patient_id,contact_revision),
 foreign key(business_id,patient_id) references public.patients(business_id,id) on delete cascade
);
create index patient_email_contact_events_pending on private.patient_email_contact_events(created_at,patient_id)
 where processed_at is null;
revoke all on private.patient_email_contact_events from public,anon,authenticated,service_role;

create function private.advance_patient_email_contact_revision() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 -- A caller cannot preserve/reuse a previous authority revision by assigning it.
 if tg_op='INSERT' then new.email_contact_revision:=1;
 else
  new.email_contact_revision:=old.email_contact_revision;
  -- Preserve the local part's case and aliases. Do not infer mailbox
  -- equivalence from provider conventions; only discard outer spaces here.
  if nullif(btrim(new.email),'') is distinct from nullif(btrim(old.email),'') then
   new.email_contact_revision:=old.email_contact_revision+1;
  end if;
 end if;
 return new;
end $$;
create trigger a_advance_patient_email_contact_revision before insert or update on public.patients
 for each row execute function private.advance_patient_email_contact_revision();

create function private.record_patient_email_contact_event() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if new.email_contact_revision is distinct from old.email_contact_revision then
  insert into private.patient_email_contact_events(business_id,patient_id,contact_revision)
  values(new.business_id,new.id,new.email_contact_revision);
 end if;
 return null;
end $$;
create trigger record_patient_email_contact_event after update on public.patients
 for each row execute function private.record_patient_email_contact_event();

create function private.bind_legacy_appointment_contact() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 select p.email_contact_revision into new.legacy_contact_revision
 from public.appointments a join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 where (a.business_id,a.id)=(new.business_id,new.appointment_id);
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 return new;
end $$;
create trigger bind_legacy_appointment_contact before insert on public.appointment_management_states
 for each row execute function private.bind_legacy_appointment_contact();

create or replace function public.issue_appointment_management_capability(p_business_id uuid,p_appointment_id uuid,p_expected_generation bigint)
returns text language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; m public.appointment_management_states; v_token text; v_now timestamptz;
begin
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=p_appointment_id;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 if p_expected_generation is distinct from m.generation then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_now:=clock_timestamp();
 v_token:=encode(extensions.gen_random_bytes(32),'hex');
 -- One SELECT snapshot binds the current patient contact. A correction racing
 -- after it makes the credential immediately invalid; it cannot revive later.
 insert into private.appointment_management_capabilities(token_hash,business_id,appointment_id,generation,patient_contact_revision,created_at,expires_at)
 select encode(extensions.digest(v_token,'sha256'),'hex'),a.business_id,a.id,m.generation,p.email_contact_revision,v_now,
  least(v_now+interval '365 days',greatest(v_now+interval '1 day',a.starts_at+interval '30 days'))
 from public.patients p where (p.business_id,p.id)=(a.business_id,a.patient_id);
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 return v_token;
end $$;

create or replace function private.appointment_management_access_at(p_token text,p_legacy boolean,p_now timestamptz)
returns jsonb language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 with authorized as (
  select a.business_id,a.id as appointment_id,null::bigint as generation,null::bigint as contact_revision from public.appointments a
  where p_legacy and a.confirmation_token=p_token
  union all
  select c.business_id,c.appointment_id,c.generation,c.patient_contact_revision from private.appointment_management_capabilities c
  where not p_legacy and c.token_hash=encode(extensions.digest(p_token,'sha256'),'hex') and c.expires_at>p_now
 )
 select jsonb_build_object('business_id',a.business_id,'appointment_id',a.id,'generation',m.generation,
  'revision',private.appointment_semantic_revision(a.business_id,a.id),'access_kind',case when p_legacy then 'legacy' else 'capability' end)
 from authorized access join public.appointments a on (a.business_id,a.id)=(access.business_id,access.appointment_id)
 join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
 join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 where p_token ~ '^[0-9a-f]{64}$' and p_now is not null and isfinite(p_now)
  and ((p_legacy and m.legacy_management_allowed and m.legacy_contact_revision=p.email_contact_revision)
   or (not p_legacy and access.generation=m.generation and access.contact_revision=p.email_contact_revision))
$$;

create or replace function public.apply_patient_appointment_management(p_token text,p_legacy boolean,p_operation_id uuid,
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
  if not exists(select 1 from public.businesses where id=v_business and is_active) or not private.appointment_business_allows_operation_at(v_business,v_now) then
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
    -- The shared trigger owns dates and the actual minimum payment window.
    -- Apply only an additional relaxation disclosed in this operation; never
    -- re-enable cancellation that the later trigger has already made unsafe.
    update public.appointment_deposits set auto_cancel=false,revision=revision+1,updated_at=v_now
    where business_id=v_business and appointment_id=a.id and auto_cancel and (v_terms->>'auto_cancel')::boolean is not true;
   end if;
  end if;
 end if;
 if v_changed then
  insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
  values(v_business,null,case p_action when 'cancel' then 'appointment.cancelled' when 'confirm' then 'appointment.confirmed' else 'appointment.rescheduled' end,
   'appointment',a.id,jsonb_build_object('origin','patient','operation_id',p_operation_id,'from_status',before_a.status,'to_status',a.status,
    'from_starts_at',before_a.starts_at,'to_starts_at',a.starts_at,'financial_terms',v_terms));
 end if;
 -- Effective appointment updates already lock the patient's activity row via
 -- the existing domain trigger. Revalidate AFTER that wait and every other
 -- effect: a contact correction/expiry that won earlier aborts this transaction,
 -- including money, audit, events and receipt. No inverse parent-lock trigger
 -- on the patient, and no shared-lock-to-write upgrade between its appointments.
 locked_access:=public.resolve_appointment_management_access(p_token,p_legacy);
 if (locked_access->>'business_id',locked_access->>'appointment_id') is distinct from (v_business::text,v_appointment::text) then
  raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 select schedule_revision into v_revision from public.appointment_management_states where business_id=v_business and appointment_id=a.id;
 v_result:=jsonb_build_object('appointment_id',a.id,'status',a.status,'starts_at',a.starts_at,'ends_at',a.ends_at,
  'changed',v_changed,'schedule_revision',v_revision,'revision',private.appointment_semantic_revision(v_business,a.id),'idempotent_replay',false);
 insert into private.appointment_management_operations(business_id,operation_id,appointment_id,origin,action,request_fingerprint,result)
 values(v_business,p_operation_id,a.id,'patient',p_action,v_fingerprint,v_result);
 return v_result;
end $$;

-- Replacements preserve their existing backend-only grants. New trigger helpers
-- have no Data API entry point or grant, including for service_role.
revoke all on function private.advance_patient_email_contact_revision(),private.record_patient_email_contact_event(),
 private.bind_legacy_appointment_contact() from public,anon,authenticated,service_role;
notify pgrst,'reload schema';
commit;
