-- E1 OP02: natural expiry is evaluated after waiting for authority rows.
-- Existing RPC signatures/roles and the membership/share-lock contract remain.
-- No applied migration is edited and no background producer is enabled.
begin;

create or replace function private.deposit_actor(p_business_id uuid,p_allowed text[]) returns text
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_actor uuid:=auth.uid(); v_role text; v_grant public.account_assistance_grants; v_now timestamptz;
begin
 if v_actor is null then return null; end if;
 select bu.role into v_role from public.business_users bu
 where bu.business_id=p_business_id and bu.user_id=v_actor
  and coalesce(bu.status,'active')='active' and bu.accepted_at is not null and bu.disabled_at is null for share;
 -- Evaluate the dates AFTER the actual locks, including the subscription lock.
 -- A time predicate before FOR SHARE can itself become old during the wait.
 select grants.* into v_grant
 from public.account_assistance_support_users support
 join public.account_assistance_grants grants on grants.support_user_id=support.user_id
 where support.user_id=v_actor and support.enabled and grants.business_id=p_business_id
  and grants.status='active' and grants.revoked_at is null
 for share of support,grants;
 if v_role is null and v_grant.id is null then return null; end if;
 perform 1 from public.business_subscriptions bs where bs.business_id=p_business_id for share;
 v_now:=clock_timestamp();
 if v_grant.id is not null and v_grant.starts_at<=v_now and v_grant.expires_at>v_now
  and v_role is distinct from 'owner' then v_role:='admin'; end if;
 if (v_role=any(p_allowed)) is not true then return null; end if;
 if private.appointment_business_allows_operation_at(p_business_id,v_now) is not true then return null; end if;
 return v_role;
end $$;
revoke all on function private.deposit_actor(uuid,text[]) from public,anon,authenticated,service_role;

-- Existing staff ABI, with post-lock and post-effect authority checks.
create or replace function public.set_appointment_deposit(p_business_id uuid, p_appointment_id uuid, p_action text,
 p_expected_revision bigint, p_note text default null)
returns table(status text, revision bigint, appointment_status text)
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
#variable_conflict use_column
declare a public.appointments; d public.appointment_deposits; v_now timestamptz:=now(); v_audit text;
begin
 if p_action is null or p_action not in ('paid','waived','pending') or p_expected_revision is null then
  raise exception 'DEPOSIT_ACTION_INVALID'; end if;
 if p_note is not null and char_length(p_note)>300 then raise exception 'DEPOSIT_NOTE_INVALID'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 select * into a from public.appointments ap where ap.business_id=p_business_id and ap.id=p_appointment_id for no key update;
 if not found then raise exception 'DEPOSIT_NOT_FOUND'; end if;
 select * into d from public.appointment_deposits ad where ad.business_id=p_business_id and ad.appointment_id=p_appointment_id for update;
 if not found then raise exception 'DEPOSIT_NOT_FOUND'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 v_now:=clock_timestamp();
 -- Plan 4.5: only a turn in an active status changes its deposit. Since 20260824030000 that is
 -- every status but cancelled; the list is explicit so that a status added later stays closed.
 if a.status not in ('reserved','confirmed','reschedule_requested') or d.status='expired' then
  raise exception 'DEPOSIT_APPOINTMENT_CLOSED'; end if;
 if d.status=p_action then return query select d.status,d.revision,a.status; return; end if;
 if d.revision is distinct from p_expected_revision then raise exception 'DEPOSIT_CHANGED'; end if;
 if p_action in ('paid','waived') then
  if d.status<>'pending' then raise exception 'DEPOSIT_CHANGED'; end if;
  update public.appointment_deposits ad set status=p_action,waived_reason=case when p_action='waived' then 'staff' end,
   recorded_by=auth.uid(),recorded_at=v_now,note=nullif(btrim(p_note),''),revision=d.revision+1,updated_at=v_now
  where ad.appointment_id=d.appointment_id returning * into d;
  if a.status='reserved' then
   update public.appointments ap set status='confirmed',confirmed_at=v_now,updated_by_user_id=auth.uid(),updated_at=v_now
   where ap.id=a.id and ap.business_id=a.business_id returning * into a;
  end if;
  v_audit:='appointment.deposit_'||p_action;
 else
  if d.waived_reason='policy_disabled' then raise exception 'DEPOSIT_ACTION_INVALID'; end if;
  if a.status='confirmed' then
   update public.appointments ap set status='reserved',confirmed_at=null,updated_by_user_id=auth.uid(),updated_at=v_now
   where ap.id=a.id and ap.business_id=a.business_id returning * into a;
  end if;
  update public.appointment_deposits ad set status='pending',waived_reason=null,recorded_by=null,recorded_at=null,note=null,
   auto_cancel=d.auto_cancel and (d.due_at-v_now>=make_interval(hours=>d.min_payment_hours)),revision=d.revision+1,updated_at=v_now
  where ad.appointment_id=d.appointment_id returning * into d;
  v_audit:='appointment.deposit_reopened';
 end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),v_audit,'appointment',p_appointment_id,
  jsonb_build_object('deposit_status',d.status,'appointment_status',a.status,'amount',d.amount));
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 return query select d.status,d.revision,a.status;
end $$;

