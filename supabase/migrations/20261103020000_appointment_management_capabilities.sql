-- E1: revocable capabilities and durable idempotency receipts. No public route
-- uses these yet. Preserve the existing 64-hex calendar/confirmation token.
begin;

create table private.appointment_management_capabilities (
 token_hash text primary key check (token_hash ~ '^[0-9a-f]{64}$'),
 business_id uuid not null,
 appointment_id uuid not null,
 generation bigint not null check (generation>0),
 expires_at timestamptz not null,
 created_at timestamptz not null default now(),
 foreign key (business_id,appointment_id) references public.appointments(business_id,id) on delete cascade
);
create index appointment_management_capabilities_appointment on private.appointment_management_capabilities(business_id,appointment_id,generation);
create index appointment_management_capabilities_expiry on private.appointment_management_capabilities(expires_at);

-- A receipt is not authority: every command checks the current actor/capability
-- again before replay. A reused operation with different input is a conflict.
create table private.appointment_management_operations (
 business_id uuid not null,
 operation_id uuid not null,
 appointment_id uuid not null,
 actor_id uuid,
 origin text not null check (origin in ('staff','patient')),
 action text not null check (char_length(action) between 1 and 80),
 request_fingerprint text not null check (request_fingerprint ~ '^[0-9a-f]{64}$'),
 result jsonb not null check (jsonb_typeof(result)='object'),
 created_at timestamptz not null default now(),
 primary key (business_id,operation_id),
 foreign key (business_id,appointment_id) references public.appointments(business_id,id) on delete cascade
);
create index appointment_management_operations_appointment on private.appointment_management_operations(business_id,appointment_id,created_at);
revoke all on private.appointment_management_capabilities,private.appointment_management_operations from public,anon,authenticated,service_role;

-- Issuance is backend-only. A route must never expose it merely for knowing a
-- calendar token: first resolve still-authorized access or a committed outbox job.
-- Parent first, just like money and revocation. A concurrent revoke wins before
-- issuance or waits; a stale generation never mints fresh access after revocation.
create function public.issue_appointment_management_capability(p_business_id uuid,p_appointment_id uuid,p_expected_generation bigint)
returns text language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; m public.appointment_management_states; v_token text; v_now timestamptz;
begin
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 select * into m from public.appointment_management_states where business_id=p_business_id and appointment_id=p_appointment_id;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 if p_expected_generation is distinct from m.generation then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 v_now:=clock_timestamp();
 v_token:=encode(extensions.gen_random_bytes(32),'hex');
 insert into private.appointment_management_capabilities(token_hash,business_id,appointment_id,generation,created_at,expires_at)
 values(encode(extensions.digest(v_token,'sha256'),'hex'),p_business_id,p_appointment_id,m.generation,v_now,
  least(v_now+interval '365 days',greatest(v_now+interval '1 day',a.starts_at+interval '30 days')));
 return v_token;
end $$;

-- One statement/snapshot for the capability, generation and semantic revision.
-- No appointment mutation and no new credential is obtained by reading a link.
-- Command implementations must revalidate after locking the appointment, rather
-- than treating this read as a lasting authorization. Calendar endpoints retain
-- their own limited read contract; this is specifically management access.
create function public.resolve_appointment_management_access(p_token text,p_legacy boolean default false)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_result jsonb;
begin
 if p_legacy is null or not coalesce(p_token ~ '^[0-9a-f]{64}$',false) then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 with authorized as (
  select ap.business_id,ap.id as appointment_id,null::bigint as generation from public.appointments ap
  where p_legacy and ap.confirmation_token=p_token
  union all
  select c.business_id,c.appointment_id,c.generation from private.appointment_management_capabilities c
  where not p_legacy and c.token_hash=encode(extensions.digest(p_token,'sha256'),'hex') and c.expires_at>clock_timestamp()
 )
 select jsonb_build_object('business_id',a.business_id,'appointment_id',a.id,'generation',m.generation,
  'revision',private.appointment_semantic_revision(a.business_id,a.id),'access_kind',case when p_legacy then 'legacy' else 'capability' end)
 into v_result
 from authorized access join public.appointments a on (a.business_id,a.id)=(access.business_id,access.appointment_id)
 join public.appointment_management_states m on (m.business_id,m.appointment_id)=(a.business_id,a.id)
 where (p_legacy and m.legacy_management_allowed) or (not p_legacy and access.generation=m.generation);
 if v_result is null then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 return v_result;
