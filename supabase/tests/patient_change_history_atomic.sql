-- The visible change history of a patient is written in the same transaction as the
-- change it describes: a saved update cannot lose its history line, and a history line
-- that cannot be written undoes the update. Synthetic data only; everything is rolled back.
begin;
select extensions.plan(8);

create temporary table history_fixture(label text primary key, id uuid not null);

do $$
declare
 b uuid:=gen_random_uuid(); u_owner uuid:=gen_random_uuid(); u_pro uuid:=gen_random_uuid();
 p_own uuid:=gen_random_uuid(); p_other uuid:=gen_random_uuid(); x uuid;
begin
 insert into auth.users(id,email) select id,'change-history-'||id||'@example.test' from unnest(array[u_owner,u_pro]) id;
 insert into public.businesses(id,name,slug,industry,timezone) values(b,'Historial',b::text,'other','America/Argentina/Buenos_Aires');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=b;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values
  (b,u_owner,'owner','active',now()),(b,u_pro,'professional','active',now());
 insert into public.professionals(id,business_id,name) values(p_own,b,'Profesional propio'),(p_other,b,'Profesional ajeno');
 insert into public.professional_users(business_id,user_id,professional_id) values(b,u_pro,p_own);
 insert into public.patients(owner_id,business_id,full_name) values(u_owner,b,'Paciente original') returning id into x;
 insert into public.professional_patient_links(business_id,professional_id,patient_id,source,is_active,created_by)
  values(b,p_own,x,'manual',true,u_owner);
 insert into history_fixture values('business',b),('owner',u_owner),('pro',u_pro),('p_own',p_own),('p_other',p_other),('x',x);
end $$;

create function pg_temp.fid(p_label text) returns uuid language sql as $$ select id from history_fixture where label=p_label $$;
-- Saves the patient's name as the actor, with the history line the application describes.
create function pg_temp.save_name(p_actor text, p_name text, p_fields text[], p_professional uuid, p_email text default null) returns void language plpgsql as $$
begin
 perform set_config('request.jwt.claim.sub', pg_temp.fid(p_actor)::text, true);
 perform public.update_patient_with_clinical_profile_safely(
  p_actor_id => pg_temp.fid(p_actor), p_business_id => pg_temp.fid('business'), p_patient_id => pg_temp.fid('x'),
  p_full_name => p_name, p_dni => null, p_phone => null, p_phone_raw => null, p_phone_e164 => null, p_email => p_email,
  p_birth_date => null, p_address => null, p_insurance => null, p_insurance_plan => null,
  p_changed_fields => p_fields,
  p_change_summary => case when cardinality(p_fields) > 0 then 'Se modificó: ' || array_to_string(p_fields, ', ') || '.' end,
  p_changed_by_professional_id => p_professional, p_changed_by_name => 'Autor sintético');
end $$;
create function pg_temp.history() returns text language sql as $$
 select coalesce(string_agg(summary || ' by ' || coalesce(changed_by_professional_id::text, 'owner'), ' | ' order by created_at), '')
 from public.patient_profile_change_events where patient_id = pg_temp.fid('x')
$$;

-- 1. A change and its history line commit together, attributed to the actor.
do $$
begin
 perform pg_temp.save_name('pro', 'Paciente renombrado', array['nombre'], pg_temp.fid('p_own'));
 if (select full_name from public.patients where id = pg_temp.fid('x')) <> 'Paciente renombrado'
  or pg_temp.history() <> 'Se modificó: nombre. by ' || pg_temp.fid('p_own') then
  raise exception 'TEST_CHANGE_WITHOUT_ITS_HISTORY %', pg_temp.history();
 end if;
end $$;
select extensions.pass('a change and its history line commit together');

-- 2. A save that changed nothing writes no history line.
do $$
begin
 perform pg_temp.save_name('owner', 'Paciente renombrado', '{}', null);
 if (select count(*) from public.patient_profile_change_events where patient_id = pg_temp.fid('x')) <> 1 then
  raise exception 'TEST_EMPTY_CHANGE_WROTE_HISTORY %', pg_temp.history();
 end if;
end $$;
select extensions.pass('a save without changes writes no history line');

-- 3. A history line attributed to someone else's professional profile is refused, and
-- the change it belonged to is undone with it.
do $$
begin
 begin
  perform pg_temp.save_name('pro', 'Paciente ajeno', array['nombre'], pg_temp.fid('p_other'));
  raise exception 'TEST_FOREIGN_AUTHOR_ACCEPTED';
 exception when others then
  if sqlerrm <> 'PATIENT_UPDATE_DENIED' then raise; end if;
 end;
 if (select full_name from public.patients where id = pg_temp.fid('x')) <> 'Paciente renombrado'
  or (select count(*) from public.patient_profile_change_events where patient_id = pg_temp.fid('x')) <> 1 then
  raise exception 'TEST_REFUSED_HISTORY_KEPT_THE_CHANGE %', pg_temp.history();
 end if;
end $$;
select extensions.pass('a history line that cannot be written undoes its change');

-- 4. Only the trusted backend runs it, as the previous signature.
select extensions.ok(
 has_function_privilege('service_role', 'public.update_patient_with_clinical_profile_safely(uuid,uuid,uuid,text,text,text,text,text,text,date,text,text,text,text[],text,uuid,text,boolean,text,text,text,timestamptz,timestamptz)', 'execute')
 and not has_function_privilege('authenticated', 'public.update_patient_with_clinical_profile_safely(uuid,uuid,uuid,text,text,text,text,text,text,date,text,text,text,text[],text,uuid,text,boolean,text,text,text,timestamptz,timestamptz)', 'execute')
 and not has_function_privilege('anon', 'public.update_patient_with_clinical_profile_safely(uuid,uuid,uuid,text,text,text,text,text,text,date,text,text,text,text[],text,uuid,text,boolean,text,text,text,timestamptz,timestamptz)', 'execute'),
 'only the trusted backend saves a patient with its history');

