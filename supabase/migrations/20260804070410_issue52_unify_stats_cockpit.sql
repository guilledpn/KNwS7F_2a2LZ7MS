-- Candidate for LCD-20260804-01 / ADR-027 / Issue #52.
-- Apply only in DEV until the documented contract and UI are reviewed.

alter table public.crm_goals
  add column if not exists estimated_cns_per_agenda numeric(8,2) not null default 2.50,
  add column if not exists estimated_clp_per_cns integer not null default 10000;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'crm_goals_estimated_cns_per_agenda_positive'
      and conrelid = 'public.crm_goals'::regclass
  ) then
    alter table public.crm_goals
      add constraint crm_goals_estimated_cns_per_agenda_positive
      check (estimated_cns_per_agenda > 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'crm_goals_estimated_clp_per_cns_positive'
      and conrelid = 'public.crm_goals'::regclass
  ) then
    alter table public.crm_goals
      add constraint crm_goals_estimated_clp_per_cns_positive
      check (estimated_clp_per_cns > 0);
  end if;
end
$$;

alter table public.crm_log
  alter column fecha set default ((now() at time zone 'America/Santiago')::date);

create or replace function public.save_gestion_v2(
  p_work_item_id uuid default null::uuid,
  p_contact_id uuid default null::uuid,
  p_active_period text default null::text,
  p_estado text default 'Pendiente'::text,
  p_ingreso numeric default 0,
  p_comentarios text default ''::text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_work uuid;
  v_contact uuid;
  v_old text;
  v_target text;
  v_period text := coalesce(p_active_period, public.active_period());
  v_campaign uuid;
  v_origen text;
  v_rut text;
  v_rut_number bigint;
  v_rut_range text;
  v_local_date date := (now() at time zone 'America/Santiago')::date;
  v_hour int := extract(hour from now() at time zone 'America/Santiago')::int;
  v_event_id bigint;
  v_sprint uuid := public.crm_current_sprint_id();
  v_profile_only boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_work_item_id is not null then
    select w.work_item_id, w.contact_id, w.estado_gestion::text, w.period,
           w.campaign_id, w.origen, c.rut_norm
      into v_work, v_contact, v_old, v_period, v_campaign, v_origen, v_rut
    from public.work_queue w
    left join public.contacts c on c.contact_id = w.contact_id
    where w.work_item_id = p_work_item_id;
  elsif p_contact_id is not null then
    select w.work_item_id, w.contact_id, w.estado_gestion::text, w.period,
           w.campaign_id, w.origen, c.rut_norm
      into v_work, v_contact, v_old, v_period, v_campaign, v_origen, v_rut
    from public.work_queue w
    left join public.contacts c on c.contact_id = w.contact_id
    where w.contact_id = p_contact_id and w.period = v_period
    limit 1;
  end if;

  if v_work is null then
    return jsonb_build_object('ok', false, 'error', 'No encontré work item para guardar gestión');
  end if;

  v_target := coalesce(nullif(p_estado, ''), v_old, 'Pendiente');
  v_profile_only := (v_old is not distinct from v_target)
    or (v_old is null and v_target = 'Pendiente');

  if v_profile_only then
    update public.work_queue
    set ingreso_estimado = coalesce(p_ingreso, 0),
        comentarios = coalesce(p_comentarios, ''),
        updated_at = now()
    where work_item_id = v_work;

    return jsonb_build_object(
      'ok', true,
      'work_item_id', v_work,
      'contact_id', v_contact,
      'event_id', null,
      'sprint_id', null,
      'profile_only', true
    );
  end if;

  v_rut_number := public.crm_rut_number(v_rut);
  v_rut_range := public.crm_rut_range(v_rut);

  update public.work_queue
  set estado_gestion = v_target,
      ingreso_estimado = coalesce(p_ingreso, 0),
      comentarios = coalesce(p_comentarios, ''),
      updated_at = now()
  where work_item_id = v_work;

  insert into public.crm_log(
    work_item_id,
    contact_id,
    fecha,
    estado_anterior,
    estado_nuevo,
    ingreso_estimado,
    comentarios
  )
  values (
    v_work,
    v_contact,
    v_local_date,
    v_old,
    v_target,
    p_ingreso,
    p_comentarios
  );

  insert into public.crm_events(
    event_type,
    event_ts,
    local_date,
    local_hour,
    local_weekday,
    hour_block,
    sprint_id,
    work_item_id,
    contact_id,
    campaign_id,
    period,
    origen,
    rut_norm,
    rut_number,
    rut_range,
    estado_anterior,
    estado_nuevo,
    is_agenda,
    is_no_agenda,
    is_volver_llamar,
    is_no_contactado,
    is_contacto_invalido,
    ingreso_estimado,
    metadata
  )
  values (
    'gestion_saved',
    now(),
    v_local_date,
    v_hour,
    extract(isodow from now() at time zone 'America/Santiago')::int,
    public.crm_hour_block(v_hour),
    v_sprint,
    v_work,
    v_contact,
    v_campaign,
    v_period,
    v_origen,
    v_rut,
    v_rut_number,
    v_rut_range,
    v_old,
    v_target,
    public.crm_is_agenda(v_target),
    lower(coalesce(v_target, '')) = 'no agenda',
    lower(coalesce(v_target, '')) = 'volver a llamar',
    lower(coalesce(v_target, '')) = 'no contactado',
    lower(coalesce(v_target, '')) = 'contacto inválido',
    p_ingreso,
    jsonb_build_object('comentarios_len', length(coalesce(p_comentarios, '')))
  )
  returning event_id into v_event_id;

  if v_sprint is not null then
    update public.crm_sprints
    set calls_count = calls_count + 1,
        agendas_count = agendas_count + case when public.crm_is_agenda(v_target) then 1 else 0 end,
        updated_at = now()
    where sprint_id = v_sprint and status = 'running';
  end if;

  return jsonb_build_object(
    'ok', true,
    'work_item_id', v_work,
    'contact_id', v_contact,
    'event_id', v_event_id,
    'sprint_id', v_sprint,
    'profile_only', false
  );
end
$$;

revoke all on function public.save_gestion_v2(uuid, uuid, text, text, numeric, text)
  from public, anon;
grant execute on function public.save_gestion_v2(uuid, uuid, text, text, numeric, text)
  to authenticated;

create or replace function public.get_stats_cockpit_v1()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
  v_today date := (v_now at time zone 'America/Santiago')::date;
  v_month_key text := to_char(v_today, 'YYYY-MM');
  v_month_start date := date_trunc('month', v_today)::date;
  v_month_end date := (date_trunc('month', v_today) + interval '1 month - 1 day')::date;
  v_week_start date := v_today - (extract(isodow from v_today)::int - 1);
  v_week_end date := least(v_month_end, v_week_start + 6);
  v_workdays integer[] := array[1,2,3,4,5];
  v_weekend_target integer := 0;
  v_monthly_target integer := 0;
  v_stored_daily_target integer := 0;
  v_cns_per_agenda numeric(8,2) := 2.50;
  v_clp_per_cns integer := 10000;
  v_clp_per_agenda numeric := 25000;
  v_total_active_days integer := 0;
  v_elapsed_active_days integer := 0;
  v_active_days_left integer := 0;
  v_is_today_active boolean := false;
  v_normal_daily integer := 0;
  v_today_target integer := 0;
  v_month_agendas integer := 0;
  v_expected_through_today integer := 0;
  v_remaining_agendas integer := 0;
  v_needed_daily integer := 0;
  v_recommended_today integer := 0;
  v_projected_current integer := 0;
  v_projected_normal integer := 0;
  v_periods jsonb := '{}'::jsonb;
  v_story jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select
    coalesce(g.monthly_goal, 0),
    coalesce(g.daily_goal, 0),
    coalesce(g.estimated_cns_per_agenda, 2.50),
    coalesce(g.estimated_clp_per_cns, 10000)
  into v_monthly_target, v_stored_daily_target, v_cns_per_agenda, v_clp_per_cns
  from public.crm_goals g
  where g.goal_month = v_month_key;

  v_monthly_target := coalesce(v_monthly_target, 0);
  v_stored_daily_target := coalesce(v_stored_daily_target, 0);
  v_cns_per_agenda := coalesce(v_cns_per_agenda, 2.50);
  v_clp_per_cns := coalesce(v_clp_per_cns, 10000);
  v_clp_per_agenda := v_cns_per_agenda * v_clp_per_cns;

  select coalesce(s.workdays, array[1,2,3,4,5]), coalesce(s.weekend_target_agendas, 0)
  into v_workdays, v_weekend_target
  from public.crm_goal_settings s
  where s.setting_id = 1;

  v_workdays := coalesce(v_workdays, array[1,2,3,4,5]);
  v_weekend_target := coalesce(v_weekend_target, 0);

  with calendar as (
    select
      d::date as day,
      case
        when dg.goal_date is not null then dg.target_agendas > 0
        when h.holiday_date is not null then h.target_agendas > 0
        when extract(isodow from d)::int = any(v_workdays) then true
        else v_weekend_target > 0
      end as is_active
    from generate_series(v_month_start, v_month_end, interval '1 day') d
    left join public.crm_daily_goals dg on dg.goal_date = d::date
    left join public.crm_holidays h on h.holiday_date = d::date
  )
  select
    count(*) filter (where is_active),
    count(*) filter (where is_active and day <= v_today),
    count(*) filter (where is_active and day >= v_today),
    coalesce(bool_or(is_active) filter (where day = v_today), false)
  into v_total_active_days, v_elapsed_active_days, v_active_days_left, v_is_today_active
  from calendar;

  v_normal_daily := case
    when v_monthly_target > 0 and v_total_active_days > 0
      then ceil(v_monthly_target::numeric / v_total_active_days)::int
    else v_stored_daily_target
  end;

  select coalesce(
    dg.target_agendas,
    case
      when h.holiday_date is not null then h.target_agendas
      when extract(isodow from v_today)::int = any(v_workdays) then v_normal_daily
      else v_weekend_target
    end,
    0
  )
  into v_today_target
  from (select 1) seed
  left join public.crm_daily_goals dg on dg.goal_date = v_today
  left join public.crm_holidays h on h.holiday_date = v_today;

  select count(*) filter (where is_agenda)::int
  into v_month_agendas
  from public.crm_contact_day_outcomes_v1
  where local_date between v_month_start and v_today;

  v_month_agendas := coalesce(v_month_agendas, 0);
  v_expected_through_today := case
    when v_monthly_target > 0 and v_total_active_days > 0
      then round(v_monthly_target::numeric * v_elapsed_active_days / v_total_active_days)::int
    else 0
  end;
  v_remaining_agendas := greatest(0, v_monthly_target - v_month_agendas);
  v_needed_daily := case
    when v_remaining_agendas > 0 and v_active_days_left > 0
      then ceil(v_remaining_agendas::numeric / v_active_days_left)::int
    else 0
  end;
  v_recommended_today := case
    when v_monthly_target <= 0 or not v_is_today_active then 0
    else greatest(v_today_target, v_normal_daily, v_needed_daily)
  end;
  v_projected_current := case
    when v_elapsed_active_days > 0
      then greatest(v_month_agendas, round(v_month_agendas::numeric * v_total_active_days / v_elapsed_active_days)::int)
    else v_month_agendas
  end;
  v_projected_normal := greatest(
    v_month_agendas,
    v_month_agendas + greatest(0, v_monthly_target - v_expected_through_today)
  );

  with raw as (
    select
      'last_hour'::text as window_key,
      'Últimos 60 minutos'::text as label,
      (v_now - interval '60 minutes')::text as range_start,
      v_now::text as range_end,
      count(*)::int as worked_contacts,
      count(*) filter (where is_effective_call)::int as effective_calls,
      count(*) filter (where is_agenda)::int as agendas,
      count(*) filter (where is_no_agenda)::int as no_agenda
    from public.crm_contact_day_outcomes_v1
    where created_at >= v_now - interval '60 minutes' and created_at <= v_now

    union all

    select
      'today',
      'Hoy',
      v_today::text,
      v_today::text,
      count(*)::int,
      count(*) filter (where is_effective_call)::int,
      count(*) filter (where is_agenda)::int,
      count(*) filter (where is_no_agenda)::int
    from public.crm_contact_day_outcomes_v1
    where local_date = v_today

    union all

    select
      'week',
      'Semana calendario',
      v_week_start::text,
      v_today::text,
      count(*)::int,
      count(*) filter (where is_effective_call)::int,
      count(*) filter (where is_agenda)::int,
      count(*) filter (where is_no_agenda)::int
    from public.crm_contact_day_outcomes_v1
    where local_date between v_week_start and v_today

    union all

    select
      'month',
      'Mes calendario',
      v_month_start::text,
      v_today::text,
      count(*)::int,
      count(*) filter (where is_effective_call)::int,
      count(*) filter (where is_agenda)::int,
      count(*) filter (where is_no_agenda)::int
    from public.crm_contact_day_outcomes_v1
    where local_date between v_month_start and v_today
  )
  select coalesce(
    jsonb_object_agg(
      window_key,
      jsonb_build_object(
        'label', label,
        'range_start', range_start,
        'range_end', range_end,
        'worked_contacts', worked_contacts,
        'effective_calls', effective_calls,
        'agendas', agendas,
        'no_agenda', no_agenda,
        'effective_conversion_rate', case
          when effective_calls > 0 then round(100 * agendas::numeric / effective_calls, 1)
          else null
        end,
        'worked_per_agenda', case
          when agendas > 0 then round(worked_contacts::numeric / agendas, 2)
          else null
        end,
        'expected_cns', round(agendas * v_cns_per_agenda, 2),
        'expected_clp', round(agendas * v_clp_per_agenda)::bigint
      )
    ),
    '{}'::jsonb
  )
  into v_periods
  from raw;

  with calendar as (
    select
      d::date as day,
      h.name as holiday_name,
      case
        when dg.goal_date is not null then dg.target_agendas > 0
        when h.holiday_date is not null then h.target_agendas > 0
        when extract(isodow from d)::int = any(v_workdays) then true
        else v_weekend_target > 0
      end as is_active
    from generate_series(v_month_start, v_month_end, interval '1 day') d
    left join public.crm_daily_goals dg on dg.goal_date = d::date
    left join public.crm_holidays h on h.holiday_date = d::date
  ), indexed as (
    select
      c.*,
      sum(case when c.is_active then 1 else 0 end) over (order by c.day)::int as active_day_index
    from calendar c
  ), actuals as (
    select local_date, count(*) filter (where is_agenda)::int as daily_agendas
    from public.crm_contact_day_outcomes_v1
    where local_date between v_month_start and v_today
    group by local_date
  ), series as (
    select
      i.day,
      i.is_active,
      i.holiday_name,
      coalesce(a.daily_agendas, 0)::int as daily_agendas,
      case
        when v_monthly_target > 0 and v_total_active_days > 0
          then round(v_monthly_target::numeric * i.active_day_index / v_total_active_days)::int
        else 0
      end as expected_cumulative,
      case
        when i.day <= v_today
          then sum(coalesce(a.daily_agendas, 0)) over (order by i.day)::int
        else null
      end as actual_cumulative
    from indexed i
    left join actuals a on a.local_date = i.day
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'day', day,
        'is_workday', is_active,
        'holiday_name', holiday_name,
        'daily_agendas', daily_agendas,
        'expected_cumulative', expected_cumulative,
        'actual_cumulative', actual_cumulative
      ) order by day
    ),
    '[]'::jsonb
  )
  into v_story
  from series;

  return jsonb_build_object(
    'ok', true,
    'generated_at', v_now,
    'timezone', 'America/Santiago',
    'metric_contract', 'daily_person_outcome_v1',
    'value_contract', 'agenda_expected_value_v1',
    'goal', jsonb_build_object(
      'source', 'crm_goals',
      'goal_month', v_month_key,
      'monthly_agendas', v_monthly_target,
      'normal_daily_agendas', v_normal_daily,
      'today_target_agendas', v_today_target,
      'estimated_cns_per_agenda', v_cns_per_agenda,
      'estimated_clp_per_cns', v_clp_per_cns,
      'estimated_clp_per_agenda', round(v_clp_per_agenda)::bigint,
      'target_expected_cns', round(v_monthly_target * v_cns_per_agenda, 2),
      'target_expected_clp', round(v_monthly_target * v_clp_per_agenda)::bigint
    ),
    'periods', v_periods,
    'month', jsonb_build_object(
      'start', v_month_start,
      'end', v_month_end,
      'week_start', v_week_start,
      'week_end', v_week_end,
      'actual_agendas', v_month_agendas,
      'expected_through_today', v_expected_through_today,
      'gap_to_pace', v_month_agendas - v_expected_through_today,
      'remaining_agendas', v_remaining_agendas,
      'active_days_total', v_total_active_days,
      'active_days_elapsed', v_elapsed_active_days,
      'active_days_left_including_today', v_active_days_left,
      'is_today_active', v_is_today_active,
      'needed_daily_to_finish', v_needed_daily,
      'recommended_today_agendas', v_recommended_today,
      'projected_end_at_current_pace', v_projected_current,
      'projected_end_if_normal_from_now', v_projected_normal,
      'actual_expected_cns', round(v_month_agendas * v_cns_per_agenda, 2),
      'actual_expected_clp', round(v_month_agendas * v_clp_per_agenda)::bigint,
      'remaining_expected_cns', round(v_remaining_agendas * v_cns_per_agenda, 2),
      'remaining_expected_clp', round(v_remaining_agendas * v_clp_per_agenda)::bigint
    ),
    'month_story', jsonb_build_object(
      'today', v_today,
      'series', v_story
    ),
    'next_agenda', jsonb_build_object(
      'expected_cns', v_cns_per_agenda,
      'expected_clp', round(v_clp_per_agenda)::bigint
    ),
    'notices', jsonb_build_array(
      'CNS y pesos son equivalencias esperadas, no producción reconocida ni ingreso devengado.'
    )
  );
end
$$;

revoke all on function public.get_stats_cockpit_v1() from public, anon;
grant execute on function public.get_stats_cockpit_v1() to authenticated;

comment on function public.get_stats_cockpit_v1() is
  'LCD-20260804-01 / ADR-027. Cockpit unificado desde resultados finales por Persona/día y equivalencias esperadas configurables.';

comment on column public.crm_goals.estimated_cns_per_agenda is
  'Supuesto mensual para el pulso motivacional; no representa CNS sometidos, emitidos ni reconocidos.';

comment on column public.crm_goals.estimated_clp_per_cns is
  'Valor monetario de referencia del pulso motivacional; no representa ingreso devengado.';

notify pgrst, 'reload schema';
