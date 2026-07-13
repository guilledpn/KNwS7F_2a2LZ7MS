-- LCD-20260713-01
-- Promoción a PROD de métricas operativas derivadas por Persona y día.
-- No reemplaza get_stats_v1: preserva el cockpit y agrega un contrato específico.

create or replace function public.crm_management_state_key(p_state text)
returns text
language sql
immutable
set search_path = public, pg_temp
as $$
  select case lower(trim(coalesce(p_state,'')))
    when '' then 'pendiente'
    when 'pendiente' then 'pendiente'
    when 'agenda' then 'agenda'
    when 'no agenda' then 'no_agenda'
    when 'volver a llamar' then 'volver_llamar'
    when 'no contactado' then 'no_contactado'
    when 'contacto inválido' then 'contacto_invalido'
    when 'contacto invalido' then 'contacto_invalido'
    when 'inválido' then 'contacto_invalido'
    when 'invalido' then 'contacto_invalido'
    when 'gestionado' then 'gestionado'
    else regexp_replace(lower(trim(coalesce(p_state,''))), '\s+', '_', 'g')
  end
$$;

revoke all on function public.crm_management_state_key(text) from public, anon, authenticated;

create or replace view public.crm_contact_day_outcomes_v1
with (security_invoker = true)
as
with normalized as (
  select
    l.log_id,
    l.work_item_id,
    l.contact_id,
    l.fecha as local_date,
    l.created_at,
    l.estado_anterior,
    l.estado_nuevo,
    public.crm_management_state_key(l.estado_anterior) as previous_state_key,
    public.crm_management_state_key(l.estado_nuevo) as final_state_key,
    case
      when l.contact_id is not null then 'contact:' || l.contact_id::text
      when l.work_item_id is not null then 'work:' || l.work_item_id::text
      else 'log:' || l.log_id::text
    end as person_key
  from public.crm_log l
), ranked as (
  select
    n.*,
    row_number() over (
      partition by n.local_date, n.person_key
      order by n.created_at desc, n.log_id desc
    ) as outcome_rank
  from normalized n
  where n.final_state_key is distinct from n.previous_state_key
)
select
  log_id,
  work_item_id,
  contact_id,
  local_date,
  extract(hour from created_at at time zone 'America/Santiago')::int as local_hour,
  created_at,
  person_key,
  estado_anterior,
  estado_nuevo,
  previous_state_key,
  final_state_key,
  case final_state_key
    when 'agenda' then 'Agenda'
    when 'no_agenda' then 'No agenda'
    when 'volver_llamar' then 'Volver a llamar'
    when 'no_contactado' then 'No contactado'
    when 'contacto_invalido' then 'Contacto Inválido'
    when 'pendiente' then 'Pendiente'
    when 'gestionado' then 'Gestionado'
    else coalesce(nullif(trim(estado_nuevo),''),'Pendiente')
  end as final_state_label,
  final_state_key in ('agenda','no_agenda') as is_effective_call,
  final_state_key = 'agenda' as is_agenda,
  final_state_key = 'no_agenda' as is_no_agenda
from ranked
where outcome_rank = 1;

revoke all on public.crm_contact_day_outcomes_v1 from public, anon, authenticated;
comment on view public.crm_contact_day_outcomes_v1 is 'LCD-20260713-01. Resultado final derivado por Persona y fecha local desde el último cambio significativo de estado.';

create or replace function public.get_management_metrics_v1(p_days integer default 30)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_today date := (now() at time zone 'America/Santiago')::date;
  v_days int := greatest(coalesce(p_days,30),1);
  v_from date := v_today - (v_days - 1);
  v_month_start date := date_trunc('month', v_today)::date;
  v_today_worked int := 0;
  v_today_effective int := 0;
  v_today_agendas int := 0;
  v_today_no_agenda int := 0;
  v_period_worked int := 0;
  v_period_effective int := 0;
  v_period_agendas int := 0;
  v_period_no_agenda int := 0;
  v_month_agendas int := 0;
  v_today_breakdown jsonb := '{}'::jsonb;
  v_period_breakdown jsonb := '{}'::jsonb;
  v_month_daily jsonb := '[]'::jsonb;
