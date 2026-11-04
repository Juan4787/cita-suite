-- Appointment contact is scoped to one creation and a monotonic patient epoch.
begin;
select extensions.plan(14);
create temporary table booking_contact_fixture(label text primary key,value text not null);
create function pg_temp.bcv(label text) returns text language sql as $$select value from booking_contact_fixture f where f.label=$1$$;
create function pg_temp.bcid(label text) returns uuid language sql as $$select pg_temp.bcv($1)::uuid$$;
create function pg_temp.bccounts() returns jsonb language sql as $$select jsonb_build_array(
 (select count(*) from public.patients where business_id=pg_temp.bcid('business')),
 (select count(*) from public.appointments where business_id=pg_temp.bcid('business')),
 (select count(*) from public.appointment_management_states where business_id=pg_temp.bcid('business')),
 (select count(*) from public.appointment_booking_contexts where business_id=pg_temp.bcid('business')),
 (select count(*) from public.appointment_intake_submissions where business_id=pg_temp.bcid('business')),
 (select count(*) from public.audit_logs where business_id=pg_temp.bcid('business')),
 (select count(*) from private.appointment_email_events where business_id=pg_temp.bcid('business')),
 (select count(*) from private.public_booking_email_contacts where business_id=pg_temp.bcid('business')))$$;
do $$declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); i uuid:=gen_random_uuid(); begin
 insert into auth.users(id,email) values(u,'booking-email-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled,max_booking_days_ahead)
 values(b,'Synthetic public email',b::text,'other','UTC',true,90);
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.services(id,business_id,name,duration_minutes,is_public) values(s,b,'Synthetic email service',30,true);
 insert into public.professionals(id,business_id,name,is_public) values(p,b,'Synthetic email professional',true);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes,is_active)
 select b,p,day,'08:00','18:00',30,0,true from generate_series(0,6) day;
 insert into public.booking_integrations(id,business_id,name,is_active,allowed_origins,allowed_service_ids,allowed_professional_ids)
 values(i,b,'Synthetic email integration',true,array['https://booking.example.test'],array[s],array[p]);
 insert into booking_contact_fixture values('business',b::text),('owner',u::text),('service',s::text),('professional',p::text),('integration',i::text),('key',gen_random_uuid()::text);
 update public.appointment_email_policies set email_enabled=false where business_id=b;
end$$;
create function pg_temp.bcbook(mode text,email text,key text default gen_random_uuid()::text,hour integer default 9,patient_name text default 'Synthetic Email Patient') returns jsonb
language plpgsql as $$declare result record; info jsonb; b uuid:=pg_temp.bcid('business'); p uuid:=pg_temp.bcid('professional'); s uuid:=pg_temp.bcid('service');
 starts timestamptz:=date_trunc('day',now())+interval '25 days'+make_interval(hours=>hour); i uuid:=pg_temp.bcid('integration'); rev bigint; availability bigint;
begin
 select revision into rev from public.booking_integrations where id=i;
 select booking_availability_revision into availability from public.businesses where id=b;
 if mode='direct' then
  select * into result from public.create_appointment_with_patient_identity(b,'public',null,patient_name,'3425048209','+5493425048209',email,
   false,null,s,array[p],starts,null,null,false,'public_booking','valid',false,key);
 elsif mode='integrated' then
  select * into result from public.create_integrated_public_appointment(i,rev,availability,patient_name,'3425048209','+5493425048209',email,
   s,array[p],starts,null,'valid','in_person','{}',key);
 elsif mode='information' then
  info:=public.get_public_patient_booking_schema(b,array[p],null);
  select * into result from public.create_public_booking_with_information(jsonb_build_object('business_id',b,'professional_ids',array[p],
   'service_id',s,'patient_name',patient_name,'patient_phone_raw','3425048209','patient_phone_e164','+5493425048209','patient_email',email,
   'starts_at',starts,'phone_status','valid','request_key',key,'schema_hash',info->>'hash','answers','{}'::jsonb,'price_quote_hash',''));
 else raise exception 'INVALID_EMAIL_FIXTURE_MODE'; end if;
 return to_jsonb(result);
end$$;

create function pg_temp.bccontact(label text) returns text language sql as $$
 select email from private.appointment_email_contact(pg_temp.bcid('business'),(pg_temp.bcv($1)::jsonb->>'id')::uuid)
$$;
insert into booking_contact_fixture values('first',pg_temp.bcbook('direct',' Saved+Contact@Example.test ',gen_random_uuid()::text,9)::text);
insert into booking_contact_fixture values('second',pg_temp.bcbook('direct',' Booking+Contact@Example.test ',pg_temp.bcv('key'),10)::text);
select extensions.ok(pg_temp.bcv('first')::jsonb->>'patient_id'=pg_temp.bcv('second')::jsonb->>'patient_id'
 and (select email from public.patients where id=(pg_temp.bcv('first')::jsonb->>'patient_id')::uuid)='Saved+Contact@Example.test',
 'A returning public booking preserves patient resolution and does not rewrite the canonical contact');
