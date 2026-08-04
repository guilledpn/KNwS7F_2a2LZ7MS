-- LCD-20260804-01 / Issue #52.
-- DEV no contenía este helper aunque save_gestion_v2 dependía de él.
-- Se restaura de forma idempotente y con permisos explícitos antes de promover.

create or replace function public.crm_current_sprint_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select sprint_id
  from public.crm_sprints
  where status = 'running'
    and local_date = (now() at time zone 'America/Santiago')::date
  order by started_at desc
  limit 1
$$;

revoke all on function public.crm_current_sprint_id() from public, anon;
grant execute on function public.crm_current_sprint_id() to authenticated;

comment on function public.crm_current_sprint_id() is
  'LCD-20260804-01. Helper autenticado requerido por save_gestion_v2 para asociar una gestión al sprint activo del día.';

notify pgrst, 'reload schema';
