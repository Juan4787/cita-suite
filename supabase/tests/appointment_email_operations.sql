-- Operator email controls (ZH04, ZH12, OP05). Synthetic and rolled back; nothing reaches a provider,
-- so this proves what the operator sees and changes, never what the provider holds.
begin;
select extensions.plan(21);
create temporary table ops_fixture(label text primary key,id uuid not null);
create function pg_temp.oid(label text) returns uuid language sql as $$select id from ops_fixture f where f.label=$1$$;
create function pg_temp.ops() returns jsonb language sql as $$select public.operator_get_email_operations(null)$$;
create function pg_temp.save(p_revision bigint,p_producer boolean,p_limit integer,p_messages integer,p_start timestamptz,p_expiry timestamptz,p_lift boolean default false)
returns jsonb language sql as $$
 select public.operator_set_email_operations(pg_temp.oid('operator'),p_revision,p_producer,p_limit,p_messages,p_start,p_expiry,p_lift)
$$;

do $$ declare b uuid:=gen_random_uuid(); o uuid:=gen_random_uuid(); m uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); f uuid:=gen_random_uuid(); a uuid:=gen_random_uuid(); begin
 insert into auth.users(id,email) values(o,'ops-owner-'||o||'@example.test'),(m,'ops-operator-'||m||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic operations practice',b::text,'other','UTC');
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,o,'owner','active',now());
 insert into public.patients(id,business_id,owner_id,full_name,email) values(p,b,o,'Synthetic operations patient','ops@example.test');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Synthetic service',30);
 insert into public.professionals(id,business_id,name) values(f,b,'Synthetic professional');
 insert into public.professional_services(business_id,professional_id,service_id) values(b,f,s);
 insert into public.appointments(id,business_id,patient_id,service_id,professional_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(a,b,p,s,f,date_trunc('hour',now())+interval '30 days',date_trunc('hour',now())+interval '30 days 30 minutes',
  date_trunc('hour',now())+interval '30 days',date_trunc('hour',now())+interval '30 days 30 minutes','reserved','manual','Synthetic service','Synthetic professional',30);
 insert into ops_fixture values('business',b),('operator',m),('appointment',a);
end $$;

select extensions.ok(has_function_privilege('service_role','public.operator_get_email_operations(timestamptz)','EXECUTE')
 and has_function_privilege('service_role','public.operator_set_email_operations(uuid,bigint,boolean,integer,integer,timestamptz,timestamptz,boolean)','EXECUTE')
 and not exists(select 1 from unnest(array['anon','authenticated']) role_name,
  unnest(array['public.operator_get_email_operations(timestamptz)','public.operator_set_email_operations(uuid,bigint,boolean,integer,integer,timestamptz,timestamptz,boolean)']) signature
  where has_function_privilege(role_name,signature,'EXECUTE')),
 '1. Only the backend can read or change the email operations; the page admits only the operator');

create temporary table ops_seen(label text primary key,value jsonb not null);
insert into ops_seen select 'initial',pg_temp.ops();
select extensions.ok((select value->'credit_messages'='null'::jsonb and value->'credit_used'='null'::jsonb and value->'senders' is not null
  and (value->>'daily_limit')::int=100 from ops_seen where label='initial'),
 '2. Without a recorded credit nothing is assumed: no size, no consumption');

select extensions.throws_ok($$select pg_temp.save((select (value->>'revision')::bigint+1 from ops_seen where label='initial'),false,100,null,null,null)$$,
 'P0001','EMAIL_OPERATIONS_CHANGED','3. A form based on another revision changes nothing');
select extensions.throws_ok($$select pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='initial'),false,100,10000,now(),null)$$,
 'P0001','EMAIL_OPERATIONS_INVALID','4a. A credit needs its size, start and expiry together');
select extensions.throws_ok($$select pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='initial'),false,100,10000,now(),now()-interval '1 day')$$,
 'P0001','EMAIL_OPERATIONS_INVALID','4b. A credit cannot expire before it starts');
