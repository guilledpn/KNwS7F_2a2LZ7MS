begin;

create or replace function public.get_contacts_v2_filtered(
  p_active_period text default null::text,
  p_search text default ''::text,
  p_states text[] default array[]::text[],
  p_types text[] default array[]::text[],
  p_months text[] default array[]::text[],
  p_month_mode text default 'any'::text,
  p_campaigns text[] default array[]::text[],
  p_campaign_desc_keys text[] default array[]::text[],
  p_reminder text default ''::text,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_period text := coalesce(nullif(p_active_period,''),public.active_period());
  v_search text := lower(trim(coalesce(p_search,'')));
  v_search_digits text := nullif(regexp_replace(coalesce(p_search,''),'\D','','g'),'');
  v_states text[] := coalesce(p_states,array[]::text[]);
  v_types text[] := coalesce(p_types,array[]::text[]);
  v_months text[] := coalesce(p_months,array[]::text[]);
  v_month_count integer := coalesce(cardinality(coalesce(p_months,array[]::text[])),0);
  v_month_mode text := lower(coalesce(nullif(p_month_mode,''),'any'));
  v_campaigns text[] := coalesce(p_campaigns,array[]::text[]);
  v_campaign_desc_keys text[] := coalesce(p_campaign_desc_keys,array[]::text[]);
  v_reminder text := lower(trim(coalesce(p_reminder,'')));
  v_limit integer := greatest(1,least(coalesce(p_limit,50),200));
  v_offset integer := greatest(0,coalesce(p_offset,0));
  v_rows jsonb := '[]'::jsonb;
  v_total bigint := 0;
  v_base bigint := 0;
  v_pending bigint := 0;
  v_assigned bigint := 0;
begin
  perform set_config('statement_timeout','15000',true);

  select
    count(*),
    count(*) filter(
      where nullif(trim(w.estado_gestion),'') is null
         or lower(trim(w.estado_gestion)) = 'pendiente'
    ),
    count(*) filter(where w.origen = 'asignado')
  into v_base,v_pending,v_assigned
  from public.work_queue w
  where w.period = v_period
    and w.visible;

  with base as materialized (
    select
      w.work_item_id,
      w.contact_id,
      w.cms_id,
      w.period,
      w.campaign_id,
      w.origen,
      w.display_order,
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
      c.search_text,
      cp.campaign_name,
      cp.campaign_desc,
      case
        when nullif(trim(w.estado_gestion),'') is null
          or lower(trim(w.estado_gestion)) = 'pendiente' then 'pendiente'
        when lower(trim(w.estado_gestion)) = 'agenda' then 'agenda'
        when lower(trim(w.estado_gestion)) = 'no agenda' then 'no_agenda'
        when lower(trim(w.estado_gestion)) = 'volver a llamar' then 'volver'
        when lower(trim(w.estado_gestion)) = 'no contactado' then 'no_contactado'
        when translate(lower(trim(w.estado_gestion)),'áéíóúüñ','aeiouun')
          in ('contacto invalido','invalido') then 'invalido'
        else translate(lower(trim(w.estado_gestion)),' áéíóúüñ','_aeiouun')
      end as estado_key,
      translate(
        lower(
          regexp_replace(
            regexp_replace(
              trim(coalesce(cp.campaign_desc,'')),
              '^[[:space:]]*[0-9]+[[:space:]]*[.\-):][[:space:]]*',
              ''
            ),
            '[[:space:]]+',
            ' ',
            'g'
          )
        ),
        'áéíóúüñ',
        'aeiouun'
      ) as campaign_desc_key,
      (
        nullif(trim(w.recordatorio_titulo),'') is not null
        or w.recordatorio_fecha_hora is not null
      ) as has_reminder
    from public.work_queue w
    join public.contacts c on c.contact_id = w.contact_id
    left join public.campaigns cp on cp.campaign_id = w.campaign_id
    where w.period = v_period
      and w.visible
  ),
  filtered as materialized (
    select b.*
    from base b
    where
      (
        v_search = ''
        or translate(lower(coalesce(b.search_text,'')),'áéíóúüñ','aeiouun')
          like '%'||translate(v_search,'áéíóúüñ','aeiouun')||'%'
        or coalesce(b.rut,'') ilike '%'||p_search||'%'
        or (v_search_digits is not null and b.rut_norm ilike '%'||v_search_digits||'%')
      )
      and (
        coalesce(cardinality(v_states),0) = 0
        or b.estado_key = any(v_states)
      )
      and (
        coalesce(cardinality(v_types),0) = 0
        or b.origen = any(v_types)
      )
      and (
        coalesce(cardinality(v_campaigns),0) = 0
        or b.campaign_name = any(v_campaigns)
      )
      and (
        coalesce(cardinality(v_campaign_desc_keys),0) = 0
        or b.campaign_desc_key = any(v_campaign_desc_keys)
      )
      and (
        v_reminder = ''
        or (v_reminder = 'con' and b.has_reminder)
        or (v_reminder = 'sin' and not b.has_reminder)
      )
      and (
        v_month_count = 0
        or (
          v_month_mode = 'any'
          and exists(
            select 1
            from public.contact_month_state mm
            where mm.contact_id = b.contact_id
              and mm.visible
              and mm.period = any(v_months)
          )
        )
        or (
          v_month_mode = 'all'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id = b.contact_id
              and mm.visible
              and mm.period = any(v_months)
          ) = v_month_count
        )
        or (
          v_month_mode = 'only'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id = b.contact_id
              and mm.visible
              and mm.period = any(v_months)
          ) = v_month_count
          and not exists(
            select 1
            from public.contact_month_state mm
            where mm.contact_id = b.contact_id
              and mm.visible
              and not (mm.period = any(v_months))
          )
        )
      )
  ),
  page as (
    select f.*
    from filtered f
    order by
      coalesce(f.display_order,2147483647),
      f.nombre nulls last,
      f.work_item_id
    limit v_limit offset v_offset
  ),
  enriched as (
    select
      p.*,
      coalesce(ms.periods,array[]::text[]) as meses_aparicion
    from page p
    left join lateral (
      select array_agg(distinct cms.period order by cms.period desc) as periods
      from public.contact_month_state cms
      where cms.contact_id = p.contact_id
        and cms.visible
    ) ms on true
  )
  select
    coalesce((select count(*) from filtered),0),
    coalesce(jsonb_agg(jsonb_build_object(
      'work_item_id',e.work_item_id,
      'contact_id',e.contact_id,
      'rut_norm',e.rut_norm,
      'rut',coalesce(e.rut,e.rut_norm),
      'nombre',e.nombre,
      'telefono_1',e.telefono_1,
      'telefono_2',e.telefono_2,
      'telefono_3',e.telefono_3,
      'email',e.email,
      'telefono_activo_idx',e.telefono_activo_idx,
      'period',e.period,
      'campaign_id',e.campaign_id,
      'campaign_name',e.campaign_name,
      'campaign_desc',e.campaign_desc,
      'origen',e.origen,
      'motivo_gestionabilidad',e.origen,
      'motivo_label',case when e.origen='asignado' then 'Asignado' else 'Disponible por regla' end,
      'gestionable_actual',true,
      'meses_aparicion',to_jsonb(e.meses_aparicion),
      'ultimo_mes_observado',e.period,
      'ultimo_estado_observado',e.estado_gestion,
      'aparece_en_campana_activa',true,
      'estado_gestion',e.estado_gestion,
      'comentarios',e.comentarios,
      'ingreso_estimado',e.ingreso_estimado,
      'recordatorio_titulo',coalesce(e.recordatorio_titulo,''),
      'recordatorio_fecha_hora',e.recordatorio_fecha_hora
    ) order by
      coalesce(e.display_order,2147483647),
      e.nombre nulls last,
      e.work_item_id
    ),'[]'::jsonb)
  into v_total,v_rows
  from enriched e;

  return jsonb_build_object(
    'ok',true,
    'source','get_contacts_v2_filtered_issue46',
    'active_period',v_period,
    'rows',v_rows,
    'result_total',v_total,
    'base_total',v_base,
    'base_pending',v_pending,
    'base_assigned',v_assigned,
    'limit',v_limit,
    'offset',v_offset
  );
