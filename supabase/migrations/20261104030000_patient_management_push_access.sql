-- AC09: new public notification writes decide management authority in SQL.
-- Existing device receipts and trusted background delivery keep their contracts.
begin;

create function private.push_management_context_at(p_token text,p_legacy boolean,p_now timestamptz)
returns public.appointments language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 with access as materialized (select private.appointment_management_access_at(p_token,p_legacy,p_now) as context)
 select a.* from access join public.appointments a
  on (a.business_id,a.id)=((context->>'business_id')::uuid,(context->>'appointment_id')::uuid)
 join public.patients p on (p.business_id,p.id)=(a.business_id,a.patient_id)
 join public.businesses b on b.id=a.business_id
 where context is not null and p.archived_at is null and b.is_active
  and private.appointment_business_allows_operation_at(b.id,p_now)
$$;

create function private.lock_patient_push_management(p_token text,p_legacy boolean,p_require_future boolean)
returns public.appointments language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments;
begin
 a:=private.push_management_context_at(p_token,p_legacy,clock_timestamp());
 if a.id is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 perform 1 from public.appointments where business_id=a.business_id and id=a.id for no key update;
 a:=private.push_management_context_at(p_token,p_legacy,clock_timestamp());
 if a.id is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 -- These commands never write patient activity/profile. SHARE prevents contact
 -- correction through the decision, without introducing a later lock upgrade.
 perform 1 from public.patients where business_id=a.business_id and id=a.patient_id for share;
 a:=private.push_management_context_at(p_token,p_legacy,clock_timestamp());
 if a.id is null or (p_require_future and
  (a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=clock_timestamp())) then
  raise exception 'APPOINTMENT_LINK_UNAVAILABLE';
 end if;
 return a;
end $$;

-- The existing trigger and preparation reuse exactly the same association/device
-- guard. A reused test must still be attached to this appointment and healthy.
create function private.require_push_subscription_identity(p_subscription_id uuid,p_business_id uuid,p_appointment_id uuid)
returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_subscription record;
begin
 select subscription.business_id,subscription.appointment_id,subscription.detached_at,device.provider_gone_at
 into v_subscription from public.push_subscriptions subscription
 join public.push_devices device on device.id=subscription.device_id
 where subscription.id=p_subscription_id for key share of subscription,device;
 if not found then raise exception 'PUSH_SUBSCRIPTION_NOT_FOUND'; end if;
 if v_subscription.business_id is distinct from p_business_id or v_subscription.appointment_id is distinct from p_appointment_id then
  raise exception 'PUSH_SUBSCRIPTION_MISMATCH';
 end if;
 if v_subscription.detached_at is not null then raise exception 'PUSH_SUBSCRIPTION_DETACHED'; end if;
 if v_subscription.provider_gone_at is not null then raise exception 'PUSH_DEVICE_GONE'; end if;
end $$;
create or replace function private.validate_push_delivery_attempt_identity()
returns trigger language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 perform private.require_push_subscription_identity(new.subscription_id,new.business_id,new.appointment_id);
 return new;
end $$;

