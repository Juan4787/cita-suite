-- Pending OAuth consent is bound to the exact original management channel.
-- No plaintext links, new capability issuance or revocation of established accounts.
begin;
alter table public.google_calendar_oauth_attempts
 add column management_token_hash text,
 add column management_token_ciphertext text,
 add column management_legacy boolean,
 add column authorized_at timestamptz;
alter table public.google_calendar_oauth_attempts add constraint google_calendar_oauth_management_binding check (
 (management_token_hash is null and management_token_ciphertext is null and management_legacy is null and authorized_at is null)
 or (management_token_hash is not null and management_token_ciphertext is not null and management_legacy is not null
  and management_token_hash ~ '^[0-9a-f]{64}$' and length(management_token_ciphertext) between 20 and 4096)
);
-- Old attempts deliberately retain NULL binding. Existing account connections
-- are not changed. The new callback cannot upgrade an old calendar-only nonce.
create function private.lock_patient_calendar_oauth_attempt(p_token text,p_legacy boolean,p_attempt_id uuid)
returns public.google_calendar_oauth_attempts language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; attempt public.google_calendar_oauth_attempts;
begin
 -- These commands write only child OAuth/connection/event/audit rows. They do
 -- not update appointment telemetry or patient activity/profile: SHARE is final.
 a:=private.lock_patient_push_management(p_token,p_legacy,true);
 select * into attempt from public.google_calendar_oauth_attempts
 where (business_id,appointment_id,id)=(a.business_id,a.id,p_attempt_id) for update;
 if not found or attempt.management_legacy is distinct from p_legacy
  or attempt.management_token_hash is distinct from encode(extensions.digest(p_token,'sha256'),'hex')
  or attempt.expires_at<=clock_timestamp() then raise exception 'GOOGLE_CALENDAR_OAUTH_STATE_INVALID'; end if;
 return attempt;
end $$;
create function public.begin_patient_google_calendar_authorization(p_token text,p_legacy boolean,p_state_hash text,
 p_verifier_ciphertext text,p_management_ciphertext text,p_force_consent boolean)
returns uuid language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; result uuid; v_now timestamptz;
begin
 a:=private.lock_patient_push_management(p_token,p_legacy,true);
 if not coalesce(p_state_hash ~ '^[0-9a-f]{64}$',false) or not coalesce(length(p_verifier_ciphertext) between 20 and 4096,false)
  or not coalesce(length(p_management_ciphertext) between 20 and 4096,false) or p_force_consent is null then
  raise exception 'GOOGLE_CALENDAR_OAUTH_STATE_INVALID'; end if;
 v_now:=clock_timestamp();
 insert into public.google_calendar_oauth_attempts(business_id,appointment_id,state_hash,code_verifier_ciphertext,force_consent,
  created_at,expires_at,management_token_hash,management_token_ciphertext,management_legacy)
 values(a.business_id,a.id,p_state_hash,p_verifier_ciphertext,p_force_consent,v_now,v_now+interval '10 minutes',
  encode(extensions.digest(p_token,'sha256'),'hex'),p_management_ciphertext,p_legacy) returning id into result;
 perform private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,result);
 return result;
end $$;
create function public.consume_patient_google_calendar_authorization(p_state_hash text,p_token text,p_legacy boolean)
returns table(attempt_id uuid,business_id uuid,appointment_id uuid,code_verifier_ciphertext text,force_consent boolean)
language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare target uuid; attempt public.google_calendar_oauth_attempts;
begin
 select id into target from public.google_calendar_oauth_attempts where state_hash=p_state_hash;
 if target is null then raise exception 'GOOGLE_CALENDAR_OAUTH_STATE_INVALID'; end if;
 attempt:=private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,target);
 if attempt.consumed_at is not null then raise exception 'GOOGLE_CALENDAR_OAUTH_STATE_INVALID'; end if;
 update public.google_calendar_oauth_attempts set consumed_at=clock_timestamp() where id=target;
 perform private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,target);
 return query select attempt.id,attempt.business_id,attempt.appointment_id,attempt.code_verifier_ciphertext,attempt.force_consent;
end $$;

