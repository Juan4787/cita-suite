-- Operator email controls (ZH04, ZH12, OP05). Synthetic and rolled back; nothing reaches a provider,
-- so this proves what the operator sees and changes, never what the provider holds.
begin;
select extensions.plan(12);
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

select * from extensions.finish();
rollback;
