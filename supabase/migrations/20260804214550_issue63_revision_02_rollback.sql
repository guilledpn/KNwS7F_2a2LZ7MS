-- Issue #63 · funciones administrativas; no ejecutan la operación al crearse.

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
begin
  perform set_config('statement_timeout','900000',true);
  select * into strict v_operation from issue63_ops.operation limit 1 for update;
  if v_operation.status <> 'applied' then
    raise exception 'Rollback requires applied status; current=%',v_operation.status
      using errcode='55000';
  end if;

  if exists (
    select 1 from public.crm_log where created_at > v_operation.applied_at
  ) or exists (
    select 1 from public.crm_events where created_at > v_operation.applied_at
  ) or exists (
    select 1 from public.work_queue
    where period=v_operation.period and updated_at > v_operation.applied_at
  ) then
    raise exception 'Rollback blocked: PROD received writes after the Issue #63 apply'
      using errcode='55000';
  end if;

  lock table public.contacts in share row exclusive mode;
  lock table public.campaigns in share row exclusive mode;
  lock table public.contact_month_state in share row exclusive mode;
  lock table public.monthly_source_order in share row exclusive mode;
  lock table public.work_queue in share row exclusive mode;
  lock table public.crm_import_runs in share row exclusive mode;
  lock table public.crm_import_progress in share row exclusive mode;

  delete from public.work_queue where period=v_operation.period;
  delete from public.monthly_source_order where period=v_operation.period;
  delete from public.contact_month_state where period=v_operation.period;
  delete from public.campaigns where period=v_operation.period;

  update public.contacts c set
    rut=s.rut,
    nombre=s.nombre,
    telefono_1=s.telefono_1,
    telefono_2=s.telefono_2,
    telefono_3=s.telefono_3,
    email=s.email,
    telefono_activo_idx=s.telefono_activo_idx
  from issue63_ops.snapshot_contacts s
  where s.operation_key=v_operation.operation_key and s.contact_id=c.contact_id;

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

  update issue63_ops.operation
     set status='rolled_back',rolled_back_at=clock_timestamp(),
         result=jsonb_build_object(
           'ok',true,
           'period',v_operation.period,
           'active_period',public.active_period(),
           'rollback','completed'
         )
   where operation_key=v_operation.operation_key;

  v_result := jsonb_build_object(
    'ok',true,
    'issue',63,
    'operation_key',v_operation.operation_key,
    'status','rolled_back',
    'period',v_operation.period,
    'active_period',public.active_period()
  );

  insert into public.crm_guardrail_events(event_type,severity,details)
  values('issue63_august_revision_02_rolled_back','warning',v_result);
  return v_result;
end
$function$;

revoke all on function issue63_ops.rollback_operation() from public, anon, authenticated;
