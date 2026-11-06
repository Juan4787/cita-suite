-- Appointment email delivery: sender readiness, durable work, provider evidence and suppressions.
-- Installing this sends nothing: the producer switch stays off until a release turns it on.
--
-- Invariants, each kept by the functions below:
--  1. A provider call never happens inside a transaction. Claim commits first, results later.
--  2. The recipient, schedule revision, status and sender are read when claiming, never trusted
--     from the moment the work was created.
--  3. A claimed message without a known result becomes `uncertain`. Nothing resends it by itself,
--     because the provider may already have accepted it.
--  4. The identity of a message includes the schedule revision, so a duplicate guard can never
--     swallow the reminder of a new time.
--  5. Provider evidence updates only its own message: never the appointment, money or another
--     message. `delivered` means the receiving server took it, not that a person read it.
begin;

alter table private.appointment_management_runtime
 add column email_producer_enabled_at timestamptz,
 add column email_daily_limit integer not null default 100 check(email_daily_limit between 0 and 1000000),
 add column email_daily_reserve integer not null default 10 check(email_daily_reserve>=0),
 add column email_paused_until timestamptz,
 add column email_pause_reason text check(email_pause_reason is null or char_length(email_pause_reason)<=80);

create function private.stamp_email_producer_activation() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if new.email_producer_enabled and not old.email_producer_enabled then
  new.email_producer_enabled_at:=clock_timestamp();
 end if;
 return new;
end $$;
create trigger stamp_email_producer_activation before update of email_producer_enabled on private.appointment_management_runtime
 for each row execute function private.stamp_email_producer_activation();

-- When the current time of the appointment was established. A reminder is owed only if the time
-- existed before the reminder became due: a booking made inside a window gets its receipt instead.
alter table public.appointment_management_states add column schedule_changed_at timestamptz;
update public.appointment_management_states m set schedule_changed_at=a.created_at
 from public.appointments a where (a.business_id,a.id)=(m.business_id,m.appointment_id);
alter table public.appointment_management_states alter column schedule_changed_at set default clock_timestamp();
alter table public.appointment_management_states alter column schedule_changed_at set not null;

alter table private.appointment_email_events add column processed_at timestamptz;
create index appointment_email_events_unprocessed on private.appointment_email_events(occurred_at,id) where processed_at is null;

create or replace function private.record_appointment_email_event() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_revision bigint; v_generation bigint; v_purpose text; v_enabled boolean;
begin
 if tg_op='UPDATE' and (new.starts_at,new.ends_at,new.service_id,new.professional_id)
  is distinct from (old.starts_at,old.ends_at,old.service_id,old.professional_id) then
  update public.appointment_management_states set schedule_revision=schedule_revision+1,schedule_changed_at=clock_timestamp()
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
  values(new.business_id,new.id,v_revision,v_generation,v_purpose)
  on conflict(business_id,appointment_id,schedule_revision,management_generation,purpose) do nothing;
 end if;
 return null;
end $$;

