-- Operator agenda writes: current identity/permission, observed revision,
-- durable recovery and all-or-nothing effects. Owned disposable DB only.
begin;
select extensions.plan(25);
create temporary table staff_agenda_fixture(label text primary key,id uuid not null,extra jsonb);
grant select on staff_agenda_fixture to authenticated;
create function pg_temp.said(p_label text) returns uuid language sql as $$ select id from staff_agenda_fixture where label=p_label $$;
create function pg_temp.sarev(p_label text) returns text language sql as $$
 select private.appointment_semantic_revision(pg_temp.said('business'),pg_temp.said(p_label))
$$;
create function pg_temp.sacfg() returns bigint language sql as $$
 select booking_availability_revision from public.businesses where id=pg_temp.said('business')
$$;
create function pg_temp.satarget(p_label text) returns timestamptz language sql as $$
 select starts_at+interval '6 hours' from public.appointments where id=pg_temp.said(p_label)
$$;
create function pg_temp.sastate(p_label text) returns jsonb language sql as $$
 select jsonb_build_object('appointment',to_jsonb(a),'management',(select to_jsonb(m) from public.appointment_management_states m where m.appointment_id=a.id),
 'team',(select jsonb_agg(to_jsonb(t) order by professional_id) from public.appointment_professionals t where t.appointment_id=a.id),
 'projection',(select to_jsonb(d) from public.appointment_deposits d where d.appointment_id=a.id),
 'requirements',(select jsonb_agg(to_jsonb(r) order by ordinal) from public.appointment_deposit_requirements r where r.appointment_id=a.id),
 'events',(select jsonb_agg(to_jsonb(e) order by ordinal) from public.appointment_deposit_events e where e.appointment_id=a.id),
 'audit',(select count(*) from public.audit_logs where entity_id=a.id),'releases',(select count(*) from public.appointment_slot_releases where appointment_id=a.id),
 'email',(select count(*) from private.appointment_email_events where appointment_id=a.id),
 'operations',(select count(*) from private.appointment_management_operations where appointment_id=a.id))
 from public.appointments a where a.id=pg_temp.said(p_label)
$$;
create function pg_temp.sacall(p_label text,p_operation uuid,p_revision text,p_action text,p_target timestamptz default null,
 p_config bigint default null,p_actor uuid default null,p_replay boolean default false) returns jsonb language plpgsql as $$
declare result jsonb; previous_sub text:=current_setting('request.jwt.claim.sub',true); begin
 perform set_config('request.jwt.claim.sub','',true);
 begin
  result:=public.apply_staff_appointment_management(pg_temp.said('business'),coalesce(p_actor,pg_temp.said('owner')),
   pg_temp.said(p_label),p_operation,p_revision,p_action,p_target,false,p_config,null,p_replay);
 exception when others then perform set_config('request.jwt.claim.sub',coalesce(previous_sub,''),true); raise; end;
 perform set_config('request.jwt.claim.sub',coalesce(previous_sub,''),true); return result;
end $$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid();
 reception uuid:=gen_random_uuid(); professional uuid:=gen_random_uuid(); readonly_user uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid(); support_user uuid:=gen_random_uuid(); begin
 insert into auth.users(id,email) select actor,'staff-agenda-'||actor||'@example.test' from unnest(array[u,reception,professional,readonly_user,outsider,support_user]) actor;
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic staff agenda',b::text,'other','America/Argentina/Cordoba');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now()),(b,reception,'reception','active',now()),(b,professional,'professional','active',now()),(b,readonly_user,'readonly','active',now());
 insert into public.account_assistance_support_users(user_id,email,enabled) values(support_user,'staff-agenda-'||support_user||'@example.test',true);
 insert into public.professionals(id,business_id,name,is_public) values(p,b,'Synthetic staff professional',true);
 insert into public.services(id,business_id,name,duration_minutes,is_public) values(s,b,'Synthetic staff service',30,true);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into staff_agenda_fixture(label,id) values('business',b),('owner',u),('professional',p),('service',s),('reception',reception),('professional_user',professional),('readonly',readonly_user),('outsider',outsider),('support',support_user);
 update private.deposit_automation set enabled=true;
 update private.appointment_management_runtime set email_producer_enabled=true;
 insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details) values(b,true,true,'fixed',40000,'Synthetic transfer');
 perform set_config('request.jwt.claim.sub',u::text,true);
