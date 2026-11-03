-- E1, plan 12.18/12.20-22: additive foundations only. No producer, email or new
-- financial rule is activated here. The current deposit remains one-to-one.
begin;

create table public.appointment_email_policies (
 business_id uuid primary key references public.businesses(id) on delete cascade,
 email_enabled boolean not null default true,
 require_email boolean not null default true,
 show_cancel boolean not null default true,
 show_reschedule boolean not null default true,
 require_deposit_on_reschedule boolean not null default true,
 previous_deposit_disposition text not null default 'forfeit' check (previous_deposit_disposition in ('credit','forfeit')),
 sender_verified boolean not null default false,
 revision bigint not null default 1 check (revision>0),
 updated_at timestamptz not null default now(),
 updated_by uuid
);

-- Financial defaults are preferences for informed bookings, never retroactive
-- terms. A legacy appointment has no new penalty, regardless of these defaults.
create table public.appointment_management_states (
 business_id uuid not null,
 appointment_id uuid primary key,
 appointment_revision bigint not null default 1 check (appointment_revision>0),
 generation bigint not null default 1 check (generation>0),
 legacy_management_allowed boolean not null default true,
 terms_acknowledged boolean not null default false,
 require_deposit_on_reschedule boolean not null default false,
 previous_deposit_disposition text not null default 'credit' check (previous_deposit_disposition in ('credit','forfeit')),
 accepted_at timestamptz,
 accepted_policy_revision bigint,
 terms_snapshot jsonb not null default '{}'::jsonb check (jsonb_typeof(terms_snapshot)='object'),
 foreign key (business_id,appointment_id) references public.appointments(business_id,id) on delete cascade,
 unique (business_id,appointment_id),
 check (terms_acknowledged or (not require_deposit_on_reschedule and previous_deposit_disposition='credit')),
 check (not terms_acknowledged or (accepted_at is not null and accepted_policy_revision is not null))
);

create table public.appointment_deposit_requirements (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null,
 appointment_id uuid not null,
 patient_id uuid not null,
 ordinal bigint generated always as identity,
 is_current boolean not null default true,
 status text not null check (status in ('pending','paid','waived','expired')),
 amount bigint not null check (amount between 1 and 1000000000000),
 base_amount bigint not null check (base_amount between 1 and 1000000000000 and base_amount>=amount),
 currency text not null default 'ARS' check (currency='ARS'),
 allocation text not null check (allocation in ('none','applied','forfeited','unresolved')),
 terms_snapshot jsonb not null check (jsonb_typeof(terms_snapshot)='object'),
 projection_revision bigint not null check (projection_revision>0),
 recorded_by uuid,
 recorded_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 foreign key (business_id,appointment_id) references public.appointments(business_id,id) on delete cascade,
 foreign key (business_id,patient_id) references public.patients(business_id,id),
 unique (business_id,appointment_id,id),
 check ((status='paid' and allocation in ('applied','forfeited','unresolved')) or (status<>'paid' and allocation='none'))
);
create unique index appointment_deposit_requirements_current on public.appointment_deposit_requirements(business_id,appointment_id) where is_current;
create index appointment_deposit_requirements_history on public.appointment_deposit_requirements(business_id,appointment_id,ordinal);
create index appointment_deposit_requirements_patient on public.appointment_deposit_requirements(business_id,patient_id);

-- Corrections append an event. 'existing_state_observed' explicitly does not
-- pretend that the migration witnessed a payment or knows its original time.
create table public.appointment_deposit_events (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null,
 appointment_id uuid not null,
 requirement_id uuid not null,
 ordinal bigint generated always as identity,
 event_type text not null check (event_type in ('existing_state_observed','requirement_created','payment_recorded',
  'recording_reversed','requirement_waived','requirement_expired','requirement_reopened','requirement_updated',
  'payment_unresolved','payment_applied','payment_forfeited','late_payment_recorded')),
 amount bigint not null default 0 check (amount between 0 and 1000000000000),
 actor_id uuid,
 metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata)='object'),
 created_at timestamptz not null default now(),
 foreign key (business_id,appointment_id,requirement_id)
  references public.appointment_deposit_requirements(business_id,appointment_id,id) on delete cascade
);
create index appointment_deposit_events_history on public.appointment_deposit_events(business_id,appointment_id,ordinal);

