-- Issue #52 · regression for the management write path changed by the stats lot.
-- The selected DEV row and every generated record are rolled back.
begin;

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000052","role":"authenticated"}',
  true
);
set local role authenticated;

do $smoke$
declare
  v_work_item_id uuid;
  v_period text;
  v_current_state text;
  v_target_state text;
  v_result jsonb;
  v_event_id bigint;
  v_log_date date;
  v_event_date date;
begin
  if has_function_privilege('anon', 'public.crm_current_sprint_id()', 'execute') then
    raise exception 'anon must not execute crm_current_sprint_id';
  end if;

  select work_item_id, period, estado_gestion::text
  into v_work_item_id, v_period, v_current_state
  from public.work_queue
  order by updated_at desc nulls last, work_item_id
  limit 1;

  if v_work_item_id is null then
    raise exception 'DEV smoke requires at least one fictitious work item';
  end if;

  v_target_state := case
    when lower(coalesce(v_current_state, '')) = 'no contactado' then 'Volver a llamar'
    else 'No contactado'
  end;

  v_result := public.save_gestion_v2(
    v_work_item_id,
    null,
    v_period,
    v_target_state,
    0,
    'Issue #52 transactional smoke; rollback'
  );

  if not coalesce((v_result->>'ok')::boolean, false) then
    raise exception 'save_gestion_v2 failed: %', v_result;
  end if;

  v_event_id := (v_result->>'event_id')::bigint;
  if v_event_id is null then
    raise exception 'save_gestion_v2 did not create an event: %', v_result;
  end if;

  select local_date
  into v_event_date
  from public.crm_events
  where event_id = v_event_id;

  select fecha
  into v_log_date
  from public.crm_log
  where work_item_id = v_work_item_id
    and estado_nuevo = v_target_state
  order by created_at desc, log_id desc
  limit 1;

  if v_log_date is distinct from v_event_date then
    raise exception 'Chile dates diverged: crm_log %, crm_events %', v_log_date, v_event_date;
  end if;

  if v_log_date is distinct from (now() at time zone 'America/Santiago')::date then
    raise exception 'Management date is not current Chile date: %', v_log_date;
  end if;
end
$smoke$;

rollback;
