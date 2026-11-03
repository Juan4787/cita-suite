-- Check an actual old-schema -> new-schema migration, then remove only this
-- fixture's namespace. Merely seeding after the migration cannot prove backfill.
begin;
select extensions.plan(8);
select extensions.is((select jsonb_agg(jsonb_build_object('appointment',to_jsonb(a),'deposit',to_jsonb(d)) order by a.id)
 from public.appointments a join public.appointment_deposits d on d.appointment_id=a.id
 where a.business_id=(select business_id from private.e1_upgrade_fixture)),
 (select before_state from private.e1_upgrade_fixture),'E1 upgrade leaves old appointments/deposit projections byte-for-value unchanged');
select extensions.is((select count(*) from public.appointment_deposit_requirements where business_id=(select business_id from private.e1_upgrade_fixture)),
 5::bigint,'E1 upgrade creates exactly one observed requirement per existing projection');
select extensions.is((select string_agg(labels.key||':'||r.status||':'||r.allocation,',' order by labels.key)
 from private.e1_upgrade_fixture f cross join lateral jsonb_each_text(f.appointment_ids) labels
 join public.appointment_deposit_requirements r on r.business_id=f.business_id and r.appointment_id=labels.value::uuid),
 'expired:expired:none,paid:paid:applied,paid_cancelled:paid:unresolved,pending:pending:none,waived:waived:none',
 'E1 upgrade preserves paid/waived/expired meaning; cancelled money remains unresolved');
select extensions.is((select count(*) from public.appointment_deposit_events where business_id=(select business_id from private.e1_upgrade_fixture)
 and event_type='existing_state_observed'),5::bigint,'E1 upgrade records only observed state, without manufacturing historical payment events');
select extensions.is((select count(*) from public.appointment_deposit_events where business_id=(select business_id from private.e1_upgrade_fixture)
 and (event_type<>'existing_state_observed' or (amount>0 and metadata->>'status'<>'paid'))),0::bigint,'E1 upgrade never invents payments or treats waived obligations as money');
select extensions.is((select count(*) from public.appointment_management_states where business_id=(select business_id from private.e1_upgrade_fixture)
 and not terms_acknowledged and not require_deposit_on_reschedule and previous_deposit_disposition='credit'),5::bigint,'E1 upgrade imposes no retroactive financial terms');
select extensions.is((select count(*) from public.appointment_deposit_requirements r join private.e1_upgrade_fixture f
 on r.business_id=f.business_id and r.appointment_id=(f.appointment_ids->>'paid_cancelled')::uuid
 where r.status='paid' and r.recorded_at is null),1::bigint,'One actual old payment with unknown time stays unknown; an absent row cannot pass');
select extensions.is((select sum(amount) from public.appointment_deposit_requirements where business_id=(select business_id from private.e1_upgrade_fixture)
 and status='paid' and allocation='applied'),40000::numeric,'Applicable observed money is counted once, without cancelled payments');
select * from extensions.finish();
rollback;
begin;
-- The existing appointments -> patients FK is RESTRICT. Remove this owned
-- fixture's appointments before its practice/patients, as older upgrade fixtures
-- do; never weaken a money/history FK just to make test cleanup succeed.
delete from public.appointments where business_id=(select business_id from private.e1_upgrade_fixture);
delete from public.businesses where id=(select business_id from private.e1_upgrade_fixture);
delete from auth.users where id=(select owner_id from private.e1_upgrade_fixture);
drop table private.e1_upgrade_fixture;
commit;
