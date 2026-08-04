-- Issue #63 · funciones administrativas; no ejecutan la operación al crearse.

create or replace function issue63_ops.validate_rollback()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_contacts_mismatch integer;
  v_new_contacts_remaining integer;
  v_campaigns_mismatch integer;
  v_cms_mismatch integer;
  v_order_mismatch integer;
  v_queue_mismatch integer;
  v_runs_mismatch integer;
  v_progress_mismatch integer;
  v_sequence_mismatch integer;
  v_public_staging integer;
begin
  select * into strict v_operation from issue63_ops.operation limit 1;

  select count(*)::integer into v_contacts_mismatch
  from issue63_ops.snapshot_contacts s
  left join public.contacts c on c.contact_id=s.contact_id
  where s.operation_key=v_operation.operation_key
    and (
      c.contact_id is null
      or (c.rut_norm,c.rut,c.nombre,c.telefono_1,c.telefono_2,c.telefono_3,
          c.email,c.telefono_activo_idx,c.search_text,c.created_at,c.updated_at)
        is distinct from
         (s.rut_norm,s.rut,s.nombre,s.telefono_1,s.telefono_2,s.telefono_3,
          s.email,s.telefono_activo_idx,s.search_text,s.created_at,s.updated_at)
    );

  select count(*)::integer into v_new_contacts_remaining
  from issue63_ops.stage_rows st
  join public.contacts c on c.rut_norm=st.rut_norm
  left join issue63_ops.snapshot_contacts s
    on s.operation_key=v_operation.operation_key and s.rut_norm=st.rut_norm
  where st.operation_key=v_operation.operation_key
    and st.load_type='mensual'
    and s.rut_norm is null;

  select count(*)::integer into v_campaigns_mismatch from (
    (select campaign_id,period,campaign_key,campaign_name,campaign_desc,created_at
     from public.campaigns where period=v_operation.period
     except
     select campaign_id,period,campaign_key,campaign_name,campaign_desc,created_at
     from issue63_ops.snapshot_campaigns where operation_key=v_operation.operation_key)
    union all
    (select campaign_id,period,campaign_key,campaign_name,campaign_desc,created_at
     from issue63_ops.snapshot_campaigns where operation_key=v_operation.operation_key
     except
     select campaign_id,period,campaign_key,campaign_name,campaign_desc,created_at
     from public.campaigns where period=v_operation.period)
  ) q;

  select count(*)::integer into v_cms_mismatch from (
    (select cms_id,contact_id,campaign_id,period,source_priority,import_order,
            is_assigned,visible,last_seen_at,created_at,estado_origen
     from public.contact_month_state where period=v_operation.period
     except
     select cms_id,contact_id,campaign_id,period,source_priority,import_order,
            is_assigned,visible,last_seen_at,created_at,estado_origen
     from issue63_ops.snapshot_cms where operation_key=v_operation.operation_key)
    union all
    (select cms_id,contact_id,campaign_id,period,source_priority,import_order,
            is_assigned,visible,last_seen_at,created_at,estado_origen
     from issue63_ops.snapshot_cms where operation_key=v_operation.operation_key
     except
     select cms_id,contact_id,campaign_id,period,source_priority,import_order,
            is_assigned,visible,last_seen_at,created_at,estado_origen
     from public.contact_month_state where period=v_operation.period)
  ) q;

  select count(*)::integer into v_order_mismatch from (
    (select period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
     from public.monthly_source_order where period=v_operation.period
     except
     select period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
     from issue63_ops.snapshot_monthly_order where operation_key=v_operation.operation_key)
    union all
    (select period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
     from issue63_ops.snapshot_monthly_order where operation_key=v_operation.operation_key
     except
     select period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
     from public.monthly_source_order where period=v_operation.period)
  ) q;

  select count(*)::integer into v_queue_mismatch from (
    (select work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,
            display_order,estado_gestion,ingreso_estimado,comentarios,
            recordatorio_titulo,recordatorio_fecha_hora,created_at,updated_at
     from public.work_queue where period=v_operation.period
     except
     select work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,
            display_order,estado_gestion,ingreso_estimado,comentarios,
            recordatorio_titulo,recordatorio_fecha_hora,created_at,updated_at
     from issue63_ops.snapshot_work_queue where operation_key=v_operation.operation_key)
    union all
    (select work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,
            display_order,estado_gestion,ingreso_estimado,comentarios,
            recordatorio_titulo,recordatorio_fecha_hora,created_at,updated_at
     from issue63_ops.snapshot_work_queue where operation_key=v_operation.operation_key
     except
     select work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,
            display_order,estado_gestion,ingreso_estimado,comentarios,
            recordatorio_titulo,recordatorio_fecha_hora,created_at,updated_at
     from public.work_queue where period=v_operation.period)
  ) q;

  select count(*)::integer into v_runs_mismatch from (
    (select r.run_id,r.file_name,r.load_type,r.period,r.row_count,r.distinct_ruts,
            r.status,r.result,r.created_at,r.updated_at
     from public.crm_import_runs r
     join issue63_ops.file_manifest m
       on m.operation_key=v_operation.operation_key
      and m.file_name=r.file_name and m.load_type=r.load_type and r.period=v_operation.period
     except
     select run_id,file_name,load_type,period,row_count,distinct_ruts,
            status,result,created_at,updated_at
     from issue63_ops.snapshot_import_runs where operation_key=v_operation.operation_key)
    union all
    (select run_id,file_name,load_type,period,row_count,distinct_ruts,
            status,result,created_at,updated_at
     from issue63_ops.snapshot_import_runs where operation_key=v_operation.operation_key
     except
     select r.run_id,r.file_name,r.load_type,r.period,r.row_count,r.distinct_ruts,
            r.status,r.result,r.created_at,r.updated_at
     from public.crm_import_runs r
     join issue63_ops.file_manifest m
       on m.operation_key=v_operation.operation_key
      and m.file_name=r.file_name and m.load_type=r.load_type and r.period=v_operation.period)
  ) q;

  select count(*)::integer into v_progress_mismatch from (
    (select p.file_name,p.load_type,p.period,p.total_rows,p.processed_rows,
            p.status,p.last_error,p.created_at,p.updated_at
     from public.crm_import_progress p
     join issue63_ops.file_manifest m
       on m.operation_key=v_operation.operation_key
      and m.file_name=p.file_name and m.load_type=p.load_type and p.period=v_operation.period
     except
     select file_name,load_type,period,total_rows,processed_rows,
            status,last_error,created_at,updated_at
     from issue63_ops.snapshot_import_progress where operation_key=v_operation.operation_key)
    union all
    (select file_name,load_type,period,total_rows,processed_rows,
            status,last_error,created_at,updated_at
     from issue63_ops.snapshot_import_progress where operation_key=v_operation.operation_key
     except
     select p.file_name,p.load_type,p.period,p.total_rows,p.processed_rows,
            p.status,p.last_error,p.created_at,p.updated_at
     from public.crm_import_progress p
     join issue63_ops.file_manifest m
       on m.operation_key=v_operation.operation_key
      and m.file_name=p.file_name and m.load_type=p.load_type and p.period=v_operation.period)
  ) q;

  select count(*)::integer into v_sequence_mismatch
  from issue63_ops.snapshot_sequences s
  where s.operation_key=v_operation.operation_key
    and s.sequence_name='public.crm_import_runs_run_id_seq'
    and not exists (
      select 1 from public.crm_import_runs_run_id_seq q
      where q.last_value=s.last_value and q.is_called=s.is_called
    );

  select count(*)::integer into v_public_staging from public.staging_contacts;

  if public.active_period() <> v_operation.expected_prior->>'active_period'
     or v_contacts_mismatch <> 0
     or v_new_contacts_remaining <> 0
     or v_campaigns_mismatch <> 0
     or v_cms_mismatch <> 0
     or v_order_mismatch <> 0
     or v_queue_mismatch <> 0
     or v_runs_mismatch <> 0
     or v_progress_mismatch <> 0
     or v_sequence_mismatch <> 0
     or v_public_staging <> (v_operation.expected_prior->>'public_staging_rows')::integer then
    raise exception 'Issue #63 rollback validation failed'
      using detail=jsonb_build_object(
        'active_period',public.active_period(),
        'contacts_mismatch',v_contacts_mismatch,
        'new_contacts_remaining',v_new_contacts_remaining,
        'campaigns_mismatch',v_campaigns_mismatch,
        'cms_mismatch',v_cms_mismatch,
        'monthly_order_mismatch',v_order_mismatch,
        'queue_mismatch',v_queue_mismatch,
        'runs_mismatch',v_runs_mismatch,
        'progress_mismatch',v_progress_mismatch,
        'sequence_mismatch',v_sequence_mismatch,
        'public_staging',v_public_staging
      )::text,
      errcode='55000';
  end if;

  return jsonb_build_object(
    'ok',true,
    'period',v_operation.period,
    'active_period',public.active_period(),
    'contacts_mismatch',v_contacts_mismatch,
    'new_contacts_remaining',v_new_contacts_remaining,
    'campaigns_mismatch',v_campaigns_mismatch,
    'cms_mismatch',v_cms_mismatch,
    'monthly_order_mismatch',v_order_mismatch,
    'queue_mismatch',v_queue_mismatch,
    'runs_mismatch',v_runs_mismatch,
    'progress_mismatch',v_progress_mismatch,
    'sequence_mismatch',v_sequence_mismatch,
    'public_staging_rows',v_public_staging
  );