end $$;
create function pg_temp.sacase(p_label text,p_paid boolean default false) returns void language plpgsql as $$
declare patient uuid; a uuid; starts timestamptz; begin
 starts:=date_trunc('hour',now())+make_interval(days=>20+(select count(*)::integer from staff_agenda_fixture));
 insert into public.patients(business_id,owner_id,full_name) values(pg_temp.said('business'),pg_temp.said('owner'),'Synthetic staff '||p_label) returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,
  service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(pg_temp.said('business'),patient,pg_temp.said('professional'),pg_temp.said('service'),starts,starts+interval '30 minutes','reserved','manual','Synthetic staff service','Synthetic staff professional',30) returning id into a;
 update public.appointment_management_states set terms_acknowledged=true,require_deposit_on_reschedule=true,
  previous_deposit_disposition='forfeit',accepted_at=now(),accepted_policy_revision=1 where appointment_id=a;
 if p_paid then perform public.set_appointment_deposit(pg_temp.said('business'),a,'paid',1,null); end if;
 insert into staff_agenda_fixture values(p_label,a,null);
end $$;

select pg_temp.sacase('paid',true);
select extensions.is((select public.appointment_management_revision(a) from public.appointments a where a.id=pg_temp.said('paid')),pg_temp.sarev('paid'),
 '1. Displayed revision reuses the semantic authority in the same snapshot');
do $$ declare a public.appointments; expected text:=pg_temp.sarev('paid'); begin
 select * into a from public.appointments where id=pg_temp.said('paid'); a.patient_id:=gen_random_uuid();
 if public.appointment_management_revision(a) is distinct from expected then raise exception 'STAFF_COMPOSITE_TRUSTED'; end if;
 perform set_config('request.jwt.claim.sub',pg_temp.said('outsider')::text,true);
 if public.appointment_management_revision(a) is not null then raise exception 'STAFF_COMPUTED_SCOPE_LEAK'; end if;
 perform set_config('request.jwt.claim.sub',pg_temp.said('owner')::text,true);
end $$;
select extensions.pass('2. Fabricated composite contents do not bypass actual row visibility or change its digest');
select extensions.ok(not has_function_privilege('authenticated','public.apply_staff_appointment_management(uuid,uuid,uuid,uuid,text,text,timestamptz,boolean,bigint,text,boolean)','EXECUTE')
 and not has_function_privilege('anon','public.apply_staff_appointment_management(uuid,uuid,uuid,uuid,text,text,timestamptz,boolean,bigint,text,boolean)','EXECUTE')
 and has_function_privilege('service_role','public.apply_staff_appointment_management(uuid,uuid,uuid,uuid,text,text,timestamptz,boolean,bigint,text,boolean)','EXECUTE')
 and not has_function_privilege('authenticated','private.business_operation_actor(uuid,text[],uuid)','EXECUTE'),
 '3. Only the backend can execute the command; the delegated actor helper is private');
do $$ declare before jsonb:=pg_temp.sastate('paid'); target timestamptz:=pg_temp.satarget('paid'); r jsonb; begin
 r:=pg_temp.sacall('paid',gen_random_uuid(),pg_temp.sarev('paid'),'reschedule',target,pg_temp.sacfg());
 if r->>'status'<>'confirmed' or (r->>'starts_at')::timestamptz is distinct from target or (r->>'schedule_revision')::bigint<>2
  or (pg_temp.sastate('paid')->'projection') is distinct from before->'projection'
  or (pg_temp.sastate('paid')->'requirements') is distinct from before->'requirements'
  or (pg_temp.sastate('paid')->'events') is distinct from before->'events'
  or (select patient_id from public.appointments where id=pg_temp.said('paid'))::text is distinct from before#>>'{appointment,patient_id}'
  or exists(select 1 from public.appointment_deposit_requirements where appointment_id=pg_temp.said('paid') and allocation='forfeited') then raise exception 'STAFF_MOVE_PENALIZED'; end if;
end $$;
select extensions.pass('4. A staff move preserves paid money/identity and confirmation, without a patient forfeiture or new obligation');
select pg_temp.sacase('pending');
do $$ declare target timestamptz:=pg_temp.satarget('pending'); begin
 perform pg_temp.sacall('pending',gen_random_uuid(),pg_temp.sarev('pending'),'reschedule',target,pg_temp.sacfg(),pg_temp.said('reception'));
 if (select count(*) from public.appointment_deposit_requirements where appointment_id=pg_temp.said('pending'))<>1
  or not exists(select 1 from public.appointment_deposits where appointment_id=pg_temp.said('pending') and status='pending' and due_at=target-interval '48 hours')
  or not exists(select 1 from public.appointments where id=pg_temp.said('pending') and status='reserved') then raise exception 'STAFF_PENDING_DUPLICATED'; end if;
