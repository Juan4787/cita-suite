-- AC09: pending patient uploads are bound to the authority that started them.
-- Preserve clinical history and the existing bounded completion grace. Storage
-- verification remains in the backend; a signed upload URL is not revocable SQL.
begin;
create table private.patient_document_upload_authority (
 file_id uuid primary key references public.patient_radiographs(id) on delete cascade,
 management_generation bigint not null check (management_generation>0),
 patient_contact_revision bigint not null check (patient_contact_revision>0)
);
revoke all on private.patient_document_upload_authority from public,anon,authenticated,service_role;
-- Only the unchanged initial legacy identity is demonstrable for pre-E pending
-- uploads. Never bless a pending object after a previous revocation/contact edit.
insert into private.patient_document_upload_authority
 select f.id,m.generation,p.email_contact_revision from public.patient_radiographs f
 join public.appointments a on (a.business_id,a.id,a.patient_id)=(f.business_id,f.appointment_id,f.patient_id)
 join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
 join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 join public.appointment_patient_information_contexts c
  on (c.business_id,c.appointment_id,c.patient_id_snapshot)=(a.business_id,a.id,a.patient_id)
 where f.source='patient' and f.status='uploading' and m.generation=1 and m.legacy_management_allowed
  and m.legacy_contact_revision=1 and p.email_contact_revision=1;

-- One clock and one statement snapshot for capability, identity, clinical scope,
-- pending binding and the upload lease. Ready files are existing clinical data.
create function private.public_patient_document_upload_snapshot(p_token text,p_file_id uuid,p_legacy boolean,p_now timestamptz)
returns public.patient_radiographs language plpgsql stable security definer set search_path=pg_catalog,pg_temp as $$
declare appointment public.appointments; file public.patient_radiographs;
begin
 appointment:=private.booking_information_context_at(p_token,p_legacy,p_now);
 if appointment.id is null then raise exception 'BOOKING_INFORMATION_UNAVAILABLE'; end if;
 select * into file from public.patient_radiographs where id=p_file_id and appointment_id=appointment.id
  and business_id=appointment.business_id and patient_id=appointment.patient_id and source='patient' and status in ('uploading','ready');
 if not found then raise exception 'RADIOGRAPH_NOT_FOUND'; end if;
 if file.status='uploading' and not exists(
  select 1 from private.patient_document_upload_authority d
   join public.appointment_management_states m on (m.business_id,m.appointment_id)=(file.business_id,file.appointment_id)
   join public.patients p on (p.business_id,p.id)=(file.business_id,file.patient_id)
  where d.file_id=file.id and d.management_generation=m.generation and d.patient_contact_revision=p.email_contact_revision
 ) then raise exception 'BOOKING_INFORMATION_UNAVAILABLE'; end if;
 if appointment.starts_at<=p_now
  and not exists(select 1 from public.clinical_upload_slots where file_id=file.id and expires_at>p_now)
  and not(file.status='ready' and file.ready_at>p_now-interval '15 minutes') then
  raise exception 'BOOKING_INFORMATION_UNAVAILABLE'; end if;
 return file;
end $$;
create function public.get_public_patient_document_upload(p_token text,p_file_id uuid,p_legacy boolean)
returns public.patient_radiographs language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare file public.patient_radiographs;
begin
 perform private.require_clinical_file_service_call();
 select * into file from private.public_patient_document_upload_snapshot(p_token,p_file_id,p_legacy,clock_timestamp());
 return file;
end $$;
create or replace function public.get_public_patient_document_upload(p_token text,p_file_id uuid)
returns public.patient_radiographs language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select public.get_public_patient_document_upload(p_token,p_file_id,true)
$$;

