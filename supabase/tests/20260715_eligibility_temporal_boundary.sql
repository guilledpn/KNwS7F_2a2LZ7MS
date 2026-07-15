-- LCD-20260715-01 · ADR-020
-- Una aparición futura no puede alterar la elegibilidad de un período anterior.
-- Uso exclusivo en DEV. Todos los fixtures se revierten.

begin;

do $fixture$
begin
  insert into public.contacts(contact_id,rut_norm,rut,nombre,search_text)
  values (
    '98000000-0000-0000-0000-000000000001',
    'fixture980000001',
    '98.000.000-1',
    'Fixture frontera temporal',
    'fixture temporal'
  );

  insert into public.campaigns(campaign_id,period,campaign_key,campaign_name)
  values
    ('98100000-0000-0000-0000-000000000001','2099-06','fixture-temporal-2099-06','Fixture junio'),
    ('98100000-0000-0000-0000-000000000002','2099-08','fixture-temporal-2099-08','Fixture agosto');

  insert into public.contact_month_state(
    cms_id,contact_id,campaign_id,period,source_priority,import_order,
    is_assigned,visible,estado_origen
  ) values
    ('98200000-0000-0000-0000-000000000001','98000000-0000-0000-0000-000000000001','98100000-0000-0000-0000-000000000001','2099-06',1,1,false,true,'No Gestionado'),
    ('98200000-0000-0000-0000-000000000002','98000000-0000-0000-0000-000000000001','98100000-0000-0000-0000-000000000002','2099-08',1,2,false,true,'Gestionado');

  if not exists (
    select 1
    from public.contact_eligibility_for_period('2099-07')
    where contact_id='98000000-0000-0000-0000-000000000001'
      and is_gestionable
      and eligibility_reason='latest_no_gestionado'
      and latest_period='2099-06'
  ) then
    raise exception 'FIXTURE future appearance leaked into historical evaluation';
  end if;
end
$fixture$;

rollback;

select jsonb_build_object(
  'status','PASS',
  'validation','eligibility_temporal_boundary',
  'future_appearance_ignored_for_prior_period',true,
  'fixtures_rolled_back',true,
  'prod_accessed',false
) as result;
