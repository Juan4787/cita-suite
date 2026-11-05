-- SN14: record money received after cancellation without reopening the turn or
-- rewriting its closed deposit. Corrections append facts, never bank refunds.
begin;

alter table public.appointment_deposit_events add column corrects_event_id uuid
 references public.appointment_deposit_events(id);
alter table public.appointment_deposit_events add constraint appointment_deposit_event_correction_kind
 check(corrects_event_id is null or event_type='recording_reversed');
create unique index appointment_deposit_event_one_correction
 on public.appointment_deposit_events(corrects_event_id) where corrects_event_id is not null;

create function private.appointment_late_deposit_balance(p_business_id uuid,p_appointment_id uuid,p_patient_id uuid)
returns numeric language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select coalesce(sum(case when e.event_type='late_payment_recorded' then e.amount
  when e.event_type='recording_reversed' and e.corrects_event_id is not null then -e.amount else 0 end),0)
 from public.appointment_deposit_events e join public.appointment_deposit_requirements r
  on (r.business_id,r.appointment_id,r.id)=(e.business_id,e.appointment_id,e.requirement_id)
 where e.business_id=p_business_id and e.appointment_id=p_appointment_id and r.patient_id=p_patient_id
$$;

create function private.appointment_deposit_summary(p_business_id uuid,p_appointment_id uuid,p_patient_id uuid)
returns jsonb language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select jsonb_build_object(
  'applied_amount',coalesce(sum(amount) filter(where allocation='applied'),0)::text,
  'forfeited_amount',coalesce(sum(amount) filter(where allocation='forfeited'),0)::text,
  'unresolved_amount',(coalesce(sum(amount) filter(where allocation='unresolved'),0)
   +private.appointment_late_deposit_balance(p_business_id,p_appointment_id,p_patient_id))::text)
 from public.appointment_deposit_requirements
 where business_id=p_business_id and appointment_id=p_appointment_id and patient_id=p_patient_id and status='paid'
$$;

-- Identity repair and monetary commands already retain the same appointment.
-- The established paid-requirement guard remains; this covers the new facts
-- that deliberately leave that requirement and its projection closed.
create function private.guard_late_deposit_identity() returns trigger
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if (new.business_id,new.patient_id) is distinct from (old.business_id,old.patient_id)
  and private.appointment_late_deposit_balance(old.business_id,old.id,old.patient_id)>0 then
  raise exception 'APPOINTMENT_DEPOSIT_IDENTITY_CHANGE'; end if;
 return new;
end $$;
create trigger guard_late_deposit_identity before update of business_id,patient_id on public.appointments
 for each row execute function private.guard_late_deposit_identity();

-- A computed field, like appointment_management_revision: the actual row is
-- reloaded and its existing reader scope checked. A forged composite argument
-- cannot choose another patient. Summary and parent share one SELECT snapshot.
create function public.appointment_deposit_financials(public.appointments) returns jsonb
language sql stable security definer set search_path=pg_catalog,pg_temp as $$
 select private.appointment_deposit_summary(a.business_id,a.id,a.patient_id)||jsonb_build_object(
  'late_payments',coalesce((select jsonb_agg(t.payload order by t.ordinal desc) from (
   select e.ordinal,jsonb_build_object('id',e.id,'amount',e.amount::text,'recorded_at',e.created_at,
    'corrected',exists(select 1 from public.appointment_deposit_events correction where correction.corrects_event_id=e.id)) as payload
   from public.appointment_deposit_events e join public.appointment_deposit_requirements r
    on (r.business_id,r.appointment_id,r.id)=(e.business_id,e.appointment_id,e.requirement_id)
   where e.business_id=a.business_id and e.appointment_id=a.id and r.patient_id=a.patient_id
    and e.event_type='late_payment_recorded' order by e.ordinal desc limit 50) t),'[]'::jsonb),
  'late_payments_truncated',exists(select 1 from public.appointment_deposit_events e
   join public.appointment_deposit_requirements r on (r.business_id,r.appointment_id,r.id)=(e.business_id,e.appointment_id,e.requirement_id)
   where e.business_id=a.business_id and e.appointment_id=a.id and r.patient_id=a.patient_id
    and e.event_type='late_payment_recorded' order by e.ordinal desc offset 50 limit 1))
 from public.appointments a
 where auth.uid() is not null and a.business_id=($1).business_id and a.id=($1).id
  and (a.business_id=any((select public.user_appointment_reader_business_ids())::uuid[])
   or (a.business_id,a.id) in (select scope.business_id,scope.appointment_id from public.user_allocated_appointment_ids() scope))
