create or replace function public.crm_issue36_controlled_finalize(
  p_token text,
  p_action text default 'check',
  p_period text default null
)
returns jsonb
language plpgsql
security definer
set search_path = 'public', 'pg_temp'
as $function$
declare
  v_token_hash text;
  v_staging bigint := 0;
  v_cms_rows bigint := 0;
  v_assigned bigint := 0;
  v_result jsonb;
  v_already_done boolean := false;
begin
  if now() >= timestamptz '2026-08-05 12:00:00+00' then
    raise exception 'Issue #36 operation gate expired' using errcode = '42501';
  end if;

  if coalesce(auth.jwt()->>'role','') <> 'anon' then
    raise exception 'Issue #36 gate requires the expected public client role' using errcode = '42501';
  end if;

  v_token_hash := encode(extensions.digest(coalesce(p_token,''), 'sha256'), 'hex');
  if v_token_hash <> '42582521c0e9378958fde3254a35a5e0c73dbe377e006269267dfb02297e1cc1' then
    raise exception 'Invalid Issue #36 operation token' using errcode = '42501';
  end if;

  if p_action not in ('check','rebuild') then
    raise exception 'Unsupported Issue #36 action: %', p_action using errcode = '22023';
  end if;

  select count(*) into v_staging from public.staging_contacts;

  if p_action = 'check' then
    return jsonb_build_object(
      'ok', true,
      'issue', 36,
      'action', 'check',
      'active_period', public.active_period(),
      'staging_rows', v_staging,
      'july', public.import_period_status('2026-07'),
      'august', public.import_period_status('2026-08'),
      'expires_at', '2026-08-05T12:00:00Z'
    );
  end if;

  if p_period not in ('2026-07','2026-08') then
    raise exception 'Issue #36 rebuild is restricted to 2026-07 and 2026-08' using errcode = '22023';
  end if;

  if v_staging <> 0 then
    raise exception 'Cannot rebuild while staging contains % rows', v_staging using errcode = '55000';
  end if;

  select count(*), count(distinct contact_id) filter (where is_assigned)
    into v_cms_rows, v_assigned
  from public.contact_month_state
  where period = p_period and visible;

  if p_period = '2026-07' and (v_cms_rows <> 75308 or v_assigned <> 165) then
    raise exception 'July precondition failed: cms_rows=%, assigned=%', v_cms_rows, v_assigned using errcode = '55000';
  end if;

  if p_period = '2026-08' and (v_cms_rows <> 28186 or v_assigned <> 54) then
    raise exception 'August precondition failed: cms_rows=%, assigned=%', v_cms_rows, v_assigned using errcode = '55000';
  end if;

  select exists(
    select 1
    from public.crm_guardrail_events
    where event_type = 'issue36_controlled_rebuild'
      and details->>'period' = p_period
      and details->>'operation' = 'close_july_activate_august_2026'
  ) into v_already_done;

  if v_already_done then
    return jsonb_build_object(
      'ok', true,
      'issue', 36,
      'action', 'rebuild',
      'period', p_period,
      'already_done', true,
      'active_period', public.active_period(),
      'status', public.import_period_status(p_period)
    );
  end if;

  v_result := public.rebuild_work_queue_for_period(p_period);

  insert into public.crm_guardrail_events(event_type, severity, details)
  values(
    'issue36_controlled_rebuild',
    'warning',
    jsonb_build_object(
      'issue', 36,
      'operation', 'close_july_activate_august_2026',
      'period', p_period,
      'cms_rows', v_cms_rows,
      'assigned_rows', v_assigned,
      'result', v_result
    )
  );

  return jsonb_build_object(
    'ok', true,
    'issue', 36,
    'action', 'rebuild',
    'period', p_period,
    'already_done', false,
    'active_period', public.active_period(),
    'result', v_result,
    'status', public.import_period_status(p_period)
  );
end
$function$;

revoke all on function public.crm_issue36_controlled_finalize(text,text,text) from public;
revoke all on function public.crm_issue36_controlled_finalize(text,text,text) from authenticated;
grant execute on function public.crm_issue36_controlled_finalize(text,text,text) to anon;

comment on function public.crm_issue36_controlled_finalize(text,text,text) is
'Temporary, token-gated operational gate for Issue #36. Restricted to validation and canonical queue rebuilds for 2026-07 and 2026-08; expires 2026-08-05 and must be removed after the operation.';