end $$;
select extensions.pass('5. Reception moves an unpaid appointment with one pending obligation and recalculated dates');
do $$ declare before jsonb:=pg_temp.sastate('paid'); r jsonb; begin
 r:=pg_temp.sacall('paid',gen_random_uuid(),pg_temp.sarev('paid'),'reschedule',(select starts_at from public.appointments where id=pg_temp.said('paid')),pg_temp.sacfg());
 if (r->>'changed')::boolean is distinct from false or (pg_temp.sastate('paid')-'operations') is distinct from (before-'operations') then raise exception 'STAFF_NOOP_EFFECT'; end if;
end $$;
select extensions.pass('6. A same-time move does not reset confirmation, deadlines, calendar, audit or events');
do $$ declare rev text:=pg_temp.sarev('paid'); before jsonb; begin
 perform pg_temp.sacall('paid',gen_random_uuid(),rev,'reschedule',pg_temp.satarget('paid'),pg_temp.sacfg()); before:=pg_temp.sastate('paid');
 begin perform pg_temp.sacall('paid',gen_random_uuid(),rev,'reschedule',pg_temp.satarget('paid'),pg_temp.sacfg()); raise exception 'STAFF_STALE_WROTE';
 exception when others then if sqlerrm<>'APPOINTMENT_MANAGEMENT_CHANGED' then raise; end if; end;
 if pg_temp.sastate('paid') is distinct from before then raise exception 'STAFF_STALE_PARTIAL'; end if;
end $$;
select extensions.pass('7. Two moves that retain Confirmed cannot overwrite one another using an old observed revision');
select pg_temp.sacase('replay',true);
do $$ declare op uuid:=gen_random_uuid(); rev text:=pg_temp.sarev('replay'); cfg bigint:=pg_temp.sacfg(); target timestamptz:=pg_temp.satarget('replay'); before jsonb; r jsonb; begin
 perform pg_temp.sacall('replay',op,rev,'reschedule',target,cfg); before:=pg_temp.sastate('replay');
 r:=pg_temp.sacall('replay',op,rev,'reschedule',target,cfg);
 if (r->>'idempotent_replay')::boolean is distinct from true or pg_temp.sastate('replay') is distinct from before then raise exception 'STAFF_REPLAY_EFFECT'; end if;
 update staff_agenda_fixture set extra=jsonb_build_object('operation',op,'revision',rev,'configuration',cfg,'target',target) where label='replay';
end $$;
select extensions.pass('8. Exact committed operation replay returns its receipt without a second change, audit or event');
do $$ declare r jsonb; before jsonb:=pg_temp.sastate('replay'); begin
 select extra into r from staff_agenda_fixture where label='replay';
 begin perform pg_temp.sacall('replay',(r->>'operation')::uuid,r->>'revision','reschedule',(r->>'target')::timestamptz+interval '1 hour',(r->>'configuration')::bigint); raise exception 'STAFF_REUSED_OPERATION';
 exception when others then if sqlerrm<>'APPOINTMENT_OPERATION_CONFLICT' then raise; end if; end;
 if pg_temp.sastate('replay') is distinct from before then raise exception 'STAFF_CONFLICT_EFFECT'; end if;
end $$;
select extensions.pass('9. An operation reused with a different payload cannot borrow the original receipt');
do $$ declare r jsonb; result jsonb; before jsonb:=pg_temp.sastate('replay'); begin
 select extra into r from staff_agenda_fixture where label='replay';
 update public.businesses set min_booking_notice_minutes=min_booking_notice_minutes+1 where id=pg_temp.said('business');
 result:=pg_temp.sacall('replay',(r->>'operation')::uuid,r->>'revision','reschedule',(r->>'target')::timestamptz,(r->>'configuration')::bigint,null,true);
 if (result->>'idempotent_replay')::boolean is distinct from true then raise exception 'STAFF_RECOVERY_PREFLIGHT'; end if;
 result:=pg_temp.sacall('replay',gen_random_uuid(),r->>'revision','reschedule',(r->>'target')::timestamptz,(r->>'configuration')::bigint,null,true);
 if result is not null or pg_temp.sastate('replay') is distinct from before then raise exception 'STAFF_ABSENT_RECOVERY_EXECUTED'; end if;