select extensions.throws_ok($$select pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='initial'),false,-1,null,null,null)$$,
 'P0001','EMAIL_OPERATIONS_INVALID','4c. The daily cap cannot be negative');

-- Three messages around the credit start: before it, started after it, and accepted after it.
insert into private.appointment_email_deliveries(business_id,appointment_id,purpose,dedupe_key,schedule_revision,state,due_at,expires_at,started_at,accepted_at)
select pg_temp.oid('business'),pg_temp.oid('appointment'),'booking_receipt',k,1,'accepted',now()-interval '3 days',now()+interval '1 day',st,ac
from (values('ops:before',now()-interval '3 days',now()-interval '3 days'),('ops:after',now()-interval '1 hour',now()-interval '1 hour'),
 ('ops:late-accept',now()-interval '3 days',now()-interval '2 hours')) v(k,st,ac);
insert into ops_seen select 'saved',pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='initial'),true,500,10000,now()-interval '1 day',now()+interval '20 days');
select extensions.ok((select (value->>'revision')::bigint=(select (value->>'revision')::bigint+1 from ops_seen where label='initial')
  and (value->>'daily_limit')::int=500 and (value->>'credit_messages')::int=10000 and (value->>'producer_enabled')::boolean from ops_seen where label='saved'),
 '5. A valid save applies everything at once and advances the revision by one');
select extensions.ok((select (value->>'credit_used')::int=2 from ops_seen where label='saved'),
 '6. Consumption counts what started or was accepted since the credit started, and nothing older');
select extensions.ok(exists(select 1 from public.audit_logs where user_id=pg_temp.oid('operator') and action='email.operations_changed'
  and (metadata->>'credit_messages')::int=10000),'7. The change is recorded with the operator who made it');
select extensions.throws_ok($$select pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='initial'),true,500,10000,now()-interval '1 day',now()+interval '20 days')$$,
 'P0001','EMAIL_OPERATIONS_CHANGED','8. The previous form cannot be saved again after someone else saved');

update private.appointment_management_runtime set email_paused_until=now()+interval '10 minutes',email_pause_reason='SERR_157' where singleton;
insert into ops_seen select 'paused',pg_temp.ops();
insert into ops_seen select 'lifted',pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='saved'),true,500,10000,now()-interval '1 day',now()+interval '20 days',true);
select extensions.ok((select value->>'pause_reason'='SERR_157' from ops_seen where label='paused')
  and (select value->'paused_until'='null'::jsonb from ops_seen where label='lifted')
  and (select email_paused_until is null and email_pause_reason is null from private.appointment_management_runtime where singleton),
 '9. A pause is visible with its reason and only an explicit decision lifts it before its time');

insert into ops_seen select 'off',pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='lifted'),false,500,10000,now()-interval '1 day',now()+interval '20 days');
select pg_sleep(0.01);
insert into ops_seen select 'on',pg_temp.save((select (value->>'revision')::bigint from ops_seen where label='off'),true,500,10000,now()-interval '1 day',now()+interval '20 days');
select extensions.ok((select (value->>'producer_enabled_at')::timestamptz>(select (value->>'producer_enabled_at')::timestamptz from ops_seen where label='saved')
  from ops_seen where label='on') and not (select value->>'producer_enabled' from ops_seen where label='off')::boolean,
 '10. Turning sending off and on again starts a new activation: nothing from the pause is treated as new');

-- Staff decisions, run as the person. A mocked app test cannot see a type error here: these two
-- functions reached production storing a role in a uuid, and failed for everyone.
do $$ declare r uuid:=gen_random_uuid(); x uuid:=gen_random_uuid(); b uuid:=pg_temp.oid('business');
begin
 insert into auth.users(id,email) values(r,'ops-reception-'||r||'@example.test'),(x,'ops-outsider-'||x||'@example.test');
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,r,'reception','active',now());
 insert into ops_fixture values('reception',r),('outsider',x);
 insert into ops_fixture select 'owner',user_id from public.business_users where business_id=b and role='owner';
