-- LCD-20260715-01 · ADR-020
-- Unifica la política canónica de gestionabilidad en APP LLAMADOS.
-- Alcance: DEV. No ejecuta backfill ni reconstruye colas automáticamente.
-- Los objetos legacy se conservan con un nombre interno para permitir rollback exacto.

begin;

-- Preservar las implementaciones previas sin copiar ni reinterpretar su código.
alter function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  rename to get_contacts_v2_legacy_lcd20260715;
alter function public.rebuild_work_queue_for_period(text)
  rename to rebuild_work_queue_for_period_legacy_lcd20260715;
alter function public.sync_work_queue_for_period_batch(text,integer,integer,uuid)
  rename to sync_work_queue_for_period_batch_legacy_lcd20260715;
alter function public.process_monthly_state_batch(uuid,integer,integer,integer)
  rename to process_monthly_state_batch_legacy_lcd20260715;
alter function public.process_assigned_load(uuid)
  rename to process_assigned_load_legacy_lcd20260715;

revoke all on function public.get_contacts_v2_legacy_lcd20260715(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  from public, anon, authenticated;
revoke all on function public.rebuild_work_queue_for_period_legacy_lcd20260715(text)
  from public, anon, authenticated;
revoke all on function public.sync_work_queue_for_period_batch_legacy_lcd20260715(text,integer,integer,uuid)
  from public, anon, authenticated;
revoke all on function public.process_monthly_state_batch_legacy_lcd20260715(uuid,integer,integer,integer)
  from public, anon, authenticated;
revoke all on function public.process_assigned_load_legacy_lcd20260715(uuid)
  from public, anon, authenticated;

create function public.contact_eligibility_for_period(p_period text)
returns table(
  contact_id uuid,
  is_gestionable boolean,
  eligibility_reason text,
  assigned_current boolean,
  appears_active boolean,
  latest_cms_id uuid,
  latest_campaign_id uuid,
  latest_period text,
  latest_import_order integer,
  latest_status text,
  assigned_cms_id uuid,
  assigned_campaign_id uuid,
  assigned_order integer,
  context_cms_id uuid,
  context_campaign_id uuid,
  context_order integer
)
language sql
stable
security definer
set search_path = public, pg_temp
as $function$
with current_assigned as (
  select distinct on (cms.contact_id)
    cms.contact_id,
    cms.cms_id,
    cms.campaign_id,
    cms.import_order
  from public.contact_month_state cms
  where cms.period = p_period
    and cms.visible
    and cms.is_assigned
  order by
    cms.contact_id,
    cms.source_priority desc,
    cms.import_order asc nulls last,
    cms.last_seen_at desc,
    cms.cms_id
),
active_presence as (
  select distinct cms.contact_id
  from public.contact_month_state cms
  where cms.period = p_period
    and cms.visible
),
latest_period as (
  select cms.contact_id, max(cms.period) as period
  from public.contact_month_state cms
  where cms.visible
  group by cms.contact_id
),
latest_appearance as (
  select distinct on (cms.contact_id)
    cms.contact_id,
    cms.cms_id,
    cms.campaign_id,
    cms.period,
    cms.import_order,
    case
      when lower(trim(coalesce(cms.estado_origen,''))) = 'gestionado' then 'Gestionado'
      when lower(trim(coalesce(cms.estado_origen,''))) = 'no gestionado' then 'No Gestionado'
      else null
    end as estado_normalizado
  from public.contact_month_state cms
  join latest_period lp
    on lp.contact_id = cms.contact_id
   and lp.period = cms.period
  where cms.visible
  order by
    cms.contact_id,
    case
      when lower(trim(coalesce(cms.estado_origen,''))) = 'gestionado' then 0
      when lower(trim(coalesce(cms.estado_origen,''))) = 'no gestionado' then 1
      else 2
    end,
    cms.source_priority desc,
    cms.import_order asc nulls last,
    cms.last_seen_at desc,
    cms.cms_id
)
select
  c.contact_id,
  case
    when ca.contact_id is not null then true
    when ap.contact_id is not null then false
    when la.estado_normalizado = 'No Gestionado' then true
    else false
  end as is_gestionable,
  case
    when ca.contact_id is not null then 'assigned_current'
    when ap.contact_id is not null then 'active_unassigned'
    when la.contact_id is null then 'never_observed'
    when la.estado_normalizado = 'No Gestionado' then 'latest_no_gestionado'
    when la.estado_normalizado = 'Gestionado' then 'latest_gestionado'
    else 'latest_status_missing'
  end as eligibility_reason,
  (ca.contact_id is not null) as assigned_current,
  (ap.contact_id is not null) as appears_active,
  la.cms_id as latest_cms_id,
  la.campaign_id as latest_campaign_id,
  la.period as latest_period,
  la.import_order as latest_import_order,
  la.estado_normalizado as latest_status,
  ca.cms_id as assigned_cms_id,
  ca.campaign_id as assigned_campaign_id,
  ca.import_order as assigned_order,
  coalesce(ca.cms_id, la.cms_id) as context_cms_id,
  coalesce(ca.campaign_id, la.campaign_id) as context_campaign_id,
  coalesce(ca.import_order, la.import_order) as context_order
from public.contacts c
left join current_assigned ca on ca.contact_id = c.contact_id
left join active_presence ap on ap.contact_id = c.contact_id
left join latest_appearance la on la.contact_id = c.contact_id
$function$;

revoke all on function public.contact_eligibility_for_period(text)
  from public, anon, authenticated;

create function public.rebuild_work_queue_for_period(p_period text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_total integer := 0;
  v_assigned integer := 0;
  v_rule integer := 0;
  v_status_rows integer := 0;
  v_missing_status_rows integer := 0;
begin
  perform set_config('statement_timeout','120000',true);

  select
    count(*) filter (
      where lower(trim(coalesce(estado_origen,''))) in ('gestionado','no gestionado')
    ),
    count(*) filter (
      where nullif(trim(coalesce(estado_origen,'')),'') is null
         or lower(trim(estado_origen)) not in ('gestionado','no gestionado')
    )
  into v_status_rows, v_missing_status_rows
  from public.contact_month_state
  where visible;

  update public.work_queue
     set visible = false,
         updated_at = now()
   where period = p_period
     and visible;

  with eligible as (
    select
      e.contact_id,
      e.context_cms_id as cms_id,
      e.context_campaign_id as campaign_id,
      case when e.assigned_current then 'asignado' else 'regla' end as origen,
      e.context_order as display_order
    from public.contact_eligibility_for_period(p_period) e
    where e.is_gestionable
  ),
  upserted as (
    insert into public.work_queue(
      contact_id, cms_id, period, campaign_id, origen, visible, display_order
    )
    select
      e.contact_id,
      e.cms_id,
      p_period,
      e.campaign_id,
      e.origen,
      true,
      e.display_order
    from eligible e
    on conflict(contact_id,period) do update set
      cms_id = excluded.cms_id,
      campaign_id = excluded.campaign_id,
      origen = excluded.origen,
      visible = true,
      display_order = excluded.display_order,
      updated_at = now()
    returning origen
  )
  select
    count(*),
    count(*) filter (where origen = 'asignado'),
    count(*) filter (where origen = 'regla')
  into v_total, v_assigned, v_rule
  from upserted;

  return jsonb_build_object(
    'ok', true,
    'period', p_period,
    'rule', 'canonical_monthly_eligibility_v1',
    'visible_total_rows', v_total,
    'visible_assigned_rows', v_assigned,
    'visible_rule_rows', v_rule,
    'valid_status_rows', v_status_rows,
    'missing_or_invalid_status_rows', v_missing_status_rows,
    'missing_status_behavior', 'fail_closed'
  );
end
$function$;

create function public.sync_work_queue_for_period_batch(
  p_period text,
  p_start_order integer,
  p_end_order integer,
  p_session uuid default null::uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_candidates integer := 0;
  v_visible integer := 0;
  v_hidden integer := 0;
begin
  perform set_config('statement_timeout','60000',true);

  with candidate_contacts as (
    select distinct ct.contact_id
    from public.staging_contacts s
    join public.contacts ct on ct.rut_norm = s.rut_norm
    where s.period = p_period
      and coalesce(s.import_order,s.staging_id) between p_start_order and p_end_order
      and (p_session is null or s.import_session_id = p_session)
  )
  select count(*) into v_candidates from candidate_contacts;

  with candidate_contacts as (
    select distinct ct.contact_id
    from public.staging_contacts s
    join public.contacts ct on ct.rut_norm = s.rut_norm
    where s.period = p_period
      and coalesce(s.import_order,s.staging_id) between p_start_order and p_end_order
      and (p_session is null or s.import_session_id = p_session)
  ),
  ineligible as (
    select cc.contact_id
    from candidate_contacts cc
    join public.contact_eligibility_for_period(p_period) e
      on e.contact_id = cc.contact_id
    where not e.is_gestionable
  ),
  hidden as (
    update public.work_queue w
       set visible = false,
           updated_at = now()
      from ineligible i
     where w.contact_id = i.contact_id
       and w.period = p_period
       and w.visible
    returning 1
  )
  select count(*) into v_hidden from hidden;

  with candidate_contacts as (
    select distinct ct.contact_id
    from public.staging_contacts s
    join public.contacts ct on ct.rut_norm = s.rut_norm
    where s.period = p_period
      and coalesce(s.import_order,s.staging_id) between p_start_order and p_end_order
      and (p_session is null or s.import_session_id = p_session)
  ),
  eligible as (
    select
      e.contact_id,
      e.context_cms_id as cms_id,
      e.context_campaign_id as campaign_id,
      case when e.assigned_current then 'asignado' else 'regla' end as origen,
      e.context_order as display_order
    from candidate_contacts cc
    join public.contact_eligibility_for_period(p_period) e
      on e.contact_id = cc.contact_id
    where e.is_gestionable
  ),
  upserted as (
    insert into public.work_queue(
      contact_id,cms_id,period,campaign_id,origen,visible,display_order,estado_gestion
    )
    select
      e.contact_id,e.cms_id,p_period,e.campaign_id,e.origen,true,e.display_order,null
    from eligible e
    on conflict(contact_id,period) do update set
      cms_id = excluded.cms_id,
      campaign_id = excluded.campaign_id,
      origen = excluded.origen,
      visible = true,
      display_order = excluded.display_order,
      updated_at = now()
    returning 1
  )
  select count(*) into v_visible from upserted;

  return jsonb_build_object(
    'ok', true,
    'period', p_period,
    'processed', v_candidates,
    'visible', v_visible,
    'hidden', v_hidden,
    'rule', 'canonical_monthly_eligibility_v1',
    'p_start_order', p_start_order,
    'p_end_order', p_end_order
  );
end
$function$;

create function public.process_monthly_state_batch(
  p_session uuid,
  p_start_order integer default 0,
  p_end_order integer default 2147483647,
  p_source_priority integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_count integer;
  v_wq integer := 0;
  r record;
  v_res jsonb;
begin
  perform set_config('statement_timeout','60000',true);

  with s_raw as (
    select
      s.*,
      coalesce(nullif(s.campaign_key,''),public.norm_campaign_key(s.campaign_name)) as ck
    from public.staging_contacts s
    where s.import_session_id = p_session
      and coalesce(s.import_order,s.staging_id) between p_start_order and p_end_order
  ),
  s as (
    select distinct on (rut_norm,period,ck) *
    from s_raw
    order by rut_norm,period,ck,coalesce(import_order,staging_id) desc,staging_id desc
  ),
  camp_src as (
    select distinct on (period,ck)
      period,
      ck,
      nullif(campaign_name,'') as campaign_name,
      nullif(campaign_desc,'') as campaign_desc
    from s_raw
    order by
      period,
      ck,
      case when nullif(campaign_name,'') is null then 1 else 0 end,
      case when nullif(campaign_desc,'') is null then 1 else 0 end,
      coalesce(import_order,staging_id) desc,
      staging_id desc
  ),
  camp as (
    insert into public.campaigns(period,campaign_key,campaign_name,campaign_desc)
    select period,ck,campaign_name,campaign_desc
    from camp_src
    on conflict(period,campaign_key) do update set
      campaign_name = coalesce(excluded.campaign_name,public.campaigns.campaign_name),
      campaign_desc = coalesce(excluded.campaign_desc,public.campaigns.campaign_desc)
    returning campaign_id,period,campaign_key
  ),
  allcamp as (
    select campaign_id,period,campaign_key from camp
    union
    select c.campaign_id,c.period,c.campaign_key
    from public.campaigns c
    join (select distinct period,ck from s_raw) x
      on x.period = c.period
     and x.ck = c.campaign_key
  ),
  ins as (
    insert into public.contact_month_state(
      contact_id,campaign_id,period,source_priority,import_order,
      is_assigned,visible,last_seen_at,estado_origen
    )
    select
      ct.contact_id,
      ac.campaign_id,
      s.period,
      p_source_priority,
      coalesce(s.import_order,s.staging_id),
      lower(trim(coalesce(s.load_type,''))) in ('asignado','assigned'),
      true,
      now(),
      nullif(trim(s.estado_origen),'')
    from s
    join public.contacts ct on ct.rut_norm = s.rut_norm
    join allcamp ac on ac.period = s.period and ac.campaign_key = s.ck
    on conflict(contact_id,campaign_id,period) do update set
      source_priority = greatest(public.contact_month_state.source_priority,excluded.source_priority),
      import_order = excluded.import_order,
      is_assigned = public.contact_month_state.is_assigned or excluded.is_assigned,
      visible = true,
      last_seen_at = now(),
      estado_origen = coalesce(excluded.estado_origen,public.contact_month_state.estado_origen)
    returning 1
  )
  select count(*) into v_count from ins;

  for r in
    select distinct period
    from public.staging_contacts
    where import_session_id = p_session
      and coalesce(import_order,staging_id) between p_start_order and p_end_order
  loop
    v_res := public.sync_work_queue_for_period_batch(
      r.period,p_start_order,p_end_order,p_session
    );
    v_wq := v_wq + coalesce((v_res->>'processed')::integer,0);
  end loop;

  return jsonb_build_object(
    'ok', true,
    'processed', v_count,
    'work_queue_synced', v_wq,
    'rule', 'canonical_monthly_eligibility_v1'
  );
end
$function$;

create function public.process_assigned_load(p_session uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_period text;
  v_period_count integer;
  v_total integer;
  v_source_managed integer := 0;
  v_source_pending integer := 0;
  v_applied_managed integer := 0;
  v_rebuild jsonb;
begin
  select
    max(period),
    count(distinct period),
    count(*),
    count(*) filter (where lower(trim(coalesce(estado_origen,''))) = 'gestionado'),
    count(*) filter (where lower(trim(coalesce(estado_origen,''))) = 'no gestionado')
  into
    v_period,
    v_period_count,
    v_total,
    v_source_managed,
    v_source_pending
  from public.staging_contacts
  where import_session_id = p_session;

  if v_total = 0 then
    return jsonb_build_object(
      'ok', false,
      'code', 'EMPTY_ASSIGNED_LOAD',
      'error', 'La sesión de carga asignada no contiene filas.'
    );
  end if;

  if v_period_count <> 1 then
    return jsonb_build_object(
      'ok', false,
      'code', 'MULTIPLE_PERIODS_IN_ASSIGNED_LOAD',
      'error', 'La carga asignada debe contener exactamente un período.',
      'period_count', v_period_count
    );
  end if;

  update public.staging_contacts
     set load_type = 'asignado'
   where import_session_id = p_session;

  perform public.process_monthly_contacts_batch(p_session,0,2147483647);
  perform public.process_monthly_state_batch(p_session,0,2147483647,9999);

  v_rebuild := public.rebuild_work_queue_for_period(v_period);

  -- "Gestionado" importado es un estado corporativo de la fuente.
  -- Se representa en la proyección work_queue sólo cuando no existe una
  -- gestión interna sustantiva; no se escribe en contact_operational_state.
  with source_rows as (
    select distinct on (c.contact_id)
      c.contact_id,
      s.period,
      lower(trim(coalesce(s.estado_origen,''))) as source_status,
      coalesce(s.import_order,s.staging_id) as source_order
    from public.staging_contacts s
    join public.contacts c on c.rut_norm = s.rut_norm
    where s.import_session_id = p_session
    order by c.contact_id,coalesce(s.import_order,s.staging_id)
  ),
  updated as (
    update public.work_queue w
       set estado_gestion = 'Gestionado',
           updated_at = now()
      from source_rows s
     where w.contact_id = s.contact_id
       and w.period = s.period
       and s.source_status = 'gestionado'
       and (w.estado_gestion is null or w.estado_gestion = 'Pendiente')
    returning 1
  )
  select count(*) into v_applied_managed from updated;

  update public.work_queue w
     set estado_gestion = 'Pendiente',
         updated_at = now()
    from public.staging_contacts s
    join public.contacts c on c.rut_norm = s.rut_norm
   where s.import_session_id = p_session
     and w.contact_id = c.contact_id
     and w.period = s.period
     and lower(trim(coalesce(s.estado_origen,''))) = 'no gestionado'
     and w.estado_gestion is null;

  return jsonb_build_object(
    'ok', coalesce((v_rebuild->>'ok')::boolean,false),
    'asignados', v_total,
    'period', v_period,
    'source_managed', v_source_managed,
    'source_pending', v_source_pending,
    'applied_managed_projection', v_applied_managed,
    'operational_state_mutations', 0,
    'eligibility_rule', 'canonical_monthly_eligibility_v1',
    'rebuild', v_rebuild
  );
end
$function$;

create function public.get_contacts_v2(
  p_active_period text default null::text,
  p_search text default ''::text,
  p_situation text default 'gestionables'::text,
  p_pending_only boolean default false,
  p_assigned_only boolean default false,
  p_types text[] default array[]::text[],
  p_months text[] default array[]::text[],
  p_month_mode text default 'any'::text,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_period text := coalesce(nullif(p_active_period,''),public.active_period());
  v_actor uuid := auth.uid();
  v_search text := lower(trim(coalesce(p_search,'')));
  v_search_digits text := nullif(regexp_replace(coalesce(p_search,''),'\D','','g'),'');
  v_situation text := lower(coalesce(nullif(p_situation,''),'gestionables'));
  v_mode text := lower(coalesce(nullif(p_month_mode,''),'any'));
  v_months text[] := coalesce(p_months,array[]::text[]);
  v_month_count integer := coalesce(cardinality(coalesce(p_months,array[]::text[])),0);
  v_types text[] := coalesce(p_types,array[]::text[]);
  v_limit integer := greatest(1,least(coalesce(p_limit,50),200));
  v_offset integer := greatest(0,coalesce(p_offset,0));
  v_rows jsonb := '[]'::jsonb;
  v_total bigint := 0;
  v_base bigint := 0;
  v_pending bigint := 0;
  v_assigned bigint := 0;
begin
  perform set_config('statement_timeout','15000',true);

  with current_queue as (
    select
      w.contact_id,
      w.work_item_id,
      w.cms_id,
      w.campaign_id,
      w.origen,
      w.visible,
      w.display_order,
      w.estado_gestion,
      w.ingreso_estimado,
      w.comentarios,
      w.recordatorio_titulo,
      w.recordatorio_fecha_hora
    from public.work_queue w
    where w.period = v_period
  ),
  classified as (
    select
      c.contact_id,
      c.rut_norm,
      c.rut,
      c.nombre,
      c.telefono_1,
      c.telefono_2,
      c.telefono_3,
      c.email,
      c.telefono_activo_idx,
      c.search_text,
      e.is_gestionable,
      e.eligibility_reason,
      e.assigned_current,
      e.appears_active,
      e.latest_period,
      e.latest_status,
      e.context_campaign_id,
      e.context_order,
      e.assigned_order,
      q.work_item_id,
      q.cms_id as queue_cms_id,
      q.campaign_id as queue_campaign_id,
      q.display_order,
      q.estado_gestion as queue_state,
      q.ingreso_estimado as queue_ingreso,
      q.comentarios as queue_comments,
      q.recordatorio_titulo,
      q.recordatorio_fecha_hora,
      os.last_managed_at,
      os.last_managed_date,
      os.next_eligible_date,
      os.last_state,
      os.last_work_item_id,
      os.last_ingreso,
      os.last_comments,
      os.last_managed_by,
      (v_actor is not null and os.last_managed_by = v_actor) as managed_by_me
    from public.contacts c
    join public.contact_eligibility_for_period(v_period) e
      on e.contact_id = c.contact_id
    left join public.contact_operational_state os on os.contact_id = c.contact_id
    left join current_queue q on q.contact_id = c.contact_id
  ),
  normalized as (
    select
      cl.*,
      case
        when cl.assigned_current then 'asignado'
        when cl.is_gestionable then 'regla'
        else 'historico'
      end as origen_calculado,
      case
        when nullif(cl.queue_state,'') is not null then cl.queue_state
        when cl.is_gestionable then 'Pendiente'
        else coalesce(nullif(cl.last_state,''),'Gestionado')
      end as estado_calculado,
      coalesce(cl.queue_ingreso,cl.last_ingreso,0) as ingreso_calculado,
      coalesce(cl.queue_comments,cl.last_comments,'') as comentarios_calculados
    from classified cl
  ),
  filtered as (
    select n.*
    from normalized n
    where
      (
        v_situation in ('todos','all')
        or (v_situation in ('gestionables','operativos') and n.is_gestionable)
        or (v_situation in ('no_gestionables','nogestionables','descartados') and not n.is_gestionable)
      )
      and (not p_assigned_only or n.assigned_current)
      and (
        coalesce(cardinality(v_types),0) = 0
        or n.origen_calculado = any(v_types)
      )
      and (
        not p_pending_only
        or n.estado_calculado = 'Pendiente'
      )
      and (
        v_search = ''
        or translate(lower(coalesce(n.search_text,'')),'áéíóúüñ','aeiouun')
             like '%'||translate(v_search,'áéíóúüñ','aeiouun')||'%'
        or n.rut ilike '%'||p_search||'%'
        or (v_search_digits is not null and n.rut_norm ilike '%'||v_search_digits||'%')
      )
      and (
        v_month_count = 0
        or (
          v_mode = 'any'
          and exists(
            select 1
            from public.contact_month_state mm
            where mm.contact_id = n.contact_id
              and mm.visible
              and mm.period = any(v_months)
          )
        )
        or (
          v_mode = 'all'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id = n.contact_id
              and mm.visible
              and mm.period = any(v_months)
          ) = v_month_count
        )
        or (
          v_mode = 'only'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id = n.contact_id
              and mm.visible
              and mm.period = any(v_months)
          ) = v_month_count
          and not exists(
            select 1
            from public.contact_month_state mm
            where mm.contact_id = n.contact_id
              and mm.visible
              and not (mm.period = any(v_months))
          )
        )
      )
  ),
  counted as (
    select f.*,count(*) over() as total_count
    from filtered f
    order by
      case f.origen_calculado when 'asignado' then 0 when 'regla' then 1 else 2 end,
      coalesce(f.assigned_order,f.context_order,f.display_order,2147483647),
      f.nombre nulls last,
      f.contact_id
    limit v_limit offset v_offset
  ),
  enriched as (
    select
      p.*,
      cp.campaign_name,
      cp.campaign_desc,
      coalesce(ms.periods,array[]::text[]) as meses_aparicion
    from counted p
    left join public.campaigns cp on cp.campaign_id = p.context_campaign_id
    left join lateral (
      select array_agg(distinct cms.period order by cms.period desc) as periods
      from public.contact_month_state cms
      where cms.contact_id = p.contact_id
        and cms.visible
    ) ms on true
  )
  select
    coalesce((select count(*) from normalized where is_gestionable),0),
    coalesce((select count(*) from normalized where is_gestionable and estado_calculado = 'Pendiente'),0),
    coalesce((select count(*) from normalized where assigned_current),0),
    coalesce(max(e.total_count),0),
    coalesce(jsonb_agg(jsonb_build_object(
      'work_item_id',coalesce(e.work_item_id,gen_random_uuid()),
      'contact_id',e.contact_id,
      'rut_norm',e.rut_norm,
      'rut',coalesce(e.rut,e.rut_norm),
      'nombre',e.nombre,
      'telefono_1',e.telefono_1,
      'telefono_2',e.telefono_2,
      'telefono_3',e.telefono_3,
      'email',e.email,
      'telefono_activo_idx',e.telefono_activo_idx,
      'period',v_period,
      'campaign_id',e.context_campaign_id,
      'campaign_name',e.campaign_name,
      'campaign_desc',e.campaign_desc,
      'origen',e.origen_calculado,
      'motivo_gestionabilidad',e.eligibility_reason,
      'motivo_label',case e.eligibility_reason
        when 'assigned_current' then 'Asignado'
        when 'latest_no_gestionado' then 'Disponible por última aparición No Gestionado'
        when 'active_unassigned' then 'Vigente no asignado'
        when 'latest_gestionado' then 'Última aparición Gestionado'
        when 'latest_status_missing' then 'Estado corporativo faltante'
        else 'Sin aparición corporativa'
      end,
      'gestionable_actual',e.is_gestionable,
      'managed_by_me',e.managed_by_me,
      'meses_aparicion',to_jsonb(e.meses_aparicion),
      'ultimo_mes_observado',e.latest_period,
      'ultimo_estado_observado',e.latest_status,
      'ultimo_estado_corporativo',e.latest_status,
      'ultimo_estado_operativo',e.last_state,
      'aparece_en_campana_activa',e.appears_active,
      'estado_gestion',e.estado_calculado,
      'comentarios',e.comentarios_calculados,
      'ingreso_estimado',e.ingreso_calculado,
      'recordatorio_titulo',coalesce(e.recordatorio_titulo,''),
      'recordatorio_fecha_hora',e.recordatorio_fecha_hora,
      'last_managed_date',e.last_managed_date,
      'last_managed_by',e.last_managed_by,
      'next_eligible_date',e.next_eligible_date
    ) order by
      case e.origen_calculado when 'asignado' then 0 when 'regla' then 1 else 2 end,
      coalesce(e.assigned_order,e.context_order,e.display_order,2147483647),
      e.nombre nulls last,
      e.contact_id
    ),'[]'::jsonb)
  into v_base,v_pending,v_assigned,v_total,v_rows
  from enriched e;

  return jsonb_build_object(
    'ok', true,
    'source', 'get_contacts_v2_canonical_monthly_eligibility',
    'active_period', v_period,
    'rule', 'canonical_monthly_eligibility_v1',
    'rows', v_rows,
    'result_total', v_total,
    'base_total', v_base,
    'base_pending', v_pending,
    'base_assigned', v_assigned,
    'limit', v_limit,
    'offset', v_offset
  );
exception when others then
  return jsonb_build_object(
    'ok', false,
    'source', 'get_contacts_v2_canonical_monthly_eligibility',
    'error', sqlerrm,
    'sqlstate', sqlstate
  );
end
$function$;

revoke all on function public.rebuild_work_queue_for_period(text)
  from public, anon;
revoke all on function public.sync_work_queue_for_period_batch(text,integer,integer,uuid)
  from public, anon;
revoke all on function public.process_monthly_state_batch(uuid,integer,integer,integer)
  from public, anon;
revoke all on function public.process_assigned_load(uuid)
  from public, anon;
revoke all on function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  from public, anon;

grant execute on function public.rebuild_work_queue_for_period(text) to authenticated;
grant execute on function public.sync_work_queue_for_period_batch(text,integer,integer,uuid) to authenticated;
grant execute on function public.process_monthly_state_batch(uuid,integer,integer,integer) to authenticated;
grant execute on function public.process_assigned_load(uuid) to authenticated;
grant execute on function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  to authenticated;

comment on function public.contact_eligibility_for_period(text) is
  'ADR-020: política canónica interna de gestionabilidad. No expuesta al cliente.';
comment on function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer) is
  'LCD-20260715-01: consulta de contactos basada en la política mensual canónica.';
comment on function public.rebuild_work_queue_for_period(text) is
  'LCD-20260715-01: reconstruye la proyección work_queue sin modificar gestiones del usuario.';

commit;