-- One sender per practice. The preference to send lives in appointment_email_policies; this row
-- says whether sending is actually possible. A display name is not a verified domain.
create table private.business_email_senders (
 business_id uuid primary key references public.businesses(id) on delete cascade,
 sending_domain text unique check(sending_domain is null or (
  sending_domain ~ '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.cita-suite\.com\.ar$'
  and split_part(sending_domain,'.',1) not in ('app','www','api','mail','smtp','avisos','admin','auth','cdn','status','staging','bounce'))),
 from_local text not null default 'turnos' check(from_local ~ '^[a-z0-9][a-z0-9._-]{0,40}$'),
 reply_to_email text check(reply_to_email is null or (char_length(reply_to_email)<=254 and reply_to_email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')),
 domain_state text not null default 'unprovisioned' check(domain_state in ('unprovisioned','dns_pending','verified','failed','disabled')),
 provider_domain_key text check(provider_domain_key is null or char_length(provider_domain_key)<=200),
 last_error_code text check(last_error_code is null or char_length(last_error_code)<=80),
 verified_at timestamptz,
 last_checked_at timestamptz,
 created_at timestamptz not null default clock_timestamp(),
 updated_at timestamptz not null default clock_timestamp(),
 check(domain_state<>'verified' or (sending_domain is not null and verified_at is not null))
);
revoke all on private.business_email_senders from public,anon,authenticated,service_role;

create function private.email_sender_ready(p_business_id uuid) returns boolean
language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select exists(select 1 from private.business_email_senders s where s.business_id=p_business_id
  and s.domain_state='verified' and s.sending_domain is not null and s.reply_to_email is not null)
$$;

create function private.mirror_email_sender_readiness() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 update public.appointment_email_policies set sender_verified=private.email_sender_ready(new.business_id)
 where business_id=new.business_id and sender_verified is distinct from private.email_sender_ready(new.business_id);
 return null;
end $$;
create trigger mirror_email_sender_readiness after insert or update on private.business_email_senders
 for each row execute function private.mirror_email_sender_readiness();

create table private.appointment_email_deliveries (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null,
 appointment_id uuid not null,
 purpose text not null check(purpose in ('booking_receipt','reschedule_receipt','cancellation_receipt','deposit_request','reminder_72h','reminder_24h')),
 dedupe_key text not null check(char_length(dedupe_key) between 1 and 120),
 schedule_revision bigint not null check(schedule_revision>0),
 state text not null default 'pending' check(state in ('pending','sending','retry','accepted','delivered','uncertain','failed','bounced','complained','discarded')),
 due_at timestamptz not null,
 expires_at timestamptz not null,
 attempts integer not null default 0 check(attempts>=0),
 next_attempt_at timestamptz,
 lease_token uuid,
 lease_expires_at timestamptz,
 recipient_email text,
 patient_id uuid,
 contact_revision bigint,
 management_generation bigint,
 provider_request_id text check(provider_request_id is null or char_length(provider_request_id)<=200),
 failure_code text check(failure_code is null or char_length(failure_code)<=80),
 discard_reason text check(discard_reason is null or char_length(discard_reason)<=80),
 duplicate_risk_accepted_by uuid,
 created_at timestamptz not null default clock_timestamp(),
 started_at timestamptz,
 accepted_at timestamptz,
 delivered_at timestamptz,
 soft_bounced_at timestamptz,
 bounced_at timestamptz,
 complained_at timestamptz,
 unique(business_id,appointment_id,dedupe_key),
 foreign key(business_id,appointment_id) references public.appointments(business_id,id) on delete cascade,
 check(state<>'sending' or (lease_token is not null and lease_expires_at is not null)),
 check(state<>'discarded' or discard_reason is not null)
);
create index appointment_email_deliveries_work on private.appointment_email_deliveries(due_at,id) where state in ('pending','retry');
create index appointment_email_deliveries_leases on private.appointment_email_deliveries(lease_expires_at) where state='sending';
create index appointment_email_deliveries_appointment on private.appointment_email_deliveries(business_id,appointment_id,created_at);
create index appointment_email_deliveries_started on private.appointment_email_deliveries(started_at) where started_at is not null;
create index appointment_email_deliveries_review on private.appointment_email_deliveries(business_id) where state='uncertain';
revoke all on private.appointment_email_deliveries from public,anon,authenticated,service_role;

-- Scope is one practice and one address, so a shared family mailbox can stop all its messages
-- from that practice without affecting any other practice.
create table private.email_suppressions (
 business_id uuid not null references public.businesses(id) on delete cascade,
 email_normalized text not null check(email_normalized=lower(btrim(email_normalized)) and char_length(email_normalized) between 3 and 254),
 reason text not null check(reason in ('unsubscribe','hard_bounce','complaint')),
 delivery_id uuid,
 created_at timestamptz not null default clock_timestamp(),
 lifted_at timestamptz,
 lifted_by uuid,
 primary key(business_id,email_normalized)
);
revoke all on private.email_suppressions from public,anon,authenticated,service_role;

create table private.email_unsubscribe_tokens (
 token_hash text primary key check(token_hash ~ '^[0-9a-f]{64}$'),
 business_id uuid not null references public.businesses(id) on delete cascade,
 email_normalized text not null,
 delivery_id uuid,
 expires_at timestamptz not null,
 used_at timestamptz
);
create index email_unsubscribe_tokens_expiry on private.email_unsubscribe_tokens(expires_at);
revoke all on private.email_unsubscribe_tokens from public,anon,authenticated,service_role;

-- The receipt comes before success is answered to the provider, so a repeated notification
-- changes nothing. Only identifiers and outcomes are kept, never the provider body.
create table private.email_provider_events (
 webhook_request_id text primary key check(char_length(webhook_request_id) between 1 and 200),
 delivery_id uuid,
 business_id uuid,
 event_name text not null check(event_name in ('delivered','soft_bounce','hard_bounce','complaint','open','click','unknown')),
 occurred_at timestamptz,
 received_at timestamptz not null default clock_timestamp(),
 outcome text not null check(char_length(outcome)<=40)
);
create index email_provider_events_received on private.email_provider_events(received_at);
revoke all on private.email_provider_events from public,anon,authenticated,service_role;

-- Turns committed facts into work. Reminders are derived from the current appointment when their
-- window opens, so changing or cancelling needs no invalidation step and an old appointment only
-- gets what is still useful.
create function private.plan_appointment_email_work(p_now timestamptz,p_limit integer)
returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare e record; c record; v_enabled_at timestamptz;
begin
 select email_producer_enabled_at into v_enabled_at from private.appointment_management_runtime where singleton;

 for e in select * from private.appointment_email_events where processed_at is null
  order by occurred_at,id limit p_limit for update skip locked loop
  insert into private.appointment_email_deliveries(business_id,appointment_id,purpose,dedupe_key,schedule_revision,due_at,expires_at)
  select e.business_id,e.appointment_id,e.purpose,e.purpose||':'||e.schedule_revision,e.schedule_revision,e.occurred_at,
   case when e.purpose='cancellation_receipt' then e.occurred_at+interval '24 hours'
    else least(e.occurred_at+interval '24 hours',a.starts_at) end
  from public.appointments a where (a.business_id,a.id)=(e.business_id,e.appointment_id)
  on conflict(business_id,appointment_id,dedupe_key) do nothing;
  update private.appointment_email_events set processed_at=p_now where id=e.id;
 end loop;

 -- A corrected or added address owes the current receipt once, and only for useful appointments.
 -- Pending work needs nothing here: it reads the current contact when claimed.
 for c in select * from private.patient_email_contact_events where processed_at is null
  order by created_at,patient_id limit p_limit for update skip locked loop
  insert into private.appointment_email_deliveries(business_id,appointment_id,purpose,dedupe_key,schedule_revision,due_at,expires_at)
  select a.business_id,a.id,'booking_receipt','contact:'||c.contact_revision||':'||m.schedule_revision,m.schedule_revision,p_now,
   least(p_now+interval '24 hours',a.starts_at)
  from public.appointments a
  join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
  where a.business_id=c.business_id and a.patient_id=c.patient_id
   and a.status in ('reserved','confirmed','reschedule_requested') and a.starts_at>p_now
   and v_enabled_at is not null and c.created_at>=v_enabled_at
   and not exists(select 1 from private.appointment_email_deliveries d
    where (d.business_id,d.appointment_id)=(a.business_id,a.id) and d.schedule_revision=m.schedule_revision
     and d.purpose in ('booking_receipt','reschedule_receipt') and d.state in ('accepted','delivered','pending','retry','sending','uncertain'))
  on conflict(business_id,appointment_id,dedupe_key) do nothing;
  update private.patient_email_contact_events set processed_at=p_now
  where (business_id,patient_id,contact_revision)=(c.business_id,c.patient_id,c.contact_revision);
 end loop;

 -- A new obligation is requested alone only when no receipt of that revision carries it.
 insert into private.appointment_email_deliveries(business_id,appointment_id,purpose,dedupe_key,schedule_revision,due_at,expires_at)
 select a.business_id,a.id,'deposit_request','deposit_request:'||r.id,m.schedule_revision,p_now,least(d.due_at,a.starts_at)
 from public.appointment_deposit_requirements r
 join public.appointment_deposits d on (d.business_id,d.appointment_id)=(r.business_id,r.appointment_id)
 join public.appointments a on (a.business_id,a.id)=(r.business_id,r.appointment_id)
 join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
 where r.is_current and r.status='pending' and d.status='pending' and v_enabled_at is not null and r.created_at>=v_enabled_at
  and a.status in ('reserved','confirmed','reschedule_requested') and a.starts_at>p_now and d.due_at>p_now
  and not exists(select 1 from private.appointment_email_deliveries x
   where (x.business_id,x.appointment_id)=(a.business_id,a.id) and x.schedule_revision=m.schedule_revision
    and x.purpose in ('booking_receipt','reschedule_receipt') and x.state<>'discarded')
 on conflict(business_id,appointment_id,dedupe_key) do nothing;

 insert into private.appointment_email_deliveries(business_id,appointment_id,purpose,dedupe_key,schedule_revision,due_at,expires_at)
 select a.business_id,a.id,w.purpose,w.purpose||':'||m.schedule_revision,m.schedule_revision,a.starts_at-w.lead,
  least(a.starts_at-w.lead+interval '30 minutes',a.starts_at)
 from public.appointments a
 join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
 join public.appointment_email_policies p on p.business_id=a.business_id and p.email_enabled
 cross join (values('reminder_72h',interval '72 hours'),('reminder_24h',interval '24 hours')) w(purpose,lead)
 where a.status in ('reserved','confirmed','reschedule_requested')
  and a.starts_at>p_now and a.starts_at<=p_now+interval '72 hours 30 minutes'
  and p_now>=a.starts_at-w.lead and p_now<a.starts_at-w.lead+interval '30 minutes'
  and m.schedule_changed_at<a.starts_at-w.lead
 on conflict(business_id,appointment_id,dedupe_key) do nothing;
end $$;

create function private.discard_appointment_email(p_id uuid,p_reason text)
returns void language sql security definer set search_path=pg_catalog,pg_temp as $$
 update private.appointment_email_deliveries set state='discarded',discard_reason=p_reason,next_attempt_at=null,lease_token=null,lease_expires_at=null
 where id=p_id
$$;

-- Service only. Commits before the caller contacts the provider: `sending` is the durable promise
-- that an attempt may exist, which is what makes a lost response recoverable.
create function public.claim_appointment_email_batch(p_limit integer,p_now timestamptz default null)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=coalesce(p_now,clock_timestamp()); v_runtime private.appointment_management_runtime;
 d private.appointment_email_deliveries; a public.appointments; m public.appointment_management_states;
 pol public.appointment_email_policies; s private.business_email_senders; dep public.appointment_deposits; v_contact record;
 v_items jsonb:='[]'::jsonb; v_taken integer:=0; v_used integer; v_budget integer; v_lease uuid; v_token text; v_unsub text;
 v_snapshot jsonb; v_email text; v_discarded integer:=0;
begin
 if p_limit is null or p_limit<1 or p_limit>20 or not isfinite(v_now) then raise exception 'EMAIL_CLAIM_INVALID'; end if;
 select * into v_runtime from private.appointment_management_runtime where singleton;
 if not v_runtime.email_producer_enabled then return jsonb_build_object('enabled',false,'items','[]'::jsonb); end if;

 perform private.plan_appointment_email_work(v_now,50);

 update private.appointment_email_deliveries set state='uncertain',failure_code='lease_expired',lease_token=null,lease_expires_at=null
 where state='sending' and lease_expires_at<=v_now;
 update private.appointment_email_deliveries set state='discarded',discard_reason='expired',next_attempt_at=null
 where state in ('pending','retry') and expires_at<=v_now;

 if v_runtime.email_paused_until is not null and v_runtime.email_paused_until>v_now then
  return jsonb_build_object('enabled',true,'paused',true,'reason',v_runtime.email_pause_reason,'items','[]'::jsonb);
 end if;

 -- The provider exposes no quota: this is our own durable count, shared by all practices.
 select count(*) into v_used from private.appointment_email_deliveries where started_at>v_now-interval '24 hours';
 v_budget:=greatest(0,v_runtime.email_daily_limit-v_runtime.email_daily_reserve-v_used);

 for d in select x.* from private.appointment_email_deliveries x
  where x.state in ('pending','retry') and coalesce(x.next_attempt_at,x.due_at)<=v_now and private.email_sender_ready(x.business_id)
  order by case when x.purpose in ('booking_receipt','reschedule_receipt','cancellation_receipt') then 0 when x.purpose='deposit_request' then 1 else 2 end,x.due_at,x.id
  limit p_limit*3 for update of x skip locked loop
  exit when v_taken>=p_limit or v_budget<=0;
  select * into a from public.appointments where business_id=d.business_id and id=d.appointment_id for no key update skip locked;
  continue when not found;
  select * into m from public.appointment_management_states where business_id=d.business_id and appointment_id=d.appointment_id;
  select * into pol from public.appointment_email_policies where business_id=d.business_id;
  select * into s from private.business_email_senders where business_id=d.business_id;
  select * into dep from public.appointment_deposits where business_id=d.business_id and appointment_id=d.appointment_id;

  if not pol.email_enabled then perform private.discard_appointment_email(d.id,'email_disabled'); v_discarded:=v_discarded+1; continue; end if;
  if d.purpose='cancellation_receipt' then
   if a.status<>'cancelled' then perform private.discard_appointment_email(d.id,'not_cancelled'); v_discarded:=v_discarded+1; continue; end if;
  else
   if a.status not in ('reserved','confirmed','reschedule_requested') then perform private.discard_appointment_email(d.id,'appointment_cancelled'); v_discarded:=v_discarded+1; continue; end if;
   if a.starts_at<=v_now then perform private.discard_appointment_email(d.id,'appointment_started'); v_discarded:=v_discarded+1; continue; end if;
   if d.schedule_revision is distinct from m.schedule_revision then perform private.discard_appointment_email(d.id,'superseded_schedule'); v_discarded:=v_discarded+1; continue; end if;
  end if;
  if d.purpose='deposit_request' and (dep.appointment_id is null or dep.status<>'pending') then
   perform private.discard_appointment_email(d.id,'deposit_not_pending'); v_discarded:=v_discarded+1; continue;
  end if;

  select * into v_contact from private.appointment_email_contact(d.business_id,d.appointment_id);
  v_email:=btrim(v_contact.email);
  if v_email is null or v_email='' then perform private.discard_appointment_email(d.id,'no_recipient'); v_discarded:=v_discarded+1; continue; end if;
  if char_length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
   perform private.discard_appointment_email(d.id,'invalid_recipient'); v_discarded:=v_discarded+1; continue; end if;
  if exists(select 1 from private.email_suppressions x where x.business_id=d.business_id and x.email_normalized=lower(v_email) and x.lifted_at is null) then
   perform private.discard_appointment_email(d.id,'suppressed'); v_discarded:=v_discarded+1; continue; end if;
  -- A receipt accepted just before a reminder opens already carries the same appointment facts
  -- for the same address and revision. Proximity alone never suppresses anything.
  if d.purpose in ('reminder_72h','reminder_24h') and exists(select 1 from private.appointment_email_deliveries r
   where (r.business_id,r.appointment_id)=(d.business_id,d.appointment_id) and r.schedule_revision=d.schedule_revision
    and r.purpose in ('booking_receipt','reschedule_receipt') and r.state in ('accepted','delivered')
    and r.accepted_at>=d.due_at-interval '30 minutes' and r.contact_revision=v_contact.contact_revision) then
   perform private.discard_appointment_email(d.id,'covered_by_receipt'); v_discarded:=v_discarded+1; continue;
  end if;

  v_token:=null;
  if d.purpose<>'cancellation_receipt' then
   v_token:=public.issue_appointment_management_capability(d.business_id,d.appointment_id,m.generation);
  end if;
  v_unsub:=encode(extensions.gen_random_bytes(32),'hex');
  insert into private.email_unsubscribe_tokens(token_hash,business_id,email_normalized,delivery_id,expires_at)
  values(encode(extensions.digest(v_unsub,'sha256'),'hex'),d.business_id,lower(v_email),d.id,v_now+interval '365 days');
  v_snapshot:=private.appointment_management_snapshot(d.business_id,d.appointment_id,null,v_now);
  v_lease:=gen_random_uuid();
  update private.appointment_email_deliveries set state='sending',attempts=attempts+1,lease_token=v_lease,lease_expires_at=v_now+interval '10 minutes',
   next_attempt_at=null,started_at=v_now,recipient_email=v_email,patient_id=v_contact.patient_id,contact_revision=v_contact.contact_revision,management_generation=m.generation
  where id=d.id;
  v_items:=v_items||jsonb_build_array(jsonb_build_object('delivery_id',d.id,'lease_token',v_lease,'purpose',d.purpose,'recipient',v_email,
   'token',v_token,'unsubscribe_token',v_unsub,
   'sender',jsonb_build_object('from_address',s.from_local||'@'||s.sending_domain,'reply_to',s.reply_to_email),
   'preferences',jsonb_build_object('show_cancel',pol.show_cancel,'show_reschedule',pol.show_reschedule),
   'snapshot',v_snapshot));
  v_taken:=v_taken+1; v_budget:=v_budget-1;
 end loop;

 return jsonb_build_object('enabled',true,'paused',false,'items',v_items,'discarded',v_discarded,
  'quota',jsonb_build_object('used',v_used+v_taken,'limit',v_runtime.email_daily_limit,'reserve',v_runtime.email_daily_reserve));
end $$;

-- Service only. A result that no longer holds its lease changes nothing, so a late worker cannot
-- overwrite what evidence already decided. Only a provider-recognized permanent answer ends a message.
create function public.record_appointment_email_results(p_results jsonb,p_now timestamptz default null)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=coalesce(p_now,clock_timestamp()); r record; d private.appointment_email_deliveries; v_applied integer:=0; v_ignored integer:=0;
begin
 if p_results is null or jsonb_typeof(p_results)<>'array' then raise exception 'EMAIL_RESULTS_INVALID'; end if;
 for r in select * from jsonb_to_recordset(p_results) as x(delivery_id uuid,lease_token uuid,outcome text,request_id text,code text) loop
  if r.outcome not in ('accepted','retry','failed','uncertain','sender_rejected','pause','released') then raise exception 'EMAIL_RESULTS_INVALID'; end if;
  select * into d from private.appointment_email_deliveries where id=r.delivery_id and lease_token=r.lease_token for update;
  if not found then
   -- Evidence can arrive first. Keep the provider identity on the message it belongs to.
   if r.outcome='accepted' then
    update private.appointment_email_deliveries set provider_request_id=coalesce(provider_request_id,left(r.request_id,200)),accepted_at=coalesce(accepted_at,v_now)
    where id=r.delivery_id and state in ('delivered','bounced','complained');
   end if;
   v_ignored:=v_ignored+1; continue;
  end if;
  if d.state<>'sending' then
   if r.outcome='accepted' and d.state in ('delivered','bounced','complained') then
    update private.appointment_email_deliveries set provider_request_id=coalesce(provider_request_id,left(r.request_id,200)),accepted_at=coalesce(accepted_at,v_now) where id=d.id;
   end if;
   v_ignored:=v_ignored+1; continue;
  end if;
  if r.outcome='accepted' then
   update private.appointment_email_deliveries set state='accepted',accepted_at=v_now,provider_request_id=left(r.request_id,200),failure_code=null,lease_token=null,lease_expires_at=null where id=d.id;
  elsif r.outcome='released' then
   -- The run ended before this message was attempted: it certainly did not leave.
   update private.appointment_email_deliveries set state='pending',attempts=greatest(attempts-1,0),started_at=null,lease_token=null,lease_expires_at=null where id=d.id;
  elsif r.outcome='uncertain' then
   update private.appointment_email_deliveries set state='uncertain',failure_code=left(coalesce(r.code,'unknown'),80),lease_token=null,lease_expires_at=null where id=d.id;
  elsif r.outcome='failed' then
   update private.appointment_email_deliveries set state='failed',failure_code=left(coalesce(r.code,'unknown'),80),lease_token=null,lease_expires_at=null where id=d.id;
  elsif r.outcome='retry' then
   if d.attempts>=5 or v_now>=d.expires_at then
    update private.appointment_email_deliveries set state='failed',failure_code=left(coalesce(r.code,'retries_exhausted'),80),lease_token=null,lease_expires_at=null where id=d.id;
   else
    update private.appointment_email_deliveries set state='retry',failure_code=left(r.code,80),lease_token=null,lease_expires_at=null,
     next_attempt_at=v_now+(case d.attempts when 1 then interval '5 minutes' when 2 then interval '15 minutes' else interval '60 minutes' end) where id=d.id;
   end if;
  else
   -- The provider refused before sending, so this attempt certainly did not leave. It does not
   -- count against the message: the configuration has to be repaired instead.
   update private.appointment_email_deliveries set state='retry',attempts=greatest(attempts-1,0),failure_code=left(r.code,80),lease_token=null,lease_expires_at=null,
    next_attempt_at=v_now+interval '15 minutes',started_at=null where id=d.id;
   if r.outcome='sender_rejected' then
    update private.business_email_senders set domain_state='failed',last_error_code=left(r.code,80),last_checked_at=v_now,updated_at=v_now where business_id=d.business_id;
   else
    update private.appointment_management_runtime set email_paused_until=v_now+interval '15 minutes',email_pause_reason=left(r.code,80) where singleton;
   end if;
  end if;
  v_applied:=v_applied+1;
 end loop;
 return jsonb_build_object('applied',v_applied,'ignored',v_ignored);
end $$;

-- Service only, after the webhook signature was checked. Repeats and unknown references are
-- answered as handled, so the provider stops retrying, and they change nothing.
create function public.record_email_provider_event(p_webhook_request_id text,p_client_reference text,p_event text,p_occurred_at timestamptz default null)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare d private.appointment_email_deliveries; v_id uuid; v_inserted integer; v_outcome text:='ignored'; v_now timestamptz:=clock_timestamp();
begin
 if coalesce(char_length(p_webhook_request_id),0) not between 1 and 200 or
  p_event is null or p_event not in ('delivered','soft_bounce','hard_bounce','complaint','open','click','unknown') then
  raise exception 'EMAIL_EVENT_INVALID'; end if;
 if p_client_reference ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then v_id:=p_client_reference::uuid; end if;
 insert into private.email_provider_events(webhook_request_id,delivery_id,event_name,occurred_at,outcome)
 values(p_webhook_request_id,v_id,p_event,p_occurred_at,'received') on conflict(webhook_request_id) do nothing;
 get diagnostics v_inserted=row_count;
 if v_inserted=0 then return jsonb_build_object('duplicate',true,'outcome','duplicate'); end if;
 if v_id is not null then select * into d from private.appointment_email_deliveries where id=v_id for update; end if;
 if d.id is null then
  update private.email_provider_events set outcome='unknown_reference' where webhook_request_id=p_webhook_request_id;
  return jsonb_build_object('duplicate',false,'outcome','unknown_reference');
 end if;
 if p_event='delivered' and d.state in ('sending','uncertain','accepted') then
  update private.appointment_email_deliveries set state='delivered',delivered_at=coalesce(p_occurred_at,v_now),accepted_at=coalesce(accepted_at,v_now),lease_token=null,lease_expires_at=null where id=d.id;
  v_outcome:='delivered';
 elsif p_event='soft_bounce' then
  update private.appointment_email_deliveries set soft_bounced_at=coalesce(p_occurred_at,v_now) where id=d.id;
  v_outcome:='soft_bounce';
 elsif p_event in ('hard_bounce','complaint') and d.state in ('sending','uncertain','accepted','delivered') then
  update private.appointment_email_deliveries set state=case when p_event='complaint' then 'complained' else 'bounced' end,
   bounced_at=case when p_event='hard_bounce' then coalesce(p_occurred_at,v_now) else bounced_at end,
   complained_at=case when p_event='complaint' then coalesce(p_occurred_at,v_now) else complained_at end,
   lease_token=null,lease_expires_at=null where id=d.id;
  if d.recipient_email is not null then
   insert into private.email_suppressions(business_id,email_normalized,reason,delivery_id)
   values(d.business_id,lower(btrim(d.recipient_email)),case when p_event='complaint' then 'complaint' else 'hard_bounce' end,d.id)
   on conflict(business_id,email_normalized) do update set reason=excluded.reason,delivery_id=excluded.delivery_id,created_at=clock_timestamp(),lifted_at=null,lifted_by=null
   where private.email_suppressions.lifted_at is not null;
  end if;
  v_outcome:=p_event;
 end if;
 update private.email_provider_events set outcome=v_outcome,business_id=d.business_id where webhook_request_id=p_webhook_request_id;
 return jsonb_build_object('duplicate',false,'outcome',v_outcome);
end $$;

-- Reading a link never unsubscribes: mail scanners open links. Only the explicit POST does.
create function public.get_email_unsubscribe(p_token text) returns jsonb
language plpgsql stable security definer set search_path=pg_catalog,pg_temp as $$
declare t private.email_unsubscribe_tokens; b public.businesses;
begin
 if not coalesce(p_token ~ '^[0-9a-f]{64}$',false) then return null; end if;
 select * into t from private.email_unsubscribe_tokens where token_hash=encode(extensions.digest(p_token,'sha256'),'hex') and expires_at>clock_timestamp();
 if not found then return null; end if;
 select * into b from public.businesses where id=t.business_id;
 return jsonb_build_object('business_name',b.name,'unsubscribed',exists(select 1 from private.email_suppressions s
  where s.business_id=t.business_id and s.email_normalized=t.email_normalized and s.lifted_at is null));
end $$;

create function public.apply_email_unsubscribe(p_token text) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare t private.email_unsubscribe_tokens; b public.businesses;
begin
 if not coalesce(p_token ~ '^[0-9a-f]{64}$',false) then raise exception 'EMAIL_UNSUBSCRIBE_UNAVAILABLE'; end if;
 select * into t from private.email_unsubscribe_tokens where token_hash=encode(extensions.digest(p_token,'sha256'),'hex') and expires_at>clock_timestamp() for update;
 if not found then raise exception 'EMAIL_UNSUBSCRIBE_UNAVAILABLE'; end if;
 insert into private.email_suppressions(business_id,email_normalized,reason,delivery_id)
 values(t.business_id,t.email_normalized,'unsubscribe',t.delivery_id)
 on conflict(business_id,email_normalized) do update set reason='unsubscribe',delivery_id=excluded.delivery_id,created_at=clock_timestamp(),lifted_at=null,lifted_by=null
 where private.email_suppressions.lifted_at is not null;
 update private.email_unsubscribe_tokens set used_at=coalesce(used_at,clock_timestamp()) where token_hash=t.token_hash;
 select * into b from public.businesses where id=t.business_id;
 return jsonb_build_object('business_name',b.name,'unsubscribed',true);
end $$;

-- What the practice sees about one appointment. No provider diagnostics, no tokens.
create function public.list_appointment_email_deliveries(p_business_id uuid,p_appointment_id uuid) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',d.id,'purpose',d.purpose,'state',d.state,'recipient',d.recipient_email,
   'created_at',d.created_at,'accepted_at',d.accepted_at,'delivered_at',d.delivered_at,'discard_reason',d.discard_reason,'failure_code',d.failure_code) order by d.created_at desc,d.id)
  from (select * from private.appointment_email_deliveries x where x.business_id=p_business_id and x.appointment_id=p_appointment_id order by x.created_at desc limit 30) d),'[]'::jsonb);
