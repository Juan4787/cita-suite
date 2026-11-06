-- `private.deposit_actor` answers the role, not the person. Both functions stored it in a uuid, so
-- every staff decision on an uncertain message and every save of the reply contact failed with a
-- type error. The bodies are otherwise unchanged; their privileges stay as they were.
begin;

create or replace function public.resolve_appointment_email_delivery(p_business_id uuid,p_delivery_id uuid,p_decision text) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_actor uuid:=auth.uid(); d private.appointment_email_deliveries; v_now timestamptz:=clock_timestamp();
begin
 if v_actor is null or private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if p_decision is null or p_decision not in ('resend','dismiss') then raise exception 'EMAIL_DECISION_INVALID'; end if;
 select * into d from private.appointment_email_deliveries where id=p_delivery_id and business_id=p_business_id for update;
 if not found or d.state<>'uncertain' then raise exception 'EMAIL_DELIVERY_CHANGED'; end if;
 if p_decision='resend' then
  update private.appointment_email_deliveries set state='retry',next_attempt_at=v_now,duplicate_risk_accepted_by=v_actor,expires_at=greatest(expires_at,v_now+interval '1 hour') where id=d.id;
 else
  update private.appointment_email_deliveries set state='discarded',discard_reason='operator_dismissed' where id=d.id;
 end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,v_actor,'appointment.email_uncertain_resolved','appointment',d.appointment_id,jsonb_build_object('purpose',d.purpose,'decision',p_decision));
 return jsonb_build_object('state',case when p_decision='resend' then 'retry' else 'discarded' end);
end $$;

create or replace function public.save_business_email_contact(p_business_id uuid,p_reply_to text) returns jsonb
language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_actor uuid:=auth.uid(); v_email text:=nullif(btrim(p_reply_to),'');
begin
 if v_actor is null or private.deposit_actor(p_business_id,array['owner','admin']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if v_email is not null and (char_length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then raise exception 'EMAIL_CONTACT_INVALID'; end if;
 insert into private.business_email_senders(business_id,reply_to_email) values(p_business_id,v_email)
 on conflict(business_id) do update set reply_to_email=excluded.reply_to_email,updated_at=clock_timestamp();
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,v_actor,'business.email_contact_updated','business',p_business_id,'{}'::jsonb);
 return jsonb_build_object('ready',private.email_sender_ready(p_business_id));
end $$;

notify pgrst,'reload schema';
commit;
