#!/usr/bin/env bash
# OP02: actual expiry/revocation while a staff command waits on PostgreSQL.
# Owned loopback disposable database only; never production or provider calls.
set -Eeuo pipefail
staff_database_url="${SUPABASE_TEST_DB_URL:?An explicit disposable PostgreSQL URL is required.}"
case "$staff_database_url" in
 postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;;
 *) echo 'Refusing staff authorization races outside disposable loopback PostgreSQL.' >&2; exit 2 ;;
esac
staff_business='e3200000-0000-4000-8000-000000000001'
staff_owner='e3200000-0000-4000-8000-000000000002'
staff_support='e3200000-0000-4000-8000-000000000003'
staff_directory=$(mktemp -d)
staff_holder=''
export PGOPTIONS='-c lock_timeout=7000 -c statement_timeout=12000'
staff_psql=(psql "$staff_database_url" -X -v ON_ERROR_STOP=1 -qAt)
staff_previous_deposit=$("${staff_psql[@]}" -c 'select enabled from private.deposit_automation where singleton;')
[[ "$staff_previous_deposit" =~ ^[tf]$ ]]
cleanup_staff() {
 local status=$?
 trap - EXIT
 if [[ -n "$staff_holder" ]]; then kill "$staff_holder" 2>/dev/null || true; wait "$staff_holder" 2>/dev/null || true; fi
 if ! "${staff_psql[@]}" <<SQL
update private.deposit_automation set enabled='$staff_previous_deposit'::boolean;
drop schema if exists staff_authorization_race cascade;
delete from public.appointments where business_id='$staff_business';
delete from public.businesses where id='$staff_business' and slug='e2e-staff-authorization-race';
delete from public.account_assistance_support_users where user_id='$staff_support' and email='staff-authorization-support@example.test';
delete from auth.users where (id='$staff_owner' and email='staff-authorization-owner@example.test') or (id='$staff_support' and email='staff-authorization-support@example.test');
SQL
 then status=1; fi
 rm -r -- "$staff_directory"
 exit "$status"
}
trap cleanup_staff EXIT
trap 'status=$?; echo "Staff authorization race failed at line $LINENO, status $status." >&2; for log in "$staff_directory"/*.log; do [[ ! -f "$log" ]] || cat "$log" >&2; done' ERR
"${staff_psql[@]}" <<SQL
create schema staff_authorization_race;
create table staff_authorization_race.requests(label text primary key,appointment_id uuid,operation_id uuid,revision text);
insert into auth.users(id,email) values('$staff_owner','staff-authorization-owner@example.test'),('$staff_support','staff-authorization-support@example.test');
insert into public.businesses(id,name,slug,industry,timezone) values('$staff_business','Synthetic staff authorization','e2e-staff-authorization-race','other','UTC');
update public.business_subscriptions set is_permanent=true,commercial_access_enabled=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='$staff_business';
insert into public.business_users(business_id,user_id,role,status,accepted_at) values('$staff_business','$staff_owner','owner','active',now());
insert into public.account_assistance_support_users(user_id,email,enabled) values('$staff_support','staff-authorization-support@example.test',true);
insert into public.professionals(id,business_id,name) values('e3200000-0000-4000-8000-000000000004','$staff_business','Synthetic staff professional');
insert into public.services(id,business_id,name,duration_minutes) values('e3200000-0000-4000-8000-000000000005','$staff_business','Synthetic staff service',30);
insert into public.professional_services(business_id,professional_id,service_id) values('$staff_business','e3200000-0000-4000-8000-000000000004','e3200000-0000-4000-8000-000000000005');
insert into public.deposit_policies(business_id,enabled,amount_mode,fixed_amount,transfer_details) values('$staff_business',true,'fixed',40000,'Synthetic transfer');
update private.deposit_automation set enabled=true;
SQL
"${staff_psql[@]}" <<'SQL'
create function staff_authorization_race.prepare(p_label text) returns void language plpgsql as $$
declare b uuid:='e3200000-0000-4000-8000-000000000001'; a uuid; patient uuid; starts timestamptz; begin
 insert into public.patients(business_id,owner_id,full_name) values(b,'e3200000-0000-4000-8000-000000000002','Synthetic '||p_label) returning id into patient;
 starts:=date_trunc('hour',clock_timestamp())+make_interval(days=>20+(select count(*)::integer from staff_authorization_race.requests));
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,'e3200000-0000-4000-8000-000000000004','e3200000-0000-4000-8000-000000000005',starts,starts+interval '30 minutes','reserved','manual','Synthetic staff service','Synthetic staff professional',30) returning id into a;
 insert into staff_authorization_race.requests values(p_label,a,gen_random_uuid(),private.appointment_semantic_revision(b,a));
 delete from public.account_assistance_grants where business_id=b;
 insert into public.account_assistance_grants(business_id,requested_by_user_id,support_user_id,starts_at,expires_at)
 values(b,'e3200000-0000-4000-8000-000000000002','e3200000-0000-4000-8000-000000000003',clock_timestamp()-interval '1 minute',clock_timestamp()+interval '3 seconds');