-- Existing staff ABI, with post-lock and post-effect authority checks.
create or replace function public.open_appointment_deposit_reminder(p_business_id uuid, p_appointment_id uuid, p_reopen boolean default false)
returns table(previously_opened_at timestamptz, opened_at timestamptz)
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; d public.appointment_deposits; v_now timestamptz:=now();
begin
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 select * into a from public.appointments ap where ap.business_id=p_business_id and ap.id=p_appointment_id for no key update;
 if not found then raise exception 'DEPOSIT_NOT_FOUND'; end if;
 select * into d from public.appointment_deposits ad where ad.business_id=p_business_id and ad.appointment_id=p_appointment_id for update;
 if not found then raise exception 'DEPOSIT_NOT_FOUND'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 v_now:=clock_timestamp();
 if a.status not in ('reserved','confirmed','reschedule_requested') or d.status='expired' then raise exception 'DEPOSIT_APPOINTMENT_CLOSED'; end if;
 if d.status<>'pending' then raise exception 'DEPOSIT_NOT_PENDING'; end if;
 if d.reminder_opened_at is not null and p_reopen is not true then raise exception 'DEPOSIT_REMINDER_ALREADY_OPENED'; end if;
 update public.appointment_deposits ad set reminder_opened_at=v_now,reminder_opened_by=auth.uid(),updated_at=v_now
 where ad.appointment_id=d.appointment_id;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),'appointment.deposit_reminder_opened','appointment',p_appointment_id,null);
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 return query select d.reminder_opened_at,v_now;
end $$;

-- Existing staff ABI, with post-lock and post-effect authority checks.
create or replace function public.save_deposit_policy(p_business_id uuid, p_settings jsonb, p_expected_revision bigint) returns bigint
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
#variable_conflict use_column
declare v_current public.deposit_policies; v_new public.deposit_policies; v_excluded uuid[]; v_now timestamptz:=now();
 v_locked uuid[]; v_waived integer:=0; v_fixed numeric; v_percentage numeric;
