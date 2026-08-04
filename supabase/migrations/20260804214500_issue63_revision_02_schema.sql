-- Issue #63 · staging aislado y aplicación controlada de TOTAL/ASIGNADO revisión 02.
--
-- Esta migración NO configura una operación, NO contiene secretos y NO modifica datos
-- canónicos por sí sola. Crea infraestructura temporal en un esquema no expuesto y
-- dos RPC acotadas para cargar sólo a staging mediante la publishable/anon key Legacy.
-- La configuración, aplicación, rollback y cleanup requieren una llamada administrativa
-- explícita y permanecen fuera de los roles cliente.

create schema if not exists issue63_ops;
revoke all on schema issue63_ops from public, anon, authenticated;

create table issue63_ops.operation (
  operation_key text primary key,
  issue_number integer not null check (issue_number = 63),
  period text not null check (period ~ '^\d{4}-\d{2}$'),
  token_sha256 text not null check (token_sha256 ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null,
  status text not null check (status in ('configured','staging','staged','applying','applied','rolled_back')),
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
  search_text text,
  created_at timestamptz,
  updated_at timestamptz,
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

create table issue63_ops.snapshot_sequences (
  operation_key text not null,
  sequence_name text not null,
  last_value bigint not null,
  is_called boolean not null,
  primary key (operation_key, sequence_name)
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
alter table issue63_ops.snapshot_sequences enable row level security;

revoke all on all tables in schema issue63_ops from public, anon, authenticated;
revoke all on all sequences in schema issue63_ops from public, anon, authenticated;