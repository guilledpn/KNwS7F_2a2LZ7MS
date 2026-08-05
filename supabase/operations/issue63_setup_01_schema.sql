-- Parte 1/4 · esquema privado, manifest y configuración.
-- Issue #63 · infraestructura temporal reducida para TOTAL/ASIGNADO revisión 02.
--
-- Operación excepcional, no migración durable. Este archivo crea staging privado,
-- dos RPC acotadas y funciones administrativas de apply/rollback. No configura una
-- operación, no contiene token, credenciales, XLSX ni PII.

create schema if not exists issue63_ops;
revoke all on schema issue63_ops from public, anon, authenticated;

create table issue63_ops.operation (
  operation_key text primary key,
  issue_number integer not null check (issue_number = 63),
  period text not null check (period = '2026-08'),
  token_sha256 text not null check (token_sha256 ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null,
  status text not null check (
    status in ('configured','staging','staged','applying','applied','rolled_back')
  ),
  expected_prior jsonb not null,
  configured_at timestamptz not null default now(),
  staged_at timestamptz,
  applied_at timestamptz,
  rolled_back_at timestamptz,
  result jsonb not null default '{}'::jsonb
);

create table issue63_ops.file_manifest (
  operation_key text not null references issue63_ops.operation(operation_key) on delete cascade,
  file_name text not null,
  load_type text not null check (load_type in ('mensual','asignado')),
  xlsx_sha256 text not null check (xlsx_sha256 ~ '^[0-9a-f]{64}$'),
  payload_sha256 text not null check (payload_sha256 ~ '^[0-9a-f]{64}$'),
  expected_rows integer not null check (expected_rows > 0),
  expected_distinct_ruts integer not null check (expected_distinct_ruts > 0),
  expected_status_counts jsonb not null,
  expected_campaign_counts jsonb not null,
  primary key (operation_key, file_name),
  unique (operation_key, load_type)
);

create table issue63_ops.stage_rows (
  operation_key text not null,
  file_name text not null,
  load_type text not null,
  source_order integer not null check (source_order > 0),
  payload_line text not null,
  row_sha256 text not null check (row_sha256 ~ '^[0-9a-f]{64}$'),
  rut_norm text not null,
  rut text not null,
  nombre text not null,
  telefono_1 text not null,
  telefono_2 text not null,
  telefono_3 text not null,
  email text not null,
  campaign_name text not null,
  campaign_desc text not null,
  campaign_key text not null,
  estado_origen text not null check (estado_origen in ('Gestionado','No Gestionado')),
  staged_at timestamptz not null default now(),
  primary key (operation_key, file_name, source_order),
  unique (operation_key, file_name, rut_norm),
  foreign key (operation_key, file_name)
    references issue63_ops.file_manifest(operation_key, file_name)
    on delete cascade
);

create index issue63_stage_rows_operation_load_rut_idx
  on issue63_ops.stage_rows(operation_key, load_type, rut_norm);
create index issue63_stage_rows_operation_campaign_idx
  on issue63_ops.stage_rows(operation_key, load_type, campaign_key);

create table issue63_ops.snapshot_contacts (
  operation_key text not null,
  contact_id uuid not null,
  rut_norm text not null,
  rut text,
  nombre text,
  telefono_1 text,
  telefono_2 text,
  telefono_3 text,
  email text,
  telefono_activo_idx integer,
  primary key (operation_key, contact_id),
  unique (operation_key, rut_norm)
);

create table issue63_ops.snapshot_campaigns (
  operation_key text not null,
  campaign_id uuid not null,
  period text not null,
  campaign_key text not null,
  campaign_name text,
  campaign_desc text,
  created_at timestamptz,
  primary key (operation_key, campaign_id)
);

create table issue63_ops.snapshot_cms (
  operation_key text not null,
  cms_id uuid not null,
  contact_id uuid not null,
  campaign_id uuid not null,
  period text not null,
  source_priority integer not null,
  import_order integer,
  is_assigned boolean not null,
  visible boolean not null,
  last_seen_at timestamptz,
  created_at timestamptz,
  estado_origen text,
  primary key (operation_key, cms_id)
);

create table issue63_ops.snapshot_monthly_order (
  operation_key text not null,
  period text not null,
  contact_id uuid not null,
  source_row integer not null,
  source_session uuid,
  source_file text,
  source_sha256 text,
  updated_at timestamptz not null,
  primary key (operation_key, period, contact_id)
);

create table issue63_ops.snapshot_work_queue (
  operation_key text not null,
  work_item_id uuid not null,
  contact_id uuid not null,
  cms_id uuid,
  period text not null,
  campaign_id uuid,
  origen text not null,
  visible boolean not null,
  display_order integer,
  estado_gestion text,
  ingreso_estimado numeric,
  comentarios text,
  recordatorio_titulo text,
  recordatorio_fecha_hora timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  primary key (operation_key, work_item_id)
);

create table issue63_ops.snapshot_import_runs (
  operation_key text not null,
  run_id bigint not null,
  file_name text not null,
  load_type text not null,
  period text not null,
  row_count integer,
  distinct_ruts integer,
  status text,
  result jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  primary key (operation_key, run_id)
);

create table issue63_ops.snapshot_import_progress (
  operation_key text not null,
  file_name text not null,
  load_type text not null,
  period text not null,
  total_rows integer,
  processed_rows integer,
  status text,
  last_error text,
  created_at timestamptz,
  updated_at timestamptz,
  primary key (operation_key, file_name, load_type, period)
);

alter table issue63_ops.operation enable row level security;
alter table issue63_ops.file_manifest enable row level security;
alter table issue63_ops.stage_rows enable row level security;
alter table issue63_ops.snapshot_contacts enable row level security;
alter table issue63_ops.snapshot_campaigns enable row level security;
alter table issue63_ops.snapshot_cms enable row level security;
alter table issue63_ops.snapshot_monthly_order enable row level security;
alter table issue63_ops.snapshot_work_queue enable row level security;
alter table issue63_ops.snapshot_import_runs enable row level security;
alter table issue63_ops.snapshot_import_progress enable row level security;

revoke all on all tables in schema issue63_ops from public, anon, authenticated;
revoke all on all sequences in schema issue63_ops from public, anon, authenticated;

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
    raise exception 'Issue #63 RPC requires the Legacy anon role' using errcode='42501';
  end if;

  select * into v_operation
  from issue63_ops.operation
  order by configured_at desc
  limit 1;

  if not found then
    raise exception 'Issue #63 operation is not configured' using errcode='55000';
  end if;
  if now() >= v_operation.expires_at then
    raise exception 'Issue #63 operation token expired' using errcode='42501';
  end if;

  v_token_hash := encode(
    extensions.digest(convert_to(coalesce(p_token,''),'UTF8'),'sha256'),
    'hex'
  );
  if v_token_hash <> v_operation.token_sha256 then
    raise exception 'Invalid Issue #63 operation token' using errcode='42501';
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
begin
  if p_operation_key <> 'issue63-202608-revision-02'
     or p_period <> '2026-08'
     or p_token_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid Issue #63 configuration' using errcode='22023';
  end if;
  if p_expires_at <= now() or p_expires_at > now() + interval '72 hours' then
    raise exception 'Expiration must be between now and 72 hours' using errcode='22023';
  end if;
  if jsonb_typeof(p_manifest) <> 'array' or jsonb_array_length(p_manifest) <> 2 then
    raise exception 'Manifest must contain exactly two files' using errcode='22023';
  end if;
  if exists (select 1 from issue63_ops.operation) then
    raise exception 'Issue #63 operation is already configured; cleanup is required first'
      using errcode='55000';
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
      and xlsx_sha256='116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd'
      and payload_sha256='81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef'
      and expected_rows=84912
      and expected_distinct_ruts=84912
      and expected_status_counts='{"Gestionado":2448,"No Gestionado":82464}'::jsonb
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

