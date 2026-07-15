-- LCD-20260715-01 · ADR-020
-- Prueba transaccional y reversible de la política canónica.
-- Uso exclusivo en DEV. Todas las filas ficticias se revierten al finalizar.

begin;

do $fixture$
declare
  v_period text := '2099-07';
  v_result jsonb;
  v_count integer;
begin
  insert into public.contacts(contact_id,rut_norm,rut,nombre,search_text)
  values
    ('92000000-0000-0000-0000-000000000001','fixture920000001','92.000.000-1','Fixture asignado','fixture asignado'),
    ('92000000-0000-0000-0000-000000000002','fixture920000002','92.000.000-2','Fixture activo no asignado','fixture activo'),
    ('92000000-0000-0000-0000-000000000003','fixture920000003','92.000.000-3','Fixture histórico no gestionado','fixture historico ng'),
    ('92000000-0000-0000-0000-000000000004','fixture920000004','92.000.000-4','Fixture histórico gestionado','fixture historico g'),
    ('92000000-0000-0000-0000-000000000005','fixture920000005','92.000.000-5','Fixture estado reciente faltante','fixture missing'),
    ('92000000-0000-0000-0000-000000000006','fixture920000006','92.000.000-6','Fixture nunca observado','fixture never'),
    ('92000000-0000-0000-0000-000000000007','fixture920000007','92.000.000-7','Fixture conflicto conservador','fixture conflict');

  insert into public.campaigns(campaign_id,period,campaign_key,campaign_name)
  values
    ('93000000-0000-0000-0000-000000000001','2099-05','fixture-2099-05','Fixture mayo'),
    ('93000000-0000-0000-0000-000000000002','2099-06','fixture-2099-06-a','Fixture junio A'),
    ('93000000-0000-0000-0000-000000000003','2099-06','fixture-2099-06-b','Fixture junio B'),
    ('93000000-0000-0000-0000-000000000004','2099-07','fixture-2099-07','Fixture julio');

  insert into public.contact_month_state(
    cms_id,contact_id,campaign_id,period,source_priority,import_order,is_assigned,visible,estado_origen
  ) values
    ('94000000-0000-0000-0000-000000000001','92000000-0000-0000-0000-000000000001','93000000-0000-0000-0000-000000000004','2099-07',9999,1,true,true,'Gestionado'),
    ('94000000-0000-0000-0000-000000000002','92000000-0000-0000-0000-000000000002','93000000-0000-0000-0000-000000000004','2099-07',1,2,false,true,'No Gestionado'),
    ('94000000-0000-0000-0000-000000000003','92000000-0000-0000-0000-000000000003','93000000-0000-0000-0000-000000000002','2099-06',1,3,false,true,'No Gestionado'),
    ('94000000-0000-0000-0000-000000000004','92000000-0000-0000-0000-000000000004','93000000-0000-0000-0000-000000000002','2099-06',1,4,false,true,'Gestionado'),
    ('94000000-0000-0000-0000-000000000005','92000000-0000-0000-0000-000000000005','93000000-0000-0000-0000-000000000001','2099-05',1,5,false,true,'No Gestionado'),
    ('94000000-0000-0000-0000-000000000006','92000000-0000-0000-0000-000000000005','93000000-0000-0000-0000-000000000002','2099-06',1,6,false,true,null),
    ('94000000-0000-0000-0000-000000000007','92000000-0000-0000-0000-000000000007','93000000-0000-0000-0000-000000000002','2099-06',1,7,false,true,'No Gestionado'),
    ('94000000-0000-0000-0000-000000000008','92000000-0000-0000-0000-000000000007','93000000-0000-0000-0000-000000000003','2099-06',1,8,false,true,'Gestionado');

  create temporary table expected_eligibility(
    contact_id uuid primary key,
    is_gestionable boolean not null,
    eligibility_reason text not null
  ) on commit drop;

  insert into expected_eligibility values
    ('92000000-0000-0000-0000-000000000001',true,'assigned_current'),
    ('92000000-0000-0000-0000-000000000002',false,'active_unassigned'),
    ('92000000-0000-0000-0000-000000000003',true,'latest_no_gestionado'),
    ('92000000-0000-0000-0000-000000000004',false,'latest_gestionado'),
    ('92000000-0000-0000-0000-000000000005',false,'latest_status_missing'),
    ('92000000-0000-0000-0000-000000000006',false,'never_observed'),
    ('92000000-0000-0000-0000-000000000007',false,'latest_gestionado');

  if exists (
    select contact_id,is_gestionable,eligibility_reason
    from public.contact_eligibility_for_period(v_period)
    where contact_id::text like '92000000-%'
    except
    select contact_id,is_gestionable,eligibility_reason from expected_eligibility
  ) or exists (
    select contact_id,is_gestionable,eligibility_reason from expected_eligibility
    except
    select contact_id,is_gestionable,eligibility_reason
    from public.contact_eligibility_for_period(v_period)
    where contact_id::text like '92000000-%'
  ) then
    raise exception 'FIXTURE helper does not match ADR-020';
  end if;

  insert into public.work_queue(
    work_item_id,contact_id,cms_id,period,campaign_id,origen,visible,display_order,
    estado_gestion,ingreso_estimado,comentarios,recordatorio_titulo,recordatorio_fecha_hora
  ) values
    ('95000000-0000-0000-0000-000000000001','92000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000001','2099-07','93000000-0000-0000-0000-000000000004','asignado',false,1,'Agenda',12345,'preservar asignado','Recordatorio asignado','2099-07-20 10:30:00+00'),
    ('95000000-0000-0000-0000-000000000002','92000000-0000-0000-0000-000000000002','94000000-0000-0000-0000-000000000002','2099-07','93000000-0000-0000-0000-000000000004','regla',true,2,'Volver a llamar',54321,'preservar excluido','Recordatorio excluido','2099-07-21 11:30:00+00');

  v_result := public.rebuild_work_queue_for_period(v_period);
  if coalesce((v_result->>'ok')::boolean,false) is not true then
    raise exception 'FIXTURE rebuild failed: %',v_result;
  end if;

  if not exists (
    select 1 from public.work_queue
    where contact_id='92000000-0000-0000-0000-000000000001'
      and period=v_period and visible and origen='asignado'
      and estado_gestion='Agenda' and ingreso_estimado=12345
      and comentarios='preservar asignado'
      and recordatorio_titulo='Recordatorio asignado'
  ) then
    raise exception 'FIXTURE rebuild did not preserve assigned user facts';
  end if;

  if not exists (
    select 1 from public.work_queue
    where contact_id='92000000-0000-0000-0000-000000000002'
      and period=v_period and not visible
      and estado_gestion='Volver a llamar' and ingreso_estimado=54321
      and comentarios='preservar excluido'
      and recordatorio_titulo='Recordatorio excluido'
  ) then
    raise exception 'FIXTURE rebuild did not preserve hidden user facts';
  end if;

  insert into public.staging_contacts(
    import_session_id,load_type,period,import_order,rut_norm,rut,nombre,
    campaign_name,campaign_key,estado_origen
  ) values (
    '96000000-0000-0000-0000-000000000001','mensual','2099-07',2,
    'fixture920000002','92.000.000-2','Fixture activo no asignado',
    'Fixture julio','fixture-2099-07','No Gestionado'
  );

  update public.work_queue
     set visible=true
   where contact_id='92000000-0000-0000-0000-000000000002' and period=v_period;

  v_result := public.sync_work_queue_for_period_batch(
    v_period,2,2,'96000000-0000-0000-0000-000000000001'
  );
  if exists (
    select 1 from public.work_queue
    where contact_id='92000000-0000-0000-0000-000000000002'
      and period=v_period and visible
  ) then
    raise exception 'FIXTURE batch sync published active unassigned';
  end if;

  v_result := public.get_contacts_v2(
    v_period,'fixture92000000','gestionables',false,false,
    array[]::text[],array[]::text[],'any',200,0
  );
  select count(*) into v_count
  from jsonb_array_elements(v_result->'rows') r
  where r->>'contact_id' in (
    '92000000-0000-0000-0000-000000000001',
    '92000000-0000-0000-0000-000000000003'
  );
  if v_count <> 2 then
    raise exception 'FIXTURE get_contacts_v2 missing eligible rows: %',v_result;
  end if;
end
$fixture$;

rollback;

select jsonb_build_object(
  'status','PASS',
  'validation','canonical_eligibility_transactional_fixtures',
  'fixtures_rolled_back',true,
  'prod_accessed',false
) as result;
