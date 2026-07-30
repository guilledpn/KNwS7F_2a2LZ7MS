-- Issue #22/#24 · prueba transaccional de muestras de análisis.
-- Ejecutar en un ambiente de prueba con permisos de propietario.

begin;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);

do $test$
declare
  v_sample_id uuid;
  v_item_id uuid;
  v_work_item_id uuid;
  v_contact_id uuid;
  v_cms_id uuid;
  v_campaign_id uuid;
  v_before jsonb;
  v_completed jsonb;
  v_after jsonb;
  v_corrected jsonb;
  v_after_correction jsonb;
begin
  select work_item_id, contact_id, cms_id, campaign_id
    into v_work_item_id, v_contact_id, v_cms_id, v_campaign_id
  from public.work_queue
  limit 1;

  if v_work_item_id is null then
    raise exception 'Fixture requires at least one work_queue row';
  end if;

  insert into public.crm_analysis_samples(sample_key,title,target_count)
  values ('TEST_ANALYSIS_SAMPLE_20260730','Fixture análisis',1)
  returning sample_id into v_sample_id;

  insert into public.crm_analysis_sample_items(
    sample_id,contact_id,work_item_id,source_cms_id,source_campaign_id,
    source_period,source_import_order,source_campaign_size,target_percentile,
    actual_percentile,stratum_key,sample_sequence
  ) values (
    v_sample_id,v_contact_id,v_work_item_id,v_cms_id,v_campaign_id,
    '2026-07',1,1,0.5,0.5,'fixture_p50',1
  ) returning sample_item_id into v_item_id;

  v_before := public.get_analysis_sample_v1('TEST_ANALYSIS_SAMPLE_20260730',true,200,0);
  if coalesce((v_before->>'ok')::boolean,false) is not true
     or (v_before->>'sample_pending')::integer <> 1
     or jsonb_array_length(v_before->'rows') <> 1 then
    raise exception 'Unexpected sample before completion: %', v_before;
  end if;

  if coalesce(v_before->'rows'->0->>'campaign_name','x') <> ''
     or coalesce(v_before->'rows'->0->>'campaign_desc','x') <> '' then
    raise exception 'Capture RPC leaks campaign context: %', v_before;
  end if;

  v_completed := public.complete_analysis_sample_item_v1(v_item_id,2575334);
  if coalesce((v_completed->>'ok')::boolean,false) is not true
     or (v_completed->>'sample_completed')::integer <> 1
     or (v_completed->>'sample_pending')::integer <> 0 then
    raise exception 'Unexpected completion response: %', v_completed;
  end if;

  v_after := public.get_analysis_sample_v1('TEST_ANALYSIS_SAMPLE_20260730',false,200,0);
  if v_after->>'status' <> 'completed'
     or (v_after->'rows'->0->>'sample_captured_income')::numeric <> 2575334 then
    raise exception 'Unexpected sample after completion: %', v_after;
  end if;

  -- Issue #24: una muestra ya completada debe permitir corregir una observación.
  v_corrected := public.complete_analysis_sample_item_v1(v_item_id,3123456);
  if coalesce((v_corrected->>'ok')::boolean,false) is not true
     or (v_corrected->>'sample_completed')::integer <> 1
     or (v_corrected->>'sample_pending')::integer <> 0 then
    raise exception 'Unexpected correction response: %', v_corrected;
  end if;

  v_after_correction := public.get_analysis_sample_v1('TEST_ANALYSIS_SAMPLE_20260730',false,200,0);
  if v_after_correction->>'status' <> 'completed'
     or (v_after_correction->'rows'->0->>'sample_captured_income')::numeric <> 3123456 then
    raise exception 'Correction was not preserved: %', v_after_correction;
  end if;
end
$test$;

rollback;
