-- LCD-20260715-01 · Enmienda ADR-020
-- Refinamiento de dominio:
-- 1. una aparición sin estado no oculta el último estado corporativo válido;
-- 2. un contacto sin ninguna aparición corporativa es manual y gestionable;
-- 3. un contacto observado, pero sin ningún estado válido, permanece fail-closed.

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
observed_presence as (
  select distinct cms.contact_id
  from public.contact_month_state cms
  where cms.visible
    and cms.period <= p_period
),
valid_status_rows as (
  select
    cms.contact_id,
    cms.cms_id,
    cms.campaign_id,
    cms.period,
    cms.import_order,
    cms.source_priority,
    cms.last_seen_at,
    case
      when lower(trim(cms.estado_origen)) = 'gestionado' then 'Gestionado'
      when lower(trim(cms.estado_origen)) = 'no gestionado' then 'No Gestionado'
    end as estado_normalizado
  from public.contact_month_state cms
  where cms.visible
    and cms.period <= p_period
    and lower(trim(coalesce(cms.estado_origen,''))) in ('gestionado','no gestionado')
),
latest_valid_period as (
  select vsr.contact_id, max(vsr.period) as period
  from valid_status_rows vsr
  group by vsr.contact_id
),
latest_valid_status as (
  select distinct on (vsr.contact_id)
    vsr.contact_id,
    vsr.cms_id,
    vsr.campaign_id,
    vsr.period,
    vsr.import_order,
    vsr.estado_normalizado
  from valid_status_rows vsr
  join latest_valid_period lvp
    on lvp.contact_id = vsr.contact_id
   and lvp.period = vsr.period
  order by
    vsr.contact_id,
    case when vsr.estado_normalizado = 'Gestionado' then 0 else 1 end,
    vsr.source_priority desc,
    vsr.import_order asc nulls last,
    vsr.last_seen_at desc,
    vsr.cms_id
)
select
  c.contact_id,
  case
    when ca.contact_id is not null then true
    when ap.contact_id is not null then false
    when lvs.estado_normalizado = 'No Gestionado' then true
    when op.contact_id is null then true
    else false
  end as is_gestionable,
  case
    when ca.contact_id is not null then 'assigned_current'
    when ap.contact_id is not null then 'active_unassigned'
    when lvs.estado_normalizado = 'No Gestionado' then 'latest_no_gestionado'
    when lvs.estado_normalizado = 'Gestionado' then 'latest_gestionado'
    when op.contact_id is null then 'manual_contact'
    else 'latest_status_missing'
  end as eligibility_reason,
  (ca.contact_id is not null) as assigned_current,
  (ap.contact_id is not null) as appears_active,
  lvs.cms_id as latest_cms_id,
  lvs.campaign_id as latest_campaign_id,
  lvs.period as latest_period,
  lvs.import_order as latest_import_order,
  lvs.estado_normalizado as latest_status,
  ca.cms_id as assigned_cms_id,
  ca.campaign_id as assigned_campaign_id,
  ca.import_order as assigned_order,
  coalesce(ca.cms_id,lvs.cms_id) as context_cms_id,
  coalesce(ca.campaign_id,lvs.campaign_id) as context_campaign_id,
  coalesce(ca.import_order,lvs.import_order) as context_order
from public.contacts c
left join current_assigned ca on ca.contact_id = c.contact_id
left join active_presence ap on ap.contact_id = c.contact_id
left join observed_presence op on op.contact_id = c.contact_id
left join latest_valid_status lvs on lvs.contact_id = c.contact_id
$function$;

revoke all on function public.contact_eligibility_for_period(text)
  from public, anon, authenticated;

comment on function public.contact_eligibility_for_period(text) is
  'ADR-020 enmendado: asignación; exclusión activa; último estado corporativo válido; contacto manual. No expuesta al cliente.';
