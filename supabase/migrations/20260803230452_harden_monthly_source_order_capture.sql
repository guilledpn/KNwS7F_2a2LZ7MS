-- Harden the additive monthly source-order fix.
--
-- Goals:
--   1. Capture the original global row of monthly TOTAL loads only.
--   2. Never let an ASIGNADOS load overwrite monthly source order.
--   3. Reorder existing visible queue rows without changing membership or state.
--
-- This migration is intentionally additive and preserves Legacy contracts.

create or replace function public.process_monthly_state_batch(
  p_session uuid,
  p_start_order integer default 0,
  p_end_order integer default 2147483647,
  p_source_priority integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
set statement_timeout to '120s'
as $function$
declare
  v_scanned integer := 0;
  v_changed integer := 0;
  v_order_rows integer := 0;
begin
  perform set_config('statement_timeout','120000',true);

  -- Source priority 9999 is the established ASIGNADOS path.  It must retain
  -- its own order in work_queue, but it must not replace the global order of
  -- the monthly TOTAL file.
  if p_source_priority < 9999 then
    -- A new monthly session replaces the previous canonical order for the
    -- period.  This delete runs only on the first processed batch because the
    -- subsequent rows already carry p_session.
    delete from public.monthly_source_order m
    using (
      select distinct s.period
      from public.staging_contacts s
      where s.import_session_id = p_session
        and coalesce(s.import_order,s.staging_id) between p_start_order and p_end_order
    ) p
    where m.period = p.period
      and m.source_session is distinct from p_session;

    with order_src as (
      select
        s.period,
        ct.contact_id,
        min(coalesce(s.import_order,s.staging_id))::integer as source_row
      from public.staging_contacts s
      join public.contacts ct on ct.rut_norm = s.rut_norm
      where s.import_session_id = p_session
        and coalesce(s.import_order,s.staging_id) between p_start_order and p_end_order
      group by s.period,ct.contact_id
    ), captured as (
      insert into public.monthly_source_order(
        period,contact_id,source_row,source_session,source_file,source_sha256,updated_at
      )
      select
        o.period,
        o.contact_id,
        o.source_row,
        p_session,
        null,
        null,
        now()
      from order_src o
      on conflict(period,contact_id) do update set
        source_row = case
          when public.monthly_source_order.source_session = excluded.source_session
            then least(public.monthly_source_order.source_row,excluded.source_row)
          else excluded.source_row
        end,
        source_session = excluded.source_session,
        source_file = excluded.source_file,
        source_sha256 = excluded.source_sha256,
        updated_at = now()
      returning 1
    )
    select count(*)::integer into v_order_rows from captured;
  end if;

  with s_raw as (
    select *,coalesce(nullif(campaign_key,''),public.norm_campaign_key(campaign_name)) as ck
    from public.staging_contacts
    where import_session_id=p_session
      and coalesce(import_order,staging_id) between p_start_order and p_end_order
  ), s as (
    select distinct on (rut_norm,period,ck) *
    from s_raw
    order by rut_norm,period,ck,coalesce(import_order,staging_id) desc,staging_id desc
  ), counted as (
    select count(*)::integer as n from s
  ), camp_src as (
    select distinct on (period,ck)
      period,
      ck,
      nullif(campaign_name,'') as campaign_name,
      nullif(campaign_desc,'') as campaign_desc
    from s_raw
    order by period,ck,
      case when nullif(campaign_name,'') is null then 1 else 0 end,
      case when nullif(campaign_desc,'') is null then 1 else 0 end,
      coalesce(import_order,staging_id) desc,
      staging_id desc
  ), camp as (
    insert into public.campaigns(period,campaign_key,campaign_name,campaign_desc)
    select period,ck,campaign_name,campaign_desc
    from camp_src
    on conflict(period,campaign_key) do update set
      campaign_name=coalesce(excluded.campaign_name,public.campaigns.campaign_name),
      campaign_desc=coalesce(excluded.campaign_desc,public.campaigns.campaign_desc)
    where (public.campaigns.campaign_name,public.campaigns.campaign_desc)
      is distinct from (
        coalesce(excluded.campaign_name,public.campaigns.campaign_name),
        coalesce(excluded.campaign_desc,public.campaigns.campaign_desc)
      )
    returning campaign_id,period,campaign_key
  ), allcamp as (
    select campaign_id,period,campaign_key from camp
    union
    select c.campaign_id,c.period,c.campaign_key
    from public.campaigns c
    join (select distinct period,ck from s_raw) x
      on x.period=c.period and x.ck=c.campaign_key
  ), changed as (
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
      false,
      true,
      now(),
      nullif(trim(s.estado_origen),'')
    from s
    join public.contacts ct on ct.rut_norm=s.rut_norm
    join allcamp ac on ac.period=s.period and ac.campaign_key=s.ck
    on conflict(contact_id,campaign_id,period) do update set
      source_priority=greatest(public.contact_month_state.source_priority,excluded.source_priority),
      import_order=excluded.import_order,
      visible=true,
      last_seen_at=now(),
      estado_origen=coalesce(excluded.estado_origen,public.contact_month_state.estado_origen)
    where public.contact_month_state.visible is distinct from true
       or public.contact_month_state.estado_origen is distinct from coalesce(excluded.estado_origen,public.contact_month_state.estado_origen)
    returning 1
  )
  select
    (select n from counted),
    (select count(*)::integer from changed)
  into v_scanned,v_changed;

  return jsonb_build_object(
    'ok',true,
    'processed',coalesce(v_scanned,0),
    'scanned',coalesce(v_scanned,0),
    'changed',coalesce(v_changed,0),
    'source_order_captured',coalesce(v_order_rows,0),
    'work_queue_synced',0
  );
end
$function$;

create or replace function public.apply_monthly_source_order_to_queue(p_period text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
set statement_timeout to '120s'
as $function$
declare
  v_changed integer := 0;
begin
  -- This function never inserts, hides or deletes queue rows.  It only updates
  -- display_order for visible rule rows that have a canonical source row.
  with updated as (
    update public.work_queue w
    set display_order = least(
          2147483646,
          (
            1000000::bigint
            + 1000000::bigint * greatest(
                0,
                (
                  substring(p_period,1,4)::integer * 12
                  + substring(p_period,6,2)::integer
                )
                - (
                  substring(cms.period,1,4)::integer * 12
                  + substring(cms.period,6,2)::integer
                )
              )
            + mso.source_row::bigint
          )
        )::integer,
        updated_at = now()
    from public.contact_month_state cms
    join public.monthly_source_order mso
      on mso.period = cms.period
     and mso.contact_id = cms.contact_id
    where w.cms_id = cms.cms_id
      and w.period = p_period
      and w.visible
      and w.origen = 'regla'
      and w.display_order is distinct from least(
            2147483646,
            (
              1000000::bigint
              + 1000000::bigint * greatest(
                  0,
                  (
                    substring(p_period,1,4)::integer * 12
                    + substring(p_period,6,2)::integer
                  )
                  - (
                    substring(cms.period,1,4)::integer * 12
                    + substring(cms.period,6,2)::integer
                  )
                )
              + mso.source_row::bigint
            )
          )::integer
    returning 1
  )
  select count(*)::integer into v_changed from updated;

  return jsonb_build_object(
    'ok',true,
    'period',p_period,
    'updated_display_orders',coalesce(v_changed,0),
    'membership_changed',false,
    'states_changed',false
  );
end
$function$;

-- The canonical rebuild uses monthly_source_order through
-- contact_eligibility_for_period.  It must not infer monthly order from any
-- staging rows because an ASIGNADOS load also uses staging_contacts.
create or replace function public.rebuild_work_queue_for_period(p_period text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
set statement_timeout to '300s'
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
  into v_status_rows,v_missing_status_rows
  from public.contact_month_state
  where visible;

  update public.work_queue
     set visible=false,
         updated_at=now()
   where period=p_period
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
  ), upserted as (
    insert into public.work_queue(
      contact_id,cms_id,period,campaign_id,origen,visible,display_order
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
      cms_id=excluded.cms_id,
      campaign_id=excluded.campaign_id,
      origen=excluded.origen,
      visible=true,
      display_order=excluded.display_order,
      updated_at=now()
    returning origen
  )
  select
    count(*),
    count(*) filter(where origen='asignado'),
    count(*) filter(where origen='regla')
  into v_total,v_assigned,v_rule
  from upserted;

  return jsonb_build_object(
    'ok',true,
    'period',p_period,
    'rule','canonical_monthly_eligibility_v1',
    'ordering','monthly_source_order_v1',
    'visible_total_rows',v_total,
    'visible_assigned_rows',v_assigned,
    'visible_rule_rows',v_rule,
    'valid_status_rows',v_status_rows,
    'missing_or_invalid_status_rows',v_missing_status_rows,
    'missing_status_behavior','fail_closed'
  );
end
$function$;

create or replace function public.sync_work_queue_for_staging_session(p_session uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  r record;
  v_total integer := 0;
  v_reordered integer := 0;
  v_res jsonb;
  v_order_res jsonb;
begin
  for r in
    select
      period,
      min(coalesce(import_order,staging_id))::integer as min_order,
      max(coalesce(import_order,staging_id))::integer as max_order
    from public.staging_contacts
    where import_session_id=p_session
    group by period
  loop
    v_res := public.sync_work_queue_for_period_batch(
      r.period,r.min_order,r.max_order,p_session
    );
    v_total := v_total + coalesce((v_res->>'processed')::integer,0);

    v_order_res := public.apply_monthly_source_order_to_queue(r.period);
    v_reordered := v_reordered
      + coalesce((v_order_res->>'updated_display_orders')::integer,0);
  end loop;

  return jsonb_build_object(
    'ok',true,
    'session',p_session,
    'processed',v_total,
    'reordered',v_reordered
  );
end
$function$;

revoke all on function public.apply_monthly_source_order_to_queue(text) from public;
grant execute on function public.apply_monthly_source_order_to_queue(text) to authenticated;
