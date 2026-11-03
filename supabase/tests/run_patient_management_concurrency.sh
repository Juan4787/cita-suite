#!/usr/bin/env bash
# Two controlled connections; remote owned disposable PostgreSQL only.
set -Eeuo pipefail
database_url="${SUPABASE_TEST_DB_URL:?An explicit disposable PostgreSQL URL is required.}"
case "$database_url" in
 postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;;
 *) echo 'Refusing patient management races outside disposable loopback PostgreSQL.' >&2; exit 2 ;;
esac
business_id='e3100000-0000-4000-8000-000000000001'
owner_id='e3100000-0000-4000-8000-000000000002'
professional_id='e3100000-0000-4000-8000-000000000003'
service_id='e3100000-0000-4000-8000-000000000004'
slug='e2e-patient-management-race'
task_directory=$(mktemp -d)
holder_pid=''
psql_owned() { psql "$database_url" -X -v ON_ERROR_STOP=1 -qAt "$@"; }
previous_deposit=$(psql_owned -c 'select enabled from private.deposit_automation where singleton;')
previous_runtime=$(psql_owned -c "select reschedule_enabled||'|'||email_producer_enabled from private.appointment_management_runtime where singleton;")
[[ "$previous_deposit" =~ ^[tf]$ && "$previous_runtime" =~ ^(true|false)\|(true|false)$ ]]
cleanup() {
 local status=$?
 trap - EXIT
 if [[ -n "$holder_pid" ]]; then kill "$holder_pid" 2>/dev/null || true; wait "$holder_pid" 2>/dev/null || true; fi
 if ! psql_owned <<SQL
update private.deposit_automation set enabled='$previous_deposit'::boolean;
update private.appointment_management_runtime set reschedule_enabled='${previous_runtime%|*}'::boolean,email_producer_enabled='${previous_runtime#*|}'::boolean;
drop schema if exists patient_management_race cascade;
delete from public.appointments a using public.businesses b where a.business_id=b.id and b.id='$business_id' and b.slug='$slug';
delete from public.businesses where id='$business_id' and slug='$slug';
delete from auth.users where id='$owner_id' and email='patient-management-race@example.test';
SQL
 then status=1; fi
 rm -r -- "$task_directory"
 exit "$status"
}
trap cleanup EXIT
on_error() {
 local status=$? line=$1
 echo "Patient management race failed at line $line, status $status." >&2
 for log in "$task_directory"/*.log; do [[ ! -f "$log" ]] || cat "$log" >&2; done
}
trap 'on_error $LINENO' ERR
psql_owned <<SQL
create schema patient_management_race;
create table patient_management_race.requests(label text primary key,appointment_id uuid,token text,operation_id uuid,
 revision text,target timestamptz,availability_revision bigint,terms jsonb,deposit_revision bigint);
create table patient_management_race.signals(label text primary key);
insert into auth.users(id,email) values('$owner_id','patient-management-race@example.test');
insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled,max_booking_days_ahead)
 values('$business_id','Synthetic management race','$slug','other','UTC',true,365);
update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
 paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='$business_id';
insert into public.business_users(business_id,user_id,role,status,accepted_at) values('$business_id','$owner_id','owner','active',now());
insert into public.professionals(id,business_id,name,is_public) values('$professional_id','$business_id','Synthetic management professional',true);
insert into public.services(id,business_id,name,duration_minutes,is_public) values('$service_id','$business_id','Synthetic management service',60,true);
insert into public.professional_services(business_id,professional_id,service_id) values('$business_id','$professional_id','$service_id');
insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details)
 values('$business_id',true,true,'fixed',40000,'Synthetic transfer');
update private.deposit_automation set enabled=true;
update private.appointment_management_runtime set reschedule_enabled=true,email_producer_enabled=true;
SQL
psql_owned <<'SQL'
create function patient_management_race.prepare(p_label text,p_due boolean default false,p_target timestamptz default null) returns void language plpgsql as $$
declare a uuid; patient uuid; starts timestamptz; b uuid:='e3100000-0000-4000-8000-000000000001'; begin
 starts:=date_trunc('hour',now())+make_interval(days=>20+(select count(*)::integer from patient_management_race.requests));
 insert into public.patients(owner_id,business_id,full_name) values('e3100000-0000-4000-8000-000000000002',b,'Synthetic management '||p_label) returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
 service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,'e3100000-0000-4000-8000-000000000003','e3100000-0000-4000-8000-000000000004',starts,starts+interval '1 hour',
 'reserved','manual','Synthetic service','Synthetic professional',60) returning id into a;
 update public.appointment_management_states set terms_acknowledged=true,require_deposit_on_reschedule=true,
  previous_deposit_disposition='forfeit',accepted_at=now(),accepted_policy_revision=1 where appointment_id=a;
 if p_due then update public.appointment_deposits set due_at=clock_timestamp()-interval '1 hour',auto_cancel=true,revision=revision+1 where appointment_id=a; end if;
 insert into patient_management_race.requests
 select p_label,a,public.issue_appointment_management_capability(b,a,1),gen_random_uuid(),private.appointment_semantic_revision(b,a),
  coalesce(p_target,starts+interval '6 hours'),(select booking_availability_revision from public.businesses where id=b),
  private.appointment_reschedule_financial_terms(b,a,coalesce(p_target,starts+interval '6 hours'),clock_timestamp()),
  (select revision from public.appointment_deposits where appointment_id=a);
end $$;
create function patient_management_race.act(p_label text,p_action text default 'reschedule',p_new_operation boolean default false) returns jsonb language plpgsql as $$
declare r patient_management_race.requests; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 return public.apply_patient_appointment_management(r.token,false,case when p_new_operation then gen_random_uuid() else r.operation_id end,
  r.revision,p_action,case when p_action='reschedule' then r.target end,
  case when p_action='reschedule' then r.availability_revision end,case when p_action='reschedule' then r.terms end);
end $$;
create function patient_management_race.pay(p_label text) returns void language plpgsql as $$
declare r patient_management_race.requests; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 perform set_config('request.jwt.claim.sub','e3100000-0000-4000-8000-000000000002',true);
 perform public.set_appointment_deposit('e3100000-0000-4000-8000-000000000001',r.appointment_id,'paid',r.deposit_revision,null);
 perform set_config('request.jwt.claim.sub','',true);
end $$;
create function patient_management_race.assert_state(p_label text,p_status text,p_deposit text,p_moved boolean,p_moves integer) returns void language plpgsql as $$
declare r patient_management_race.requests; a public.appointments; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 select * into strict a from public.appointments where id=r.appointment_id;
 if a.status is distinct from p_status or (select status from public.appointment_deposits where appointment_id=a.id) is distinct from p_deposit
  or (a.starts_at=r.target) is distinct from p_moved
  or (select count(*) from private.appointment_email_events where appointment_id=a.id and purpose='reschedule_receipt')<>p_moves
 then raise exception 'PATIENT_RACE_PARTIAL_STATE_%',p_label; end if;
end $$;
SQL
deadlocks_before=$(psql_owned -c 'select deadlocks from pg_stat_database where datname=current_database();')
wait_marker() {
 for attempt in {1..240}; do
  if rg_marker=$(sed -n '/^PATIENT_HOLDER_READY$/p' "$task_directory/holder.log"); [[ -n "$rg_marker" ]]; then return; fi
  if ! kill -0 "$holder_pid" 2>/dev/null; then break; fi
  sleep 0.025
 done
 cat "$task_directory/holder.log" >&2; return 1
}
hold_until_waiter() {
 cat <<SQL
do \$\$ begin
 for attempt in 1..240 loop
  perform pg_stat_clear_snapshot();
  if exists(select 1 from pg_stat_activity a where a.application_name='patient-management-other' and a.wait_event_type='Lock'
   and pg_backend_pid()=any(pg_blocking_pids(a.pid))) then return; end if;
  perform pg_sleep(0.025);
 end loop;
 raise exception 'PATIENT_RACE_OTHER_SIDE_DID_NOT_WAIT';
end \$\$;
SQL
}
race() {
 local name=$1 first=$2 second=$3 expected_error=${4:-}
 echo "Patient management race: $name" >&2
 psql_owned >"$task_directory/holder.log" 2>&1 <<SQL &
set statement_timeout='12s';
begin;
$first
\echo PATIENT_HOLDER_READY
$(hold_until_waiter)
commit;
SQL
 holder_pid=$!
 wait_marker
 local status=0
 PGAPPNAME=patient-management-other psql_owned >"$task_directory/other.log" 2>&1 <<SQL || status=$?
set statement_timeout='12s';
$second
SQL
 wait "$holder_pid"; holder_pid=''
 if [[ -n "$expected_error" ]]; then
  if [[ "$status" == 0 ]] || ! grep -Fq "$expected_error" "$task_directory/other.log"; then cat "$task_directory/other.log" >&2; return 1; fi
 elif [[ "$status" != 0 ]]; then cat "$task_directory/other.log" >&2; return 1;
 fi
 echo "PASS: $name (overlap verified by PostgreSQL lock wait)."
}

psql_owned -c "select patient_management_race.prepare('duplicate');"
race duplicate "select patient_management_race.act('duplicate');" "select patient_management_race.act('duplicate');"
psql_owned -c "select patient_management_race.assert_state('duplicate','reserved','pending',true,1);"

psql_owned -c "select patient_management_race.prepare('move_cancel');"
race move_before_cancel "select patient_management_race.act('move_cancel');" "select patient_management_race.act('move_cancel','cancel',true);" APPOINTMENT_MANAGEMENT_CHANGED
psql_owned -c "select patient_management_race.assert_state('move_cancel','reserved','pending',true,1);"
psql_owned -c "select patient_management_race.prepare('cancel_move');"
race cancel_before_move "select patient_management_race.act('cancel_move','cancel');" "select patient_management_race.act('cancel_move');" APPOINTMENT_MANAGEMENT_CHANGED
psql_owned -c "select patient_management_race.assert_state('cancel_move','cancelled','pending',false,0);"

psql_owned -c "select patient_management_race.prepare('pay_move');"
race pay_before_move "select patient_management_race.pay('pay_move');" "select patient_management_race.act('pay_move');" APPOINTMENT_MANAGEMENT_CHANGED
psql_owned -c "select patient_management_race.assert_state('pay_move','confirmed','paid',false,0);"
psql_owned -c "select patient_management_race.prepare('move_pay');"
race move_before_stale_pay "select patient_management_race.act('move_pay');" "select patient_management_race.pay('move_pay');" DEPOSIT_CHANGED
psql_owned -c "select patient_management_race.assert_state('move_pay','reserved','pending',true,1);"

psql_owned -c "select patient_management_race.prepare('expiry_move',true);"
race expiry_before_move "select private.expire_unpaid_deposits(clock_timestamp(),100);" "select patient_management_race.act('expiry_move');" APPOINTMENT_MANAGEMENT_CHANGED
psql_owned -c "select patient_management_race.assert_state('expiry_move','cancelled','expired',false,0);"

psql_owned -c "select patient_management_race.prepare('config_move');"
race configuration_before_move "update public.services set duration_minutes=90 where id='$service_id';" "select patient_management_race.act('config_move');" APPOINTMENT_AVAILABILITY_CHANGED
psql_owned -c "select patient_management_race.assert_state('config_move','reserved','pending',false,0);"
psql_owned -c "update public.services set duration_minutes=60 where id='$service_id'; select patient_management_race.prepare('move_config');"
race move_before_configuration "select patient_management_race.act('move_config');" "update public.services set duration_minutes=90 where id='$service_id';"
psql_owned -c "select patient_management_race.assert_state('move_config','reserved','pending',true,1); update public.services set duration_minutes=60 where id='$service_id';"

psql_owned -c "select patient_management_race.prepare('slot_a',false,date_trunc('hour',now())+interval '120 days'); select patient_management_race.prepare('slot_b',false,date_trunc('hour',now())+interval '120 days');"
race overlapping_target "select patient_management_race.act('slot_a');" "select patient_management_race.act('slot_b');" 'exclusion constraint'
psql_owned -c "select patient_management_race.assert_state('slot_a','reserved','pending',true,1); select patient_management_race.assert_state('slot_b','reserved','pending',false,0);"

# Inverse expiry order: the worker must SKIP the held appointment instead of
# waiting. A separate signal after the worker exits proves overlap without a
# timing-only sleep or a permanently open third connection.
psql_owned -c "select patient_management_race.prepare('move_expiry',true);"
psql_owned >"$task_directory/holder.log" 2>&1 <<'SQL' &
set statement_timeout='12s';
begin;
select patient_management_race.act('move_expiry');
\echo PATIENT_HOLDER_READY
do $$ begin
 for attempt in 1..240 loop
  if exists(select 1 from patient_management_race.signals where label='expiry_finished') then return; end if;
  perform pg_sleep(0.025);
 end loop;
 raise exception 'PATIENT_RACE_EXPIRY_DID_NOT_FINISH';
end $$;
commit;
SQL
holder_pid=$!
wait_marker
psql_owned >"$task_directory/other.log" 2>&1 <<'SQL'
set statement_timeout='1s';
select private.expire_unpaid_deposits(clock_timestamp(),100);
SQL
kill -0 "$holder_pid"
psql_owned -c "insert into patient_management_race.signals values('expiry_finished');"
wait "$holder_pid"; holder_pid=''
psql_owned -c "select patient_management_race.assert_state('move_expiry','reserved','pending',true,1);"
echo 'PASS: expiry skips the appointment held by a completed uncommitted patient move.'
deadlocks_after=$(psql_owned -c 'select deadlocks from pg_stat_database where datname=current_database();')
[[ "$deadlocks_before" == "$deadlocks_after" ]]
echo 'PASS: ten controlled patient-management races; no PostgreSQL deadlock.'
