-- SN14: actual money facts remain distinct from closed deposit obligations.
-- No provider/bank calls. All synthetic data and fault injection roll back.
begin;
select extensions.plan(20);
create temporary table late_fixture(label text primary key,value text not null);
create function pg_temp.lv(label text) returns text language sql as $$select value from late_fixture where late_fixture.label=$1$$;
create function pg_temp.lid(label text) returns uuid language sql as $$select pg_temp.lv($1)::uuid$$;
create function pg_temp.lrev() returns text language sql as $$select private.appointment_semantic_revision(pg_temp.lid('business'),pg_temp.lid('appointment'))$$;
create function pg_temp.lstate() returns jsonb language sql as $$select jsonb_build_object(
 'appointments',(select jsonb_agg(to_jsonb(a) order by id) from public.appointments a where business_id=pg_temp.lid('business')),
 'deposits',(select jsonb_agg(to_jsonb(d) order by appointment_id) from public.appointment_deposits d where business_id=pg_temp.lid('business')),
 'requirements',(select jsonb_agg(to_jsonb(r) order by ordinal) from public.appointment_deposit_requirements r where business_id=pg_temp.lid('business')),
 'events',(select jsonb_agg(to_jsonb(e) order by ordinal) from public.appointment_deposit_events e where business_id=pg_temp.lid('business')),
 'audit',(select jsonb_agg(to_jsonb(l) order by id) from public.audit_logs l where business_id=pg_temp.lid('business')),
 'operations',(select jsonb_agg(to_jsonb(o) order by operation_id) from private.appointment_management_operations o where business_id=pg_temp.lid('business')),
 'outbox',(select count(*) from private.appointment_email_events where business_id=pg_temp.lid('business')),
 'releases',(select count(*) from public.appointment_slot_releases where business_id=pg_temp.lid('business')))$$;
create function pg_temp.lcall(action text default 'record',amount text default '40000',target uuid default null,
 operation_id uuid default gen_random_uuid(),revision text default null,note text default null) returns jsonb language sql as $$
 select public.record_late_appointment_deposit(pg_temp.lid('business'),pg_temp.lid('appointment'),operation_id,
  coalesce(revision,pg_temp.lrev()),action,amount,target,note)$$;
create function pg_temp.lreject(expected text,action text default 'record',amount text default '40000',target uuid default null,
 operation_id uuid default gen_random_uuid(),revision text default null,note text default null) returns void language plpgsql as $$
declare before jsonb:=pg_temp.lstate(); begin
 begin perform pg_temp.lcall(action,amount,target,operation_id,revision,note); raise exception 'LATE_UNEXPECTED_SUCCESS';
 exception when others then if sqlerrm is distinct from expected then raise; end if; end;
 if pg_temp.lstate() is distinct from before then raise exception 'LATE_PARTIAL_STATE'; end if;
end $$;
do $$declare b uuid:=gen_random_uuid(); owner_id uuid:=gen_random_uuid(); reception_id uuid:=gen_random_uuid(); viewer_id uuid:=gen_random_uuid();
 patient_id uuid:=gen_random_uuid(); replacement_id uuid:=gen_random_uuid(); professional_id uuid:=gen_random_uuid(); service_id uuid:=gen_random_uuid(); a uuid; active_id uuid;
 starts timestamptz:=date_trunc('hour',clock_timestamp())+interval '36 hours'; begin
 insert into auth.users(id,email) select id,'late-'||id||'@example.test' from unnest(array[owner_id,reception_id,viewer_id]) id;
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Synthetic late deposit',b::text,'other','UTC');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,owner_id,'owner','active',now()),(b,reception_id,'reception','active',now()),(b,viewer_id,'readonly','active',now());
 insert into public.patients(id,business_id,owner_id,full_name,phone_e164) values(patient_id,b,owner_id,'Synthetic late patient','+5493512345678'),(replacement_id,b,owner_id,'Synthetic replacement','+5493512345679');
 insert into public.professionals(id,business_id,name) values(professional_id,b,'Synthetic professional');
 insert into public.services(id,business_id,name,duration_minutes) values(service_id,b,'Synthetic service',30);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,professional_id,service_id);
 update private.deposit_automation set enabled=true;
 insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details,applies_to_manual)
 values(b,true,true,'fixed',40000,'Synthetic transfer',true);
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot,created_at)
 values(b,patient_id,professional_id,service_id,starts,starts+interval '30 minutes','reserved','manual','Synthetic service','Synthetic professional',30,clock_timestamp()-interval '7 days') returning id into a;
 perform private.expire_unpaid_deposits();
 if not exists(select 1 from public.appointments ap join public.appointment_deposits d on d.appointment_id=ap.id where ap.id=a and ap.status='cancelled' and d.status='expired') then raise exception 'LATE_EXPIRY_FIXTURE_INVALID'; end if;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(b,patient_id,professional_id,service_id,starts+interval '10 days',starts+interval '10 days 30 minutes','reserved','manual','Synthetic service','Synthetic professional',30) returning id into active_id;
 insert into late_fixture values('business',b::text),('owner',owner_id::text),('reception',reception_id::text),('readonly',viewer_id::text),('patient',patient_id::text),('replacement',replacement_id::text),('appointment',a::text),('active',active_id::text);
