-- A public booking supplies contact for that appointment, not authority to
-- rewrite every appointment of a patient matched by name/phone. No sender runs.
begin;
create table private.public_booking_email_contacts (
 business_id uuid not null,
 appointment_id uuid not null,
 patient_id_snapshot uuid not null,
 patient_contact_revision bigint not null check(patient_contact_revision>0),
 email text not null check(email=btrim(email) and char_length(email)<=254 and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
 primary key(business_id,appointment_id),
 foreign key(business_id,appointment_id) references public.appointments(business_id,id) on delete cascade
);
-- The patient is an observed identity, not another independently writable
-- relationship. Insertion verifies the current parent; the reader joins that
-- identity and discards it after repair. No extra patient FK/row lock is taken
-- after the public contact-resolution advisory lock.
revoke all on private.public_booking_email_contacts from public,anon,authenticated,service_role;

create function private.appointment_email_contact(p_business_id uuid,p_appointment_id uuid)
returns table(patient_id uuid,contact_revision bigint,email text)
language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select p.id,p.email_contact_revision,
  case when c.patient_id_snapshot=p.id and c.patient_contact_revision=p.email_contact_revision
   then c.email else nullif(btrim(p.email),'') end
 from public.appointments a
 join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 left join private.public_booking_email_contacts c on (c.business_id,c.appointment_id)=(a.business_id,a.id)
 where (a.business_id,a.id)=(p_business_id,p_appointment_id)
$$;
revoke all on function private.appointment_email_contact(uuid,uuid) from public,anon,authenticated,service_role;

create function private.discard_reassigned_booking_email_contact() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 delete from private.public_booking_email_contacts where business_id=old.business_id and appointment_id=old.id;
 return null;
end $$;
create trigger discard_reassigned_booking_email_contact after update of patient_id on public.appointments
 for each row when(new.patient_id is distinct from old.patient_id)
 execute function private.discard_reassigned_booking_email_contact();
revoke all on function private.discard_reassigned_booking_email_contact() from public,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION public.create_appointment_with_patient_identity(p_business_id uuid, p_patient_mode text, p_patient_id uuid, p_patient_name text, p_patient_phone_raw text, p_patient_phone_e164 text, p_patient_email text, p_update_existing_phone boolean, p_owner_id uuid, p_service_id uuid, p_professional_ids uuid[], p_starts_at timestamp with time zone, p_internal_note text, p_created_by_user_id uuid, p_ignore_break boolean, p_source text, p_phone_communication_status text, p_phone_warning_acknowledged boolean, p_idempotency_key text, p_replay_only boolean DEFAULT false)
 RETURNS TABLE(id uuid, patient_id uuid, confirmation_token text, starts_at timestamp with time zone, ends_at timestamp with time zone, service_name_snapshot text, professional_name_snapshot text, patient_created boolean, idempotent_replay boolean, patient_resolution_strategy text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare
 created record; current_appointment public.appointments;
begin
 if coalesce(nullif(btrim(p_source),''),'manual') in('manual','admin')
  and private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_created_by_user_id) is null then
  raise exception 'APPOINTMENT_CREATOR_INVALID';
 end if;
 perform set_config('cita.booking_professional_ids',coalesce(p_professional_ids,'{}'::uuid[])::text,true);
 for created in select * from public.create_appointment_with_patient_identity_before_pricing(
  p_business_id,p_patient_mode,p_patient_id,p_patient_name,p_patient_phone_raw,p_patient_phone_e164,p_patient_email,
  p_update_existing_phone,p_owner_id,p_service_id,p_professional_ids,p_starts_at,p_internal_note,p_created_by_user_id,
  p_ignore_break,p_source,p_phone_communication_status,p_phone_warning_acknowledged,p_idempotency_key,p_replay_only
 ) loop
  if lower(btrim(p_source))='public_booking' and not created.idempotent_replay then
   perform private.assert_public_booking_email(p_business_id,p_patient_email);
  end if;
  -- Core creation holds the creation-key advisory lock already. Repair takes
  -- only this parent; lock it before exposing a result sampled before a wait.
  select * into current_appointment from public.appointments a
  where a.business_id=p_business_id and a.id=created.id for no key update;
  if not found or current_appointment.patient_resolution_strategy='reassigned_manual'
   or (current_appointment.patient_id,current_appointment.confirmation_token) is distinct from
    (created.patient_id,created.confirmation_token) then
   raise exception 'APPOINTMENT_IDEMPOTENCY_CONFLICT';
  end if;
  if lower(btrim(p_source))='public_booking' and not created.idempotent_replay and nullif(btrim(p_patient_email),'') is not null then
   -- One snapshot records the contact epoch. A later authorized correction
   -- makes this override obsolete without changing or locking other parents.
   insert into private.public_booking_email_contacts(business_id,appointment_id,patient_id_snapshot,patient_contact_revision,email)
   select current_appointment.business_id,current_appointment.id,p.id,p.email_contact_revision,btrim(p_patient_email)
   from public.patients p where (p.business_id,p.id)=(current_appointment.business_id,current_appointment.patient_id);
   if not found then raise exception 'PATIENT_NOT_FOUND'; end if;
  end if;
  return query select created.id,created.patient_id,created.confirmation_token,created.starts_at,created.ends_at,
   created.service_name_snapshot,created.professional_name_snapshot,created.patient_created,created.idempotent_replay,created.patient_resolution_strategy;
 end loop;
 if coalesce(nullif(btrim(p_source),''),'manual') in('manual','admin')
  and private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_created_by_user_id) is null then
  raise exception 'APPOINTMENT_CREATOR_INVALID';
 end if;
end;
$function$
;

commit;
