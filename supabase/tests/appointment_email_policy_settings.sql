-- Preferences are separate from existing consent/money and sender readiness.
begin;
select extensions.plan(14);
create temporary table email_policy_fixture(label text primary key,id uuid not null);
grant select on email_policy_fixture to authenticated;
create function pg_temp.epid(label text) returns uuid language sql as $$select id from email_policy_fixture f where f.label=$1$$;
create function pg_temp.epsettings() returns jsonb language sql as $$select jsonb_build_object(
 'email_enabled',false,'require_email',true,'show_cancel',false,'show_reschedule',true,
 'require_deposit_on_reschedule',true,'previous_deposit_disposition','forfeit')$$;
do $$ declare b uuid:=gen_random_uuid(); owner_id uuid:=gen_random_uuid(); reception uuid:=gen_random_uuid();
 admin_id uuid:=gen_random_uuid(); other_user uuid:=gen_random_uuid(); begin
 insert into auth.users(id,email) select u,'email-policy-'||u||'@example.test' from unnest(array[owner_id,reception,admin_id,other_user]) u;
 insert into public.businesses(id,name,slug,industry) values(b,'Synthetic email preferences',b::text,'other');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values
  (b,owner_id,'owner','active',now()),(b,reception,'reception','active',now()),(b,admin_id,'admin','active',now());
 insert into email_policy_fixture values('business',b),('owner',owner_id),('admin',admin_id),('reception',reception),('outsider',other_user);
end $$;
select extensions.ok((select email_enabled and require_email and show_cancel and show_reschedule
 and require_deposit_on_reschedule and previous_deposit_disposition='forfeit' and not sender_verified
 from public.appointment_email_policies where business_id=pg_temp.epid('business')),'Defaults enable email, required contact and contextual actions while sender remains unverified');
select set_config('request.jwt.claim.sub',pg_temp.epid('owner')::text,true);
set local role authenticated;
select extensions.is(public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings(),1),2::bigint,'Owner can disable sending independently of required email');
select extensions.is(public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings(),1),2::bigint,'Retry after a lost reply recovers the same current preference values');
select extensions.throws_ok($$select public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings()||'{"require_email":false}',1)$$,'P0001','EMAIL_POLICY_CHANGED','Stale different settings cannot overwrite another save');
select extensions.throws_ok($$select public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings()||'{"sender_verified":true}',2)$$,'P0001','EMAIL_POLICY_INVALID','Configuration cannot forge verified sender readiness');
select extensions.throws_ok($$select public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings()||'{"email_enabled":"false"}',2)$$,'P0001','EMAIL_POLICY_INVALID','Boolean strings are not unchecked preferences');
select extensions.throws_ok($$select public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings()-'require_email',2)$$,'P0001','EMAIL_POLICY_INVALID','A missing field never becomes a default or an implicit consent');
reset role;
select extensions.ok((select not email_enabled and require_email and not sender_verified and revision=2 and updated_by=pg_temp.epid('owner')
 from public.appointment_email_policies where business_id=pg_temp.epid('business'))
 and (select count(*) from public.audit_logs where entity_id=pg_temp.epid('business') and action='business.appointment_email_policy_updated')=1,
 'One persisted update and one audit survive a retry, with readiness unchanged');
select set_config('request.jwt.claim.sub',pg_temp.epid('reception')::text,true);
select extensions.throws_ok($$select public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings(),2)$$,'P0001','EMAIL_POLICY_FORBIDDEN','Reception cannot configure even when submitting current values');
select set_config('request.jwt.claim.sub',pg_temp.epid('outsider')::text,true);
select extensions.throws_ok($$select public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings(),2)$$,'P0001','EMAIL_POLICY_FORBIDDEN','An actor outside the practice cannot recover or change its settings');
select set_config('request.jwt.claim.sub',pg_temp.epid('admin')::text,true);
select extensions.is(public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings()||'{"require_email":false}',2),3::bigint,'Administration may relax public email without enabling deliveries');
create function pg_temp.reject_email_policy_audit() returns trigger language plpgsql as $$begin
 if new.entity_id=pg_temp.epid('business') and new.action='business.appointment_email_policy_updated' then raise exception 'SYNTHETIC_EMAIL_AUDIT_FAILURE'; end if;
 return new; end$$;
create trigger zz_reject_email_policy_audit after insert on public.audit_logs for each row execute function pg_temp.reject_email_policy_audit();
do $$ declare before_policy jsonb; audit_count bigint; begin
 select to_jsonb(p) into before_policy from public.appointment_email_policies p where business_id=pg_temp.epid('business');
 select count(*) into audit_count from public.audit_logs where entity_id=pg_temp.epid('business');
 begin perform public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings(),3); raise exception 'EMAIL_AUDIT_FAILURE_IGNORED';
 exception when others then if sqlerrm is distinct from 'SYNTHETIC_EMAIL_AUDIT_FAILURE' then raise; end if; end;
 if before_policy is distinct from (select to_jsonb(p) from public.appointment_email_policies p where business_id=pg_temp.epid('business'))
  or audit_count<>(select count(*) from public.audit_logs where entity_id=pg_temp.epid('business')) then raise exception 'EMAIL_POLICY_PARTIAL_EFFECT'; end if;
end $$;
drop trigger zz_reject_email_policy_audit on public.audit_logs;
select extensions.pass('Audit failure rolls back the entire preference update');
create function pg_temp.expire_email_policy_access() returns trigger language plpgsql as $$begin
 if new.entity_id=pg_temp.epid('business') and new.action='business.appointment_email_policy_updated' then
  update public.business_subscriptions set is_permanent=false,paid_until=clock_timestamp()-interval '1 second' where business_id=pg_temp.epid('business');
 end if; return new; end$$;
create trigger zz_expire_email_policy_access after insert on public.audit_logs for each row execute function pg_temp.expire_email_policy_access();
do $$ declare before_policy jsonb; audit_count bigint; begin
 select to_jsonb(p) into before_policy from public.appointment_email_policies p where business_id=pg_temp.epid('business');
 select count(*) into audit_count from public.audit_logs where entity_id=pg_temp.epid('business');
 begin perform public.save_appointment_email_policy(pg_temp.epid('business'),pg_temp.epsettings(),3); raise exception 'EXPIRED_EMAIL_POLICY_COMMITTED';
 exception when others then if sqlerrm is distinct from 'EMAIL_POLICY_FORBIDDEN' then raise; end if; end;
 if before_policy is distinct from (select to_jsonb(p) from public.appointment_email_policies p where business_id=pg_temp.epid('business'))
  or audit_count<>(select count(*) from public.audit_logs where entity_id=pg_temp.epid('business'))
  or not (select is_permanent from public.business_subscriptions where business_id=pg_temp.epid('business')) then raise exception 'EMAIL_AUTHORITY_PARTIAL_EFFECT'; end if;
end $$;
drop trigger zz_expire_email_policy_access on public.audit_logs;
select extensions.pass('Losing commercial authority before the final decision rolls back settings, audit and injected expiration');
select extensions.ok(has_function_privilege('authenticated','public.save_appointment_email_policy(uuid,jsonb,bigint)','EXECUTE')
 and not has_function_privilege('anon','public.save_appointment_email_policy(uuid,jsonb,bigint)','EXECUTE')
 and not has_function_privilege('service_role','public.save_appointment_email_policy(uuid,jsonb,bigint)','EXECUTE')
 and not has_table_privilege('authenticated','public.appointment_email_policies','UPDATE'),
 'Only an authenticated authorized operator can use the command; no raw write or backend actor substitution');
select * from extensions.finish();
rollback;
