-- E: an explicit staff delivery prepares one current snapshot and capability.
-- Reading an agenda/list never issues credentials. No provider is called here.
begin;

create function public.prepare_staff_appointment_delivery(p_business_id uuid,p_appointment_id uuid,
 p_expected_revision text,p_kind text,p_reopen boolean default false,p_expected_phone text default null) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; patient public.patients; m public.appointment_management_states;
 d public.appointment_deposits; policy public.deposit_policies; b public.businesses;
 v_actor uuid:=auth.uid(); v_now timestamptz; v_token text; v_modality text; v_reopened boolean:=false;
begin
 if p_business_id is null or p_appointment_id is null
  or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false)
  or not coalesce(p_kind in ('activation','rescheduled','reminder','deposit'),false)
  or p_reopen is null or (p_reopen and p_kind not in ('reminder','deposit'))
  or (p_expected_phone is not null and (length(p_expected_phone)>128 or p_kind not in ('reminder','deposit'))) then
  raise exception 'APPOINTMENT_DELIVERY_INVALID'; end if;
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],v_actor) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_NOT_FOUND'; end if;
 -- Same parent-first order as identity repair. Holding the patient prevents a
 -- recipient/name correction between this snapshot and credential issuance.
 select * into patient from public.patients where business_id=p_business_id and id=a.patient_id for share;
 if not found or patient.blocked or patient.archived_at is not null then
  raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],v_actor) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if private.appointment_semantic_revision(p_business_id,a.id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 -- The route uses the existing phone normalizer before recording an opening.
 -- Bind that successful check to the exact stored value under the patient lock;
 -- a concurrent correction cannot silently switch the prepared recipient.
 if p_kind in ('reminder','deposit') and (p_expected_phone is null or btrim(p_expected_phone)=''
  or p_expected_phone is distinct from patient.phone_e164) then
  raise exception 'APPOINTMENT_DELIVERY_CONTACT_CHANGED'; end if;
 v_now:=clock_timestamp();
 if a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=v_now
  or (p_kind='reminder' and a.status='reschedule_requested') then
  raise exception 'APPOINTMENT_DELIVERY_UNAVAILABLE'; end if;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=a.id;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;

 if p_kind='reminder' then
  v_reopened:=a.whatsapp_reminder_opened_at is not null;
  if v_reopened and not p_reopen then raise exception 'APPOINTMENT_REMINDER_ALREADY_OPENED'; end if;
  update public.appointments set whatsapp_reminder_opened_at=v_now,whatsapp_reminder_opened_by=v_actor,updated_at=v_now
   where business_id=p_business_id and id=a.id;
  insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
   values(p_business_id,v_actor,'reminder.whatsapp_opened','appointment',a.id,jsonb_build_object('reopened',v_reopened));
 elsif p_kind='deposit' then
  -- Preserve this command's established pending/reopen rules and audit. Its
  -- locks and effects are part of this same transaction, never a second commit.
  perform public.open_appointment_deposit_reminder(p_business_id,a.id,p_reopen);
  select * into d from public.appointment_deposits where business_id=p_business_id and appointment_id=a.id;
  select * into policy from public.deposit_policies where business_id=p_business_id;
 end if;

 -- The backend issuer remains separate for outbox workers. This authenticated
 -- command supplies its own current authority; no browser chooses an actor.
 v_token:=public.issue_appointment_management_capability(p_business_id,a.id,m.generation);
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
  values(p_business_id,v_actor,'appointment.management_link_prepared','appointment',a.id,
   jsonb_build_object('kind',p_kind,'generation',m.generation));
 select * into b from public.businesses where id=p_business_id;
 select modality into v_modality from public.appointment_booking_contexts where business_id=p_business_id and appointment_id=a.id;
 -- Audit triggers may wait too. Expiry rolls back marks, capability and audit,
 -- rather than returning a success after the authority or useful time expired.
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],v_actor) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if a.starts_at<=clock_timestamp() then raise exception 'APPOINTMENT_DELIVERY_UNAVAILABLE'; end if;
 return jsonb_build_object('appointment_id',a.id,'token',v_token,'patient_name',patient.full_name,
  'phone_e164',patient.phone_e164,'starts_at',a.starts_at,'status',a.status,'modality',coalesce(v_modality,'in_person'),
  'business',jsonb_build_object('name',b.name,'timezone',b.timezone,'address',b.address,'maps_url',b.maps_url),
  'deposit',case when p_kind='deposit' then jsonb_build_object('appointment_id',d.appointment_id,'status',d.status,
   'amount',d.amount,'currency',d.currency,'request_from',d.request_from,'due_at',d.due_at,'auto_cancel',d.auto_cancel,
   'waived_reason',d.waived_reason,'recorded_at',d.recorded_at,'reminder_opened_at',d.reminder_opened_at,
   'expired_at',d.expired_at,'revision',d.revision) end,
  'transfer_details',case when p_kind='deposit' then policy.transfer_details end,
  'deposit_auto_cancel_enabled',coalesce(p_kind='deposit' and policy.auto_cancel_enabled,false));
end $$;

-- A staff assertion of a manual send is not provider delivery evidence. The
-- displayed revision prevents an old message from covering a moved/repaired turn.
-- Repeating that assertion is a no-op, including its audit.
create function public.mark_appointment_whatsapp_reminder_sent(p_business_id uuid,p_appointment_id uuid,
 p_expected_revision text) returns boolean
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; v_actor uuid:=auth.uid(); v_now timestamptz;
begin
 if p_business_id is null or p_appointment_id is null or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false) then
  raise exception 'APPOINTMENT_DELIVERY_INVALID'; end if;
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],v_actor) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_NOT_FOUND'; end if;
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],v_actor) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if private.appointment_semantic_revision(p_business_id,a.id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_now:=clock_timestamp();
 -- Recording an already performed manual send may happen after its time; it
 -- does not issue a new message or capability. Preserve that factual contract.
 if a.status not in ('reserved','confirmed') then
  raise exception 'APPOINTMENT_DELIVERY_UNAVAILABLE'; end if;
 if a.whatsapp_reminder_marked_sent_at is not null then return false; end if;
 update public.appointments set whatsapp_reminder_marked_sent_at=v_now,whatsapp_reminder_marked_sent_by=v_actor,updated_at=v_now
  where business_id=p_business_id and id=a.id;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
  values(p_business_id,v_actor,'reminder.whatsapp_marked_sent','appointment',a.id,null);
 if private.business_operation_actor(p_business_id,array['owner','admin','reception'],v_actor) is null then
  raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 return true;
end $$;

revoke all on function public.prepare_staff_appointment_delivery(uuid,uuid,text,text,boolean,text),
 public.mark_appointment_whatsapp_reminder_sent(uuid,uuid,text) from public,anon,authenticated,service_role;
grant execute on function public.prepare_staff_appointment_delivery(uuid,uuid,text,text,boolean,text),
 public.mark_appointment_whatsapp_reminder_sent(uuid,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
