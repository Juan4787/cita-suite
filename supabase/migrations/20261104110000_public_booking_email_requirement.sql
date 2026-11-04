-- E3: every public creation passes through the existing identity wrapper.
-- Validation shares the creation transaction; a completed authorized replay is
-- recovered before applying a subsequently changed requirement.
begin;
create function private.assert_public_booking_email(p_business_id uuid,p_email text) returns void
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare required boolean; email text:=nullif(btrim(p_email),'');
begin
 select p.require_email into required from public.appointment_email_policies p where p.business_id=p_business_id for share;
 if not found then raise exception 'EMAIL_POLICY_UNAVAILABLE'; end if;
 if required and email is null then raise exception 'PUBLIC_PATIENT_EMAIL_REQUIRED'; end if;
 if email is not null and (char_length(email)>254 or email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then
  raise exception 'PUBLIC_PATIENT_EMAIL_INVALID'; end if;
end $$;
revoke all on function private.assert_public_booking_email(uuid,text) from public,anon,authenticated,service_role;

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
