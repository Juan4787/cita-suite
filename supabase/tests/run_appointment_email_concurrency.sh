#!/usr/bin/env bash
set -euo pipefail
# Appointment email under real contention. Every writer is the actual command: claiming,
# recording results, provider evidence, staff cancellation and rescheduling, and a patient
# contact correction. A barrier holds one transaction open while the other runs, in both
# orders. No provider is contacted: this proves locks and the decisions taken after them,
# never that a message reached a mailbox.
database_url="${SUPABASE_TEST_DB_URL:-postgresql://postgres:postgres@127.0.0.1:55422/postgres}"
case "$database_url" in postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;; *) exit 2;; esac
scratch=$(mktemp -d)
holder_pid=''; other_pid=''
query() { psql "$database_url" -X -v ON_ERROR_STOP=1 -qAt "$@"; }

previous_runtime=$(query -c "select coalesce(email_producer_enabled::text,'false')||','||coalesce(quote_literal(email_producer_enabled_at),'null') from private.appointment_management_runtime where singleton;")
previous_enabled=${previous_runtime%%,*}; previous_enabled_at=${previous_runtime#*,}

cleanup() {
 for child in "$holder_pid" "$other_pid"; do if [ -n "$child" ]; then kill "$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; fi; done
 # The runtime row is shared by every later suite: restore it before anything that may fail.
 query -c "update private.appointment_management_runtime set email_producer_enabled=$previous_enabled,email_producer_enabled_at=$previous_enabled_at where singleton;" >/dev/null 2>&1 || true
 query <<'SQL' >/dev/null 2>&1 || true
delete from private.email_provider_events where webhook_request_id like 'race-%';
delete from private.appointment_email_events where business_id='e5300000-0000-4000-8000-000000000001';
delete from private.appointment_email_deliveries where business_id='e5300000-0000-4000-8000-000000000001';
delete from private.email_unsubscribe_tokens where business_id='e5300000-0000-4000-8000-000000000001';
delete from private.email_suppressions where business_id='e5300000-0000-4000-8000-000000000001';
delete from public.businesses where id='e5300000-0000-4000-8000-000000000001';
delete from auth.users where id='e5400000-0000-4000-8000-000000000001';
drop schema if exists email_race cascade;
SQL
 rm -r -- "$scratch"
}
trap cleanup EXIT

fail() {
 local log
 for log in "$scratch"/*.log; do [ -e "$log" ] || continue; echo "== ${log##*/}"; cat "$log"; done
 echo "$1" >&2; exit 1
}

# Runs stdin inside a transaction that stays open at a barrier until `release`.
hold() {
 local label=$1 lock=$2 log=$3 body attempt
 body=$(cat)
 printf 'begin;\n%s\nselect pg_advisory_xact_lock(%s);\nselect email_race.wait_go(%s);\ncommit;\n' "$body" "$lock" "'$label'" |
  PGAPPNAME=email-race-holder query >"$scratch/$log" 2>&1 &
 holder_pid=$!
 for attempt in $(seq 1 500); do
  if [ "$(query -c "select exists(select 1 from pg_locks where locktype='advisory' and classid=0 and objid=$lock and granted);" 2>/dev/null || true)" = t ]; then return 0; fi
  if ! kill -0 "$holder_pid" 2>/dev/null; then fail "Holder $label ended before its barrier"; fi
  sleep 0.02
 done
 fail "Holder $label did not reach its barrier"
}
release() {
 local status=0
 query -c "update email_race.control set go=true where label='$1';" >/dev/null
 wait "$holder_pid" || status=$?
 holder_pid=''
 return "$status"
}
# Runs stdin in the background as the competing session.
start_other() {
 local log=$1 body
 body=$(cat)
 printf '%s\n' "$body" | PGAPPNAME=email-race-other query >"$scratch/$log" 2>&1 &
 other_pid=$!
}
other_blocked() {
 [ "$(query -c "select exists(select 1 from pg_stat_activity o join pg_stat_activity h on h.application_name='email-race-holder' where o.application_name='email-race-other' and h.pid=any(pg_blocking_pids(o.pid)));" 2>/dev/null || true)" = t ]
}
await_blocked() {
 local attempt
 for attempt in $(seq 1 500); do other_blocked && return 0; sleep 0.02; done
 return 1
}
# The competing session either finished or is waiting on the holder: either way it ran while
# the holder was still open.
await_ran() {
 local attempt
 for attempt in $(seq 1 500); do
  if ! kill -0 "$other_pid" 2>/dev/null || other_blocked; then return 0; fi
  sleep 0.02
 done
 return 1
}
finish_other() {
 local status=0
 wait "$other_pid" || status=$?
 other_pid=''
 return "$status"
}
# A statement that must not wait for the holder. The timeouts only bound the harness: reaching
# one is a failure, never an accepted outcome.
free_run() {
 local log=$1
 { printf "begin;\nset local lock_timeout='5s';\nset local statement_timeout='20s';\n"; cat; printf 'commit;\n'; } |
  PGAPPNAME=email-race-free query >"$scratch/$log" 2>&1
}