alter table public.appointment_email_policies enable row level security;
alter table public.appointment_management_states enable row level security;
alter table public.appointment_deposit_requirements enable row level security;
alter table public.appointment_deposit_events enable row level security;
revoke all on public.appointment_email_policies,public.appointment_management_states,
 public.appointment_deposit_requirements,public.appointment_deposit_events from public,anon,authenticated,service_role;
revoke all on sequence public.appointment_deposit_requirements_ordinal_seq,public.appointment_deposit_events_ordinal_seq
 from public,anon,authenticated,service_role;
grant select on public.appointment_email_policies,public.appointment_management_states,
 public.appointment_deposit_requirements,public.appointment_deposit_events to authenticated,service_role;
create policy appointment_email_policies_member_select on public.appointment_email_policies for select to authenticated
 using (public.user_business_role(business_id) is not null);
-- The appointments' set-based rule, evaluated once per statement, also governs
-- money/history. No correlated per-row appointment/RLS lookup.
create policy appointment_management_states_appointment_select on public.appointment_management_states for select to authenticated
 using (business_id=any((select public.user_appointment_reader_business_ids())::uuid[])
  or (business_id,appointment_id) in (select a.business_id,a.appointment_id from public.user_allocated_appointment_ids() a));
create policy appointment_deposit_requirements_appointment_select on public.appointment_deposit_requirements for select to authenticated
 using (business_id=any((select public.user_appointment_reader_business_ids())::uuid[])
  or (business_id,appointment_id) in (select a.business_id,a.appointment_id from public.user_allocated_appointment_ids() a));
create policy appointment_deposit_events_appointment_select on public.appointment_deposit_events for select to authenticated
 using (business_id=any((select public.user_appointment_reader_business_ids())::uuid[])
  or (business_id,appointment_id) in (select a.business_id,a.appointment_id from public.user_allocated_appointment_ids() a));

insert into public.appointment_email_policies(business_id) select id from public.businesses;
insert into public.appointment_management_states(business_id,appointment_id) select business_id,id from public.appointments;

-- The initial history is a snapshot of demonstrable state, with neither an
-- invented payment event nor a retroactive change to the existing projection.
insert into public.appointment_deposit_requirements(business_id,appointment_id,patient_id,status,amount,base_amount,allocation,
 terms_snapshot,projection_revision,recorded_by,recorded_at,created_at)
select d.business_id,d.appointment_id,a.patient_id,d.status,d.amount,d.amount,
 case when d.status<>'paid' then 'none' when a.status='cancelled' then 'unresolved' else 'applied' end,
 jsonb_build_object('percentage',d.percentage,'reference_amount',d.reference_amount,'request_days',d.request_days,
  'deadline_hours',d.deadline_hours,'min_payment_hours',d.min_payment_hours,'policy_revision',d.policy_revision,
  'request_from',d.request_from,'due_at',d.due_at,'auto_cancel',d.auto_cancel,'waived_reason',d.waived_reason),
 d.revision,d.recorded_by,d.recorded_at,now()
from public.appointment_deposits d join public.appointments a on (a.business_id,a.id)=(d.business_id,d.appointment_id);
insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,amount,metadata)
select r.business_id,r.appointment_id,r.id,'existing_state_observed',case when r.status='paid' then r.amount else 0 end,
 jsonb_build_object('status',r.status,'allocation',r.allocation,'recorded_at',r.recorded_at,'source','migration_observation')
from public.appointment_deposit_requirements r;

create function private.initialize_appointment_email_policy() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 insert into public.appointment_email_policies(business_id) values(new.id);
 return null;
