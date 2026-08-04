-- LCD-20260804-01 / Issue #52.
-- DEV carecía de cuatro helpers ya vigentes en PROD y requeridos por save_gestion_v2.
-- Se restauran sin modificar hechos ni datos operativos.

create or replace function public.crm_rut_number(p_rut_norm text)
returns bigint
language sql
immutable
set search_path = public, pg_temp
as $$
  select nullif(regexp_replace(coalesce(p_rut_norm, ''), '[^0-9]', '', 'g'), '')::bigint / 10
$$;

create or replace function public.crm_rut_range(p_rut_norm text)
returns text
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  n bigint := public.crm_rut_number(p_rut_norm);
begin
  if n is null then return 'Sin RUT'; end if;
  if n < 5000000 then return '<5M'; end if;
  if n < 8000000 then return '5M–8M'; end if;
  if n < 10000000 then return '8M–10M'; end if;
  if n < 12000000 then return '10M–12M'; end if;
  if n < 14000000 then return '12M–14M'; end if;
  if n < 16000000 then return '14M–16M'; end if;
  if n < 18000000 then return '16M–18M'; end if;
  if n < 20000000 then return '18M–20M'; end if;
  return '20M+';
end
$$;

create or replace function public.crm_hour_block(p_hour integer)
returns text
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
    when p_hour between 8 and 9 then '08:00–10:00'
    when p_hour between 10 and 11 then '10:00–12:00'
    when p_hour between 12 and 13 then '12:00–14:00'
    when p_hour between 14 and 15 then '14:00–16:00'
    when p_hour between 16 and 17 then '16:00–18:00'
    when p_hour between 18 and 19 then '18:00–20:00'
    when p_hour < 8 then 'Antes de 08:00'
    else 'Después de 20:00'
  end
$$;

create or replace function public.crm_is_agenda(p_estado text)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select lower(coalesce(p_estado, '')) in ('agenda', 'agendado', 'agendada')
$$;

notify pgrst, 'reload schema';
