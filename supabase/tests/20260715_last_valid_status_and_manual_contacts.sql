-- LCD-20260715-01 · Enmienda ADR-020
-- Valida último estado corporativo válido y contactos manuales.
-- Uso exclusivo en DEV. Todos los fixtures se revierten.

begin;

do $fixture$
declare
  v_period text := '2099-07';
  v_result jsonb;
begin
  insert into public.contacts(contact_id,rut_norm,rut,nombre,search_text)
  values
    ('99000000-0000-0000-0000-000000000001','fixture990000001','99.000.000-1','Fixture estado válido anterior','fixture valid prior'),
    ('99000000-0000-0000-0000-000000000002','fixture990000002','99.000.000-2','Fixture sin estado válido','fixture no valid'),
    ('99000000-0000-0000-0000-000000000003','fixture990000003','99.000.000-3','Fixture contacto manual','fixture manual');

  insert into public.campaigns(campaign_id,period,campaign_key,campaign_name)
  values
    ('99100000-0000-0000-0000-000000000001','2099-05','fixture-valid-2099-05','Fixture mayo'),
    ('99100000-0000-0000-0000-000000000002','2099-06','fixture-valid-2099-06','Fixture junio');

  insert into public.contact_month_state(
    cms_id,contact_id,campaign_id,period,source_priority,import_order,
    is_assigned,visible,estado_origen
  ) values
    ('99200000-0000-0000-0000-000000000001','99000000-0000-0000-0000-000000000001','99100000-0000-0000-0000-000000000001','2099-05',1,1,false,true,'No Gestionado'),
    ('99200000-0000-0000-0000-000000000002','99000000-0000-0000-0000-000000000001','99100000-0000-0000-0000-000000000002','2099-06',1,2,false,true,null),
    ('99200000-0000-0000-0000-000000000003','99000000-0000-0000-0000-000000000002','99100000-0000-0000-0000-000000000002','2099-06',1,3,false,true,null);

  if not exists (
    select 1
    from public.contact_eligibility_for_period(v_period)
    where contact_id='99000000-0000-0000-0000-000000000001'
      and is_gestionable
      and eligibility_reason='latest_no_gestionado'
      and latest_period='2099-05'
      and latest_status='No Gestionado'
  ) then
    raise exception 'FIXTURE invalid later appearance hid the prior valid status';
  end if;

  if not exists (
    select 1
    from public.contact_eligibility_for_period(v_period)
    where contact_id='99000000-0000-0000-0000-000000000002'
      and not is_gestionable
      and eligibility_reason='latest_status_missing'
  ) then
    raise exception 'FIXTURE observed contact without valid status did not fail closed';
  end if;

  if not exists (
    select 1
    from public.contact_eligibility_for_period(v_period)
    where contact_id='99000000-0000-0000-0000-000000000003'
      and is_gestionable
      and eligibility_reason='manual_contact'
      and latest_period is null
      and latest_status is null
  ) then
    raise exception 'FIXTURE manual contact was not gestionable';
  end if;

  v_result := public.rebuild_work_queue_for_period(v_period);
  if coalesce((v_result->>'ok')::boolean,false) is not true then
    raise exception 'FIXTURE rebuild failed: %',v_result;
  end if;

  if not exists (
    select 1 from public.work_queue
    where contact_id='99000000-0000-0000-0000-000000000001'
      and period=v_period and visible and origen='regla'
  ) then
    raise exception 'FIXTURE prior valid No Gestionado was not projected';
  end if;

  if not exists (
    select 1 from public.work_queue
    where contact_id='99000000-0000-0000-0000-000000000003'
      and period=v_period and visible and origen='regla'
      and cms_id is null and campaign_id is null
  ) then
    raise exception 'FIXTURE manual contact was not projected without corporate context';
  end if;

  if exists (
    select 1 from public.work_queue
    where contact_id='99000000-0000-0000-0000-000000000002'
      and period=v_period and visible
  ) then
    raise exception 'FIXTURE contact without any valid corporate status became visible';
  end if;
end
$fixture$;

rollback;

select jsonb_build_object(
  'status','PASS',
  'validation','last_valid_status_and_manual_contacts',
  'newer_invalid_status_ignored',true,
  'manual_contact_gestionable',true,
  'observed_without_valid_status_fail_closed',true,
  'fixtures_rolled_back',true,
  'prod_accessed',false
) as result;
