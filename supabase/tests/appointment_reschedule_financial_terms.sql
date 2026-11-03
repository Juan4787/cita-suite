-- E1: financial preview only. The later command contract must prove that these
-- terms and the actual appointment/money/events commit together. No real money.
begin;
select extensions.plan(19);
create temporary table financial_fixture(label text primary key,id uuid not null);
create function pg_temp.fid(p_label text) returns uuid language sql as $$
 select id from financial_fixture where label=p_label
$$;
create function pg_temp.fin_terms(p_label text,p_target timestamptz default null) returns jsonb language sql as $$
 select private.appointment_reschedule_financial_terms(a.business_id,a.id,coalesce(p_target,a.starts_at+interval '3 days'),now())
 from public.appointments a where a.id=pg_temp.fid(p_label)
$$;
create function pg_temp.fin_core(p_label text) returns jsonb language sql as $$
 select jsonb_build_array(t->'kind',t->'amount',t->'forfeit_amount',t->'credit_amount',t->'quote_amount')
 from (select pg_temp.fin_terms(p_label) t) q
$$;
do $$ declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid(); begin
 insert into auth.users(id,email) values(u,'financial-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Financial E1',b::text,'other','America/Argentina/Cordoba');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'Financial professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'Financial service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 insert into financial_fixture values('business',b),('owner',u),('professional',p),('service',s);
 update private.deposit_automation set enabled=true;
 insert into public.deposit_policies(business_id,enabled,auto_cancel_enabled,amount_mode,fixed_amount,transfer_details)
 values(b,true,true,'fixed',40000,'Synthetic financial fixture');
 perform set_config('request.jwt.claim.sub',u::text,true);
end $$;
create function pg_temp.fin_case(p_label text,p_require boolean,p_disposition text,p_status text default 'paid',
 p_quote bigint default null,p_informed boolean default true) returns void language plpgsql as $$
declare a uuid; patient uuid; starts timestamptz; rev bigint;
begin
 -- Use the real price-snapshot trigger, not an UPDATE that it would overwrite.
 delete from public.service_price_policies where business_id=pg_temp.fid('business');
 if p_quote is not null then
  insert into public.service_price_policies(business_id,service_id,base_amount,base_month,first_adjustment_month,monthly_percentage)
  values(pg_temp.fid('business'),pg_temp.fid('service'),p_quote,date_trunc('month',now())::date,
   (date_trunc('month',now())+interval '1 month')::date,0);
 end if;
 update public.appointment_email_policies set require_deposit_on_reschedule=p_require,previous_deposit_disposition=p_disposition,
  revision=revision+1 where business_id=pg_temp.fid('business');
 starts:=date_trunc('hour',now())+make_interval(days=>10+(select count(*)::integer from financial_fixture));
 insert into public.patients(owner_id,business_id,full_name) values(pg_temp.fid('owner'),pg_temp.fid('business'),'Financial synthetic '||p_label) returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(pg_temp.fid('business'),patient,pg_temp.fid('professional'),pg_temp.fid('service'),starts,starts+interval '1 hour',starts,starts+interval '1 hour',
  'reserved','manual','Financial service','Financial professional',60) returning id into a;
 insert into financial_fixture values(p_label,a);
 update public.appointment_management_states set terms_acknowledged=p_informed,require_deposit_on_reschedule=p_informed and p_require,
  previous_deposit_disposition=case when p_informed then p_disposition else 'credit' end,
  accepted_at=case when p_informed then now() end,
  accepted_policy_revision=case when p_informed then (select revision from public.appointment_email_policies where business_id=pg_temp.fid('business')) end
 where appointment_id=a;
 if p_status<>'pending' then
  select revision into rev from public.appointment_deposits where appointment_id=a;
  perform public.set_appointment_deposit(pg_temp.fid('business'),a,p_status,rev,null);
 end if;
end $$;

