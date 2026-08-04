-- Issue #63 · configuración administrativa hash-locked.

create or replace function issue63_ops.require_operation(p_token text)
returns issue63_ops.operation
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_token_hash text;
begin
  if coalesce(auth.jwt()->>'role','') <> 'anon' then
    raise exception 'Issue #63 RPC requires the configured Legacy client role'
      using errcode = '42501';
  end if;

  select * into v_operation
  from issue63_ops.operation
  order by configured_at desc
  limit 1;

  if not found then
    raise exception 'Issue #63 operation is not configured' using errcode = '55000';
  end if;

  if now() >= v_operation.expires_at then
    raise exception 'Issue #63 operation token expired' using errcode = '42501';
  end if;

  v_token_hash := encode(extensions.digest(convert_to(coalesce(p_token,''),'UTF8'),'sha256'),'hex');
  if v_token_hash <> v_operation.token_sha256 then
    raise exception 'Invalid Issue #63 operation token' using errcode = '42501';
  end if;

  return v_operation;
end
$function$;

create or replace function issue63_ops.configure_operation(
  p_operation_key text,
  p_period text,
  p_token_sha256 text,
  p_expires_at timestamptz,
  p_manifest jsonb,
  p_expected_prior jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_manifest_count integer;
  v_names_count integer;
begin
  if p_operation_key <> 'issue63-202608-revision-02' then
    raise exception 'Unexpected Issue #63 operation key' using errcode = '22023';
  end if;
  if p_period <> '2026-08' then
    raise exception 'Issue #63 is restricted to period 2026-08' using errcode = '22023';
  end if;
  if p_token_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid token hash' using errcode = '22023';
  end if;
  if p_expires_at <= now() or p_expires_at > now() + interval '72 hours' then
    raise exception 'Expiration must be between now and 72 hours' using errcode = '22023';
  end if;
  if jsonb_typeof(p_manifest) <> 'array' or jsonb_array_length(p_manifest) <> 2 then
    raise exception 'Manifest must contain exactly two files' using errcode = '22023';
  end if;

  select count(*), count(*) filter (
    where file_name in ('202608_TOTAL_02_NM.xlsx','202608_ASIGNADO_02_NM.xlsx')
  )
  into v_manifest_count, v_names_count
  from jsonb_to_recordset(p_manifest) as x(
    file_name text,
    load_type text,
    xlsx_sha256 text,
    payload_sha256 text,
    expected_rows integer,
    expected_distinct_ruts integer,
    expected_status_counts jsonb,
    expected_campaign_counts jsonb
  );

  if v_manifest_count <> 2 or v_names_count <> 2 then
    raise exception 'Manifest file names are not the Issue #63 revisions' using errcode = '22023';
  end if;
  if exists (select 1 from issue63_ops.operation) then
    raise exception 'Issue #63 operation is already configured; cleanup is required first'
      using errcode = '55000';
  end if;

  insert into issue63_ops.operation(
    operation_key,issue_number,period,token_sha256,expires_at,status,expected_prior
  ) values (
    p_operation_key,63,p_period,p_token_sha256,p_expires_at,'configured',p_expected_prior
  );

  insert into issue63_ops.file_manifest(
    operation_key,file_name,load_type,xlsx_sha256,payload_sha256,
    expected_rows,expected_distinct_ruts,expected_status_counts,expected_campaign_counts
  )
  select
    p_operation_key,x.file_name,x.load_type,x.xlsx_sha256,x.payload_sha256,
    x.expected_rows,x.expected_distinct_ruts,x.expected_status_counts,x.expected_campaign_counts
  from jsonb_to_recordset(p_manifest) as x(
    file_name text,
    load_type text,
    xlsx_sha256 text,
    payload_sha256 text,
    expected_rows integer,
    expected_distinct_ruts integer,
    expected_status_counts jsonb,
    expected_campaign_counts jsonb
  );

  if not exists (
    select 1 from issue63_ops.file_manifest
    where operation_key=p_operation_key
      and file_name='202608_TOTAL_02_NM.xlsx'
      and load_type='mensual'
  ) or not exists (
    select 1 from issue63_ops.file_manifest
    where operation_key=p_operation_key
      and file_name='202608_ASIGNADO_02_NM.xlsx'
      and load_type='asignado'
  ) then
    raise exception 'Manifest load types are invalid' using errcode = '22023';
  end if;

  if not exists (
    select 1 from issue63_ops.file_manifest
    where operation_key=p_operation_key
      and file_name='202608_TOTAL_02_NM.xlsx'
      and load_type='mensual'
      and xlsx_sha256='116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd'
      and payload_sha256='81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef'
      and expected_rows=84912
      and expected_distinct_ruts=84912
      and expected_status_counts='{"Gestionado":2448,"No Gestionado":82464}'::jsonb
      and expected_campaign_counts='{
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-ciclo-de-vida-proteccion":11999,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-profesionales":13416,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-propension-integral":56367,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-joven":2243,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-senior":887
      }'::jsonb
  ) or not exists (
    select 1 from issue63_ops.file_manifest
    where operation_key=p_operation_key
      and file_name='202608_ASIGNADO_02_NM.xlsx'
      and load_type='asignado'
      and xlsx_sha256='43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019'
      and payload_sha256='201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76'
      and expected_rows=198
      and expected_distinct_ruts=198
      and expected_status_counts='{"No Gestionado":198}'::jsonb
      and expected_campaign_counts='{
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-ciclo-de-vida-proteccion":34,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-profesionales":15,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-propension-integral":145,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-joven":4
      }'::jsonb
  ) then
    raise exception 'Manifest differs from the audited Issue #63 files'
      using errcode='22023';
  end if;

  if p_expected_prior <> '{
    "active_period":"2026-08",
    "period_cms_rows":28186,
    "period_all_cms_rows":28186,
    "period_distinct_contacts":28186,
    "period_assigned_rows":54,
    "period_campaigns":4,
    "public_staging_rows":0,
    "total_existing_pairs":28186,
    "total_added_pairs":56726,
    "total_removed_pairs":0,
    "status_no_gestionado_to_gestionado":2260,
    "assigned_added":145,
    "assigned_removed":1,
    "assigned_common":53,
    "containment_event_id":7960,
    "containment_snapshot_id":"ISSUE43-PROD-2026-08-V1",
    "containment_rows":286
  }'::jsonb then
    raise exception 'Prior-state contract differs from the audited Issue #63 preflight'
      using errcode='22023';
  end if;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue63_operation_configured',
    'info',
    jsonb_build_object(
      'issue',63,
      'operation_key',p_operation_key,
      'period',p_period,
      'expires_at',p_expires_at,
      'files',(
        select jsonb_agg(jsonb_build_object(
          'file_name',m.file_name,
          'load_type',m.load_type,
          'expected_rows',m.expected_rows,
          'xlsx_sha256',m.xlsx_sha256,
          'payload_sha256',m.payload_sha256
        ) order by m.load_type)
        from issue63_ops.file_manifest m
        where m.operation_key=p_operation_key
      )
    )
  );

  return jsonb_build_object(
    'ok',true,
    'issue',63,
    'operation_key',p_operation_key,
    'period',p_period,
    'status','configured',
    'expires_at',p_expires_at
  );
end
$function$;

create or replace function issue63_ops.contiguous_rows(
  p_operation_key text,
  p_file_name text,
  p_expected_rows integer
)
returns integer
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(min(g.i)-1,p_expected_rows)::integer
  from generate_series(1,p_expected_rows) as g(i)
  left join issue63_ops.stage_rows s
    on s.operation_key=p_operation_key
   and s.file_name=p_file_name
   and s.source_order=g.i
  where s.source_order is null
$function$;
