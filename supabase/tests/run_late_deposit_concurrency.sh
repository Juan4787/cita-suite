#!/usr/bin/env bash
# Owned disposable PostgreSQL only. Verified waits, no external money/messages.
set -Eeuo pipefail
late_database_url="${SUPABASE_TEST_DB_URL:?An explicit disposable PostgreSQL URL is required.}"
case "$late_database_url" in
 postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;;
 *) echo 'Refusing late-deposit races outside disposable loopback PostgreSQL.' >&2; exit 2 ;;
esac
late_business='e3300000-0000-4000-8000-000000000001'
late_owner='e3300000-0000-4000-8000-000000000002'
late_support='e3300000-0000-4000-8000-000000000003'
late_directory=$(mktemp -d)
late_holder=''
export PGOPTIONS='-c lock_timeout=7000 -c statement_timeout=12000'
late_psql=(psql "$late_database_url" -X -v ON_ERROR_STOP=1 -qAt)
late_previous_deposit=$("${late_psql[@]}" -c 'select enabled from private.deposit_automation where singleton;')
[[ "$late_previous_deposit" =~ ^[tf]$ ]]
cleanup_late() {
 local status=$?
 trap - EXIT
 if [[ -n "$late_holder" ]]; then kill "$late_holder" 2>/dev/null || true; wait "$late_holder" 2>/dev/null || true; fi
 if ! "${late_psql[@]}" <<SQL
update private.deposit_automation set enabled='$late_previous_deposit'::boolean;
drop schema if exists late_deposit_race cascade;
delete from public.appointments where business_id='$late_business';
delete from public.businesses where id='$late_business' and slug='e2e-late-deposit-race';
delete from public.account_assistance_support_users where user_id='$late_support' and email='late-support@example.test';
delete from auth.users where (id='$late_owner' and email='late-owner@example.test') or (id='$late_support' and email='late-support@example.test');
SQL
 then status=1; fi
 rm -r -- "$late_directory"
 exit "$status"
}
trap cleanup_late EXIT
trap 'status=$?; echo "Late deposit race failed at line $LINENO, status $status." >&2; for log in "$late_directory"/*.log; do [[ ! -f "$log" ]] || cat "$log" >&2; done' ERR
"${late_psql[@]}" <<SQL
create schema late_deposit_race;
create table late_deposit_race.requests(label text primary key,appointment_id uuid,patient_id uuid,replacement_id uuid,operation_id uuid,revision text,event_id uuid,baseline jsonb);
insert into auth.users(id,email) values('$late_owner','late-owner@example.test'),('$late_support','late-support@example.test');
insert into public.businesses(id,name,slug,industry,timezone) values('$late_business','Synthetic late money','e2e-late-deposit-race','other','UTC');
update public.business_subscriptions set is_permanent=true,commercial_access_enabled=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='$late_business';
insert into public.business_users(business_id,user_id,role,status,accepted_at) values('$late_business','$late_owner','owner','active',now());
insert into public.account_assistance_support_users(user_id,email,enabled) values('$late_support','late-support@example.test',true);
insert into public.professionals(id,business_id,name) values('e3300000-0000-4000-8000-000000000004','$late_business','Synthetic professional');
insert into public.services(id,business_id,name,duration_minutes) values('e3300000-0000-4000-8000-000000000005','$late_business','Synthetic service',30);
insert into public.professional_services(business_id,professional_id,service_id) values('$late_business','e3300000-0000-4000-8000-000000000004','e3300000-0000-4000-8000-000000000005');
insert into public.deposit_policies(business_id,enabled,amount_mode,fixed_amount,transfer_details,applies_to_manual) values('$late_business',true,'fixed',40000,'Synthetic transfer',true);
update private.deposit_automation set enabled=true;
SQL
"${late_psql[@]}" <<'SQL'
create function late_deposit_race.state(p_appointment uuid) returns jsonb language sql as $$select jsonb_build_object(
 'appointment',(select to_jsonb(a) from public.appointments a where id=p_appointment),
 'deposit',(select to_jsonb(d) from public.appointment_deposits d where appointment_id=p_appointment),
 'requirements',(select jsonb_agg(to_jsonb(r) order by ordinal) from public.appointment_deposit_requirements r where appointment_id=p_appointment),
 'events',(select jsonb_agg(to_jsonb(e) order by ordinal) from public.appointment_deposit_events e where appointment_id=p_appointment),
 'audit',(select jsonb_agg(to_jsonb(l) order by id) from public.audit_logs l where entity_id=p_appointment),
 'receipts',(select jsonb_agg(to_jsonb(o) order by operation_id) from private.appointment_management_operations o where appointment_id=p_appointment),
 'outbox',(select count(*) from private.appointment_email_events where appointment_id=p_appointment),
 'releases',(select count(*) from public.appointment_slot_releases where appointment_id=p_appointment))$$;