end $$;
create temporary table ops_deliveries(label text primary key,id uuid not null);
with created as (
 insert into private.appointment_email_deliveries(business_id,appointment_id,purpose,dedupe_key,schedule_revision,state,due_at,expires_at,started_at)
 select pg_temp.oid('business'),pg_temp.oid('appointment'),'booking_receipt',k,1,'uncertain',now()-interval '1 hour',now()+interval '1 day',now()-interval '1 hour'
 from (values('ops:resend'),('ops:dismiss')) v(k) returning id,dedupe_key)
insert into ops_deliveries select dedupe_key,id from created;
create function pg_temp.resolve(p_label text,p_decision text) returns jsonb language sql as $$
 select public.resolve_appointment_email_delivery(pg_temp.oid('business'),(select id from ops_deliveries where label=p_label),p_decision)
$$;

select set_config('request.jwt.claim.sub',pg_temp.oid('outsider')::text,true);
select extensions.throws_ok($$select pg_temp.resolve('ops:resend','resend')$$,'P0001','APPOINTMENT_MANAGEMENT_FORBIDDEN','11. Someone outside the practice cannot decide on a message');
select set_config('request.jwt.claim.sub',pg_temp.oid('reception')::text,true);
select extensions.ok(pg_temp.resolve('ops:resend','resend')->>'state'='retry'
 and (select state='retry' and duplicate_risk_accepted_by=pg_temp.oid('reception') from private.appointment_email_deliveries where id=(select id from ops_deliveries where label='ops:resend'))
 and exists(select 1 from public.audit_logs where user_id=pg_temp.oid('reception') and action='appointment.email_uncertain_resolved'),
 '12. Reception can resend, and the record names the person who accepted the risk of a duplicate');
select extensions.throws_ok($$select pg_temp.resolve('ops:resend','resend')$$,'P0001','EMAIL_DELIVERY_CHANGED','13. A decision already taken cannot be taken twice');
select set_config('request.jwt.claim.sub',pg_temp.oid('owner')::text,true);
select extensions.ok(pg_temp.resolve('ops:dismiss','dismiss')->>'state'='discarded'
 and (select state='discarded' and discard_reason='operator_dismissed' from private.appointment_email_deliveries where id=(select id from ops_deliveries where label='ops:dismiss')),
 '14. The owner can close a message without sending it again');

select set_config('request.jwt.claim.sub',pg_temp.oid('reception')::text,true);
select extensions.throws_ok($$select public.save_business_email_contact(pg_temp.oid('business'),'respuestas@example.test')$$,'P0001','APPOINTMENT_MANAGEMENT_FORBIDDEN','15. Reception cannot change the reply contact');
select set_config('request.jwt.claim.sub',pg_temp.oid('owner')::text,true);
select extensions.ok((public.save_business_email_contact(pg_temp.oid('business'),' respuestas@example.test '))?'ready'
 and (select reply_to_email='respuestas@example.test' from private.business_email_senders where business_id=pg_temp.oid('business'))
 and exists(select 1 from public.audit_logs where user_id=pg_temp.oid('owner') and action='business.email_contact_updated'),
 '16. The owner saves the reply contact, and the record names who did');
select extensions.throws_ok($$select public.save_business_email_contact(pg_temp.oid('business'),'sin-arroba')$$,'P0001','EMAIL_CONTACT_INVALID','17. An address that cannot receive a reply is refused');
select extensions.ok((select value->>'domain_state'='unprovisioned' and value->>'reply_to'='respuestas@example.test' and value ? 'needs_review' and value ? 'ready'
  from (select public.get_business_email_status(pg_temp.oid('business')) value) status),
 '18. The status screen reads the sender, the contact and what needs review');
select set_config('request.jwt.claim.sub',pg_temp.oid('outsider')::text,true);
select extensions.throws_ok($$select public.get_business_email_status(pg_temp.oid('business'))$$,'P0001','APPOINTMENT_MANAGEMENT_FORBIDDEN','19. Someone outside the practice cannot read it');
select set_config('request.jwt.claim.sub','',true);

select * from extensions.finish();
rollback;
