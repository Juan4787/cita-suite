-- The staff consumers now use apply_staff_appointment_management. Keeping an
-- authenticated UPDATE grant would bypass its observed revision, receipt and
-- audit. Backend telemetry and existing security-definer RPCs keep their grants.
begin;
revoke update on table public.appointments from public,anon,authenticated;
notify pgrst,'reload schema';
commit;