$$;

create function public.record_late_appointment_deposit(p_business_id uuid,p_appointment_id uuid,p_operation_id uuid,
 p_expected_revision text,p_action text,p_amount text default null,p_corrects_event_id uuid default null,p_note text default null)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; m public.appointment_management_states; r public.appointment_deposit_requirements;
 prior private.appointment_management_operations; original public.appointment_deposit_events;
 v_actor uuid:=auth.uid(); v_fingerprint text; v_amount bigint; v_event uuid; v_now timestamptz;
 v_action text; v_result jsonb; v_note text:=nullif(btrim(p_note),'');
begin
 if p_business_id is null or p_appointment_id is null or p_operation_id is null
  or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false)
  or not coalesce(p_action in ('record','correct'),false) or length(p_note)>300 then
  raise exception 'DEPOSIT_LATE_INVALID'; end if;
 if p_action='record' then
  if p_corrects_event_id is not null or not coalesce(p_amount ~ '^[1-9][0-9]{0,12}$',false) then
   raise exception 'DEPOSIT_LATE_INVALID'; end if;
  v_amount:=p_amount::bigint;
  if v_amount>1000000000000 then raise exception 'DEPOSIT_LATE_INVALID'; end if;
 elsif p_amount is not null or p_corrects_event_id is null then raise exception 'DEPOSIT_LATE_INVALID'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 perform pg_advisory_xact_lock(hashtextextended('appointment-management-operation:'||p_business_id::text||':'||p_operation_id::text,0));
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'DEPOSIT_NOT_FOUND'; end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=a.id;
 if not found then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_action:='late_deposit_'||p_action;
 v_fingerprint:=encode(extensions.digest(jsonb_build_object('contract','staff-late-deposit-1','actor_id',v_actor,
  'appointment_id',a.id,'patient_id',a.patient_id,'generation',m.generation,'action',p_action,
  'expected_revision',p_expected_revision,'amount',p_amount,'corrects_event_id',p_corrects_event_id,'note',v_note)::text,'sha256'),'hex');
 select * into prior from private.appointment_management_operations where business_id=p_business_id and operation_id=p_operation_id;
 if found then
  if prior.appointment_id is distinct from a.id or prior.actor_id is distinct from v_actor or prior.origin<>'staff'
   or prior.action is distinct from v_action or prior.request_fingerprint is distinct from v_fingerprint then
   raise exception 'APPOINTMENT_OPERATION_CONFLICT'; end if;
  return prior.result||jsonb_build_object('idempotent_replay',true);
 end if;
 if private.appointment_semantic_revision(p_business_id,a.id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 if a.status<>'cancelled' then raise exception 'DEPOSIT_LATE_REQUIRES_CANCELLED'; end if;
 if p_action='record' then
  select * into r from public.appointment_deposit_requirements
   where business_id=p_business_id and appointment_id=a.id and patient_id=a.patient_id and is_current for update;
  if not found then raise exception 'DEPOSIT_NOT_FOUND'; end if;
 else
  select * into original from public.appointment_deposit_events
   where business_id=p_business_id and appointment_id=a.id and id=p_corrects_event_id and event_type='late_payment_recorded';
  if not found then raise exception 'DEPOSIT_LATE_RECORD_NOT_FOUND'; end if;
  select * into r from public.appointment_deposit_requirements
   where business_id=p_business_id and appointment_id=a.id and patient_id=a.patient_id and id=original.requirement_id for update;
  if not found then raise exception 'DEPOSIT_LATE_RECORD_NOT_FOUND'; end if;
  if exists(select 1 from public.appointment_deposit_events where corrects_event_id=original.id) then
   raise exception 'DEPOSIT_LATE_ALREADY_CORRECTED'; end if;
  v_amount:=original.amount;
 end if;
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 v_now:=clock_timestamp();
 insert into public.appointment_deposit_events(business_id,appointment_id,requirement_id,event_type,amount,actor_id,metadata,created_at,corrects_event_id)
 values(p_business_id,a.id,r.id,case when p_action='record' then 'late_payment_recorded' else 'recording_reversed' end,
  v_amount,v_actor,jsonb_build_object('origin','staff_late_deposit','operation_id',p_operation_id,'note',v_note),v_now,p_corrects_event_id)
 returning id into v_event;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,v_actor,case when p_action='record' then 'appointment.late_deposit_recorded' else 'appointment.late_deposit_corrected' end,
  'appointment',a.id,jsonb_build_object('operation_id',p_operation_id,'event_id',v_event,'amount',v_amount,'corrects_event_id',p_corrects_event_id));
 v_result:=jsonb_build_object('event_id',v_event,'amount',v_amount::text,'corrects_event_id',p_corrects_event_id,
  'unresolved_amount',private.appointment_deposit_summary(p_business_id,a.id,a.patient_id)->>'unresolved_amount',
  'revision',private.appointment_semantic_revision(p_business_id,a.id),'idempotent_replay',false);
 insert into private.appointment_management_operations(business_id,operation_id,appointment_id,actor_id,origin,action,request_fingerprint,result)
 values(p_business_id,p_operation_id,a.id,v_actor,'staff',v_action,v_fingerprint,v_result);
 -- Includes waits caused by event/audit/receipt triggers. A natural expiry must
 -- roll back every local effect, even though no appointment column was changed.
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'DEPOSIT_FORBIDDEN'; end if;
 return v_result;