end $$;
create function staff_authorization_race.act(p_label text,p_action text) returns void language plpgsql as $$
declare r staff_authorization_race.requests; b uuid:='e3200000-0000-4000-8000-000000000001'; settings jsonb; begin
 perform set_config('request.jwt.claim.sub','e3200000-0000-4000-8000-000000000003',true);
 select * into strict r from staff_authorization_race.requests where label=p_label;
 if p_action='revoke' then perform public.revoke_appointment_management_access(b,r.appointment_id,r.operation_id,r.revision);
 elsif p_action='pay' then perform public.set_appointment_deposit(b,r.appointment_id,'paid',1,null);
 elsif p_action='remind' then perform public.open_appointment_deposit_reminder(b,r.appointment_id,false);
 elsif p_action='policy' then
  settings:=jsonb_build_object('enabled',true,'auto_cancel_enabled',false,'amount_mode','fixed','fixed_amount',50000,'percentage',null,
   'request_days',7,'deadline_hours',48,'min_payment_hours',24,'transfer_details','Changed synthetic transfer','applies_to_manual',true,'excluded_service_ids','[]'::jsonb);
  perform public.save_deposit_policy(b,settings,1);
 else raise exception 'STAFF_RACE_INVALID_ACTION'; end if;
end $$;
create function staff_authorization_race.assert_unchanged(p_label text) returns void language plpgsql as $$
declare r staff_authorization_race.requests; begin
 select * into strict r from staff_authorization_race.requests where label=p_label;
 if (select status from public.appointments where id=r.appointment_id) is distinct from 'reserved'
  or not exists(select 1 from public.appointment_deposits where appointment_id=r.appointment_id and status='pending' and revision=1 and reminder_opened_at is null)
  or not exists(select 1 from public.appointment_management_states where appointment_id=r.appointment_id and generation=1 and legacy_management_allowed)
  or exists(select 1 from private.appointment_management_operations where appointment_id=r.appointment_id)
  or exists(select 1 from public.appointment_deposit_requirements where appointment_id=r.appointment_id and status='paid')
  or exists(select 1 from public.audit_logs where entity_id=r.appointment_id and action in ('appointment.management_access_revoked','appointment.deposit_paid','appointment.deposit_reminder_opened'))
  or not exists(select 1 from public.deposit_policies where business_id='e3200000-0000-4000-8000-000000000001' and revision=1 and fixed_amount=40000)
 then raise exception 'STAFF_RACE_PARTIAL_STATE'; end if;
end $$;
SQL
staff_deadlocks=$("${staff_psql[@]}" -c 'select deadlocks from pg_stat_database where datname=current_database();')
for staff_action in revoke pay remind policy; do
 "${staff_psql[@]}" -c "select staff_authorization_race.prepare('$staff_action');"
 staff_lock="select id from public.appointments where id=(select appointment_id from staff_authorization_race.requests where label='$staff_action') for no key update;"
 [[ "$staff_action" != policy ]] || staff_lock="select business_id from public.deposit_policies where business_id='$staff_business' for no key update;"
 "${staff_psql[@]}" >"$staff_directory/holder.log" 2>&1 <<SQL &
begin;
$staff_lock
\echo STAFF_HOLDER_READY
do \$\$ begin
 for attempt in 1..240 loop
  perform pg_stat_clear_snapshot();
  if exists(select 1 from pg_stat_activity a where a.application_name='staff-authorization-other' and a.wait_event_type='Lock' and pg_backend_pid()=any(pg_blocking_pids(a.pid))) then
   perform pg_sleep(greatest(extract(epoch from ((select expires_at from public.account_assistance_grants where business_id='$staff_business')-clock_timestamp())),0)+0.025);
   return;
  end if;
  perform pg_sleep(0.025);
 end loop;
 raise exception 'STAFF_RACE_OTHER_SIDE_DID_NOT_WAIT';
end \$\$;
commit;
SQL
 staff_holder=$!
 staff_ready=false
 for attempt in {1..240}; do
  if grep -Fq STAFF_HOLDER_READY "$staff_directory/holder.log"; then staff_ready=true; break; fi
  if ! kill -0 "$staff_holder" 2>/dev/null; then break; fi
  sleep 0.025
 done
 [[ "$staff_ready" == true ]]
 staff_result=0
 PGAPPNAME=staff-authorization-other "${staff_psql[@]}" -c "select staff_authorization_race.act('$staff_action','$staff_action');" >"$staff_directory/actor.log" 2>&1 || staff_result=$?
 wait "$staff_holder"; staff_holder=''
 staff_error=DEPOSIT_FORBIDDEN
 [[ "$staff_action" != revoke ]] || staff_error=APPOINTMENT_MANAGEMENT_FORBIDDEN
 [[ "$staff_action" != policy ]] || staff_error=DEPOSIT_POLICY_FORBIDDEN
 if [[ "$staff_result" == 0 ]] || ! grep -Fq "$staff_error" "$staff_directory/actor.log"; then
  cat "$staff_directory/actor.log" >&2; echo "FAIL: expired help executed $staff_action after a verified lock wait." >&2; exit 1
 fi
 "${staff_psql[@]}" -c "select staff_authorization_race.assert_unchanged('$staff_action');"
 echo "PASS: expired help rejects $staff_action after a verified lock wait, with no partial state."
done
[[ $("${staff_psql[@]}" -c 'select deadlocks from pg_stat_database where datname=current_database();') == "$staff_deadlocks" ]]
echo 'PASS: staff authorization lock waits did not increase deadlocks.'
