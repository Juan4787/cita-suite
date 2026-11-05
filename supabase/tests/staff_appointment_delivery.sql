-- Explicit staff delivery: current authority/recipient, atomic marks and audit.
begin;
select extensions.plan(16);
create temporary table delivery_fixture(label text primary key,value text not null);
create function pg_temp.dv(label text) returns text language sql as $$select value from delivery_fixture where delivery_fixture.label=$1$$;
create function pg_temp.did(label text) returns uuid language sql as $$select pg_temp.dv($1)::uuid$$;
create function pg_temp.delivery_revision() returns text language sql as $$select private.appointment_semantic_revision(pg_temp.did('business'),pg_temp.did('appointment'))$$;
create function pg_temp.delivery_counts() returns jsonb language sql as $$select jsonb_build_object(
 'appointment',(select to_jsonb(a) from public.appointments a where id=pg_temp.did('appointment')),
 'deposit',(select to_jsonb(d) from public.appointment_deposits d where appointment_id=pg_temp.did('appointment')),
 'capabilities',(select count(*) from private.appointment_management_capabilities where business_id=pg_temp.did('business')),
 'audit',(select count(*) from public.audit_logs where business_id=pg_temp.did('business')),
 'money',(select count(*) from public.appointment_deposit_events where business_id=pg_temp.did('business')),
 'requirements',(select jsonb_agg(to_jsonb(r) order by ordinal) from public.appointment_deposit_requirements r where business_id=pg_temp.did('business')),
 'outbox',(select count(*) from private.appointment_email_events where business_id=pg_temp.did('business')))$$;
create function pg_temp.delivery(kind text,reopen boolean default false,phone text default null,revision text default null) returns jsonb language sql as $$
 select public.prepare_staff_appointment_delivery(pg_temp.did('business'),pg_temp.did('appointment'),coalesce(revision,pg_temp.delivery_revision()),kind,reopen,phone)$$;
create function pg_temp.reject_delivery(kind text,expected text,reopen boolean default false,phone text default null,revision text default null) returns void language plpgsql as $$
declare before jsonb:=pg_temp.delivery_counts(); begin
 begin perform pg_temp.delivery(kind,reopen,phone,revision); raise exception 'DELIVERY_UNEXPECTED_SUCCESS';
 exception when others then if sqlerrm is distinct from expected then raise; end if; end;
 if pg_temp.delivery_counts() is distinct from before then raise exception 'DELIVERY_PARTIAL_STATE'; end if;
end$$;
do $$declare b uuid:=gen_random_uuid(); owner_id uuid:=gen_random_uuid(); reception_id uuid:=gen_random_uuid(); viewer_id uuid:=gen_random_uuid();
 patient_id uuid:=gen_random_uuid(); professional_id uuid:=gen_random_uuid(); service_id uuid:=gen_random_uuid(); a uuid; starts timestamptz:=date_trunc('hour',clock_timestamp())+interval '20 days'; begin
 insert into auth.users(id,email) select id,'delivery-'||id||'@example.test' from unnest(array[owner_id,reception_id,viewer_id]) id;
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic delivery',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,owner_id,'owner','active',now()),(b,reception_id,'reception','active',now()),(b,viewer_id,'readonly','active',now());
 insert into public.patients(id,business_id,owner_id,full_name,phone_e164,email) values(patient_id,b,owner_id,'Synthetic delivery patient','+5493512345678','delivery-patient@example.test');
 insert into public.professionals(id,business_id,name) values(professional_id,b,'Synthetic professional');
 insert into public.services(id,business_id,name,duration_minutes) values(service_id,b,'Synthetic service',30);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,professional_id,service_id);
 update private.deposit_automation set enabled=true;
 insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details,applies_to_manual)
 values(b,true,true,'fixed',40000,'Synthetic delivery transfer',true);
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient_id,professional_id,service_id,starts,starts+interval '30 minutes','reserved','manual','Synthetic service','Synthetic professional',30) returning id into a;
 insert into delivery_fixture values('business',b::text),('owner',owner_id::text),('reception',reception_id::text),('readonly',viewer_id::text),('patient',patient_id::text),('appointment',a::text);
end$$;
select set_config('request.jwt.claim.sub',pg_temp.dv('reception'),true);

