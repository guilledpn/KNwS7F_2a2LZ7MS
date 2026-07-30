-- Issue #26 · separar edición de ficha de eventos de gestión y recuperar artefactos históricos.

create table if not exists public.crm_recovery_issue26 (
  recovery_id bigint generated always as identity primary key,
  entity_type text not null,
  entity_key text not null,
  reason text not null,
  row_data jsonb not null,
  archived_at timestamptz not null default now(),
  unique(entity_type, entity_key)
);

alter table public.crm_recovery_issue26 enable row level security;
revoke all on table public.crm_recovery_issue26 from public, anon, authenticated;
revoke all on sequence public.crm_recovery_issue26_recovery_id_seq from public, anon, authenticated;

-- Respaldar eventos que no representan una gestión real.
insert into public.crm_recovery_issue26(entity_type,entity_key,reason,row_data)
select 'crm_events', e.event_id::text, 'issue26_profile_autosave_artifact', to_jsonb(e)
from public.crm_events e
where e.event_type='gestion_saved'
  and (
    (e.estado_anterior is null and e.estado_nuevo='Pendiente')
    or e.estado_anterior=e.estado_nuevo
  )
on conflict(entity_type,entity_key) do nothing;

-- Respaldar logs gemelos de esos eventos.
insert into public.crm_recovery_issue26(entity_type,entity_key,reason,row_data)
select 'crm_log', l.log_id::text, 'issue26_profile_autosave_artifact', to_jsonb(l)
from public.crm_log l
where exists (
  select 1
  from public.crm_events e
  where e.event_type='gestion_saved'
    and (
      (e.estado_anterior is null and e.estado_nuevo='Pendiente')
      or e.estado_anterior=e.estado_nuevo
    )
    and e.contact_id=l.contact_id
    and e.work_item_id=l.work_item_id
    and e.event_ts=l.created_at
    and e.estado_anterior is not distinct from l.estado_anterior
    and e.estado_nuevo is not distinct from l.estado_nuevo
)
on conflict(entity_type,entity_key) do nothing;

-- Respaldar Sprints antes de cualquier ajuste de contadores.
insert into public.crm_recovery_issue26(entity_type,entity_key,reason,row_data)
select distinct 'crm_sprints', s.sprint_id::text, 'issue26_counter_recovery', to_jsonb(s)
from public.crm_sprints s
join public.crm_events e on e.sprint_id=s.sprint_id
where e.event_type='gestion_saved'
  and (
    (e.estado_anterior is null and e.estado_nuevo='Pendiente')
    or e.estado_anterior=e.estado_nuevo
  )
on conflict(entity_type,entity_key) do nothing;

-- Los autosaves null -> Pendiente también cambiaron estado_gestion sin que hubiese gestión.
-- Sólo restaurar NULL cuando el work item sigue Pendiente y no existe una gestión real posterior.
insert into public.crm_recovery_issue26(entity_type,entity_key,reason,row_data)
select 'work_queue_state', w.work_item_id::text, 'issue26_restore_null_pending', to_jsonb(w)
from public.work_queue w
where w.estado_gestion='Pendiente'
  and exists (
    select 1 from public.crm_events f
    where f.work_item_id=w.work_item_id
      and f.event_type='gestion_saved'
      and f.estado_anterior is null
      and f.estado_nuevo='Pendiente'
  )
  and not exists (
    select 1
    from public.crm_events x
    where x.work_item_id=w.work_item_id
      and x.event_ts > (
        select max(f2.event_ts)
        from public.crm_events f2
        where f2.work_item_id=w.work_item_id
          and f2.event_type='gestion_saved'
          and f2.estado_anterior is null
          and f2.estado_nuevo='Pendiente'
      )
      and not (
        (x.estado_anterior is null and x.estado_nuevo='Pendiente')
        or x.estado_anterior=x.estado_nuevo
      )
  )
on conflict(entity_type,entity_key) do nothing;

update public.work_queue w
set estado_gestion=null,
    updated_at=now()
where w.estado_gestion='Pendiente'
  and exists (
    select 1 from public.crm_events f
    where f.work_item_id=w.work_item_id
      and f.event_type='gestion_saved'
      and f.estado_anterior is null
      and f.estado_nuevo='Pendiente'
  )
  and not exists (
    select 1
    from public.crm_events x
    where x.work_item_id=w.work_item_id
      and x.event_ts > (
        select max(f2.event_ts)
        from public.crm_events f2
        where f2.work_item_id=w.work_item_id
          and f2.event_type='gestion_saved'
          and f2.estado_anterior is null
          and f2.estado_nuevo='Pendiente'
      )
      and not (
        (x.estado_anterior is null and x.estado_nuevo='Pendiente')
        or x.estado_anterior=x.estado_nuevo
      )
  );

