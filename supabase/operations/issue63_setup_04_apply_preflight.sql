-- Parte 4/7 · preflight, locks y snapshots de aplicación.
create or replace function issue63_ops.apply_operation()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_total issue63_ops.file_manifest;
  v_assigned issue63_ops.file_manifest;
  v_current_cms integer;
  v_current_all_cms integer;
  v_current_distinct integer;
  v_current_assigned integer;
  v_current_campaigns integer;
  v_public_staging integer;
  v_total_existing integer;
  v_total_added integer;
  v_total_removed integer;
  v_transition integer;
  v_assigned_added integer;
  v_assigned_removed integer;
  v_assigned_common integer;
  v_containment_rows integer;
  v_validation jsonb;
  v_session uuid := gen_random_uuid();
begin
  perform set_config('statement_timeout','900000',true);
  select * into strict v_operation from issue63_ops.operation limit 1 for update;
  select * into strict v_total from issue63_ops.file_manifest
    where operation_key=v_operation.operation_key and load_type='mensual';
  select * into strict v_assigned from issue63_ops.file_manifest
    where operation_key=v_operation.operation_key and load_type='asignado';

  if v_operation.status='applied' then
    return issue63_ops.validate_applied();
  end if;
  if v_operation.status not in ('staged','staging','configured') then
    raise exception 'Issue #63 cannot apply from status %',v_operation.status
      using errcode='55000';
  end if;
  if now() >= v_operation.expires_at then
    raise exception 'Issue #63 configuration expired before apply' using errcode='42501';
  end if;

  perform issue63_ops.validate_stage();

  lock table public.contacts in share row exclusive mode;
  lock table public.campaigns in share row exclusive mode;
  lock table public.contact_month_state in share row exclusive mode;
  lock table public.monthly_source_order in share row exclusive mode;
  lock table public.work_queue in share row exclusive mode;
  lock table public.crm_import_runs in share row exclusive mode;
  lock table public.crm_import_progress in share row exclusive mode;
  lock table public.crm_log in share row exclusive mode;
  lock table public.crm_events in share row exclusive mode;
  lock table public.crm_analysis_sample_items in share row exclusive mode;

  select count(*)::integer,count(distinct contact_id)::integer,
         count(*) filter(where is_assigned)::integer
  into v_current_cms,v_current_distinct,v_current_assigned
  from public.contact_month_state
  where period=v_operation.period and visible;
  select count(*)::integer into v_current_all_cms
  from public.contact_month_state where period=v_operation.period;
  select count(*)::integer into v_current_campaigns
  from public.campaigns where period=v_operation.period;
  select count(*)::integer into v_public_staging from public.staging_contacts;

  if public.active_period() <> v_operation.expected_prior->>'active_period'
     or v_current_cms <> (v_operation.expected_prior->>'period_cms_rows')::integer
     or v_current_all_cms <> (v_operation.expected_prior->>'period_all_cms_rows')::integer
     or v_current_distinct <> (v_operation.expected_prior->>'period_distinct_contacts')::integer
     or v_current_assigned <> (v_operation.expected_prior->>'period_assigned_rows')::integer
     or v_current_campaigns <> (v_operation.expected_prior->>'period_campaigns')::integer
     or v_public_staging <> (v_operation.expected_prior->>'public_staging_rows')::integer then
    raise exception 'Issue #63 prior-state guard failed' using errcode='55000';
  end if;

  select count(*)::integer into v_total_existing
  from issue63_ops.stage_rows t
  join public.contacts c on c.rut_norm=t.rut_norm
  join public.campaigns ca
    on ca.period=v_operation.period and ca.campaign_key=t.campaign_key
  join public.contact_month_state cms
    on cms.contact_id=c.contact_id and cms.campaign_id=ca.campaign_id
   and cms.period=v_operation.period
  where t.operation_key=v_operation.operation_key and t.load_type='mensual';

  select count(*)::integer into v_total_added
  from issue63_ops.stage_rows t
  left join public.contacts c on c.rut_norm=t.rut_norm
  left join public.campaigns ca
    on ca.period=v_operation.period and ca.campaign_key=t.campaign_key
  left join public.contact_month_state cms
    on cms.contact_id=c.contact_id and cms.campaign_id=ca.campaign_id
   and cms.period=v_operation.period
  where t.operation_key=v_operation.operation_key and t.load_type='mensual'
    and cms.cms_id is null;

  select count(*)::integer into v_total_removed
  from public.contact_month_state cms
  join public.contacts c on c.contact_id=cms.contact_id
  join public.campaigns ca on ca.campaign_id=cms.campaign_id
  left join issue63_ops.stage_rows t
    on t.operation_key=v_operation.operation_key and t.load_type='mensual'
   and t.rut_norm=c.rut_norm and t.campaign_key=ca.campaign_key
  where cms.period=v_operation.period and cms.visible and t.rut_norm is null;

  select count(*)::integer into v_transition
  from issue63_ops.stage_rows t
  join public.contacts c on c.rut_norm=t.rut_norm
  join public.campaigns ca
    on ca.period=v_operation.period and ca.campaign_key=t.campaign_key
  join public.contact_month_state cms
    on cms.contact_id=c.contact_id and cms.campaign_id=ca.campaign_id
   and cms.period=v_operation.period
  where t.operation_key=v_operation.operation_key and t.load_type='mensual'
    and lower(trim(cms.estado_origen))='no gestionado'
    and t.estado_origen='Gestionado';

  with current_assigned as (
    select distinct c.rut_norm
    from public.contact_month_state cms
    join public.contacts c on c.contact_id=cms.contact_id
    where cms.period=v_operation.period and cms.visible and cms.is_assigned
  ), staged_assigned as (
    select rut_norm from issue63_ops.stage_rows
    where operation_key=v_operation.operation_key and load_type='asignado'
  )
  select
    (select count(*) from staged_assigned s left join current_assigned c using(rut_norm)
      where c.rut_norm is null),
    (select count(*) from current_assigned c left join staged_assigned s using(rut_norm)
      where s.rut_norm is null),
    (select count(*) from staged_assigned s join current_assigned c using(rut_norm))
  into v_assigned_added,v_assigned_removed,v_assigned_common;

  if v_total_existing <> (v_operation.expected_prior->>'total_existing_pairs')::integer
     or v_total_added <> (v_operation.expected_prior->>'total_added_pairs')::integer
     or v_total_removed <> (v_operation.expected_prior->>'total_removed_pairs')::integer
     or v_transition <> (v_operation.expected_prior->>'status_no_gestionado_to_gestionado')::integer
     or v_assigned_added <> (v_operation.expected_prior->>'assigned_added')::integer
     or v_assigned_removed <> (v_operation.expected_prior->>'assigned_removed')::integer
     or v_assigned_common <> (v_operation.expected_prior->>'assigned_common')::integer then
    raise exception 'Issue #63 delta guard failed' using errcode='55000';
  end if;

  select jsonb_array_length(coalesce(e.details->'rows','[]'::jsonb))::integer
  into v_containment_rows
  from public.crm_guardrail_events e
  where e.event_id=(v_operation.expected_prior->>'containment_event_id')::bigint
    and e.details->>'snapshot_id'=v_operation.expected_prior->>'containment_snapshot_id';
  if coalesce(v_containment_rows,0) <> (v_operation.expected_prior->>'containment_rows')::integer then
    raise exception 'Issue #43 containment snapshot is missing or changed'
      using errcode='55000';
  end if;
  if exists (
    select 1
    from public.crm_guardrail_events e,
         lateral jsonb_array_elements(e.details->'rows') row_value
    join public.work_queue w
      on w.work_item_id=(row_value->>'work_item_id')::uuid
     and w.contact_id=(row_value->>'contact_id')::uuid
     and w.period=row_value->>'period'
    where e.event_id=(v_operation.expected_prior->>'containment_event_id')::bigint
      and w.visible
  ) then
    raise exception 'Issue #43 containment is not intact before apply'
      using errcode='55000';
  end if;

  update issue63_ops.operation set status='applying'
  where operation_key=v_operation.operation_key;

  truncate table
    issue63_ops.snapshot_contacts,
    issue63_ops.snapshot_campaigns,
    issue63_ops.snapshot_cms,
    issue63_ops.snapshot_monthly_order,
    issue63_ops.snapshot_work_queue,
    issue63_ops.snapshot_import_runs,
    issue63_ops.snapshot_import_progress;

  insert into issue63_ops.snapshot_contacts
  select distinct
    v_operation.operation_key,c.contact_id,c.rut_norm,c.rut,c.nombre,
    c.telefono_1,c.telefono_2,c.telefono_3,c.email,c.telefono_activo_idx
  from public.contacts c
  join issue63_ops.stage_rows s
    on s.operation_key=v_operation.operation_key
   and s.load_type='mensual' and s.rut_norm=c.rut_norm;

  insert into issue63_ops.snapshot_campaigns
  select v_operation.operation_key,c.*
  from public.campaigns c where c.period=v_operation.period;
  insert into issue63_ops.snapshot_cms
  select v_operation.operation_key,cms.*
  from public.contact_month_state cms where cms.period=v_operation.period;
  insert into issue63_ops.snapshot_monthly_order
  select v_operation.operation_key,m.*
  from public.monthly_source_order m where m.period=v_operation.period;
  insert into issue63_ops.snapshot_work_queue
  select v_operation.operation_key,w.*
  from public.work_queue w where w.period=v_operation.period;
  insert into issue63_ops.snapshot_import_runs
  select v_operation.operation_key,r.*
  from public.crm_import_runs r
  join issue63_ops.file_manifest m
    on m.operation_key=v_operation.operation_key
   and m.file_name=r.file_name and m.load_type=r.load_type and r.period=v_operation.period;
  insert into issue63_ops.snapshot_import_progress
  select v_operation.operation_key,p.*
  from public.crm_import_progress p
  join issue63_ops.file_manifest m
    on m.operation_key=v_operation.operation_key
   and m.file_name=p.file_name and m.load_type=p.load_type and p.period=v_operation.period;