select pg_temp.fin_case('forfeit_new',true,'forfeit');
select extensions.is(pg_temp.fin_core('forfeit_new'),'["new_requirement","40000","40000","0",null]'::jsonb,
 '1. Informed default: only the current applicable payment is forfeited and a new deposit is required');
select pg_temp.fin_case('credit_new',true,'credit');
select extensions.is(pg_temp.fin_core('credit_new'),'["new_requirement","40000","0","40000",null]'::jsonb,
 '2. New deposit plus previous money at credit remain distinct');
select pg_temp.fin_case('credit_no_new',false,'credit');
select extensions.is(pg_temp.fin_core('credit_no_new'),'["none",null,"0","40000",null]'::jsonb,
 '3. No new requirement does not manufacture another payment');
select pg_temp.fin_case('forfeit_no_new',false,'forfeit');
select extensions.is(pg_temp.fin_core('forfeit_no_new'),'["none",null,"40000","0",null]'::jsonb,
 '4. Forfeit without another advance is not represented as payment of the full consultation');
select pg_temp.fin_case('unpaid',true,'forfeit','pending');
select extensions.is(pg_temp.fin_core('unpaid'),'["reuse_pending","40000","0","0",null]'::jsonb,
 '5. An unpaid move reuses one obligation, with no fictitious forfeited money');
select pg_temp.fin_case('waived',true,'credit','waived');
select extensions.is(pg_temp.fin_core('waived'),'["new_requirement","40000","0","0",null]'::jsonb,
 '6. A one-off waiver is not cash and does not waive a later informed obligation');
select pg_temp.fin_case('legacy',true,'forfeit','paid',null,false);
select extensions.is(pg_temp.fin_core('legacy'),'["none",null,"0","40000",null]'::jsonb,
 '7. No informed original terms: no retroactive forfeit or new charge');
select pg_temp.fin_case('capped',true,'credit','paid',50000);
select extensions.is(pg_temp.fin_core('capped'),'["new_requirement","10000","0","40000","50000"]'::jsonb,
 '8. Known quote limits the new advance to the positive amount after applicable recorded deposits');
select extensions.is((pg_temp.fin_terms('capped')->>'base_amount')::bigint,40000::bigint,
 '9. A reduced advance does not replace the original base for future reschedules');
select pg_temp.fin_case('covered',true,'credit','paid',40000);
select extensions.is(pg_temp.fin_core('covered'),'["none",null,"0","40000","40000"]'::jsonb,
 '10. No positive quote remainder means no additional advance, not a fictitious payment');
select pg_temp.fin_case('unknown',true,'credit','paid',null);
select extensions.is(pg_temp.fin_core('unknown'),'["new_requirement","40000","0","40000",null]'::jsonb,
 '11. An absent quote stays unknown; a fixed deposit is not capped against zero');

-- Seed a demonstrable earlier credited payment separately from the current one.
insert into public.appointment_deposit_requirements(business_id,appointment_id,patient_id,is_current,status,amount,base_amount,
 allocation,terms_snapshot,projection_revision,recorded_by,recorded_at)
select business_id,appointment_id,patient_id,false,'paid',40000,40000,'applied',terms_snapshot,1,recorded_by,recorded_at
from public.appointment_deposit_requirements where appointment_id=pg_temp.fid('forfeit_new') and is_current;
update public.appointment_email_policies set require_deposit_on_reschedule=true,previous_deposit_disposition='forfeit'
 where business_id=pg_temp.fid('business');
select extensions.is(pg_temp.fin_core('forfeit_new'),'["new_requirement","40000","40000","40000",null]'::jsonb,
 '12. Disposition does not consume an earlier historical credit again');

do $$ declare t jsonb; begin
 t:=pg_temp.fin_terms('unpaid',now()+interval '1 hour');
 if (t->>'auto_cancel')::boolean is not false or (t->>'last_minute')::boolean is not true then raise exception 'E1_RETROACTIVE_PAYMENT_DEADLINE'; end if;
 update public.appointment_deposits set auto_cancel=false where appointment_id=pg_temp.fid('unpaid');
 t:=pg_temp.fin_terms('unpaid');
 if (t->>'auto_cancel')::boolean is not false then raise exception 'E1_PROTECTED_DEPOSIT_REARMED'; end if;
