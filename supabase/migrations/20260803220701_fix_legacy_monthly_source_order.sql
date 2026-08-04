create table if not exists public.monthly_source_order (
  period text not null,
  contact_id uuid not null references public.contacts(contact_id) on delete cascade,
  source_row integer not null check (source_row > 0),
  source_session uuid,
  source_file text,
  source_sha256 text,
  updated_at timestamptz not null default now(),
  primary key (period, contact_id)
);
create index if not exists monthly_source_order_period_row_idx on public.monthly_source_order(period, source_row, contact_id);
alter table public.monthly_source_order enable row level security;
revoke all on table public.monthly_source_order from anon, authenticated;
comment on table public.monthly_source_order is 'Canonical global row position of each contact in a monthly TOTAL source. Read through SECURITY DEFINER functions; not exposed to Legacy clients.';
comment on column public.monthly_source_order.source_row is 'One-based data-row position in the complete monthly source, excluding the header.';

create or replace function public.contact_eligibility_for_period(p_period text)
returns table(contact_id uuid,is_gestionable boolean,eligibility_reason text,assigned_current boolean,appears_active boolean,latest_cms_id uuid,latest_campaign_id uuid,latest_period text,latest_import_order integer,latest_status text,assigned_cms_id uuid,assigned_campaign_id uuid,assigned_order integer,context_cms_id uuid,context_campaign_id uuid,context_order integer)
language sql stable security definer set search_path to 'public','pg_temp'
as $function$
with current_assigned as (
  select distinct on (cms.contact_id) cms.contact_id,cms.cms_id,cms.campaign_id,cms.import_order
  from public.contact_month_state cms
  where cms.period=p_period and cms.visible and cms.is_assigned
  order by cms.contact_id,cms.source_priority desc,cms.import_order asc nulls last,cms.last_seen_at desc,cms.cms_id
),
active_presence as (
  select distinct cms.contact_id from public.contact_month_state cms where cms.period=p_period and cms.visible
),
observed_presence as (
  select distinct cms.contact_id from public.contact_month_state cms where cms.visible and cms.period<=p_period
),
valid_status_rows as (
  select cms.contact_id,cms.cms_id,cms.campaign_id,cms.period,cms.import_order,cms.source_priority,cms.last_seen_at,
    case when lower(trim(cms.estado_origen))='gestionado' then 'Gestionado' when lower(trim(cms.estado_origen))='no gestionado' then 'No Gestionado' end as estado_normalizado
  from public.contact_month_state cms
  where cms.visible and cms.period<=p_period and lower(trim(coalesce(cms.estado_origen,''))) in ('gestionado','no gestionado')
),
latest_valid_period as (
  select vsr.contact_id,max(vsr.period) as period from valid_status_rows vsr group by vsr.contact_id
),
latest_valid_status as (
  select distinct on (vsr.contact_id) vsr.contact_id,vsr.cms_id,vsr.campaign_id,vsr.period,vsr.import_order,vsr.estado_normalizado
  from valid_status_rows vsr join latest_valid_period lvp on lvp.contact_id=vsr.contact_id and lvp.period=vsr.period
  order by vsr.contact_id,case when vsr.estado_normalizado='Gestionado' then 0 else 1 end,vsr.source_priority desc,vsr.import_order asc nulls last,vsr.last_seen_at desc,vsr.cms_id
)
select c.contact_id,
  case when ca.contact_id is not null then true when ap.contact_id is not null then false when lvs.estado_normalizado='No Gestionado' then true when op.contact_id is null then true else false end,
  case when ca.contact_id is not null then 'assigned_current' when ap.contact_id is not null then 'active_unassigned' when lvs.estado_normalizado='No Gestionado' then 'latest_no_gestionado' when lvs.estado_normalizado='Gestionado' then 'latest_gestionado' when op.contact_id is null then 'manual_contact' else 'latest_status_missing' end,
  (ca.contact_id is not null),(ap.contact_id is not null),lvs.cms_id,lvs.campaign_id,lvs.period,lvs.import_order,lvs.estado_normalizado,
  ca.cms_id,ca.campaign_id,ca.import_order,coalesce(ca.cms_id,lvs.cms_id),coalesce(ca.campaign_id,lvs.campaign_id),
  case
    when ca.contact_id is not null then coalesce(ca.import_order,999999)
    when lvs.period ~ '^[0-9]{4}-[0-9]{2}$' and p_period ~ '^[0-9]{4}-[0-9]{2}$' then
      least(1999999999,1000000+greatest(0,((substring(p_period,1,4)::integer*12+substring(p_period,6,2)::integer)-(substring(lvs.period,1,4)::integer*12+substring(lvs.period,6,2)::integer)))*1000000+least(coalesce(mso.source_row,lvs.import_order,999999),999999))::integer
    when lvs.period is not null then least(1999999999,1000000000+least(coalesce(mso.source_row,lvs.import_order,999999),999999))::integer
    else 2000000000
  end
