#!/usr/bin/env bash
# Gate authorization after it captured its snapshot; mutate before presentation.
# A correct one-query read returns a coherent old view, then a coherent new one.
set -Eeuo pipefail
database_url="${SUPABASE_TEST_DB_URL:?An explicit disposable PostgreSQL URL is required.}"
case "$database_url" in
 postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;;
 *) echo 'Refusing patient view race outside disposable loopback PostgreSQL.' >&2; exit 2 ;;
esac
export PGOPTIONS='-c lock_timeout=7000 -c statement_timeout=12000'
psql_command=(psql "$database_url" -X -v ON_ERROR_STOP=1 -qAt)
task_directory=$(mktemp -d)
holder_pid=''
business_id='e3200000-0000-4000-8000-000000000001'
owner_id='e3200000-0000-4000-8000-000000000002'
slug='e2e-patient-management-view-race'
previous_deposit=$("${psql_command[@]}" -c 'select enabled from private.deposit_automation where singleton;')
previous_runtime=$("${psql_command[@]}" -c "select reschedule_enabled||'|'||email_producer_enabled from private.appointment_management_runtime where singleton;")
[[ "$previous_deposit" =~ ^[tf]$ && "$previous_runtime" =~ ^(true|false)\|(true|false)$ ]]
cleanup() {
 local status=$?
 trap - EXIT
 if [[ -n "$holder_pid" ]]; then kill "$holder_pid" 2>/dev/null || true; wait "$holder_pid" 2>/dev/null || true; fi
 if ! "${psql_command[@]}" <<SQL
do \$\$ begin
 if to_regprocedure('private.appointment_management_access_before_view_race(text,boolean,timestamptz)') is not null then
  drop function private.appointment_management_access_at(text,boolean,timestamptz);
  alter function private.appointment_management_access_before_view_race(text,boolean,timestamptz) rename to appointment_management_access_at;
 end if;
end \$\$;
update private.deposit_automation set enabled='$previous_deposit'::boolean;
update private.appointment_management_runtime set reschedule_enabled='${previous_runtime%|*}'::boolean,email_producer_enabled='${previous_runtime#*|}'::boolean;
drop schema if exists patient_view_race cascade;
delete from public.appointments a using public.businesses b where a.business_id=b.id and b.id='$business_id' and b.slug='$slug';
delete from public.businesses where id='$business_id' and slug='$slug';
delete from auth.users where id='$owner_id' and email='patient-view-race@example.test';
SQL
 then status=1; fi
 rm -r -- "$task_directory"
 exit "$status"
}
trap cleanup EXIT
on_error() {
 local status=$?
 echo "Patient view race failed at line $1, status $status." >&2
 for log in "$task_directory"/*.log; do [[ ! -f "$log" ]] || cat "$log" >&2; done
}
trap 'on_error $LINENO' ERR
"${psql_command[@]}" <<SQL
create schema patient_view_race;
create table patient_view_race.request(appointment_id uuid,token text,revision text,original_start timestamptz,target timestamptz,
 availability_revision bigint,terms jsonb);
insert into auth.users(id,email) values('$owner_id','patient-view-race@example.test');
insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled)
 values('$business_id','Synthetic coherent view','$slug','other','UTC',true);
update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
 paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id='$business_id';
insert into public.business_users(business_id,user_id,role,status,accepted_at) values('$business_id','$owner_id','owner','active',now());
insert into public.professionals(id,business_id,name,is_public) values('e3200000-0000-4000-8000-000000000003','$business_id','Synthetic view professional',true);
insert into public.services(id,business_id,name,duration_minutes,is_public) values('e3200000-0000-4000-8000-000000000004','$business_id','Synthetic view service',60,true);
insert into public.professional_services(business_id,professional_id,service_id)
 values('$business_id','e3200000-0000-4000-8000-000000000003','e3200000-0000-4000-8000-000000000004');
insert into public.patients(id,business_id,owner_id,full_name) values('e3200000-0000-4000-8000-000000000005','$business_id','$owner_id','Synthetic view patient');
update private.deposit_automation set enabled=true;
update private.appointment_management_runtime set reschedule_enabled=true,email_producer_enabled=false;
insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details)
 values('$business_id',true,true,'fixed',40000,'Synthetic view transfer');
insert into public.appointments(id,business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
 service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values('e3200000-0000-4000-8000-000000000006','$business_id','e3200000-0000-4000-8000-000000000005',
 'e3200000-0000-4000-8000-000000000003','e3200000-0000-4000-8000-000000000004',date_trunc('hour',now())+interval '20 days',
 date_trunc('hour',now())+interval '20 days 1 hour','reserved','manual','Synthetic service','Synthetic professional',60);
select set_config('request.jwt.claim.sub','$owner_id',false);
select public.set_appointment_deposit('$business_id','e3200000-0000-4000-8000-000000000006','paid',1,null);
select set_config('request.jwt.claim.sub','',false);
update public.appointment_management_states set terms_acknowledged=true,require_deposit_on_reschedule=true,previous_deposit_disposition='forfeit',
 accepted_at=now(),accepted_policy_revision=1 where appointment_id='e3200000-0000-4000-8000-000000000006';
insert into patient_view_race.request select a.id,public.issue_appointment_management_capability(a.business_id,a.id,1),
 private.appointment_semantic_revision(a.business_id,a.id),a.starts_at,a.starts_at+interval '6 hours',b.booking_availability_revision,
 private.appointment_reschedule_financial_terms(a.business_id,a.id,a.starts_at+interval '6 hours',clock_timestamp())
 from public.appointments a join public.businesses b on b.id=a.business_id where a.id='e3200000-0000-4000-8000-000000000006';
alter function private.appointment_management_access_at(text,boolean,timestamptz) rename to appointment_management_access_before_view_race;
SQL
"${psql_command[@]}" <<'SQL'
-- Only a gate in an owned fixture. Restore the exact original function/OID/ACL
-- in cleanup; it is never a production authorization implementation.
create function private.appointment_management_access_at(p_token text,p_legacy boolean,p_now timestamptz)
returns jsonb language plpgsql stable security definer set search_path=pg_catalog,pg_temp as $$
declare result jsonb; begin
 result:=private.appointment_management_access_before_view_race(p_token,p_legacy,p_now);
 perform pg_advisory_xact_lock(732061103);
 return result;
end $$;
revoke all on function private.appointment_management_access_at(text,boolean,timestamptz) from public,anon,authenticated,service_role;
SQL
"${psql_command[@]}" >"$task_directory/holder.log" 2>&1 <<'SQL' &
begin;
select pg_advisory_xact_lock(732061103);
\echo PATIENT_VIEW_GATE_READY
do $$ begin
 for attempt in 1..240 loop
  perform pg_stat_clear_snapshot();
  if exists(select 1 from pg_stat_activity a where a.application_name='patient-view-reader' and a.wait_event_type='Lock'
   and pg_backend_pid()=any(pg_blocking_pids(a.pid))) then return; end if;
  perform pg_sleep(0.025);
 end loop;
 raise exception 'PATIENT_VIEW_READER_DID_NOT_WAIT';
end $$;
select public.apply_patient_appointment_management(token,false,gen_random_uuid(),revision,'reschedule',target,availability_revision,terms)
 from patient_view_race.request;
commit;
SQL
holder_pid=$!
ready=false
for attempt in {1..240}; do
 if grep -q '^PATIENT_VIEW_GATE_READY$' "$task_directory/holder.log"; then ready=true; break; fi
 if ! kill -0 "$holder_pid" 2>/dev/null; then break; fi
 sleep 0.025
done
[[ "$ready" == true ]]
PGAPPNAME=patient-view-reader "${psql_command[@]}" >"$task_directory/reader.log" 2>&1 <<'SQL'
do $$ declare r patient_view_race.request; v jsonb; begin
 select * into strict r from patient_view_race.request;
 v:=public.get_patient_appointment_management_view(r.token,false);
 if v->>'revision' is distinct from r.revision or (v->>'starts_at')::timestamptz is distinct from r.original_start
  or v->>'status' is distinct from 'confirmed' or v->>'schedule_revision'<>'1' or v->'deposit'->>'status' is distinct from 'paid'
  or v->'financial_summary'->>'applied_amount' is distinct from '40000' then raise exception 'PATIENT_VIEW_MIXED_OLD_AND_NEW_SNAPSHOT'; end if;
end $$;
do $$ declare r patient_view_race.request; v jsonb; begin
 select * into strict r from patient_view_race.request;
 v:=public.get_patient_appointment_management_view(r.token,false);
 if v->>'revision'=r.revision or (v->>'starts_at')::timestamptz is distinct from r.target
  or v->>'status' is distinct from 'reserved' or v->>'schedule_revision'<>'2' or v->'deposit'->>'status' is distinct from 'pending'
  or v->'financial_summary'->>'forfeited_amount' is distinct from '40000' then raise exception 'PATIENT_VIEW_DID_NOT_ADVANCE_ON_NEXT_QUERY'; end if;
end $$;
SQL
wait "$holder_pid"; holder_pid=''
echo 'PASS: real concurrent update preserved one coherent authorization/presentation/money snapshot; the next read sees all new state.'