end $$;
create trigger initialize_appointment_email_policy after insert on public.businesses
 for each row execute function private.initialize_appointment_email_policy();

create function private.reject_deposit_event_rewrite() returns trigger
language plpgsql set search_path=pg_catalog,pg_temp as $$
begin raise exception 'APPOINTMENT_DEPOSIT_EVENT_IMMUTABLE'; end $$;
create trigger appointment_deposit_events_immutable before update on public.appointment_deposit_events
 for each row execute function private.reject_deposit_event_rewrite();
-- Application roles cannot delete; owner-driven deletion of the parent practice
-- still cascades for the existing deletion/retention contract and CI fixtures.

-- All current deposit writers already hold the appointment first: creation,
-- set_appointment_deposit, rescheduling, policy-off and expiry. This trigger does
-- not acquire a parent lock after a child lock. New commands must keep that order.
create function private.synchronize_deposit_requirement() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare r public.appointment_deposit_requirements; a public.appointments; v_terms jsonb; v_allocation text; v_event text;
begin
 select * into a from public.appointments where business_id=new.business_id and id=new.appointment_id;
 v_terms:=jsonb_build_object('percentage',new.percentage,'reference_amount',new.reference_amount,'request_days',new.request_days,
  'deadline_hours',new.deadline_hours,'min_payment_hours',new.min_payment_hours,'policy_revision',new.policy_revision,
  'request_from',new.request_from,'due_at',new.due_at,'auto_cancel',new.auto_cancel,'waived_reason',new.waived_reason);
 select * into r from public.appointment_deposit_requirements
 where business_id=new.business_id and appointment_id=new.appointment_id and is_current for update;
 if not found then
  if tg_op<>'INSERT' then raise exception 'APPOINTMENT_DEPOSIT_HISTORY_MISSING'; end if;
  v_allocation:=case when new.status<>'paid' then 'none' when a.status='cancelled' then 'unresolved' else 'applied' end;
  insert into public.appointment_deposit_requirements(business_id,appointment_id,patient_id,status,amount,base_amount,
   allocation,terms_snapshot,projection_revision,recorded_by,recorded_at)
  values(new.business_id,new.appointment_id,a.patient_id,new.status,new.amount,new.amount,v_allocation,v_terms,
   new.revision,new.recorded_by,new.recorded_at) returning * into r;
  insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,metadata)
  values(r.business_id,r.appointment_id,r.id,'requirement_created',jsonb_build_object('status',new.status));
  -- Even a backend inserting an already-settled projection records only what is
  -- observed. Only the authorized pending -> paid command witnesses a payment.
  if new.status<>'pending' then
   insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,amount,metadata)
   values(r.business_id,r.appointment_id,r.id,'existing_state_observed',case when new.status='paid' then new.amount else 0 end,
    jsonb_build_object('status',new.status,'recorded_at',new.recorded_at));
  end if;
  return null;
 end if;
 if r.patient_id is distinct from a.patient_id then raise exception 'APPOINTMENT_DEPOSIT_IDENTITY_CHANGE'; end if;
 if r.status='paid' and new.amount is distinct from r.amount then raise exception 'APPOINTMENT_DEPOSIT_PAID_AMOUNT_IMMUTABLE'; end if;
 -- Compare the CURRENT requirement, not OLD projection. A new cycle installs its
 -- new pending requirement before replacing the old paid projection. Otherwise
 -- that replacement would be mistaken for undoing the historical payment.
 if r.status is distinct from new.status then
  v_event:=case when r.status='paid' and new.status='pending' then 'recording_reversed'
   when new.status='paid' then 'payment_recorded' when new.status='waived' then 'requirement_waived'
   when new.status='expired' then 'requirement_expired' else 'requirement_reopened' end;
 elsif (r.amount,r.terms_snapshot) is distinct from (new.amount,v_terms) then v_event:='requirement_updated';
 end if;
 v_allocation:=case when new.status<>'paid' then 'none' when r.status='paid' then r.allocation
  when a.status='cancelled' then 'unresolved' else 'applied' end;
 update public.appointment_deposit_requirements set status=new.status,amount=new.amount,allocation=v_allocation,
  base_amount=greatest(base_amount,new.amount),terms_snapshot=v_terms,projection_revision=new.revision,
  recorded_by=new.recorded_by,recorded_at=new.recorded_at,updated_at=now() where id=r.id;
 if v_event is not null then
  insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,amount,actor_id,metadata)
  values(r.business_id,r.appointment_id,r.id,v_event,
   case when v_event in ('payment_recorded','recording_reversed') then new.amount else 0 end,auth.uid(),
   jsonb_build_object('from_status',r.status,'to_status',new.status,'projection_revision',new.revision));
 end if;
 return null;
