-- E1 foundation: semantic revision, compatibility of the current one-to-one deposit,
-- and durable history. A green here does not certify rescheduling, email or a mailbox.
-- Each read happens after the writing statement; NULL must never pass a check silently.
begin;
select extensions.plan(22);

create temporary table management_fixture(label text primary key, id uuid not null);
grant select on management_fixture to authenticated;
create function pg_temp.mid(p_label text) returns uuid language sql as $$
 select id from management_fixture where label=p_label
$$;
do $$
declare b uuid:=gen_random_uuid(); b2 uuid:=gen_random_uuid(); u uuid:=gen_random_uuid();
 outsider uuid:=gen_random_uuid(); professional uuid:=gen_random_uuid(); service uuid:=gen_random_uuid();
begin
 insert into auth.users(id,email) values(u,'management-'||u||'@example.test'),(outsider,'management-'||outsider||'@example.test');
 insert into public.businesses(id,name,slug,industry,timezone)
 values(b,'Gestión E1',b::text,'other','America/Argentina/Cordoba'),(b2,'Otro E1',b2::text,'other','America/Argentina/Cordoba');
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id in(b,b2);
 insert into public.business_users(business_id,user_id,role,status,accepted_at)
 values(b,u,'owner','active',now()),(b2,outsider,'owner','active',now());
 insert into public.professionals(id,business_id,name) values(professional,b,'Profesional E1');
 insert into public.services(id,business_id,name,duration_minutes) values(service,b,'Consulta E1',60);
 insert into public.professional_services(business_id,professional_id,service_id) values(b,professional,service);
 insert into management_fixture values('business',b),('other_business',b2),('owner',u),('outsider',outsider),
  ('professional',professional),('service',service);
end $$;