end $$;

-- The person decides what the system cannot know. Resending can duplicate, so the choice is recorded.
create function public.resolve_appointment_email_delivery(p_business_id uuid,p_delivery_id uuid,p_decision text) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_actor uuid; d private.appointment_email_deliveries; v_now timestamptz:=clock_timestamp();
begin
 v_actor:=private.deposit_actor(p_business_id,array['owner','admin','reception']);
 if v_actor is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if p_decision is null or p_decision not in ('resend','dismiss') then raise exception 'EMAIL_DECISION_INVALID'; end if;
 select * into d from private.appointment_email_deliveries where id=p_delivery_id and business_id=p_business_id for update;
 if not found or d.state<>'uncertain' then raise exception 'EMAIL_DELIVERY_CHANGED'; end if;
 if p_decision='resend' then
  update private.appointment_email_deliveries set state='retry',next_attempt_at=v_now,duplicate_risk_accepted_by=v_actor,expires_at=greatest(expires_at,v_now+interval '1 hour') where id=d.id;
 else
  update private.appointment_email_deliveries set state='discarded',discard_reason='operator_dismissed' where id=d.id;
 end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,v_actor,'appointment.email_uncertain_resolved','appointment',d.appointment_id,jsonb_build_object('purpose',d.purpose,'decision',p_decision));
 return jsonb_build_object('state',case when p_decision='resend' then 'retry' else 'discarded' end);
