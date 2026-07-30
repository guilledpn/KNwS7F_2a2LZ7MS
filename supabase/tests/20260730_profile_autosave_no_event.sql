-- Issue #26 · autosave de ficha no debe crear gestión.
begin;

do $bootstrap$
begin
  if to_regprocedure('public.crm_current_sprint_id()') is null then
    execute 'create function public.crm_current_sprint_id() returns uuid language sql stable as $$ select null::uuid $$';
  end if;
  if to_regprocedure('public.crm_rut_number(text)') is null then
    execute 'create function public.crm_rut_number(text) returns bigint language sql immutable as $$ select null::bigint $$';
  end if;
  if to_regprocedure('public.crm_rut_range(text)') is null then
    execute 'create function public.crm_rut_range(text) returns text language sql immutable as $$ select null::text $$';
  end if;
  if to_regprocedure('public.crm_hour_block(integer)') is null then
    execute 'create function public.crm_hour_block(integer) returns text language sql immutable as $$ select ''test''::text $$';
  end if;
  if to_regprocedure('public.crm_is_agenda(text)') is null then
    execute 'create function public.crm_is_agenda(text) returns boolean language sql immutable as $$ select lower(coalesce($1,''''))=''agenda'' $$';
  end if;
end
$bootstrap$;

do $test$
declare
  v_work uuid;
  v_contact uuid;
  v_before_events integer;
  v_before_logs integer;
  v_after_events integer;
  v_after_logs integer;
  v_state text;
  v_result jsonb;
begin
  select work_item_id,contact_id
    into v_work,v_contact
  from public.work_queue
  where estado_gestion is null
  limit 1;

  if v_work is null then
    raise exception 'Fixture requires a null-state work_queue row';
  end if;

  select count(*) into v_before_events from public.crm_events where work_item_id=v_work;
  select count(*) into v_before_logs from public.crm_log where work_item_id=v_work;

  v_result := public.save_gestion_v2(v_work,v_contact,null,'Pendiente',1234567,'profile-only');
  if coalesce((v_result->>'profile_only')::boolean,false) is not true then
    raise exception 'null -> Pendiente must be profile_only: %',v_result;
  end if;

  select estado_gestion into v_state from public.work_queue where work_item_id=v_work;
  if v_state is not null then
    raise exception 'Profile autosave must not convert NULL state to Pendiente: %',v_state;
  end if;

  select count(*) into v_after_events from public.crm_events where work_item_id=v_work;
  select count(*) into v_after_logs from public.crm_log where work_item_id=v_work;
  if v_after_events<>v_before_events or v_after_logs<>v_before_logs then
    raise exception 'Profile autosave created history';
  end if;

  v_result := public.save_gestion_v2(v_work,v_contact,null,'No contactado',1234567,'real-management');
  if coalesce((v_result->>'profile_only')::boolean,true) is true then
    raise exception 'Explicit state change must create management history: %',v_result;
  end if;

  select count(*) into v_after_events from public.crm_events where work_item_id=v_work;
  select count(*) into v_after_logs from public.crm_log where work_item_id=v_work;
  if v_after_events<>v_before_events+1 or v_after_logs<>v_before_logs+1 then
    raise exception 'Explicit state change did not create exactly one history row';
  end if;

  v_result := public.save_gestion_v2(v_work,v_contact,null,'No contactado',2345678,'same-state-profile-edit');
  if coalesce((v_result->>'profile_only')::boolean,false) is not true then
    raise exception 'same-state save must be profile_only: %',v_result;
  end if;

  select count(*) into v_after_events from public.crm_events where work_item_id=v_work;
  select count(*) into v_after_logs from public.crm_log where work_item_id=v_work;
  if v_after_events<>v_before_events+1 or v_after_logs<>v_before_logs+1 then
    raise exception 'Same-state profile edit created extra history';
  end if;
end
$test$;

rollback;