create function late_deposit_race.prepare(p_label text,p_seed boolean,p_help boolean) returns void language plpgsql as $$
declare b uuid:='e3300000-0000-4000-8000-000000000001'; a uuid; patient uuid; replacement uuid; starts timestamptz; seed jsonb; begin
 perform set_config('request.jwt.claim.sub','e3300000-0000-4000-8000-000000000002',true);
 insert into public.patients(business_id,owner_id,full_name,phone_e164) values(b,'e3300000-0000-4000-8000-000000000002','Synthetic '||p_label,'+5493512345678') returning id into patient;
 insert into public.patients(business_id,owner_id,full_name,phone_e164) values(b,'e3300000-0000-4000-8000-000000000002','Replacement '||p_label,'+5493512345679') returning id into replacement;
 starts:=date_trunc('hour',clock_timestamp())+make_interval(days=>20+(select count(*)::integer from late_deposit_race.requests));
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,'e3300000-0000-4000-8000-000000000004','e3300000-0000-4000-8000-000000000005',starts,starts+interval '30 minutes','reserved','manual','Synthetic service','Synthetic professional',30) returning id into a;
 update public.appointments set status='cancelled' where id=a;
 if p_seed then seed:=public.record_late_appointment_deposit(b,a,gen_random_uuid(),private.appointment_semantic_revision(b,a),'record','40000'); end if;
 insert into late_deposit_race.requests values(p_label,a,patient,replacement,gen_random_uuid(),private.appointment_semantic_revision(b,a),(seed->>'event_id')::uuid,late_deposit_race.state(a));
 delete from public.account_assistance_grants where business_id=b;
 if p_help then
  insert into public.account_assistance_grants(business_id,requested_by_user_id,support_user_id,starts_at,expires_at)
  values(b,'e3300000-0000-4000-8000-000000000002','e3300000-0000-4000-8000-000000000003',clock_timestamp()-interval '1 minute',clock_timestamp()+interval '3 seconds');
 end if;
end $$;
create function late_deposit_race.act(p_label text,p_action text,p_helper boolean default false) returns jsonb language plpgsql as $$
declare r late_deposit_race.requests; b uuid:='e3300000-0000-4000-8000-000000000001'; begin
 perform set_config('request.jwt.claim.sub',case when p_helper then 'e3300000-0000-4000-8000-000000000003' else 'e3300000-0000-4000-8000-000000000002' end,true);
 select * into strict r from late_deposit_race.requests where label=p_label;
 if p_action='repair' then
  perform public.reassign_appointment_patient_safely(b,r.appointment_id,r.replacement_id,'e3300000-0000-4000-8000-000000000002','Synthetic race repair');
  return jsonb_build_object('repaired',true);
 end if;
 return public.record_late_appointment_deposit(b,r.appointment_id,case when p_action='distinct' then gen_random_uuid() else r.operation_id end,r.revision,
  case when p_action='correct' then 'correct' else 'record' end,case when p_action='correct' then null else '40000' end,case when p_action='correct' then r.event_id end);
end $$;
create function late_deposit_race.check_result(p_label text) returns void language plpgsql as $$
declare r late_deposit_race.requests; v_patient uuid; v_late integer; v_correct integer; begin
 select * into strict r from late_deposit_race.requests where label=p_label;
 if p_label like 'help_%' then
  if late_deposit_race.state(r.appointment_id) is distinct from r.baseline then raise exception 'LATE_HELP_PARTIAL_STATE'; end if;
  return;
 end if;
 select patient_id into v_patient from public.appointments where id=r.appointment_id;
 select count(*) filter(where event_type='late_payment_recorded'),count(*) filter(where corrects_event_id is not null) into v_late,v_correct from public.appointment_deposit_events where appointment_id=r.appointment_id;
 if p_label='repair_first' then
  if v_patient<>r.replacement_id or v_late<>0 or exists(select 1 from private.appointment_management_operations where appointment_id=r.appointment_id)
   or private.appointment_late_deposit_balance('e3300000-0000-4000-8000-000000000001',r.appointment_id,r.replacement_id)<>0 then raise exception 'LATE_REPAIR_WIN_INVALID'; end if;
 else
  if v_patient<>r.patient_id or v_late<>1 or v_correct<>(case when p_label='correction' then 1 else 0 end)
   or (select count(*) from private.appointment_management_operations where appointment_id=r.appointment_id)<>(case when p_label='correction' then 2 else 1 end)
   or (select count(*) from public.audit_logs where entity_id=r.appointment_id and action in ('appointment.late_deposit_recorded','appointment.late_deposit_corrected'))<>(case when p_label='correction' then 2 else 1 end)
  then raise exception 'LATE_RACE_DUPLICATED_OR_REASSIGNED'; end if;
 end if;