end $$;

-- Readiness for the settings screen: separate facts, so nothing implies sending works when it does not.
create function public.get_business_email_status(p_business_id uuid) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare s private.business_email_senders; v_runtime private.appointment_management_runtime; v_used integer;
begin
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 select * into s from private.business_email_senders where business_id=p_business_id;
 select * into v_runtime from private.appointment_management_runtime where singleton;
 select count(*) into v_used from private.appointment_email_deliveries where started_at>clock_timestamp()-interval '24 hours';
 return jsonb_build_object('domain_state',coalesce(s.domain_state,'unprovisioned'),'from_address',case when s.sending_domain is not null then s.from_local||'@'||s.sending_domain end,
  'reply_to',s.reply_to_email,'ready',private.email_sender_ready(p_business_id),'producer_enabled',v_runtime.email_producer_enabled,
  'paused',coalesce(v_runtime.email_paused_until>clock_timestamp(),false),'used_24h',v_used,'daily_limit',v_runtime.email_daily_limit,
  'needs_review',(select count(*) from private.appointment_email_deliveries d where d.business_id=p_business_id and d.state='uncertain'),
  'failed_7d',(select count(*) from private.appointment_email_deliveries d where d.business_id=p_business_id and d.state in ('failed','bounced','complained') and d.created_at>clock_timestamp()-interval '7 days'));
