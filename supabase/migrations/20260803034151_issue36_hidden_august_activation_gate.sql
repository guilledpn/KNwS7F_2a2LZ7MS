create or replace function public.crm_issue36_ingest_hidden_chunk(
  p_token text,
  p_session uuid,
  p_file_name text,
  p_load_type text,
  p_period text,
  p_start_order integer,
  p_tsv text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_token_hash text;
  v_rows integer := 0;
  v_expected_rows integer := 0;
  v_end_order integer := 0;
  v_result jsonb;
  v_hidden_cms integer := 0;
  v_hidden_queue integer := 0;
  v_total_progress integer := 0;
begin
  perform set_config('statement_timeout','120000',true);

  if now() >= timestamptz '2026-08-05 12:00:00+00' then
    raise exception 'Issue #36 operation gate expired' using errcode='42501';
  end if;
  if coalesce(auth.jwt()->>'role','') <> 'anon' then
    raise exception 'Issue #36 gate requires the expected public client role' using errcode='42501';
  end if;
  v_token_hash := encode(extensions.digest(coalesce(p_token,''), 'sha256'), 'hex');
  if v_token_hash <> '42582521c0e9378958fde3254a35a5e0c73dbe377e006269267dfb02297e1cc1' then
    raise exception 'Invalid Issue #36 operation token' using errcode='42501';
  end if;
  if p_period <> '2026-08' then
    raise exception 'Issue #36 hidden ingest is restricted to 2026-08' using errcode='22023';
  end if;

  if p_file_name = '202608_TOTAL_01_NM.xlsx' and p_load_type = 'mensual' then
    v_expected_rows := 28186;
  elsif p_file_name = '202608_ASIGNADO_01_NM.xlsx' and p_load_type = 'asignado' then
    v_expected_rows := 54;
    select coalesce(processed_rows,0) into v_total_progress
    from public.crm_import_progress
    where file_name='202608_TOTAL_01_NM.xlsx' and load_type='mensual' and period='2026-08';
    if coalesce(v_total_progress,0) <> 28186 then
      raise exception 'ASIGNADOS cannot start before TOTAL reaches 28186 rows; current progress=%', coalesce(v_total_progress,0)
        using errcode='55000';
    end if;
  else
    raise exception 'Unsupported Issue #36 file/type combination' using errcode='22023';
  end if;

  if exists (
    select 1 from public.crm_guardrail_events
    where event_type='issue36_august_activated'
      and details->>'operation'='close_july_activate_august_2026'
  ) then
    raise exception 'August Issue #36 operation is already activated' using errcode='55000';
  end if;

  select count(*)::integer into v_rows
  from regexp_split_to_table(coalesce(p_tsv,''), E'\\n') line
  where line <> '';

  if v_rows < 1 or v_rows > 100 then
    raise exception 'Hidden chunk must contain between 1 and 100 rows; received %', v_rows using errcode='22023';
  end if;

  v_end_order := p_start_order + v_rows - 1;
  if p_start_order < 1 or v_end_order > v_expected_rows then
    raise exception 'Invalid source range %-% for expected total %', p_start_order, v_end_order, v_expected_rows using errcode='22023';
  end if;

  if exists (
    select 1
    from regexp_split_to_table(p_tsv, E'\\n') line
    where line <> '' and array_length(string_to_array(line,E'\\t'),1) <> 11
  ) then
    raise exception 'Every TSV row must contain exactly 11 columns' using errcode='22023';
  end if;

  v_result := public.ingest_and_process_tsv_chunk(
    p_session,p_file_name,p_load_type,p_period,p_start_order,p_tsv
  );

  if coalesce((v_result->>'ok')::boolean,false) is not true
     or coalesce((v_result->>'rows')::integer,0) <> v_rows then
    raise exception 'Underlying ingest returned an unexpected result: %', v_result using errcode='55000';
  end if;

  update public.contact_month_state
     set visible=false
   where period='2026-08' and visible;
  get diagnostics v_hidden_cms = row_count;

  update public.work_queue
     set visible=false, updated_at=now()
   where period='2026-08' and visible;
  get diagnostics v_hidden_queue = row_count;

  if public.active_period() <> '2026-07' then
    raise exception 'Hidden ingest unexpectedly changed active period to %', public.active_period() using errcode='55000';
  end if;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values('issue36_hidden_ingest_chunk','info',jsonb_build_object(
    'issue',36,'operation','close_july_activate_august_2026',
    'file_name',p_file_name,'load_type',p_load_type,
    'start_order',p_start_order,'end_order',v_end_order,'rows',v_rows,
    'hidden_cms_rows',v_hidden_cms,'hidden_queue_rows',v_hidden_queue
  ));

  return jsonb_build_object(
    'ok',true,'issue',36,'mode','hidden_until_final_activation',
    'file_name',p_file_name,'load_type',p_load_type,'period',p_period,
    'start_order',p_start_order,'end_order',v_end_order,'rows',v_rows,
    'staging_deleted',coalesce((v_result->>'staging_deleted')::integer,0),
    'assigned_updated',coalesce((v_result->>'assigned_updated')::integer,0),
    'hidden_cms_rows',v_hidden_cms,'hidden_queue_rows',v_hidden_queue,
    'active_period',public.active_period(),'underlying',v_result
  );
end
$function$;

revoke all on function public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text) from public;
grant execute on function public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text) to anon;

