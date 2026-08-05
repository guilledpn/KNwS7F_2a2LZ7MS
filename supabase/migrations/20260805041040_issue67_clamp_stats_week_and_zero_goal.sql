-- Issue #67 · DEV candidate for financial Stats hierarchy.
--
-- This migration keeps the public.get_stats_cockpit_v1() signature and payload stable.
-- It corrects two semantics already approved by the product owner:
--   1. the current calendar week is bounded by the current month;
--   2. a monthly target of zero disables every derived daily target.
--
-- Recovery: restore the previous function definition from the migration immediately
-- preceding Issue #67. No stored facts or user data are modified by this migration.

do $migration$
declare
  v_oid oid := to_regprocedure('public.get_stats_cockpit_v1()');
  v_definition text;
  v_old_week text := 'v_week_start date := v_today - (extract(isodow from v_today)::int - 1);';
  v_new_week text := 'v_week_start date := greatest(v_month_start, v_today - (extract(isodow from v_today)::int - 1));';
  v_today_anchor text := '  left join public.crm_holidays h on h.holiday_date = v_today;';
  v_today_guard text := '  if v_monthly_target <= 0 then';
begin
  if v_oid is null then
    raise exception 'No existe public.get_stats_cockpit_v1()';
  end if;

  select pg_get_functiondef(v_oid) into v_definition;

  if position(v_new_week in v_definition) = 0 then
    if position(v_old_week in v_definition) = 0 then
      raise exception 'La definición de get_stats_cockpit_v1 no contiene la semana esperada';
    end if;
    v_definition := replace(v_definition, v_old_week, v_new_week);
  end if;

  if position('else v_stored_daily_target' in v_definition) > 0 then
    v_definition := replace(v_definition, 'else v_stored_daily_target', 'else 0');
  elsif position(
    'else 0' in substring(
      v_definition from position('v_normal_daily := case' in v_definition) for 320
    )
  ) = 0 then
    raise exception 'La definición de get_stats_cockpit_v1 no contiene la meta diaria esperada';
  end if;

  if position(v_today_guard in v_definition) = 0 then
    if position(v_today_anchor in v_definition) = 0 then
      raise exception 'La definición de get_stats_cockpit_v1 no contiene la meta de hoy esperada';
    end if;
    v_definition := replace(
      v_definition,
      v_today_anchor,
      v_today_anchor || chr(10) || chr(10) ||
      '  if v_monthly_target <= 0 then' || chr(10) ||
      '    v_today_target := 0;' || chr(10) ||
      '  end if;'
    );
  end if;

  execute v_definition;
end
$migration$;
