#!/usr/bin/env bash
set -euo pipefail
# An editor owns the patient row before its trigger. Email-only updates need
# no name/phone advisory lock; actual identity/eligibility changes must not wait
# on that advisory lock while owning the row. Exercise the real writer RPCs.
database_url="${SUPABASE_TEST_DB_URL:-postgresql://postgres:postgres@127.0.0.1:55422/postgres}"
case "$database_url" in postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;; *) exit 2;; esac
scratch=$(mktemp -d)
editor_pid=''; booking_pid=''
query() { psql "$database_url" -X -v ON_ERROR_STOP=1 -qAt "$@"; }
cleanup() {
 for child in "$editor_pid" "$booking_pid"; do if [ -n "$child" ]; then kill "$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; fi; done
 query <<'SQL' >/dev/null 2>&1 || true
drop schema if exists booking_contact_race cascade;
delete from public.businesses where id='b8300000-0000-4000-8000-000000000001';
delete from auth.users where id='b8400000-0000-4000-8000-000000000001';
SQL
 rm -r -- "$scratch"
}
trap cleanup EXIT
query <<'SQL'
create schema booking_contact_race;
create table booking_contact_race.control(label text primary key,go boolean not null default false);
insert into booking_contact_race.control(label) values('editor'),('booking'),('identity'),('blocked'),('archived');
create function booking_contact_race.wait_go(p_label text) returns void language plpgsql as $$begin
 for attempt in 1..1500 loop
  if (select go from booking_contact_race.control where label=p_label) then return; end if;
  perform pg_sleep(0.02);
 end loop; raise exception 'CONTACT_RACE_BARRIER_TIMEOUT';
end$$;
insert into auth.users(id,email) values('b8400000-0000-4000-8000-000000000001','contact-race-owner@example.test');
insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled,max_booking_days_ahead)
 values('b8300000-0000-4000-8000-000000000001','Synthetic contact race','synthetic-booking-contact-race','other','UTC',true,90);
update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null
 where business_id='b8300000-0000-4000-8000-000000000001';
insert into public.business_users(business_id,user_id,role,status,accepted_at)
 values('b8300000-0000-4000-8000-000000000001','b8400000-0000-4000-8000-000000000001','owner','active',now());
insert into public.services(id,business_id,name,duration_minutes,is_public)
 values('b8600000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','Synthetic contact service',30,true);
insert into public.professionals(id,business_id,name,is_public)
 values('b8700000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','Synthetic contact professional',true);
insert into public.professional_services(business_id,professional_id,service_id)
 values('b8300000-0000-4000-8000-000000000001','b8700000-0000-4000-8000-000000000001','b8600000-0000-4000-8000-000000000001');
insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes,is_active)
 select 'b8300000-0000-4000-8000-000000000001','b8700000-0000-4000-8000-000000000001',day,'08:00','18:00',30,0,true from generate_series(0,6) day;
insert into public.patients(id,business_id,owner_id,full_name,phone,phone_raw,phone_e164,email)
 values('b8500000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','b8400000-0000-4000-8000-000000000001','Synthetic Contact Patient','3425048209','3425048209','+5493425048209','Original@example.test');
create function booking_contact_race.book(p_key text default 'b8800000-0000-4000-8000-000000000001',p_hour integer default 9) returns void language plpgsql as $$begin
 perform public.create_appointment_with_patient_identity('b8300000-0000-4000-8000-000000000001','public',null,'Synthetic Contact Patient','3425048209','+5493425048209','Booking+Contact@Example.test',false,null,
 'b8600000-0000-4000-8000-000000000001',array['b8700000-0000-4000-8000-000000000001'::uuid],date_trunc('day',now())+interval '25 days'+make_interval(hours=>p_hour),null,null,false,'public_booking','valid',false,p_key);
end$$;
SQL
# This outer row lock represents the real editor's interval after SELECT FOR
# UPDATE and before its UPDATE trigger. The write is the actual authorized RPC.
PGAPPNAME=booking-contact-editor query <<'SQL' >"$scratch/editor.log" 2>&1 &
begin;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select 1 from public.patients where id='b8500000-0000-4000-8000-000000000001' for update;
select pg_advisory_xact_lock(942173);
select booking_contact_race.wait_go('editor');
select * from public.update_patient_with_clinical_profile_safely(
 'b8400000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','b8500000-0000-4000-8000-000000000001',
 'Synthetic Contact Patient',null,'3425048209','3425048209','+5493425048209','Corrected@Example.test',null,null,null,null,
 array['email'],'Synthetic contact correction',null,'Synthetic owner',false,null,null,null,null,null);