exception when others then
  return jsonb_build_object(
    'ok',false,
    'source','get_contacts_v2_filtered_issue46',
    'error',sqlerrm,
    'sqlstate',sqlstate
  );
end
$function$;

create or replace function public.get_contacts_v2_filter_options(
  p_active_period text default null::text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  with params as (
    select coalesce(nullif(p_active_period,''),public.active_period()) as period
  ),
  queue_contacts as materialized (
    select w.contact_id,w.campaign_id
    from public.work_queue w
    cross join params p
    where w.period = p.period
      and w.visible
  )
  select jsonb_build_object(
    'ok',true,
    'source','get_contacts_v2_filter_options_issue46',
    'months',coalesce((
      select jsonb_agg(x.period order by x.period desc)
      from (
        select distinct cms.period
        from public.contact_month_state cms
        join queue_contacts q on q.contact_id = cms.contact_id
        where cms.visible
      ) x
    ),'[]'::jsonb),
    'campaigns',coalesce((
      select jsonb_agg(x.campaign_name order by x.campaign_name)
      from (
        select distinct cp.campaign_name
        from queue_contacts q
        join public.campaigns cp on cp.campaign_id = q.campaign_id
        where nullif(trim(cp.campaign_name),'') is not null
      ) x
    ),'[]'::jsonb),
    'descriptions',coalesce((
      select jsonb_agg(x.campaign_desc order by x.campaign_desc)
      from (
        select distinct cp.campaign_desc
        from queue_contacts q
        join public.campaigns cp on cp.campaign_id = q.campaign_id
        where nullif(trim(cp.campaign_desc),'') is not null
      ) x
    ),'[]'::jsonb)
  );
$function$;

revoke all on function public.get_contacts_v2_filtered(
  text,text,text[],text[],text[],text,text[],text[],text,integer,integer
) from public,anon,authenticated;
revoke all on function public.get_contacts_v2_filter_options(text)
  from public,anon,authenticated;

grant execute on function public.get_contacts_v2_filtered(
  text,text,text[],text[],text[],text,text[],text[],text,integer,integer
) to anon,authenticated;
grant execute on function public.get_contacts_v2_filter_options(text)
  to anon,authenticated;

comment on function public.get_contacts_v2_filtered(
  text,text,text[],text[],text[],text,text[],text[],text,integer,integer
) is
  'Issue #46: lectura operacional filtrada antes de conteo, orden y paginación; no modifica work_queue.';
comment on function public.get_contacts_v2_filter_options(text) is
  'Issue #46: opciones completas de filtros limitadas a la cola operacional visible.';

commit;