select extensions.ok(has_function_privilege('authenticated','public.prepare_staff_appointment_delivery(uuid,uuid,text,text,boolean,text)','EXECUTE')
 and has_function_privilege('authenticated','public.mark_appointment_whatsapp_reminder_sent(uuid,uuid,text)','EXECUTE')
 and not has_function_privilege('anon','public.prepare_staff_appointment_delivery(uuid,uuid,text,text,boolean,text)','EXECUTE')
 and not has_function_privilege('service_role','public.prepare_staff_appointment_delivery(uuid,uuid,text,text,boolean,text)','EXECUTE')
 and not has_function_privilege('anon','public.mark_appointment_whatsapp_reminder_sent(uuid,uuid,text)','EXECUTE')
 and not has_function_privilege('service_role','public.mark_appointment_whatsapp_reminder_sent(uuid,uuid,text)','EXECUTE')
 and not has_table_privilege('authenticated','public.appointments','UPDATE'),
 '1. Explicit authenticated commands do not restore raw updates or backend actor impersonation');

insert into delivery_fixture values('first',pg_temp.delivery('activation')::text);
select extensions.ok(pg_temp.dv('first')::jsonb->>'token' ~ '^[0-9a-f]{64}$'
 and (public.resolve_appointment_management_access(pg_temp.dv('first')::jsonb->>'token',false)->>'appointment_id')::uuid=pg_temp.did('appointment')
 and pg_temp.dv('first')::jsonb->>'phone_e164'='+5493512345678'
 and exists(select 1 from public.audit_logs where entity_id=pg_temp.did('appointment') and action='appointment.management_link_prepared' and user_id=pg_temp.did('reception'))
 and not exists(select 1 from public.audit_logs where entity_id=pg_temp.did('appointment') and metadata::text like '%'||(pg_temp.dv('first')::jsonb->>'token')||'%'),
 '2. Reception obtains a current scoped capability, consistent recipient and audit without logging the secret');

update public.patients set email='corrected-delivery@example.test' where id=pg_temp.did('patient');
insert into delivery_fixture values('fresh',pg_temp.delivery('rescheduled')::text);
do $$begin
 begin perform public.resolve_appointment_management_access(pg_temp.dv('first')::jsonb->>'token',false); raise exception 'OLD_DELIVERY_LINK_REVIVED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 if public.resolve_appointment_management_access(pg_temp.dv('fresh')::jsonb->>'token',false) is null then raise exception 'NEW_DELIVERY_LINK_INVALID'; end if;
end$$;
select extensions.pass('3. A corrected contact invalidates the old link; explicit staff delivery issues current authority without reviving it');

select set_config('request.jwt.claim.sub',pg_temp.dv('readonly'),true);
select pg_temp.reject_delivery('activation','APPOINTMENT_MANAGEMENT_FORBIDDEN');
do $$declare before jsonb:=pg_temp.delivery_counts(); begin
 begin perform public.mark_appointment_whatsapp_reminder_sent(pg_temp.did('business'),pg_temp.did('appointment'),pg_temp.delivery_revision()); raise exception 'READONLY_MARKED_SENT';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
 if before is distinct from pg_temp.delivery_counts() then raise exception 'READONLY_MARK_EFFECT'; end if;
end$$;
select set_config('request.jwt.claim.sub',pg_temp.dv('reception'),true);
update public.business_users set status='disabled',disabled_at=clock_timestamp() where business_id=pg_temp.did('business') and user_id=pg_temp.did('reception');
select pg_temp.reject_delivery('activation','APPOINTMENT_MANAGEMENT_FORBIDDEN');
update public.business_users set status='active',disabled_at=null where business_id=pg_temp.did('business') and user_id=pg_temp.did('reception');
select extensions.pass('4. Read-only and a disabled membership cannot mint or audit a delivery');

do $$declare before jsonb:=pg_temp.delivery_counts(); begin
 begin perform public.prepare_staff_appointment_delivery(gen_random_uuid(),pg_temp.did('appointment'),pg_temp.delivery_revision(),'activation'); raise exception 'CROSS_TENANT_DELIVERY';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
 if before is distinct from pg_temp.delivery_counts() then raise exception 'CROSS_TENANT_DELIVERY_EFFECT'; end if;
