-- E1: revocable management, independent from calendar identity. No real email.
begin;
select extensions.plan(33);
create temporary table management_access_fixture(label text primary key,value text not null);
create function pg_temp.access_value(p_label text) returns text language sql as $$
 select value from management_access_fixture where label=p_label
$$;
create function pg_temp.access_id(p_label text) returns uuid language sql as $$
 select pg_temp.access_value(p_label)::uuid
$$;
create function pg_temp.access_resolve(p_label text,p_legacy boolean default false) returns jsonb language sql as $$
 select public.resolve_appointment_management_access(pg_temp.access_value(p_label),p_legacy)
$$;
create function pg_temp.access_issue(p_label text,p_generation bigint) returns void language plpgsql as $$ begin
 insert into management_access_fixture values(p_label,public.issue_appointment_management_capability(
  pg_temp.access_id('business'),pg_temp.access_id('appointment'),p_generation));
end $$;
do $$
declare b uuid:=gen_random_uuid(); b2 uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid();
 p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); patient uuid; a uuid; calendar_token text;
begin
 insert into auth.users(id,email) values(u,'capability-'||u||'@example.test'),(outsider,'capability-'||outsider||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Capability E1',b::text,'other','America/Argentina/Cordoba'),
  (b2,'Other capability E1',b2::text,'other','America/Argentina/Cordoba');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id in(b,b2);
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now()),(b2,outsider,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'Capability professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Capability service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into public.patients(owner_id,business_id,full_name) values(u,b,'Capability synthetic patient') returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient,p,s,now()+interval '10 days',now()+interval '10 days 1 hour',now()+interval '10 days',now()+interval '10 days 1 hour',
  'reserved','manual','Capability service','Capability professional',60) returning id,confirmation_token into a,calendar_token;
 insert into management_access_fixture values('business',b::text),('other_business',b2::text),('owner',u::text),('outsider',outsider::text),
  ('appointment',a::text),('calendar_token',calendar_token),('revision',private.appointment_semantic_revision(b,a)),('revoke_operation',gen_random_uuid()::text);
end $$;

select pg_temp.access_issue('capability',1);
select extensions.ok(pg_temp.access_value('capability') ~ '^[0-9a-f]{64}$'
 and pg_temp.access_value('capability')<>pg_temp.access_value('calendar_token'),'1. Management credential is opaque, separate from the calendar token');
select extensions.is((select count(*) from private.appointment_management_capabilities
 where business_id=pg_temp.access_id('business') and appointment_id=pg_temp.access_id('appointment')
 and token_hash=encode(extensions.digest(pg_temp.access_value('capability'),'sha256'),'hex')),1::bigint,'2. Only the digest is persisted in the capability lookup');
select extensions.ok((pg_temp.access_resolve('capability')->>'appointment_id')=pg_temp.access_value('appointment')
 and (pg_temp.access_resolve('capability')->>'business_id')=pg_temp.access_value('business')
 and (pg_temp.access_resolve('capability')->>'revision')=pg_temp.access_value('revision'),'3. Capability resolves only its appointment and current revision');
select extensions.is(pg_temp.access_resolve('calendar_token',true)->>'appointment_id',pg_temp.access_value('appointment'),
 '4. Legacy access works before its first revocation');

do $$ declare bad text; begin
 foreach bad in array array[null::text,'','wrong','0000000000000000000000000000000000000000000000000000000000000000'] loop
  begin
   perform public.resolve_appointment_management_access(bad,false);
   raise exception 'E1_INVALID_CAPABILITY_ACCEPTED';
  exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 end loop;
end $$;
select extensions.pass('5. Malformed, absent and unknown capabilities fail uniformly');
do $$ begin
 begin
  perform public.issue_appointment_management_capability(pg_temp.access_id('business'),pg_temp.access_id('appointment'),2);
  raise exception 'E1_STALE_GENERATION_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_CHANGED' then raise; end if; end;
 begin
  perform public.issue_appointment_management_capability(pg_temp.access_id('other_business'),pg_temp.access_id('appointment'),1);
  raise exception 'E1_FOREIGN_ISSUANCE_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
end $$;
select extensions.pass('6. Issuance cannot cross a tenant or use a stale generation');

select set_config('request.jwt.claim.sub',pg_temp.access_value('owner'),true);
do $$ declare result jsonb; begin
 result:=public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),
  pg_temp.access_id('revoke_operation'),pg_temp.access_value('revision'));
 if (result->>'generation')::bigint is distinct from 2 then raise exception 'E1_REVOCATION_DID_NOT_ADVANCE'; end if;