commit;
SQL
editor_pid=$!
ready=false
for attempt in $(seq 1 300); do
 if [ "$(query -c "select exists(select 1 from pg_locks where locktype='advisory' and classid=0 and objid=942173 and granted);" 2>/dev/null || true)" = t ]; then ready=true; break; fi
 sleep 0.02
done
if [ "$ready" != true ]; then cat "$scratch/editor.log"; echo 'Editor barrier was not observed' >&2; exit 1; fi
PGAPPNAME=booking-contact-create query -c 'select booking_contact_race.book();' >"$scratch/booking.log" 2>&1 &
booking_pid=$!
observed=false
for attempt in $(seq 1 300); do
 if [ "$(query -c "select exists(select 1 from pg_stat_activity b join pg_stat_activity e on e.application_name='booking-contact-editor' where b.application_name='booking-contact-create' and e.pid=any(pg_blocking_pids(b.pid)));" 2>/dev/null || true)" = t ]; then observed=true; break; fi
 sleep 0.02
done
query -c "update booking_contact_race.control set go=true where label='editor';" >/dev/null
set +e
wait "$booking_pid"; booking_result=$?; booking_pid=''
wait "$editor_pid"; editor_result=$?; editor_pid=''
set -e
if [ "$observed" != true ] || [ "$editor_result" -ne 0 ] || [ "$booking_result" -ne 0 ]; then
 cat "$scratch/editor.log" "$scratch/booking.log"
 echo 'Email-only contention must complete both operations without a wait cycle' >&2; exit 1
fi
query <<'SQL'
do $$begin
 if (select count(*) from public.appointments where business_id='b8300000-0000-4000-8000-000000000001')<>1 then raise exception 'CONTENDED_BOOKING_MISSING_OR_DUPLICATED'; end if;
end$$;
select booking_contact_race.book();
do $$begin
 if (select count(*) from public.appointments where business_id='b8300000-0000-4000-8000-000000000001')<>1 then raise exception 'RETRY_DUPLICATED_BOOKING'; end if;
 if (select email from public.patients where id='b8500000-0000-4000-8000-000000000001')<>'Corrected@Example.test' then raise exception 'CANONICAL_CONTACT_OVERWRITTEN'; end if;
 if (select c.email from public.appointments a cross join lateral private.appointment_email_contact(a.business_id,a.id) c where a.business_id='b8300000-0000-4000-8000-000000000001')<>'Booking+Contact@Example.test' then raise exception 'NEW_BOOKING_RECIPIENT_IGNORED'; end if;
end$$;
SQL
# Opposite order: the completed booking holds the patient until commit. The
# legacy editor overload deliberately omits optimistic revisions in this race;
# its independent CAS behavior is covered by the patient editor SQL tests.
PGAPPNAME=booking-contact-create query <<'SQL' >"$scratch/booking-first.log" 2>&1 &
begin;
select booking_contact_race.book('b8800000-0000-4000-8000-000000000002',11);
select pg_advisory_xact_lock(942174);
select booking_contact_race.wait_go('booking');
commit;
SQL
booking_pid=$!
ready=false
for attempt in $(seq 1 300); do
 if [ "$(query -c "select exists(select 1 from pg_locks where locktype='advisory' and classid=0 and objid=942174 and granted);" 2>/dev/null || true)" = t ]; then ready=true; break; fi
 sleep 0.02
done
if [ "$ready" != true ]; then cat "$scratch/booking-first.log"; echo 'Booking barrier was not observed' >&2; exit 1; fi
PGAPPNAME=booking-contact-editor query <<'SQL' >"$scratch/editor-second.log" 2>&1 &
begin;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select * from public.update_patient_with_clinical_profile_safely(
 'b8400000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','b8500000-0000-4000-8000-000000000001',
 'Synthetic Contact Patient',null,'3425048209','3425048209','+5493425048209','Final@Example.test',null,null,null,null,
 array['email'],'Synthetic second contact correction',null,'Synthetic owner',false,null,null,null,null,null);
