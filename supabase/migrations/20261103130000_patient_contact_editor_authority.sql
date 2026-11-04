-- Preserve the existing optimistic edit and atomic history ABI. Contact changes
-- require current authority, including temporary assistance, until the final
-- effect. No new command, patient identity or accounting abstraction.
begin;
create or replace function public.update_patient_with_clinical_profile_safely(
	p_actor_id uuid,
	p_business_id uuid,
	p_patient_id uuid,
	p_full_name text,
	p_dni text,
	p_phone text,
	p_phone_raw text,
	p_phone_e164 text,
	p_email text,
	p_birth_date date,
	p_address text,
	p_insurance text,
	p_insurance_plan text,
	p_update_clinical_profile boolean default false,
	p_allergies text default null,
	p_medication text default null,
	p_background text default null,
	p_expected_patient_updated_at timestamptz default null,
	p_expected_clinical_profile_updated_at timestamptz default null
)
returns table(
	patient_id uuid,
	patient_updated_at timestamptz,
	clinical_profile_id uuid,
	clinical_profile_updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions, pg_catalog, pg_temp
as $$
declare
	v_actor uuid := coalesce(p_actor_id, auth.uid());
	v_role text;
	v_professional_id uuid;
	v_full_name text := regexp_replace(trim(coalesce(p_full_name, '')), '\s+', ' ', 'g');
	v_patient public.patients%rowtype;
	v_profile public.patient_clinical_profiles%rowtype;
	v_patient_id uuid;
	v_patient_updated_at timestamptz;
	v_profile_id uuid;
	v_profile_updated_at timestamptz;
begin
	if v_actor is null then
		raise exception 'AUTH_REQUIRED';
	end if;
	-- La ruta llama esta función con service_role y explicita al usuario que
	-- inició la sesión. Un caller autenticado no puede suplantar a otro actor.
	if coalesce(auth.role(), '') <> 'service_role'
		and auth.uid() is distinct from v_actor
	then
		raise exception 'PATIENT_UPDATE_DENIED';
	end if;
	if p_business_id is null or p_patient_id is null then
		raise exception 'PATIENT_NOT_FOUND';
	end if;

	v_role:=private.business_operation_actor(p_business_id,array['owner','admin','reception','professional'],v_actor);
	if v_role is null then
		if private.appointment_business_allows_operation_at(p_business_id,clock_timestamp()) is not true then
			raise exception 'BUSINESS_ACCESS_RESTRICTED';
		end if;
		raise exception 'PATIENT_UPDATE_DENIED';
	end if;
	if v_role='professional' then
		-- Match registration's professional-user -> patient -> patient-link order.
		-- Only lock the assignment here; validate/lock the active link after patient.
		select pu.professional_id into v_professional_id
		from public.professional_users pu join public.professional_patient_links ppl
		 on (ppl.business_id,ppl.professional_id)=(pu.business_id,pu.professional_id)
		where pu.business_id=p_business_id and pu.user_id=v_actor
		 and ppl.patient_id=p_patient_id and ppl.is_active
		order by pu.professional_id,ppl.id limit 1 for share of pu;
		if not found then raise exception 'PATIENT_ACCESS_DENIED'; end if;
	end if;
	if v_full_name = '' then
		raise exception 'PATIENT_NAME_REQUIRED';
	end if;

	-- Bloquea la ficha una sola vez. Todas las ediciones que usan esta RPC se
	-- serializan por paciente y el token evita sobrescribir una versión ajena.
	select *
	into v_patient
	from public.patients p
	where p.business_id = p_business_id
		and p.id = p_patient_id
	for update;
	if not found then
		raise exception 'PATIENT_NOT_FOUND';
	end if;
	if v_role='professional' then
		perform 1 from public.professional_patient_links ppl
		where ppl.business_id=p_business_id and ppl.professional_id=v_professional_id
		 and ppl.patient_id=p_patient_id and ppl.is_active for share;
		if not found then raise exception 'PATIENT_ACCESS_DENIED'; end if;
	end if;
	if p_expected_patient_updated_at is not null
		and v_patient.updated_at is distinct from p_expected_patient_updated_at
	then
		raise exception 'PATIENT_UPDATE_CONFLICT';
	end if;

	if coalesce(p_update_clinical_profile, false) then
		select *
		into v_profile
		from public.patient_clinical_profiles profile
		where profile.business_id = p_business_id
			and profile.patient_id = p_patient_id
		for update;
		if p_expected_clinical_profile_updated_at is not null
			and (v_profile.id is null or v_profile.updated_at is distinct from p_expected_clinical_profile_updated_at)
		then
			raise exception 'PATIENT_UPDATE_CONFLICT';
		end if;
	end if;

	update public.patients p
	set
		full_name = v_full_name,
		dni = nullif(trim(coalesce(p_dni, '')), ''),
		phone = nullif(trim(coalesce(p_phone, '')), ''),
		phone_raw = nullif(trim(coalesce(p_phone_raw, '')), ''),
		phone_e164 = nullif(trim(coalesce(p_phone_e164, '')), ''),
		email = nullif(trim(coalesce(p_email, '')), ''),
		birth_date = p_birth_date,
		address = nullif(trim(coalesce(p_address, '')), ''),
		insurance = nullif(trim(coalesce(p_insurance, '')), ''),
		insurance_plan = nullif(trim(coalesce(p_insurance_plan, '')), ''),
		updated_at = clock_timestamp()
	where p.business_id = p_business_id
		and p.id = p_patient_id
	returning p.id, p.updated_at
	into v_patient_id, v_patient_updated_at;
	if v_patient_id is null then
		raise exception 'PATIENT_UPDATE_CONFLICT';
	end if;

	if coalesce(p_update_clinical_profile, false) then
		if v_profile.id is null then
			begin
				insert into public.patient_clinical_profiles (
					business_id,
					patient_id,
					allergies,
					medication,
					background,
					updated_by,
					created_by
				)
				values (
					p_business_id,
					p_patient_id,
					nullif(trim(coalesce(p_allergies, '')), ''),
					nullif(trim(coalesce(p_medication, '')), ''),
					nullif(trim(coalesce(p_background, '')), ''),
					v_actor,
					v_actor
				)
				returning id, updated_at
				into v_profile_id, v_profile_updated_at;
			exception
				when unique_violation then
					raise exception 'PATIENT_UPDATE_CONFLICT';
			end;
		else
			update public.patient_clinical_profiles profile
			set
				allergies = nullif(trim(coalesce(p_allergies, '')), ''),
				medication = nullif(trim(coalesce(p_medication, '')), ''),
				background = nullif(trim(coalesce(p_background, '')), ''),
				updated_by = v_actor,
				updated_at = clock_timestamp()
			where profile.id = v_profile.id
				and profile.business_id = p_business_id
				and profile.patient_id = p_patient_id
				and profile.updated_at = v_profile.updated_at
			returning profile.id, profile.updated_at
			into v_profile_id, v_profile_updated_at;
			if v_profile_id is null then
				raise exception 'PATIENT_UPDATE_CONFLICT';
			end if;
		end if;
	end if;

	-- A temporary admin can fall back to a permanent professional at expiry.
	-- A merely non-null allowed role would then retain the previous admin scope.
	if private.business_operation_actor(p_business_id,array['owner','admin','reception','professional'],v_actor)
	 is distinct from v_role then raise exception 'PATIENT_UPDATE_DENIED'; end if;

	return query
	select v_patient_id, v_patient_updated_at, v_profile_id, v_profile_updated_at;
end;
$$;

create or replace function public.update_patient_with_clinical_profile_safely(
	p_actor_id uuid,
	p_business_id uuid,
	p_patient_id uuid,
	p_full_name text,
	p_dni text,
	p_phone text,
	p_phone_raw text,
	p_phone_e164 text,
	p_email text,
	p_birth_date date,
	p_address text,
	p_insurance text,
	p_insurance_plan text,
	p_changed_fields text[],
	p_change_summary text,
	p_changed_by_professional_id uuid,
	p_changed_by_name text,
	p_update_clinical_profile boolean default false,
	p_allergies text default null,
	p_medication text default null,
	p_background text default null,
	p_expected_patient_updated_at timestamptz default null,
	p_expected_clinical_profile_updated_at timestamptz default null
)
returns table(
	patient_id uuid,
	patient_updated_at timestamptz,
	clinical_profile_id uuid,
	clinical_profile_updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions, pg_catalog, pg_temp
as $$
declare
	v_actor uuid := coalesce(p_actor_id, auth.uid());
	v_saved record;
	v_role text;
begin
	if v_actor is null then raise exception 'AUTH_REQUIRED'; end if;
	if coalesce(auth.role(),'')<>'service_role' and auth.uid() is distinct from v_actor then
		raise exception 'PATIENT_UPDATE_DENIED'; end if;
	if p_business_id is null or p_patient_id is null then raise exception 'PATIENT_NOT_FOUND'; end if;
	v_role:=private.business_operation_actor(p_business_id,array['owner','admin','reception','professional'],v_actor);
	if v_role is null then
		if private.appointment_business_allows_operation_at(p_business_id,clock_timestamp()) is not true then
			raise exception 'BUSINESS_ACCESS_RESTRICTED';
		end if;
		raise exception 'PATIENT_UPDATE_DENIED';
	end if;
	if p_changed_by_professional_id is not null then
		perform 1 from public.professional_users pu
		where pu.business_id=p_business_id and pu.professional_id=p_changed_by_professional_id and pu.user_id=v_actor for share;
		if not found then raise exception 'PATIENT_UPDATE_DENIED'; end if;
	end if;
	if coalesce(cardinality(p_changed_fields), 0) > 0 and (
		nullif(trim(coalesce(p_change_summary, '')), '') is null
		or nullif(trim(coalesce(p_changed_by_name, '')), '') is null
	) then
		raise exception 'PATIENT_CHANGE_HISTORY_INVALID';
	end if;

	-- The previous signature keeps every check, lock and write of the update itself.
	select *
	into v_saved
	from public.update_patient_with_clinical_profile_safely(
		p_actor_id, p_business_id, p_patient_id, p_full_name, p_dni, p_phone, p_phone_raw,
		p_phone_e164, p_email, p_birth_date, p_address, p_insurance, p_insurance_plan,
		p_update_clinical_profile, p_allergies, p_medication, p_background,
		p_expected_patient_updated_at, p_expected_clinical_profile_updated_at
	);

	if coalesce(cardinality(p_changed_fields), 0) > 0 then
		insert into public.patient_profile_change_events (
			business_id,
			patient_id,
			changed_by_user_id,
			changed_by_professional_id,
			changed_by_name,
			changed_fields,
			summary
		)
		values (
			p_business_id,
			p_patient_id,
			v_actor,
			p_changed_by_professional_id,
			p_changed_by_name,
			to_jsonb(p_changed_fields),
			p_change_summary
		);
	end if;

	-- History is an effect of this command too. Its INSERT may have waited
	-- after the core's last check, so natural expiry must still roll back all.
	if private.business_operation_actor(p_business_id,array['owner','admin','reception','professional'],v_actor)
	 is distinct from v_role then raise exception 'PATIENT_UPDATE_DENIED'; end if;

	return query
	select v_saved.patient_id, v_saved.patient_updated_at, v_saved.clinical_profile_id, v_saved.clinical_profile_updated_at;
end;
$$;

-- Both replacements preserve their existing backend-only grants.
notify pgrst,'reload schema';
commit;
