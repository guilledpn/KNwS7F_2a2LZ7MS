-- Parte 5/7 · mutación, validación y trazabilidad de aplicación.
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
    email=excluded.email
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
    campaign_desc=excluded.campaign_desc;

  with total_rows as (
    select total.*,assigned.source_order as assigned_order
    from issue63_ops.stage_rows total
    left join issue63_ops.stage_rows assigned
      on assigned.operation_key=total.operation_key
     and assigned.load_type='asignado'
     and assigned.rut_norm=total.rut_norm
     and assigned.campaign_key=total.campaign_key
    where total.operation_key=v_operation.operation_key
      and total.load_type='mensual'
  )
  insert into public.contact_month_state(
    contact_id,campaign_id,period,source_priority,import_order,
    is_assigned,visible,last_seen_at,estado_origen
  )
  select
    c.contact_id,ca.campaign_id,v_operation.period,
    case when src.assigned_order is null then 1 else 9999 end,
    coalesce(src.assigned_order,src.source_order),
    src.assigned_order is not null,true,now(),src.estado_origen
  from total_rows src
  join public.contacts c on c.rut_norm=src.rut_norm
  join public.campaigns ca
    on ca.period=v_operation.period and ca.campaign_key=src.campaign_key
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
    v_operation.period,c.contact_id,total.source_order,v_session,
    v_total.file_name,v_total.xlsx_sha256,now()
  from issue63_ops.stage_rows total
  join public.contacts c on c.rut_norm=total.rut_norm
  where total.operation_key=v_operation.operation_key and total.load_type='mensual';

  update public.work_queue
     set visible=false
   where period=v_operation.period and visible;

  drop table if exists pg_temp.issue63_contained;
  create temporary table issue63_contained(contact_id uuid primary key) on commit drop;
  insert into pg_temp.issue63_contained(contact_id)
  select distinct (row_value->>'contact_id')::uuid
  from public.crm_guardrail_events e,
       lateral jsonb_array_elements(e.details->'rows') row_value
  where e.event_id=(v_operation.expected_prior->>'containment_event_id')::bigint
    and e.details->>'snapshot_id'=v_operation.expected_prior->>'containment_snapshot_id';

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
    display_order=excluded.display_order;

  delete from public.crm_import_runs current
  using issue63_ops.file_manifest manifest
  where manifest.operation_key=v_operation.operation_key
    and current.file_name=manifest.file_name
    and current.load_type=manifest.load_type
    and current.period=v_operation.period;

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
  where m.operation_key=v_operation.operation_key;

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
  update issue63_ops.operation set result=v_validation
  where operation_key=v_operation.operation_key;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue63_august_revision_02_applied',
    'warning',
    jsonb_build_object(
      'issue',63,
      'operation_key',v_operation.operation_key,
      'period',v_operation.period,
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