end $$;
select set_config('request.jwt.claim.sub',pg_temp.lv('reception'),true);

select extensions.ok(has_function_privilege('authenticated','public.record_late_appointment_deposit(uuid,uuid,uuid,text,text,text,uuid,text)','EXECUTE')
 and has_function_privilege('authenticated','public.appointment_deposit_financials(public.appointments)','EXECUTE')
 and not exists(select 1 from unnest(array['anon','service_role']) role_name,
  unnest(array['public.record_late_appointment_deposit(uuid,uuid,uuid,text,text,text,uuid,text)','public.appointment_deposit_financials(public.appointments)']) signature
  where has_function_privilege(role_name,signature,'EXECUTE'))
 and not has_table_privilege('authenticated','public.appointment_deposit_events','INSERT,UPDATE,DELETE'),
 '1. Authenticated commands only; no backend actor impersonation or raw journal writes');

do $$declare amount text; begin
 foreach amount in array array[null,'','0','-1','1.5','1,5','40.000','1e3',' 1','01','1000000000001',repeat('9',100)] loop
  perform pg_temp.lreject('DEPOSIT_LATE_INVALID','record',amount); end loop;
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID',null);
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID','refund');
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID','record','1',gen_random_uuid());
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID','correct','1',gen_random_uuid());
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID','correct',null);
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID',revision=>'bad');
 perform pg_temp.lreject('DEPOSIT_LATE_INVALID',note=>repeat('x',301));
end $$;
select extensions.pass('2. Whole positive bounded pesos, action/target/revision and note are validated without effects');

select set_config('request.jwt.claim.sub',pg_temp.lv('readonly'),true);
select pg_temp.lreject('DEPOSIT_FORBIDDEN');
select set_config('request.jwt.claim.sub','',true);
select pg_temp.lreject('DEPOSIT_FORBIDDEN');
select set_config('request.jwt.claim.sub',pg_temp.lv('reception'),true);
update public.business_users set status='disabled',disabled_at=clock_timestamp() where business_id=pg_temp.lid('business') and user_id=pg_temp.lid('reception');
select pg_temp.lreject('DEPOSIT_FORBIDDEN');
update public.business_users set status='active',disabled_at=null where business_id=pg_temp.lid('business') and user_id=pg_temp.lid('reception');
do $$declare before jsonb:=pg_temp.lstate(); begin
 begin perform public.record_late_appointment_deposit(gen_random_uuid(),pg_temp.lid('appointment'),gen_random_uuid(),pg_temp.lrev(),'record','1'); raise exception 'LATE_FOREIGN_TENANT';
 exception when others then if sqlerrm<>'DEPOSIT_FORBIDDEN' then raise; end if; end;
 if before is distinct from pg_temp.lstate() then raise exception 'LATE_FOREIGN_EFFECT'; end if;
end $$;
select extensions.pass('3. Readonly, anonymous, disabled and foreign-tenant actors cannot record or recover facts');

do $$declare before jsonb:=pg_temp.lstate(); begin
 begin perform public.record_late_appointment_deposit(pg_temp.lid('business'),pg_temp.lid('active'),gen_random_uuid(),
 private.appointment_semantic_revision(pg_temp.lid('business'),pg_temp.lid('active')),'record','1'); raise exception 'LATE_ACTIVE_ACCEPTED';
 exception when others then if sqlerrm<>'DEPOSIT_LATE_REQUIRES_CANCELLED' then raise; end if; end;
 if before is distinct from pg_temp.lstate() then raise exception 'LATE_ACTIVE_EFFECT'; end if;
