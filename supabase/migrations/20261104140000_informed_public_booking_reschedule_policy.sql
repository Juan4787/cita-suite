-- Only a new, informed public booking may adopt its clinic's rescheduling
-- consequences. Existing appointments and completed replays are untouched.
begin;
create function private.accept_public_booking_reschedule_policy(p_business_id uuid,p_appointment_id uuid) returns void
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_required boolean; v_raw text; v_headers jsonb; v_terms jsonb; v_number numeric;
 v_policy public.appointment_email_policies; v_effective jsonb; v_now timestamptz;
begin
 -- No deposit means no new deposit penalty to enroll. This also protects that
 -- booking if a future administrative correction introduces an obligation.
 if not exists(select 1 from public.appointment_deposits where business_id=p_business_id and appointment_id=p_appointment_id) then return; end if;
 select reschedule_enabled into v_required from private.appointment_management_runtime where singleton for share;
 if not found then raise exception 'RESCHEDULE_POLICY_TERMS_CHANGED'; end if;
 begin
  v_headers:=nullif(current_setting('request.headers',true),'')::jsonb;
  v_raw:=v_headers->>'x-cita-reschedule-policy';
 exception when invalid_text_representation or numeric_value_out_of_range then raise exception 'RESCHEDULE_POLICY_TERMS_INVALID'; end;
 if v_raw is null then
  if v_required then raise exception 'RESCHEDULE_POLICY_TERMS_CHANGED'; end if;
  return; -- Compatibility while the operator has not enabled this feature.
 end if;
 if octet_length(v_raw)>1024 then raise exception 'RESCHEDULE_POLICY_TERMS_INVALID'; end if;
 begin v_terms:=v_raw::jsonb;
 exception when invalid_text_representation or numeric_value_out_of_range then raise exception 'RESCHEDULE_POLICY_TERMS_INVALID'; end;
 if jsonb_typeof(v_terms) is distinct from 'object' then raise exception 'RESCHEDULE_POLICY_TERMS_INVALID'; end if;
 if (v_terms-array['schema_version','policy_revision','require_deposit_on_reschedule','previous_deposit_disposition'])<>'{}'::jsonb
  or v_terms->'schema_version' is distinct from '1'::jsonb
  or jsonb_typeof(v_terms->'policy_revision') is distinct from 'number'
  or jsonb_typeof(v_terms->'require_deposit_on_reschedule') is distinct from 'boolean'
  or jsonb_typeof(v_terms->'previous_deposit_disposition') is distinct from 'string'
  or (v_terms->>'previous_deposit_disposition') not in('credit','forfeit') then raise exception 'RESCHEDULE_POLICY_TERMS_INVALID'; end if;
 v_number:=(v_terms->>'policy_revision')::numeric;
 if v_number<1 or v_number>9007199254740991 or v_number<>trunc(v_number) then raise exception 'RESCHEDULE_POLICY_TERMS_INVALID'; end if;
 select * into v_policy from public.appointment_email_policies where business_id=p_business_id for share;
 if not found then raise exception 'RESCHEDULE_POLICY_TERMS_CHANGED'; end if;
 -- Revision alone is not a reason to reject: email/presentation changes and
 -- genuine relaxations do not impose a more expensive financial contract.
 if v_number>v_policy.revision
  or (v_policy.require_deposit_on_reschedule and not (v_terms->>'require_deposit_on_reschedule')::boolean)
  or (v_policy.previous_deposit_disposition='forfeit' and v_terms->>'previous_deposit_disposition'='credit') then
  raise exception 'RESCHEDULE_POLICY_TERMS_CHANGED';
 end if;
 v_effective:=jsonb_build_object('schema_version',1,'policy_revision',v_policy.revision,
  'require_deposit_on_reschedule',v_policy.require_deposit_on_reschedule,'previous_deposit_disposition',v_policy.previous_deposit_disposition);
 v_now:=clock_timestamp();
 update public.appointment_management_states set terms_acknowledged=true,
  require_deposit_on_reschedule=v_policy.require_deposit_on_reschedule,previous_deposit_disposition=v_policy.previous_deposit_disposition,
  accepted_at=v_now,accepted_policy_revision=v_policy.revision,
  terms_snapshot=jsonb_build_object('schema_version',1,'source','public_booking','disclosed',v_terms,'effective',v_effective)
 where business_id=p_business_id and appointment_id=p_appointment_id;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,null,'appointment.reschedule_policy_informed','appointment',p_appointment_id,
  jsonb_build_object('source','public_booking','disclosed',v_terms,'effective',v_effective));
end $$;
revoke all on function private.accept_public_booking_reschedule_policy(uuid,uuid) from public,anon,authenticated,service_role;

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
  if lower(btrim(p_source))='public_booking' and not created.idempotent_replay then
   -- This parent belongs to the new creation and is already held. Never enroll
   -- by reading a receipt, replaying a key or changing a clinic preference.
   perform private.accept_public_booking_reschedule_policy(p_business_id,current_appointment.id);
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