end $$;
select extensions.pass('10. Recovery precedes changed availability and never executes an absent operation');
select pg_temp.sacase('cancel',true);
do $$ declare before_sequence integer; rev text:=pg_temp.sarev('cancel'); begin
 select calendar_sequence into before_sequence from public.appointments where id=pg_temp.said('cancel');
 perform pg_temp.sacall('cancel',gen_random_uuid(),rev,'cancel');
 if not exists(select 1 from public.appointments where id=pg_temp.said('cancel') and status='cancelled' and calendar_sequence=before_sequence+1)
  or not exists(select 1 from public.appointment_deposit_requirements where appointment_id=pg_temp.said('cancel') and status='paid' and allocation='unresolved')
  or exists(select 1 from public.appointment_deposit_requirements where appointment_id=pg_temp.said('cancel') and allocation='forfeited') then raise exception 'STAFF_CANCEL_MONEY'; end if;
end $$;
select extensions.pass('11. Staff cancellation advances calendar sequence and preserves paid money as unresolved');
do $$ declare actor uuid; before jsonb:=pg_temp.sastate('pending'); begin
 foreach actor in array array[pg_temp.said('professional_user'),pg_temp.said('readonly'),pg_temp.said('outsider')] loop
  begin perform pg_temp.sacall('pending',gen_random_uuid(),pg_temp.sarev('pending'),'cancel',null,null,actor); raise exception 'STAFF_ROLE_BYPASS';
  exception when others then if sqlerrm<>'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
 end loop;
 if pg_temp.sastate('pending') is distinct from before then raise exception 'STAFF_ROLE_EFFECT'; end if;
end $$;
select extensions.pass('12. Professional, read-only and unrelated actors cannot borrow operator authority');
do $$ declare r jsonb; begin
 select extra into r from staff_agenda_fixture where label='replay';
 update public.business_users set disabled_at=clock_timestamp() where business_id=pg_temp.said('business') and user_id=pg_temp.said('owner');
 begin perform pg_temp.sacall('replay',(r->>'operation')::uuid,r->>'revision','reschedule',(r->>'target')::timestamptz,(r->>'configuration')::bigint,null,true); raise exception 'STAFF_REPLAY_REVOKED_ACTOR';
 exception when others then if sqlerrm<>'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
 update public.business_users set disabled_at=null where business_id=pg_temp.said('business') and user_id=pg_temp.said('owner');
end $$;
select extensions.pass('13. An old receipt does not authorize a staff member whose membership was revoked');
select pg_temp.sacase('audit');
create function pg_temp.reject_staff_audit() returns trigger language plpgsql as $$ begin
 if new.entity_id=pg_temp.said('audit') and new.action='appointment.rescheduled' then raise exception 'FORCED_STAFF_AUDIT_FAILURE'; end if; return new;
end $$;
create trigger reject_staff_audit before insert on public.audit_logs for each row execute function pg_temp.reject_staff_audit();
do $$ declare before jsonb:=pg_temp.sastate('audit'); begin
 begin perform pg_temp.sacall('audit',gen_random_uuid(),pg_temp.sarev('audit'),'reschedule',pg_temp.satarget('audit'),pg_temp.sacfg()); raise exception 'STAFF_AUDIT_PARTIAL_COMMIT';
 exception when others then if sqlerrm<>'FORCED_STAFF_AUDIT_FAILURE' then raise; end if; end;
 if pg_temp.sastate('audit') is distinct from before then raise exception 'STAFF_AUDIT_ROLLBACK_INCOMPLETE'; end if;
end $$;
drop trigger reject_staff_audit on public.audit_logs;
select extensions.pass('14. Audit failure rolls back agenda, deposit/history, releases, email events and receipt');
create function pg_temp.reject_staff_receipt() returns trigger language plpgsql as $$ begin
 if new.appointment_id=pg_temp.said('audit') then raise exception 'FORCED_STAFF_RECEIPT_FAILURE'; end if; return new;
end $$;
create trigger reject_staff_receipt before insert on private.appointment_management_operations for each row execute function pg_temp.reject_staff_receipt();
do $$ declare before jsonb:=pg_temp.sastate('audit'); begin
 begin perform pg_temp.sacall('audit',gen_random_uuid(),pg_temp.sarev('audit'),'reschedule',pg_temp.satarget('audit'),pg_temp.sacfg()); raise exception 'STAFF_RECEIPT_PARTIAL_COMMIT';
 exception when others then if sqlerrm<>'FORCED_STAFF_RECEIPT_FAILURE' then raise; end if; end;
 if pg_temp.sastate('audit') is distinct from before then raise exception 'STAFF_RECEIPT_ROLLBACK_INCOMPLETE'; end if;
