create or replace function public.process_assigned_load(p_session uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_period text;
  v_total int;
  v_source_managed int := 0;
  v_source_pending int := 0;
  v_applied_managed int := 0;
begin
  perform public.process_monthly_contacts_batch(p_session,0,2147483647);
  perform public.process_monthly_state_batch(p_session,0,2147483647,9999);

  select max(period),
         count(*),
         count(*) filter (where lower(trim(coalesce(estado_origen,''))) = 'gestionado'),
         count(*) filter (where lower(trim(coalesce(estado_origen,''))) = 'no gestionado')
    into v_period, v_total, v_source_managed, v_source_pending
  from public.staging_contacts
  where import_session_id=p_session;

  perform public.rebuild_work_queue_for_period(v_period);

  with source_rows as (
    select distinct on (c.contact_id)
           c.contact_id,
           s.period,
           lower(trim(coalesce(s.estado_origen,''))) as source_status,
           coalesce(s.import_order,s.staging_id) as source_order
    from public.staging_contacts s
    join public.contacts c on c.rut_norm=s.rut_norm
    where s.import_session_id=p_session
    order by c.contact_id, coalesce(s.import_order,s.staging_id)
  ), updated as (
    update public.work_queue w
       set estado_gestion='Gestionado',
           updated_at=now()
      from source_rows s
     where w.contact_id=s.contact_id
       and w.period=s.period
       and s.source_status='gestionado'
       and (w.estado_gestion is null or w.estado_gestion='Pendiente')
    returning 1
  )
  select count(*) into v_applied_managed from updated;

  update public.work_queue w
     set estado_gestion='Pendiente',
         updated_at=now()
    from public.staging_contacts s
    join public.contacts c on c.rut_norm=s.rut_norm
   where s.import_session_id=p_session
     and w.contact_id=c.contact_id
     and w.period=s.period
     and lower(trim(coalesce(s.estado_origen,'')))='no gestionado'
     and w.estado_gestion is null;

  return jsonb_build_object(
    'ok',true,
    'asignados',v_total,
    'period',v_period,
    'source_managed',v_source_managed,
    'source_pending',v_source_pending,
    'applied_managed',v_applied_managed
  );
end
$function$;

revoke all on function public.process_assigned_load(uuid) from public, anon;
grant execute on function public.process_assigned_load(uuid) to authenticated;