create function pg_temp.management_appointment(p_label text,p_day integer) returns uuid language plpgsql as $$
declare patient uuid; appointment uuid; starts timestamptz:=date_trunc('hour',now())+make_interval(days=>p_day);
begin
 insert into public.patients(owner_id,business_id,full_name)
 values(pg_temp.mid('owner'),pg_temp.mid('business'),'Paciente E1 '||p_label) returning id into patient;
 insert into public.appointments(business_id,patient_id,professional_id,service_id,starts_at,ends_at,
  blocking_starts_at,blocking_ends_at,status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(pg_temp.mid('business'),patient,pg_temp.mid('professional'),pg_temp.mid('service'),starts,starts+interval '1 hour',
  starts,starts+interval '1 hour','reserved','manual','Consulta E1','Profesional E1',60) returning id into appointment;
 insert into management_fixture values(p_label,appointment);
 return appointment;
end $$;
create function pg_temp.management_revision(p_label text) returns text language sql as $$
 select private.appointment_semantic_revision(pg_temp.mid('business'),pg_temp.mid(p_label))
$$;
create function pg_temp.management_payment_action(p_label text,p_action text) returns void language plpgsql as $$
declare rev bigint;
begin
 perform set_config('request.jwt.claim.sub',pg_temp.mid('owner')::text,true);
 select revision into rev from public.appointment_deposits where appointment_id=pg_temp.mid(p_label);
 perform public.set_appointment_deposit(pg_temp.mid('business'),pg_temp.mid(p_label),p_action,rev,null);
end $$;

-- New practices prefer email and both pertinent actions, independently of sender readiness.
do $$
declare settings public.appointment_email_policies;
begin
 select * into settings from public.appointment_email_policies where business_id=pg_temp.mid('business');
 if settings.email_enabled is not true or settings.require_email is not true
  or settings.show_cancel is not true or settings.show_reschedule is not true
  or settings.require_deposit_on_reschedule is not true or settings.previous_deposit_disposition is distinct from 'forfeit'
  or settings.sender_verified is not false then raise exception 'E1_DEFAULT_POLICY'; end if;
end $$;
select extensions.pass('1. Preferencias activas por defecto, separadas del emisor todavía no verificado');

select pg_temp.management_appointment('legacy',10);
do $$ begin
 if pg_temp.management_revision('legacy') is null or pg_temp.management_revision('legacy') !~ '^[0-9a-f]{64}$' then
  raise exception 'E1_SEMANTIC_REVISION_MISSING'; end if;
end $$;
select extensions.pass('2. Revisión semántica opaca de un turno existente');

do $$ declare before text:=pg_temp.management_revision('legacy'); begin
 update public.appointments set updated_at=clock_timestamp(),calendar_action_count=calendar_action_count+1
 where id=pg_temp.mid('legacy');
 update public.appointment_email_policies set show_cancel=false,revision=revision+1 where business_id=pg_temp.mid('business');
 if pg_temp.management_revision('legacy') is distinct from before then raise exception 'E1_TELEMETRY_CONFLICT'; end if;
end $$;
select extensions.pass('3. Telemetría no produce un conflicto semántico artificial');

do $$ declare before text:=pg_temp.management_revision('legacy'); middle text; begin
 update public.appointments set starts_at=starts_at+interval '1 hour',ends_at=ends_at+interval '1 hour',
  blocking_starts_at=blocking_starts_at+interval '1 hour',blocking_ends_at=blocking_ends_at+interval '1 hour'
 where id=pg_temp.mid('legacy');
 middle:=pg_temp.management_revision('legacy');
 if middle is not distinct from before then raise exception 'E1_FIRST_MOVE_UNDETECTED'; end if;
 update public.appointments set starts_at=starts_at+interval '1 hour',ends_at=ends_at+interval '1 hour',
  blocking_starts_at=blocking_starts_at+interval '1 hour',blocking_ends_at=blocking_ends_at+interval '1 hour'
 where id=pg_temp.mid('legacy');
 if pg_temp.management_revision('legacy') is not distinct from middle then raise exception 'E1_SECOND_MOVE_UNDETECTED'; end if;
end $$;
select extensions.pass('4. Dos cambios conservando Reservado generan revisiones diferentes');

do $$ declare before text:=pg_temp.management_revision('legacy'); begin
 update public.appointments set status='reschedule_requested',reschedule_requested_at=now() where id=pg_temp.mid('legacy');
 if pg_temp.management_revision('legacy') is not distinct from before then raise exception 'E1_STATUS_UNDETECTED'; end if;
end $$;
select extensions.pass('5. Un cambio de estado cambia la revisión');

do $$ declare state public.appointment_management_states; begin
 select * into state from public.appointment_management_states where appointment_id=pg_temp.mid('legacy');
 if state.terms_acknowledged is not false or state.require_deposit_on_reschedule is not false
  or state.previous_deposit_disposition is distinct from 'credit' then raise exception 'E1_RETROACTIVE_TERMS'; end if;
end $$;
select extensions.pass('6. Sin condiciones informadas no se imponen pérdidas ni cargos retroactivos');

do $$ declare before text:=pg_temp.management_revision('legacy'); begin
 update public.appointment_email_policies set require_deposit_on_reschedule=false,revision=revision+1 where business_id=pg_temp.mid('business');
 if pg_temp.management_revision('legacy') is not distinct from before then raise exception 'E1_POLICY_UNDETECTED'; end if;
end $$;
select extensions.pass('7. El contrato detecta una revisión de las condiciones del consultorio');

update private.deposit_automation set enabled=true;
insert into public.deposit_policies(business_id,enabled,amount_mode,fixed_amount,transfer_details)
values(pg_temp.mid('business'),true,'fixed',40000,'Alias sintético de E1');
select pg_temp.management_appointment('deposit',12);
do $$ declare requirement public.appointment_deposit_requirements; begin
 select * into requirement from public.appointment_deposit_requirements where appointment_id=pg_temp.mid('deposit') and is_current;
 if requirement.amount is distinct from 40000 or requirement.status is distinct from 'pending'
  or requirement.allocation is distinct from 'none' then raise exception 'E1_REQUIREMENT_MISSING'; end if;
end $$;
select extensions.pass('8. La proyección vigente conserva uno a uno y crea su obligación histórica');

select pg_temp.management_payment_action('deposit','paid');
do $$ begin
 if (select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.mid('deposit') and event_type='payment_recorded') is distinct from 1::bigint
  or (select allocation from public.appointment_deposit_requirements where appointment_id=pg_temp.mid('deposit') and is_current) is distinct from 'applied'
  or (select status from public.appointments where id=pg_temp.mid('deposit')) is distinct from 'confirmed' then raise exception 'E1_PAYMENT_HISTORY'; end if;
end $$;
select extensions.pass('9. Registrar el pago confirma y registra historia de dinero, juntos');

select pg_temp.management_payment_action('deposit','paid');
select extensions.is((select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.mid('deposit') and event_type='payment_recorded'),1::bigint,
 '10. Repetir el registro no duplica dinero ni eventos');

select pg_temp.management_payment_action('deposit','pending');
do $$ begin
 if (select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.mid('deposit') and event_type='payment_recorded') is distinct from 1::bigint
  or (select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.mid('deposit') and event_type='recording_reversed') is distinct from 1::bigint
  or (select allocation from public.appointment_deposit_requirements where appointment_id=pg_temp.mid('deposit') and is_current) is distinct from 'none'
  or (select status from public.appointments where id=pg_temp.mid('deposit')) is distinct from 'reserved' then raise exception 'E1_RECORDING_REVERSED'; end if;
end $$;
select extensions.pass('11. Deshacer conserva el hecho previo y agrega corrección, sin simular devolución bancaria');

do $$ declare before text:=pg_temp.management_revision('deposit'); begin
 perform public.open_appointment_deposit_reminder(pg_temp.mid('business'),pg_temp.mid('deposit'),false);
 if pg_temp.management_revision('deposit') is distinct from before then raise exception 'E1_REMINDER_CONFLICT'; end if;
end $$;
select extensions.pass('12. Abrir WhatsApp no cambia la revisión semántica ni el dinero');

select pg_temp.management_appointment('waived',14);
select pg_temp.management_payment_action('waived','waived');
select extensions.is((select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.mid('waived') and event_type='payment_recorded'),0::bigint,
 '13. Una excepción no se importa como dinero recibido');

create function pg_temp.fail_deposit_event() returns trigger language plpgsql as $$ begin
 if new.appointment_id=pg_temp.mid('deposit') and new.event_type='payment_recorded' then raise exception 'E1_PROVOKED_HISTORY_FAILURE'; end if;
 return new;
end $$;
create trigger e1_provoked_history_failure before insert on public.appointment_deposit_events
 for each row execute function pg_temp.fail_deposit_event();
do $$ begin
 begin
  perform pg_temp.management_payment_action('deposit','paid');
  raise exception 'E1_FAILURE_WAS_NOT_PROVOKED';
 exception when others then
  if sqlerrm is distinct from 'E1_PROVOKED_HISTORY_FAILURE' then raise; end if;
 end;
 if (select status from public.appointment_deposits where appointment_id=pg_temp.mid('deposit')) is distinct from 'pending'
  or (select status from public.appointments where id=pg_temp.mid('deposit')) is distinct from 'reserved'
  or (select status from public.appointment_deposit_requirements where appointment_id=pg_temp.mid('deposit') and is_current) is distinct from 'pending'
  or (select count(*) from public.appointment_deposit_events where appointment_id=pg_temp.mid('deposit') and event_type='payment_recorded') is distinct from 1::bigint then
  raise exception 'E1_PARTIAL_PAYMENT_ON_FAILURE'; end if;
end $$;
select extensions.pass('14. Falla al registrar historia revierte pago, estado y obligación');
drop trigger e1_provoked_history_failure on public.appointment_deposit_events;

do $$ declare table_name text; begin
 foreach table_name in array array['appointment_email_policies','appointment_management_states','appointment_deposit_requirements','appointment_deposit_events'] loop
  if has_table_privilege('anon','public.'||table_name,'SELECT') or has_table_privilege('authenticated','public.'||table_name,'INSERT,UPDATE,DELETE') then
   raise exception 'E1_DIRECT_API_WRITE_OR_ANON_READ %',table_name; end if;
 end loop;
 if has_function_privilege('anon','private.appointment_semantic_revision(uuid,uuid)','EXECUTE')
  or has_function_privilege('authenticated','private.appointment_semantic_revision(uuid,uuid)','EXECUTE') then raise exception 'E1_PRIVATE_REVISION_EXPOSED'; end if;
end $$;
select extensions.pass('15. Tablas sin acceso anónimo/escritura directa y función privada sin ejecución pública');

select set_config('request.jwt.claim.sub',pg_temp.mid('outsider')::text,true);
set local role authenticated;
select extensions.is((select count(*) from public.appointment_deposit_requirements where business_id=pg_temp.mid('business')),0::bigint,
 '16. Otro consultorio no puede leer obligaciones ni dinero');
reset role;

-- SET ROLE and JWT identity are separate. Restore the owner after the negative
-- tenant read; keeping the outsider would test the role guard, not an ABA move.
select set_config('request.jwt.claim.sub',pg_temp.mid('owner')::text,true);
do $$ declare before text:=pg_temp.management_revision('legacy'); begin
 update public.appointments set starts_at=starts_at+interval '1 hour',ends_at=ends_at+interval '1 hour',
  blocking_starts_at=blocking_starts_at+interval '1 hour',blocking_ends_at=blocking_ends_at+interval '1 hour' where id=pg_temp.mid('legacy');
 update public.appointments set starts_at=starts_at-interval '1 hour',ends_at=ends_at-interval '1 hour',
  blocking_starts_at=blocking_starts_at-interval '1 hour',blocking_ends_at=blocking_ends_at-interval '1 hour' where id=pg_temp.mid('legacy');
 if pg_temp.management_revision('legacy') is not distinct from before then raise exception 'E1_ABA_UNDETECTED'; end if;
end $$;
select extensions.pass('17. Mover y volver no vuelve válida una pantalla anterior a ambos cambios');

do $$ declare before text:=pg_temp.management_revision('deposit'); begin
 perform set_config('TimeZone','Pacific/Auckland',true);
 if pg_temp.management_revision('deposit') is distinct from before then raise exception 'E1_TIMEZONE_CONFLICT'; end if;
 perform set_config('TimeZone','UTC',true);
end $$;
select extensions.pass('18. La misma revisión no depende de la zona horaria de la sesión SQL');

select extensions.is(private.appointment_semantic_revision(pg_temp.mid('other_business'),pg_temp.mid('deposit')),null::text,
 '19. Consultorio ajeno no obtiene una revisión del turno');

select set_config('request.jwt.claim.sub',pg_temp.mid('owner')::text,true);
select pg_temp.management_payment_action('deposit','paid');
update public.appointments set status='cancelled',cancelled_at=now(),cancelled_reason='Prueba E1'
 where id=pg_temp.mid('deposit');
do $$ begin
 if (select allocation from public.appointment_deposit_requirements where appointment_id=pg_temp.mid('deposit') and is_current) is distinct from 'unresolved'
  or (select status from public.appointment_deposit_requirements where appointment_id=pg_temp.mid('deposit') and is_current) is distinct from 'paid'
  or (select status from public.appointment_deposits where appointment_id=pg_temp.mid('deposit')) is distinct from 'paid' then
  raise exception 'E1_CANCEL_ERASED_OR_FORFEITED_PAYMENT'; end if;
end $$;
select extensions.pass('20. Cancelar conserva el pago, sin devolución ni pérdida automática');

do $$ declare patient uuid; begin
 select patient_id into patient from public.appointments where id=pg_temp.mid('legacy');
 begin
  update public.appointments set patient_id=patient where id=pg_temp.mid('deposit');
  raise exception 'E1_REASSIGNMENT_SHOULD_FAIL';
 exception when others then
  if sqlerrm is distinct from 'APPOINTMENT_DEPOSIT_IDENTITY_CHANGE' then raise; end if;
 end;
end $$;
select extensions.pass('21. Reasignar un turno con dinero no traslada el pago a otra persona');

do $$ begin
 begin
  update public.appointment_deposit_events set amount=0 where appointment_id=pg_temp.mid('deposit');
  raise exception 'E1_EVENT_REWRITE_SHOULD_FAIL';
 exception when others then
  if sqlerrm is distinct from 'APPOINTMENT_DEPOSIT_EVENT_IMMUTABLE' then raise; end if;
 end;
end $$;
select extensions.pass('22. Los eventos económicos no se reescriben para corregir un registro');

select * from extensions.finish();
rollback;