query <<'SQL' >/dev/null
create schema email_race;
create table email_race.control(label text primary key,go boolean not null default false);
insert into email_race.control(label) values('claim'),('cancel_first'),('claim_before_cancel'),('reschedule_first'),('claim_before_reschedule'),
 ('event_first'),('result_first'),('bounce_first'),('result_before_bounce'),('duplicate'),('correction_first'),('claim_before_correction');
create table email_race.appointments(label text primary key,id uuid not null unique);
create table email_race.claims(label text primary key,value jsonb not null);
create function email_race.wait_go(p_label text) returns void language plpgsql as $$begin
 for attempt in 1..1500 loop
  if (select go from email_race.control where label=p_label) then return; end if;
  perform pg_sleep(0.02);
 end loop; raise exception 'EMAIL_RACE_BARRIER_TIMEOUT';
end$$;

insert into auth.users(id,email) values('e5400000-0000-4000-8000-000000000001','email-race-owner@example.test');
insert into public.businesses(id,name,slug,industry,timezone) values('e5300000-0000-4000-8000-000000000001','Synthetic email race','synthetic-email-race','other','UTC');
update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null
 where business_id='e5300000-0000-4000-8000-000000000001';
insert into public.business_users(business_id,user_id,role,status,accepted_at)
 values('e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001','owner','active',now());
insert into public.services(id,business_id,name,duration_minutes) values('e5600000-0000-4000-8000-000000000001','e5300000-0000-4000-8000-000000000001','Synthetic race service',30);
insert into public.professionals(id,business_id,name) values('e5700000-0000-4000-8000-000000000001','e5300000-0000-4000-8000-000000000001','Synthetic race professional');
insert into public.professional_services(business_id,professional_id,service_id)
 values('e5300000-0000-4000-8000-000000000001','e5700000-0000-4000-8000-000000000001','e5600000-0000-4000-8000-000000000001');
insert into public.patients(id,business_id,owner_id,full_name,phone,phone_raw,phone_e164,email) values
 ('e5500000-0000-4000-8000-000000000001','e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001','Synthetic Race Main','3425048301','3425048301','+5493425048301','race-main@example.test'),
 ('e5500000-0000-4000-8000-000000000002','e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001','Synthetic Race Bounce One','3425048302','3425048302','+5493425048302','race-bounce-1@example.test'),
 ('e5500000-0000-4000-8000-000000000003','e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001','Synthetic Race Bounce Two','3425048303','3425048303','+5493425048303','race-bounce-2@example.test'),
 ('e5500000-0000-4000-8000-000000000004','e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001','Synthetic Race Mail One','3425048304','3425048304','+5493425048304','race-old-1@example.test'),
 ('e5500000-0000-4000-8000-000000000005','e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001','Synthetic Race Mail Two','3425048305','3425048305','+5493425048305','race-old-2@example.test');
select public.operator_set_business_email_sender('e5300000-0000-4000-8000-000000000001','carrera-correo.cita-suite.com.ar','verified',null,'contacto-carrera@example.test');
update private.appointment_management_runtime set email_producer_enabled=true where singleton;

