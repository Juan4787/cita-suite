-- E1/E2: one authorized snapshot for patient presentation and slot selection.
-- This contract must fail before the read API exists; no browser/Zoho proof.
begin;
select extensions.plan(22);
create temporary table management_view_fixture(label text primary key,id uuid not null,token text);
create function pg_temp.vid(p_label text) returns uuid language sql as $$ select id from management_view_fixture where label=p_label $$;
create function pg_temp.vread(p_label text default 'appointment',p_target timestamptz default null) returns jsonb language sql as $$
 select public.get_patient_appointment_management_view(token,false,p_target) from management_view_fixture where label=p_label
$$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); patient uuid:=gen_random_uuid(); a uuid;
 starts timestamptz:=date_trunc('hour',now())+interval '15 days'; begin
 insert into auth.users(id,email) values(u,'view-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone,public_booking_enabled)
 values(b,'Synthetic management view',b::text,'other','America/Argentina/Cordoba',true);
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name,is_public) values(p,b,'Synthetic public professional',true);
 insert into public.services(id,business_id,name,duration_minutes,is_public) values(s,b,'Synthetic view service',60,true);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(id,business_id,owner_id,full_name,email)
 values(patient,b,u,'Synthetic current patient','PRIVATE-PATIENT@example.test');
 update private.deposit_automation set enabled=true;
 update private.appointment_management_runtime set reschedule_enabled=true,email_producer_enabled=false;
 insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details)
 values(b,true,true,'fixed',40000,'Synthetic transfer instructions');
 perform set_config('request.jwt.claim.sub',u::text,true);
 for counter in 0..1 loop
  insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,internal_note,
   service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
  values(b,patient,p,s,starts+make_interval(days=>counter),starts+make_interval(days=>counter,hours=>1),
   'reserved','manual','PRIVATE-CLINICAL-NOTE','Synthetic service','Synthetic professional',60) returning id into a;
  update public.appointment_management_states set terms_acknowledged=true,require_deposit_on_reschedule=true,
   previous_deposit_disposition='forfeit',accepted_at=now(),accepted_policy_revision=1 where appointment_id=a;
  if counter=0 then perform public.set_appointment_deposit(b,a,'paid',(select revision from public.appointment_deposits where appointment_id=a),null); end if;
  insert into management_view_fixture values(case when counter=0 then 'appointment' else 'pending' end,a,public.issue_appointment_management_capability(b,a,1));
 end loop;
 insert into management_view_fixture(label,id) values('business',b),('owner',u),('service',s),('professional',p),('patient',patient);
end $$;

-- Auxiliary presentation follows its own scope, independently from moving slots.
select extensions.ok((pg_temp.vread()->>'can_manage_reminders')::boolean
 and not (pg_temp.vread()->>'can_add_information')::boolean,
 'Manual appointment without questionnaire still permits reminders, with no dead clinical link');
insert into public.appointment_patient_information_contexts(business_id,appointment_id,patient_id_snapshot,schema_snapshot)
values(pg_temp.vid('business'),pg_temp.vid('appointment'),pg_temp.vid('patient'),
 '[{"id":"coverage","label":"Cobertura","kind":"text","required":false,"maxLength":100}]');
select extensions.ok((pg_temp.vread()->>'can_manage_reminders')::boolean
 and (pg_temp.vread()->>'can_add_information')::boolean,
 'Matching current clinical context permits information and reminders');
update public.businesses set public_booking_enabled=false where id=pg_temp.vid('business');
select extensions.ok((pg_temp.vread()->>'can_manage_reminders')::boolean
 and (pg_temp.vread()->>'can_add_information')::boolean and not (pg_temp.vread()->>'can_reschedule')::boolean,
 'Turning new reservations off does not disable existing-appointment auxiliaries');
update public.businesses set public_booking_enabled=true where id=pg_temp.vid('business');
update public.business_subscriptions set commercial_access_enabled=false where business_id=pg_temp.vid('business');
select extensions.ok(not (pg_temp.vread()->>'can_manage_reminders')::boolean
 and not (pg_temp.vread()->>'can_add_information')::boolean and (pg_temp.vread()->>'can_cancel')::boolean,
 'Commercial suspension retains cancellation without offering new reminders or clinical editing');
