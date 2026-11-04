-- Patient row writers must never wait for a public contact-resolution advisory
-- lock. Advancing a row lock into the public core would invert the existing
-- professional/appointment -> patient order of other writers instead.
begin;
create or replace function private.serialize_patient_contact_changes()
returns trigger language plpgsql security definer set search_path=public,pg_catalog as $$
declare v_old_lock_key text; v_new_lock_key text; v_lock_key text;
begin
 if tg_op='UPDATE' and
  (new.business_id,public.normalized_patient_name(new.full_name),new.phone_e164,new.archived_at,new.blocked)
   is not distinct from
  (old.business_id,public.normalized_patient_name(old.full_name),old.phone_e164,old.archived_at,old.blocked) then
  -- Email, clinical/profile data and activity do not change name/phone matching
  -- or booking eligibility. Email authority has its own monotonic epoch.
  return new;
 end if;
 if new.business_id is not null and new.phone_e164 is not null and public.normalized_patient_name(new.full_name) is not null then
  v_new_lock_key:='patient-contact-resolution:'||new.business_id::text||':'||private.public_booking_contact_bucket(new.full_name,new.phone_e164);
 end if;
 if tg_op='INSERT' then
  -- This new row is not visible to a competing resolution; preserve insert
  -- serialization without forcing a transient conflict for normal new patients.
  if v_new_lock_key is not null then perform pg_advisory_xact_lock(hashtextextended(v_new_lock_key,0)); end if;
  return new;
 end if;
 if old.business_id is not null and old.phone_e164 is not null and public.normalized_patient_name(old.full_name) is not null then
  v_old_lock_key:='patient-contact-resolution:'||old.business_id::text||':'||private.public_booking_contact_bucket(old.full_name,old.phone_e164);
 end if;
 -- UPDATE has already acquired its row lock. A non-blocking acquisition is
 -- required even in sorted key order: a public resolution may own either key
 -- and need that row via its FK/activity write. Failure rolls back the complete
 -- authorized operation; the existing editor conflict keeps its draft.
 for v_lock_key in select distinct value from unnest(array[v_old_lock_key,v_new_lock_key]) as keys(value)
  where value is not null order by value loop
  if not pg_try_advisory_xact_lock(hashtextextended(v_lock_key,0)) then raise exception 'PATIENT_UPDATE_CONFLICT'; end if;
 end loop;
 return new;
end $$;
create or replace trigger patients_serialize_contact_changes
 before insert or update of business_id,full_name,phone_e164,archived_at,blocked on public.patients
 for each row execute function private.serialize_patient_contact_changes();
-- Existing function identity, trigger timing, grants and all writer RPCs remain.
commit;