end$$;
select extensions.pass('5. A foreign tenant is rejected without a capability or partial effects');

select pg_temp.reject_delivery(null,'APPOINTMENT_DELIVERY_INVALID');
select pg_temp.reject_delivery('other','APPOINTMENT_DELIVERY_INVALID');
select pg_temp.reject_delivery('activation','APPOINTMENT_DELIVERY_INVALID',true);
select pg_temp.reject_delivery('activation','APPOINTMENT_DELIVERY_INVALID',false,'unexpected');
select pg_temp.reject_delivery('activation','APPOINTMENT_MANAGEMENT_CHANGED',false,null,repeat('0',64));
select pg_temp.reject_delivery('reminder','APPOINTMENT_DELIVERY_CONTACT_CHANGED');
select pg_temp.reject_delivery('reminder','APPOINTMENT_DELIVERY_CONTACT_CHANGED',false,'+5493511111111');
select extensions.pass('6. Invalid purpose/reopen/revision and changed or unchecked recipient fail with no marks, money or links');

insert into delivery_fixture values('before-open-revision',pg_temp.delivery_revision());
select pg_temp.delivery('reminder',false,'+5493512345678') is not null;
select pg_temp.reject_delivery('reminder','APPOINTMENT_REMINDER_ALREADY_OPENED',false,'+5493512345678');
select extensions.ok(pg_temp.delivery_revision()=pg_temp.dv('before-open-revision')
 and (select count(*)=1 from public.audit_logs where entity_id=pg_temp.did('appointment') and action='reminder.whatsapp_opened')
 and (select whatsapp_reminder_opened_by=pg_temp.did('reception') from public.appointments where id=pg_temp.did('appointment')),
 '7. Reminder opening and audit commit together; another ordinary opening is rejected and telemetry leaves the semantic revision unchanged');

select pg_temp.delivery('reminder',true,'+5493512345678') is not null;
select extensions.ok((select count(*)=2 from public.audit_logs where entity_id=pg_temp.did('appointment') and action='reminder.whatsapp_opened')
 and exists(select 1 from public.audit_logs where entity_id=pg_temp.did('appointment') and action='reminder.whatsapp_opened' and metadata->>'reopened'='true'),
 '8. A deliberate reopening preserves the existing explicit confirmation rule');

do $$declare before jsonb; first boolean; again boolean; begin
 first:=public.mark_appointment_whatsapp_reminder_sent(pg_temp.did('business'),pg_temp.did('appointment'),pg_temp.delivery_revision()); before:=pg_temp.delivery_counts();
 again:=public.mark_appointment_whatsapp_reminder_sent(pg_temp.did('business'),pg_temp.did('appointment'),pg_temp.delivery_revision());
 if first is not true or again is not false or before is distinct from pg_temp.delivery_counts()
  or (select count(*) from public.audit_logs where entity_id=pg_temp.did('appointment') and action='reminder.whatsapp_marked_sent')<>1 then raise exception 'MARK_SENT_NOT_IDEMPOTENT'; end if;
end$$;
select extensions.pass('9. Repeating a manual sent assertion recovers the fact without a duplicate write or audit');

insert into delivery_fixture values('before-move',pg_temp.delivery_revision());
update public.appointments set starts_at=starts_at+interval '1 hour',ends_at=ends_at+interval '1 hour' where id=pg_temp.did('appointment');
do $$declare before jsonb:=pg_temp.delivery_counts(); begin
 begin perform public.mark_appointment_whatsapp_reminder_sent(pg_temp.did('business'),pg_temp.did('appointment'),pg_temp.dv('before-move')); raise exception 'OLD_SEND_COVERED_NEW_DATE';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_CHANGED' then raise; end if; end;
 if before is distinct from pg_temp.delivery_counts() then raise exception 'STALE_SEND_EFFECT'; end if;
end$$;
select extensions.pass('10. A stale sent assertion cannot cover a different schedule');