create function email_race.aid(p_label text) returns uuid language sql stable as $$select id from email_race.appointments where label=p_label$$;
-- Every appointment is weeks away, so no reminder is due and each claim is about receipts.
create function email_race.book(p_label text,p_patient uuid,p_day integer,p_hour integer) returns void language plpgsql as $$
declare v_id uuid:=gen_random_uuid(); v_starts timestamptz:=date_trunc('day',clock_timestamp())+make_interval(days=>20+p_day,hours=>p_hour);
begin
 insert into public.appointments(id,business_id,patient_id,service_id,professional_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(v_id,'e5300000-0000-4000-8000-000000000001',p_patient,'e5600000-0000-4000-8000-000000000001','e5700000-0000-4000-8000-000000000001',
  v_starts,v_starts+interval '30 minutes',v_starts,v_starts+interval '30 minutes','reserved','manual','Synthetic race service','Synthetic race professional',30);
 insert into email_race.appointments values(p_label,v_id);
end$$;
-- Claims are kept whole, so later checks and results use exactly what each session received.
create function email_race.claim(p_label text,p_limit integer default 20) returns integer language sql as $$
 with c as (insert into email_race.claims select p_label,public.claim_appointment_email_batch(p_limit,null) returning value)
 select jsonb_array_length(value->'items') from c
$$;
create function email_race.items(p_claim text,p_appointment text,p_purpose text default null) returns jsonb language sql stable as $$
 select coalesce(jsonb_agg(i),'[]'::jsonb) from email_race.claims c cross join lateral jsonb_array_elements(c.value->'items') i
 where c.label=p_claim and i->'snapshot'->>'id'=email_race.aid(p_appointment)::text and (p_purpose is null or i->>'purpose'=p_purpose)
$$;
create function email_race.delivery_id(p_claim text,p_appointment text) returns text language sql stable as $$
 select email_race.items(p_claim,p_appointment)#>>'{0,delivery_id}'
$$;
create function email_race.result_for(p_claim text,p_appointment text,p_outcome text default 'accepted') returns jsonb language sql as $$
 select public.record_appointment_email_results((select jsonb_agg(jsonb_build_object('delivery_id',i->>'delivery_id','lease_token',i->>'lease_token',
  'outcome',p_outcome,'request_id','req-'||(i->>'delivery_id'))) from jsonb_array_elements(email_race.items(p_claim,p_appointment)) i),null)
$$;
create function email_race.settle(p_claim text) returns jsonb language sql as $$
 select public.record_appointment_email_results(coalesce((select jsonb_agg(jsonb_build_object('delivery_id',i->>'delivery_id','lease_token',i->>'lease_token',
  'outcome','accepted','request_id','req-'||(i->>'delivery_id'))) from email_race.claims c cross join lateral jsonb_array_elements(c.value->'items') i where c.label=p_claim),'[]'::jsonb),null)
$$;
create function email_race.deliveries(p_appointment text,p_purpose text) returns setof private.appointment_email_deliveries language sql stable as $$
 select * from private.appointment_email_deliveries where business_id='e5300000-0000-4000-8000-000000000001'
  and appointment_id=email_race.aid(p_appointment) and purpose=p_purpose order by created_at,id
$$;
-- The real staff writer. Its expected revision is read before it waits, as the application does.
create function email_race.staff(p_appointment text,p_action text,p_starts timestamptz default null) returns jsonb language plpgsql as $$
declare v_id uuid:=email_race.aid(p_appointment);
begin
 perform set_config('request.jwt.claims','{"role":"service_role"}',true);
 return public.apply_staff_appointment_management('e5300000-0000-4000-8000-000000000001','e5400000-0000-4000-8000-000000000001',v_id,gen_random_uuid(),
  private.appointment_semantic_revision('e5300000-0000-4000-8000-000000000001',v_id),p_action,p_starts,false,
  case when p_action='reschedule' then (select booking_availability_revision from public.businesses where id='e5300000-0000-4000-8000-000000000001') end);
end$$;
-- The real patient editor, changing only the address.
create function email_race.correct(p_patient uuid,p_email text) returns void language plpgsql as $$
declare p public.patients;
begin
 select * into p from public.patients where id=p_patient;
 perform set_config('request.jwt.claims','{"role":"service_role"}',true);
 perform * from public.update_patient_with_clinical_profile_safely('e5400000-0000-4000-8000-000000000001','e5300000-0000-4000-8000-000000000001',p_patient,
  p.full_name,null,p.phone,p.phone_raw,p.phone_e164,p_email,null,null,null,null,array['email'],'Synthetic race correction',null,'Synthetic owner',false,null,null,null,null,null);
end$$;
create function email_race.link_works(p_token text) returns boolean language plpgsql as $$
begin
 return (public.resolve_appointment_management_access(p_token,false)->>'appointment_id') is not null;
exception when raise_exception then
 if sqlerrm='APPOINTMENT_LINK_UNAVAILABLE' then return false; end if;
 raise;
end$$;
SQL

# 1. Two claims at once. The first holds what it took; the second must neither wait for it nor
# take any of it, and nothing is lost once both commit.
query -c "select email_race.book('c'||n,'e5500000-0000-4000-8000-000000000001',0,7+n) from generate_series(1,6) n;" >/dev/null
hold claim 951001 claim-held.log <<'SQL'
select email_race.claim('claim-a',4);
SQL
free_run claim-free.log <<'SQL' || fail 'A second claim waited for the first one'
select email_race.claim('claim-b',4);
SQL
release claim || fail 'The held claim failed'
query <<'SQL' >/dev/null
select email_race.claim('claim-c');
do $$declare v_ids uuid[]; begin
 select array_agg((i->>'delivery_id')::uuid) into v_ids from email_race.claims c cross join lateral jsonb_array_elements(c.value->'items') i
  where c.label in ('claim-a','claim-b','claim-c') and i->>'purpose'='booking_receipt'
   and i->'snapshot'->>'id' in (select id::text from email_race.appointments where label ~ '^c[1-6]$');
 if coalesce(cardinality(v_ids),0)<>6 or (select count(distinct x) from unnest(v_ids) x)<>6 then raise exception 'CLAIM_RACE_DUPLICATED_OR_LOST %',v_ids; end if;
 if (select jsonb_array_length(value->'items') from email_race.claims where label='claim-a')<>4 then raise exception 'HELD_CLAIM_SIZE'; end if;
 if exists(select 1 from private.appointment_email_deliveries d join email_race.appointments a on a.id=d.appointment_id
  where a.label ~ '^c[1-6]$' and (d.state<>'sending' or d.attempts<>1)) then raise exception 'CLAIM_RACE_STATE'; end if;
end$$;
select email_race.settle(label) from email_race.claims where label in ('claim-a','claim-b','claim-c');
SQL

# 2. A staff cancellation holds the appointment while a claim runs: the claim skips it without
# waiting, and the next claim discards the stale receipt and sends the cancellation instead.
query -c "select email_race.book('k1','e5500000-0000-4000-8000-000000000001',1,8);" >/dev/null
hold cancel_first 951002 cancel-held.log <<'SQL'
select email_race.staff('k1','cancel') is not null;
SQL
free_run claim-during-cancel.log <<'SQL' || fail 'A claim waited for a cancellation in progress'
select email_race.claim('during-cancel');
SQL
query <<'SQL' >/dev/null || fail 'A claim took an appointment while its cancellation was in progress'
do $$begin
 if jsonb_array_length(email_race.items('during-cancel','k1'))<>0 then raise exception 'CLAIMED_AN_APPOINTMENT_BEING_CANCELLED'; end if;
 if (select state from email_race.deliveries('k1','booking_receipt'))<>'pending' then raise exception 'SKIPPED_RECEIPT_NOT_PENDING'; end if;
end$$;
SQL
release cancel_first || fail 'The held cancellation failed'
query <<'SQL' >/dev/null
select email_race.claim('after-cancel');
do $$begin
 if (select state||':'||coalesce(discard_reason,'') from email_race.deliveries('k1','booking_receipt'))<>'discarded:appointment_cancelled' then raise exception 'STALE_RECEIPT_AFTER_CANCEL'; end if;
 if jsonb_array_length(email_race.items('after-cancel','k1','cancellation_receipt'))<>1 then raise exception 'CANCELLATION_RECEIPT_MISSING'; end if;
 if email_race.items('after-cancel','k1','cancellation_receipt')#>>'{0,token}' is not null then raise exception 'CANCELLATION_RECEIPT_CARRIES_ACTIONS'; end if;
end$$;
select email_race.settle('during-cancel'); select email_race.settle('after-cancel');
SQL

# 3. The opposite order: the claim holds the appointment, so the cancellation waits and then
# succeeds. The receipt claimed earlier keeps its result and the cancellation follows once.
query -c "select email_race.book('k2','e5500000-0000-4000-8000-000000000001',1,9);" >/dev/null
hold claim_before_cancel 951003 claim-before-cancel.log <<'SQL'
select email_race.claim('before-cancel');
SQL
start_other cancel-waiting.log <<'SQL'
select email_race.staff('k2','cancel') is not null;
SQL
await_blocked || fail 'The cancellation did not wait for the claim holding the appointment'
release claim_before_cancel || fail 'The held claim failed'
finish_other || fail 'The cancellation failed after the claim committed'
query <<'SQL' >/dev/null
do $$begin
 if (select status from public.appointments where id=email_race.aid('k2'))<>'cancelled' then raise exception 'CANCELLATION_LOST'; end if;
 if jsonb_array_length(email_race.items('before-cancel','k2','booking_receipt'))<>1 then raise exception 'HELD_CLAIM_MISSED_RECEIPT'; end if;
end$$;
select email_race.settle('before-cancel');
select email_race.claim('after-held-cancel');
do $$begin
 if (select state from email_race.deliveries('k2','booking_receipt'))<>'accepted' then raise exception 'RECEIPT_RESULT_LOST'; end if;
 if jsonb_array_length(email_race.items('after-held-cancel','k2','cancellation_receipt'))<>1 then raise exception 'CANCELLATION_RECEIPT_AFTER_HELD_CLAIM'; end if;
 if (select count(*) from email_race.deliveries('k2','cancellation_receipt'))<>1 then raise exception 'DUPLICATE_CANCELLATION_RECEIPT'; end if;
end$$;
select email_race.settle('after-held-cancel');
SQL

# 4. A staff reschedule holds the appointment while a claim runs: the claim skips it, and the
# next claim drops the receipt of the old time and sends the change with the new one.
query -c "select email_race.book('r1','e5500000-0000-4000-8000-000000000001',2,8);" >/dev/null
hold reschedule_first 951004 reschedule-held.log <<'SQL'
select email_race.staff('r1','reschedule',date_trunc('day',clock_timestamp())+interval '22 days 14 hours') is not null;
SQL
free_run claim-during-reschedule.log <<'SQL' || fail 'A claim waited for a reschedule in progress'
select email_race.claim('during-reschedule');
SQL
query <<'SQL' >/dev/null || fail 'A claim took an appointment while it was being rescheduled'
do $$begin
 if jsonb_array_length(email_race.items('during-reschedule','r1'))<>0 then raise exception 'CLAIMED_AN_APPOINTMENT_BEING_MOVED'; end if;
end$$;
SQL
release reschedule_first || fail 'The held reschedule failed'
query <<'SQL' >/dev/null
select email_race.claim('after-reschedule');
do $$declare v_item jsonb:=email_race.items('after-reschedule','r1','reschedule_receipt'); begin
 if (select state||':'||coalesce(discard_reason,'') from email_race.deliveries('r1','booking_receipt'))<>'discarded:superseded_schedule' then raise exception 'OLD_TIME_RECEIPT_SENT'; end if;
 if jsonb_array_length(v_item)<>1 then raise exception 'RESCHEDULE_RECEIPT_MISSING'; end if;
 if (v_item#>>'{0,snapshot,starts_at}')::timestamptz<>(select starts_at from public.appointments where id=email_race.aid('r1'))
  or (select starts_at from public.appointments where id=email_race.aid('r1'))<>date_trunc('day',clock_timestamp())+interval '22 days 14 hours' then raise exception 'RESCHEDULE_RECEIPT_TIME'; end if;
end$$;
select email_race.settle('during-reschedule'); select email_race.settle('after-reschedule');
SQL

# 5. The opposite order: the claim holds the appointment, the reschedule waits, and the change
# is then sent for the new revision while the receipt of the old one keeps its own result.
query -c "select email_race.book('r2','e5500000-0000-4000-8000-000000000001',2,9);" >/dev/null
hold claim_before_reschedule 951005 claim-before-reschedule.log <<'SQL'
select email_race.claim('before-reschedule');
SQL
start_other reschedule-waiting.log <<'SQL'
select email_race.staff('r2','reschedule',date_trunc('day',clock_timestamp())+interval '22 days 15 hours') is not null;
SQL
await_blocked || fail 'The reschedule did not wait for the claim holding the appointment'
release claim_before_reschedule || fail 'The held claim failed'
finish_other || fail 'The reschedule failed after the claim committed'
query <<'SQL' >/dev/null
select email_race.settle('before-reschedule');
select email_race.claim('after-held-reschedule');
do $$declare v_item jsonb:=email_race.items('after-held-reschedule','r2','reschedule_receipt'); begin
 if (select state from email_race.deliveries('r2','booking_receipt'))<>'accepted' then raise exception 'OLD_RECEIPT_RESULT_LOST'; end if;
 if jsonb_array_length(v_item)<>1 then raise exception 'RESCHEDULE_RECEIPT_AFTER_HELD_CLAIM'; end if;
 if (select schedule_revision from email_race.deliveries('r2','reschedule_receipt'))<>(select schedule_revision from public.appointment_management_states where appointment_id=email_race.aid('r2'))
  or (select schedule_revision from email_race.deliveries('r2','booking_receipt'))>=(select schedule_revision from email_race.deliveries('r2','reschedule_receipt')) then raise exception 'RESCHEDULE_REVISION'; end if;
 if (v_item#>>'{0,snapshot,starts_at}')::timestamptz<>date_trunc('day',clock_timestamp())+interval '22 days 15 hours' then raise exception 'RESCHEDULE_RECEIPT_TIME_AFTER_WAIT'; end if;
end$$;
select email_race.settle('after-held-reschedule');
SQL

# 6. Provider evidence and the send result for the same message, in both orders. Either way the
# message ends delivered and keeps the provider identity.
query <<'SQL' >/dev/null
select email_race.book('w'||n,'e5500000-0000-4000-8000-000000000001',3,7+n) from generate_series(1,3) n;
select email_race.claim('webhook-claim');
SQL
hold event_first 951006 event-first.log <<'SQL'
select public.record_email_provider_event('race-delivered-1',email_race.delivery_id('webhook-claim','w1'),'delivered',clock_timestamp()) is not null;
SQL
start_other result-waiting.log <<'SQL'
select email_race.result_for('webhook-claim','w1') is not null;
SQL
await_blocked || fail 'The result did not wait for the evidence holding the message'
release event_first || fail 'The held evidence failed'
finish_other || fail 'The result failed after the evidence committed'
hold result_first 951007 result-first.log <<'SQL'
select email_race.result_for('webhook-claim','w2') is not null;
SQL
start_other event-waiting.log <<'SQL'
select public.record_email_provider_event('race-delivered-2',email_race.delivery_id('webhook-claim','w2'),'delivered',clock_timestamp()) is not null;
SQL
await_blocked || fail 'The evidence did not wait for the result holding the message'
release result_first || fail 'The held result failed'
finish_other || fail 'The evidence failed after the result committed'
query <<'SQL' >/dev/null
do $$begin
 if exists(select 1 from email_race.appointments a join private.appointment_email_deliveries d on d.appointment_id=a.id
  where a.label in ('w1','w2') and not (d.state='delivered' and d.provider_request_id='req-'||d.id and d.accepted_at is not null
   and d.delivered_at is not null and d.lease_token is null)) then raise exception 'EVIDENCE_RESULT_ORDER_CHANGED_OUTCOME'; end if;
end$$;
SQL

# 7. A hard bounce and the send result, in both orders: the message ends bounced, keeps the
# provider identity, and the address is suppressed for this practice.
query <<'SQL' >/dev/null
select email_race.book('b1','e5500000-0000-4000-8000-000000000002',3,11);
select email_race.book('b2','e5500000-0000-4000-8000-000000000003',3,12);
select email_race.claim('bounce-claim');
SQL
hold bounce_first 951008 bounce-first.log <<'SQL'
select public.record_email_provider_event('race-bounce-1',email_race.delivery_id('bounce-claim','b1'),'hard_bounce',clock_timestamp()) is not null;
SQL
start_other bounce-result-waiting.log <<'SQL'
select email_race.result_for('bounce-claim','b1') is not null;
SQL
await_blocked || fail 'The result did not wait for the bounce holding the message'
release bounce_first || fail 'The held bounce failed'
finish_other || fail 'The result failed after the bounce committed'
hold result_before_bounce 951009 result-before-bounce.log <<'SQL'
select email_race.result_for('bounce-claim','b2') is not null;
SQL
start_other bounce-waiting.log <<'SQL'
select public.record_email_provider_event('race-bounce-2',email_race.delivery_id('bounce-claim','b2'),'hard_bounce',clock_timestamp()) is not null;
SQL
await_blocked || fail 'The bounce did not wait for the result holding the message'
release result_before_bounce || fail 'The held result failed'
finish_other || fail 'The bounce failed after the result committed'
query <<'SQL' >/dev/null
do $$begin
 if exists(select 1 from email_race.appointments a join private.appointment_email_deliveries d on d.appointment_id=a.id
  where a.label in ('b1','b2') and not (d.state='bounced' and d.provider_request_id='req-'||d.id and d.bounced_at is not null and d.lease_token is null))
  then raise exception 'BOUNCE_RESULT_ORDER_CHANGED_OUTCOME'; end if;
 if (select count(*) from private.email_suppressions where business_id='e5300000-0000-4000-8000-000000000001'
  and email_normalized in ('race-bounce-1@example.test','race-bounce-2@example.test') and reason='hard_bounce' and lifted_at is null)<>2 then raise exception 'BOUNCE_NOT_SUPPRESSED'; end if;
end$$;
SQL

# 8. The provider repeats a notification while the first copy is still being saved: the second
# one waits, is recognized as a repeat, and changes nothing.
hold duplicate 951010 duplicate-first.log <<'SQL'
select public.record_email_provider_event('race-duplicate',email_race.delivery_id('webhook-claim','w3'),'delivered',clock_timestamp()) is not null;
SQL
start_other duplicate-second.log <<'SQL'
insert into email_race.claims select 'duplicate-second',public.record_email_provider_event('race-duplicate',email_race.delivery_id('webhook-claim','w3'),'delivered',clock_timestamp());
SQL
await_blocked || fail 'The repeated notification did not wait for the first copy'
release duplicate || fail 'The first notification failed'
finish_other || fail 'The repeated notification failed'
query <<'SQL' >/dev/null
do $$begin
 if (select value->>'duplicate' from email_race.claims where label='duplicate-second')<>'true' then raise exception 'REPEAT_NOT_RECOGNIZED'; end if;
 if (select count(*) from private.email_provider_events where webhook_request_id='race-duplicate')<>1 then raise exception 'REPEAT_STORED_TWICE'; end if;
 if (select state from email_race.deliveries('w3','booking_receipt'))<>'delivered' then raise exception 'REPEAT_CHANGED_THE_MESSAGE'; end if;
end$$;
select email_race.settle('webhook-claim'); select email_race.settle('bounce-claim');
SQL

# 9. A contact correction and a claim, in both orders. A claim reads only committed contact:
# either it sends to the address valid when it claimed, whose link the correction then disables,
# or it waits for the next run and uses the corrected address. A message already handed to the
# provider is not repeated automatically (EM07).
query -c "select email_race.book('e1','e5500000-0000-4000-8000-000000000004',4,8);" >/dev/null
hold correction_first 951011 correction-first.log <<'SQL'
select email_race.correct('e5500000-0000-4000-8000-000000000004','race-new-1@example.test');
SQL
free_run claim-during-correction.log <<'SQL' || fail 'A claim waited for a contact correction'
select email_race.claim('during-correction');
SQL
query <<'SQL' >/dev/null || fail 'A claim used an address that was not committed'
do $$begin
 if jsonb_array_length(email_race.items('during-correction','e1'))=1
  and email_race.items('during-correction','e1')#>>'{0,recipient}'<>'race-old-1@example.test' then raise exception 'CLAIM_READ_UNCOMMITTED_CONTACT'; end if;
end$$;
SQL
release correction_first || fail 'The held correction failed'
query <<'SQL' >/dev/null
do $$begin
 if jsonb_array_length(email_race.items('during-correction','e1'))=1 and email_race.link_works(email_race.items('during-correction','e1')#>>'{0,token}')
  then raise exception 'OLD_ADDRESS_LINK_SURVIVED_CORRECTION'; end if;
end$$;
select email_race.settle('during-correction');
select email_race.claim('after-correction');
do $$declare v_late jsonb:=email_race.items('after-correction','e1','booking_receipt'); begin
 if jsonb_array_length(email_race.items('during-correction','e1'))=1 then
  if jsonb_array_length(v_late)<>0 or (select count(*) from email_race.deliveries('e1','booking_receipt'))<>1 then raise exception 'DELIVERED_RECEIPT_REPEATED'; end if;
 elsif jsonb_array_length(v_late)<>1 or v_late#>>'{0,recipient}'<>'race-new-1@example.test' or not email_race.link_works(v_late#>>'{0,token}') then
  raise exception 'SKIPPED_RECEIPT_NOT_SENT_TO_CORRECTED_ADDRESS';
 end if;
end$$;
select email_race.settle('after-correction');
SQL
query -c "select email_race.book('e2','e5500000-0000-4000-8000-000000000005',4,9);" >/dev/null
hold claim_before_correction 951012 claim-before-correction.log <<'SQL'
select email_race.claim('before-correction');
SQL
start_other correction-during-claim.log <<'SQL'
select email_race.correct('e5500000-0000-4000-8000-000000000005','race-new-2@example.test');
SQL
await_ran || fail 'The correction neither ran nor waited while the claim was open'
release claim_before_correction || fail 'The held claim failed'
finish_other || fail 'The correction failed while a claim held the appointment'
query <<'SQL' >/dev/null
do $$declare v_item jsonb:=email_race.items('before-correction','e2','booking_receipt'); begin
 if jsonb_array_length(v_item)<>1 or v_item#>>'{0,recipient}'<>'race-old-2@example.test' then raise exception 'HELD_CLAIM_RECIPIENT'; end if;
 if email_race.link_works(v_item#>>'{0,token}') then raise exception 'OLD_ADDRESS_LINK_SURVIVED_LATE_CORRECTION'; end if;
 if (select email from public.patients where id='e5500000-0000-4000-8000-000000000005')<>'race-new-2@example.test' then raise exception 'CORRECTION_LOST'; end if;
end$$;
select email_race.settle('before-correction');
select email_race.claim('after-claim-correction');
do $$begin
 if jsonb_array_length(email_race.items('after-claim-correction','e2'))<>0 or (select count(*) from email_race.deliveries('e2','booking_receipt'))<>1 then raise exception 'IN_FLIGHT_RECEIPT_REPEATED'; end if;
 if exists(select 1 from private.patient_email_contact_events where business_id='e5300000-0000-4000-8000-000000000001'
  and patient_id in ('e5500000-0000-4000-8000-000000000004','e5500000-0000-4000-8000-000000000005') and processed_at is null) then raise exception 'CONTACT_EVENT_NOT_PLANNED'; end if;
end$$;
select email_race.settle('after-claim-correction');
SQL

echo 'Appointment email: claim/claim, claim/cancel and claim/reschedule in both orders, result/evidence and result/bounce in both orders, repeated evidence and claim/correction in both orders verified.'