-- The contact editor is also an E writer: permission belongs to the current
-- actor, including disabled memberships and real temporary assistance.
update public.business_users set disabled_at=clock_timestamp()
 where business_id=pg_temp.fid('business') and user_id=pg_temp.fid('owner');
do $$ declare before jsonb; begin
 select to_jsonb(p) into strict before from public.patients p where p.id=pg_temp.fid('x');
 begin
  perform pg_temp.save_name('owner','Unauthorized disabled editor',array['nombre','correo electrónico'],null,'denied@example.test');
  raise exception 'TEST_DISABLED_PATIENT_EDITOR_ALLOWED';
 exception when others then if sqlerrm is distinct from 'PATIENT_UPDATE_DENIED' then raise; end if; end;
 if (select to_jsonb(p) from public.patients p where p.id=pg_temp.fid('x')) is distinct from before
  or (select count(*) from public.patient_profile_change_events where patient_id=pg_temp.fid('x'))<>1 then
  raise exception 'TEST_DISABLED_PATIENT_EDITOR_LEFT_PARTIAL_STATE'; end if;
end $$;
select extensions.pass('disabled membership cannot edit patient contact or leave history/revocation effects');
update public.business_users set disabled_at=null
 where business_id=pg_temp.fid('business') and user_id=pg_temp.fid('owner');
do $$ declare helper uuid:=gen_random_uuid(); begin
 insert into auth.users(id,email) values(helper,'profile-assistance-'||helper||'@example.test');
 insert into public.account_assistance_support_users(user_id,email,enabled)
 values(helper,'profile-assistance-'||helper||'@example.test',true);
 insert into public.account_assistance_grants(business_id,requested_by_user_id,support_user_id,starts_at,expires_at)
 values(pg_temp.fid('business'),pg_temp.fid('owner'),helper,clock_timestamp()-interval '1 minute',clock_timestamp()+interval '1 hour');
 insert into history_fixture values('support',helper);
 perform pg_temp.save_name('support','Authorized assistance contact edit',array['nombre','correo electrónico'],null,'current-profile@example.test');
 if not exists(select 1 from public.patients where id=pg_temp.fid('x') and email='current-profile@example.test')
  or not exists(select 1 from public.patient_profile_change_events where patient_id=pg_temp.fid('x') and changed_by_user_id=helper)
  or exists(select 1 from public.business_users where business_id=pg_temp.fid('business') and user_id=helper) then
  raise exception 'TEST_ASSISTANCE_PROFILE_ATTRIBUTION_OR_ARTIFICIAL_MEMBERSHIP'; end if;
end $$;
select extensions.pass('active independent assistance edits contact with its own authorship and no artificial membership');
update public.account_assistance_grants set expires_at=clock_timestamp()-interval '1 second'
 where business_id=pg_temp.fid('business') and support_user_id=pg_temp.fid('support');
do $$ declare before jsonb; history bigint; begin
 select to_jsonb(p) into strict before from public.patients p where p.id=pg_temp.fid('x');
 select count(*) into history from public.patient_profile_change_events where patient_id=pg_temp.fid('x');
 begin
  perform pg_temp.save_name('support','Expired assistance',array['nombre'],null,'expired-profile@example.test');
  raise exception 'TEST_EXPIRED_ASSISTANCE_PATIENT_EDITOR_ALLOWED';
 exception when others then if sqlerrm is distinct from 'PATIENT_UPDATE_DENIED' then raise; end if; end;
 if (select to_jsonb(p) from public.patients p where p.id=pg_temp.fid('x')) is distinct from before
  or (select count(*) from public.patient_profile_change_events where patient_id=pg_temp.fid('x')) is distinct from history then
  raise exception 'TEST_EXPIRED_ASSISTANCE_PATIENT_EDITOR_PARTIAL_STATE'; end if;
end $$;
select extensions.pass('expired independent assistance cannot change contact or its visible history');
create function pg_temp.fail_profile_contact_history() returns trigger language plpgsql as $$
begin
 if new.patient_id=pg_temp.fid('x') then raise exception 'TEST_PROVOKED_CONTACT_HISTORY_FAILURE'; end if;
 return new;
end $$;
create trigger fail_profile_contact_history before insert on public.patient_profile_change_events
 for each row execute function pg_temp.fail_profile_contact_history();
do $$ declare before jsonb; events bigint; begin
 select to_jsonb(p) into strict before from public.patients p where p.id=pg_temp.fid('x');
 select count(*) into events from private.patient_email_contact_events where patient_id=pg_temp.fid('x');
 begin
  perform pg_temp.save_name('owner','Contact must roll back',array['nombre','correo electrónico'],null,'rolled-back-profile@example.test');
  raise exception 'TEST_CONTACT_HISTORY_FAILURE_NOT_OBSERVED';
 exception when others then if sqlerrm is distinct from 'TEST_PROVOKED_CONTACT_HISTORY_FAILURE' then raise; end if; end;
 if (select to_jsonb(p) from public.patients p where p.id=pg_temp.fid('x')) is distinct from before
  or (select count(*) from private.patient_email_contact_events where patient_id=pg_temp.fid('x')) is distinct from events then
  raise exception 'TEST_CONTACT_HISTORY_FAILURE_LEFT_REVOCATION_OR_PROFILE'; end if;
end $$;
drop trigger fail_profile_contact_history on public.patient_profile_change_events;
select extensions.pass('history failure rolls back contact, authority revision and durable contact event together');

select * from extensions.finish();
rollback;