end $$;

-- An authorized staff member can revoke management without rotating calendar
-- identity or changing the appointment/payment. Replay still checks membership.
create function public.revoke_appointment_management_access(p_business_id uuid,p_appointment_id uuid,p_operation_id uuid,p_expected_revision text)
returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.appointments; m public.appointment_management_states; prior private.appointment_management_operations;
 v_fingerprint text; v_result jsonb;
begin
 if private.deposit_actor(p_business_id,array['owner','admin','reception']) is null then raise exception 'APPOINTMENT_MANAGEMENT_FORBIDDEN'; end if;
 if p_operation_id is null or not coalesce(p_expected_revision ~ '^[0-9a-f]{64}$',false) then raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 -- Serialize a reused identity even if the second caller names another turn.
 -- Every future management command shares this namespace and lock order.
 perform pg_advisory_xact_lock(hashtextextended('appointment-management-operation:'||p_business_id::text||':'||p_operation_id::text,0));
 select * into a from public.appointments where business_id=p_business_id and id=p_appointment_id for no key update;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 v_fingerprint:=encode(extensions.digest(jsonb_build_object('action','revoke','appointment_id',p_appointment_id,
  'expected_revision',p_expected_revision,'actor_id',auth.uid())::text,'sha256'),'hex');
 select * into prior from private.appointment_management_operations where business_id=p_business_id and operation_id=p_operation_id;
 if found then
  if prior.appointment_id is distinct from p_appointment_id or prior.request_fingerprint is distinct from v_fingerprint
   or prior.actor_id is distinct from auth.uid() or prior.origin<>'staff' or prior.action<>'revoke' then
   raise exception 'APPOINTMENT_OPERATION_CONFLICT'; end if;
  return prior.result||jsonb_build_object('idempotent_replay',true);
 end if;
 if private.appointment_semantic_revision(p_business_id,p_appointment_id) is distinct from p_expected_revision then
  raise exception 'APPOINTMENT_MANAGEMENT_CHANGED'; end if;
 update public.appointment_management_states set generation=generation+1,legacy_management_allowed=false
 where business_id=p_business_id and appointment_id=p_appointment_id returning * into m;
 if not found then raise exception 'APPOINTMENT_LINK_UNAVAILABLE'; end if;
 insert into public.audit_logs(business_id,user_id,action,entity_type,entity_id,metadata)
 values(p_business_id,auth.uid(),'appointment.management_access_revoked','appointment',p_appointment_id,
  jsonb_build_object('generation',m.generation,'origin','staff'));
 v_result:=jsonb_build_object('appointment_id',a.id,'generation',m.generation,
  'revision',private.appointment_semantic_revision(p_business_id,p_appointment_id),'idempotent_replay',false);
 insert into private.appointment_management_operations(business_id,operation_id,appointment_id,actor_id,origin,action,request_fingerprint,result)
 values(p_business_id,p_operation_id,p_appointment_id,auth.uid(),'staff','revoke',v_fingerprint,v_result);
 return v_result;
end $$;

revoke all on function public.issue_appointment_management_capability(uuid,uuid,bigint),
 public.resolve_appointment_management_access(text,boolean),public.revoke_appointment_management_access(uuid,uuid,uuid,text)
 from public,anon,authenticated,service_role;
grant execute on function public.issue_appointment_management_capability(uuid,uuid,bigint),
 public.resolve_appointment_management_access(text,boolean) to service_role;
grant execute on function public.revoke_appointment_management_access(uuid,uuid,uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
