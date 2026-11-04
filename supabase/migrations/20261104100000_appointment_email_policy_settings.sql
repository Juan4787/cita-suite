-- E3 preferences. This command changes no existing appointment, money, sender
-- verification or delivery. New economic terms still require their own consent.
begin;
create function public.save_appointment_email_policy(p_business_id uuid,p_settings jsonb,p_expected_revision bigint)
returns bigint language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare current_policy public.appointment_email_policies; next_policy public.appointment_email_policies;
begin
 if private.business_operation_actor(p_business_id,array['owner','admin'],auth.uid()) is null then
  raise exception 'EMAIL_POLICY_FORBIDDEN';
 end if;
 if p_expected_revision is null or p_expected_revision<1 or jsonb_typeof(p_settings) is distinct from 'object'
  or octet_length(p_settings::text)>2048 then raise exception 'EMAIL_POLICY_INVALID'; end if;
 if (select count(*) from jsonb_object_keys(p_settings))<>6
  or exists(select 1 from unnest(array['email_enabled','require_email','show_cancel','show_reschedule','require_deposit_on_reschedule']) k
   where jsonb_typeof(p_settings->k) is distinct from 'boolean')
  or jsonb_typeof(p_settings->'previous_deposit_disposition') is distinct from 'string'
  or (p_settings->>'previous_deposit_disposition' in('credit','forfeit')) is not true then
  raise exception 'EMAIL_POLICY_INVALID';
 end if;
 -- No parent rows are visited: agenda commands may take this row in SHARE mode.
 -- In particular, changing preferences cannot reinterpret accepted obligations.
 select * into current_policy from public.appointment_email_policies p where p.business_id=p_business_id for update;
 if not found then raise exception 'EMAIL_POLICY_UNAVAILABLE'; end if;
 next_policy:=jsonb_populate_record(current_policy,p_settings);
 if p_expected_revision>current_policy.revision then raise exception 'EMAIL_POLICY_CHANGED'; end if;
 if row(current_policy.email_enabled,current_policy.require_email,current_policy.show_cancel,current_policy.show_reschedule,
   current_policy.require_deposit_on_reschedule,current_policy.previous_deposit_disposition)
  is not distinct from row(next_policy.email_enabled,next_policy.require_email,next_policy.show_cancel,next_policy.show_reschedule,
   next_policy.require_deposit_on_reschedule,next_policy.previous_deposit_disposition) then
  -- A lost response can be recovered if the intended settings are still current.
  -- This is value idempotency, not recovery of an economic command by its status.
  if private.business_operation_actor(p_business_id,array['owner','admin'],auth.uid()) is null then
   raise exception 'EMAIL_POLICY_FORBIDDEN'; end if;
  return current_policy.revision;
 end if;
 if p_expected_revision<>current_policy.revision then raise exception 'EMAIL_POLICY_CHANGED'; end if;
 update public.appointment_email_policies set email_enabled=next_policy.email_enabled,require_email=next_policy.require_email,
  show_cancel=next_policy.show_cancel,show_reschedule=next_policy.show_reschedule,
  require_deposit_on_reschedule=next_policy.require_deposit_on_reschedule,
  previous_deposit_disposition=next_policy.previous_deposit_disposition,
  revision=current_policy.revision+1,updated_at=clock_timestamp(),updated_by=auth.uid()
 where business_id=p_business_id;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),'business.appointment_email_policy_updated','business',p_business_id,
  jsonb_build_object('previous_revision',current_policy.revision,'revision',current_policy.revision+1,'settings',p_settings));
 -- Assistance and commercial access can expire while waiting or auditing.
 if private.business_operation_actor(p_business_id,array['owner','admin'],auth.uid()) is null then
  raise exception 'EMAIL_POLICY_FORBIDDEN'; end if;
 return current_policy.revision+1;
end $$;
revoke all on function public.save_appointment_email_policy(uuid,jsonb,bigint) from public,anon,authenticated,service_role;
grant execute on function public.save_appointment_email_policy(uuid,jsonb,bigint) to authenticated;
commit;