-- This established command changes device data, never its endpoint/id keys.
-- Match that write with NO KEY UPDATE, so a background delivery's real FK key
-- shares can finish before the association upsert. Keep its complete ABI/body.
CREATE OR REPLACE FUNCTION public.save_appointment_push_subscription(target_business_id uuid, target_appointment_id uuid, target_endpoint text, target_p256dh text, target_auth text, target_user_agent text, save_time timestamp with time zone DEFAULT now())
 RETURNS TABLE(subscription_id uuid, device_id uuid, endpoint text, verification_confirmed_at timestamp with time zone, test_suppressed boolean, provider_gone boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog', 'pg_temp'
AS $function$
declare
	v_device public.push_devices%rowtype;
	v_subscription_id uuid;
	v_keys_changed boolean := false;
	v_positive_at timestamptz;
	v_test_suppressed boolean := false;
begin
	if target_business_id is null
		or target_appointment_id is null
		or save_time is null
		or nullif(trim(target_endpoint), '') is null
		or nullif(trim(target_p256dh), '') is null
		or nullif(trim(target_auth), '') is null
	then
		raise exception 'PUSH_SUBSCRIPTION_INVALID';
	end if;

	if not exists (
		select 1
		from public.appointments appointment
		where appointment.business_id = target_business_id
			and appointment.id = target_appointment_id
	) then
		raise exception 'APPOINTMENT_NOT_FOUND';
	end if;

	select device.*
	into v_device
	from public.push_devices device
	where device.endpoint = target_endpoint
	for no key update;

	if not found then
		insert into public.push_devices (
			endpoint,
			p256dh,
			auth,
			user_agent,
			last_seen_at,
			verification_required_at,
			created_at,
			updated_at
		)
		values (
			target_endpoint,
			target_p256dh,
			target_auth,
			target_user_agent,
			save_time,
			save_time,
			save_time,
			save_time
		)
		returning * into v_device;
	else
		v_keys_changed := v_device.p256dh is distinct from target_p256dh
			or v_device.auth is distinct from target_auth;

		update public.push_devices device
		set
			p256dh = target_p256dh,
			auth = target_auth,
			user_agent = coalesce(target_user_agent, device.user_agent),
			last_seen_at = save_time,
			verification_required_at = case
				when v_keys_changed then save_time
				else device.verification_required_at
			end,
			provider_gone_at = case
				when v_keys_changed then null
				else device.provider_gone_at
			end,
			updated_at = save_time
		where device.id = v_device.id
		returning * into v_device;
	end if;

	v_positive_at := greatest(
		v_device.last_test_confirmed_at,
		v_device.last_notification_clicked_at
	);
	v_test_suppressed :=
		v_device.provider_gone_at is null
		and v_positive_at is not null
		and (
			v_device.verification_required_at is null
			or v_positive_at >= v_device.verification_required_at
			or v_device.last_test_confirmed_at >= save_time - interval '48 hours'
		);

	insert into public.push_subscriptions (
		business_id,
		appointment_id,
		device_id,
		failed_count,
		detached_at,
		detached_reason,
		updated_at
	)
	values (
		target_business_id,
		target_appointment_id,
		v_device.id,
		0,
		null,
		null,
		save_time
	)
	on conflict on constraint push_subscriptions_appointment_device_key do update
	set
		business_id = excluded.business_id,
		failed_count = 0,
		detached_at = null,
		detached_reason = null,
		updated_at = excluded.updated_at
	returning id into v_subscription_id;

	return query
	select
		v_subscription_id,
		v_device.id,
		v_device.endpoint,
		case when v_test_suppressed then v_positive_at else null end,
		v_test_suppressed,
		v_device.provider_gone_at is not null;
end;
$function$
;

create function public.save_patient_appointment_push_subscription(p_token text,p_legacy boolean,
 p_endpoint text,p_p256dh text,p_auth text,p_user_agent text)
returns table(subscription_id uuid,device_id uuid,endpoint text,verification_confirmed_at timestamptz,test_suppressed boolean,provider_gone boolean)
language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments;
begin
 a:=private.lock_patient_push_management(p_token,p_legacy,true);
 return query select * from public.save_appointment_push_subscription(a.business_id,a.id,p_endpoint,p_p256dh,p_auth,p_user_agent,clock_timestamp());
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(a.business_id,null,'appointment.push_subscribed','appointment',a.id,
  jsonb_build_object('endpoint_host',split_part(split_part(split_part(p_endpoint,'://',2),'/',1),':',1)));
 perform private.lock_patient_push_management(p_token,p_legacy,true);
end $$;

create function public.begin_patient_push_test(p_token text,p_legacy boolean,p_subscription_id uuid,
 p_receipt_token_hash text,p_request_key_hash text)
returns table(delivery_id uuid,reused boolean,push_service_status integer,failure_kind text)
language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; prior public.push_delivery_attempts; result uuid; v_now timestamptz;
begin
 a:=private.lock_patient_push_management(p_token,p_legacy,true);
 if p_subscription_id is null or p_receipt_token_hash is null or p_receipt_token_hash !~ '^[a-f0-9]{64}$'
  or (p_request_key_hash is not null and p_request_key_hash !~ '^[a-f0-9]{64}$') then
  raise exception 'PUSH_SUBSCRIPTION_INVALID';
 end if;
 perform private.require_push_subscription_identity(p_subscription_id,a.business_id,a.id);
 v_now:=clock_timestamp();
 -- Recover the exact key even if it failed/expired: it is the same attempted
 -- operation, never permission to send it again with another receipt secret.
 select * into prior from public.push_delivery_attempts d where d.appointment_id=a.id
  and d.subscription_id=p_subscription_id and d.kind='test' and d.request_key_hash=p_request_key_hash;
 if found then
  perform private.lock_patient_push_management(p_token,p_legacy,true);
  return query select prior.id,true,prior.push_service_status::integer,
   case when prior.failed_at is not null and prior.user_confirmed_at is null and prior.clicked_at is null
    then coalesce(prior.failure_kind,'transient') else null::text end;
  return;
 end if;
 -- The parent gate closes the old two-tab gap between checking for a recent
 -- test and inserting one. This is the existing 30-second presentation rule.
 select * into prior from public.push_delivery_attempts d where d.appointment_id=a.id
  and d.subscription_id=p_subscription_id and d.kind='test' and d.created_at>v_now-interval '30 seconds'
  -- Preserve deliveryState's established precedence: real confirmation/click
  -- wins over a later provider timeout. Do not send a second test in that race.
  and (d.user_confirmed_at is not null or d.clicked_at is not null or
   (d.expires_at>v_now and d.failed_at is null and d.superseded_at is null and d.user_reported_missing_at is null))
  order by d.created_at desc limit 1;
 if found then
  perform private.lock_patient_push_management(p_token,p_legacy,true);
  return query select prior.id,true,prior.push_service_status::integer,null::text;
  return;
 end if;
 insert into public.push_delivery_attempts(business_id,appointment_id,subscription_id,kind,request_key_hash,
  receipt_token_hash,expires_at,created_at,updated_at)
 values(a.business_id,a.id,p_subscription_id,'test',p_request_key_hash,p_receipt_token_hash,v_now+interval '5 minutes',v_now,v_now)
 returning id into result;
 perform private.lock_patient_push_management(p_token,p_legacy,true);
 return query select result,false,null::integer,null::text;
end $$;

create function public.record_patient_push_test_feedback(p_token text,p_legacy boolean,p_delivery_id uuid,p_visible boolean)
returns boolean language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; result boolean;
begin
 -- Finishing an already accepted test does not create a new appointment
 -- reminder. Keep that established device-feedback contract after closure.
 a:=private.lock_patient_push_management(p_token,p_legacy,false);
 result:=public.record_push_test_feedback(a.id,p_delivery_id,p_visible,clock_timestamp());
 perform private.lock_patient_push_management(p_token,p_legacy,false);
 return result;
end $$;

revoke all on function private.push_management_context_at(text,boolean,timestamptz),
 private.lock_patient_push_management(text,boolean,boolean),private.require_push_subscription_identity(uuid,uuid,uuid),
 public.save_patient_appointment_push_subscription(text,boolean,text,text,text,text),
 public.begin_patient_push_test(text,boolean,uuid,text,text),public.record_patient_push_test_feedback(text,boolean,uuid,boolean)
 from public,anon,authenticated,service_role;
grant execute on function public.save_patient_appointment_push_subscription(text,boolean,text,text,text,text),
 public.begin_patient_push_test(text,boolean,uuid,text,text),public.record_patient_push_test_feedback(text,boolean,uuid,boolean) to service_role;
notify pgrst,'reload schema';
commit;