end $$;

-- The public snapshot replacement below changes only its financial-summary
-- calculation, retaining the current distinct information/reminder scopes.

CREATE OR REPLACE FUNCTION private.appointment_management_snapshot(p_business_id uuid, p_appointment_id uuid, p_starts_at timestamp with time zone, p_now timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare a public.appointments; b public.businesses; m public.appointment_management_states; d public.appointment_deposits;
 dp public.deposit_policies; c public.appointment_booking_contexts; i public.booking_integrations;
 v_scope jsonb; v_terms jsonb; v_deposit jsonb; v_financial_summary jsonb; v_patient_name text; v_integration jsonb;
 v_patient_active boolean; v_auxiliary boolean;
 v_active_future boolean; v_operable boolean; v_booking boolean; v_cancel boolean; v_reschedule boolean; v_confirm boolean; v_auto_cancel boolean;
begin
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id;
 if not found then return null; end if;
 select * into b from public.businesses where id=p_business_id;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=p_appointment_id;
 select * into d from public.appointment_deposits where business_id=p_business_id and appointment_id=p_appointment_id;
 select * into dp from public.deposit_policies where business_id=p_business_id;
 select * into c from public.appointment_booking_contexts where business_id=p_business_id and appointment_id=p_appointment_id;
 select full_name,archived_at is null into v_patient_name,v_patient_active from public.patients where business_id=p_business_id and id=a.patient_id;
 v_active_future:=a.status in ('reserved','confirmed','reschedule_requested') and a.starts_at>p_now;
 v_operable:=b.is_active and coalesce(private.appointment_business_allows_operation_at(b.id,p_now),false);
 v_booking:=v_operable and b.public_booking_enabled;
 v_auxiliary:=v_active_future and v_operable and coalesce(v_patient_active,false);
 v_scope:=private.appointment_reschedule_scope(p_business_id,p_appointment_id,p_now);
 if v_active_future then v_terms:=private.appointment_reschedule_financial_terms(p_business_id,p_appointment_id,coalesce(p_starts_at,a.starts_at),p_now); end if;
 v_cancel:=v_active_future;
 v_reschedule:=v_active_future and coalesce((v_scope->>'can_select')::boolean,false) and v_terms->>'unavailable_reason' is null;
 v_confirm:=v_active_future and a.status='reserved' and v_operable and coalesce(d.status not in ('pending','expired'),true);
 v_auto_cancel:=d.status='pending' and a.status='reserved' and a.starts_at>p_now and d.auto_cancel and dp.enabled and dp.auto_cancel_enabled
  and v_operable and p_now<d.due_at+interval '24 hours' and coalesce((select enabled from private.deposit_automation where singleton),false);
 if d.appointment_id is not null then
  v_deposit:=jsonb_build_object('appointment_id',d.appointment_id,'status',d.status,'amount',d.amount,'currency',d.currency,
   'request_from',d.request_from,'due_at',d.due_at,'auto_cancel',coalesce(v_auto_cancel,false),'waived_reason',d.waived_reason,
   'recorded_at',d.recorded_at,'reminder_opened_at',d.reminder_opened_at,'expired_at',d.expired_at,'revision',d.revision);
 end if;
 v_financial_summary:=private.appointment_deposit_summary(p_business_id,p_appointment_id,a.patient_id);
 if c.appointment_id is not null then
  select * into i from public.booking_integrations where business_id=p_business_id and id=c.integration_id;
  v_integration:=jsonb_build_object('id',c.integration_id,'revision',i.revision,'is_active',i.is_active,'public_key',i.public_key,
   'theme_snapshot',c.theme_snapshot,'entry_point',c.entry_point,'modality',c.modality,
   'video_instructions_snapshot',c.video_instructions_snapshot,'modality_windows',i.modality_windows);
 end if;
 return jsonb_build_object('schema_version',1,'id',a.id,'status',a.status,'starts_at',a.starts_at,'ends_at',a.ends_at,'now',p_now,
  'schedule_revision',m.schedule_revision,'calendar_token',a.confirmation_token,'patient_name',v_patient_name,
  'service_name_snapshot',a.service_name_snapshot,'professional_name_snapshot',a.professional_name_snapshot,
  'service_id',a.service_id,'professional_ids',v_scope->'professional_ids','reschedule_duration_minutes',v_scope->'duration_minutes',
  'modality',coalesce(c.modality,'in_person'),'integration',v_integration,
  'patient_instructions_snapshot',a.patient_instructions_snapshot,'public_reminder_description_snapshot',a.public_reminder_description_snapshot,
  'price_quote_snapshot',a.price_quote_snapshot,'calendar_action_status',a.calendar_action_status,'calendar_action_at',a.calendar_action_at,
  'calendar_action_count',a.calendar_action_count,'calendar_sequence',a.calendar_sequence,'calendar_update_required_at',a.calendar_update_required_at,
  'deposit',v_deposit,'deposit_transfer_details',case when v_active_future and d.status='pending' then dp.transfer_details end,
  'financial_terms',v_terms,'financial_summary',v_financial_summary,
  'reschedule_unavailable_reason',coalesce(v_scope->>'reason',v_terms->>'unavailable_reason'),
  'can_add_information',v_auxiliary and exists(select 1 from public.appointment_patient_information_contexts ic
   where (ic.business_id,ic.appointment_id,ic.patient_id_snapshot)=(a.business_id,a.id,a.patient_id)),
  'can_manage_reminders',v_auxiliary,
  'can_cancel',v_cancel,'can_reschedule',v_reschedule,'can_confirm',v_confirm,'is_past',a.starts_at<=p_now,
  'new_booking_allowed',a.status='cancelled' and a.starts_at>p_now and v_booking,
  'business',jsonb_build_object('id',b.id,'name',b.name,'slug',b.slug,'timezone',b.timezone,'phone',b.phone,
   'address',case when c.modality is distinct from 'video' then b.address end,
   'address_instructions',case when c.modality='video' then c.video_instructions_snapshot else b.address_instructions end,
   'maps_url',case when c.modality is distinct from 'video' then b.maps_url end,'logo_url',b.logo_url,'is_active',b.is_active,
   'public_booking_enabled',b.public_booking_enabled,'cancellation_policy',b.cancellation_policy,
   'whatsapp_contact_phone',case when b.whatsapp_contact_enabled then b.whatsapp_phone end));
end $function$
;

revoke all on function private.appointment_late_deposit_balance(uuid,uuid,uuid),
 private.appointment_deposit_summary(uuid,uuid,uuid),private.guard_late_deposit_identity(),
 public.appointment_deposit_financials(public.appointments),
 public.record_late_appointment_deposit(uuid,uuid,uuid,text,text,text,uuid,text)
 from public,anon,authenticated,service_role;
grant execute on function public.appointment_deposit_financials(public.appointments),
 public.record_late_appointment_deposit(uuid,uuid,uuid,text,text,text,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