end $$;
select extensions.ok((select generation=2 and not legacy_management_allowed from public.appointment_management_states
 where business_id=pg_temp.access_id('business') and appointment_id=pg_temp.access_id('appointment')),'7. Revocation disables both current and legacy credentials');
do $$ declare label text; begin
 foreach label in array array['capability','calendar_token'] loop
  begin
   perform pg_temp.access_resolve(label,label='calendar_token');
   raise exception 'E1_REVOKED_CREDENTIAL_ACCEPTED';
  exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 end loop;
end $$;
select extensions.pass('8. Old capability and legacy token can no longer resolve management access');
select extensions.is((select confirmation_token from public.appointments where id=pg_temp.access_id('appointment')),pg_temp.access_value('calendar_token'),
 '9. Revocation preserves stable calendar identity');
do $$ declare result jsonb; begin
 result:=public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),
  pg_temp.access_id('revoke_operation'),pg_temp.access_value('revision'));
 if (result->>'generation')::bigint is distinct from 2 then raise exception 'E1_DUPLICATE_REVOCATION'; end if;
end $$;
select extensions.is((select count(*) from public.audit_logs where business_id=pg_temp.access_id('business')
 and entity_id=pg_temp.access_id('appointment') and action='appointment.management_access_revoked'),1::bigint,
 '10. Replaying the same revocation does not revoke again or duplicate audit');
select pg_temp.access_issue('new_capability',2);
select extensions.is(pg_temp.access_resolve('new_capability')->>'generation','2','11. A newly authorized generation works after revocation');
do $$ begin
 begin
  perform public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),
   pg_temp.access_id('revoke_operation'),repeat('0',64));
  raise exception 'E1_OPERATION_PAYLOAD_REUSE_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_OPERATION_CONFLICT' then raise; end if; end;
 begin
  perform public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),
   gen_random_uuid(),pg_temp.access_value('revision'));
  raise exception 'E1_STALE_REVOCATION_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_CHANGED' then raise; end if; end;
end $$;
select extensions.pass('12. Reusing an operation with different input or a stale summary cannot change access');
select set_config('request.jwt.claim.sub',pg_temp.access_value('outsider'),true);
do $$ begin
 begin
  perform public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),
   gen_random_uuid(),pg_temp.access_resolve('new_capability')->>'revision');
  raise exception 'E1_FOREIGN_REVOCATION_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
end $$;
select extensions.pass('13. A different practice owner cannot revoke this appointment');
select set_config('request.jwt.claim.sub',pg_temp.access_value('owner'),true);
update public.business_users set disabled_at=now() where business_id=pg_temp.access_id('business') and user_id=pg_temp.access_id('owner');
do $$ begin
 begin
  perform public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),
   pg_temp.access_id('revoke_operation'),pg_temp.access_value('revision'));
  raise exception 'E1_REVOKED_ACTOR_REPLAY_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
end $$;
select extensions.pass('14. Replay still revalidates staff authorization after membership revocation');
update public.business_users set disabled_at=null where business_id=pg_temp.access_id('business') and user_id=pg_temp.access_id('owner');

update private.appointment_management_capabilities set expires_at=now()-interval '1 second'
 where token_hash=encode(extensions.digest(pg_temp.access_value('new_capability'),'sha256'),'hex');
do $$ begin
 begin perform pg_temp.access_resolve('new_capability'); raise exception 'E1_EXPIRED_CAPABILITY_ACCEPTED';
 exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
end $$;
select extensions.pass('15. Expired access cannot be used');
select pg_temp.access_issue('failure_capability',2);
create function pg_temp.fail_management_audit() returns trigger language plpgsql as $$ begin
 if new.business_id=pg_temp.access_id('business') and new.action='appointment.management_access_revoked' then raise exception 'E1_PROVOKED_REVOCATION_AUDIT'; end if;
 return new;
end $$;
create trigger e1_management_audit_failure before insert on public.audit_logs for each row execute function pg_temp.fail_management_audit();
do $$ declare before text:=pg_temp.access_resolve('failure_capability')->>'revision'; operations bigint; begin
 select count(*) into operations from private.appointment_management_operations where business_id=pg_temp.access_id('business');
 begin
  perform public.revoke_appointment_management_access(pg_temp.access_id('business'),pg_temp.access_id('appointment'),gen_random_uuid(),before);
  raise exception 'E1_REVOCATION_FAILURE_NOT_PROVOKED';
 exception when others then if sqlerrm is distinct from 'E1_PROVOKED_REVOCATION_AUDIT' then raise; end if; end;
 if (pg_temp.access_resolve('failure_capability')->>'revision') is distinct from before
  or (select count(*) from private.appointment_management_operations where business_id=pg_temp.access_id('business')) is distinct from operations then
  raise exception 'E1_PARTIAL_REVOCATION'; end if;