begin
  select
    count(*),
    count(*) filter (where is_effective_call),
    count(*) filter (where is_agenda),
    count(*) filter (where is_no_agenda)
  into v_today_worked, v_today_effective, v_today_agendas, v_today_no_agenda
  from public.crm_contact_day_outcomes_v1
  where local_date = v_today;

  select
    count(*),
    count(*) filter (where is_effective_call),
    count(*) filter (where is_agenda),
    count(*) filter (where is_no_agenda)
  into v_period_worked, v_period_effective, v_period_agendas, v_period_no_agenda
  from public.crm_contact_day_outcomes_v1
  where local_date between v_from and v_today;

  select count(*) filter (where is_agenda)
  into v_month_agendas
  from public.crm_contact_day_outcomes_v1
  where local_date between v_month_start and v_today;

  select coalesce(jsonb_object_agg(x.final_state_label, x.qty), '{}'::jsonb)
  into v_today_breakdown
  from (
    select final_state_label, count(*)::int as qty
    from public.crm_contact_day_outcomes_v1
    where local_date = v_today
    group by final_state_label
    order by final_state_label
  ) x;

  select coalesce(jsonb_object_agg(x.final_state_label, x.qty), '{}'::jsonb)
  into v_period_breakdown
  from (
    select final_state_label, count(*)::int as qty
    from public.crm_contact_day_outcomes_v1
    where local_date between v_from and v_today
    group by final_state_label
    order by final_state_label
  ) x;

  with days as (
    select d::date as day
    from generate_series(v_month_start, v_today, interval '1 day') d
  ), actuals as (
    select local_date, count(*) filter(where is_agenda)::int as daily_agendas
    from public.crm_contact_day_outcomes_v1
    where local_date between v_month_start and v_today
    group by local_date
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'day', days.day::text,
        'daily_agendas', coalesce(actuals.daily_agendas,0)
      ) order by days.day
    ),
    '[]'::jsonb
  )
  into v_month_daily
  from days
  left join actuals on actuals.local_date = days.day;

  return jsonb_build_object(
    'ok', true,
    'generated_at', now(),
    'timezone', 'America/Santiago',
    'metric_contract', 'daily_person_outcome_v1',
    'today', jsonb_build_object(
      'date', v_today,
      'worked_contacts', coalesce(v_today_worked,0),
      'effective_calls', coalesce(v_today_effective,0),
      'agendas', coalesce(v_today_agendas,0),
      'no_agenda', coalesce(v_today_no_agenda,0),
      'effective_conversion_rate', case when v_today_effective > 0 then round(100 * v_today_agendas::numeric / v_today_effective, 1) else null end,
      'worked_per_agenda', case when v_today_agendas > 0 then round(v_today_worked::numeric / v_today_agendas, 2) else null end,
      'result_breakdown', v_today_breakdown
    ),
    'period', jsonb_build_object(
      'days', v_days,
      'worked_contacts', coalesce(v_period_worked,0),
      'effective_calls', coalesce(v_period_effective,0),
      'agendas', coalesce(v_period_agendas,0),
      'no_agenda', coalesce(v_period_no_agenda,0),
      'effective_conversion_rate', case when v_period_effective > 0 then round(100 * v_period_agendas::numeric / v_period_effective, 1) else null end,
      'worked_per_agenda', case when v_period_agendas > 0 then round(v_period_worked::numeric / v_period_agendas, 2) else null end,
      'result_breakdown', v_period_breakdown
    ),
    'month', jsonb_build_object(
      'agendas', coalesce(v_month_agendas,0),
      'daily_series', v_month_daily
    )
  );
end
$$;

revoke all on function public.get_management_metrics_v1(integer) from public, anon;
grant execute on function public.get_management_metrics_v1(integer) to authenticated;
comment on function public.get_management_metrics_v1(integer) is 'LCD-20260713-01. Contrato de métricas operativas derivadas por Persona y fecha local para PROD.';

create or replace function public.get_daily_management_report_v1(p_date date default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_date date := coalesce(p_date, (now() at time zone 'America/Santiago')::date);
  v_worked int := 0;
  v_effective int := 0;
  v_agendas int := 0;
  v_no_agenda int := 0;
  v_breakdown jsonb := '{}'::jsonb;
  v_agenda_rows jsonb := '[]'::jsonb;
begin
  select
    count(*),
    count(*) filter (where is_effective_call),
    count(*) filter (where is_agenda),
    count(*) filter (where is_no_agenda)
  into v_worked, v_effective, v_agendas, v_no_agenda
  from public.crm_contact_day_outcomes_v1
  where local_date = v_date;

  select coalesce(jsonb_object_agg(x.final_state_label, x.qty), '{}'::jsonb)
  into v_breakdown
  from (
    select final_state_label, count(*)::int as qty
    from public.crm_contact_day_outcomes_v1
    where local_date = v_date
    group by final_state_label
    order by final_state_label
  ) x;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'contact_id', o.contact_id,
        'work_item_id', o.work_item_id,
        'rut_norm', c.rut_norm,
        'rut', coalesce(c.rut, c.rut_norm),
        'nombre', coalesce(nullif(c.nombre,''), 'Sin nombre')
      ) order by coalesce(nullif(c.nombre,''), 'Sin nombre'), o.person_key
    ),
    '[]'::jsonb
  )
  into v_agenda_rows
  from public.crm_contact_day_outcomes_v1 o
  left join public.contacts c on c.contact_id = o.contact_id
  where o.local_date = v_date and o.is_agenda;

  return jsonb_build_object(
    'ok', true,
    'date', v_date,
    'worked_contacts', coalesce(v_worked,0),
    'effective_calls', coalesce(v_effective,0),
    'agendas', coalesce(v_agendas,0),
    'no_agenda', coalesce(v_no_agenda,0),
    'effective_conversion_rate', case when coalesce(v_effective,0) > 0 then round(100 * v_agendas::numeric / v_effective, 1) else null end,
    'worked_per_agenda', case when coalesce(v_agendas,0) > 0 then round(v_worked::numeric / v_agendas, 2) else null end,
    'final_state_breakdown', v_breakdown,
    'agenda_rows', v_agenda_rows,
    'metric_contract', 'daily_person_outcome_v1'
  );
end
$$;

revoke all on function public.get_daily_management_report_v1(date) from public, anon;
grant execute on function public.get_daily_management_report_v1(date) to authenticated;
comment on function public.get_daily_management_report_v1(date) is 'LCD-20260713-01. Informe diario unificado desde resultados finales por Persona y fecha.';
