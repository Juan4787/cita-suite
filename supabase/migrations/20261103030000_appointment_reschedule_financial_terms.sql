-- E1: readonly financial terms. Actual moves must re-evaluate under the policy /
-- appointment locks and commit the matching history/events atomically (next step).
begin;

-- An unknown quote is not zero. Validate the accepted snapshot's relevant
-- contract without recalculating today's price or requiring its old policy to
-- still exist. SQL never casts an unbounded decimal directly to bigint.
create function private.appointment_quote_amount(p_quote jsonb) returns bigint
language plpgsql immutable set search_path=pg_catalog,pg_temp as $$
declare v_amount numeric; v_base numeric; v_revision numeric; v_current numeric;
begin
 if jsonb_typeof(p_quote) is distinct from 'object'
  or jsonb_typeof(p_quote->'amount') is distinct from 'number'
  or jsonb_typeof(p_quote->'base_amount') is distinct from 'number'
  or jsonb_typeof(p_quote->'revision') is distinct from 'number'
  or jsonb_typeof(p_quote->'adjusted') is distinct from 'boolean'
  or coalesce(p_quote->>'currency','')<>'ARS'
  or not coalesce(p_quote->>'hash' ~* '^[0-9a-f]{64}$',false)
  or not coalesce(p_quote->>'policy_id' ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',false)
  or not coalesce(p_quote->>'date' ~ '^\d{4}-\d{2}-\d{2}$',false)
  or not coalesce(p_quote->>'month' ~ '^\d{4}-\d{2}-\d{2}$',false) then return null; end if;
 v_amount:=(p_quote->>'amount')::numeric; v_base:=(p_quote->>'base_amount')::numeric; v_revision:=(p_quote->>'revision')::numeric;
 if v_amount not between 0 and 1000000000000 or v_amount<>trunc(v_amount)
  or v_base not between 0 and 1000000000000 or v_base<>trunc(v_base)
  or v_revision not between 1 and 9007199254740991 or v_revision<>trunc(v_revision) then return null; end if;
 if p_quote ? 'current_amount' then
  if jsonb_typeof(p_quote->'current_amount') is distinct from 'number' then return null; end if;
  v_current:=(p_quote->>'current_amount')::numeric;
  if v_current not between 0 and 1000000000000 or v_current<>trunc(v_current) then return null; end if;
 end if;
 return v_amount::bigint;
end $$;

create function private.appointment_reschedule_financial_terms(p_business_id uuid,p_appointment_id uuid,
 p_starts_at timestamptz,p_from timestamptz) returns jsonb
language plpgsql stable security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; m public.appointment_management_states; d public.appointment_deposits;
 r public.appointment_deposit_requirements; basis public.appointment_deposit_requirements;
 dp public.deposit_policies; preferences public.appointment_email_policies;
 v_kind text:='none'; v_reason text; v_amount bigint; v_base bigint; v_quote bigint;
 v_credit numeric:=0; v_forfeit bigint:=0; v_previous bigint:=0; v_disposition text:='none';
 v_enabled boolean; v_has_current boolean; v_has_projection boolean; v_has_basis boolean;
 v_request_days integer; v_deadline_hours integer; v_min_payment_hours integer; v_timezone text;
 v_request_from timestamptz; v_due_at timestamptz; v_auto_cancel boolean:=false; v_last_minute boolean:=false; schedule record;
begin
 if p_starts_at is null or p_from is null or not isfinite(p_starts_at) or not isfinite(p_from) or p_starts_at<=p_from then
  raise exception 'APPOINTMENT_RESCHEDULE_TIME_INVALID'; end if;
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 if a.status not in ('reserved','confirmed','reschedule_requested') or a.starts_at<=p_from then
  raise exception 'APPOINTMENT_CANNOT_RESCHEDULE'; end if;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=p_appointment_id;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 select * into preferences from public.appointment_email_policies where business_id=p_business_id;
 if not found then raise exception 'APPOINTMENT_FINANCIAL_STATE_INVALID'; end if;
 select * into d from public.appointment_deposits where business_id=p_business_id and appointment_id=p_appointment_id;
 v_has_projection:=found;
 select * into r from public.appointment_deposit_requirements
 where business_id=p_business_id and appointment_id=p_appointment_id and is_current;
 v_has_current:=found;
 if v_has_projection is distinct from v_has_current then raise exception 'APPOINTMENT_FINANCIAL_STATE_INVALID'; end if;
 if v_has_current and (r.status,r.amount,r.patient_id) is distinct from (d.status,d.amount,a.patient_id) then
  raise exception 'APPOINTMENT_FINANCIAL_STATE_INVALID'; end if;
 select * into basis from public.appointment_deposit_requirements
 where business_id=p_business_id and appointment_id=p_appointment_id and patient_id=a.patient_id order by ordinal desc limit 1;
 v_has_basis:=found;
 if v_has_current then basis:=r; end if;
 if v_has_basis then v_base:=basis.base_amount; end if;
 select coalesce(sum(amount),0) into v_credit from public.appointment_deposit_requirements
 where business_id=p_business_id and appointment_id=p_appointment_id and patient_id=a.patient_id and status='paid' and allocation='applied';
 select * into dp from public.deposit_policies where business_id=p_business_id;
 select enabled into v_enabled from private.deposit_automation where singleton;
 select timezone into v_timezone from public.businesses where id=p_business_id;
 v_quote:=private.appointment_quote_amount(a.price_quote_snapshot);
 -- The initial page reads the CURRENT interval with this same helper. Expose
 -- readiness even for a no-op, so it can hide an unavailable reschedule action
 -- without inventing a hypothetical target or duplicating the financial policy.
 if v_has_basis then
  if v_enabled is not true then v_reason:='deposit_automation_paused';
  elsif exists(select 1 from public.appointment_deposit_requirements where business_id=p_business_id and appointment_id=p_appointment_id and patient_id=a.patient_id
   and status='paid' and allocation='unresolved') then v_reason:='payment_unresolved';
  elsif v_has_current and d.status='pending' and dp.enabled is not true then v_reason:='policy_change_pending';
  end if;
 end if;

 <<decision>>
 begin
  if p_starts_at=a.starts_at then
   v_kind:='unchanged';
   if v_has_current and d.status='pending' then
    v_amount:=d.amount; v_request_from:=d.request_from; v_due_at:=d.due_at;
    v_auto_cancel:=d.auto_cancel and coalesce(dp.auto_cancel_enabled,false) and coalesce(v_enabled,false);
   end if;
   exit decision;
  end if;
  if not v_has_basis then exit decision; end if;
  -- An operator pause freezes financial changes. It is not a business decision
  -- to waive a new advance or forfeit/credit an existing payment.
  if v_reason is not null then v_kind:='unavailable'; exit decision; end if;
  if v_has_current and d.status='pending' then
   v_kind:='reuse_pending'; v_amount:=d.amount; exit decision;
  end if;
  -- No new penalty is applied to uninformed reservations. Current relaxation
  -- also wins over an older harsher preference; it never makes that photo harsher.
  if v_has_current and r.status='paid' and r.allocation='applied' then
   v_previous:=r.amount;
   v_disposition:=case when m.terms_acknowledged and dp.enabled is true
    and m.previous_deposit_disposition='forfeit' and preferences.previous_deposit_disposition='forfeit' then 'forfeit' else 'credit' end;
   if v_disposition='forfeit' then v_forfeit:=r.amount; v_credit:=v_credit-v_forfeit; end if;
  end if;
  if m.terms_acknowledged and dp.enabled is true then
   if m.require_deposit_on_reschedule and preferences.require_deposit_on_reschedule then
    v_amount:=v_base;
    if v_quote is not null then v_amount:=least(v_base,greatest(v_quote-v_credit,0))::bigint; end if;
    if v_amount>0 then v_kind:='new_requirement'; else v_amount:=null; end if;
   end if;
  end if;
 end decision;

 if v_kind in ('reuse_pending','new_requirement') then
  begin
   v_request_days:=(basis.terms_snapshot->>'request_days')::integer;
   v_deadline_hours:=(basis.terms_snapshot->>'deadline_hours')::integer;
   v_min_payment_hours:=(basis.terms_snapshot->>'min_payment_hours')::integer;
  exception when invalid_text_representation or numeric_value_out_of_range then
   raise exception 'APPOINTMENT_FINANCIAL_STATE_INVALID';
  end;
  if v_request_days is null or v_request_days not between 1 and 60 or v_deadline_hours is null or v_deadline_hours not between 1 and 720
   or v_min_payment_hours is null or v_min_payment_hours not between 0 and 168 then raise exception 'APPOINTMENT_FINANCIAL_STATE_INVALID'; end if;
  select * into schedule from private.deposit_schedule(p_starts_at,p_from,v_timezone,v_request_days,v_deadline_hours,v_min_payment_hours);
  v_request_from:=schedule.request_from; v_due_at:=schedule.due_at;
  v_last_minute:=not schedule.auto_cancel;
  v_auto_cancel:=schedule.auto_cancel and dp.auto_cancel_enabled and (v_kind='new_requirement' or d.auto_cancel);
 end if;

 -- Canonical integer strings retain exact accumulated credits beyond JS's safe
 -- integer range. Consumers format them as BigInt; they never recompute the fee.
 -- UTC text keeps microseconds intact when the browser submits the shown terms.
 return jsonb_build_object('kind',v_kind,'unavailable_reason',v_reason,'required',v_amount is not null,
  'amount',v_amount::text,'base_amount',v_base::text,'currency','ARS','previous_applicable_payment_amount',v_previous::text,
  'previous_payment_disposition',v_disposition,'forfeit_amount',v_forfeit::text,'credit_amount',v_credit::text,
  'quote_amount',v_quote::text,'quote_remainder',case when v_quote is not null then greatest(v_quote-v_credit,0)::text end,
  'request_from',to_char(v_request_from at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
  'due_at',to_char(v_due_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
  'auto_cancel',v_auto_cancel,'last_minute',v_last_minute,'terms_informed',m.terms_acknowledged,
  'current_deposit_status',d.status,'current_deposit_amount',d.amount::text,'current_payment_allocation',r.allocation,
  'request_days',v_request_days,'deadline_hours',v_deadline_hours,'min_payment_hours',v_min_payment_hours);
end $$;

revoke all on function private.appointment_quote_amount(jsonb),private.appointment_reschedule_financial_terms(uuid,uuid,timestamptz,timestamptz)
 from public,anon,authenticated,service_role;
commit;