create or replace function public.crm_issue36_august_control(
  p_token text,
  p_action text default 'check'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_token_hash text;
  v_staging bigint := 0;
  v_all_rows bigint := 0;
  v_distinct bigint := 0;
  v_visible bigint := 0;
  v_assigned bigint := 0;
  v_campaigns bigint := 0;
  v_gestionado bigint := 0;
  v_no_gestionado bigint := 0;
  v_progress_total integer := 0;
  v_progress_assigned integer := 0;
  v_total integer := 0;
  v_rule integer := 0;
  v_queue_assigned integer := 0;
  v_status jsonb;
  v_already_done boolean := false;
begin
  perform set_config('statement_timeout','300000',true);

  if now() >= timestamptz '2026-08-05 12:00:00+00' then
    raise exception 'Issue #36 operation gate expired' using errcode='42501';
  end if;
  if coalesce(auth.jwt()->>'role','') <> 'anon' then
    raise exception 'Issue #36 gate requires the expected public client role' using errcode='42501';
  end if;
  v_token_hash := encode(extensions.digest(coalesce(p_token,''), 'sha256'), 'hex');
  if v_token_hash <> '42582521c0e9378958fde3254a35a5e0c73dbe377e006269267dfb02297e1cc1' then
    raise exception 'Invalid Issue #36 operation token' using errcode='42501';
  end if;
  if p_action not in ('check','activate') then
    raise exception 'Unsupported Issue #36 August action: %',p_action using errcode='22023';
  end if;

  select count(*) into v_staging from public.staging_contacts;
  select count(*),count(distinct contact_id),count(*) filter(where visible),
         count(distinct contact_id) filter(where is_assigned),
         count(*) filter(where lower(trim(coalesce(estado_origen,'')))='gestionado'),
         count(*) filter(where lower(trim(coalesce(estado_origen,'')))='no gestionado')
    into v_all_rows,v_distinct,v_visible,v_assigned,v_gestionado,v_no_gestionado
  from public.contact_month_state where period='2026-08';
  select count(*) into v_campaigns from public.campaigns where period='2026-08';
  select coalesce(processed_rows,0) into v_progress_total
    from public.crm_import_progress
   where file_name='202608_TOTAL_01_NM.xlsx' and load_type='mensual' and period='2026-08';
  select coalesce(processed_rows,0) into v_progress_assigned
    from public.crm_import_progress
   where file_name='202608_ASIGNADO_01_NM.xlsx' and load_type='asignado' and period='2026-08';

  v_status := jsonb_build_object(
    'all_rows',v_all_rows,'distinct_contacts',v_distinct,'visible_rows',v_visible,
    'assigned_contacts',v_assigned,'campaigns',v_campaigns,
    'gestionado',v_gestionado,'no_gestionado',v_no_gestionado,
    'progress_total',coalesce(v_progress_total,0),
    'progress_assigned',coalesce(v_progress_assigned,0),
    'staging_rows',v_staging,'active_period',public.active_period(),
    'visible_queue_rows',(select count(*) from public.work_queue where period='2026-08' and visible)
  );

  if p_action='check' then
    return jsonb_build_object('ok',true,'issue',36,'action','check','status',v_status);
  end if;

  select exists(
    select 1 from public.crm_guardrail_events
    where event_type='issue36_august_activated'
      and details->>'operation'='close_july_activate_august_2026'
  ) into v_already_done;
  if v_already_done then
    return jsonb_build_object('ok',true,'issue',36,'action','activate','already_done',true,'status',v_status);
  end if;

  if v_staging <> 0 or public.active_period() <> '2026-07'
     or v_all_rows <> 28186 or v_distinct <> 28186 or v_visible <> 0
     or v_assigned <> 54 or v_campaigns <> 4
     or v_gestionado <> 5 or v_no_gestionado <> 28181
     or coalesce(v_progress_total,0) <> 28186 or coalesce(v_progress_assigned,0) <> 54 then
    raise exception 'August activation precondition failed: %',v_status using errcode='55000';
  end if;

  update public.contact_month_state set visible=true where period='2026-08' and not visible;

  create temporary table issue36_august_eligible on commit drop as
  select e.contact_id,e.context_cms_id as cms_id,e.context_campaign_id as campaign_id,
         case when e.assigned_current then 'asignado' else 'regla' end::text as origen,
         e.context_order as display_order
  from public.contact_eligibility_for_period('2026-08') e
  where e.is_gestionable;

  update public.work_queue set visible=false,updated_at=now()
   where period='2026-08' and visible;

  insert into public.work_queue(contact_id,cms_id,period,campaign_id,origen,visible,display_order)
  select contact_id,cms_id,'2026-08',campaign_id,origen,true,display_order
  from issue36_august_eligible
  on conflict(contact_id,period) do update set
    cms_id=excluded.cms_id,campaign_id=excluded.campaign_id,origen=excluded.origen,
    visible=true,display_order=excluded.display_order,updated_at=now();

  select count(*),count(*) filter(where origen='asignado'),count(*) filter(where origen='regla')
    into v_total,v_queue_assigned,v_rule
  from public.work_queue where period='2026-08' and visible;

  if v_queue_assigned <> 54 or public.active_period() <> '2026-08' then
    raise exception 'August post-activation validation failed: total=%, assigned=%, rule=%, active=%',
      v_total,v_queue_assigned,v_rule,public.active_period() using errcode='55000';
  end if;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values('issue36_august_activated','warning',jsonb_build_object(
    'issue',36,'operation','close_july_activate_august_2026',
    'all_rows',v_all_rows,'assigned_rows',v_assigned,
    'visible_total_rows',v_total,'visible_assigned_rows',v_queue_assigned,
    'visible_rule_rows',v_rule,'activation_mode','hidden_chunks_then_atomic_activation_v5'
  ));

  return jsonb_build_object(
    'ok',true,'issue',36,'action','activate','already_done',false,
    'active_period',public.active_period(),
    'visible_total_rows',v_total,'visible_assigned_rows',v_queue_assigned,
    'visible_rule_rows',v_rule,
    'status',public.import_period_status('2026-08')
  );
end
$function$;

revoke all on function public.crm_issue36_august_control(text,text) from public;
grant execute on function public.crm_issue36_august_control(text,text) to anon;