begin
 if private.deposit_actor(p_business_id,array['owner','admin']) is null then raise exception 'DEPOSIT_POLICY_FORBIDDEN'; end if;
 -- Every key is required with its JSON type and no other key is accepted: a missing or mistyped
 -- value is an error, never a default (an unchecked box that is simply absent must not become
 -- «yes»). The expected revision is required as well.
 if p_expected_revision is null or jsonb_typeof(p_settings) is distinct from 'object' or octet_length(p_settings::text)>8192 then
  raise exception 'DEPOSIT_POLICY_INVALID'; end if;
 -- Its own statement, because the order of evaluation inside one condition is not guaranteed
 -- and the keys of a non-object would raise a different error. Array constructors, not '{...}'
 -- literals: in a literal an unquoted null is the SQL NULL, and `= any` over a NULL element is
 -- NULL, which a negated condition would silently let through.
 if exists(select 1 from (values ('enabled',array['boolean']),('auto_cancel_enabled',array['boolean']),('amount_mode',array['string']),
    ('fixed_amount',array['number','null']),('percentage',array['number','null']),('request_days',array['number']),
    ('deadline_hours',array['number']),('min_payment_hours',array['number']),('transfer_details',array['string','null']),
    ('applies_to_manual',array['boolean']),('excluded_service_ids',array['array'])) k(name,types)
   where (coalesce(jsonb_typeof(p_settings->k.name),'missing')=any(k.types)) is not true)
  or (select count(*) from jsonb_object_keys(p_settings))<>11 then
  raise exception 'DEPOSIT_POLICY_INVALID'; end if;
 select * into v_current from public.deposit_policies dp where dp.business_id=p_business_id for update;
 if private.deposit_actor(p_business_id,array['owner','admin']) is null then raise exception 'DEPOSIT_POLICY_FORBIDDEN'; end if;
 v_now:=clock_timestamp();
 if coalesce(v_current.revision,0)<>p_expected_revision then raise exception 'DEPOSIT_POLICY_CHANGED'; end if;
 begin
  v_new.business_id:=p_business_id;
  v_new.enabled:=(p_settings->>'enabled')::boolean;
  v_new.auto_cancel_enabled:=(p_settings->>'auto_cancel_enabled')::boolean;
  v_new.amount_mode:=p_settings->>'amount_mode';
  -- Parsed as written: assigning to bigint or numeric(5,2) would round silently.
  v_fixed:=(p_settings->>'fixed_amount')::numeric;
  v_percentage:=(p_settings->>'percentage')::numeric;
  -- An integer column rejects 7.5 instead of rounding it.
  v_new.request_days:=(p_settings->>'request_days')::integer;
  v_new.deadline_hours:=(p_settings->>'deadline_hours')::integer;
  v_new.min_payment_hours:=(p_settings->>'min_payment_hours')::integer;
  v_new.transfer_details:=nullif(btrim(p_settings->>'transfer_details'),'');
  v_new.applies_to_manual:=(p_settings->>'applies_to_manual')::boolean;
  select coalesce(array_agg(distinct value::uuid),'{}') into v_excluded from jsonb_array_elements_text(p_settings->'excluded_service_ids');
 exception when others then raise exception 'DEPOSIT_POLICY_INVALID';
 end;
 if v_new.amount_mode not in ('fixed','percentage')
  or (v_fixed is not null and (v_fixed<>trunc(v_fixed) or v_fixed not between 1 and 1000000000000))
  or (v_percentage is not null and (v_percentage<=0 or v_percentage>100 or v_percentage<>round(v_percentage,2)))
  or v_new.request_days not between 1 and 60 or v_new.deadline_hours not between 1 and 720 or v_new.min_payment_hours not between 0 and 168
  or char_length(coalesce(v_new.transfer_details,''))>500
  or (v_new.enabled and ((v_new.amount_mode='fixed' and v_fixed is null) or (v_new.amount_mode='percentage' and v_percentage is null)))
  or exists(select 1 from unnest(v_excluded) e(service_id) where not exists(
   select 1 from public.services s where s.business_id=p_business_id and s.id=e.service_id)) then
  raise exception 'DEPOSIT_POLICY_INVALID';
 end if;
 v_new.fixed_amount:=v_fixed::bigint;
 v_new.percentage:=v_percentage;
 insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,percentage,request_days,deadline_hours,
  min_payment_hours,transfer_details,applies_to_manual,revision,updated_at,updated_by)
 values(p_business_id,v_new.enabled,v_new.auto_cancel_enabled,v_new.amount_mode,v_new.fixed_amount,v_new.percentage,v_new.request_days,
  v_new.deadline_hours,v_new.min_payment_hours,v_new.transfer_details,v_new.applies_to_manual,coalesce(v_current.revision,0)+1,v_now,auth.uid())
 on conflict (business_id) do update set enabled=excluded.enabled,auto_cancel_enabled=excluded.auto_cancel_enabled,amount_mode=excluded.amount_mode,
  fixed_amount=excluded.fixed_amount,percentage=excluded.percentage,request_days=excluded.request_days,deadline_hours=excluded.deadline_hours,
  min_payment_hours=excluded.min_payment_hours,transfer_details=excluded.transfer_details,applies_to_manual=excluded.applies_to_manual,
  revision=excluded.revision,updated_at=excluded.updated_at,updated_by=excluded.updated_by
 where deposit_policies.revision=coalesce(v_current.revision,0);
 if not found then raise exception 'DEPOSIT_POLICY_CHANGED'; end if;
 delete from public.deposit_service_exclusions e where e.business_id=p_business_id;
 insert into public.deposit_service_exclusions(business_id,service_id) select p_business_id,service_id from unnest(v_excluded) service_id;
 if not v_new.enabled then
  select coalesce(array_agg(locked.id),'{}') into v_locked from (
   select a.id from public.appointments a
   join public.appointment_deposits ad on ad.appointment_id=a.id and ad.business_id=a.business_id
   where a.business_id=p_business_id and ad.status='pending'
   order by a.id
   for no key update of a
  ) locked;
  -- A deposit recorded while this waited is no longer pending: the status is re-read here.
  update public.appointment_deposits ad set status='waived',waived_reason='policy_disabled',revision=ad.revision+1,updated_at=v_now
  where ad.business_id=p_business_id and ad.appointment_id=any(v_locked) and ad.status='pending';
  get diagnostics v_waived=row_count;
 end if;
 -- Disabling can wait on several parent appointments AFTER writing the policy.
 -- A rejection here rolls back policy, waivers, history and audit together.
 if private.deposit_actor(p_business_id,array['owner','admin']) is null then raise exception 'DEPOSIT_POLICY_FORBIDDEN'; end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),'business.deposit_policy_saved','business',p_business_id,
  jsonb_build_object('enabled',v_new.enabled,'auto_cancel_enabled',v_new.auto_cancel_enabled,'amount_mode',v_new.amount_mode,
   'revision',coalesce(v_current.revision,0)+1,'waived_pending',v_waived));
 return coalesce(v_current.revision,0)+1;