end $$;
select extensions.pass('4. A late-payment command cannot replace the ordinary active-deposit command');

insert into late_fixture values('before',pg_temp.lstate()::text),('revision',pg_temp.lrev()),('operation',gen_random_uuid()::text);
insert into late_fixture values('first',pg_temp.lcall(operation_id=>pg_temp.lid('operation'),note=>'Synthetic internal note')::text);
select extensions.ok((pg_temp.lstate()-'events'-'audit'-'operations')=(pg_temp.lv('before')::jsonb-'events'-'audit'-'operations')
 and pg_temp.lv('first')::jsonb->>'unresolved_amount'='40000'
 and exists(select 1 from public.appointment_deposit_events where id=(pg_temp.lv('first')::jsonb->>'event_id')::uuid and event_type='late_payment_recorded' and amount=40000 and actor_id=pg_temp.lid('reception') and metadata->>'note'='Synthetic internal note')
 and exists(select 1 from public.audit_logs where entity_id=pg_temp.lid('appointment') and action='appointment.late_deposit_recorded' and user_id=pg_temp.lid('reception'))
 and exists(select 1 from private.appointment_management_operations where operation_id=pg_temp.lid('operation') and actor_id=pg_temp.lid('reception') and origin='staff'),
 '5. Event, real actor, audit and receipt commit together without changing cancellation, closed obligation, release or outbox');

select pg_temp.lreject('APPOINTMENT_MANAGEMENT_CHANGED',revision=>pg_temp.lv('revision'));
select extensions.ok(pg_temp.lrev()<>pg_temp.lv('revision') and pg_temp.lrev()=pg_temp.lv('first')::jsonb->>'revision',
 '6. Economic journal advances the existing semantic revision without an appointment UPDATE');

do $$declare before jsonb:=pg_temp.lstate(); replay jsonb; begin
 replay:=pg_temp.lcall(operation_id=>pg_temp.lid('operation'),revision=>pg_temp.lv('revision'),note=>'Synthetic internal note');
 if replay->>'idempotent_replay'<>'true' or replay-'idempotent_replay'<>pg_temp.lv('first')::jsonb-'idempotent_replay'
  or before is distinct from pg_temp.lstate() then raise exception 'LATE_REPLAY_DUPLICATED'; end if;
end $$;
select extensions.pass('7. A lost accepted response recovers before mutable revision validation with no second fact/audit');

select pg_temp.lreject('APPOINTMENT_OPERATION_CONFLICT',operation_id=>pg_temp.lid('operation'),revision=>pg_temp.lv('revision'));
select set_config('request.jwt.claim.sub',pg_temp.lv('owner'),true);
select pg_temp.lreject('APPOINTMENT_OPERATION_CONFLICT',operation_id=>pg_temp.lid('operation'),revision=>pg_temp.lv('revision'),note=>'Synthetic internal note');
select set_config('request.jwt.claim.sub',pg_temp.lv('reception'),true);
select extensions.pass('8. Another payload or authorized actor cannot reuse the original operation receipt');

do $$declare snapshot jsonb; staff jsonb; a public.appointments; forged public.appointments; begin
 snapshot:=private.appointment_management_snapshot(pg_temp.lid('business'),pg_temp.lid('appointment'),null,clock_timestamp());
 select * into a from public.appointments where id=pg_temp.lid('appointment');
 forged:=a; forged.patient_id:=pg_temp.lid('replacement');
 staff:=public.appointment_deposit_financials(a);
 if snapshot->'financial_summary'<>jsonb_build_object('applied_amount','0','forfeited_amount','0','unresolved_amount','40000')
  or snapshot->'financial_summary'<>staff-'late_payments'-'late_payments_truncated'
  or staff<>public.appointment_deposit_financials(forged)
  or staff::text like '%Synthetic internal note%' or staff::text like '%actor_id%'
  or jsonb_array_length(staff->'late_payments')<>1 or staff->>'late_payments_truncated'<>'false'
  or snapshot->>'can_add_information'<>'false' or snapshot->>'can_manage_reminders'<>'false'
 then raise exception 'LATE_PROJECTION_INVALID'; end if;
 perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
 if public.appointment_deposit_financials(a) is not null then raise exception 'LATE_FOREIGN_READER'; end if;
 perform set_config('request.jwt.claim.sub',pg_temp.lv('reception'),true);
end $$;
select extensions.pass('9. Staff/public summaries agree; forged patient and foreign reader cannot expose another identity or private notes');

