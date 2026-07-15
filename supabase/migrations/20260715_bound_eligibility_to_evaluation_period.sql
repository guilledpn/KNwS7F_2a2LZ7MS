-- LCD-20260715-01 · ADR-020
-- La última aparición corporativa debe ser relativa al período evaluado.
-- Evita que una campaña futura altere retroactivamente la gestionabilidad.

create or replace function public.contact_eligibility_for_period(p_period text)
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
    and cms.period <= p_period
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

comment on function public.contact_eligibility_for_period(text) is
  'ADR-020: política canónica interna limitada al período evaluado. No expuesta al cliente.';
