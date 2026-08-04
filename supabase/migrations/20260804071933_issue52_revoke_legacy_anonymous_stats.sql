-- Issue #52: the integrated cockpit is authenticated-only. Keep retired statistics
-- contracts unavailable to the anonymous role while they remain for rollback.
do $$
begin
  if to_regprocedure('public.get_stats_v1(integer,integer)') is not null then
    execute 'revoke all on function public.get_stats_v1(integer,integer) from public, anon';
    execute 'grant execute on function public.get_stats_v1(integer,integer) to authenticated';
  end if;

  if to_regprocedure('public.get_management_metrics_v1(integer)') is not null then
    execute 'revoke all on function public.get_management_metrics_v1(integer) from public, anon';
    execute 'grant execute on function public.get_management_metrics_v1(integer) to authenticated';
  end if;
end
$$;
