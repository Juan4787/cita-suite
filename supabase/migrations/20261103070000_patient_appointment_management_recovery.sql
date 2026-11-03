-- An authorized committed receipt can be recovered before re-running mutable
-- availability preflight. This function never executes an absent operation.
begin;
create function public.recover_patient_appointment_management(p_token text,p_legacy boolean,p_operation_id uuid,
 p_expected_revision text,p_action text,p_starts_at timestamptz default null,p_availability_revision bigint default null,
 p_financial_terms jsonb default null,p_integration_revision bigint default null) returns jsonb
language plpgsql volatile security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=clock_timestamp(); v_access jsonb; v_receipt jsonb; v_fingerprint text;
begin
 if p_legacy is null or p_operation_id is null or not coalesce(p_token ~ '^[0-9a-f]{64}$',false)
  or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false)
  or not coalesce(p_action in ('cancel','confirm','reschedule'),false) then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 if p_financial_terms is not null and (jsonb_typeof(p_financial_terms)<>'object' or octet_length(p_financial_terms::text)>8192) then
  raise exception 'APPOINTMENT_FINANCIAL_TERMS_CHANGED'; end if;
 -- Authorization, patient identity and receipt share one statement snapshot.
 -- No row locks: this read cannot create money, agenda or operation effects.
 with access as materialized (select private.appointment_management_access_at(p_token,p_legacy,v_now) as context)
 select context,to_jsonb(o),private.patient_management_request_fingerprint(p_action,a.id,a.patient_id,(context->>'generation')::bigint,
  p_expected_revision,p_starts_at,p_availability_revision,p_financial_terms,p_integration_revision)
 into v_access,v_receipt,v_fingerprint
 from access join public.appointments a on (a.business_id,a.id)=((context->>'business_id')::uuid,(context->>'appointment_id')::uuid)
 left join private.appointment_management_operations o on o.business_id=a.business_id and o.operation_id=p_operation_id
 where context is not null;
 if v_access is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 if v_receipt is null then return null; end if;
 if v_receipt->>'appointment_id' is distinct from v_access->>'appointment_id' or v_receipt->>'origin'<>'patient'
  or v_receipt->>'action' is distinct from p_action or v_receipt->>'request_fingerprint' is distinct from v_fingerprint then
  raise exception 'APPOINTMENT_OPERATION_CONFLICT'; end if;
 return v_receipt->'result'||jsonb_build_object('idempotent_replay',true);
end $$;
revoke all on function public.recover_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint)
 from public,anon,authenticated,service_role;
grant execute on function public.recover_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb,bigint) to service_role;
notify pgrst,'reload schema';
commit;
