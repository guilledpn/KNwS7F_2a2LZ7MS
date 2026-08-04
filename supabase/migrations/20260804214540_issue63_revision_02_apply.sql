-- Issue #63 · funciones administrativas; no ejecutan la operación al crearse.

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
  v_containment_rows integer := 0;
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
    raise exception 'Issue #63 prior-state guard failed'
      using errcode='55000';
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
    (select count(*) from staged_assigned s left join current_assigned c using(rut_norm) where c.rut_norm is null),
    (select count(*) from current_assigned c left join staged_assigned s using(rut_norm) where s.rut_norm is null),
    (select count(*) from staged_assigned s join current_assigned c using(rut_norm))
  into v_assigned_added,v_assigned_removed,v_assigned_common;

  if v_total_existing <> (v_operation.expected_prior->>'total_existing_pairs')::integer
     or v_total_added <> (v_operation.expected_prior->>'total_added_pairs')::integer
     or v_total_removed <> (v_operation.expected_prior->>'total_removed_pairs')::integer
     or v_transition <> (v_operation.expected_prior->>'status_no_gestionado_to_gestionado')::integer
     or v_assigned_added <> (v_operation.expected_prior->>'assigned_added')::integer
     or v_assigned_removed <> (v_operation.expected_prior->>'assigned_removed')::integer
     or v_assigned_common <> (v_operation.expected_prior->>'assigned_common')::integer then
    raise exception 'Issue #63 delta guard failed'
      using errcode='55000';
  end if;

  if nullif(v_operation.expected_prior->>'containment_event_id','') is not null then
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
  select
    v_operation.operation_key,c.contact_id,c.rut_norm,c.rut,c.nombre,
    c.telefono_1,c.telefono_2,c.telefono_3,c.email,c.telefono_activo_idx,
    c.search_text,c.created_at,c.updated_at
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

  insert into public.contacts(
    rut_norm,rut,nombre,telefono_1,telefono_2,telefono_3,email
  )
  select rut_norm,nullif(rut,''),nullif(nombre,''),nullif(telefono_1,''),
         nullif(telefono_2,''),nullif(telefono_3,''),nullif(email,'')
  from issue63_ops.stage_rows
  where operation_key=v_operation.operation_key and load_type='mensual'
  order by source_order
  on conflict(rut_norm) do update set
    rut=coalesce(excluded.rut,public.contacts.rut),
    nombre=coalesce(excluded.nombre,public.contacts.nombre),
    telefono_1=excluded.telefono_1,
    telefono_2=excluded.telefono_2,
    telefono_3=excluded.telefono_3,
    email=excluded.email,
    updated_at=now()
  where (public.contacts.rut,public.contacts.nombre,public.contacts.telefono_1,
         public.contacts.telefono_2,public.contacts.telefono_3,public.contacts.email)
    is distinct from
        (coalesce(excluded.rut,public.contacts.rut),
         coalesce(excluded.nombre,public.contacts.nombre),excluded.telefono_1,
         excluded.telefono_2,excluded.telefono_3,excluded.email);

  insert into public.campaigns(period,campaign_key,campaign_name,campaign_desc)
  select distinct on (campaign_key)
    v_operation.period,campaign_key,campaign_name,campaign_desc
  from issue63_ops.stage_rows
  where operation_key=v_operation.operation_key and load_type='mensual'
  order by campaign_key,source_order desc
  on conflict(period,campaign_key) do update set
    campaign_name=excluded.campaign_name,
    campaign_desc=excluded.campaign_desc
  where (public.campaigns.campaign_name,public.campaigns.campaign_desc)
    is distinct from (excluded.campaign_name,excluded.campaign_desc);

  with total_rows as (
    select t.*,a.source_order as assigned_order
    from issue63_ops.stage_rows t
    left join issue63_ops.stage_rows a
      on a.operation_key=t.operation_key and a.load_type='asignado'
     and a.rut_norm=t.rut_norm and a.campaign_key=t.campaign_key
    where t.operation_key=v_operation.operation_key and t.load_type='mensual'
  )
  insert into public.contact_month_state(
    contact_id,campaign_id,period,source_priority,import_order,
    is_assigned,visible,last_seen_at,estado_origen
  )
  select
    c.contact_id,ca.campaign_id,v_operation.period,
    case when t.assigned_order is null then 1 else 9999 end,
    coalesce(t.assigned_order,t.source_order),
    t.assigned_order is not null,
    true,now(),t.estado_origen
  from total_rows t
  join public.contacts c on c.rut_norm=t.rut_norm
  join public.campaigns ca
    on ca.period=v_operation.period and ca.campaign_key=t.campaign_key
  on conflict(contact_id,campaign_id,period) do update set
    source_priority=excluded.source_priority,
    import_order=excluded.import_order,
    is_assigned=excluded.is_assigned,
    visible=true,
    last_seen_at=now(),
    estado_origen=excluded.estado_origen;

  delete from public.monthly_source_order where period=v_operation.period;
  insert into public.monthly_source_order(
    period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
  )
  select
    v_operation.period,c.contact_id,t.source_order,v_session,
    v_total.file_name,v_total.xlsx_sha256,now()
  from issue63_ops.stage_rows t
  join public.contacts c on c.rut_norm=t.rut_norm
  where t.operation_key=v_operation.operation_key and t.load_type='mensual';

  update public.work_queue
     set visible=false,updated_at=now()
   where period=v_operation.period and visible;

  drop table if exists pg_temp.issue63_contained;
  create temporary table issue63_contained(contact_id uuid primary key) on commit drop;
  if nullif(v_operation.expected_prior->>'containment_event_id','') is not null then
    insert into pg_temp.issue63_contained(contact_id)
    select distinct (row_value->>'contact_id')::uuid
    from public.crm_guardrail_events e,
         lateral jsonb_array_elements(e.details->'rows') row_value
    where e.event_id=(v_operation.expected_prior->>'containment_event_id')::bigint
      and e.details->>'snapshot_id'=v_operation.expected_prior->>'containment_snapshot_id';
  end if;

  drop table if exists pg_temp.issue63_eligible;
  create temporary table issue63_eligible on commit drop as
  select
    e.contact_id,
    e.context_cms_id as cms_id,
    e.context_campaign_id as campaign_id,
    case when e.assigned_current then 'asignado' else 'regla' end as origen,
    e.context_order as display_order
  from public.contact_eligibility_for_period(v_operation.period) e
  where e.is_gestionable
    and (e.assigned_current or not exists (
      select 1 from pg_temp.issue63_contained c where c.contact_id=e.contact_id
    ));
  create unique index issue63_eligible_contact_idx on pg_temp.issue63_eligible(contact_id);

  insert into public.work_queue(
    contact_id,cms_id,period,campaign_id,origen,visible,display_order
  )
  select contact_id,cms_id,v_operation.period,campaign_id,origen,true,display_order
  from pg_temp.issue63_eligible
  on conflict(contact_id,period) do update set
    cms_id=excluded.cms_id,
    campaign_id=excluded.campaign_id,
    origen=excluded.origen,
    visible=true,
    display_order=excluded.display_order,
    updated_at=now();

  insert into public.crm_import_runs(
    file_name,load_type,period,row_count,distinct_ruts,status,result,updated_at
  )
  select
    m.file_name,m.load_type,v_operation.period,m.expected_rows,
    m.expected_distinct_ruts,'done',
    jsonb_build_object(
      'issue',63,
      'operation_key',v_operation.operation_key,
      'xlsx_sha256',m.xlsx_sha256,
      'payload_sha256',m.payload_sha256,
      'application','atomic_admin_operation',
      'containment_issue43_preserved',true
    ),now()
  from issue63_ops.file_manifest m
  where m.operation_key=v_operation.operation_key
  on conflict(file_name,load_type,period) do update set
    row_count=excluded.row_count,
    distinct_ruts=excluded.distinct_ruts,
    status='done',
    result=excluded.result,
    updated_at=now();

  insert into public.crm_import_progress(
    file_name,load_type,period,total_rows,processed_rows,status,last_error,updated_at
  )
  select m.file_name,m.load_type,v_operation.period,m.expected_rows,
         m.expected_rows,'done',null,now()
  from issue63_ops.file_manifest m
  where m.operation_key=v_operation.operation_key
  on conflict(file_name,load_type,period) do update set
    total_rows=excluded.total_rows,
    processed_rows=excluded.processed_rows,
    status='done',
    last_error=null,
    updated_at=now();

  update issue63_ops.operation
     set status='applied',applied_at=clock_timestamp()
   where operation_key=v_operation.operation_key;

  v_validation := issue63_ops.validate_applied();

  update issue63_ops.operation
     set result=v_validation
   where operation_key=v_operation.operation_key;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue63_august_revision_02_applied',
    'warning',
    jsonb_build_object(
      'issue',63,
      'operation_key',v_operation.operation_key,
      'period',v_operation.period,
      'total_file',v_total.file_name,
      'assigned_file',v_assigned.file_name,
      'prior_deltas',jsonb_build_object(
        'total_existing',v_total_existing,
        'total_added',v_total_added,
        'total_removed',v_total_removed,
        'status_no_gestionado_to_gestionado',v_transition,
        'assigned_added',v_assigned_added,
        'assigned_removed',v_assigned_removed,
        'assigned_common',v_assigned_common
      ),
      'validation',v_validation,
      'rollback','issue63_ops.rollback_operation() before cleanup and before resuming PWA writes'
    )
  );

  return v_validation;
end
$function$;

revoke all on function issue63_ops.apply_operation() from public, anon, authenticated;
