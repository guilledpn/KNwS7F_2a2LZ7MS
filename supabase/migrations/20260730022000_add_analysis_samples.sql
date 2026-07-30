-- Issue #22 · Muestras de análisis reutilizables
-- Infraestructura genérica para seleccionar contactos sin alterar campañas,
-- estados comerciales, comentarios ni la cola operativa.

begin;

create table if not exists public.crm_analysis_samples (
  sample_id uuid primary key default gen_random_uuid(),
  sample_key text not null unique,
  title text not null,
  purpose text,
  status text not null default 'active'
    check (status in ('active','completed','cancelled')),
  target_count integer not null default 0 check (target_count >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crm_analysis_sample_items (
  sample_item_id uuid primary key default gen_random_uuid(),
  sample_id uuid not null references public.crm_analysis_samples(sample_id) on delete cascade,
  contact_id uuid not null references public.contacts(contact_id) on delete restrict,
  work_item_id uuid not null references public.work_queue(work_item_id) on delete restrict,
  source_cms_id uuid references public.contact_month_state(cms_id) on delete set null,
  source_campaign_id uuid references public.campaigns(campaign_id) on delete set null,
  source_period text,
  source_import_order integer,
  source_campaign_size integer,
  target_percentile numeric(6,5),
  actual_percentile numeric(8,7),
  stratum_key text not null,
  sample_sequence integer not null check (sample_sequence > 0),
  completed_at timestamptz,
  captured_income numeric,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(sample_id, contact_id),
  unique(sample_id, sample_sequence)
);

create index if not exists crm_analysis_sample_items_pending_idx
  on public.crm_analysis_sample_items(sample_id, completed_at, sample_sequence);

create index if not exists crm_analysis_sample_items_contact_idx
  on public.crm_analysis_sample_items(contact_id);

alter table public.crm_analysis_samples enable row level security;
alter table public.crm_analysis_sample_items enable row level security;

-- Las tablas no forman parte de la API directa. La app usa RPC acotadas.
revoke all on table public.crm_analysis_samples from public, anon, authenticated;
revoke all on table public.crm_analysis_sample_items from public, anon, authenticated;

create or replace function public.get_analysis_sample_v1(
  p_sample_key text,
  p_pending_only boolean default true,
  p_limit integer default 200,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  v_sample public.crm_analysis_samples%rowtype;
  v_limit integer := greatest(1, least(coalesce(p_limit,200), 500));
  v_offset integer := greatest(0, coalesce(p_offset,0));
  v_rows jsonb := '[]'::jsonb;
  v_result_total integer := 0;
  v_total integer := 0;
  v_completed integer := 0;
  v_pending integer := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select *
    into v_sample
  from public.crm_analysis_samples
  where sample_key = p_sample_key
    and status <> 'cancelled';

  if not found then
    return jsonb_build_object(
      'ok', false,
      'code', 'SAMPLE_NOT_FOUND',
      'sample_key', p_sample_key
    );
  end if;

  select
    count(*),
    count(*) filter (where completed_at is not null),
    count(*) filter (where completed_at is null)
  into v_total, v_completed, v_pending
  from public.crm_analysis_sample_items
  where sample_id = v_sample.sample_id;

  with filtered as (
    select
      i.sample_item_id,
      i.sample_sequence,
      i.completed_at,
      i.captured_income,
      w.work_item_id,
      w.contact_id,
      w.estado_gestion,
      w.comentarios,
      w.ingreso_estimado,
      w.recordatorio_titulo,
      w.recordatorio_fecha_hora,
      c.rut_norm,
      c.rut,
      c.nombre,
      c.telefono_1,
      c.telefono_2,
      c.telefono_3,
      c.email,
      c.telefono_activo_idx,
      count(*) over() as result_total
    from public.crm_analysis_sample_items i
    join public.work_queue w on w.work_item_id = i.work_item_id
    join public.contacts c on c.contact_id = i.contact_id
    where i.sample_id = v_sample.sample_id
      and (not p_pending_only or i.completed_at is null)
    order by i.sample_sequence
    limit v_limit offset v_offset
  )
  select
    coalesce(jsonb_agg(jsonb_build_object(
      'sample_item_id', sample_item_id,
      'sample_sequence', sample_sequence,
      'sample_completed', completed_at is not null,
      'sample_captured_income', captured_income,
      'work_item_id', work_item_id,
      'contact_id', contact_id,
      'rut_norm', rut_norm,
      'rut', coalesce(rut,rut_norm),
      'nombre', nombre,
      'telefono_1', telefono_1,
      'telefono_2', telefono_2,
      'telefono_3', telefono_3,
      'email', email,
      'telefono_activo_idx', telefono_activo_idx,
      'campaign_name', '',
      'campaign_desc', '',
      'motivo_gestionabilidad', 'analysis_sample',
      'motivo_label', 'Muestra de análisis',
      'gestionable_actual', true,
      'meses_aparicion', '[]'::jsonb,
      'ultimo_mes_observado', '',
      'ultimo_estado_observado', estado_gestion,
      'aparece_en_campana_activa', false,
      'estado_gestion', coalesce(estado_gestion,'Pendiente'),
      'comentarios', coalesce(comentarios,''),
      'ingreso_estimado', coalesce(ingreso_estimado,0),
      'recordatorio_titulo', recordatorio_titulo,
      'recordatorio_fecha_hora', recordatorio_fecha_hora
    ) order by sample_sequence), '[]'::jsonb),
    coalesce(max(result_total),0)
  into v_rows, v_result_total
  from filtered;

  return jsonb_build_object(
    'ok', true,
    'sample_id', v_sample.sample_id,
    'sample_key', v_sample.sample_key,
    'title', v_sample.title,
    'status', v_sample.status,
    'sample_total', v_total,
    'sample_completed', v_completed,
    'sample_pending', v_pending,
    'result_total', v_result_total,
    'rows', v_rows
  );
end
$function$;

create or replace function public.complete_analysis_sample_item_v1(
  p_sample_item_id uuid,
  p_ingreso numeric default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_sample_id uuid;
  v_sample_key text;
  v_total integer := 0;
  v_completed integer := 0;
  v_pending integer := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  update public.crm_analysis_sample_items i
     set completed_at = coalesce(i.completed_at, now()),
         captured_income = coalesce(p_ingreso,0)
    from public.crm_analysis_samples s
   where i.sample_item_id = p_sample_item_id
     and s.sample_id = i.sample_id
     and s.status = 'active'
  returning i.sample_id, s.sample_key
       into v_sample_id, v_sample_key;

  if v_sample_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'SAMPLE_ITEM_NOT_FOUND_OR_INACTIVE',
      'sample_item_id', p_sample_item_id
    );
  end if;

  select
    count(*),
    count(*) filter (where completed_at is not null),
    count(*) filter (where completed_at is null)
  into v_total, v_completed, v_pending
  from public.crm_analysis_sample_items
  where sample_id = v_sample_id;

  if v_pending = 0 then
    update public.crm_analysis_samples
       set status = 'completed', updated_at = now()
     where sample_id = v_sample_id
       and status = 'active';
  else
    update public.crm_analysis_samples
       set updated_at = now()
     where sample_id = v_sample_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'sample_key', v_sample_key,
    'sample_total', v_total,
    'sample_completed', v_completed,
    'sample_pending', v_pending
  );
end
$function$;

revoke all on function public.get_analysis_sample_v1(text,boolean,integer,integer)
  from public, anon, authenticated;
revoke all on function public.complete_analysis_sample_item_v1(uuid,numeric)
  from public, anon, authenticated;

grant execute on function public.get_analysis_sample_v1(text,boolean,integer,integer)
  to authenticated;
grant execute on function public.complete_analysis_sample_item_v1(uuid,numeric)
  to authenticated;

commit;