-- Established core ABI/ACL/body preserved except the unnecessary parent key lock.
CREATE OR REPLACE FUNCTION public.authorize_google_calendar_event(p_appointment_id uuid, p_oauth_client_key text, p_google_subject text, p_refresh_token_ciphertext text, p_granted_scopes text[], p_now timestamp with time zone DEFAULT now())
 RETURNS TABLE(connection_row_id uuid, event_row_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
	appointment_row public.appointments%rowtype;
	connection_row public.google_calendar_connections%rowtype;
	existing_event public.appointment_google_calendar_events%rowtype;
	target_event_id uuid;
begin
	select * into appointment_row
	from public.appointments
	where id = p_appointment_id
	for no key update;

	if not found then
		raise exception 'GOOGLE_CALENDAR_APPOINTMENT_NOT_FOUND';
	end if;
	if not (
		'https://www.googleapis.com/auth/calendar.events.owned'
		= any(coalesce(p_granted_scopes, '{}'::text[]))
	) then
		raise exception 'GOOGLE_CALENDAR_SCOPE_MISSING';
	end if;
	if appointment_row.status not in ('reserved', 'confirmed', 'reschedule_requested')
		or appointment_row.starts_at <= p_now then
		raise exception 'GOOGLE_CALENDAR_APPOINTMENT_NOT_ACTIVE';
	end if;

	insert into public.google_calendar_connections as connection (
		oauth_client_key,
		google_subject,
		refresh_token_ciphertext,
		granted_scopes,
		revoked_at,
		last_error_code,
		updated_at
	) values (
		p_oauth_client_key,
		p_google_subject,
		p_refresh_token_ciphertext,
		coalesce(p_granted_scopes, '{}'::text[]),
		null,
		null,
		p_now
	)
	on conflict (oauth_client_key, google_subject) do update
	set refresh_token_ciphertext = coalesce(
			excluded.refresh_token_ciphertext,
			connection.refresh_token_ciphertext
		),
		granted_scopes = case
			when cardinality(excluded.granted_scopes) > 0 then excluded.granted_scopes
			else connection.granted_scopes
		end,
		revoked_at = case
			when excluded.refresh_token_ciphertext is not null then null
			else connection.revoked_at
		end,
		last_error_code = case
			when excluded.refresh_token_ciphertext is not null then null
			else connection.last_error_code
		end,
		updated_at = excluded.updated_at
	returning connection.* into connection_row;

	if connection_row.refresh_token_ciphertext is null or connection_row.revoked_at is not null then
		raise exception 'GOOGLE_CALENDAR_REAUTH_REQUIRED';
	end if;

	select * into existing_event
	from public.appointment_google_calendar_events
	where appointment_id = p_appointment_id
	for update;

	if found
		and existing_event.connection_id <> connection_row.id
		and existing_event.sync_status in ('active', 'pending_update', 'pending_delete') then
		raise exception 'GOOGLE_CALENDAR_ALREADY_CONNECTED';
	end if;

	insert into public.appointment_google_calendar_events as event_link (
		business_id,
		appointment_id,
		connection_id,
		calendar_id,
		event_id,
		sync_status,
		synced_sequence,
		claimed_at,
		attempt_count,
		next_attempt_at,
		last_error_code,
		last_error_at,
		updated_at
	) values (
		appointment_row.business_id,
		appointment_row.id,
		connection_row.id,
		'primary',
		null,
		'pending_create',
		-1,
		null,
		0,
		p_now,
		null,
		null,
		p_now
	)
	on conflict (appointment_id) do update
	set connection_id = excluded.connection_id,
		event_id = case
			when event_link.connection_id = excluded.connection_id then event_link.event_id
			else null
		end,
		sync_status = case
			when event_link.connection_id = excluded.connection_id
				and event_link.event_id is not null then 'pending_update'
			else 'pending_create'
		end,
		synced_sequence = case
			when event_link.connection_id = excluded.connection_id then event_link.synced_sequence
			else -1
		end,
		claimed_at = null,
		attempt_count = 0,
		next_attempt_at = p_now,
		last_error_code = null,
		last_error_at = null,
		updated_at = p_now
	returning event_link.id into target_event_id;

	return query select connection_row.id, target_event_id;
end;
$function$
;
create function public.authorize_patient_google_calendar_event(p_token text,p_legacy boolean,p_attempt_id uuid,
 p_oauth_client_key text,p_google_subject text,p_refresh_token_ciphertext text,p_granted_scopes text[])
returns table(connection_row_id uuid,event_row_id uuid)
language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare attempt public.google_calendar_oauth_attempts; result record;
begin
 attempt:=private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,p_attempt_id);
 if attempt.consumed_at is null then raise exception 'GOOGLE_CALENDAR_OAUTH_STATE_INVALID'; end if;
 if attempt.authorized_at is not null then raise exception 'GOOGLE_CALENDAR_OAUTH_ALREADY_AUTHORIZED'; end if;
 -- The background worker may already be creating the previous account's event.
 -- Do not replace that connection just because Pending has no provider ID yet.
 if exists(select 1 from public.appointment_google_calendar_events e join public.google_calendar_connections c on c.id=e.connection_id
  where (e.business_id,e.appointment_id)=(attempt.business_id,attempt.appointment_id)
   and e.sync_status in ('active','pending_create','pending_update','pending_delete')
   and (c.oauth_client_key,c.google_subject) is distinct from (p_oauth_client_key,p_google_subject)) then
  raise exception 'GOOGLE_CALENDAR_ALREADY_CONNECTED'; end if;
 select * into result from public.authorize_google_calendar_event(attempt.appointment_id,p_oauth_client_key,p_google_subject,
  p_refresh_token_ciphertext,p_granted_scopes,clock_timestamp());
 if result.event_row_id is null or result.connection_row_id is null then raise exception 'GOOGLE_CALENDAR_EVENT_LINK_NOT_CREATED'; end if;
 update public.google_calendar_oauth_attempts set authorized_at=clock_timestamp() where id=attempt.id;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(attempt.business_id,null,'appointment.google_calendar_authorized','appointment',attempt.appointment_id,
  jsonb_build_object('event_id',result.event_row_id,'attempt_id',attempt.id));
 perform private.lock_patient_calendar_oauth_attempt(p_token,p_legacy,attempt.id);
 return query select result.connection_row_id::uuid,result.event_row_id::uuid;
end $$;
revoke all on function private.lock_patient_calendar_oauth_attempt(text,boolean,uuid),
 public.begin_patient_google_calendar_authorization(text,boolean,text,text,text,boolean),
 public.consume_patient_google_calendar_authorization(text,text,boolean),
 public.authorize_patient_google_calendar_event(text,boolean,uuid,text,text,text,text[])
 from public,anon,authenticated,service_role;
grant execute on function public.begin_patient_google_calendar_authorization(text,boolean,text,text,text,boolean),
 public.consume_patient_google_calendar_authorization(text,text,boolean),
 public.authorize_patient_google_calendar_event(text,boolean,uuid,text,text,text,text[]) to service_role;
notify pgrst,'reload schema';
commit;