end $$;

create function public.save_business_email_contact(p_business_id uuid,p_reply_to text) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_actor uuid; v_email text:=nullif(btrim(p_reply_to),'');
begin
 v_actor:=private.deposit_actor(p_business_id,array['owner','admin']);
 if v_actor is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if v_email is not null and (char_length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then raise exception 'EMAIL_CONTACT_INVALID'; end if;
 insert into private.business_email_senders(business_id,reply_to_email) values(p_business_id,v_email)
 on conflict(business_id) do update set reply_to_email=excluded.reply_to_email,updated_at=clock_timestamp();
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,v_actor,'business.email_contact_updated','business',p_business_id,'{}'::jsonb);
 return jsonb_build_object('ready',private.email_sender_ready(p_business_id));
end $$;

-- Operator only, after the provider and DNS were checked by the provisioning tool.
create function public.operator_set_business_email_sender(p_business_id uuid,p_domain text,p_state text,p_provider_domain_key text default null,p_reply_to text default null)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=clock_timestamp();
begin
 if p_state is null or p_state not in ('dns_pending','verified','failed','disabled') then raise exception 'EMAIL_SENDER_INVALID'; end if;
 insert into private.business_email_senders(business_id,sending_domain,domain_state,provider_domain_key,reply_to_email,verified_at,last_checked_at)
 values(p_business_id,lower(btrim(p_domain)),p_state,p_provider_domain_key,nullif(btrim(p_reply_to),''),case when p_state='verified' then v_now end,v_now)
 on conflict(business_id) do update set sending_domain=excluded.sending_domain,domain_state=excluded.domain_state,
  provider_domain_key=coalesce(excluded.provider_domain_key,private.business_email_senders.provider_domain_key),
  reply_to_email=coalesce(excluded.reply_to_email,private.business_email_senders.reply_to_email),
  verified_at=case when excluded.domain_state='verified' then coalesce(private.business_email_senders.verified_at,v_now) else private.business_email_senders.verified_at end,
  last_error_code=null,last_checked_at=v_now,updated_at=v_now;
 return jsonb_build_object('ready',private.email_sender_ready(p_business_id));