end
$function$;

create or replace function issue63_ops.rollback_operation()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_new_contacts_with_external_refs integer;
  v_result jsonb;
  v_validation jsonb;
begin
  perform set_config('statement_timeout','900000',true);
  select * into strict v_operation from issue63_ops.operation limit 1 for update;
  if v_operation.status <> 'applied' then
    raise exception 'Rollback requires applied status; current=%',v_operation.status
      using errcode='55000';
  end if;

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

  perform issue63_ops.validate_applied();

  if exists (
    select 1 from public.crm_log where created_at > v_operation.applied_at
  ) or exists (
    select 1 from public.crm_events where created_at > v_operation.applied_at
  ) or exists (
    select 1 from public.work_queue
    where period=v_operation.period and updated_at > v_operation.applied_at
  ) or exists (
    select 1
    from public.contacts c
    join issue63_ops.stage_rows st
      on st.operation_key=v_operation.operation_key
     and st.load_type='mensual' and st.rut_norm=c.rut_norm
    where c.updated_at > v_operation.applied_at
  ) or exists (
    select 1 from public.crm_import_runs r
    join issue63_ops.file_manifest m
      on m.operation_key=v_operation.operation_key
     and m.file_name=r.file_name and m.load_type=r.load_type and r.period=v_operation.period
    where r.updated_at > v_operation.applied_at
  ) or exists (
    select 1 from public.crm_import_progress p
    join issue63_ops.file_manifest m
      on m.operation_key=v_operation.operation_key
     and m.file_name=p.file_name and m.load_type=p.load_type and p.period=v_operation.period
    where p.updated_at > v_operation.applied_at
  ) then
    raise exception 'Rollback blocked: PROD received writes after the Issue #63 apply'
      using errcode='55000';
  end if;

  if exists (
    select 1
    from public.crm_analysis_sample_items a
    join public.work_queue w on w.work_item_id=a.work_item_id
    where w.period=v_operation.period
  ) then
    raise exception 'Rollback blocked: period work items acquired external references'
      using errcode='55000';
  end if;

  select count(*)::integer into v_new_contacts_with_external_refs
  from public.contacts c
  join issue63_ops.stage_rows st
    on st.operation_key=v_operation.operation_key
   and st.load_type='mensual' and st.rut_norm=c.rut_norm
  left join issue63_ops.snapshot_contacts sc
    on sc.operation_key=v_operation.operation_key and sc.contact_id=c.contact_id
  where sc.contact_id is null
    and (
      exists(select 1 from public.crm_log l where l.contact_id=c.contact_id)
      or exists(select 1 from public.crm_events e where e.contact_id=c.contact_id)
      or exists(select 1 from public.crm_analysis_sample_items a where a.contact_id=c.contact_id)
    );
  if v_new_contacts_with_external_refs <> 0 then
    raise exception 'Rollback blocked: new contacts acquired external references'
      using errcode='55000';
  end if;

  delete from public.work_queue where period=v_operation.period;
  delete from public.monthly_source_order where period=v_operation.period;
  delete from public.contact_month_state where period=v_operation.period;
  delete from public.campaigns where period=v_operation.period;

  execute 'alter table public.contacts disable trigger trg_contacts_search';
  execute 'alter table public.contacts disable trigger trg_contacts_updated';

  update public.contacts c set
    rut_norm=s.rut_norm,
    rut=s.rut,
    nombre=s.nombre,
    telefono_1=s.telefono_1,
    telefono_2=s.telefono_2,
    telefono_3=s.telefono_3,
    email=s.email,
    telefono_activo_idx=s.telefono_activo_idx,
    search_text=s.search_text,
    created_at=s.created_at,
    updated_at=s.updated_at
  from issue63_ops.snapshot_contacts s
  where s.operation_key=v_operation.operation_key and s.contact_id=c.contact_id;

  execute 'alter table public.contacts enable trigger trg_contacts_search';
  execute 'alter table public.contacts enable trigger trg_contacts_updated';

  delete from public.contacts c
  using issue63_ops.stage_rows st
  left join issue63_ops.snapshot_contacts sc
    on sc.operation_key=v_operation.operation_key and sc.rut_norm=st.rut_norm
  where st.operation_key=v_operation.operation_key
    and st.load_type='mensual'
    and c.rut_norm=st.rut_norm
    and sc.rut_norm is null;

  insert into public.campaigns(
    campaign_id,period,campaign_key,campaign_name,campaign_desc,created_at
  )
  select campaign_id,period,campaign_key,campaign_name,campaign_desc,created_at
  from issue63_ops.snapshot_campaigns
  where operation_key=v_operation.operation_key;

  insert into public.contact_month_state(
    cms_id,contact_id,campaign_id,period,source_priority,import_order,
    is_assigned,visible,last_seen_at,created_at,estado_origen
  )
  select cms_id,contact_id,campaign_id,period,source_priority,import_order,
         is_assigned,visible,last_seen_at,created_at,estado_origen
  from issue63_ops.snapshot_cms
  where operation_key=v_operation.operation_key;

  insert into public.monthly_source_order(
    period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
  )
  select period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
  from issue63_ops.snapshot_monthly_order
  where operation_key=v_operation.operation_key;

  insert into public.work_queue(
    work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,
    display_order,estado_gestion,ingreso_estimado,comentarios,
    recordatorio_titulo,recordatorio_fecha_hora,created_at,updated_at
  )
  select work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,
         display_order,estado_gestion,ingreso_estimado,comentarios,
         recordatorio_titulo,recordatorio_fecha_hora,created_at,updated_at
  from issue63_ops.snapshot_work_queue
  where operation_key=v_operation.operation_key;

  delete from public.crm_import_runs r
  using issue63_ops.file_manifest m
  where m.operation_key=v_operation.operation_key
    and r.file_name=m.file_name and r.load_type=m.load_type and r.period=v_operation.period;
  insert into public.crm_import_runs(
    run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
  )
  select run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
  from issue63_ops.snapshot_import_runs
  where operation_key=v_operation.operation_key;

  delete from public.crm_import_progress p
  using issue63_ops.file_manifest m
  where m.operation_key=v_operation.operation_key
    and p.file_name=m.file_name and p.load_type=m.load_type and p.period=v_operation.period;
  insert into public.crm_import_progress(
    file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
  )
  select file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
  from issue63_ops.snapshot_import_progress
  where operation_key=v_operation.operation_key;

  perform pg_catalog.setval(s.sequence_name::regclass,s.last_value,s.is_called)
  from issue63_ops.snapshot_sequences s
  where s.operation_key=v_operation.operation_key
    and s.sequence_name='public.crm_import_runs_run_id_seq';

  v_validation := issue63_ops.validate_rollback();

  update issue63_ops.operation
     set status='rolled_back',rolled_back_at=clock_timestamp(),
         result=v_validation || jsonb_build_object(
           'status','rolled_back',
           'rollback','completed',
           'audit_trail','guardrail events intentionally preserved'
         )
   where operation_key=v_operation.operation_key;

  v_result := v_validation || jsonb_build_object(
    'issue',63,
    'operation_key',v_operation.operation_key,
    'status','rolled_back',
    'audit_trail','guardrail events intentionally preserved'
  );

  insert into public.crm_guardrail_events(event_type,severity,details)
  values('issue63_august_revision_02_rolled_back','warning',v_result);
  return v_result;
end
$function$;

revoke all on function issue63_ops.validate_rollback() from public, anon, authenticated;
revoke all on function issue63_ops.rollback_operation() from public, anon, authenticated;