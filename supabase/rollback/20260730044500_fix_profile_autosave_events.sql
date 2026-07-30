-- Rollback Issue #26.
-- Reinstala el comportamiento anterior y restaura los registros archivados por la migración.

insert into public.crm_events
select x.*
from public.crm_recovery_issue26 r
cross join lateral jsonb_populate_record(null::public.crm_events,r.row_data) x
where r.entity_type='crm_events'
  and r.reason='issue26_profile_autosave_artifact'
  and not exists(select 1 from public.crm_events e where e.event_id=x.event_id);

insert into public.crm_log
select x.*
from public.crm_recovery_issue26 r
cross join lateral jsonb_populate_record(null::public.crm_log,r.row_data) x
where r.entity_type='crm_log'
  and r.reason='issue26_profile_autosave_artifact'
  and not exists(select 1 from public.crm_log l where l.log_id=x.log_id);

update public.work_queue w
set estado_gestion=(r.row_data->>'estado_gestion'),
    updated_at=coalesce((r.row_data->>'updated_at')::timestamptz,w.updated_at)
from public.crm_recovery_issue26 r
where r.entity_type='work_queue_state'
  and r.reason='issue26_restore_null_pending'
  and r.entity_key=w.work_item_id::text;

update public.crm_sprints s
set calls_count=coalesce((r.row_data->>'calls_count')::integer,s.calls_count),
    agendas_count=coalesce((r.row_data->>'agendas_count')::integer,s.agendas_count),
    updated_at=coalesce((r.row_data->>'updated_at')::timestamptz,s.updated_at)
from public.crm_recovery_issue26 r
where r.entity_type='crm_sprints'
  and r.reason='issue26_counter_recovery'
  and r.entity_key=s.sprint_id::text;

create or replace function public.save_gestion_v2(
  p_work_item_id uuid default null::uuid,
  p_contact_id uuid default null::uuid,
  p_active_period text default null::text,
  p_estado text default 'Pendiente'::text,
  p_ingreso numeric default 0,
  p_comentarios text default ''::text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_work uuid;
  v_contact uuid;
  v_old text;
  v_period text := coalesce(p_active_period, active_period());
  v_campaign uuid;
  v_origen text;
  v_rut text;
  v_rut_number bigint;
  v_rut_range text;
  v_hour int := extract(hour from now() at time zone 'America/Santiago')::int;
  v_event_id bigint;
  v_sprint uuid := public.crm_current_sprint_id();
begin
  if p_work_item_id is not null then
    select w.work_item_id,w.contact_id,w.estado_gestion::text,w.period,w.campaign_id,w.origen,c.rut_norm
      into v_work,v_contact,v_old,v_period,v_campaign,v_origen,v_rut
    from work_queue w
    left join contacts c on c.contact_id=w.contact_id
    where w.work_item_id=p_work_item_id;
  elsif p_contact_id is not null then
    select w.work_item_id,w.contact_id,w.estado_gestion::text,w.period,w.campaign_id,w.origen,c.rut_norm
      into v_work,v_contact,v_old,v_period,v_campaign,v_origen,v_rut
    from work_queue w
    left join contacts c on c.contact_id=w.contact_id
    where w.contact_id=p_contact_id and w.period=v_period
    limit 1;
  end if;

  if v_work is null then
    return jsonb_build_object('ok',false,'error','No encontré work item para guardar gestión');
  end if;

  v_rut_number := public.crm_rut_number(v_rut);
  v_rut_range := public.crm_rut_range(v_rut);

  update work_queue
     set estado_gestion=nullif(p_estado,''),
         ingreso_estimado=coalesce(p_ingreso,0),
         comentarios=coalesce(p_comentarios,''),
         updated_at=now()
   where work_item_id=v_work;

  insert into crm_log(work_item_id,contact_id,estado_anterior,estado_nuevo,ingreso_estimado,comentarios)
  values(v_work,v_contact,v_old,p_estado,p_ingreso,p_comentarios);

  insert into public.crm_events(
    event_type,event_ts,local_date,local_hour,local_weekday,hour_block,
    sprint_id,work_item_id,contact_id,campaign_id,period,origen,
    rut_norm,rut_number,rut_range,
    estado_anterior,estado_nuevo,
    is_agenda,is_no_agenda,is_volver_llamar,is_no_contactado,is_contacto_invalido,
    ingreso_estimado,metadata
  ) values (
    'gestion_saved',now(),(now() at time zone 'America/Santiago')::date,v_hour,
    extract(isodow from now() at time zone 'America/Santiago')::int,public.crm_hour_block(v_hour),
    v_sprint,v_work,v_contact,v_campaign,v_period,v_origen,
    v_rut,v_rut_number,v_rut_range,
    v_old,p_estado,
    public.crm_is_agenda(p_estado),lower(coalesce(p_estado,''))='no agenda',lower(coalesce(p_estado,''))='volver a llamar',lower(coalesce(p_estado,''))='no contactado',lower(coalesce(p_estado,''))='contacto inválido',
    p_ingreso,
    jsonb_build_object('comentarios_len',length(coalesce(p_comentarios,'')))
  ) returning event_id into v_event_id;

  if v_sprint is not null then
    update public.crm_sprints
       set calls_count=calls_count+1,
           agendas_count=agendas_count+case when public.crm_is_agenda(p_estado) then 1 else 0 end,
           updated_at=now()
     where sprint_id=v_sprint and status='running';
  end if;

  return jsonb_build_object('ok',true,'work_item_id',v_work,'contact_id',v_contact,'event_id',v_event_id,'sprint_id',v_sprint);
end
$function$;

select setval(pg_get_serial_sequence('public.crm_events','event_id'),coalesce((select max(event_id) from public.crm_events),1),true);
select setval(pg_get_serial_sequence('public.crm_log','log_id'),coalesce((select max(log_id) from public.crm_log),1),true);