-- Si existieran artefactos dentro de un Sprint, corregir sus contadores.
with bad as (
  select sprint_id,
         count(*)::integer as calls_to_remove,
         count(*) filter(where is_agenda)::integer as agendas_to_remove
  from public.crm_events
  where sprint_id is not null
    and event_type='gestion_saved'
    and (
      (estado_anterior is null and estado_nuevo='Pendiente')
      or estado_anterior=estado_nuevo
    )
  group by sprint_id
)
update public.crm_sprints s
set calls_count=greatest(0,s.calls_count-b.calls_to_remove),
    agendas_count=greatest(0,s.agendas_count-b.agendas_to_remove),
    updated_at=now()
from bad b
where s.sprint_id=b.sprint_id;

-- Eliminar logs y eventos respaldados.
delete from public.crm_log l
using public.crm_recovery_issue26 r
where r.entity_type='crm_log'
  and r.reason='issue26_profile_autosave_artifact'
  and l.log_id=r.entity_key::bigint;

delete from public.crm_events e
using public.crm_recovery_issue26 r
where r.entity_type='crm_events'
  and r.reason='issue26_profile_autosave_artifact'
  and e.event_id=r.entity_key::bigint;

-- Registrar resumen de recuperación.
insert into public.crm_recovery_issue26(entity_type,entity_key,reason,row_data)
select 'summary','issue26','issue26_cleanup_summary',jsonb_build_object(
  'events_archived',(select count(*) from public.crm_recovery_issue26 where entity_type='crm_events' and reason='issue26_profile_autosave_artifact'),
  'logs_archived',(select count(*) from public.crm_recovery_issue26 where entity_type='crm_log' and reason='issue26_profile_autosave_artifact'),
  'work_items_restored_to_null',(select count(*) from public.crm_recovery_issue26 where entity_type='work_queue_state' and reason='issue26_restore_null_pending'),
  'sprints_backed_up',(select count(*) from public.crm_recovery_issue26 where entity_type='crm_sprints' and reason='issue26_counter_recovery'),
  'created_at',now()
)
on conflict(entity_type,entity_key) do update
set row_data=excluded.row_data, archived_at=now();

-- Guardar datos de ficha no debe crear gestión si el estado no cambia.
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
  v_target text;
  v_period text := coalesce(p_active_period, active_period());
  v_campaign uuid;
  v_origen text;
  v_rut text;
  v_rut_number bigint;
  v_rut_range text;
  v_hour int := extract(hour from now() at time zone 'America/Santiago')::int;
  v_event_id bigint;
  v_sprint uuid := public.crm_current_sprint_id();
  v_profile_only boolean := false;
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

  v_target := coalesce(nullif(p_estado,''),v_old,'Pendiente');
  v_profile_only := (v_old is not distinct from v_target)
                    or (v_old is null and v_target='Pendiente');

  if v_profile_only then
    update work_queue
       set ingreso_estimado=coalesce(p_ingreso,0),
           comentarios=coalesce(p_comentarios,''),
           updated_at=now()
     where work_item_id=v_work;

    return jsonb_build_object(
      'ok',true,
      'work_item_id',v_work,
      'contact_id',v_contact,
      'event_id',null,
      'sprint_id',null,
      'profile_only',true
    );
  end if;

  v_rut_number := public.crm_rut_number(v_rut);
  v_rut_range := public.crm_rut_range(v_rut);

  update work_queue
     set estado_gestion=v_target,
         ingreso_estimado=coalesce(p_ingreso,0),
         comentarios=coalesce(p_comentarios,''),
         updated_at=now()
   where work_item_id=v_work;

  insert into crm_log(work_item_id,contact_id,estado_anterior,estado_nuevo,ingreso_estimado,comentarios)
  values(v_work,v_contact,v_old,v_target,p_ingreso,p_comentarios);

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
    v_old,v_target,
    public.crm_is_agenda(v_target),lower(coalesce(v_target,''))='no agenda',lower(coalesce(v_target,''))='volver a llamar',lower(coalesce(v_target,''))='no contactado',lower(coalesce(v_target,''))='contacto inválido',
    p_ingreso,
    jsonb_build_object('comentarios_len',length(coalesce(p_comentarios,'')))
  ) returning event_id into v_event_id;

  if v_sprint is not null then
    update public.crm_sprints
       set calls_count=calls_count+1,
           agendas_count=agendas_count+case when public.crm_is_agenda(v_target) then 1 else 0 end,
           updated_at=now()
     where sprint_id=v_sprint and status='running';
  end if;

  return jsonb_build_object('ok',true,'work_item_id',v_work,'contact_id',v_contact,'event_id',v_event_id,'sprint_id',v_sprint,'profile_only',false);
end
$function$;
