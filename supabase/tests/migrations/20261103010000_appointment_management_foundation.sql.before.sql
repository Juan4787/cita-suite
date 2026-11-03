-- This committed fixture runs only in the disposable reconstruction, BEFORE E1.
-- It captures what the old application actually stores, not supposed history.
begin;
create table private.e1_upgrade_fixture(business_id uuid primary key, owner_id uuid not null, before_state jsonb not null);
do $$
declare b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); s uuid:=gen_random_uuid();
 patient uuid; a uuid; wanted text; rev bigint; n integer:=0; previous_enabled boolean;
begin
 select enabled into previous_enabled from private.deposit_automation where singleton;
 insert into auth.users(id,email) values(u,'e1-upgrade-'||u||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'E1 upgrade synthetic',b::text,'other','America/Argentina/Cordoba');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(b,u,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(p,b,'E1 upgrade professional');
 insert into public.services(id,business_id,name,duration_minutes) values(s,b,'E1 upgrade service',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,p,s);
 update private.deposit_automation set enabled=true;
 insert into public.deposit_policies(business_id,enabled,amount_mode,fixed_amount,transfer_details) values(b,true,'fixed',40000,'Synthetic upgrade only');
 perform set_config('request.jwt.claim.sub',u::text,true);
 foreach wanted in array array['pending','paid','waived','expired','paid_cancelled'] loop
  n:=n+1;
  insert into public.patients(owner_id,business_id,full_name) values(u,b,'E1 upgrade '||wanted) returning id into patient;
  insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
   status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
  values(b,patient,p,s,date_trunc('hour',now())+make_interval(days=>n+10),date_trunc('hour',now())+make_interval(days=>n+10,hours=>1),
   date_trunc('hour',now())+make_interval(days=>n+10),date_trunc('hour',now())+make_interval(days=>n+10,hours=>1),
   'reserved','manual',wanted,'E1 upgrade professional',60) returning id into a;
  if wanted in ('paid','waived','paid_cancelled') then
   select revision into rev from public.appointment_deposits where appointment_id=a;
   perform public.set_appointment_deposit(b,a,case when wanted='waived' then 'waived' else 'paid' end,rev,null);
  end if;
  if wanted in ('expired','paid_cancelled') then
   update public.appointments set status='cancelled',cancelled_at=now(),cancelled_reason='Synthetic upgrade' where id=a;
  end if;
  if wanted='expired' then
   update public.appointment_deposits set status='expired',expired_at=now() where appointment_id=a;
  end if;
  -- An imported old payment may have no known original time. Keep that unknown.
  if wanted='paid_cancelled' then update public.appointment_deposits set recorded_at=null where appointment_id=a; end if;
 end loop;
 insert into private.e1_upgrade_fixture
 select b,u,jsonb_agg(jsonb_build_object('appointment',to_jsonb(ap),'deposit',to_jsonb(d)) order by ap.id)
 from public.appointments ap join public.appointment_deposits d on d.appointment_id=ap.id where ap.business_id=b;
 update private.deposit_automation set enabled=previous_enabled;
end $$;
commit;
