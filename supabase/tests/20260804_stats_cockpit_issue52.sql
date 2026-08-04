-- Issue #52 · contract and motivational equivalence regression.
-- This test changes only the current-month settings inside a rolled-back transaction.
begin;

insert into public.crm_goals(
  goal_month,
  daily_goal,
  monthly_goal,
  estimated_cns_per_agenda,
  estimated_clp_per_cns,
  updated_at
)
values (
  to_char(now() at time zone 'America/Santiago', 'YYYY-MM'),
  9,
  189,
  2.50,
  10000,
  now()
)
on conflict (goal_month) do update
set daily_goal = excluded.daily_goal,
    monthly_goal = excluded.monthly_goal,
    estimated_cns_per_agenda = excluded.estimated_cns_per_agenda,
    estimated_clp_per_cns = excluded.estimated_clp_per_cns,
    updated_at = excluded.updated_at;

do $acl$
begin
  if has_function_privilege('anon', 'public.get_stats_cockpit_v1()', 'execute') then
    raise exception 'anon must not execute get_stats_cockpit_v1';
  end if;
  if not has_function_privilege('authenticated', 'public.get_stats_cockpit_v1()', 'execute') then
    raise exception 'authenticated must execute get_stats_cockpit_v1';
  end if;
end
$acl$;

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000052","role":"authenticated"}',
  true
);
set local role authenticated;

do $contract$
declare
  v_stats jsonb := public.get_stats_cockpit_v1();
  v_month_agendas numeric;
begin
  if (v_stats #>> '{goal,monthly_agendas}')::integer <> 189 then
    raise exception 'Settings goal must govern cockpit: %', v_stats #>> '{goal,monthly_agendas}';
  end if;
  if (v_stats #>> '{goal,target_expected_cns}')::numeric <> 472.50 then
    raise exception '189 agendas must equal 472.5 expected CNS';
  end if;
  if (v_stats #>> '{goal,target_expected_clp}')::bigint <> 4725000 then
    raise exception '189 agendas must equal CLP 4,725,000 expected';
  end if;
  if (v_stats #>> '{next_agenda,expected_cns}')::numeric <> 2.50
     or (v_stats #>> '{next_agenda,expected_clp}')::bigint <> 25000 then
    raise exception 'Next agenda pulse must equal 2.5 CNS / CLP 25,000';
  end if;
  if not (v_stats->'periods' ?& array['last_hour','today','week','month']) then
    raise exception 'Cockpit periods are incomplete';
  end if;
  if v_stats->>'metric_contract' is distinct from 'daily_person_outcome_v1' then
    raise exception 'Unexpected metric contract: %', v_stats->>'metric_contract';
  end if;
  v_month_agendas := (v_stats #>> '{periods,month,agendas}')::numeric;
  if (v_stats #>> '{periods,month,expected_cns}')::numeric <> v_month_agendas * 2.50 then
    raise exception 'Month expected CNS does not derive from month agendas';
  end if;
end
$contract$;

rollback;