end $$;

-- Whether reminders by email will really be attempted for this appointment, so the page does not
-- ask a patient to set up something they already have. It says nothing about reaching a mailbox.
create function private.appointment_email_reminders_active(p_business_id uuid,p_appointment_id uuid) returns boolean
language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select coalesce((select r.email_producer_enabled from private.appointment_management_runtime r where r.singleton),false)
  and coalesce((select p.email_enabled from public.appointment_email_policies p where p.business_id=p_business_id),false)
  and private.email_sender_ready(p_business_id)
  and exists(select 1 from private.appointment_email_contact(p_business_id,p_appointment_id) c
   where nullif(btrim(c.email),'') is not null and not exists(select 1 from private.email_suppressions s
    where s.business_id=p_business_id and s.email_normalized=lower(btrim(c.email)) and s.lifted_at is null))
$$;

create or replace function public.get_patient_appointment_management_view(p_token text,p_legacy boolean default false,p_starts_at timestamptz default null)
returns jsonb language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=clock_timestamp(); v_result jsonb;
begin
 if p_legacy is null or not coalesce(p_token ~ '^[0-9a-f]{64}$',false) then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 with access as materialized (select private.appointment_management_access_at(p_token,p_legacy,v_now) as context)
 select private.appointment_management_snapshot((context->>'business_id')::uuid,(context->>'appointment_id')::uuid,p_starts_at,v_now)
  ||jsonb_build_object('revision',context->'revision','generation',context->'generation','access_kind',context->'access_kind',
   'email_reminders_active',private.appointment_email_reminders_active((context->>'business_id')::uuid,(context->>'appointment_id')::uuid))
 into v_result from access where context is not null;
 if v_result is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 return v_result;