create function pg_temp.reject_late_audit() returns trigger language plpgsql as $$begin
 if new.entity_id=pg_temp.lid('appointment') and new.action in ('appointment.late_deposit_recorded','appointment.late_deposit_corrected') then raise exception 'SYNTHETIC_LATE_AUDIT_FAILURE'; end if; return new;
end $$;
create trigger synthetic_late_audit before insert on public.audit_logs for each row execute function pg_temp.reject_late_audit();
select pg_temp.lreject('SYNTHETIC_LATE_AUDIT_FAILURE');
select pg_temp.lreject('SYNTHETIC_LATE_AUDIT_FAILURE','correct',null,(pg_temp.lv('first')::jsonb->>'event_id')::uuid);
drop trigger synthetic_late_audit on public.audit_logs;
select extensions.pass('10. An audit failure rolls back both new receipts and attempted monetary facts/corrections');

create function pg_temp.reject_late_receipt() returns trigger language plpgsql as $$begin
 if new.appointment_id=pg_temp.lid('appointment') and new.action like 'late_deposit_%' then raise exception 'SYNTHETIC_LATE_RECEIPT_FAILURE'; end if; return new;
end $$;
create trigger synthetic_late_receipt before insert on private.appointment_management_operations for each row execute function pg_temp.reject_late_receipt();
select pg_temp.lreject('SYNTHETIC_LATE_RECEIPT_FAILURE');
select pg_temp.lreject('SYNTHETIC_LATE_RECEIPT_FAILURE','correct',null,(pg_temp.lv('first')::jsonb->>'event_id')::uuid);
drop trigger synthetic_late_receipt on private.appointment_management_operations;
select extensions.pass('11. A receipt failure after the audit leaves neither fact nor audit behind');

insert into late_fixture values('correction-operation',gen_random_uuid()::text),('correction-revision',pg_temp.lrev());
insert into late_fixture values('correction',pg_temp.lcall('correct',null,(pg_temp.lv('first')::jsonb->>'event_id')::uuid,pg_temp.lid('correction-operation'))::text);
select extensions.ok(pg_temp.lv('correction')::jsonb->>'unresolved_amount'='0'
 and exists(select 1 from public.appointment_deposit_events where id=(pg_temp.lv('correction')::jsonb->>'event_id')::uuid and event_type='recording_reversed' and corrects_event_id=(pg_temp.lv('first')::jsonb->>'event_id')::uuid and amount=40000)
 and exists(select 1 from public.appointment_deposit_events where id=(pg_temp.lv('first')::jsonb->>'event_id')::uuid and event_type='late_payment_recorded' and amount=40000)
 and (select status='expired' from public.appointment_deposits where appointment_id=pg_temp.lid('appointment')),
 '12. Correction links exactly one original immutable fact, subtracts its exact amount and never fabricates a refund or paid obligation');

select pg_temp.lreject('DEPOSIT_LATE_ALREADY_CORRECTED','correct',null,(pg_temp.lv('first')::jsonb->>'event_id')::uuid);
select pg_temp.lreject('DEPOSIT_LATE_RECORD_NOT_FOUND','correct',null,(pg_temp.lv('correction')::jsonb->>'event_id')::uuid);
select pg_temp.lreject('DEPOSIT_LATE_RECORD_NOT_FOUND','correct',null,gen_random_uuid());
do $$declare before jsonb:=pg_temp.lstate(); result jsonb; begin
 result:=pg_temp.lcall('correct',null,(pg_temp.lv('first')::jsonb->>'event_id')::uuid,pg_temp.lid('correction-operation'),pg_temp.lv('correction-revision'));
 if result->>'idempotent_replay'<>'true' or before is distinct from pg_temp.lstate() then raise exception 'LATE_CORRECTION_REPLAY'; end if;
end $$;
select extensions.pass('13. New corrections cannot reverse twice or target another correction; the identical retry recovers safely');

insert into late_fixture values('second',pg_temp.lcall(amount=>'25000')::text),('third',pg_temp.lcall(amount=>'15000')::text);
do $$declare before jsonb:=pg_temp.lstate(); begin
 begin perform public.reassign_appointment_patient_safely(pg_temp.lid('business'),pg_temp.lid('appointment'),pg_temp.lid('replacement'),pg_temp.lid('reception'),'Synthetic identity repair'); raise exception 'LATE_MONEY_REASSIGNED';
 exception when others then if sqlerrm<>'APPOINTMENT_DEPOSIT_IDENTITY_CHANGE' then raise; end if; end;
 if before is distinct from pg_temp.lstate() or private.appointment_late_deposit_balance(pg_temp.lid('business'),pg_temp.lid('appointment'),pg_temp.lid('patient'))<>40000 then raise exception 'LATE_IDENTITY_PARTIAL'; end if;