update public.business_subscriptions set commercial_access_enabled=true where business_id=pg_temp.vid('business');
update public.patients set archived_at=now() where id=pg_temp.vid('patient');
select extensions.ok(not (pg_temp.vread()->>'can_manage_reminders')::boolean
 and not (pg_temp.vread()->>'can_add_information')::boolean,
 'Archived patient does not receive new auxiliary configuration through minimal management');
update public.patients set archived_at=null where id=pg_temp.vid('patient');
update private.appointment_management_runtime set reschedule_enabled=false;
select extensions.ok((pg_temp.vread()->>'can_manage_reminders')::boolean
 and (pg_temp.vread()->>'can_add_information')::boolean and not (pg_temp.vread()->>'can_reschedule')::boolean,
 'A paused reschedule command does not become the authority for independent reminder or clinical scope');
update private.appointment_management_runtime set reschedule_enabled=true;

select extensions.ok((select v->>'id'=pg_temp.vid('appointment')::text and v->>'revision'=private.appointment_semantic_revision(pg_temp.vid('business'),pg_temp.vid('appointment'))
 and v->>'generation'='1' and v->>'schema_version'='1' and v->>'schedule_revision'='1' from (select pg_temp.vread() v) q),
 '1. Current appointment identity, revision, generation and schedule belong to one authorized read');
select extensions.ok((select (v->>'can_cancel')::boolean and (v->>'can_reschedule')::boolean and not (v->>'can_confirm')::boolean
 and v->'financial_terms'->>'kind'='unchanged' from (select pg_temp.vread() v) q),
 '2. Initial financial readiness and available actions describe the same current appointment');
select extensions.ok((select not (v ?| array['patient_id','internal_note','patients','answers','owner_id','patient_email'])
 and v::text not like '%PRIVATE-%' and v->>'patient_name'='Synthetic current patient' from (select pg_temp.vread() v) q),
 '3. Personal capability does not expose internal notes, private contact, clinical intake or unrelated identity fields');
do $$ declare before text; counts jsonb; after_counts jsonb; target timestamptz; v jsonb; begin
 before:=private.appointment_semantic_revision(pg_temp.vid('business'),pg_temp.vid('appointment'));
 select jsonb_build_array((select count(*) from private.appointment_management_capabilities),(select count(*) from private.appointment_management_operations),
  (select count(*) from public.appointment_deposit_events),(select count(*) from private.appointment_email_events),(select count(*) from public.audit_logs)) into counts;
 select starts_at+interval '3 hours' into target from public.appointments where id=pg_temp.vid('appointment');
 v:=pg_temp.vread('appointment',target);
 if v->'financial_terms'->>'kind'<>'new_requirement' or v->'financial_terms'->>'forfeit_amount'<>'40000' then raise exception 'E1_VIEW_TARGET_TERMS'; end if;
 select jsonb_build_array((select count(*) from private.appointment_management_capabilities),(select count(*) from private.appointment_management_operations),
  (select count(*) from public.appointment_deposit_events),(select count(*) from private.appointment_email_events),(select count(*) from public.audit_logs)) into after_counts;
 if counts is distinct from after_counts or private.appointment_semantic_revision(pg_temp.vid('business'),pg_temp.vid('appointment')) is distinct from before then
  raise exception 'E1_VIEW_OR_PREVIEW_WROTE_STATE'; end if;
end $$;
select extensions.pass('4. Open/preview issues no new credential and changes no state, acceptance, money, audit or email');

update public.appointment_email_policies set email_enabled=false,show_cancel=false,show_reschedule=false where business_id=pg_temp.vid('business');
select extensions.ok((select (v->>'can_cancel')::boolean and (v->>'can_reschedule')::boolean from (select pg_temp.vread() v) q),
 '5. Email preferences/button presentation do not revoke management permissions');
