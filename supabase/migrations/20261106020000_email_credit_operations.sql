-- Email operations for the operator: the credit bought from the provider, the shared daily cap,
-- the producer switch and lifting a pause. The provider exposes neither balance nor expiry
-- (docs/plans/plan-integral-avisos-20261105.md, 4.3), so the operator records each credit when
-- buying it and the app counts what it started since then: the warning never depends on the
-- provider answering (case ZH04). Buying, KYC and top-ups stay with Juan; nothing here buys,
-- recharges or contacts the provider.
begin;

alter table private.appointment_management_runtime
 add column email_credit_messages integer check(email_credit_messages is null or email_credit_messages between 1 and 100000000),
 add column email_credit_started_at timestamptz,
 add column email_credit_expires_at timestamptz,
 add column email_operations_revision bigint not null default 1 check(email_operations_revision>0),
 add constraint email_credit_complete check(
  (email_credit_messages is null and email_credit_started_at is null and email_credit_expires_at is null) or
  (email_credit_messages is not null and email_credit_started_at is not null and email_credit_expires_at is not null
   and email_credit_expires_at>email_credit_started_at));

-- Service only: the page that calls it admits only the operator's verified account. Counts and
-- states, never recipients: the operator does not need any patient's address to act.
create function public.operator_get_email_operations(p_now timestamptz default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=coalesce(p_now,clock_timestamp()); r private.appointment_management_runtime;
begin
 if not isfinite(v_now) then raise exception 'EMAIL_OPERATIONS_INVALID'; end if;
 select * into r from private.appointment_management_runtime where singleton;
 return jsonb_build_object(
  'revision',r.email_operations_revision,
  'producer_enabled',r.email_producer_enabled,'producer_enabled_at',r.email_producer_enabled_at,
  'paused_until',case when r.email_paused_until>v_now then r.email_paused_until end,
  'pause_reason',case when r.email_paused_until>v_now then r.email_pause_reason end,
  'daily_limit',r.email_daily_limit,'daily_reserve',r.email_daily_reserve,
  'used_24h',(select count(*) from private.appointment_email_deliveries where started_at>v_now-interval '24 hours'),
  'credit_messages',r.email_credit_messages,'credit_started_at',r.email_credit_started_at,'credit_expires_at',r.email_credit_expires_at,
  -- Conservative: whatever may have left since the credit started counts, accepted or not.
  'credit_used',case when r.email_credit_started_at is null then null else
   (select count(*) from private.appointment_email_deliveries where greatest(started_at,accepted_at)>=r.email_credit_started_at) end,
  'uncertain',(select count(*) from private.appointment_email_deliveries where state='uncertain'),
  'failed_7d',(select count(*) from private.appointment_email_deliveries where state in ('failed','bounced','complained') and created_at>v_now-interval '7 days'),
  'senders',coalesce((select jsonb_agg(jsonb_build_object('business_id',s.business_id,'business_name',b.name,'domain',s.sending_domain,
     'state',s.domain_state,'ready',private.email_sender_ready(s.business_id)) order by b.name,s.business_id)
   from (select * from private.business_email_senders order by business_id limit 100) s join public.businesses b on b.id=s.business_id),'[]'::jsonb));
end $$;

-- Service only, after the page verified the operator. One revision guards the whole form, so two
-- operators never overwrite each other silently. Turning the producer on stamps a new activation
-- (stamp_email_producer_activation), so nothing that happened while it was off is sent late.
create function public.operator_set_email_operations(p_actor_id uuid,p_expected_revision bigint,p_producer_enabled boolean,
 p_daily_limit integer,p_credit_messages integer,p_credit_started_at timestamptz,p_credit_expires_at timestamptz,p_lift_pause boolean default false)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare r private.appointment_management_runtime;
begin
 if p_actor_id is null or p_expected_revision is null or p_producer_enabled is null or p_lift_pause is null
  or p_daily_limit is null or p_daily_limit not between 0 and 1000000 then raise exception 'EMAIL_OPERATIONS_INVALID'; end if;
 if (p_credit_messages is null)<>(p_credit_started_at is null) or (p_credit_messages is null)<>(p_credit_expires_at is null)
  or (p_credit_messages is not null and (p_credit_messages not between 1 and 100000000 or not isfinite(p_credit_started_at)
   or not isfinite(p_credit_expires_at) or p_credit_expires_at<=p_credit_started_at)) then raise exception 'EMAIL_OPERATIONS_INVALID'; end if;
 select * into r from private.appointment_management_runtime where singleton for update;
 if r.email_operations_revision<>p_expected_revision then raise exception 'EMAIL_OPERATIONS_CHANGED'; end if;
 update private.appointment_management_runtime set email_producer_enabled=p_producer_enabled,email_daily_limit=p_daily_limit,
  email_credit_messages=p_credit_messages,email_credit_started_at=p_credit_started_at,email_credit_expires_at=p_credit_expires_at,
  email_paused_until=case when p_lift_pause then null else email_paused_until end,
  email_pause_reason=case when p_lift_pause then null else email_pause_reason end,
  email_operations_revision=email_operations_revision+1
 where singleton;
 insert into public.audit_logs(user_id,action,entity_type,metadata)
 values(p_actor_id,'email.operations_changed','appointment_management_runtime',jsonb_build_object(
  'producer_enabled',p_producer_enabled,'daily_limit',p_daily_limit,'credit_messages',p_credit_messages,
  'credit_started_at',p_credit_started_at,'credit_expires_at',p_credit_expires_at,'lifted_pause',p_lift_pause and r.email_paused_until is not null));
 return public.operator_get_email_operations(null);
end $$;

revoke all on function public.operator_get_email_operations(timestamptz) from public,anon,authenticated;
revoke all on function public.operator_set_email_operations(uuid,bigint,boolean,integer,integer,timestamptz,timestamptz,boolean) from public,anon,authenticated;
grant execute on function public.operator_get_email_operations(timestamptz) to service_role;
grant execute on function public.operator_set_email_operations(uuid,bigint,boolean,integer,integer,timestamptz,timestamptz,boolean) to service_role;

notify pgrst,'reload schema';
commit;