end $$;
select extensions.pass('14. All unresolved late records participate in the real identity-repair guard, even when the closed requirement is not paid');

select pg_temp.lcall('correct',null,(pg_temp.lv('second')::jsonb->>'event_id')::uuid) is not null;
select pg_temp.lcall('correct',null,(pg_temp.lv('third')::jsonb->>'event_id')::uuid) is not null;
select public.reassign_appointment_patient_safely(pg_temp.lid('business'),pg_temp.lid('appointment'),pg_temp.lid('replacement'),pg_temp.lid('reception'),'Synthetic repair after correcting mistaken records') is not null;
select pg_temp.lreject('APPOINTMENT_OPERATION_CONFLICT',operation_id=>pg_temp.lid('operation'),revision=>pg_temp.lv('revision'),note=>'Synthetic internal note');
select extensions.ok(private.appointment_deposit_summary(pg_temp.lid('business'),pg_temp.lid('appointment'),pg_temp.lid('replacement'))->>'unresolved_amount'='0'
 and not exists(select 1 from public.appointment_deposit_requirements where appointment_id=pg_temp.lid('appointment') and is_current)
 and (select count(*)=3 from public.appointment_deposit_events where appointment_id=pg_temp.lid('appointment') and event_type='late_payment_recorded'),
 '15. Correcting mistaken records allows ordinary repair; old receipts/history cannot become the replacement patient money or authority');

do $$declare before jsonb:=pg_temp.lstate(); begin
 update public.appointments set status='cancelled' where id=pg_temp.lid('active');
 before:=pg_temp.lstate();
 begin perform public.record_late_appointment_deposit(pg_temp.lid('business'),pg_temp.lid('active'),pg_temp.lid('operation'),
 private.appointment_semantic_revision(pg_temp.lid('business'),pg_temp.lid('active')),'record','40000'); raise exception 'LATE_OP_REASSIGNED';
 exception when others then if sqlerrm<>'APPOINTMENT_OPERATION_CONFLICT' then raise; end if; end;
 if before is distinct from pg_temp.lstate() then raise exception 'LATE_OP_REASSIGNED_EFFECT'; end if;
end $$;
select extensions.pass('16. An operation identifier is scoped to its original appointment as well as actor/payload');

update public.appointments set starts_at=starts_at-interval '40 days',ends_at=ends_at-interval '40 days' where id=pg_temp.lid('active');
do $$declare result jsonb; begin
 result:=public.record_late_appointment_deposit(pg_temp.lid('business'),pg_temp.lid('active'),gen_random_uuid(),
  private.appointment_semantic_revision(pg_temp.lid('business'),pg_temp.lid('active')),'record','1');
 if result->>'unresolved_amount'<>'1' or (select status from public.appointments where id=pg_temp.lid('active'))<>'cancelled' then raise exception 'LATE_PAST_MONEY_LOST'; end if;
end $$;
select extensions.pass('17. Factual staff money recording remains possible after the cancelled appointment time');

select pg_temp.lreject('DEPOSIT_NOT_FOUND');
select extensions.pass('18. A repaired appointment without its own deposit requirement cannot inherit a former obligation');

do $$begin
 begin update public.appointment_deposit_events set amount=1 where id=(pg_temp.lv('first')::jsonb->>'event_id')::uuid; raise exception 'LATE_HISTORY_REWRITTEN';
 exception when others then if sqlerrm<>'APPOINTMENT_DEPOSIT_EVENT_IMMUTABLE' then raise; end if; end;
end $$;
select extensions.pass('19. New late-payment facts remain append-only, like all earlier deposit events');

delete from public.appointments where id in (pg_temp.lid('appointment'),pg_temp.lid('active'));
select extensions.ok(not exists(select 1 from public.appointment_deposit_events where business_id=pg_temp.lid('business'))
 and not exists(select 1 from private.appointment_management_operations where business_id=pg_temp.lid('business')),
 '20. Owned appointment cleanup cascades facts and their correction references without dangling records');
select * from extensions.finish();
rollback;
