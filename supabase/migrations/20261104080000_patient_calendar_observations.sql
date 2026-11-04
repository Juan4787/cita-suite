-- Current patient authority owns observations/removal, not a prior HTTP read.
-- Calendar-only readers and trusted background cores keep their separate ABI.
begin;
create function private.lock_patient_calendar_management(p_token text,p_legacy boolean,p_require_future boolean)
returns public.appointments language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments;
begin
 a:=private.push_management_context_at(p_token,p_legacy,clock_timestamp());
 if a.id is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 perform 1 from public.appointments where business_id=a.business_id and id=a.id for no key update;
 a:=private.push_management_context_at(p_token,p_legacy,clock_timestamp());
 if a.id is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 -- Appointment telemetry fires patient activity. UPDATE is the final mode;
 -- two appointments of one patient must never both hold SHARE then upgrade.
 perform 1 from public.patients where business_id=a.business_id and id=a.patient_id for update;
 a:=private.push_management_context_at(p_token,p_legacy,clock_timestamp());
 if a.id is null or (p_require_future and
  (a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=clock_timestamp())) then
  raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 return a;
end $$;
revoke all on function private.lock_patient_calendar_management(text,boolean,boolean) from public,anon,authenticated,service_role;

create function public.record_patient_calendar_action(p_token text,p_legacy boolean,p_action text,p_source text default null)
returns boolean language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; v_provider text;
begin
 a:=private.lock_patient_calendar_management(p_token,p_legacy,true);
 v_provider:=case p_action when 'clicked_google' then 'google' when 'clicked_ics' then 'ics'
  when 'downloaded_ics' then 'ics' when 'clicked_outlook' then 'outlook' when 'clicked_phone_calendar' then 'phone_calendar' end;
 if v_provider is null or (p_source is not null and (p_action<>'clicked_google' or p_source<>'android_native_fallback')) then
  raise exception 'CALENDAR_OBSERVATION_INVALID'; end if;
 perform public.record_calendar_action(a.id,p_action,v_provider);
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(a.business_id,null,'appointment.calendar_action','appointment',a.id,
  jsonb_build_object('calendar_action',p_action,'calendar_provider',v_provider,'previous_status',a.calendar_action_status)
   ||case when p_source is null then '{}'::jsonb else jsonb_build_object('source',p_source) end);
 perform private.lock_patient_calendar_management(p_token,p_legacy,true);
 return true;
end $$;

create function public.mark_patient_calendar_offered(p_token text,p_legacy boolean)
returns boolean language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; v_count integer;
begin
 a:=private.lock_patient_calendar_management(p_token,p_legacy,true);
 update public.appointments set calendar_action_status='offered',calendar_offered_at=clock_timestamp()
 where business_id=a.business_id and id=a.id and calendar_action_status='not_offered';
 get diagnostics v_count=row_count;
 perform private.lock_patient_calendar_management(p_token,p_legacy,true);
 return v_count=1;
end $$;

create function public.record_patient_calendar_metric(p_token text,p_legacy boolean,p_kind text,p_variant text default null)
returns boolean language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; v_action text; v_metadata jsonb;
begin
 if p_kind not in ('android_intent','maps') or p_kind is null
  or (p_kind='android_intent' and p_variant is not null and p_variant not in ('data','type'))
  or (p_kind='maps' and p_variant is not null) then raise exception 'CALENDAR_OBSERVATION_INVALID'; end if;
 -- Audit-only commands never update patient activity or appointment coverage.
 a:=private.lock_patient_push_management(p_token,p_legacy,p_kind='android_intent');
 v_action:=case p_kind when 'maps' then 'appointment.maps_opened' else 'appointment.calendar_intent_attempt' end;
 v_metadata:=case p_kind when 'maps' then jsonb_build_object('source','public_token')
  else jsonb_build_object('method','android_intent','variant',p_variant,'calendar_status_at_attempt',a.calendar_action_status) end;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(a.business_id,null,v_action,'appointment',a.id,v_metadata);
 perform private.lock_patient_push_management(p_token,p_legacy,p_kind='android_intent');
 return true;
end $$;

create function public.request_patient_google_calendar_deletion(p_token text,p_legacy boolean)
returns jsonb language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; e public.appointment_google_calendar_events;
begin
 a:=private.lock_patient_calendar_management(p_token,p_legacy,false);
 select * into e from public.appointment_google_calendar_events
 where business_id=a.business_id and appointment_id=a.id for update;
 if not found or e.sync_status='detached' then
  return jsonb_build_object('appointment_id',a.id,'event_row_id',null,'status','not_connected');
 end if;
 if e.sync_status<>'pending_delete' then
  perform public.request_google_calendar_event_deletion(a.id,clock_timestamp());
  insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
  values(a.business_id,null,'appointment.google_calendar_delete_requested','appointment',a.id,
   jsonb_build_object('previous_status',e.sync_status));
 end if;
 perform private.lock_patient_calendar_management(p_token,p_legacy,false);
 return jsonb_build_object('appointment_id',a.id,'event_row_id',e.id,'status','pending_delete');
end $$;

revoke all on function public.record_patient_calendar_action(text,boolean,text,text),
 public.mark_patient_calendar_offered(text,boolean),public.record_patient_calendar_metric(text,boolean,text,text),
 public.request_patient_google_calendar_deletion(text,boolean) from public,anon,authenticated,service_role;
grant execute on function public.record_patient_calendar_action(text,boolean,text,text),
 public.mark_patient_calendar_offered(text,boolean),public.record_patient_calendar_metric(text,boolean,text,text),
 public.request_patient_google_calendar_deletion(text,boolean) to service_role;
notify pgrst,'reload schema';
commit;