end $$;
create trigger appointment_deposits_sync_requirement after insert or update on public.appointment_deposits
 for each row execute function private.synchronize_deposit_requirement();

-- The appointment lock remains the single door. The monotone counter only
-- advances for semantic appointment changes: A -> B -> A cannot revive a stale
-- summary. Children are hashed below rather than adding inverse-lock triggers.
create function private.track_appointment_management_state() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare r public.appointment_deposit_requirements;
begin
 if tg_op='INSERT' then
  insert into public.appointment_management_states(business_id,appointment_id) values(new.business_id,new.id);
  return null;
 end if;
 if (new.business_id,new.patient_id) is distinct from (old.business_id,old.patient_id)
  and exists(select 1 from public.appointment_deposit_requirements where business_id=old.business_id and appointment_id=old.id and status='paid') then
  raise exception 'APPOINTMENT_DEPOSIT_IDENTITY_CHANGE';
 end if;
 if new.patient_id is distinct from old.patient_id then
  -- The controlled identity-repair RPC already audits the actor and detaches
  -- the former patient's calendar/push. An unpaid/waived requirement belongs
  -- to that former patient, as does acceptance of its economic conditions.
  -- Preserve zero-money history, close its current projection, and never
  -- describe closing it as a payment, waiver or transfer to the replacement.
  for r in select * from public.appointment_deposit_requirements
   where business_id=old.business_id and appointment_id=old.id and is_current order by ordinal for update loop
   update public.appointment_deposit_requirements set is_current=false,updated_at=clock_timestamp() where id=r.id;
   insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,actor_id,metadata)
   values(r.business_id,r.appointment_id,r.id,'requirement_updated',new.updated_by_user_id,
    jsonb_build_object('reason','patient_reassigned','closed',true));
  end loop;
  delete from public.appointment_deposits where business_id=old.business_id and appointment_id=old.id;
  update public.appointment_management_states set terms_acknowledged=false,require_deposit_on_reschedule=false,
   previous_deposit_disposition='credit',accepted_at=null,accepted_policy_revision=null,terms_snapshot='{}'::jsonb
  where business_id=old.business_id and appointment_id=old.id;
 end if;
 if (new.business_id,new.patient_id,new.service_id,new.professional_id,new.starts_at,new.ends_at,new.blocking_starts_at,
  new.blocking_ends_at,new.status,new.price_quote_snapshot,new.duration_minutes_snapshot,new.ignore_break,
  new.break_minutes_snapshot,new.buffer_before_minutes_snapshot,new.buffer_after_minutes_snapshot)
  is distinct from
  (old.business_id,old.patient_id,old.service_id,old.professional_id,old.starts_at,old.ends_at,old.blocking_starts_at,
  old.blocking_ends_at,old.status,old.price_quote_snapshot,old.duration_minutes_snapshot,old.ignore_break,
  old.break_minutes_snapshot,old.buffer_before_minutes_snapshot,old.buffer_after_minutes_snapshot) then
  update public.appointment_management_states set appointment_revision=appointment_revision+1,
   generation=case when new.patient_id is distinct from old.patient_id then generation+1 else generation end,
   legacy_management_allowed=case when new.patient_id is distinct from old.patient_id then false else legacy_management_allowed end
  where business_id=new.business_id and appointment_id=new.id;
 end if;
 if new.status='cancelled' and old.status is distinct from 'cancelled' then
  for r in select * from public.appointment_deposit_requirements
   where business_id=new.business_id and appointment_id=new.id and status='paid' and allocation='applied' order by ordinal for update loop
   update public.appointment_deposit_requirements set allocation='unresolved',updated_at=now() where id=r.id;
   insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,amount,actor_id,metadata)
   values(r.business_id,r.appointment_id,r.id,'payment_unresolved',r.amount,auth.uid(),jsonb_build_object('reason','appointment_cancelled'));
  end loop;
 end if;
 return null;