commit;
SQL
editor_pid=$!
observed=false
for attempt in $(seq 1 300); do
 if [ "$(query -c "select exists(select 1 from pg_stat_activity e join pg_stat_activity b on b.application_name='booking-contact-create' where e.application_name='booking-contact-editor' and b.pid=any(pg_blocking_pids(e.pid)));" 2>/dev/null || true)" = t ]; then observed=true; break; fi
 sleep 0.02
done
query -c "update booking_contact_race.control set go=true where label='booking';" >/dev/null
set +e
wait "$booking_pid"; booking_result=$?; booking_pid=''
wait "$editor_pid"; editor_result=$?; editor_pid=''
set -e
if [ "$observed" != true ] || [ "$editor_result" -ne 0 ] || [ "$booking_result" -ne 0 ]; then
 cat "$scratch/booking-first.log" "$scratch/editor-second.log"; echo 'Opposite-order contact race failed' >&2; exit 1
fi
query <<'SQL'
do $$begin
 if (select count(*) from public.appointments where business_id='b8300000-0000-4000-8000-000000000001')<>2 then raise exception 'OPPOSITE_ORDER_BOOKING_COUNT'; end if;
 if exists(select 1 from public.appointments a cross join lateral private.appointment_email_contact(a.business_id,a.id) c
  where a.business_id='b8300000-0000-4000-8000-000000000001' and (c.email<>'Final@Example.test' or c.contact_revision<>3)) then raise exception 'STALE_POST_CORRECTION_RECIPIENT'; end if;
end$$;
SQL
# A real identity change does need the matching lock. Its UPDATE trigger must
# return the existing editor conflict rather than wait and deadlock. Preserve
# the unchanged patient, then retry that authorized edit after booking commits.
PGAPPNAME=booking-contact-editor query <<'SQL' >"$scratch/identity-editor.log" 2>&1 &
begin;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select 1 from public.patients where id='b8500000-0000-4000-8000-000000000001' for update;
select pg_advisory_xact_lock(942175);
select booking_contact_race.wait_go('identity');
select * from public.update_patient_with_clinical_profile_safely(
 'b8400000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','b8500000-0000-4000-8000-000000000001',
 'Synthetic Updated Patient',null,'3425048209','3425048209','+5493425048209','Final@Example.test',null,null,null,null,
 array['full_name'],'Synthetic identity correction',null,'Synthetic owner',false,null,null,null,null,null);
commit;
SQL
editor_pid=$!
ready=false
for attempt in $(seq 1 300); do
 if [ "$(query -c "select exists(select 1 from pg_locks where locktype='advisory' and classid=0 and objid=942175 and granted);" 2>/dev/null || true)" = t ]; then ready=true; break; fi
 sleep 0.02
done
if [ "$ready" != true ]; then cat "$scratch/identity-editor.log"; echo 'Identity editor barrier was not observed' >&2; exit 1; fi
PGAPPNAME=booking-contact-create query -c "select booking_contact_race.book('b8800000-0000-4000-8000-000000000003',13);" >"$scratch/identity-booking.log" 2>&1 &
booking_pid=$!
observed=false
for attempt in $(seq 1 300); do
 if [ "$(query -c "select exists(select 1 from pg_stat_activity b join pg_stat_activity e on e.application_name='booking-contact-editor' where b.application_name='booking-contact-create' and e.pid=any(pg_blocking_pids(b.pid)));" 2>/dev/null || true)" = t ]; then observed=true; break; fi
 sleep 0.02
done
query -c "update booking_contact_race.control set go=true where label='identity';" >/dev/null
set +e
wait "$booking_pid"; booking_result=$?; booking_pid=''
wait "$editor_pid"; editor_result=$?; editor_pid=''
set -e
if [ "$observed" != true ] || [ "$editor_result" -eq 0 ] || [ "$booking_result" -ne 0 ] || ! grep -q 'PATIENT_UPDATE_CONFLICT' "$scratch/identity-editor.log"; then
 cat "$scratch/identity-editor.log" "$scratch/identity-booking.log"; echo 'Identity contention must preserve an atomic editor conflict and the booking' >&2; exit 1
