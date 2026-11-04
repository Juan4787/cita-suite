-- AC09: explicit management channels for clinical information. Calendar identity
-- remains stable; possession of it does not recreate revoked management access.
-- No sender, producer, new financial rule or clinical-data migration is enabled.
begin;

-- Common clinical scope, with one query snapshot and an explicit clock. Upload
-- completion owns its existing grace separately; ordinary forms stay future-only.
create function private.booking_information_context_at(p_token text,p_legacy boolean,p_now timestamptz)
returns public.appointments language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 with access as materialized (select private.appointment_management_access_at(p_token,p_legacy,p_now) as context)
 select a.* from access join public.appointments a
  on (a.business_id,a.id)=((context->>'business_id')::uuid,(context->>'appointment_id')::uuid)
 join public.appointment_patient_information_contexts c
  on (c.business_id,c.appointment_id,c.patient_id_snapshot)=(a.business_id,a.id,a.patient_id)
 join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 join public.businesses b on b.id=a.business_id
 where context is not null and a.status in ('reserved','confirmed','reschedule_requested')
  and p.archived_at is null and b.is_active and private.appointment_business_allows_operation_at(b.id,p_now)
$$;

create function private.booking_information_appointment(p_token text,p_legacy boolean)
returns public.appointments language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; v_now timestamptz:=clock_timestamp();
begin
 a:=private.booking_information_context_at(p_token,p_legacy,v_now);
 if a.id is null or a.starts_at<=v_now then raise exception 'BOOKING_INFORMATION_UNAVAILABLE'; end if;
 return a;
end $$;

-- Existing callers are explicitly legacy; no flag inferred from a 64-hex value.
create or replace function private.booking_information_appointment(p_token text)
returns public.appointments language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select private.booking_information_appointment(p_token,true)
$$;

create function private.public_booking_information_snapshot(p_token text,p_legacy boolean,p_now timestamptz)
returns jsonb language plpgsql stable security definer set search_path=pg_catalog,pg_temp as $$

declare a public.appointments%rowtype; s jsonb; initial public.appointment_intake_responses%rowtype;
  latest public.appointment_intake_submissions%rowtype; documents_enabled boolean;
begin
  a:=private.booking_information_context_at(p_token,p_legacy,p_now);
  if a.id is null or a.starts_at<=p_now then return null; end if;
  select schema_snapshot into s from public.appointment_patient_information_contexts where appointment_id=a.id;
  select * into initial from public.appointment_intake_responses where appointment_id=a.id and patient_id=a.patient_id;
  select * into latest from public.appointment_intake_submissions where appointment_id=a.id and patient_id=a.patient_id order by sequence_no desc limit 1;
  select b.patient_documents_enabled and q.uploads_enabled and g.uploads_enabled into documents_enabled
    from public.businesses b join public.clinical_business_storage_budget q on q.business_id=b.id
      cross join public.clinical_storage_budget g where b.id=a.business_id and g.singleton;
  return jsonb_build_object('documents_enabled',coalesce(documents_enabled,false),
    'theme',coalesce((select theme_snapshot from public.appointment_booking_contexts where appointment_id=a.id),'cita-suite'),
    'schema',s,'schema_hash',encode(extensions.digest(s::text,'sha256'),'hex'),
    'answers',coalesce(latest.answers,initial.answers,'{}'),'comment',coalesce(latest.free_comment,initial.free_comment,''),
    'version',coalesce(latest.id::text,'initial'));
end $$;

create function public.get_public_booking_information(p_token text,p_legacy boolean)
returns jsonb language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare result jsonb;
begin
 -- The pure snapshot helper has no implicit clock. The public boundary samples
 -- actual time once and preserves one coherent identity/clinical snapshot.
 select private.public_booking_information_snapshot(p_token,p_legacy,clock_timestamp()) into result;
 if result is null then raise exception 'BOOKING_INFORMATION_UNAVAILABLE'; end if;
 return result;
end $$;

create or replace function public.get_public_booking_information(p_token text)
returns jsonb language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select public.get_public_booking_information(p_token,true)
$$;

create function public.submit_public_booking_information(p_token text,p_request_key uuid,p_schema_hash text,p_expected_version text,
 p_answers jsonb,p_comment text,p_legacy boolean)
returns uuid language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$

declare a public.appointments%rowtype; info jsonb; normalized jsonb; prior public.appointment_intake_submissions%rowtype; result uuid; changes jsonb;
begin
 a:=private.booking_information_appointment(p_token,p_legacy);
 perform 1 from public.appointments where business_id=a.business_id and id=a.id for update;
 a:=private.booking_information_appointment(p_token,p_legacy);
 -- The existing profile application takes this lock later. Acquire it BEFORE
 -- child FK inserts: two appointments of the same patient must not both hold
 -- KEY SHARE and then try to upgrade to UPDATE. Also sample contact after wait.
 perform 1 from public.patients where business_id=a.business_id and id=a.patient_id for update;
 a:=private.booking_information_appointment(p_token,p_legacy);
 info:=public.get_public_booking_information(p_token,p_legacy); normalized:=private.normalize_patient_answers(info->'schema',coalesce(p_answers,'{}'));
 if length(coalesce(p_comment,''))>2000 or p_request_key is null then raise exception 'BOOKING_INTAKE_ANSWERS_INVALID'; end if;
 select * into prior from public.appointment_intake_submissions where appointment_id=a.id and request_key=p_request_key;
 if found then
  if prior.answers is distinct from normalized or prior.free_comment is distinct from nullif(trim(coalesce(p_comment,'')),'') then raise exception 'BOOKING_INFORMATION_REQUEST_CONFLICT'; end if; return prior.id;
 end if;
 if info->>'schema_hash' is distinct from p_schema_hash or info->>'version' is distinct from p_expected_version then raise exception 'BOOKING_INFORMATION_CHANGED'; end if;
 if (select count(*) from public.appointment_intake_submissions where appointment_id=a.id)>=50 then raise exception 'BOOKING_INFORMATION_LIMIT'; end if;
 insert into public.appointment_intake_submissions(business_id,appointment_id,patient_id,request_key,schema_snapshot,answers,free_comment) values(a.business_id,a.id,a.patient_id,p_request_key,info->'schema',normalized,nullif(trim(coalesce(p_comment,'')),'')) returning id into result;
 changes:=private.apply_booking_answers_to_patient(a.business_id,a.patient_id,info->'schema',normalized); update public.appointment_intake_submissions set profile_changes=changes where id=result;
 -- Clinical/profile effects and their history remain one transaction. Expiry
 -- after a delayed effect still invalidates the entire operation.
 perform private.booking_information_appointment(p_token,p_legacy);
 return result;
end $$;

create or replace function public.submit_public_booking_information(p_token text,p_request_key uuid,p_schema_hash text,p_expected_version text,
 p_answers jsonb,p_comment text)
returns uuid language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select public.submit_public_booking_information(p_token,p_request_key,p_schema_hash,p_expected_version,p_answers,p_comment,true)
$$;

revoke all on function private.booking_information_context_at(text,boolean,timestamptz),
 private.booking_information_appointment(text,boolean),private.public_booking_information_snapshot(text,boolean,timestamptz),
 public.get_public_booking_information(text,boolean),public.submit_public_booking_information(text,uuid,text,text,jsonb,text,boolean)
 from public,anon,authenticated,service_role;
grant execute on function public.get_public_booking_information(text,boolean),
 public.submit_public_booking_information(text,uuid,text,text,jsonb,text,boolean) to service_role;
-- Existing one-argument/six-argument grants are preserved by their replacements.
notify pgrst,'reload schema';
commit;