end $$;

create or replace function public.revoke_appointment_management_access(p_business_id uuid,p_appointment_id uuid,p_operation_id uuid,p_expected_revision text)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; m public.appointment_management_states; prior private.appointment_management_operations;
 v_fingerprint text; v_result jsonb;
begin
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if p_operation_id is null or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false) then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 -- Serialize a reused identity even if the second caller names another turn.
 -- Every future management command shares this namespace and lock order.
 perform pg_advisory_xact_lock(hashtextextended('appointment-management-operation:'||p_business_id::text||':'||p_operation_id::text,0));
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 v_fingerprint:=encode(extensions.digest(jsonb_build_object('action','revoke','appointment_id',p_appointment_id,
  'expected_revision',p_expected_revision,'actor_id',auth.uid())::text,'sha256'),'hex');
 select * into prior from private.appointment_management_operations where business_id=p_business_id and operation_id=p_operation_id;
 if found then
  if prior.appointment_id is distinct from p_appointment_id or prior.request_fingerprint is distinct from v_fingerprint
   or prior.actor_id is distinct from auth.uid() or prior.origin<>'staff' or prior.action<>'revoke' then
   raise exception 'APPOINTMENT_OPERATION_CONFLICT'; end if;
  return prior.result||jsonb_build_object('idempotent_replay',true);
 end if;
 if private.appointment_semantic_revision(p_business_id,p_appointment_id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 update public.appointment_management_states set generation=generation+1,legacy_management_allowed=false
 where business_id=p_business_id and appointment_id=p_appointment_id returning * into m;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),'appointment.management_access_revoked','appointment',p_appointment_id,
  jsonb_build_object('generation',m.generation,'origin','staff'));
 v_result:=jsonb_build_object('appointment_id',a.id,'generation',m.generation,
  'revision',private.appointment_semantic_revision(p_business_id,p_appointment_id),'idempotent_replay',false);
 insert into private.appointment_management_operations(business_id,operation_id,appointment_id,actor_id,origin,action,request_fingerprint,result)
 values(p_business_id,p_operation_id,p_appointment_id,auth.uid(),'staff','revoke',v_fingerprint,v_result);
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 return v_result;
end $$;

create or replace function public.hide_appointment_slot_release(p_business_id uuid,p_release_id uuid) returns boolean
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare release public.appointment_slot_releases;
begin
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'SLOT_RELEASE_FORBIDDEN'; end if;
 select * into release from public.appointment_slot_releases r where r.business_id=p_business_id and r.id=p_release_id for no key update;
 if not found then raise exception 'SLOT_RELEASE_NOT_FOUND'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'SLOT_RELEASE_FORBIDDEN'; end if;
 if release.hidden_at is not null then return false; end if;
 update public.appointment_slot_releases r set hidden_at=statement_timestamp(),hidden_by=auth.uid() where r.business_id=p_business_id and r.id=p_release_id;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),'appointment.slot_release_hidden','appointment',release.appointment_id,
 jsonb_build_object('release_id',release.id,'professional_id',release.professional_id));
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'SLOT_RELEASE_FORBIDDEN'; end if;
 return true;
end $$;

revoke all on function public.set_appointment_deposit(uuid,uuid,text,bigint,text),
 public.open_appointment_deposit_reminder(uuid,uuid,boolean),public.save_deposit_policy(uuid,jsonb,bigint),
 public.revoke_appointment_management_access(uuid,uuid,uuid,text),public.hide_appointment_slot_release(uuid,uuid)
 from public,anon,authenticated,service_role;
grant execute on function public.set_appointment_deposit(uuid,uuid,text,bigint,text),
 public.open_appointment_deposit_reminder(uuid,uuid,boolean),public.save_deposit_policy(uuid,jsonb,bigint),
 public.revoke_appointment_management_access(uuid,uuid,uuid,text),public.hide_appointment_slot_release(uuid,uuid) to authenticated;
notify pgrst,'reload schema';
commit;