select extensions.is(pg_temp.bccontact('first'),'Saved+Contact@Example.test','The first appointment keeps its own recipient');
select extensions.is(pg_temp.bccontact('second'),'Booking+Contact@Example.test','The new appointment uses its supplied email with case/alias preserved');
select extensions.is((select count(*) from private.patient_email_contact_events where business_id=pg_temp.bcid('business')),0::bigint,
 'New appointment contact does not impersonate an authorized global contact correction');
update public.appointment_email_policies set require_email=false where business_id=pg_temp.bcid('business');
insert into booking_contact_fixture values('optional',pg_temp.bcbook('direct',null,gen_random_uuid()::text,11)::text);
select extensions.is(pg_temp.bccontact('optional'),'Saved+Contact@Example.test','Optional omitted email uses the existing canonical contact without inventing another');
insert into booking_contact_fixture values('integrated',pg_temp.bcbook('integrated','Integrated+Contact@Example.test',gen_random_uuid()::text,12)::text);
insert into booking_contact_fixture values('information',pg_temp.bcbook('information','Information+Contact@Example.test',gen_random_uuid()::text,13,'Synthetic Other Patient')::text);
select extensions.ok(pg_temp.bccontact('integrated')='Integrated+Contact@Example.test' and pg_temp.bccontact('information')='Information+Contact@Example.test',
 'Integrated and information creation share the appointment-scoped recipient contract');
update public.patients set email='Corrected+Contact@Example.test' where id=(pg_temp.bcv('first')::jsonb->>'patient_id')::uuid;
select extensions.ok(pg_temp.bccontact('first')='Corrected+Contact@Example.test' and pg_temp.bccontact('second')='Corrected+Contact@Example.test'
 and pg_temp.bccontact('optional')='Corrected+Contact@Example.test' and pg_temp.bccontact('integrated')='Corrected+Contact@Example.test',
 'A canonical correction supersedes each prior override for that patient, without updating all parents');
select extensions.throws_ok(format('select public.resolve_appointment_management_access(%L,true)',pg_temp.bcv('second')::jsonb->>'confirmation_token'),
 'P0001','APPOINTMENT_LINK_UNAVAILABLE','An earlier legacy capability is not restored by reading a new recipient');
update public.patients set email='Saved+Contact@Example.test' where id=(pg_temp.bcv('first')::jsonb->>'patient_id')::uuid;
select extensions.is(pg_temp.bccontact('second'),'Saved+Contact@Example.test','ABA to the old canonical text cannot resurrect the former booking override');
select extensions.ok(pg_temp.bcbook('direct',' Booking+Contact@Example.test ',pg_temp.bcv('key'),10)->>'id'=pg_temp.bcv('second')::jsonb->>'id'
 and pg_temp.bccontact('second')='Saved+Contact@Example.test',
 'Recovering the completed creation does not rewrite its contact epoch or revive revoked authority');
-- Force a failure at the new write boundary after the core appointment work.
-- Counts include the contact table as well as patient, authority, intake, audit/events.
create function pg_temp.reject_booking_contact() returns trigger language plpgsql as $$begin raise exception 'SYNTHETIC_CONTACT_WRITE_FAILURE'; end$$;
create trigger synthetic_booking_contact_failure before insert on private.public_booking_email_contacts
 for each row execute function pg_temp.reject_booking_contact();
do $$declare before jsonb:=pg_temp.bccounts(); begin
 begin perform pg_temp.bcbook('direct','Rollback@Example.test',gen_random_uuid()::text,14,'Synthetic Rollback Patient'); raise exception 'CONTACT_FAILURE_NOT_DETECTED';
 exception when others then if sqlerrm is distinct from 'SYNTHETIC_CONTACT_WRITE_FAILURE' then raise; end if; end;
 if pg_temp.bccounts() is distinct from before then raise exception 'PARTIAL_CONTACT_CREATION'; end if;
end$$;
drop trigger synthetic_booking_contact_failure on private.public_booking_email_contacts;
select extensions.pass('A failed contact binding rolls back the entire creation, never a partial patient/appointment');
select extensions.is((select count(*) from private.appointment_email_contact(gen_random_uuid(),(pg_temp.bcv('second')::jsonb->>'id')::uuid)),0::bigint,
 'A wrong business cannot resolve the recipient of another appointment');
select * from public.reassign_appointment_patient_safely(pg_temp.bcid('business'),(pg_temp.bcv('second')::jsonb->>'id')::uuid,
 (pg_temp.bcv('information')::jsonb->>'patient_id')::uuid,pg_temp.bcid('owner'),'Synthetic identity correction');
select extensions.ok(pg_temp.bccontact('second')='Information+Contact@Example.test'
 and not exists(select 1 from private.public_booking_email_contacts where business_id=pg_temp.bcid('business') and appointment_id=(pg_temp.bcv('second')::jsonb->>'id')::uuid),
 'The real identity-repair command discards the old recipient and resolves only the replacement patient');
select extensions.ok(not has_table_privilege('service_role','private.public_booking_email_contacts','SELECT')
 and not has_table_privilege('authenticated','private.public_booking_email_contacts','INSERT')
 and not has_function_privilege('anon','private.appointment_email_contact(uuid,uuid)','EXECUTE')
 and not has_function_privilege('service_role','private.appointment_email_contact(uuid,uuid)','EXECUTE'),
 'Recipient facts and resolver are private implementation details, not extra browser/backend APIs');
select * from extensions.finish();
rollback;
