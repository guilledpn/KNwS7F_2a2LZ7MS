-- Issue #63 · funciones administrativas; no ejecutan la operación al crearse.

create or replace function issue63_ops.validate_applied()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_total issue63_ops.file_manifest;
  v_assigned issue63_ops.file_manifest;
  v_cms_rows integer;
  v_cms_all_rows integer;
  v_cms_distinct integer;
  v_assigned_rows integer;
  v_campaigns integer;
  v_order_rows integer;
  v_status_counts jsonb;
  v_campaign_counts jsonb;
  v_assigned_missing integer;
  v_assigned_extra integer;
  v_order_mismatches integer;
  v_preserved_context_mismatches integer;
  v_queue_visible integer;
  v_queue_assigned integer;
  v_queue_duplicates integer;
  v_queue_missing_cms integer;
  v_expected_missing integer;
  v_unexpected_visible integer;
  v_containment_nonassigned_visible integer := 0;
  v_public_staging integer;
begin
  perform set_config('statement_timeout','300000',true);
  select * into strict v_operation from issue63_ops.operation limit 1;
  select * into strict v_total from issue63_ops.file_manifest
    where operation_key=v_operation.operation_key and load_type='mensual';
  select * into strict v_assigned from issue63_ops.file_manifest
    where operation_key=v_operation.operation_key and load_type='asignado';

  select count(*)::integer,count(distinct contact_id)::integer,
         count(*) filter(where is_assigned)::integer
  into v_cms_rows,v_cms_distinct,v_assigned_rows
  from public.contact_month_state
  where period=v_operation.period and visible;
  select count(*)::integer into v_cms_all_rows
  from public.contact_month_state where period=v_operation.period;

  select coalesce(jsonb_object_agg(x.estado_origen,x.n),'{}'::jsonb)
  into v_status_counts
  from (
    select estado_origen,count(*)::integer as n
    from public.contact_month_state
    where period=v_operation.period and visible
    group by estado_origen order by estado_origen
  ) x;

  select coalesce(jsonb_object_agg(x.campaign_key,x.n),'{}'::jsonb)
  into v_campaign_counts
  from (
    select ca.campaign_key,count(*)::integer as n
    from public.contact_month_state cms
    join public.campaigns ca on ca.campaign_id=cms.campaign_id
    where cms.period=v_operation.period and cms.visible
    group by ca.campaign_key order by ca.campaign_key
  ) x;

  select count(*)::integer into v_assigned_missing
  from issue63_ops.stage_rows a
  join public.contacts c on c.rut_norm=a.rut_norm
  join public.campaigns ca
    on ca.period=v_operation.period and ca.campaign_key=a.campaign_key
  left join public.contact_month_state cms
    on cms.contact_id=c.contact_id and cms.campaign_id=ca.campaign_id
   and cms.period=v_operation.period and cms.visible and cms.is_assigned
  where a.operation_key=v_operation.operation_key
    and a.load_type='asignado' and cms.cms_id is null;

  select count(*)::integer into v_assigned_extra
  from public.contact_month_state cms
  join public.contacts c on c.contact_id=cms.contact_id
  join public.campaigns ca on ca.campaign_id=cms.campaign_id
  left join issue63_ops.stage_rows a
    on a.operation_key=v_operation.operation_key and a.load_type='asignado'
   and a.rut_norm=c.rut_norm and a.campaign_key=ca.campaign_key
  where cms.period=v_operation.period and cms.visible and cms.is_assigned
    and a.rut_norm is null;

  select count(*)::integer into v_order_mismatches
  from issue63_ops.stage_rows t
  join public.contacts c on c.rut_norm=t.rut_norm
  left join public.monthly_source_order m
    on m.period=v_operation.period and m.contact_id=c.contact_id
  where t.operation_key=v_operation.operation_key and t.load_type='mensual'
    and (m.contact_id is null or m.source_row<>t.source_order
      or m.source_file<>v_total.file_name or m.source_sha256<>v_total.xlsx_sha256);

  select count(*)::integer into v_preserved_context_mismatches
  from issue63_ops.snapshot_work_queue s
  join public.work_queue w on w.work_item_id=s.work_item_id
  where s.operation_key=v_operation.operation_key
    and (w.estado_gestion,w.ingreso_estimado,w.comentarios,
         w.recordatorio_titulo,w.recordatorio_fecha_hora,w.created_at)
      is distinct from
        (s.estado_gestion,s.ingreso_estimado,s.comentarios,
         s.recordatorio_titulo,s.recordatorio_fecha_hora,s.created_at);

  select count(*)::integer into v_campaigns
  from public.campaigns where period=v_operation.period;
  select count(*)::integer into v_order_rows
  from public.monthly_source_order where period=v_operation.period;
  select count(*)::integer,
         count(*) filter(where origen='asignado')::integer
  into v_queue_visible,v_queue_assigned
  from public.work_queue
  where period=v_operation.period and visible;
  select count(*)::integer into v_queue_duplicates
  from (
    select contact_id from public.work_queue
    where period=v_operation.period
    group by contact_id having count(*)>1
  ) d;
  select count(*)::integer into v_queue_missing_cms
  from public.work_queue w
  left join public.contact_month_state cms on cms.cms_id=w.cms_id
  where w.period=v_operation.period and w.visible and cms.cms_id is null;
  select count(*)::integer into v_public_staging from public.staging_contacts;

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

  drop table if exists pg_temp.issue63_expected_queue;
  create temporary table issue63_expected_queue on commit drop as
  select e.contact_id
  from public.contact_eligibility_for_period(v_operation.period) e
  where e.is_gestionable
    and (e.assigned_current or not exists (
      select 1 from pg_temp.issue63_contained c where c.contact_id=e.contact_id
    ));

  create unique index issue63_expected_queue_contact_idx on pg_temp.issue63_expected_queue(contact_id);

  select count(*)::integer into v_expected_missing
  from pg_temp.issue63_expected_queue e
  left join public.work_queue w
    on w.contact_id=e.contact_id and w.period=v_operation.period and w.visible
  where w.contact_id is null;

  select count(*)::integer into v_unexpected_visible
  from public.work_queue w
  left join pg_temp.issue63_expected_queue e on e.contact_id=w.contact_id
  where w.period=v_operation.period and w.visible and e.contact_id is null;

  select count(*)::integer into v_containment_nonassigned_visible
  from public.work_queue w
  join pg_temp.issue63_contained c on c.contact_id=w.contact_id
  where w.period=v_operation.period and w.visible and w.origen<>'asignado';

  if public.active_period() <> v_operation.period
     or v_cms_rows <> v_total.expected_rows
     or v_cms_all_rows <> v_total.expected_rows
     or v_cms_distinct <> v_total.expected_distinct_ruts
     or v_assigned_rows <> v_assigned.expected_rows
     or v_status_counts <> v_total.expected_status_counts
     or v_campaign_counts <> v_total.expected_campaign_counts
     or v_assigned_missing <> 0
     or v_assigned_extra <> 0
     or v_campaigns <> (select count(*) from jsonb_object_keys(v_total.expected_campaign_counts))
     or v_order_rows <> v_total.expected_distinct_ruts
     or v_order_mismatches <> 0
     or v_preserved_context_mismatches <> 0
     or v_queue_assigned <> v_assigned.expected_rows
     or v_queue_duplicates <> 0
     or v_queue_missing_cms <> 0
     or v_expected_missing <> 0
     or v_unexpected_visible <> 0
     or v_containment_nonassigned_visible <> 0
     or v_public_staging <> 0 then
    raise exception 'Issue #63 applied-state validation failed'
      using detail=jsonb_build_object(
        'active_period',public.active_period(),
        'cms_rows',v_cms_rows,
        'cms_all_rows',v_cms_all_rows,
        'cms_distinct',v_cms_distinct,
        'assigned_rows',v_assigned_rows,
        'status_counts',v_status_counts,
        'campaign_counts',v_campaign_counts,
        'assigned_missing',v_assigned_missing,
        'assigned_extra',v_assigned_extra,
        'campaigns',v_campaigns,
        'order_rows',v_order_rows,
        'order_mismatches',v_order_mismatches,
        'preserved_context_mismatches',v_preserved_context_mismatches,
        'queue_visible',v_queue_visible,
        'queue_assigned',v_queue_assigned,
        'queue_duplicates',v_queue_duplicates,
        'queue_missing_cms',v_queue_missing_cms,
        'expected_missing',v_expected_missing,
        'unexpected_visible',v_unexpected_visible,
        'containment_nonassigned_visible',v_containment_nonassigned_visible,
        'public_staging',v_public_staging
      )::text,
      errcode='55000';
  end if;

  return jsonb_build_object(
    'ok',true,
    'period',v_operation.period,
    'active_period',public.active_period(),
    'cms_rows',v_cms_rows,
    'cms_all_rows',v_cms_all_rows,
    'cms_distinct_contacts',v_cms_distinct,
    'assigned_rows',v_assigned_rows,
    'status_counts',v_status_counts,
    'campaign_counts',v_campaign_counts,
    'assigned_missing',v_assigned_missing,
    'assigned_extra',v_assigned_extra,
    'campaigns',v_campaigns,
    'monthly_source_order_rows',v_order_rows,
    'monthly_source_order_mismatches',v_order_mismatches,
    'preserved_context_mismatches',v_preserved_context_mismatches,
    'queue_visible',v_queue_visible,
    'queue_assigned',v_queue_assigned,
    'queue_rule',v_queue_visible-v_queue_assigned,
    'queue_duplicates',v_queue_duplicates,
    'queue_missing_cms',v_queue_missing_cms,
    'containment_nonassigned_visible',v_containment_nonassigned_visible,
    'public_staging_rows',v_public_staging
  );
end
$function$;

revoke all on function issue63_ops.validate_applied() from public, anon, authenticated;
