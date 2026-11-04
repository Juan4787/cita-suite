-- Preserve the three existing contracts, identities, audit and history.
-- Reuse current temporal authority for manual creation/recovery and repair.
-- These are explicit complete definitions, not runtime text patches or a new
-- command framework. Existing patient, price, availability and provider rules
-- stay in their owning functions.
begin;
CREATE OR REPLACE FUNCTION public.create_appointment_with_patient_identity_before_pricing(p_business_id uuid, p_patient_mode text, p_patient_id uuid, p_patient_name text, p_patient_phone_raw text, p_patient_phone_e164 text, p_patient_email text, p_update_existing_phone boolean, p_owner_id uuid, p_service_id uuid, p_professional_ids uuid[], p_starts_at timestamp with time zone, p_internal_note text, p_created_by_user_id uuid, p_ignore_break boolean, p_source text, p_phone_communication_status text, p_phone_warning_acknowledged boolean, p_idempotency_key text, p_replay_only boolean DEFAULT false)
 RETURNS TABLE(id uuid, patient_id uuid, confirmation_token text, starts_at timestamp with time zone, ends_at timestamp with time zone, service_name_snapshot text, professional_name_snapshot text, patient_created boolean, idempotent_replay boolean, patient_resolution_strategy text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_catalog', 'pg_temp'
AS $function$
declare
	v_patient_mode text := lower(trim(coalesce(p_patient_mode, '')));
	v_source text := lower(trim(coalesce(p_source, '')));
	v_phone_status text := lower(trim(coalesce(p_phone_communication_status, '')));
	v_phone_acknowledged boolean := coalesce(p_phone_warning_acknowledged, false);
	v_replay_only boolean := coalesce(p_replay_only, false);
	v_idempotency_key text := lower(trim(coalesce(p_idempotency_key, '')));
	v_patient_name text := regexp_replace(trim(coalesce(p_patient_name, '')), '\s+', ' ', 'g');
	v_patient_phone_raw text := nullif(trim(coalesce(p_patient_phone_raw, '')), '');
	v_patient_phone_e164 text := nullif(trim(coalesce(p_patient_phone_e164, '')), '');
	v_patient_email text := nullif(trim(coalesce(p_patient_email, '')), '');
	v_professional_ids uuid[];
	v_request_fingerprint text;
	v_existing_request record;
	v_patient record;
	v_resolved_patient_id uuid;
	v_resolved_patient_name text;
	v_resolved_patient_phone_raw text;
	v_resolved_patient_phone_e164 text;
	v_resolution_strategy text;
	v_patient_created boolean := false;
	v_owner_id uuid := p_owner_id;
	v_exact_match_count integer := 0;
	v_exact_match_id uuid;
	v_service record;
	v_created record;
	v_appointment public.appointments%rowtype;
begin
	if p_business_id is null or p_service_id is null or p_starts_at is null then
		raise exception 'APPOINTMENT_REQUIRED_FIELDS';
	end if;
	if v_patient_mode not in ('existing', 'new', 'public') then
		raise exception 'PATIENT_MODE_INVALID';
	end if;
	if v_source not in ('manual', 'public_booking', 'whatsapp_bot', 'admin') then
		raise exception 'APPOINTMENT_SOURCE_INVALID';
	end if;
	if (v_patient_mode = 'public') <> (v_source = 'public_booking') then
		raise exception 'PATIENT_MODE_SOURCE_MISMATCH';
	end if;
	if v_phone_status not in ('unknown', 'valid', 'missing', 'invalid') then
		raise exception 'PHONE_COMMUNICATION_STATUS_INVALID';
	end if;
	if v_phone_status = 'valid' and v_patient_phone_e164 is null then
		raise exception 'PHONE_COMMUNICATION_STATUS_MISMATCH';
	end if;
	if v_phone_status in ('missing', 'invalid') and not v_phone_acknowledged then
		raise exception 'PHONE_WARNING_ACKNOWLEDGEMENT_REQUIRED';
	end if;
	if v_phone_status in ('unknown', 'valid') and v_phone_acknowledged then
		raise exception 'PHONE_WARNING_ACKNOWLEDGEMENT_UNEXPECTED';
	end if;
	if v_idempotency_key !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
		raise exception 'APPOINTMENT_IDEMPOTENCY_KEY_INVALID';
	end if;

	select array_agg(team.professional_id order by team.ordinality)
	into v_professional_ids
	from unnest(coalesce(p_professional_ids, array[]::uuid[])) with ordinality
		as team(professional_id, ordinality)
	where team.professional_id is not null;

	if coalesce(array_length(v_professional_ids, 1), 0) = 0 then
		raise exception 'PROFESSIONAL_NOT_FOUND';
	end if;
	if (
		select count(distinct professional_id)
		from unnest(v_professional_ids) professional_id
	) <> array_length(v_professional_ids, 1) then
		raise exception 'JOINT_APPOINTMENT_DUPLICATE_PROFESSIONAL';
	end if;

	if v_patient_mode = 'existing' then
		if p_patient_id is null then
			raise exception 'PATIENT_ID_REQUIRED';
		end if;
		if v_patient_name <> '' or v_patient_email is not null then
			raise exception 'PATIENT_EXISTING_FIELDS_UNEXPECTED';
		end if;
	else
		if p_patient_id is not null then
			raise exception 'PATIENT_ID_UNEXPECTED';
		end if;
		if v_patient_name = '' then
			raise exception 'PATIENT_NAME_REQUIRED';
		end if;
		if coalesce(p_update_existing_phone, false) then
			raise exception 'PATIENT_PHONE_UPDATE_MODE_INVALID';
		end if;
	end if;
	if v_patient_mode = 'public' and v_patient_phone_e164 is null then
		raise exception 'PUBLIC_PATIENT_PHONE_INVALID';
	end if;

	v_request_fingerprint := encode(
		digest(
			jsonb_build_object(
				'patient_mode', v_patient_mode,
				'patient_id', p_patient_id,
				'patient_name', nullif(v_patient_name, ''),
				'patient_phone_raw', v_patient_phone_raw,
				'patient_phone_e164', v_patient_phone_e164,
				'patient_email', v_patient_email,
				'update_existing_phone', coalesce(p_update_existing_phone, false),
				'owner_id', p_owner_id,
				'service_id', p_service_id,
				'professional_ids', to_jsonb(v_professional_ids),
				'starts_at', p_starts_at,
				'internal_note', nullif(trim(coalesce(p_internal_note, '')), ''),
				'created_by_user_id', p_created_by_user_id,
				'ignore_break', coalesce(p_ignore_break, false),
				'source', v_source,
				'phone_status', v_phone_status,
				'phone_acknowledged', v_phone_acknowledged
			)::text,
			'sha256'
		),
		'hex'
	);

	perform pg_advisory_xact_lock(
		hashtextextended(
			'appointment-create:' || p_business_id::text || ':' || v_idempotency_key,
			0
		)
	);

	select appointment.*
	into v_existing_request
	from public.appointments appointment
	where appointment.business_id = p_business_id
		and appointment.creation_request_key = v_idempotency_key;

	if found then
		if v_existing_request.creation_request_fingerprint is distinct from v_request_fingerprint then
			raise exception 'APPOINTMENT_IDEMPOTENCY_CONFLICT';
		end if;
		return query
		select
			v_existing_request.id,
			v_existing_request.patient_id,
			v_existing_request.confirmation_token,
			v_existing_request.starts_at,
			v_existing_request.ends_at,
			v_existing_request.service_name_snapshot,
			v_existing_request.professional_name_snapshot,
			false,
			true,
			v_existing_request.patient_resolution_strategy;
		return;
	end if;
	if v_replay_only then
		-- Zero rows means this key has not created an appointment. This read-only
		-- branch deliberately runs before mutable policy and availability checks so
		-- a retry can recover an already committed fourth booking or occupied slot.
		return;
	end if;

	if p_owner_id is not null and not exists (
		select 1
		from public.business_users business_user
		where business_user.business_id = p_business_id
			and business_user.user_id = p_owner_id
			and business_user.status = 'active'
			and business_user.disabled_at is null
	) then
        -- Assistance is temporary authority, never permanent patient ownership.
        -- Keep the original request fingerprint; reuse the existing clinic-owner
        -- resolution for a new patient when the verified helper supplied itself.
        if p_owner_id is distinct from p_created_by_user_id or v_source not in ('manual','admin')
          or private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_created_by_user_id) is null then
            raise exception 'PATIENT_OWNER_INVALID';
        end if;
        v_owner_id := null;
	end if;
    if p_created_by_user_id is not null and (
      (v_source in ('manual','admin') and private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_created_by_user_id) is null)
      or (v_source not in ('manual','admin') and not exists (
        select 1 from public.business_users business_user where business_user.business_id=p_business_id
        and business_user.user_id=p_created_by_user_id and business_user.status='active' and business_user.disabled_at is null
      ))) then
		raise exception 'APPOINTMENT_CREATOR_INVALID';
	end if;

	-- Validate the complete service/team contract before resolving or creating a
	-- patient. Public callers additionally require every selected resource to be
	-- visible in public booking at commit time, closing the race with settings.
	select service.duration_minutes
	into v_service
	from public.services service
	where service.business_id = p_business_id
		and service.id = p_service_id
		and service.is_active = true
		and (v_source <> 'public_booking' or service.is_public = true);
	if not found then
		raise exception 'SERVICE_NOT_FOUND';
	end if;
	if exists (
		select 1
		from unnest(v_professional_ids) selected(professional_id)
		left join public.professionals professional
			on professional.business_id = p_business_id
			and professional.id = selected.professional_id
			and professional.is_active = true
			and (v_source <> 'public_booking' or professional.is_public = true)
		left join public.professional_services assignment
			on assignment.business_id = p_business_id
			and assignment.professional_id = selected.professional_id
			and assignment.service_id = p_service_id
		where professional.id is null or assignment.professional_id is null
	) then
		raise exception 'PROFESSIONAL_SERVICE_NOT_ASSIGNED';
	end if;

	if v_patient_mode = 'existing' then
		select patient.id, patient.full_name, patient.phone_e164, patient.blocked, patient.archived_at
		into v_patient
		from public.patients patient
		where patient.business_id = p_business_id
			and patient.id = p_patient_id
		for update;
		if not found then
			raise exception 'PATIENT_NOT_FOUND';
		end if;
		if v_patient.archived_at is not null then
			raise exception 'PATIENT_ARCHIVED';
		end if;
		if v_patient.blocked then
			raise exception 'PATIENT_BLOCKED';
		end if;

		v_resolved_patient_id := v_patient.id;
		v_resolution_strategy := 'existing_id';
		if coalesce(p_update_existing_phone, false) then
			update public.patients patient
			set
				phone = coalesce(
					regexp_replace(v_patient_phone_e164, '\D', '', 'g'),
					v_patient_phone_raw
				),
				phone_raw = v_patient_phone_raw,
				phone_e164 = v_patient_phone_e164,
				updated_at = statement_timestamp()
			where patient.business_id = p_business_id
				and patient.id = v_resolved_patient_id;
		end if;
	elsif v_patient_mode = 'new' then
		if v_owner_id is null then
			select business_user.user_id
			into v_owner_id
			from public.business_users business_user
			where business_user.business_id = p_business_id
				and business_user.role = 'owner'
				and business_user.status = 'active'
				and business_user.disabled_at is null
			order by business_user.created_at asc, business_user.user_id asc
			limit 1;
		end if;
		if v_owner_id is null then
			raise exception 'PATIENT_OWNER_REQUIRED';
		end if;

		insert into public.patients (
			owner_id,
			business_id,
			full_name,
			phone,
			phone_raw,
			phone_e164,
			email
		)
		values (
			v_owner_id,
			p_business_id,
			v_patient_name,
			coalesce(regexp_replace(v_patient_phone_e164, '\D', '', 'g'), v_patient_phone_raw),
			v_patient_phone_raw,
			v_patient_phone_e164,
			v_patient_email
		)
		returning patients.id into v_resolved_patient_id;
		v_resolution_strategy := 'new_explicit';
		v_patient_created := true;
	else
		perform pg_advisory_xact_lock(
			hashtextextended(
				'patient-contact-resolution:' || p_business_id::text || ':' ||
				private.public_booking_contact_bucket(v_patient_name, v_patient_phone_e164),
				0
			)
		);

		select count(*)::integer
		into v_exact_match_count
		from public.patients patient
		where patient.business_id = p_business_id
			and patient.archived_at is null
			and patient.phone_e164 = v_patient_phone_e164
			and public.normalized_patient_name(patient.full_name)
				= public.normalized_patient_name(v_patient_name);

		if v_exact_match_count = 1 then
			select patient.id
			into v_exact_match_id
			from public.patients patient
			where patient.business_id = p_business_id
				and patient.archived_at is null
				and patient.phone_e164 = v_patient_phone_e164
				and public.normalized_patient_name(patient.full_name)
					= public.normalized_patient_name(v_patient_name)
			limit 1;

			select patient.id, patient.full_name, patient.phone_e164, patient.blocked, patient.archived_at
			into v_patient
			from public.patients patient
			where patient.business_id = p_business_id
				and patient.id = v_exact_match_id;
			-- Contact changes use the same advisory lock. Avoid taking a row lock
			-- here after that advisory lock: patient updates acquire their row lock
			-- first, and the inverse order could otherwise deadlock. A concurrent
			-- change is therefore serialized before or after this booking.
			if v_patient.blocked then
				raise exception 'PATIENT_BLOCKED';
			end if;
			v_resolved_patient_id := v_patient.id;
			v_resolution_strategy := 'public_exact_match';
		else
			if v_owner_id is null then
				select business_user.user_id
				into v_owner_id
				from public.business_users business_user
				where business_user.business_id = p_business_id
					and business_user.role = 'owner'
					and business_user.status = 'active'
					and business_user.disabled_at is null
				order by business_user.created_at asc, business_user.user_id asc
				limit 1;
			end if;
			if v_owner_id is null then
				raise exception 'PATIENT_OWNER_REQUIRED';
			end if;

			insert into public.patients (
				owner_id,
				business_id,
				full_name,
				phone,
				phone_raw,
				phone_e164,
				email
			)
			values (
				v_owner_id,
				p_business_id,
				v_patient_name,
				regexp_replace(v_patient_phone_e164, '\D', '', 'g'),
				v_patient_phone_raw,
				v_patient_phone_e164,
				v_patient_email
			)
			returning patients.id into v_resolved_patient_id;
			v_resolution_strategy := case
				when v_exact_match_count = 0 then 'public_new'
				else 'public_ambiguous_new'
			end;
			v_patient_created := true;
		end if;
	end if;

	select
		patient.full_name,
		coalesce(
			nullif(trim(patient.phone_raw), ''),
			nullif(trim(patient.phone), ''),
			patient.phone_e164
		) as phone_raw,
		patient.phone_e164,
		patient.blocked,
		patient.archived_at
	into v_patient
	from public.patients patient
	where patient.business_id = p_business_id
		and patient.id = v_resolved_patient_id;
	if not found then
		raise exception 'PATIENT_NOT_FOUND';
	end if;
	if v_patient.archived_at is not null then
		raise exception 'PATIENT_ARCHIVED';
	end if;
	if v_patient.blocked then
		raise exception 'PATIENT_BLOCKED';
	end if;
	v_resolved_patient_name := v_patient.full_name;
	v_resolved_patient_phone_raw := coalesce(v_patient_phone_raw, v_patient.phone_raw);
	v_resolved_patient_phone_e164 := v_patient.phone_e164;

	if array_length(v_professional_ids, 1) = 1 then
		perform set_config('cita_suite.appointment_identity_write', 'create', true);
		insert into public.appointments (
			business_id,
			patient_id,
			service_id,
			professional_id,
			starts_at,
			ends_at,
			blocking_starts_at,
			blocking_ends_at,
			status,
			source,
			reminder_due_at,
			internal_note,
			ignore_break,
			created_by_user_id,
			updated_by_user_id,
			service_name_snapshot,
			professional_name_snapshot,
			duration_minutes_snapshot,
			phone_communication_status_at_booking,
			phone_warning_acknowledged_at,
			patient_name_at_booking,
			patient_phone_raw_at_booking,
			patient_phone_e164_at_booking,
			patient_resolution_strategy,
			creation_request_key,
			creation_request_fingerprint
		)
		values (
			p_business_id,
			v_resolved_patient_id,
			p_service_id,
			v_professional_ids[1],
			p_starts_at,
			p_starts_at + make_interval(mins => v_service.duration_minutes),
			p_starts_at,
			p_starts_at + make_interval(mins => v_service.duration_minutes),
			'reserved',
			v_source,
			null,
			nullif(trim(coalesce(p_internal_note, '')), ''),
			coalesce(p_ignore_break, false),
			p_created_by_user_id,
			p_created_by_user_id,
			'Pendiente',
			'Pendiente',
			v_service.duration_minutes,
			v_phone_status,
			case when v_phone_acknowledged then statement_timestamp() else null end,
			v_resolved_patient_name,
			v_resolved_patient_phone_raw,
			v_resolved_patient_phone_e164,
			v_resolution_strategy,
			v_idempotency_key,
			v_request_fingerprint
		)
		returning * into v_appointment;
		perform set_config('cita_suite.appointment_identity_write', '', true);

		insert into public.audit_logs (
			business_id,
			user_id,
			action,
			entity_type,
			entity_id,
			metadata
		)
		values (
			p_business_id,
			p_created_by_user_id,
			case when v_source = 'public_booking' then 'appointment.public_created' else 'appointment.created' end,
			'appointment',
			v_appointment.id,
			jsonb_build_object(
				'source', v_source,
				'patient_id', v_resolved_patient_id,
				'patient_created', v_patient_created,
				'patient_resolution_strategy', v_resolution_strategy,
				'patient_name_at_booking', v_resolved_patient_name,
				'patient_phone_raw_at_booking', v_resolved_patient_phone_raw,
				'patient_phone_e164_at_booking', v_resolved_patient_phone_e164,
				'service_id', p_service_id,
				'professional_ids', to_jsonb(v_professional_ids),
				'starts_at', p_starts_at,
				'is_joint', false,
				'ignore_break', coalesce(p_ignore_break, false),
				'phone_communication_status_at_booking', v_phone_status,
				'phone_warning_acknowledged', v_phone_acknowledged,
				'creation_request_key', v_idempotency_key
			)
		);
	else
		select created.*
		into v_created
		from public.create_joint_appointment_with_phone_decision(
			p_business_id,
			v_resolved_patient_id,
			p_service_id,
			v_professional_ids,
			p_starts_at,
			p_internal_note,
			p_created_by_user_id,
			coalesce(p_ignore_break, false),
			v_source,
			v_phone_status,
			v_phone_acknowledged
		) created;
		if v_created.id is null then
			raise exception 'JOINT_APPOINTMENT_NOT_CREATED';
		end if;

		perform set_config('cita_suite.appointment_identity_write', 'create', true);
		update public.appointments appointment
		set
			patient_name_at_booking = v_resolved_patient_name,
			patient_phone_raw_at_booking = v_resolved_patient_phone_raw,
			patient_phone_e164_at_booking = v_resolved_patient_phone_e164,
			patient_resolution_strategy = v_resolution_strategy,
			creation_request_key = v_idempotency_key,
			creation_request_fingerprint = v_request_fingerprint
		where appointment.business_id = p_business_id
			and appointment.id = v_created.id
		returning * into v_appointment;
		perform set_config('cita_suite.appointment_identity_write', '', true);

		update public.audit_logs audit
		set metadata = coalesce(audit.metadata, '{}'::jsonb) || jsonb_build_object(
			'patient_created', v_patient_created,
			'patient_resolution_strategy', v_resolution_strategy,
			'patient_name_at_booking', v_resolved_patient_name,
			'patient_phone_raw_at_booking', v_resolved_patient_phone_raw,
			'patient_phone_e164_at_booking', v_resolved_patient_phone_e164,
			'creation_request_key', v_idempotency_key
		)
		where audit.business_id = p_business_id
			and audit.entity_type = 'appointment'
			and audit.entity_id = v_created.id
			and audit.action in ('appointment.created', 'appointment.public_created');
	end if;

	return query
	select
		v_appointment.id,
		v_appointment.patient_id,
		v_appointment.confirmation_token,
		v_appointment.starts_at,
		v_appointment.ends_at,
		v_appointment.service_name_snapshot,
		v_appointment.professional_name_snapshot,
		v_patient_created,
		false,
		v_resolution_strategy;
