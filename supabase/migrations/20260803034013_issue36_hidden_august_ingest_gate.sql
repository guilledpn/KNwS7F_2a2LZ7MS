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

  if v_rows < 1 or v_rows > 250 then
    raise exception 'Hidden chunk must contain between 1 and 250 rows; received %', v_rows using errcode='22023';
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
    p_session,
    p_file_name,
    p_load_type,
    p_period,
    p_start_order,
    p_tsv
  );

  if coalesce((v_result->>'ok')::boolean,false) is not true
     or coalesce((v_result->>'rows')::integer,0) <> v_rows then
    raise exception 'Underlying ingest returned an unexpected result: %', v_result using errcode='55000';
  end if;

  update public.contact_month_state
     set visible=false,
         last_seen_at=last_seen_at
   where period='2026-08' and visible;
  get diagnostics v_hidden_cms = row_count;

  update public.work_queue
     set visible=false,
         updated_at=now()
   where period='2026-08' and visible;
  get diagnostics v_hidden_queue = row_count;

  if public.active_period() <> '2026-07' then
    raise exception 'Hidden ingest unexpectedly changed active period to %', public.active_period() using errcode='55000';
  end if;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue36_hidden_ingest_chunk',
    'info',
    jsonb_build_object(
      'issue',36,
      'operation','close_july_activate_august_2026',
      'file_name',p_file_name,
      'load_type',p_load_type,
      'start_order',p_start_order,
      'end_order',v_end_order,
      'rows',v_rows,
      'hidden_cms_rows',v_hidden_cms,
      'hidden_queue_rows',v_hidden_queue
    )
  );

  return jsonb_build_object(
    'ok',true,
    'issue',36,
    'mode','hidden_until_final_activation',
    'file_name',p_file_name,
    'load_type',p_load_type,
    'period',p_period,
    'start_order',p_start_order,
    'end_order',v_end_order,
    'rows',v_rows,
    'staging_deleted',coalesce((v_result->>'staging_deleted')::integer,0),
    'assigned_updated',coalesce((v_result->>'assigned_updated')::integer,0),
    'hidden_cms_rows',v_hidden_cms,
    'hidden_queue_rows',v_hidden_queue,
    'active_period',public.active_period(),
    'underlying',v_result
  );
end
$function$;

revoke all on function public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text) from public;
grant execute on function public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text) to anon;