end $$;

-- Service only, from the maintenance job. A management link dies at its expiry, but its hash and the
-- recipient of an old message have no reason to stay. Keeps enough history to answer a practice's
-- questions about recent messages, and never touches anything that a pending message still needs.
create function public.run_appointment_email_retention(p_now timestamptz default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=coalesce(p_now,clock_timestamp()); v_capabilities integer; v_tokens integer; v_events integer; v_recipients integer; v_deliveries integer;
begin
 delete from private.appointment_management_capabilities where expires_at<v_now-interval '30 days';
 get diagnostics v_capabilities=row_count;
 delete from private.email_unsubscribe_tokens where expires_at<v_now;
 get diagnostics v_tokens=row_count;
 delete from private.email_provider_events where received_at<v_now-interval '90 days';
 get diagnostics v_events=row_count;
 delete from private.appointment_email_events where processed_at<v_now-interval '30 days';
 delete from private.patient_email_contact_events where processed_at<v_now-interval '30 days';
 update private.appointment_email_deliveries set recipient_email=null
 where recipient_email is not null and created_at<v_now-interval '180 days' and state not in ('pending','sending','retry','uncertain');
 get diagnostics v_recipients=row_count;
 delete from private.appointment_email_deliveries where created_at<v_now-interval '400 days' and state not in ('pending','sending','retry','uncertain');
 get diagnostics v_deliveries=row_count;
 return jsonb_build_object('capabilities',v_capabilities,'unsubscribe_tokens',v_tokens,'provider_events',v_events,'recipients',v_recipients,'deliveries',v_deliveries);
end $$;

revoke all on function private.stamp_email_producer_activation(),private.email_sender_ready(uuid),private.mirror_email_sender_readiness(),
 private.plan_appointment_email_work(timestamptz,integer),private.discard_appointment_email(uuid,text),private.appointment_email_reminders_active(uuid,uuid),
 public.claim_appointment_email_batch(integer,timestamptz),public.record_appointment_email_results(jsonb,timestamptz),
 public.record_email_provider_event(text,text,text,timestamptz),public.get_email_unsubscribe(text),public.apply_email_unsubscribe(text),
 public.list_appointment_email_deliveries(uuid,uuid),public.resolve_appointment_email_delivery(uuid,uuid,text),
 public.get_business_email_status(uuid),public.save_business_email_contact(uuid,text),public.operator_set_business_email_sender(uuid,text,text,text,text),
 public.run_appointment_email_retention(timestamptz)
 from public,anon,authenticated,service_role;
grant execute on function public.claim_appointment_email_batch(integer,timestamptz),public.record_appointment_email_results(jsonb,timestamptz),
 public.record_email_provider_event(text,text,text,timestamptz),public.get_email_unsubscribe(text),public.apply_email_unsubscribe(text),
 public.operator_set_business_email_sender(uuid,text,text,text,text),public.run_appointment_email_retention(timestamptz) to service_role;
grant execute on function public.list_appointment_email_deliveries(uuid,uuid),public.resolve_appointment_email_delivery(uuid,uuid,text),
 public.get_business_email_status(uuid),public.save_business_email_contact(uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
