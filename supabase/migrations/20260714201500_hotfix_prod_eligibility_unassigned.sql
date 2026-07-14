-- Hotfix PROD · Issue #12
-- Corrige get_contacts_v2 sin modificar datos ni tablas.
-- Regla conservadora para el legacy productivo:
--   gestionable = asignado actualmente OR gestionado previamente por el único usuario de la app.
-- Los contactos vigentes no asignados y nunca gestionados quedan como no gestionables.

create or replace function public.get_contacts_v2(
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
set search_path to 'public'
as $function$
declare
  v_period text := coalesce(nullif(p_active_period,''), public.active_period());
  v_rows jsonb := '[]'::jsonb;
  v_total bigint := 0;
  v_base bigint := 0;
  v_pending bigint := 0;
  v_assigned bigint := 0;
  v_limit integer := greatest(1, least(coalesce(p_limit,50), 200));
  v_offset integer := greatest(0, coalesce(p_offset,0));
  v_search text := lower(trim(coalesce(p_search,'')));
  v_search_digits text := nullif(regexp_replace(coalesce(p_search,''),'\D','','g'),'');
  v_situation text := lower(coalesce(nullif(p_situation,''),'gestionables'));
  v_mode text := lower(coalesce(nullif(p_month_mode,''),'any'));
  v_months text[] := coalesce(p_months,array[]::text[]);
  v_month_count integer := coalesce(cardinality(coalesce(p_months,array[]::text[])),0);
  v_types text[] := coalesce(p_types,array[]::text[]);
begin
  perform set_config('statement_timeout','8000',true);

  with latest_management as (
    select distinct on (l.contact_id)
      l.contact_id,
      l.estado_nuevo,
      l.ingreso_estimado,
      l.comentarios,
      l.created_at,
      l.log_id
    from public.crm_log l
    where lower(coalesce(l.estado_nuevo,'')) in (
      'agenda',
      'no agenda',
      'volver a llamar',
      'no contactado',
      'contacto inválido',
      'contacto invalido',
      'gestionado'
    )
    order by l.contact_id, l.created_at desc nulls last, l.log_id desc
  ), base as (
    select
      w.work_item_id,
      w.contact_id,
      w.cms_id,
      w.period,
      w.campaign_id,
      w.visible,
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
      lm.estado_nuevo as last_managed_state,
      lm.ingreso_estimado as last_managed_income,
      lm.comentarios as last_managed_comments,
      (w.origen='asignado') as assigned_current,
      (lm.contact_id is not null) as managed_by_me,
      (w.origen='asignado' or lm.contact_id is not null) as is_gestionable,
      case
        when w.origen='asignado' then 'asignado'
        when lm.contact_id is not null then 'gestion_propia'
        else 'historico'
      end as origen_calculado,
      case
        when w.origen='asignado' then coalesce(nullif(w.estado_gestion,''),'Pendiente')
        when lm.contact_id is not null then coalesce(nullif(w.estado_gestion,''),nullif(lm.estado_nuevo,''),'Pendiente')
        else coalesce(nullif(w.estado_gestion,''),'Pendiente')
      end as estado_calculado,
      case
        when w.origen='asignado' then coalesce(w.ingreso_estimado,0)
        when lm.contact_id is not null then coalesce(w.ingreso_estimado,lm.ingreso_estimado,0)
        else coalesce(w.ingreso_estimado,0)
      end as ingreso_calculado,
      case
        when w.origen='asignado' then coalesce(w.comentarios,'')
        when lm.contact_id is not null then coalesce(nullif(w.comentarios,''),lm.comentarios,'')
        else coalesce(w.comentarios,'')
      end as comentarios_calculados
    from public.work_queue w
    join public.contacts c on c.contact_id=w.contact_id
    left join latest_management lm on lm.contact_id=w.contact_id
    where w.period=v_period
      and w.visible
      and (
        v_search=''
        or translate(lower(coalesce(c.search_text,'')),'áéíóúüñ','aeiouun') like '%'||translate(v_search,'áéíóúüñ','aeiouun')||'%'
        or c.rut ilike '%'||p_search||'%'
        or (v_search_digits is not null and c.rut_norm ilike '%'||v_search_digits||'%')
      )
      and (
        v_month_count=0
        or (
          v_mode='any'
          and exists (
            select 1
            from public.contact_month_state mm
            where mm.contact_id=w.contact_id
              and mm.visible
              and mm.period=any(v_months)
          )
        )
        or (
          v_mode='all'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id=w.contact_id
              and mm.visible
              and mm.period=any(v_months)
          )=v_month_count
        )
        or (
          v_mode='only'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id=w.contact_id
              and mm.visible
              and mm.period=any(v_months)
          )=v_month_count
          and not exists (
            select 1
            from public.contact_month_state mm
            where mm.contact_id=w.contact_id
              and mm.visible
              and not (mm.period=any(v_months))
          )
        )
      )
  ), filtered as (
    select b.*
    from base b
    where (
      v_situation in ('todos','all')
      or (v_situation in ('gestionables','operativos') and b.is_gestionable)
      or (v_situation in ('no_gestionables','nogestionables','descartados') and not b.is_gestionable)
    )
      and (not p_assigned_only or b.assigned_current)
      and (
        coalesce(cardinality(v_types),0)=0
        or b.origen_calculado=any(v_types)
      )
      and (not p_pending_only or b.estado_calculado='Pendiente')
  ), counted as (
    select f.*, count(*) over() as total_count
    from filtered f
    order by
      case f.origen_calculado when 'asignado' then 0 when 'gestion_propia' then 1 else 2 end,
      coalesce(f.display_order,2147483647),
      f.nombre nulls last,
      f.work_item_id
    limit v_limit offset v_offset
  ), enriched as (
    select
      q.*,
      ca.campaign_name,
      ca.campaign_desc,
      coalesce(m.meses_aparicion,array[]::text[]) as meses_aparicion
    from counted q
    left join public.campaigns ca on ca.campaign_id=q.campaign_id
    left join lateral (
      select array_agg(distinct cms2.period order by cms2.period desc) as meses_aparicion
      from public.contact_month_state cms2
      where cms2.contact_id=q.contact_id and cms2.visible
    ) m on true
  )
  select
    coalesce((select count(*) from base where is_gestionable),0),
    coalesce((select count(*) from base where is_gestionable and estado_calculado='Pendiente'),0),
    coalesce((select count(*) from base where assigned_current),0),
    coalesce(max(e.total_count),0),
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
      'campaign_name',e.campaign_name,
      'campaign_desc',e.campaign_desc,
      'motivo_gestionabilidad',case
        when e.assigned_current then 'asignado'
        when e.managed_by_me then 'gestion_propia'
        else 'no_gestionable'
      end,
      'motivo_label',case
        when e.assigned_current then 'Asignado'
        when e.managed_by_me then 'Gestionado por mí'
        else 'No gestionable'
      end,
      'gestionable_actual',e.is_gestionable,
      'managed_by_me',e.managed_by_me,
      'meses_aparicion',to_jsonb(e.meses_aparicion),
      'ultimo_mes_observado',v_period,
      'ultimo_estado_observado',e.last_managed_state,
      'aparece_en_campana_activa',true,
      'estado_gestion',e.estado_calculado,
      'comentarios',e.comentarios_calculados,
      'ingreso_estimado',e.ingreso_calculado,
      'recordatorio_titulo',coalesce(e.recordatorio_titulo,''),
      'recordatorio_fecha_hora',e.recordatorio_fecha_hora
    ) order by
      case e.origen_calculado when 'asignado' then 0 when 'gestion_propia' then 1 else 2 end,
      coalesce(e.display_order,2147483647),
      e.nombre nulls last,
      e.work_item_id
    ),'[]'::jsonb)
  into v_base,v_pending,v_assigned,v_total,v_rows
  from enriched e;

  return jsonb_build_object(
    'ok',true,
    'source','get_contacts_v2_prod_hotfix_unassigned',
    'active_period',v_period,
    'rule','assigned_or_previously_managed_by_current_legacy_user',
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
    'source','get_contacts_v2_prod_hotfix_unassigned',
    'error',sqlerrm,
    'sqlstate',sqlstate
  );
end
$function$;