end $$;
SQL
late_deadlocks=$("${late_psql[@]}" -c 'select deadlocks from pg_stat_database where datname=current_database();')
for late_case in replay distinct correction record_first repair_first help_record_parent help_correct_parent help_record_audit help_correct_audit; do
 late_seed=false
 case "$late_case" in correction|help_correct_*) late_seed=true;; esac
 late_help=false
 case "$late_case" in help_*) late_help=true;; esac
 "${late_psql[@]}" -c "select late_deposit_race.prepare('$late_case',$late_seed,$late_help);"
 late_first_action=record
 late_second_action=distinct
 late_expected=APPOINTMENT_MANAGEMENT_CHANGED
 case "$late_case" in
  replay) late_second_action=record; late_expected='';;
  correction) late_first_action=correct; late_second_action=correct;;
  record_first) late_second_action=repair; late_expected=APPOINTMENT_DEPOSIT_IDENTITY_CHANGE;;
  repair_first) late_first_action=repair; late_second_action=record;;
  help_correct_*) late_second_action=correct; late_expected=DEPOSIT_FORBIDDEN;;
  help_record_*) late_second_action=record; late_expected=DEPOSIT_FORBIDDEN;;
 esac
 late_lock="select late_deposit_race.act('$late_case','$late_first_action');"
 case "$late_case" in
  help_*_parent) late_lock="select id from public.appointments where id=(select appointment_id from late_deposit_race.requests where label='$late_case') for no key update;";;
  help_*_audit) late_lock='lock table public.audit_logs in share mode;';;
 esac
 "${late_psql[@]}" >"$late_directory/holder.log" 2>&1 <<SQL &
begin;
$late_lock
\echo LATE_HOLDER_READY
do \$\$ begin
 for attempt in 1..240 loop
  perform pg_stat_clear_snapshot();
  if exists(select 1 from pg_stat_activity a where a.application_name='late-deposit-other' and a.wait_event_type='Lock' and pg_backend_pid()=any(pg_blocking_pids(a.pid))) then
   if $late_help then perform pg_sleep(greatest(extract(epoch from ((select expires_at from public.account_assistance_grants where business_id='$late_business')-clock_timestamp())),0)+0.025); end if;
   return;
  end if;
  perform pg_sleep(0.025);
 end loop;
 raise exception 'LATE_RACE_OTHER_SIDE_DID_NOT_WAIT';
end \$\$;
commit;
SQL
 late_holder=$!
 late_ready=false
 for attempt in {1..240}; do
  if grep -Fq LATE_HOLDER_READY "$late_directory/holder.log"; then late_ready=true; break; fi
  if ! kill -0 "$late_holder" 2>/dev/null; then break; fi
  sleep 0.025
 done
 [[ "$late_ready" == true ]]
 late_status=0
 PGAPPNAME=late-deposit-other "${late_psql[@]}" -c "select late_deposit_race.act('$late_case','$late_second_action',$late_help);" >"$late_directory/actor.log" 2>&1 || late_status=$?
 wait "$late_holder"; late_holder=''
 if [[ -z "$late_expected" ]]; then
  [[ "$late_status" == 0 ]]
  grep -Fq '"idempotent_replay": true' "$late_directory/actor.log"
 else
  if [[ "$late_status" == 0 ]] || ! grep -Fq "$late_expected" "$late_directory/actor.log"; then
   cat "$late_directory/actor.log" >&2; echo "FAIL: unexpected result for $late_case." >&2; exit 1
  fi
 fi
 "${late_psql[@]}" -c "select late_deposit_race.check_result('$late_case');"
 echo "PASS: late deposit $late_case after a verified lock wait; persisted state checked."
done
[[ $("${late_psql[@]}" -c 'select deadlocks from pg_stat_database where datname=current_database();') == "$late_deadlocks" ]]
echo 'PASS: late-deposit races did not increase deadlocks.'