fi
query <<'SQL'
do $$begin
 if (select count(*) from public.appointments where business_id='b8300000-0000-4000-8000-000000000001')<>3 then raise exception 'IDENTITY_CONTENDED_BOOKING_COUNT'; end if;
 if (select full_name from public.patients where id='b8500000-0000-4000-8000-000000000001')<>'Synthetic Contact Patient' then raise exception 'PARTIAL_IDENTITY_UPDATE'; end if;
 if (select count(*) from public.patient_profile_change_events where business_id='b8300000-0000-4000-8000-000000000001')<>2 then raise exception 'PARTIAL_IDENTITY_AUDIT'; end if;
end$$;
select set_config('request.jwt.claims','{"role":"service_role"}',false);
select * from public.update_patient_with_clinical_profile_safely(
 'b8400000-0000-4000-8000-000000000001','b8300000-0000-4000-8000-000000000001','b8500000-0000-4000-8000-000000000001',
 'Synthetic Updated Patient',null,'3425048209','3425048209','+5493425048209','Final@Example.test',null,null,null,null,
 array['full_name'],'Synthetic identity correction',null,'Synthetic owner',false,null,null,null,null,null);
do $$begin
 if (select full_name from public.patients where id='b8500000-0000-4000-8000-000000000001')<>'Synthetic Updated Patient' then raise exception 'IDENTITY_RETRY_NOT_SAVED'; end if;
 if (select count(*) from public.patient_profile_change_events where business_id='b8300000-0000-4000-8000-000000000001')<>3 then raise exception 'IDENTITY_RETRY_AUDIT'; end if;
end$$;
SQL
# Eligibility writers require the same protection even when name/phone do not
# change. The blocking toggle below is a privileged fixture UPDATE (trigger
# proof only); archive uses its real authenticated owner RPC. The lock timeout
# is only a harness bound: a timeout is never accepted as the product conflict.
for eligibility in blocked archived; do
 PGAPPNAME=booking-contact-create query <<SQL >"$scratch/$eligibility-holder.log" 2>&1 &
begin;
select pg_advisory_xact_lock(hashtextextended('patient-contact-resolution:'||business_id::text||':'||private.public_booking_contact_bucket(full_name,phone_e164),0))
 from public.patients where id='b8500000-0000-4000-8000-000000000001';
select pg_advisory_xact_lock(942176);
select booking_contact_race.wait_go('$eligibility');
commit;
SQL
 booking_pid=$!
 ready=false
 for attempt in $(seq 1 300); do
  if [ "$(query -c "select exists(select 1 from pg_locks where locktype='advisory' and classid=0 and objid=942176 and granted);" 2>/dev/null || true)" = t ]; then ready=true; break; fi
  sleep 0.02
 done
 if [ "$ready" != true ]; then cat "$scratch/$eligibility-holder.log"; echo 'Eligibility lock was not observed' >&2; exit 1; fi
 if [ "$eligibility" = blocked ]; then
  operation="update public.patients set blocked=true where id='b8500000-0000-4000-8000-000000000001';"
 else
  operation="select set_config('request.jwt.claims','{\"role\":\"authenticated\",\"sub\":\"b8400000-0000-4000-8000-000000000001\"}',true); set local role authenticated; select public.set_patient_archive_state_safely('b8300000-0000-4000-8000-000000000001','b8500000-0000-4000-8000-000000000001',true);"
 fi
 set +e
 query -c "begin; set local lock_timeout='2s'; $operation commit;" >"$scratch/$eligibility-writer.log" 2>&1
 writer_result=$?
 set -e
 query -c "update booking_contact_race.control set go=true where label='$eligibility';" >/dev/null
 set +e
 wait "$booking_pid"; holder_result=$?; booking_pid=''
 set -e
 if [ "$writer_result" -eq 0 ] || [ "$holder_result" -ne 0 ] || ! grep -q 'PATIENT_UPDATE_CONFLICT' "$scratch/$eligibility-writer.log"; then
  cat "$scratch/$eligibility-holder.log" "$scratch/$eligibility-writer.log"; echo 'Eligibility contention must return an atomic product conflict' >&2; exit 1
 fi
 query <<'SQL'
do $$begin
 if exists(select 1 from public.patients where id='b8500000-0000-4000-8000-000000000001' and (blocked or archived_at is not null)) then raise exception 'PARTIAL_ELIGIBILITY_WRITE'; end if;
end$$;
SQL
done
echo 'Contact / public creation: both email orders, same-key recovery, identity conflict/retry and eligibility conflicts verified.'