from public.contacts c
left join current_assigned ca on ca.contact_id=c.contact_id
left join active_presence ap on ap.contact_id=c.contact_id
left join observed_presence op on op.contact_id=c.contact_id
left join latest_valid_status lvs on lvs.contact_id=c.contact_id
left join public.monthly_source_order mso on mso.contact_id=c.contact_id and mso.period=lvs.period
$function$;
comment on function public.contact_eligibility_for_period(text) is 'Canonical monthly eligibility. Assigned contacts keep assigned order; rule contacts are ordered by newest source month and global source row.';

create or replace function public.rebuild_work_queue_for_period(p_period text)
returns jsonb language plpgsql security definer set search_path to 'public' set statement_timeout to '300s'
as $function$
declare v_total integer:=0;v_assigned integer:=0;v_rule integer:=0;v_status_rows integer:=0;v_missing_status_rows integer:=0;v_source_session uuid;v_source_order_rows integer:=0;
begin
  perform set_config('statement_timeout','120000',true);
  select s.import_session_id into v_source_session
  from public.staging_contacts s
  where s.period=p_period and lower(trim(coalesce(s.load_type,'')))='mensual'
  group by s.import_session_id
  order by max(s.created_at) desc,s.import_session_id desc limit 1;
  if v_source_session is not null then
    with src as (
      select distinct on (s.rut_norm) s.period,s.rut_norm,coalesce(s.import_order,s.staging_id)::integer as source_row
      from public.staging_contacts s
      where s.import_session_id=v_source_session and s.period=p_period and lower(trim(coalesce(s.load_type,'')))='mensual'
      order by s.rut_norm,coalesce(s.import_order,s.staging_id) asc,s.staging_id asc
    ),upserted_order as (
      insert into public.monthly_source_order(period,contact_id,source_row,source_session,source_file,source_sha256,updated_at)
      select src.period,c.contact_id,src.source_row,v_source_session,null,null,now()
      from src join public.contacts c on c.rut_norm=src.rut_norm
      on conflict(period,contact_id) do update set source_row=excluded.source_row,source_session=excluded.source_session,source_file=excluded.source_file,source_sha256=excluded.source_sha256,updated_at=now()
      returning 1
    ) select count(*) into v_source_order_rows from upserted_order;
  end if;
  select count(*) filter(where lower(trim(coalesce(estado_origen,''))) in ('gestionado','no gestionado')),
         count(*) filter(where nullif(trim(coalesce(estado_origen,'')),'') is null or lower(trim(estado_origen)) not in ('gestionado','no gestionado'))
    into v_status_rows,v_missing_status_rows from public.contact_month_state where visible;
  update public.work_queue set visible=false,updated_at=now() where period=p_period and visible;
  with eligible as (
    select e.contact_id,e.context_cms_id as cms_id,e.context_campaign_id as campaign_id,case when e.assigned_current then 'asignado' else 'regla' end as origen,e.context_order as display_order
    from public.contact_eligibility_for_period(p_period) e where e.is_gestionable
  ),upserted as (
    insert into public.work_queue(contact_id,cms_id,period,campaign_id,origen,visible,display_order)
    select e.contact_id,e.cms_id,p_period,e.campaign_id,e.origen,true,e.display_order from eligible e
    on conflict(contact_id,period) do update set cms_id=excluded.cms_id,campaign_id=excluded.campaign_id,origen=excluded.origen,visible=true,display_order=excluded.display_order,updated_at=now()
    returning origen
  )
  select count(*),count(*) filter(where origen='asignado'),count(*) filter(where origen='regla') into v_total,v_assigned,v_rule from upserted;
  return jsonb_build_object('ok',true,'period',p_period,'rule','canonical_monthly_eligibility_v1_source_order','visible_total_rows',v_total,'visible_assigned_rows',v_assigned,'visible_rule_rows',v_rule,'valid_status_rows',v_status_rows,'missing_or_invalid_status_rows',v_missing_status_rows,'missing_status_behavior','fail_closed','source_order_session',v_source_session,'source_order_rows',v_source_order_rows);
end
$function$;
comment on function public.rebuild_work_queue_for_period(text) is 'Rebuilds the queue and captures canonical monthly source order from the active Legacy staging session before cleanup.';
