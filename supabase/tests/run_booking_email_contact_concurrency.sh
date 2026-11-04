#!/usr/bin/env bash
set -euo pipefail
# The editor's row lock precedes its contact advisory lock. A returning booking
# must never hold that advisory lock while waiting on the same patient row.
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
insert into booking_contact_race.control(label) values('editor');
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
create function booking_contact_race.book() returns void language plpgsql as $$begin
 perform public.create_appointment_with_patient_identity('b8300000-0000-4000-8000-000000000001','public',null,'Synthetic Contact Patient','3425048209','+5493425048209','Booking+Contact@Example.test',false,null,
 'b8600000-0000-4000-8000-000000000001',array['b8700000-0000-4000-8000-000000000001'::uuid],date_trunc('day',now())+interval '25 days 9 hours',null,null,false,'public_booking','valid',false,'b8800000-0000-4000-8000-000000000001');
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
 if rg -q 'PUBLIC_PATIENT_CONTACT_CHANGED' "$scratch/booking.log"; then observed=true; break; fi
 if [ "$(query -c "select exists(select 1 from pg_stat_activity b join pg_stat_activity e on e.application_name='booking-contact-editor' where b.application_name='booking-contact-create' and e.pid=any(pg_blocking_pids(b.pid)));" 2>/dev/null || true)" = t ]; then observed=true; break; fi
 sleep 0.02
done
query -c "update booking_contact_race.control set go=true where label='editor';" >/dev/null
set +e
wait "$booking_pid"; booking_result=$?; booking_pid=''
wait "$editor_pid"; editor_result=$?; editor_pid=''
set -e
if [ "$observed" != true ] || [ "$editor_result" -ne 0 ] || [ "$booking_result" -eq 0 ] || ! rg -q 'PUBLIC_PATIENT_CONTACT_CHANGED' "$scratch/booking.log"; then
 cat "$scratch/editor.log" "$scratch/booking.log"
 echo 'Contact contention must reject the new booking without deadlocking or aborting the authorized editor' >&2; exit 1
fi
query <<'SQL'
do $$begin
 if exists(select 1 from public.appointments where business_id='b8300000-0000-4000-8000-000000000001') then raise exception 'PARTIAL_CONTENDED_BOOKING'; end if;
end$$;
select booking_contact_race.book();
do $$begin
 if (select count(*) from public.appointments where business_id='b8300000-0000-4000-8000-000000000001')<>1 then raise exception 'RETRY_DUPLICATED_BOOKING'; end if;
 if (select email from public.patients where id='b8500000-0000-4000-8000-000000000001')<>'Corrected@Example.test' then raise exception 'CANONICAL_CONTACT_OVERWRITTEN'; end if;
 if (select c.email from public.appointments a cross join lateral private.appointment_email_contact(a.business_id,a.id) c where a.business_id='b8300000-0000-4000-8000-000000000001')<>'Booking+Contact@Example.test' then raise exception 'NEW_BOOKING_RECIPIENT_IGNORED'; end if;
end$$;
SQL
echo 'Contact editor / public creation: observed contention, no partial booking, authorized correction and same-key retry verified.'