end $$;
drop trigger reject_staff_receipt on private.appointment_management_operations;
select extensions.pass('15. Receipt failure also rolls back every local effect');
do $$ declare before jsonb:=pg_temp.sastate('audit'); target timestamptz; begin
 select starts_at into target from public.appointments where id=pg_temp.said('pending');
 begin perform pg_temp.sacall('audit',gen_random_uuid(),pg_temp.sarev('audit'),'reschedule',target,pg_temp.sacfg()); raise exception 'STAFF_OVERLAP_ALLOWED';
 exception when exclusion_violation then null; end;
 if pg_temp.sastate('audit') is distinct from before then raise exception 'STAFF_OVERLAP_PARTIAL'; end if;
end $$;
select extensions.pass('16. Real occupied-slot exclusion rejects the entire move');
select pg_temp.sacase('identity');
do $$ declare op uuid:=gen_random_uuid(); rev text:=pg_temp.sarev('identity'); cfg bigint:=pg_temp.sacfg(); target timestamptz:=pg_temp.satarget('identity'); replacement uuid; before jsonb; begin
 perform pg_temp.sacall('identity',op,rev,'reschedule',target,cfg);
 insert into public.patients(business_id,owner_id,full_name) values(pg_temp.said('business'),pg_temp.said('owner'),'Synthetic replacement') returning id into replacement;
 perform public.reassign_appointment_patient_safely(pg_temp.said('business'),pg_temp.said('identity'),replacement,pg_temp.said('owner'),'Synthetic identity correction');
 before:=pg_temp.sastate('identity');
 begin perform pg_temp.sacall('identity',op,rev,'reschedule',target,cfg,null,true); raise exception 'STAFF_RECOVERY_NEW_IDENTITY';
 exception when others then if sqlerrm<>'APPOINTMENT_OPERATION_CONFLICT' then raise; end if; end;
 if pg_temp.sastate('identity') is distinct from before then raise exception 'STAFF_IDENTITY_PARTIAL'; end if;
end $$;
select extensions.pass('17. Reassignment cannot retag a staff receipt or repeat its effects on the replacement patient');
select pg_temp.sacase('past');
do $$ declare target timestamptz:=pg_temp.satarget('past'); begin
 update public.appointments set starts_at=now()-interval '4 hours',ends_at=now()-interval '3 hours 30 minutes' where id=pg_temp.said('past');
 update public.services set duration_minutes=45 where id=pg_temp.said('service');
 perform pg_temp.sacall('past',gen_random_uuid(),pg_temp.sarev('past'),'reschedule',target,pg_temp.sacfg());
 if not exists(select 1 from public.appointments where id=pg_temp.said('past') and starts_at=target and ends_at=target+interval '45 minutes') then raise exception 'STAFF_PAST_DURATION_CONTRACT'; end if;
end $$;
select extensions.pass('18. Staff retains past-to-future movement and current service duration');
do $$ declare before jsonb:=pg_temp.sastate('audit'); begin
 begin perform pg_temp.sacall('audit',gen_random_uuid(),pg_temp.sarev('audit'),'confirm'); raise exception 'STAFF_PENDING_CONFIRMED';
 exception when others then if sqlerrm<>'APPOINTMENT_DEPOSIT_PENDING' then raise; end if; end;
 if pg_temp.sastate('audit') is distinct from before then raise exception 'STAFF_CONFIRM_PARTIAL'; end if;
end $$;
select extensions.pass('19. Internal confirmation still cannot bypass a pending deposit');
do $$ declare before jsonb:=pg_temp.sastate('audit'); begin
 insert into public.account_assistance_grants(business_id,requested_by_user_id,support_user_id,starts_at,expires_at)
 values(pg_temp.said('business'),pg_temp.said('owner'),pg_temp.said('support'),clock_timestamp()-interval '1 minute',clock_timestamp()+interval '0.1 seconds');
 if private.business_operation_actor(pg_temp.said('business'),array['admin'],pg_temp.said('support')) is distinct from 'admin' then raise exception 'STAFF_HELP_FIXTURE'; end if;
 perform pg_sleep(0.15);
 begin perform pg_temp.sacall('audit',gen_random_uuid(),pg_temp.sarev('audit'),'cancel',null,null,pg_temp.said('support')); raise exception 'STAFF_HELP_EXPIRED';
 exception when others then if sqlerrm<>'APPOINTMENT_MANAGEMENT_FORBIDDEN' then raise; end if; end;
 if pg_temp.sastate('audit') is distinct from before then raise exception 'STAFF_HELP_EFFECT'; end if;
