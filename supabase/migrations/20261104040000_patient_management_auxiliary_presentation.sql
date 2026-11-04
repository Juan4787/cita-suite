-- Presentation is a projection of distinct existing scopes, not a new grant.
-- Future/active, operable clinic, current non-archived patient. Information also
-- requires its own patient-bound context; reminders do not. Public booking and
-- reschedule runtime are deliberately independent. Writes revalidate separately.
begin;

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
 select jsonb_build_object(
  'applied_amount',coalesce(sum(amount) filter(where allocation='applied'),0)::text,
  'forfeited_amount',coalesce(sum(amount) filter(where allocation='forfeited'),0)::text,
  'unresolved_amount',coalesce(sum(amount) filter(where allocation='unresolved'),0)::text)
 into v_financial_summary from public.appointment_deposit_requirements
 where business_id=p_business_id and appointment_id=p_appointment_id and patient_id=a.patient_id and status='paid';
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

-- Existing private function ABI/ACL/search_path are preserved. No new writer.
commit;