end $$;
create trigger appointments_management_state after insert or update on public.appointments
 for each row execute function private.track_appointment_management_state();

-- A single STABLE SQL statement sees one snapshot. Epochs make the digest
-- independent of the session TimeZone; arbitrary updated_at, calendar telemetry,
-- WhatsApp opens, sender-readiness and button preferences do not participate.
create function private.appointment_semantic_revision(p_business_id uuid,p_appointment_id uuid) returns text
language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select encode(extensions.digest(jsonb_build_object(
  'contract',1,'appointment_revision',m.appointment_revision,
  'identity',jsonb_build_array(a.business_id,a.id,a.patient_id,a.service_id,a.professional_id),
  'interval',jsonb_build_array(extract(epoch from a.starts_at),extract(epoch from a.ends_at),
   extract(epoch from a.blocking_starts_at),extract(epoch from a.blocking_ends_at)),
  'status',a.status,'quote',a.price_quote_snapshot,
  'management',jsonb_build_array(m.generation,m.legacy_management_allowed,m.terms_acknowledged,
   m.require_deposit_on_reschedule,m.previous_deposit_disposition,m.accepted_policy_revision),
  'financial_preferences',jsonb_build_array(p.require_deposit_on_reschedule,p.previous_deposit_disposition),
  'context',(select jsonb_build_array(c.modality,c.integration_id,c.integration_revision)
   from public.appointment_booking_contexts c where c.business_id=a.business_id and c.appointment_id=a.id),
  'team',(select jsonb_agg(jsonb_build_array(t.professional_id,t.is_primary,t.position,t.ignore_break,
   extract(epoch from t.starts_at),extract(epoch from t.ends_at),extract(epoch from t.blocking_starts_at),extract(epoch from t.blocking_ends_at))
   order by t.professional_id) from public.appointment_professionals t where t.business_id=a.business_id and t.appointment_id=a.id),
  'deposit',(select jsonb_build_array(d.status,d.amount,d.percentage,d.reference_amount,d.policy_revision,d.request_days,
   d.deadline_hours,d.min_payment_hours,extract(epoch from d.request_from),extract(epoch from d.due_at),d.auto_cancel,d.waived_reason)
   from public.appointment_deposits d where d.business_id=a.business_id and d.appointment_id=a.id),
  'requirements',(select jsonb_agg(jsonb_build_array(r.id,r.patient_id,r.is_current,r.status,r.amount,r.base_amount,r.allocation)
   order by r.ordinal) from public.appointment_deposit_requirements r where r.business_id=a.business_id and r.appointment_id=a.id),
  'economic_event',(select max(e.ordinal) from public.appointment_deposit_events e where e.business_id=a.business_id and e.appointment_id=a.id)
 )::text,'sha256'),'hex')
 from public.appointments a join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
 join public.appointment_email_policies p on p.business_id=a.business_id
 where a.business_id=p_business_id and a.id=p_appointment_id
$$;

revoke all on function private.initialize_appointment_email_policy(),private.reject_deposit_event_rewrite(),
 private.synchronize_deposit_requirement(),private.track_appointment_management_state(),private.appointment_semantic_revision(uuid,uuid)
 from public,anon,authenticated,service_role;

commit;