end $$;
select extensions.pass('16. Failure of audit rolls back generation, legacy access and operation receipt');

select extensions.ok(not has_function_privilege('anon','public.resolve_appointment_management_access(text,boolean)','EXECUTE')
 and not has_function_privilege('authenticated','public.resolve_appointment_management_access(text,boolean)','EXECUTE')
 and has_function_privilege('service_role','public.resolve_appointment_management_access(text,boolean)','EXECUTE'),
 '17. Resolving raw credentials is a backend-only API');
select extensions.ok(not has_function_privilege('anon','public.issue_appointment_management_capability(uuid,uuid,bigint)','EXECUTE')
 and not has_function_privilege('authenticated','public.issue_appointment_management_capability(uuid,uuid,bigint)','EXECUTE')
 and has_function_privilege('service_role','public.issue_appointment_management_capability(uuid,uuid,bigint)','EXECUTE'),
 '18. A public client cannot mint replacement credentials');
select extensions.ok(not has_table_privilege('anon','private.appointment_management_capabilities','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('authenticated','private.appointment_management_capabilities','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('service_role','private.appointment_management_capabilities','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('service_role','private.appointment_management_operations','SELECT,INSERT,UPDATE,DELETE'),
 '19. No Data API role reads/writes capability digests or operation receipts directly');
select extensions.is((select generation from public.appointment_management_states where business_id=pg_temp.access_id('business')
 and appointment_id=pg_temp.access_id('appointment')),2::bigint,'20. All rejected/failed operations leave the one successful revocation intact');
-- Email is a delivery address, not patient identity. Changing it revokes every
-- older management link, including legacy and A -> B -> A, without altering the
-- calendar token or invalidating another patient sharing that family address.
do $$ declare a public.appointments; fresh uuid; sibling uuid; sibling_appointment uuid; begin
 select * into strict a from public.appointments where id=pg_temp.access_id('appointment');
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(a.business_id,a.patient_id,a.professional_id,a.service_id,a.starts_at+interval '2 days',a.ends_at+interval '2 days',
  a.blocking_starts_at+interval '2 days',a.blocking_ends_at+interval '2 days','reserved','manual','Contact service','Contact professional',60)
 returning id,confirmation_token into fresh,a.confirmation_token;
 insert into management_access_fixture values('contact_appointment',fresh::text),('contact_legacy',a.confirmation_token),
  ('contact_before',public.issue_appointment_management_capability(a.business_id,fresh,1)),
  ('contact_agenda_revision',private.appointment_semantic_revision(a.business_id,fresh));
 insert into public.patients(owner_id,business_id,full_name,email)
 values(pg_temp.access_id('owner'),a.business_id,'Separate family patient','family-a@example.test') returning id into sibling;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(a.business_id,sibling,a.professional_id,a.service_id,a.starts_at+interval '3 days',a.ends_at+interval '3 days',
  a.blocking_starts_at+interval '3 days',a.blocking_ends_at+interval '3 days','reserved','manual','Contact service','Contact professional',60)
 returning id into sibling_appointment;
 insert into management_access_fixture values('family_capability',public.issue_appointment_management_capability(a.business_id,sibling_appointment,1));
 update public.patients set email='family-a@example.test' where business_id=a.business_id and id=a.patient_id;
end $$;
select extensions.throws_ok($q$select pg_temp.access_resolve('contact_before')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 '21. Adding or correcting email revokes previously issued management capabilities');
select extensions.throws_ok($q$select pg_temp.access_resolve('contact_legacy',true)$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 '22. Email correction also closes the original legacy management token');
insert into management_access_fixture values('contact_a',public.issue_appointment_management_capability(
 pg_temp.access_id('business'),pg_temp.access_id('contact_appointment'),1));
update public.patients set email='  family-a@example.test  ',activity_at=clock_timestamp()
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
select extensions.is(pg_temp.access_resolve('contact_a')->>'appointment_id',pg_temp.access_value('contact_appointment'),
 '23. Outer spaces and unrelated activity do not revoke a still identical delivery address');
update public.patients set email='family-b@example.test'
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
insert into management_access_fixture values('contact_b',public.issue_appointment_management_capability(
 pg_temp.access_id('business'),pg_temp.access_id('contact_appointment'),1));
update public.patients set email='family-a@example.test'
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
do $$ declare label text; begin
 foreach label in array array['contact_before','contact_legacy','contact_a','contact_b','failure_capability'] loop
  begin
   perform pg_temp.access_resolve(label,label='contact_legacy');
   raise exception 'E1_EMAIL_ABA_RESTORED_OLD_ACCESS';
  exception when others then if sqlerrm is distinct from 'APPOINTMENT_LINK_UNAVAILABLE' then raise; end if; end;
 end loop;
end $$;
select extensions.pass('24. A -> B -> A never revives older links, including another appointment of the same patient');
select extensions.ok(pg_temp.access_resolve('family_capability')->>'appointment_id' is not null
 and (select confirmation_token from public.appointments where id=pg_temp.access_id('contact_appointment'))=pg_temp.access_value('contact_legacy'),
 '25. Shared family addresses stay separate identities and stable calendar tokens do not rotate');
insert into management_access_fixture values('contact_current',public.issue_appointment_management_capability(
 pg_temp.access_id('business'),pg_temp.access_id('contact_appointment'),1));
do $$ declare patient uuid; begin
 select patient_id into strict patient from public.appointments where id=pg_temp.access_id('contact_appointment');
 begin
  update public.patients set email='rolled-back@example.test' where id=patient;
  raise exception 'E1_PROVOKED_CONTACT_ROLLBACK';
 exception when others then if sqlerrm is distinct from 'E1_PROVOKED_CONTACT_ROLLBACK' then raise; end if; end;
 end;
end $$;
select extensions.is(pg_temp.access_resolve('contact_current')->>'appointment_id',pg_temp.access_value('contact_appointment'),
 '26. A rolled back patient edit does not revoke current access or leave a partial generation');
update public.patients set email=null
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
select extensions.throws_ok($q$select pg_temp.access_resolve('contact_current')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 '27. Removing an email also revokes the previously delivered management credential');
select extensions.ok((select p.email_contact_revision=5 and
 (select count(*) from private.patient_email_contact_events e where e.patient_id=p.id)=4
 from public.patients p join public.appointments a on a.patient_id=p.id where a.id=pg_temp.access_id('contact_appointment')),
 '28. Exactly the four committed address changes have durable contact events; rollback and activity leave none');
update public.patients set email_contact_revision=1,email='  '
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
select extensions.is((select p.email_contact_revision from public.patients p join public.appointments a on a.patient_id=p.id
 where a.id=pg_temp.access_id('contact_appointment')),5::bigint,
 '29. A writer cannot reset the authority revision, including a normalized null-to-empty edit');
update public.patients set email_contact_revision=1,email='family-z@example.test'
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
select extensions.is((select p.email_contact_revision from public.patients p join public.appointments a on a.patient_id=p.id
 where a.id=pg_temp.access_id('contact_appointment')),6::bigint,
 '30. A simultaneous address/revision assignment advances from the persisted revision, never supplied input');
select extensions.ok(not has_table_privilege('anon','private.patient_email_contact_events','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('authenticated','private.patient_email_contact_events','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('service_role','private.patient_email_contact_events','SELECT,INSERT,UPDATE,DELETE')
 and not has_function_privilege('service_role','private.advance_patient_email_contact_revision()','EXECUTE'),
 '31. Contact events and authority trigger have no directly callable Data API privilege');
select extensions.is(private.appointment_semantic_revision(pg_temp.access_id('business'),pg_temp.access_id('contact_appointment')),
 pg_temp.access_value('contact_agenda_revision'),
 '32. Contact edits do not fabricate an agenda/economic revision or change accepted conditions');
insert into management_access_fixture values('local_case_capability',public.issue_appointment_management_capability(
 pg_temp.access_id('business'),pg_temp.access_id('contact_appointment'),1));
update public.patients set email='FAMILY-Z@example.test'
 where id=(select patient_id from public.appointments where id=pg_temp.access_id('contact_appointment'));
select extensions.throws_ok($q$select pg_temp.access_resolve('local_case_capability')$q$,'P0001','APPOINTMENT_LINK_UNAVAILABLE',
 '33. Different local-part case is not silently treated as an equivalent mailbox');
select * from extensions.finish();
rollback;
