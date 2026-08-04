-- Retira toda la infraestructura temporal del Issue #63 después de aceptación o rollback.
do $cleanup$
declare
  v_status text;
  v_operation_key text;
  v_period text;
  v_result jsonb;
begin
  select status,operation_key,period,result
  into v_status,v_operation_key,v_period,v_result
  from issue63_ops.operation
  limit 1;

  if not found then
    raise exception 'Issue #63 cleanup requires a configured operation';
  end if;
  if v_status not in ('applied','rolled_back') then
    raise exception 'Issue #63 cleanup requires applied or rolled_back status; current=%',v_status;
  end if;

  insert into public.crm_guardrail_events(event_type,severity,details)
  values(
    'issue63_temporary_infrastructure_removed',
    'info',
    jsonb_build_object(
      'issue',63,
      'operation_key',v_operation_key,
      'period',v_period,
      'final_status',v_status,
      'final_result',v_result,
      'removed_at',clock_timestamp()
    )
  );
end
$cleanup$;

drop function if exists public.crm_issue63_stage_chunk(text,text,text,text,text,integer,text,text);
drop function if exists public.crm_issue63_status(text);
drop schema if exists issue63_ops cascade;
