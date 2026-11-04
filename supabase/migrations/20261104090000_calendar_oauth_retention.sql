-- OAuth begin no longer performs an unbounded client-clock HTTP deletion.
-- Expired attempts cannot finalize a grant; no connection or event is deleted.
begin;
create function private.prune_calendar_oauth_attempts(p_limit integer default 500)
returns integer language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare v_now timestamptz:=clock_timestamp(); v_count integer;
begin
 if p_limit is null or p_limit not between 1 and 5000 then raise exception 'CALENDAR_OAUTH_RETENTION_LIMIT_INVALID'; end if;
 with due as materialized (
  select id from public.google_calendar_oauth_attempts where expires_at<v_now
  order by expires_at,id limit p_limit for update skip locked
 ) delete from public.google_calendar_oauth_attempts a using due where a.id=due.id;
 get diagnostics v_count=row_count;
 return v_count;
end $$;
revoke all on function private.prune_calendar_oauth_attempts(integer) from public,anon,authenticated,service_role;
do $$ declare v_job_id bigint; begin
 if to_regnamespace('cron') is null then raise exception 'CALENDAR_OAUTH_RETENTION_CRON_UNAVAILABLE'; end if;
 for v_job_id in select jobid from cron.job where jobname='cita-suite-calendar-oauth-retention' loop
  perform cron.unschedule(v_job_id);
 end loop;
 perform cron.schedule('cita-suite-calendar-oauth-retention','47 * * * *','select private.prune_calendar_oauth_attempts()');
end $$;
commit;
