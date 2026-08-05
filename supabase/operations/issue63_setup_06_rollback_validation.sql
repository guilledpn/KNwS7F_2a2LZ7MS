-- Parte 6/7 · validación del rollback contractual.
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
  v_public_staging integer;
begin
  select * into strict v_operation from issue63_ops.operation limit 1;

  select count(*)::integer into v_contacts_mismatch
  from issue63_ops.snapshot_contacts snapshot
  left join public.contacts current on current.contact_id=snapshot.contact_id
  where snapshot.operation_key=v_operation.operation_key
    and (
      current.contact_id is null
      or (current.rut_norm,current.rut,current.nombre,current.telefono_1,
          current.telefono_2,current.telefono_3,current.email,current.telefono_activo_idx)
        is distinct from
         (snapshot.rut_norm,snapshot.rut,snapshot.nombre,snapshot.telefono_1,
          snapshot.telefono_2,snapshot.telefono_3,snapshot.email,snapshot.telefono_activo_idx)
    );

  select count(*)::integer into v_new_contacts_remaining
  from issue63_ops.stage_rows staged
  join public.contacts current on current.rut_norm=staged.rut_norm
  left join issue63_ops.snapshot_contacts snapshot
    on snapshot.operation_key=v_operation.operation_key
   and snapshot.rut_norm=staged.rut_norm
  where staged.operation_key=v_operation.operation_key
    and staged.load_type='mensual'
    and snapshot.rut_norm is null;

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
  ) differences;

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
  ) differences;

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
  ) differences;

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
  ) differences;

  select count(*)::integer into v_runs_mismatch from (
    (select run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
     from public.crm_import_runs
     where period=v_operation.period
       and file_name in (select file_name from issue63_ops.file_manifest)
     except
     select run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
     from issue63_ops.snapshot_import_runs where operation_key=v_operation.operation_key)
    union all
    (select run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
     from issue63_ops.snapshot_import_runs where operation_key=v_operation.operation_key
     except
     select run_id,file_name,load_type,period,row_count,distinct_ruts,status,result,created_at,updated_at
     from public.crm_import_runs
     where period=v_operation.period
       and file_name in (select file_name from issue63_ops.file_manifest))
  ) differences;

  select count(*)::integer into v_progress_mismatch from (
    (select file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
     from public.crm_import_progress
     where period=v_operation.period
       and file_name in (select file_name from issue63_ops.file_manifest)
     except
     select file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
     from issue63_ops.snapshot_import_progress where operation_key=v_operation.operation_key)
    union all
    (select file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
     from issue63_ops.snapshot_import_progress where operation_key=v_operation.operation_key
     except
     select file_name,load_type,period,total_rows,processed_rows,status,last_error,created_at,updated_at
     from public.crm_import_progress
     where period=v_operation.period
       and file_name in (select file_name from issue63_ops.file_manifest))
  ) differences;

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
     or v_public_staging <> (v_operation.expected_prior->>'public_staging_rows')::integer then
    raise exception 'Issue #63 rollback validation failed' using errcode='55000';
  end if;

  return jsonb_build_object(
    'ok',true,
    'period',v_operation.period,
    'active_period',public.active_period(),
    'contacts_business_mismatch',v_contacts_mismatch,
    'new_contacts_remaining',v_new_contacts_remaining,
    'campaigns_mismatch',v_campaigns_mismatch,
    'cms_mismatch',v_cms_mismatch,
    'monthly_order_mismatch',v_order_mismatch,
    'queue_mismatch',v_queue_mismatch,
    'runs_mismatch',v_runs_mismatch,
    'progress_mismatch',v_progress_mismatch,
    'public_staging_rows',v_public_staging,
    'technical_identity_not_required',jsonb_build_array(
      'contacts.search_text','contacts.updated_at','sequence gaps','guardrail events'
    )
  );
end
$function$;