CREATE FUNCTION public.begin_public_patient_document_upload(p_token text, p_request_id uuid, p_filename text, p_mime text, p_bytes bigint, p_sha256 text, p_note text, p_legacy boolean)
 RETURNS patient_radiographs
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare appointment public.appointments%rowtype;file public.patient_radiographs%rowtype;extension text; prior_found boolean;
begin
 perform private.require_clinical_file_service_call();perform private.clinical_budget_lock();
 appointment:=private.booking_information_appointment(p_token,p_legacy);
 if not coalesce((select patient_documents_enabled from public.businesses where id=appointment.business_id),false) then raise exception 'CLINICAL_PATIENT_DOCUMENTS_DISABLED';end if;
 perform 1 from public.appointments where id=appointment.id for update;
 appointment:=private.booking_information_appointment(p_token,p_legacy);
 if p_request_id is null or not coalesce(p_mime in ('image/jpeg','image/png','application/pdf'),false) or not coalesce(p_bytes between 1 and 5000000,false) or not coalesce(p_sha256 ~ '^[0-9a-f]{64}$',false) or coalesce(length(trim(p_filename)),0) not between 1 and 160 or p_filename ~ '[\\/]' or length(coalesce(p_note,''))>500 then raise exception 'RADIOGRAPH_UPLOAD_INVALID';end if;
 select * into file from public.patient_radiographs f where f.appointment_id=appointment.id and f.source='patient' and f.client_request_id=p_request_id for update;
 prior_found:=found;
 perform 1 from public.patients where business_id=appointment.business_id and id=appointment.patient_id for update;
 appointment:=private.booking_information_appointment(p_token,p_legacy);
 if prior_found then
  if file.mime_type<>p_mime or file.bytes<>p_bytes or file.sha256<>p_sha256 then raise exception 'RADIOGRAPH_REQUEST_CONFLICT';end if;
  file:=public.get_public_patient_document_upload(p_token,file.id,p_legacy);
  perform private.reserve_clinical_document(file.id);
  perform private.booking_information_appointment(p_token,p_legacy);return file;
 end if;
 if (select count(*) from public.patient_radiographs f where f.appointment_id=appointment.id and f.source='patient' and (f.status in ('ready','trashed') or f.created_at>clock_timestamp()-interval '2 hours 15 minutes'))>=3 then raise exception 'CLINICAL_PATIENT_QUOTA';end if;
 extension:=case p_mime when 'application/pdf' then 'pdf' when 'image/png' then 'png' else 'jpg' end;
 file.id:=gen_random_uuid();
 insert into public.patient_radiographs(id,business_id,patient_id,source,appointment_id,status,storage_provider,storage_bucket,storage_path,integrity_status,client_request_id,original_filename,mime_type,bytes,sha256,note)
 values(file.id,appointment.business_id,appointment.patient_id,'patient',appointment.id,'uploading','supabase_storage','patient-clinical-files',appointment.business_id::text||'/'||appointment.patient_id::text||'/'||file.id::text||'/original.'||extension,'unchecked',p_request_id,trim(p_filename),p_mime,p_bytes,p_sha256,nullif(trim(p_note),'')) returning * into file;
 insert into private.patient_document_upload_authority(file_id,management_generation,patient_contact_revision)
  select file.id,m.generation,p.email_contact_revision from public.appointment_management_states m
   join public.patients p on (p.business_id,p.id)=(appointment.business_id,appointment.patient_id)
  where (m.business_id,m.appointment_id)=(appointment.business_id,appointment.id);
 perform private.reserve_clinical_document(file.id);
 insert into public.audit_logs(business_id,action,entity_type,entity_id,metadata) values(appointment.business_id,'clinical_document.patient_upload_started','patient_radiograph',file.id,jsonb_build_object('appointment_id',appointment.id,'bytes',p_bytes));
 perform private.booking_information_appointment(p_token,p_legacy);
 return file;
end $function$
;
create or replace function public.begin_public_patient_document_upload(p_token text,p_request_id uuid,p_filename text,
 p_mime text,p_bytes bigint,p_sha256 text,p_note text default null)
returns public.patient_radiographs language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select public.begin_public_patient_document_upload(p_token,p_request_id,p_filename,p_mime,p_bytes,p_sha256,p_note,true)
$$;
CREATE FUNCTION public.complete_public_patient_document_upload(p_token text, p_file_id uuid, p_bytes bigint, p_mime text, p_legacy boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare file public.patient_radiographs%rowtype;
begin
 perform private.require_clinical_file_service_call();perform private.clinical_budget_lock();
 file:=public.get_public_patient_document_upload(p_token,p_file_id,p_legacy);
 -- Budget precedes parent, then existing file and patient, as in start/retry.
 perform 1 from public.appointments where business_id=file.business_id and id=file.appointment_id for update;
 perform 1 from public.patient_radiographs where id=file.id for update;
 perform 1 from public.patients where business_id=file.business_id and id=file.patient_id for update;
 file:=public.get_public_patient_document_upload(p_token,p_file_id,p_legacy);
 if file.status='ready' then return file.id;end if;
 if file.bytes is distinct from p_bytes or file.mime_type is distinct from p_mime then raise exception 'RADIOGRAPH_OBJECT_MISMATCH';end if;
 update public.patient_radiographs set status='ready',ready_at=clock_timestamp(),integrity_status='ok' where id=file.id;
 update public.patients set activity_at=greatest(coalesce(activity_at,created_at),clock_timestamp()) where id=file.patient_id and business_id=file.business_id;
 insert into public.audit_logs(business_id,action,entity_type,entity_id,metadata) values(file.business_id,'clinical_document.patient_upload_completed','patient_radiograph',file.id,jsonb_build_object('bytes',file.bytes,'mime_type',file.mime_type,'appointment_id',file.appointment_id));
 perform public.get_public_patient_document_upload(p_token,p_file_id,p_legacy);
 return file.id;
end $function$
;
create or replace function public.complete_public_patient_document_upload(p_token text,p_file_id uuid,p_bytes bigint,p_mime text)
returns uuid language sql volatile security definer set search_path=pg_catalog,pg_temp as $$
 select public.complete_public_patient_document_upload(p_token,p_file_id,p_bytes,p_mime,true)
$$;
revoke all on function private.public_patient_document_upload_snapshot(text,uuid,boolean,timestamptz),
 public.get_public_patient_document_upload(text,uuid,boolean),
 public.begin_public_patient_document_upload(text,uuid,text,text,bigint,text,text,boolean),
 public.complete_public_patient_document_upload(text,uuid,bigint,text,boolean) from public,anon,authenticated,service_role;
grant execute on function public.get_public_patient_document_upload(text,uuid,boolean),
 public.begin_public_patient_document_upload(text,uuid,text,text,bigint,text,text,boolean),
 public.complete_public_patient_document_upload(text,uuid,bigint,text,boolean) to service_role;
notify pgrst,'reload schema';
commit;
