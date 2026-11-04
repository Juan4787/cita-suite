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
# Direct client processes keep background $! equal to the actual client PID.
# A function wrapper inherits ERR inside redirected descriptors and can attempt
# to append a diagnostic log to itself; preserve the original caller's stderr.
export PGOPTIONS='-c lock_timeout=7000 -c statement_timeout=12000'
psql_command=(psql "$database_url" -X -v ON_ERROR_STOP=1 -qAt)
previous_uploads=$("${psql_command[@]}" -c 'select uploads_enabled from public.clinical_storage_budget where singleton;')
previous_deposit=$("${psql_command[@]}" -c 'select enabled from private.deposit_automation where singleton;')
previous_runtime=$("${psql_command[@]}" -c "select reschedule_enabled||'|'||email_producer_enabled from private.appointment_management_runtime where singleton;")
[[ "$previous_deposit" =~ ^[tf]$ && "$previous_runtime" =~ ^(true|false)\|(true|false)$ ]]
cleanup() {
 local status=$?
 trap - EXIT
 echo "Patient management cleanup begins, status $status." >&2
 if [[ -n "$holder_pid" ]]; then kill "$holder_pid" 2>/dev/null || true; wait "$holder_pid" 2>/dev/null || true; fi
 if ! "${psql_command[@]}" <<SQL
begin;
select private.clinical_budget_lock();
update public.clinical_storage_budget set uploads_enabled='$previous_uploads'::boolean where singleton;
update private.deposit_automation set enabled='$previous_deposit'::boolean;
update private.appointment_management_runtime set reschedule_enabled='${previous_runtime%|*}'::boolean,email_producer_enabled='${previous_runtime#*|}'::boolean;
drop schema if exists patient_management_race cascade;
update public.clinical_upload_slots s set expires_at=clock_timestamp()-interval '1 second'
 from public.businesses b where s.business_id=b.id and b.id='$business_id' and b.slug='$slug';
select private.release_expired_clinical_reservations();
delete from public.clinical_upload_slots s using public.businesses b where s.business_id=b.id and b.id='$business_id' and b.slug='$slug';
delete from public.patient_radiographs f using public.businesses b where f.business_id=b.id and b.id='$business_id' and b.slug='$slug';
delete from public.appointments a using public.businesses b where a.business_id=b.id and b.id='$business_id' and b.slug='$slug';
delete from public.businesses where id='$business_id' and slug='$slug';
delete from auth.users where id='$owner_id' and email='patient-management-race@example.test';
commit;
SQL
 then status=1; fi
 rm -r -- "$task_directory"
 echo "Patient management cleanup finished, status $status." >&2
 exit "$status"
}
trap cleanup EXIT
on_error() {
 local status=$? line=$1
 echo "Patient management race failed at line $line, status $status." >&2
 for log in "$task_directory"/*.log; do [[ ! -f "$log" ]] || cat "$log" >&2; done
}
trap 'on_error $LINENO' ERR
"${psql_command[@]}" <<SQL
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
"${psql_command[@]}" <<'SQL'
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
create function patient_management_race.staff_act(p_label text,p_action text default 'reschedule',p_new_operation boolean default false,
 p_replay_only boolean default false) returns jsonb language plpgsql as $$
declare r patient_management_race.requests; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 return public.apply_staff_appointment_management('e3100000-0000-4000-8000-000000000001','e3100000-0000-4000-8000-000000000002',
  r.appointment_id,case when p_new_operation then gen_random_uuid() else r.operation_id end,r.revision,p_action,
  case when p_action='reschedule' then r.target end,false,case when p_action='reschedule' then r.availability_revision end,null,p_replay_only);
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
deadlocks_before=$("${psql_command[@]}" -c 'select deadlocks from pg_stat_database where datname=current_database();')
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
 local name=$1 first=$2 second=$3 expected_error=${4:-} after_wait=${5:-}
 echo "Patient management race: $name" >&2
 "${psql_command[@]}" >"$task_directory/holder.log" 2>&1 <<SQL &
set statement_timeout='12s';
begin;
$first
\echo PATIENT_HOLDER_READY
$(hold_until_waiter)
$after_wait
commit;
SQL
 holder_pid=$!
 wait_marker
 local status=0
 PGAPPNAME=patient-management-other "${psql_command[@]}" >"$task_directory/other.log" 2>&1 <<SQL || status=$?
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

"${psql_command[@]}" -c "select patient_management_race.prepare('duplicate');"
race duplicate "select patient_management_race.act('duplicate');" "select patient_management_race.act('duplicate');"
"${psql_command[@]}" -c "select patient_management_race.assert_state('duplicate','reserved','pending',true,1);"

"${psql_command[@]}" -c "select patient_management_race.prepare('move_cancel');"
race move_before_cancel "select patient_management_race.act('move_cancel');" "select patient_management_race.act('move_cancel','cancel',true);" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('move_cancel','reserved','pending',true,1);"
"${psql_command[@]}" -c "select patient_management_race.prepare('cancel_move');"
race cancel_before_move "select patient_management_race.act('cancel_move','cancel');" "select patient_management_race.act('cancel_move','reschedule',true);" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('cancel_move','cancelled','pending',false,0);"

"${psql_command[@]}" -c "select patient_management_race.prepare('pay_move');"
race pay_before_move "select patient_management_race.pay('pay_move');" "select patient_management_race.act('pay_move');" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('pay_move','confirmed','paid',false,0);"
"${psql_command[@]}" -c "select patient_management_race.prepare('move_pay');"
race move_before_stale_pay "select patient_management_race.act('move_pay');" "select patient_management_race.pay('move_pay');" DEPOSIT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('move_pay','reserved','pending',true,1);"

"${psql_command[@]}" -c "select patient_management_race.prepare('expiry_move',true);"
race expiry_before_move "select private.expire_unpaid_deposits(clock_timestamp(),100);" "select patient_management_race.act('expiry_move');" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('expiry_move','cancelled','expired',false,0);"

"${psql_command[@]}" -c "select patient_management_race.prepare('config_move');"
race configuration_before_move "update public.services set duration_minutes=90 where id='$service_id';" "select patient_management_race.act('config_move');" APPOINTMENT_AVAILABILITY_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('config_move','reserved','pending',false,0);"
"${psql_command[@]}" -c "update public.services set duration_minutes=60 where id='$service_id'; select patient_management_race.prepare('move_config');"
race move_before_configuration "select patient_management_race.act('move_config');" "update public.services set duration_minutes=90 where id='$service_id';"
"${psql_command[@]}" -c "select patient_management_race.assert_state('move_config','reserved','pending',true,1); update public.services set duration_minutes=60 where id='$service_id';"

"${psql_command[@]}" -c "select patient_management_race.prepare('slot_a',false,date_trunc('hour',now())+interval '120 days'); select patient_management_race.prepare('slot_b',false,date_trunc('hour',now())+interval '120 days');"
race overlapping_target "select patient_management_race.act('slot_a');" "select patient_management_race.act('slot_b');" 'exclusion constraint'
"${psql_command[@]}" -c "select patient_management_race.assert_state('slot_a','reserved','pending',true,1); select patient_management_race.assert_state('slot_b','reserved','pending',false,0);"

# A switch change still serializes, independently from heartbeat-only writes.
"${psql_command[@]}" -c "select patient_management_race.prepare('pause_move');"
race financial_pause_before_move "update private.deposit_automation set enabled=false;" "select patient_management_race.act('pause_move');" APPOINTMENT_RESCHEDULE_UNAVAILABLE
"${psql_command[@]}" -c "select patient_management_race.assert_state('pause_move','reserved','pending',false,0); update private.deposit_automation set enabled=true; select patient_management_race.prepare('move_pause');"
race move_before_financial_pause "select patient_management_race.act('move_pause');" "update private.deposit_automation set enabled=false;"
"${psql_command[@]}" -c "select patient_management_race.assert_state('move_pause','reserved','pending',true,1); update private.deposit_automation set enabled=true;"

# Inverse expiry order: the worker must SKIP the held appointment instead of
# waiting. A separate signal after the worker exits proves overlap without a
# timing-only sleep or a permanently open third connection.
echo 'Patient management inverse expiry: prepare.' >&2
"${psql_command[@]}" -c "select patient_management_race.prepare('move_expiry',true);"
echo 'Patient management inverse expiry: start holder.' >&2
"${psql_command[@]}" >"$task_directory/holder.log" 2>&1 <<'SQL' &
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
echo 'Patient management inverse expiry: await holder marker.' >&2
wait_marker
echo 'Patient management inverse expiry: worker begins while holder is open.' >&2
"${psql_command[@]}" >"$task_directory/other.log" 2>&1 <<'SQL'
set statement_timeout='1s';
select private.expire_unpaid_deposits(clock_timestamp(),100);
SQL
echo 'Patient management inverse expiry: worker returned.' >&2
kill -0 "$holder_pid"
"${psql_command[@]}" -c "insert into patient_management_race.signals values('expiry_finished');"
echo 'Patient management inverse expiry: signal committed; await holder.' >&2
wait "$holder_pid"; holder_pid=''
echo 'Patient management inverse expiry: holder returned; assert state.' >&2
"${psql_command[@]}" -c "select patient_management_race.assert_state('move_expiry','reserved','pending',true,1);"
echo 'PASS: expiry skips the appointment held by a completed uncommitted patient move.'

# The competing configuration commits only AFTER the command is observed
# waiting on its actual row lock and its commercial expiry has passed.
# This is a real overlap, not a sleep used to guess which command ran first.
"${psql_command[@]}" -c "select patient_management_race.prepare('access_clock');"
race access_expires_while_waiting \
 "update public.business_subscriptions set is_permanent=false,paid_until=clock_timestamp()+interval '1 second',grace_until=null where business_id='$business_id';" \
 "select patient_management_race.act('access_clock');" \
 APPOINTMENT_RESCHEDULE_UNAVAILABLE \
 "select pg_sleep(greatest(extract(epoch from ((select paid_until from public.business_subscriptions where business_id='$business_id')-clock_timestamp())),0)+0.025);"
"${psql_command[@]}" -c "select patient_management_race.assert_state('access_clock','reserved','pending',false,0); update public.business_subscriptions set is_permanent=true,paid_until=null where business_id='$business_id';"

# The same controlled fixture/locks now exercise the distinct operator command.
# A committed receipt is recovered before mutable preflight; a different request
# must keep its observed revision even if both moves would retain Reserved.
"${psql_command[@]}" -c "select patient_management_race.prepare('staff_duplicate');"
race staff_receipt_after_inflight_move "select patient_management_race.staff_act('staff_duplicate');" "select patient_management_race.staff_act('staff_duplicate','reschedule',false,true);"
"${psql_command[@]}" -c "select patient_management_race.assert_state('staff_duplicate','reserved','pending',true,1); do \$\$ begin if (select count(*) from private.appointment_management_operations where appointment_id=(select appointment_id from patient_management_race.requests where label='staff_duplicate'))<>1 then raise exception 'STAFF_DUPLICATE_RECEIPT'; end if; end \$\$;"

"${psql_command[@]}" -c "select patient_management_race.prepare('staff_stale');"
race staff_move_before_other_staff_move "select patient_management_race.staff_act('staff_stale');" "select patient_management_race.staff_act('staff_stale','reschedule',true);" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('staff_stale','reserved','pending',true,1);"

"${psql_command[@]}" -c "select patient_management_race.prepare('pay_staff');"
race payment_before_staff_move "select patient_management_race.pay('pay_staff');" "select patient_management_race.staff_act('pay_staff');" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('pay_staff','confirmed','paid',false,0);"
"${psql_command[@]}" -c "select patient_management_race.prepare('staff_pay');"
race staff_move_before_stale_payment "select patient_management_race.staff_act('staff_pay');" "select patient_management_race.pay('staff_pay');" DEPOSIT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('staff_pay','reserved','pending',true,1);"

"${psql_command[@]}" -c "select patient_management_race.prepare('staff_patient');"
race staff_move_before_patient_cancel "select patient_management_race.staff_act('staff_patient');" "select patient_management_race.act('staff_patient','cancel',true);" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('staff_patient','reserved','pending',true,1);"
"${psql_command[@]}" -c "select patient_management_race.prepare('patient_staff');"
race patient_cancel_before_staff_move "select patient_management_race.act('patient_staff','cancel');" "select patient_management_race.staff_act('patient_staff','reschedule',true);" APPOINTMENT_MANAGEMENT_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('patient_staff','cancelled','pending',false,0);"

"${psql_command[@]}" -c "select patient_management_race.prepare('config_staff');"
race configuration_before_staff_move "update public.services set duration_minutes=90 where id='$service_id';" "select patient_management_race.staff_act('config_staff');" APPOINTMENT_AVAILABILITY_CHANGED
"${psql_command[@]}" -c "select patient_management_race.assert_state('config_staff','reserved','pending',false,0); update public.services set duration_minutes=60 where id='$service_id'; select patient_management_race.prepare('staff_config');"
race staff_move_before_configuration "select patient_management_race.staff_act('staff_config');" "update public.services set duration_minutes=90 where id='$service_id';"
"${psql_command[@]}" -c "select patient_management_race.assert_state('staff_config','reserved','pending',true,1); update public.services set duration_minutes=60 where id='$service_id';"
# Contact edits hold only the patient. Observe the command waiting at its
# existing activity write AFTER the parent was taken, then commit the edit.
# A final authority check must roll back every local command effect.
"${psql_command[@]}" <<'SQL'
create table patient_management_race.contact_snapshots(label text primary key,value jsonb not null);
create function patient_management_race.domain_state(p_label text) returns jsonb language sql as $$
 select jsonb_build_object('appointment',to_jsonb(a),
  'management',(select to_jsonb(m) from public.appointment_management_states m where m.appointment_id=a.id),
  'deposit',(select to_jsonb(d) from public.appointment_deposits d where d.appointment_id=a.id),
  'requirements',(select jsonb_agg(to_jsonb(r) order by r.ordinal) from public.appointment_deposit_requirements r where r.appointment_id=a.id),
  'money_events',(select jsonb_agg(to_jsonb(e) order by e.ordinal) from public.appointment_deposit_events e where e.appointment_id=a.id),
  'releases',(select count(*) from public.appointment_slot_releases where appointment_id=a.id),
  'audit',(select count(*) from public.audit_logs where entity_id=a.id),
  'email_events',(select count(*) from private.appointment_email_events where appointment_id=a.id),
  'receipts',(select count(*) from private.appointment_management_operations where appointment_id=a.id))
 from public.appointments a join patient_management_race.requests q on q.appointment_id=a.id where q.label=p_label
$$;
create function patient_management_race.assert_corrected_contact(p_label text) returns void language plpgsql as $$
declare r patient_management_race.requests; patient public.patients; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 select p.* into strict patient from public.patients p join public.appointments a on a.patient_id=p.id where a.id=r.appointment_id;
 if patient.email is distinct from 'race-corrected@example.test' or patient.email_contact_revision<>2
  or (select count(*) from private.patient_email_contact_events where patient_id=patient.id and contact_revision=2)<>1
  or private.appointment_management_access_at(r.token,false,clock_timestamp()) is not null then
  raise exception 'CONTACT_RACE_PARTIAL_REVOCATION_%',p_label; end if;
end $$;
SQL
for contact_action in cancel reschedule; do
 contact_label="contact_before_$contact_action"
 "${psql_command[@]}" -c "select patient_management_race.prepare('$contact_label'); insert into patient_management_race.contact_snapshots select '$contact_label',patient_management_race.domain_state('$contact_label');"
 race "email_correction_before_patient_$contact_action" \
  "update public.patients set email='race-corrected@example.test' where id=(select a.patient_id from public.appointments a join patient_management_race.requests r on r.appointment_id=a.id where r.label='$contact_label');" \
  "select patient_management_race.act('$contact_label','$contact_action');" APPOINTMENT_LINK_UNAVAILABLE
 "${psql_command[@]}" -c "select patient_management_race.assert_corrected_contact('$contact_label'); do \$\$ begin if patient_management_race.domain_state('$contact_label') is distinct from (select value from patient_management_race.contact_snapshots where label='$contact_label') then raise exception 'CONTACT_RACE_LEFT_PARTIAL_AGENDA_MONEY_EFFECTS'; end if; end \$\$;"
done
"${psql_command[@]}" -c "select patient_management_race.prepare('move_before_contact');"
race patient_move_before_email_correction \
 "select patient_management_race.act('move_before_contact');" \
 "update public.patients set email='race-corrected@example.test' where id=(select a.patient_id from public.appointments a join patient_management_race.requests r on r.appointment_id=a.id where r.label='move_before_contact');"
"${psql_command[@]}" -c "select patient_management_race.assert_corrected_contact('move_before_contact'); select patient_management_race.assert_state('move_before_contact','reserved','pending',true,1);"
# Auxiliary clinical writes share the same contact authority and keep their
# own profile/submission contract; these are real row waits, in both orders.
"${psql_command[@]}" <<'SQL'
create function patient_management_race.prepare_information(p_label text) returns void language plpgsql as $$
declare r patient_management_race.requests; a public.appointments; begin
 perform patient_management_race.prepare(p_label);
 select * into strict r from patient_management_race.requests where label=p_label;
 select * into strict a from public.appointments where id=r.appointment_id;
 insert into public.appointment_patient_information_contexts(business_id,appointment_id,patient_id_snapshot,schema_snapshot)
 values(a.business_id,a.id,a.patient_id,'[{"id":"coverage","label":"Cobertura","kind":"text","required":false,"maxLength":100,"patientField":"insurance"}]');
end $$;
create function patient_management_race.submit_information(p_label text) returns uuid language plpgsql as $$
declare r patient_management_race.requests; info jsonb; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 info:=public.get_public_booking_information(r.token,false);
 return public.submit_public_booking_information(r.token,r.operation_id,info->>'schema_hash',info->>'version',
  jsonb_build_object('coverage',p_label),null,false);
end $$;
SQL
"${psql_command[@]}" -c "select patient_management_race.prepare_information('contact_before_information'); insert into patient_management_race.contact_snapshots select 'contact_before_information',patient_management_race.domain_state('contact_before_information');"
race contact_correction_before_clinical_information \
 "update public.patients set email='race-corrected@example.test' where id=(select a.patient_id from public.appointments a join patient_management_race.requests r on r.appointment_id=a.id where r.label='contact_before_information');" \
 "select patient_management_race.submit_information('contact_before_information');" BOOKING_INFORMATION_UNAVAILABLE
"${psql_command[@]}" <<'SQL'
select patient_management_race.assert_corrected_contact('contact_before_information');
do $$ declare a public.appointments; begin
 select ap.* into strict a from public.appointments ap join patient_management_race.requests r on r.appointment_id=ap.id where r.label='contact_before_information';
 if exists(select 1 from public.appointment_intake_submissions where appointment_id=a.id)
  or (select insurance from public.patients where id=a.patient_id) is not null
  or patient_management_race.domain_state('contact_before_information') is distinct from
   (select value from patient_management_race.contact_snapshots where label='contact_before_information') then
  raise exception 'CONTACT_CLINICAL_INFORMATION_PARTIAL_EFFECTS'; end if;
end $$;
SQL
"${psql_command[@]}" -c "select patient_management_race.prepare_information('information_before_contact');"
race clinical_information_before_contact_correction \
 "select patient_management_race.submit_information('information_before_contact');" \
 "update public.patients set email='race-corrected@example.test' where id=(select a.patient_id from public.appointments a join patient_management_race.requests r on r.appointment_id=a.id where r.label='information_before_contact');"
"${psql_command[@]}" <<'SQL'
select patient_management_race.assert_corrected_contact('information_before_contact');
do $$ declare a public.appointments; begin
 select ap.* into strict a from public.appointments ap join patient_management_race.requests r on r.appointment_id=ap.id where r.label='information_before_contact';
 if (select count(*) from public.appointment_intake_submissions where appointment_id=a.id)<>1
  or (select insurance from public.patients where id=a.patient_id) is distinct from 'information_before_contact' then
  raise exception 'AUTHORIZED_CLINICAL_INFORMATION_NOT_PRESERVED'; end if;
end $$;
SQL

# Two actual appointments of one patient must serialize BEFORE child FK key
# shares. A pauses after its INSERT; B then waits on A. With the old late
# patient lock, B also holds KEY SHARE and A's later UPDATE deadlocks.
"${psql_command[@]}" <<'SQL'
select patient_management_race.prepare_information('shared_patient_a');
do $$ declare a public.appointments; second_id uuid; b uuid:='e3100000-0000-4000-8000-000000000001'; begin
 select ap.* into strict a from public.appointments ap join patient_management_race.requests r on r.appointment_id=ap.id where r.label='shared_patient_a';
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,a.patient_id,a.professional_id,a.service_id,a.starts_at+interval '1 day',a.ends_at+interval '1 day','reserved','manual',
  a.service_name_snapshot,a.professional_name_snapshot,a.duration_minutes_snapshot) returning id into second_id;
 insert into public.appointment_patient_information_contexts(business_id,appointment_id,patient_id_snapshot,schema_snapshot)
  select b,second_id,a.patient_id,schema_snapshot from public.appointment_patient_information_contexts where appointment_id=a.id;
 insert into patient_management_race.requests(label,appointment_id,token,operation_id)
  values('shared_patient_b',second_id,public.issue_appointment_management_capability(b,second_id,1),gen_random_uuid());
 insert into patient_management_race.contact_snapshots select 'shared_patient_a',patient_management_race.domain_state('shared_patient_a');
 insert into patient_management_race.contact_snapshots select 'shared_patient_b',patient_management_race.domain_state('shared_patient_b');
end $$;
create function patient_management_race.pause_first_information_after_fk() returns trigger language plpgsql as $$
begin
 if new.appointment_id=(select appointment_id from patient_management_race.requests where label='shared_patient_a') then
  perform pg_advisory_xact_lock(34123,950);
  for attempt in 1..240 loop
   perform pg_stat_clear_snapshot();
   if exists(select 1 from pg_stat_activity a where a.application_name='patient-management-other' and a.wait_event_type='Lock'
    and pg_backend_pid()=any(pg_blocking_pids(a.pid))) then return new; end if;
   perform pg_sleep(0.025);
  end loop;
  raise exception 'CLINICAL_INFORMATION_COMPETITOR_DID_NOT_WAIT';
 end if;
 return new;
end $$;
create trigger zz_information_after_fk after insert on public.appointment_intake_submissions
 for each row execute function patient_management_race.pause_first_information_after_fk();
SQL
PGAPPNAME=clinical-information-first "${psql_command[@]}" >"$task_directory/holder.log" 2>&1 -c "select patient_management_race.submit_information('shared_patient_a');" &
holder_pid=$!
"${psql_command[@]}" <<'SQL'
do $$ begin
 for attempt in 1..240 loop
  perform pg_stat_clear_snapshot();
  if exists(select 1 from pg_locks where locktype='advisory' and classid=34123 and objid=950 and granted) then return; end if;
  perform pg_sleep(0.025);
 end loop;
 raise exception 'CLINICAL_INFORMATION_FIRST_DID_NOT_REACH_CHILD_INSERT';
end $$;
SQL
PGAPPNAME=patient-management-other "${psql_command[@]}" >"$task_directory/other.log" 2>&1 -c "select patient_management_race.submit_information('shared_patient_b');"
wait "$holder_pid"; holder_pid=''
"${psql_command[@]}" <<'SQL'
drop trigger zz_information_after_fk on public.appointment_intake_submissions;
do $$ declare a public.appointments; begin
 select ap.* into strict a from public.appointments ap join patient_management_race.requests r on r.appointment_id=ap.id where r.label='shared_patient_a';
 if (select count(*) from public.appointment_intake_submissions where patient_id=a.patient_id)<>2
  or (select insurance from public.patients where id=a.patient_id) is distinct from 'shared_patient_b'
  or exists(select 1 from patient_management_race.contact_snapshots s where s.label in ('shared_patient_a','shared_patient_b')
   and s.value is distinct from patient_management_race.domain_state(s.label)) then
  raise exception 'SHARED_PATIENT_CLINICAL_INFORMATION_PARTIAL_STATE'; end if;
end $$;
SQL
echo 'PASS: two appointments of the same patient serialize before child FK insertion; both persist without deadlock.'

# Completion after provider verification still decides authority in SQL, not
# in a preceding HTTP read. Contact changes serialize at the actual patient row.
"${psql_command[@]}" <<'SQL'
update public.clinical_storage_budget set uploads_enabled=true where singleton;
update public.clinical_business_storage_budget set uploads_enabled=true where business_id='e3100000-0000-4000-8000-000000000001';
update public.businesses set patient_documents_enabled=true where id='e3100000-0000-4000-8000-000000000001';
create table patient_management_race.document_requests(label text primary key,file_id uuid not null);
create function patient_management_race.prepare_document(p_label text) returns void language plpgsql as $$
declare r patient_management_race.requests; file public.patient_radiographs; begin
 perform patient_management_race.prepare_information(p_label);
 select * into strict r from patient_management_race.requests where label=p_label;
 perform set_config('request.jwt.claim.role','service_role',true);
 file:=public.begin_public_patient_document_upload(r.token,r.operation_id,'synthetic.pdf','application/pdf',100,repeat('a',64),null,false);
 insert into patient_management_race.document_requests values(p_label,file.id);
end $$;
create function patient_management_race.complete_document(p_label text) returns uuid language plpgsql as $$
declare r patient_management_race.requests; begin
 select * into strict r from patient_management_race.requests where label=p_label;
 perform set_config('request.jwt.claim.role','service_role',true);
 return public.complete_public_patient_document_upload(r.token,(select file_id from patient_management_race.document_requests where label=p_label),100,'application/pdf',false);
end $$;
select patient_management_race.prepare_document('contact_before_document');
SQL
race contact_correction_before_document_completion \
 "update public.patients set email='race-corrected@example.test' where id=(select a.patient_id from public.appointments a join patient_management_race.requests r on r.appointment_id=a.id where r.label='contact_before_document');" \
 "select patient_management_race.complete_document('contact_before_document');" BOOKING_INFORMATION_UNAVAILABLE
"${psql_command[@]}" <<'SQL'
select patient_management_race.assert_corrected_contact('contact_before_document');
do $$ declare f uuid:=(select file_id from patient_management_race.document_requests where label='contact_before_document'); begin
 if (select status from public.patient_radiographs where id=f) is distinct from 'uploading'
  or exists(select 1 from public.audit_logs where entity_id=f and action='clinical_document.patient_upload_completed')
  or not exists(select 1 from public.clinical_upload_slots where file_id=f and expires_at>clock_timestamp()) then
  raise exception 'CONTACT_DOCUMENT_COMPLETION_PARTIAL_STATE'; end if;
end $$;
select patient_management_race.prepare_document('document_before_contact');
SQL
race document_completion_before_contact_correction \
 "select patient_management_race.complete_document('document_before_contact');" \
 "update public.patients set email='race-corrected@example.test' where id=(select a.patient_id from public.appointments a join patient_management_race.requests r on r.appointment_id=a.id where r.label='document_before_contact');"
"${psql_command[@]}" <<'SQL'
select patient_management_race.assert_corrected_contact('document_before_contact');
do $$ declare f uuid:=(select file_id from patient_management_race.document_requests where label='document_before_contact'); begin
 if (select status from public.patient_radiographs where id=f) is distinct from 'ready'
  or (select count(*) from public.audit_logs where entity_id=f and action='clinical_document.patient_upload_completed')<>1 then
  raise exception 'AUTHORIZED_DOCUMENT_COMPLETION_NOT_PRESERVED'; end if;
end $$;
SQL

deadlocks_after=$("${psql_command[@]}" -c 'select deadlocks from pg_stat_database where datname=current_database();')
[[ "$deadlocks_before" == "$deadlocks_after" ]]
echo 'PASS: twenty-nine controlled management/contact/clinical races; no PostgreSQL deadlock.'