end $$;
select extensions.pass('13. A late move has no retrospective auto-cancel; a protected unpaid obligation stays protected');

do $$ declare before text:=private.appointment_semantic_revision(pg_temp.fid('business'),pg_temp.fid('forfeit_new'));
 events bigint; t jsonb; begin
 select count(*) into events from public.appointment_deposit_events where appointment_id=pg_temp.fid('forfeit_new');
 t:=pg_temp.fin_terms('forfeit_new',(select starts_at from public.appointments where id=pg_temp.fid('forfeit_new')));
 if t->>'kind' is distinct from 'unchanged' or (t->>'forfeit_amount')::bigint is distinct from 0 then raise exception 'E1_NOOP_FINANCIAL_PENALTY'; end if;
 if private.appointment_semantic_revision(pg_temp.fid('business'),pg_temp.fid('forfeit_new')) is distinct from before
  or (select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.fid('forfeit_new')) is distinct from events then
  raise exception 'E1_PREVIEW_MUTATED_STATE'; end if;
end $$;
select extensions.pass('14. Selecting the same interval cannot preview a penalty or write money/events');

update private.deposit_automation set enabled=false;
select extensions.is(pg_temp.fin_core('forfeit_new'),'["unavailable",null,"0","80000",null]'::jsonb,
 '15. An operator pause preserves the original financial state; it does not silently waive or forfeit money');
update private.deposit_automation set enabled=true;
update public.appointment_email_policies set require_deposit_on_reschedule=false,previous_deposit_disposition='credit'
 where business_id=pg_temp.fid('business');
select extensions.is(pg_temp.fin_core('forfeit_new'),'["none",null,"0","80000",null]'::jsonb,
 '16. Current relaxed financial preferences do not keep a withdrawn penalty');

do $$ declare bad jsonb; valid jsonb; begin
 select price_quote_snapshot into valid from public.appointments where id=pg_temp.fid('capped');
 if private.appointment_quote_amount(valid) is distinct from 50000::bigint then raise exception 'E1_VALID_QUOTE_REJECTED'; end if;
 foreach bad in array array['{}'::jsonb,'null'::jsonb,valid||'{"amount":"50000"}',valid||'{"amount":1.5}',
  valid||'{"amount":-1}',valid||'{"amount":1000000000001}',valid||'{"currency":"USD"}',valid||'{"hash":""}'] loop
  if private.appointment_quote_amount(bad) is not null then raise exception 'E1_INVALID_QUOTE_ACCEPTED'; end if;
 end loop;
end $$;
select extensions.pass('17. Ambiguous, noninteger, out-of-range or different-currency quotes are not a financial balance');
do $$ declare t jsonb; begin
 update private.deposit_automation set enabled=false;
 t:=pg_temp.fin_terms('forfeit_new',(select starts_at from public.appointments where id=pg_temp.fid('forfeit_new')));
 if t->>'kind' is distinct from 'unchanged' or t->>'unavailable_reason' is distinct from 'deposit_automation_paused' then
  raise exception 'E1_INITIAL_FINANCIAL_READINESS_INCOHERENT'; end if;
 update private.deposit_automation set enabled=true;
end $$;
select extensions.pass('18. Initial context and selected-slot preview share readiness, even when no move is being proposed');
select extensions.ok(not has_function_privilege('anon','private.appointment_reschedule_financial_terms(uuid,uuid,timestamptz,timestamptz)','EXECUTE')
 and not has_function_privilege('authenticated','private.appointment_reschedule_financial_terms(uuid,uuid,timestamptz,timestamptz)','EXECUTE')
 and not has_function_privilege('service_role','private.appointment_quote_amount(jsonb)','EXECUTE'),
 '19. Private financial helpers are not alternate Data API entry points');
select * from extensions.finish();
rollback;