select pg_temp.delivery('deposit',false,'+5493512345678') is not null;
select pg_temp.reject_delivery('deposit','DEPOSIT_REMINDER_ALREADY_OPENED',false,'+5493512345678');
select extensions.ok((select reminder_opened_by=pg_temp.did('reception') from public.appointment_deposits where appointment_id=pg_temp.did('appointment'))
 and (select count(*)=1 from public.audit_logs where entity_id=pg_temp.did('appointment') and action='appointment.deposit_reminder_opened'),
 '11. Deposit delivery preserves its existing pending/reopen command and real actor in the same transaction');

create function pg_temp.reject_delivery_audit() returns trigger language plpgsql as $$begin
 if new.entity_id=pg_temp.did('appointment') and new.action in ('appointment.management_link_prepared','reminder.whatsapp_marked_sent') then raise exception 'SYNTHETIC_DELIVERY_AUDIT_FAILURE'; end if; return new;
end$$;
create trigger synthetic_delivery_audit_failure before insert on public.audit_logs for each row execute function pg_temp.reject_delivery_audit();
select pg_temp.reject_delivery('reminder','SYNTHETIC_DELIVERY_AUDIT_FAILURE',true,'+5493512345678');
select pg_temp.reject_delivery('deposit','SYNTHETIC_DELIVERY_AUDIT_FAILURE',true,'+5493512345678');
do $$declare before jsonb; begin
 update public.appointments set whatsapp_reminder_marked_sent_at=null,whatsapp_reminder_marked_sent_by=null where id=pg_temp.did('appointment'); before:=pg_temp.delivery_counts();
 begin perform public.mark_appointment_whatsapp_reminder_sent(pg_temp.did('business'),pg_temp.did('appointment'),pg_temp.delivery_revision()); raise exception 'MISSING_AUDIT_SUCCEEDED';
 exception when others then if sqlerrm is distinct from 'SYNTHETIC_DELIVERY_AUDIT_FAILURE' then raise; end if; end;
 if before is distinct from pg_temp.delivery_counts() then raise exception 'MARK_WITHOUT_AUDIT'; end if;
end$$;
drop trigger synthetic_delivery_audit_failure on public.audit_logs;
select extensions.pass('12. Failure after marking/minting rolls back reminder/deposit marks, capability, money projections and all audits');

update public.patients set blocked=true where id=pg_temp.did('patient');
select pg_temp.reject_delivery('activation','APPOINTMENT_LINK_UNAVAILABLE');
update public.patients set blocked=false where id=pg_temp.did('patient');
update public.business_subscriptions set commercial_access_enabled=false where business_id=pg_temp.did('business');
select pg_temp.reject_delivery('activation','APPOINTMENT_MANAGEMENT_FORBIDDEN');
update public.business_subscriptions set commercial_access_enabled=true where business_id=pg_temp.did('business');
select extensions.pass('13. Blocked identity or commercial suspension stops distribution without mutating the appointment');

update public.appointments set status='cancelled' where id=pg_temp.did('appointment');
select pg_temp.reject_delivery('activation','APPOINTMENT_DELIVERY_UNAVAILABLE');
update public.appointments set status='reserved',starts_at=starts_at-interval '30 days',ends_at=ends_at-interval '30 days' where id=pg_temp.did('appointment');
select pg_temp.reject_delivery('activation','APPOINTMENT_DELIVERY_UNAVAILABLE');
select extensions.pass('14. Cancelled and past appointments cannot produce active delivery links');

do $$declare signature text; begin
 foreach signature in array array['public.prepare_staff_appointment_delivery(uuid,uuid,text,text,boolean,text)',
  'public.mark_appointment_whatsapp_reminder_sent(uuid,uuid,text)'] loop
  if not exists(select 1 from pg_proc where oid=signature::regprocedure and prosecdef and 'search_path=pg_catalog, pg_temp'=any(proconfig)) then raise exception 'DELIVERY_SEARCH_PATH_UNSAFE'; end if;
 end loop;
end$$;
select extensions.pass('15. Both privileged entry points fix their schema search path');

select extensions.ok(not exists(select 1 from private.appointment_management_capabilities where business_id=pg_temp.did('business')
 and token_hash in (pg_temp.dv('first')::jsonb->>'token',pg_temp.dv('fresh')::jsonb->>'token')),
 '16. Only token hashes persist; an explicit retry may issue another link but cannot recover plaintext from storage');
select * from extensions.finish();
rollback;
