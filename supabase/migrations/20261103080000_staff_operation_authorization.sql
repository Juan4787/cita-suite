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

commit;
