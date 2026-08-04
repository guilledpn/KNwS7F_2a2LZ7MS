-- Issue #45: regularize the monthly source-order hotfix before activation.
--
-- This migration restores the pre-existing ASIGNADOS contract that was
-- accidentally removed by 20260803230452_harden_monthly_source_order_capture
-- and closes the temporary privileged RPC surface. It does not rebuild or
-- mutate work_queue membership.

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

  -- ASIGNADOS uses priority 9999 and keeps its own queue order. Only TOTAL
  -- sessions may replace the canonical global order of a monthly source.
  if p_source_priority < 9999 then
    delete from public.monthly_source_order m
    using (
      select distinct s.period
      from public.staging_contacts s
      where s.import_session_id = p_session
        and coalesce(s.import_order,s.staging_id)
            between p_start_order and p_end_order
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
        and coalesce(s.import_order,s.staging_id)
            between p_start_order and p_end_order
      group by s.period,ct.contact_id
    ), captured as (
      insert into public.monthly_source_order(
        period,contact_id,source_row,source_session,source_file,
        source_sha256,updated_at
      )
      select
        o.period,o.contact_id,o.source_row,p_session,null,null,now()
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
    select
      s.*,
      coalesce(
        nullif(s.campaign_key,''),
        public.norm_campaign_key(s.campaign_name)
      ) as ck
    from public.staging_contacts s
    where s.import_session_id = p_session
      and coalesce(s.import_order,s.staging_id)
          between p_start_order and p_end_order
  ), s as (
    select distinct on (rut_norm,period,ck) *
    from s_raw
    order by
      rut_norm,period,ck,
      coalesce(import_order,staging_id) desc,
      staging_id desc
  ), counted as (
    select count(*)::integer as n from s
  ), camp_src as (
    select distinct on (period,ck)
      period,
      ck,
      nullif(campaign_name,'') as campaign_name,
      nullif(campaign_desc,'') as campaign_desc
    from s_raw
    order by
      period,ck,
      case when nullif(campaign_name,'') is null then 1 else 0 end,
      case when nullif(campaign_desc,'') is null then 1 else 0 end,
      coalesce(import_order,staging_id) desc,
      staging_id desc
  ), camp as (
    insert into public.campaigns(
      period,campaign_key,campaign_name,campaign_desc
    )
    select period,ck,campaign_name,campaign_desc
    from camp_src
    on conflict(period,campaign_key) do update set
      campaign_name = coalesce(
        excluded.campaign_name,public.campaigns.campaign_name
      ),
      campaign_desc = coalesce(
        excluded.campaign_desc,public.campaigns.campaign_desc
      )
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
      on x.period = c.period and x.ck = c.campaign_key
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
      lower(trim(coalesce(s.load_type,''))) in ('asignado','assigned'),
      true,
      now(),
      nullif(trim(s.estado_origen),'')
    from s
    join public.contacts ct on ct.rut_norm = s.rut_norm
    join allcamp ac on ac.period = s.period and ac.campaign_key = s.ck
    on conflict(contact_id,campaign_id,period) do update set
      source_priority = greatest(
        public.contact_month_state.source_priority,excluded.source_priority
      ),
      import_order = excluded.import_order,
      is_assigned = public.contact_month_state.is_assigned
        or excluded.is_assigned,
      visible = true,
      last_seen_at = now(),
      estado_origen = coalesce(
        excluded.estado_origen,public.contact_month_state.estado_origen
      )
    where public.contact_month_state.visible is distinct from true
       or public.contact_month_state.estado_origen is distinct from
          coalesce(
            excluded.estado_origen,
            public.contact_month_state.estado_origen
          )
       or public.contact_month_state.is_assigned is distinct from
          (public.contact_month_state.is_assigned or excluded.is_assigned)
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

-- The helper is internal. The authenticated Legacy client reaches ordering
-- only through the established import RPCs; it must not call this privileged
-- mutation directly.
revoke all on function public.apply_monthly_source_order_to_queue(text)
  from public,anon,authenticated;
grant execute on function public.apply_monthly_source_order_to_queue(text)
  to service_role;

alter table public.monthly_source_order enable row level security;
revoke all on table public.monthly_source_order
  from public,anon,authenticated;
