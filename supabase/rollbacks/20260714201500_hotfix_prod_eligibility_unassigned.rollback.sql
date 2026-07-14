-- Rollback del hotfix PROD · Issue #12
-- Restaura la definición anterior de get_contacts_v2.

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
  v_period text := coalesce(p_active_period, public.active_period());
  v_rows jsonb;
  v_total int := 0;
  v_base int := 0;
  v_pending int := 0;
  v_assigned int := 0;
  v_limit int := greatest(1, least(coalesce(p_limit,50), 200));
  v_offset int := greatest(0, coalesce(p_offset,0));
  v_search text := lower(trim(coalesce(p_search,'')));
begin
  perform set_config('statement_timeout','8000', true);

  select count(*),
         count(*) filter(where estado_gestion is null or estado_gestion='Pendiente'),
         count(*) filter(where origen='asignado')
    into v_base, v_pending, v_assigned
  from public.work_queue
  where period=v_period and visible;

  with filtered as (
    select
      w.work_item_id,
      w.contact_id,
      w.cms_id,
      w.period,
      w.campaign_id,
      w.origen,
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
      c.search_text
    from public.work_queue w
    join public.contacts c on c.contact_id=w.contact_id
    where w.period=v_period
      and w.visible
      and (v_search='' or c.search_text like '%'||v_search||'%')
      and (coalesce(array_length(p_types,1),0)=0 or w.origen = any(p_types))
      and (not p_assigned_only or w.origen='asignado')
      and (not p_pending_only or w.estado_gestion is null or w.estado_gestion='Pendiente')
      and (
        coalesce(array_length(p_months,1),0)=0
        or (
          p_month_mode='any'
          and exists (
            select 1 from public.contact_month_state mm
            where mm.contact_id=w.contact_id and mm.period=any(p_months)
          )
        )
        or (
          p_month_mode='all'
          and (
            select count(distinct mm.period)
            from public.contact_month_state mm
            where mm.contact_id=w.contact_id and mm.period=any(p_months)
          ) = array_length(p_months,1)
        )
        or (
          p_month_mode='only'
          and not exists (
            select 1 from public.contact_month_state mm
            where mm.contact_id=w.contact_id and not (mm.period=any(p_months))
          )
        )
      )
  ), counted as (
    select *, count(*) over() as total_count
    from filtered
    order by coalesce(display_order,999999999), nombre nulls last, work_item_id
    limit v_limit offset v_offset
  ), enriched as (
    select
      q.*,
      ca.campaign_name,
      ca.campaign_desc,
      coalesce(m.meses_aparicion, array[]::text[]) as meses_aparicion
    from counted q
    left join public.campaigns ca on ca.campaign_id=q.campaign_id
    left join lateral (
      select array_agg(distinct cms2.period order by cms2.period desc) as meses_aparicion
      from public.contact_month_state cms2
      where cms2.contact_id=q.contact_id
    ) m on true
  )
  select
    coalesce(jsonb_agg(jsonb_build_object(
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
      'campaign_name', campaign_name,
      'campaign_desc', campaign_desc,
      'motivo_gestionabilidad', origen,
      'motivo_label', case when origen='asignado' then 'Asignado' else 'Disponible por regla' end,
      'gestionable_actual', true,
      'meses_aparicion', to_jsonb(meses_aparicion),
      'ultimo_mes_observado', v_period,
      'ultimo_estado_observado', estado_gestion,
      'aparece_en_campana_activa', true,
      'estado_gestion', estado_gestion,
      'comentarios', comentarios,
      'ingreso_estimado', ingreso_estimado,
      'recordatorio_titulo', recordatorio_titulo,
      'recordatorio_fecha_hora', recordatorio_fecha_hora
    ) order by coalesce(display_order,999999999), nombre nulls last), '[]'::jsonb),
    coalesce(max(total_count),0)
  into v_rows, v_total
  from enriched;

  return jsonb_build_object(
    'ok',true,
    'active_period',v_period,
    'rows',v_rows,
    'result_total',coalesce(v_total,0),
    'base_total',coalesce(v_base,0),
    'base_pending',coalesce(v_pending,0),
    'base_assigned',coalesce(v_assigned,0),
    'optimized','page_first_v1'
  );
end
$function$;