end;
$function$
;

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

CREATE OR REPLACE FUNCTION public.reassign_appointment_patient_safely(p_business_id uuid, p_appointment_id uuid, p_new_patient_id uuid, p_actor_user_id uuid, p_reason text)
 RETURNS TABLE(appointment_id uuid, old_patient_id uuid, new_patient_id uuid, cancelled_dispatches integer, superseded_dispatches integer, detached_push_subscriptions integer, superseded_push_attempts integer, invalidated_calendar_attempts integer, queued_calendar_deletions integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_catalog', 'pg_temp'
AS $function$
declare
	v_appointment public.appointments%rowtype;
	v_new_patient record;
	v_calendar_event public.appointment_google_calendar_events%rowtype;
	v_reason text := nullif(regexp_replace(trim(coalesce(p_reason, '')), '\s+', ' ', 'g'), '');
	v_cancelled_dispatches integer := 0;
	v_superseded_dispatches integer := 0;
	v_detached_push_subscriptions integer := 0;
	v_superseded_push_attempts integer := 0;
	v_invalidated_calendar_attempts integer := 0;
	v_queued_calendar_deletions integer := 0;
begin
	if p_business_id is null or p_appointment_id is null or p_new_patient_id is null then
		raise exception 'APPOINTMENT_REASSIGNMENT_REQUIRED_FIELDS';
	end if;
	if p_actor_user_id is null then
		raise exception 'APPOINTMENT_REASSIGNMENT_ACTOR_REQUIRED';
	end if;
    if private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_actor_user_id) is null then
        raise exception 'APPOINTMENT_REASSIGNMENT_ACTOR_INVALID';
    end if;
	if v_reason is null then
		raise exception 'APPOINTMENT_REASSIGNMENT_REASON_REQUIRED';
	end if;
	if char_length(v_reason) > 500 then
		raise exception 'APPOINTMENT_REASSIGNMENT_REASON_TOO_LONG';
	end if;

	select appointment.*
	into v_appointment
	from public.appointments appointment
	where appointment.business_id = p_business_id
		and appointment.id = p_appointment_id
	for update;
	if not found then
		raise exception 'APPOINTMENT_NOT_FOUND';
	end if;
	if v_appointment.patient_id = p_new_patient_id then
		raise exception 'APPOINTMENT_PATIENT_UNCHANGED';
	end if;

	begin
		select event_link.*
		into v_calendar_event
		from public.appointment_google_calendar_events event_link
		where event_link.business_id = p_business_id
			and event_link.appointment_id = p_appointment_id
		for update nowait;
	exception when lock_not_available then
		raise exception 'APPOINTMENT_REASSIGNMENT_CALENDAR_IN_FLIGHT';
	end;
	if v_calendar_event.id is not null
		and v_calendar_event.claimed_at is not null
		and v_calendar_event.claimed_at >= statement_timestamp() - interval '10 minutes'
	then
		raise exception 'APPOINTMENT_REASSIGNMENT_CALENDAR_IN_FLIGHT';
	end if;

	select
		patient.id,
		patient.full_name,
		coalesce(
			nullif(trim(patient.phone_raw), ''),
			nullif(trim(patient.phone), ''),
			patient.phone_e164
		) as phone_raw,
		patient.phone_e164,
		patient.blocked,
		patient.archived_at
	into v_new_patient
	from public.patients patient
	where patient.business_id = p_business_id
		and patient.id = p_new_patient_id
	for update;
	if not found then
		raise exception 'PATIENT_NOT_FOUND';
	end if;
	if v_new_patient.archived_at is not null then
		raise exception 'PATIENT_ARCHIVED';
	end if;
	if v_new_patient.blocked then
		raise exception 'PATIENT_BLOCKED';
	end if;

	perform dispatch.id
	from public.message_dispatches dispatch
	where dispatch.business_id = p_business_id
		and dispatch.appointment_id = p_appointment_id
	for update;
	if exists (
		select 1
		from public.message_dispatches dispatch
		where dispatch.business_id = p_business_id
			and dispatch.appointment_id = p_appointment_id
			and dispatch.status = 'sending'
	) then
		raise exception 'APPOINTMENT_REASSIGNMENT_MESSAGE_IN_FLIGHT';
	end if;

	perform subscription.id
	from public.push_subscriptions subscription
	where subscription.business_id = p_business_id
		and subscription.appointment_id = p_appointment_id
	for update;
	perform attempt.id
	from public.push_delivery_attempts attempt
	where attempt.business_id = p_business_id
		and attempt.appointment_id = p_appointment_id
	for update;

	if exists (
		select 1
		from public.push_subscriptions subscription
		where subscription.business_id = p_business_id
			and subscription.appointment_id = p_appointment_id
			and subscription.detached_at is null
			and (
				(subscription.push_24h_claimed_at is not null
					and subscription.push_24h_sent_at is null
					and subscription.push_24h_claimed_at >= statement_timestamp() - interval '10 minutes')
				or
				(subscription.push_2h_claimed_at is not null
					and subscription.push_2h_sent_at is null
					and subscription.push_2h_claimed_at >= statement_timestamp() - interval '10 minutes')
			)
	) or exists (
		select 1
		from public.push_delivery_attempts attempt
		where attempt.business_id = p_business_id
			and attempt.appointment_id = p_appointment_id
			and attempt.superseded_at is null
			and attempt.accepted_at is null
			and attempt.failed_at is null
			and attempt.created_at >= statement_timestamp() - interval '2 minutes'
	) then
		raise exception 'APPOINTMENT_REASSIGNMENT_PUSH_IN_FLIGHT';
	end if;

	if exists (
		select 1
		from public.google_calendar_oauth_attempts attempt
		where attempt.business_id = p_business_id
			and attempt.appointment_id = p_appointment_id
			and attempt.consumed_at is not null
			and attempt.expires_at > statement_timestamp()
	) then
		raise exception 'APPOINTMENT_REASSIGNMENT_CALENDAR_IN_FLIGHT';
	end if;

	update public.message_dispatches dispatch
	set
		superseded_at = statement_timestamp(),
		superseded_reason = 'patient_reassigned',
		updated_at = statement_timestamp(),
		metadata = coalesce(dispatch.metadata, '{}'::jsonb) || jsonb_build_object(
			'superseded_by_patient_reassignment', true,
			'previous_patient_id', v_appointment.patient_id,
			'new_patient_id', p_new_patient_id
		)
	where dispatch.business_id = p_business_id
		and dispatch.appointment_id = p_appointment_id
		and dispatch.superseded_at is null;
	get diagnostics v_superseded_dispatches = row_count;

	update public.message_dispatches dispatch
	set
		status = 'cancelled',
		cancelled_at = statement_timestamp(),
		last_error_code = 'PATIENT_REASSIGNED',
		human_error_message = 'Envío cancelado porque el turno fue reasignado a otra ficha.',
		updated_at = statement_timestamp()
	where dispatch.business_id = p_business_id
		and dispatch.appointment_id = p_appointment_id
		and dispatch.status in ('scheduled', 'queued');
	get diagnostics v_cancelled_dispatches = row_count;

	update public.push_subscriptions subscription
	set
		detached_at = statement_timestamp(),
		detached_reason = 'patient_reassigned',
		push_24h_claimed_at = null,
		push_2h_claimed_at = null,
		updated_at = statement_timestamp()
	where subscription.business_id = p_business_id
		and subscription.appointment_id = p_appointment_id
		and subscription.detached_at is null;
	get diagnostics v_detached_push_subscriptions = row_count;

	update public.push_delivery_attempts attempt
	set
		superseded_at = statement_timestamp(),
		updated_at = statement_timestamp()
	where attempt.business_id = p_business_id
		and attempt.appointment_id = p_appointment_id
		and attempt.superseded_at is null;
	get diagnostics v_superseded_push_attempts = row_count;

	delete from public.google_calendar_oauth_attempts attempt
	where attempt.business_id = p_business_id
		and attempt.appointment_id = p_appointment_id
		and attempt.consumed_at is null;
	get diagnostics v_invalidated_calendar_attempts = row_count;

	update public.appointment_google_calendar_events event_link
	set
		sync_status = 'pending_delete',
		claimed_at = null,
		next_attempt_at = statement_timestamp(),
		last_error_code = null,
		last_error_at = null,
		updated_at = statement_timestamp()
	where event_link.business_id = p_business_id
		and event_link.appointment_id = p_appointment_id
		and event_link.sync_status not in ('deleted', 'detached');
	get diagnostics v_queued_calendar_deletions = row_count;

	perform set_config('cita_suite.appointment_identity_write', 'repair', true);
	update public.appointments appointment
	set
		patient_id = p_new_patient_id,
		patient_name_at_booking = v_new_patient.full_name,
		patient_phone_raw_at_booking = v_new_patient.phone_raw,
		patient_phone_e164_at_booking = v_new_patient.phone_e164,
		patient_resolution_strategy = 'reassigned_manual',
		confirmation_token = encode(gen_random_bytes(32), 'hex'),
		calendar_sequence = appointment.calendar_sequence + 1,
		calendar_action_status = 'not_offered',
		calendar_provider = null,
		calendar_offered_at = null,
		calendar_action_at = null,
		calendar_action_count = 0,
		calendar_update_required_at = null,
		updated_by_user_id = p_actor_user_id,
		updated_at = statement_timestamp()
	where appointment.business_id = p_business_id
		and appointment.id = p_appointment_id;
	perform set_config('cita_suite.appointment_identity_write', '', true);

	insert into public.audit_logs (
		business_id,
		user_id,
		action,
		entity_type,
		entity_id,
		metadata
	)
	values (
		p_business_id,
		p_actor_user_id,
		'appointment.patient_reassigned',
		'appointment',
		p_appointment_id,
		jsonb_build_object(
			'old_patient_id', v_appointment.patient_id,
			'new_patient_id', p_new_patient_id,
			'new_patient_name', v_new_patient.full_name,
			'new_patient_phone_raw', v_new_patient.phone_raw,
			'new_patient_phone_e164', v_new_patient.phone_e164,
			'reason', v_reason,
			'confirmation_token_rotated', true,
			'cancelled_dispatches', v_cancelled_dispatches,
			'superseded_dispatches', v_superseded_dispatches,
			'detached_push_subscriptions', v_detached_push_subscriptions,
			'superseded_push_attempts', v_superseded_push_attempts,
			'invalidated_calendar_attempts', v_invalidated_calendar_attempts,
			'queued_calendar_deletions', v_queued_calendar_deletions,
			'previous_calendar_action_status', v_appointment.calendar_action_status,
			'previous_calendar_action_count', v_appointment.calendar_action_count,
			'previous_resolution_strategy', v_appointment.patient_resolution_strategy
		)
	);

    if private.business_operation_actor(p_business_id,array['owner','admin','reception'],p_actor_user_id) is null then
        raise exception 'APPOINTMENT_REASSIGNMENT_ACTOR_INVALID';
    end if;

	return query
	select
		p_appointment_id,
		v_appointment.patient_id,
		p_new_patient_id,
		v_cancelled_dispatches,
		v_superseded_dispatches,
		v_detached_push_subscriptions,
		v_superseded_push_attempts,
		v_invalidated_calendar_attempts,
		v_queued_calendar_deletions;
end;
$function$
;
-- CREATE OR REPLACE preserves ACLs. The internal core stays unexposed; the
-- existing backend wrappers remain service-role only.
notify pgrst,'reload schema';
commit;