update public.businesses set public_booking_enabled=false where id=pg_temp.vid('business');
select extensions.ok((select (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean and not (v->>'new_booking_allowed')::boolean
 from (select pg_temp.vread() v) q),'6. Online booking off retains current consultation/cancellation, with no new slot offered');
update public.businesses set public_booking_enabled=true where id=pg_temp.vid('business');
update public.business_subscriptions set commercial_access_enabled=false,archived_at=now() where business_id=pg_temp.vid('business');
select extensions.ok((select (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean and not (v->>'can_confirm')::boolean
 from (select pg_temp.vread() v) q),'7. Archived access is the narrow own-appointment read/cancellation exception');
update public.business_subscriptions set commercial_access_enabled=true,archived_at=null where business_id=pg_temp.vid('business');
update private.appointment_management_runtime set reschedule_enabled=false;
select extensions.ok((select (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean from (select pg_temp.vread() v) q),
 '8. Reschedule operational pause leaves a coherent cancellation/contact route');
update private.appointment_management_runtime set reschedule_enabled=true;
update private.deposit_automation set enabled=false;
select extensions.ok((select (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean
 and v->'financial_terms'->>'unavailable_reason'='deposit_automation_paused' from (select pg_temp.vread() v) q),
 '9. Initial page uses the same financial pause as a selected target, without inventing a target date');
update private.deposit_automation set enabled=true;
update public.services set is_public=false where id=pg_temp.vid('service');
select extensions.ok((select (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean from (select pg_temp.vread() v) q),
 '10. A withdrawn service is not offered as an actionable self-service move');
update public.services set is_public=true,duration_minutes=90 where id=pg_temp.vid('service');
select extensions.is((pg_temp.vread()->>'reschedule_duration_minutes')::integer,90,
 '11. The selector gets current service duration without rewriting the already scheduled interval or accepted quote');
select extensions.ok((select not (v->>'can_confirm')::boolean and v->'deposit'->>'status'='pending'
 and v->>'deposit_transfer_details'='Synthetic transfer instructions' from (select pg_temp.vread('pending') v) q),
 '12. Paying a pending advance is not replaced by an attendance-confirmation button');

do $$ declare v_token text; begin
 select f.token into v_token from management_view_fixture f where label='appointment';
 perform public.apply_patient_appointment_management(v_token,false,gen_random_uuid(),
  private.appointment_semantic_revision(pg_temp.vid('business'),pg_temp.vid('appointment')),'cancel');
end $$;
select extensions.ok((select v->>'status'='cancelled' and not (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean
 and v->'financial_terms'='null'::jsonb and (v->>'new_booking_allowed')::boolean
 and not (v->>'can_add_information')::boolean and not (v->>'can_manage_reminders')::boolean
 and v->'financial_summary'->>'unresolved_amount'='40000' from (select pg_temp.vread() v) q),
 '13. Cancellation presents current state and unresolved money; no cancel/reschedule/retroactive financial offer');
update public.appointments set starts_at=now()-interval '2 hours',ends_at=now()-interval '1 hour' where id=pg_temp.vid('pending');
select extensions.ok((select (v->>'is_past')::boolean and not (v->>'can_cancel')::boolean and not (v->>'can_reschedule')::boolean
 and not (v->>'can_confirm')::boolean and not (v->>'can_add_information')::boolean
 and not (v->>'can_manage_reminders')::boolean and v->'financial_terms'='null'::jsonb and v->'deposit_transfer_details'='null'::jsonb
 from (select pg_temp.vread('pending') v) q),'14. Already-started appointment offers minimal consultation/contact, not agenda changes or a new payment request');
select public.revoke_appointment_management_access(pg_temp.vid('business'),pg_temp.vid('appointment'),gen_random_uuid(),
 private.appointment_semantic_revision(pg_temp.vid('business'),pg_temp.vid('appointment')));
select extensions.throws_ok($q$select pg_temp.vread()$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 '15. Revoked capability cannot obtain the current presentation or another credential');
select extensions.ok(has_function_privilege('service_role','public.get_patient_appointment_management_view(text,boolean,timestamptz)','EXECUTE')
 and not has_function_privilege('anon','public.get_patient_appointment_management_view(text,boolean,timestamptz)','EXECUTE')
 and not has_function_privilege('authenticated','public.get_patient_appointment_management_view(text,boolean,timestamptz)','EXECUTE'),
 '16. Only the validated backend reads this capability-bound projection; no direct anonymous API or tenant parameter');
select * from extensions.finish();
rollback;