end $$;
select extensions.pass('20. Delegated backend commands do not retain expired assistance authority');
select pg_temp.sacase('payment_window');
do $$ declare target timestamptz:=transaction_timestamp()+interval '72 hours'; begin
 -- The legacy trigger uses transaction-start time, incorrectly granting a full
 -- 24-hour payment window after any time spent in the transaction. The target
 -- is exactly that boundary, without a flaky sleep or browser/device clock.
 perform pg_temp.sacall('payment_window',gen_random_uuid(),pg_temp.sarev('payment_window'),'reschedule',target,pg_temp.sacfg());
 if not exists(select 1 from public.appointment_deposits where appointment_id=pg_temp.said('payment_window') and auto_cancel=false) then
  raise exception 'STAFF_PAYMENT_WINDOW_USED_TRANSACTION_CLOCK'; end if;
end $$;
select extensions.pass('21. The actual post-lock payment window cannot be extended by transaction-start time');
select extensions.ok(not has_table_privilege('authenticated','public.appointments','UPDATE')
 and not has_any_column_privilege('authenticated','public.appointments','UPDATE')
 and not has_table_privilege('anon','public.appointments','UPDATE')
 and has_table_privilege('service_role','public.appointments','UPDATE'),
 '22. Direct authenticated writes cannot bypass the command; backend telemetry keeps its grant');
select pg_temp.sacase('waived');
do $$ declare a public.appointments; before_time timestamptz; target timestamptz:=pg_temp.satarget('waived'); begin
 perform public.set_appointment_deposit(pg_temp.said('business'),pg_temp.said('waived'),'waived',1,null);
 update public.appointments set calendar_sequence=2,calendar_action_count=1,ignore_break=true where id=pg_temp.said('waived');
 select confirmed_at into before_time from public.appointments where id=pg_temp.said('waived');
 perform pg_temp.sacall('waived',gen_random_uuid(),pg_temp.sarev('waived'),'reschedule',target,pg_temp.sacfg());
 select * into a from public.appointments where id=pg_temp.said('waived');
 if a.status<>'confirmed' or a.confirmed_at is distinct from before_time or a.ignore_break or a.calendar_sequence<>3
  or a.calendar_update_required_at is null
  or not exists(select 1 from public.appointment_deposits where appointment_id=a.id and status='waived') then raise exception 'STAFF_WAIVER_CALENDAR_CONTRACT'; end if;
end $$;
select extensions.pass('23. Waiver preserves confirmation; movement advances an existing calendar and resets an unrequested break exception');
select pg_temp.sacase('no_calendar');
do $$ declare a public.appointments; begin
 update public.appointments set calendar_sequence=5,calendar_action_count=0,calendar_update_required_at=now() where id=pg_temp.said('no_calendar');
 perform pg_temp.sacall('no_calendar',gen_random_uuid(),pg_temp.sarev('no_calendar'),'reschedule',pg_temp.satarget('no_calendar'),pg_temp.sacfg());
 select * into a from public.appointments where id=pg_temp.said('no_calendar');
 if a.status<>'reserved' or a.confirmed_at is not null or a.calendar_sequence<>6 or a.calendar_update_required_at is not null then
  raise exception 'STAFF_UNUSED_CALENDAR_CONTRACT'; end if;
end $$;
select extensions.pass('24. Movement without a previous calendar action advances its sequence without inventing an update requirement');
do $$ declare before jsonb:=pg_temp.sastate('no_calendar'); appointment_id uuid:=pg_temp.said('no_calendar'); begin
 begin
  set local role authenticated;
  update public.appointments set status='cancelled' where id=appointment_id;
  raise exception 'STAFF_DIRECT_WRITE_BYPASS';
 exception when insufficient_privilege then null; end;
 reset role;
 if pg_temp.sastate('no_calendar') is distinct from before then raise exception 'STAFF_DIRECT_WRITE_PARTIAL'; end if;
end $$;
select extensions.pass('25. A real authenticated direct UPDATE is rejected without changing any agenda, money or audit state');
select * from extensions.finish();
rollback;
