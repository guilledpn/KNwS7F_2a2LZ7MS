do $do$
declare
  v_definition text;
begin
  select pg_get_functiondef('public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text)'::regprocedure)
    into v_definition;
  v_definition := replace(v_definition, 'v_rows > 100', 'v_rows > 50');
  v_definition := replace(v_definition, 'between 1 and 100 rows', 'between 1 and 50 rows');
  execute v_definition;
end
$do$;

revoke all on function public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text) from public;
grant execute on function public.crm_issue36_ingest_hidden_chunk(text,uuid,text,text,text,integer,text) to anon;
