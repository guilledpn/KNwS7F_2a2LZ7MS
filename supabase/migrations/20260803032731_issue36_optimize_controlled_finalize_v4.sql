create or replace function public.crm_issue36_controlled_finalize(
  p_token text,
  p_action text default 'check',
  p_period text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $function$
declare
  v_token_hash text;
  v_staging bigint := 0;
  v_cms_rows bigint := 0;
  v_assigned bigint := 0;
  v_total bigint := 0;
  v_rule bigint := 0;
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
      'expires_at', '2026-08-05T12:00:00Z',
      'rebuild_mode', 'single_snapshot_atomic_v4'
    );
  end if;

  if p_period not in ('2026-07','2026-08') then
    raise exception 'Issue #36 rebuild is restricted to 2026-07 and 2026-08' using errcode = '22023';
  end if;

  if v_staging <> 0 then
    raise exception 'Cannot rebuild while staging contains % rows', v_staging using errcode = '55000';
  end if;

  perform pg_advisory_xact_lock(hashtext('issue36-rebuild-' || p_period));
  perform set_config('statement_timeout','300000',true);

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
      'status', public.import_period_status(p_period),
      'rebuild_mode', 'single_snapshot_atomic_v4'
    );
  end if;

  drop table if exists pg_temp.issue36_eligible;
  create temporary table issue36_eligible on commit drop as
  select
    e.contact_id,
    e.context_cms_id as cms_id,
    e.context_campaign_id as campaign_id,
    case when e.assigned_current then 'asignado'::text else 'regla'::text end as origen,
    e.context_order as display_order
  from public.contact_eligibility_for_period(p_period) e
  where e.is_gestionable;

  create unique index on issue36_eligible(contact_id);

  select count(*),
         count(*) filter(where origen='asignado'),
         count(*) filter(where origen='regla')
    into v_total,v_assigned,v_rule
  from issue36_eligible;

  if p_period='2026-07' and (v_total <> 45076 or v_assigned <> 165 or v_rule <> 44911) then
    raise exception 'July eligibility validation failed: total=%, assigned=%, rule=%', v_total,v_assigned,v_rule using errcode='55000';
  end if;

  if p_period='2026-08' and v_assigned <> 54 then
    raise exception 'August eligibility validation failed: total=%, assigned=%, rule=%', v_total,v_assigned,v_rule using errcode='55000';
  end if;

  insert into public.work_queue(
    contact_id,cms_id,period,campaign_id,origen,visible,display_order
  )
  select
    e.contact_id,e.cms_id,p_period,e.campaign_id,e.origen,true,e.display_order
  from issue36_eligible e
  on conflict(contact_id,period) do update set
    cms_id=excluded.cms_id,
    campaign_id=excluded.campaign_id,
    origen=excluded.origen,
    visible=true,
    display_order=excluded.display_order,
    updated_at=now();

  update public.work_queue w
     set visible=false, updated_at=now()
   where w.period=p_period
     and w.visible
     and not exists (
       select 1 from issue36_eligible e where e.contact_id=w.contact_id
     );

  select count(*),
         count(*) filter(where origen='asignado'),
         count(*) filter(where origen='regla')
    into v_total,v_assigned,v_rule
  from public.work_queue
  where period=p_period and visible;

  if p_period='2026-07' and (v_total <> 45076 or v_assigned <> 165 or v_rule <> 44911) then
    raise exception 'July queue postcondition failed: total=%, assigned=%, rule=%', v_total,v_assigned,v_rule using errcode='55000';
  end if;

  if p_period='2026-08' and v_assigned <> 54 then
    raise exception 'August queue postcondition failed: total=%, assigned=%, rule=%', v_total,v_assigned,v_rule using errcode='55000';
  end if;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue36_controlled_rebuild',
    'warning',
    jsonb_build_object(
      'issue',36,
      'operation','close_july_activate_august_2026',
      'period',p_period,
      'cms_rows',v_cms_rows,
      'assigned_rows',v_assigned,
      'visible_total_rows',v_total,
      'visible_assigned_rows',v_assigned,
      'visible_rule_rows',v_rule,
      'rebuild_mode','single_snapshot_atomic_v4'
    )
  );

  return jsonb_build_object(
    'ok',true,
    'issue',36,
    'action','rebuild',
    'period',p_period,
    'already_done',false,
    'active_period',public.active_period(),
    'result',jsonb_build_object(
      'ok',true,
      'period',p_period,
      'rule','canonical_monthly_eligibility_v1',
      'visible_total_rows',v_total,
      'visible_assigned_rows',v_assigned,
      'visible_rule_rows',v_rule,
      'missing_status_behavior','fail_closed'
    ),
    'status',public.import_period_status(p_period),
    'rebuild_mode','single_snapshot_atomic_v4'
  );
end
$function$;

revoke all on function public.crm_issue36_controlled_finalize(text,text,text) from public;
revoke all on function public.crm_issue36_controlled_finalize(text,text,text) from authenticated;
grant execute on function public.crm_issue36_controlled_finalize(text,text,text) to anon;
