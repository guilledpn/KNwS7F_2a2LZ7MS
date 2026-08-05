-- Parte 7/7 · rollback contractual y permisos finales.
create or replace function issue63_ops.rollback_operation()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_new_contacts_with_external_refs integer;
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

  if exists (select 1 from public.crm_log where created_at > v_operation.applied_at)
     or exists (select 1 from public.crm_events where created_at > v_operation.applied_at)
     or exists (
       select 1 from public.work_queue
       where period=v_operation.period and updated_at > v_operation.applied_at
     )
     or exists (
       select 1
       from public.contacts current
       join issue63_ops.stage_rows staged
         on staged.operation_key=v_operation.operation_key
        and staged.load_type='mensual'
        and staged.rut_norm=current.rut_norm
       where current.updated_at > v_operation.applied_at
     )
     or exists (
       select 1 from public.crm_import_runs current
       join issue63_ops.file_manifest manifest
         on manifest.operation_key=v_operation.operation_key
        and manifest.file_name=current.file_name
        and manifest.load_type=current.load_type
        and current.period=v_operation.period
       where current.updated_at > v_operation.applied_at
     )
     or exists (
       select 1 from public.crm_import_progress current
       join issue63_ops.file_manifest manifest
         on manifest.operation_key=v_operation.operation_key
        and manifest.file_name=current.file_name
        and manifest.load_type=current.load_type
        and current.period=v_operation.period
       where current.updated_at > v_operation.applied_at
     ) then
    raise exception 'Rollback blocked: PROD received writes after the Issue #63 apply'
      using errcode='55000';
  end if;

  if exists (
    select 1
    from public.crm_analysis_sample_items sample
    left join public.work_queue queue on queue.work_item_id=sample.work_item_id
    left join public.contact_month_state cms on cms.cms_id=sample.source_cms_id
    left join public.campaigns campaign on campaign.campaign_id=sample.source_campaign_id
    where queue.period=v_operation.period
       or cms.period=v_operation.period
       or campaign.period=v_operation.period
  ) then
    raise exception 'Rollback blocked: August entities acquired analysis references'
      using errcode='55000';
  end if;

  select count(*)::integer into v_new_contacts_with_external_refs
  from public.contacts current
  join issue63_ops.stage_rows staged
    on staged.operation_key=v_operation.operation_key
   and staged.load_type='mensual'
   and staged.rut_norm=current.rut_norm
  left join issue63_ops.snapshot_contacts snapshot
    on snapshot.operation_key=v_operation.operation_key
   and snapshot.contact_id=current.contact_id
  where snapshot.contact_id is null
    and (
      exists(select 1 from public.crm_log log where log.contact_id=current.contact_id)
      or exists(select 1 from public.crm_events event where event.contact_id=current.contact_id)
      or exists(select 1 from public.crm_analysis_sample_items sample
                where sample.contact_id=current.contact_id)
    );
  if v_new_contacts_with_external_refs <> 0 then
    raise exception 'Rollback blocked: new contacts acquired external references'
      using errcode='55000';
  end if;

  delete from public.work_queue where period=v_operation.period;
  delete from public.monthly_source_order where period=v_operation.period;
  delete from public.contact_month_state where period=v_operation.period;
  delete from public.campaigns where period=v_operation.period;

  update public.contacts current set
    rut_norm=snapshot.rut_norm,
    rut=snapshot.rut,
    nombre=snapshot.nombre,
    telefono_1=snapshot.telefono_1,
    telefono_2=snapshot.telefono_2,
    telefono_3=snapshot.telefono_3,
    email=snapshot.email,
    telefono_activo_idx=snapshot.telefono_activo_idx
  from issue63_ops.snapshot_contacts snapshot
  where snapshot.operation_key=v_operation.operation_key
    and snapshot.contact_id=current.contact_id;

  delete from public.contacts current
  using issue63_ops.stage_rows staged
  left join issue63_ops.snapshot_contacts snapshot
    on snapshot.operation_key=v_operation.operation_key
   and snapshot.rut_norm=staged.rut_norm
  where staged.operation_key=v_operation.operation_key
    and staged.load_type='mensual'
    and current.rut_norm=staged.rut_norm
    and snapshot.rut_norm is null;

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

  delete from public.crm_import_runs current
  using issue63_ops.file_manifest manifest
  where manifest.operation_key=v_operation.operation_key
    and current.file_name=manifest.file_name
    and current.load_type=manifest.load_type
    and current.period=v_operation.period;
  insert into public.crm_import_runs(
    run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
  )
  select run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
  from issue63_ops.snapshot_import_runs
  where operation_key=v_operation.operation_key;

  delete from public.crm_import_progress current
  using issue63_ops.file_manifest manifest
  where manifest.operation_key=v_operation.operation_key
    and current.file_name=manifest.file_name
    and current.load_type=manifest.load_type
    and current.period=v_operation.period;
  insert into public.crm_import_progress(
    file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
  )
  select file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
  from issue63_ops.snapshot_import_progress
  where operation_key=v_operation.operation_key;

  v_validation := issue63_ops.validate_rollback();
  update issue63_ops.operation
     set status='rolled_back',rolled_back_at=clock_timestamp(),result=v_validation
   where operation_key=v_operation.operation_key;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue63_august_revision_02_rolled_back',
    'warning',
    v_validation || jsonb_build_object(
      'issue',63,
      'operation_key',v_operation.operation_key,
      'audit_trail','guardrail events intentionally preserved'
    )
  );
  return v_validation;
end
$function$;

revoke all on function issue63_ops.require_operation(text)
  from public, anon, authenticated;
revoke all on function issue63_ops.configure_operation(text,text,text,timestamptz,jsonb,jsonb)
  from public, anon, authenticated;
revoke all on function issue63_ops.contiguous_rows(text,text,integer)
  from public, anon, authenticated;
revoke all on function issue63_ops.validate_stage()
  from public, anon, authenticated;
revoke all on function issue63_ops.validate_applied()
  from public, anon, authenticated;
revoke all on function issue63_ops.apply_operation()
  from public, anon, authenticated;
revoke all on function issue63_ops.validate_rollback()
  from public, anon, authenticated;
revoke all on function issue63_ops.rollback_operation()
  from public, anon, authenticated;

revoke all on function public.crm_issue63_stage_chunk(
  text,text,text,text,text,integer,text,text
) from public, anon, authenticated;
grant execute on function public.crm_issue63_stage_chunk(
  text,text,text,text,text,integer,text,text
) to anon;

revoke all on function public.crm_issue63_status(text)
  from public, anon, authenticated;
grant execute on function public.crm_issue63_status(text) to anon;
