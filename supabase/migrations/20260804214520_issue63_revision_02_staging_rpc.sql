-- Issue #63 · RPC de staging aislado y estado agregado.

create or replace function public.crm_issue63_stage_chunk(
  p_token text,
  p_file_name text,
  p_load_type text,
  p_period text,
  p_xlsx_sha256 text,
  p_start_order integer,
  p_chunk_sha256 text,
  p_tsv text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_manifest issue63_ops.file_manifest;
  v_chunk_rows integer;
  v_end_order integer;
  v_contiguous integer;
  v_staged_rows integer;
  v_calculated_chunk_hash text;
begin
  perform set_config('statement_timeout','60000',true);
  v_operation := issue63_ops.require_operation(p_token);

  if v_operation.status not in ('configured','staging','staged') then
    raise exception 'Issue #63 staging is closed in status %',v_operation.status
      using errcode = '55000';
  end if;
  if p_period <> v_operation.period then
    raise exception 'Unexpected period' using errcode = '22023';
  end if;

  select * into v_manifest
  from issue63_ops.file_manifest
  where operation_key=v_operation.operation_key
    and file_name=p_file_name;
  if not found then
    raise exception 'File is not part of the Issue #63 manifest' using errcode = '22023';
  end if;
  if p_load_type <> v_manifest.load_type or p_xlsx_sha256 <> v_manifest.xlsx_sha256 then
    raise exception 'File type or XLSX hash does not match the configured manifest'
      using errcode = '22023';
  end if;

  v_calculated_chunk_hash := encode(
    extensions.digest(convert_to(coalesce(p_tsv,''),'UTF8'),'sha256'),
    'hex'
  );
  if v_calculated_chunk_hash <> p_chunk_sha256 then
    raise exception 'Chunk SHA-256 mismatch' using errcode = '22023';
  end if;

  with parsed as (
    select line,ordinality::integer as rn,string_to_array(line,E'\t') as fields
    from unnest(string_to_array(coalesce(p_tsv,''),E'\n')) with ordinality as x(line,ordinality)
    where line <> ''
  )
  select count(*)::integer into v_chunk_rows from parsed;

  if v_chunk_rows < 1 or v_chunk_rows > 500 then
    raise exception 'Chunk must contain between 1 and 500 rows; received %',v_chunk_rows
      using errcode = '22023';
  end if;
  v_end_order := p_start_order + v_chunk_rows - 1;
  if p_start_order < 1 or v_end_order > v_manifest.expected_rows then
    raise exception 'Chunk range is outside the configured file'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from unnest(string_to_array(p_tsv,E'\n')) as x(line)
    where line <> '' and array_length(string_to_array(line,E'\t'),1) <> 11
  ) then
    raise exception 'Every payload row must contain exactly 11 columns'
      using errcode = '22023';
  end if;

  if exists (
    with parsed as (
      select
        p_start_order + ordinality::integer - 1 as source_order,
        line,
        string_to_array(line,E'\t') as fields
      from unnest(string_to_array(p_tsv,E'\n')) with ordinality as x(line,ordinality)
      where line <> ''
    )
    select 1
    from parsed p
    where p.fields[1] !~ '^[0-9]+[0-9K]$'
       or p.fields[11] not in ('Gestionado','No Gestionado')
       or p.fields[8] = ''
       or p.fields[9] = ''
       or p.fields[10] = ''
  ) then
    raise exception 'Payload row failed semantic validation' using errcode = '22023';
  end if;

  if exists (
    with parsed as (
      select
        p_start_order + ordinality::integer - 1 as source_order,
        line
      from unnest(string_to_array(p_tsv,E'\n')) with ordinality as x(line,ordinality)
      where line <> ''
    )
    select 1
    from parsed p
    join issue63_ops.stage_rows s
      on s.operation_key=v_operation.operation_key
     and s.file_name=p_file_name
     and s.source_order=p.source_order
    where s.payload_line <> p.line
  ) then
    raise exception 'A staged source row conflicts with a previous payload'
      using errcode = '23505';
  end if;

  insert into issue63_ops.stage_rows(
    operation_key,file_name,load_type,source_order,payload_line,row_sha256,
    rut_norm,rut,nombre,telefono_1,telefono_2,telefono_3,email,
    campaign_name,campaign_desc,campaign_key,estado_origen
  )
  select
    v_operation.operation_key,
    p_file_name,
    p_load_type,
    p_start_order + p.rn - 1,
    p.line,
    encode(extensions.digest(convert_to(p.line,'UTF8'),'sha256'),'hex'),
    p.fields[1],p.fields[2],p.fields[3],p.fields[4],p.fields[5],p.fields[6],
    p.fields[7],p.fields[8],p.fields[9],p.fields[10],p.fields[11]
  from (
    select ordinality::integer as rn,line,string_to_array(line,E'\t') as fields
    from unnest(string_to_array(p_tsv,E'\n')) with ordinality as x(line,ordinality)
    where line <> ''
  ) p
  on conflict(operation_key,file_name,source_order) do nothing;

  select count(*)::integer into v_staged_rows
  from issue63_ops.stage_rows
  where operation_key=v_operation.operation_key and file_name=p_file_name;

  v_contiguous := issue63_ops.contiguous_rows(
    v_operation.operation_key,p_file_name,v_manifest.expected_rows
  );

  update issue63_ops.operation
     set status=case
       when (
         select bool_and(issue63_ops.contiguous_rows(
           m.operation_key,m.file_name,m.expected_rows
         )=m.expected_rows)
         from issue63_ops.file_manifest m
         where m.operation_key=v_operation.operation_key
       ) then 'staged'
       else 'staging'
     end,
     staged_at=case
       when (
         select bool_and(issue63_ops.contiguous_rows(
           m.operation_key,m.file_name,m.expected_rows
         )=m.expected_rows)
         from issue63_ops.file_manifest m
         where m.operation_key=v_operation.operation_key
       ) then coalesce(staged_at,now())
       else staged_at
     end
   where operation_key=v_operation.operation_key;

  return jsonb_build_object(
    'ok',true,
    'issue',63,
    'operation_key',v_operation.operation_key,
    'file_name',p_file_name,
    'load_type',p_load_type,
    'chunk_start',p_start_order,
    'chunk_end',v_end_order,
    'chunk_rows',v_chunk_rows,
    'staged_rows',v_staged_rows,
    'contiguous_rows',v_contiguous,
    'expected_rows',v_manifest.expected_rows
  );
end
$function$;

create or replace function issue63_ops.validate_stage()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_manifest issue63_ops.file_manifest;
  v_rows integer;
  v_distinct integer;
  v_min integer;
  v_max integer;
  v_payload_hash text;
  v_status_counts jsonb;
  v_campaign_counts jsonb;
  v_missing_assigned integer;
  v_field_mismatches integer;
begin
  perform set_config('statement_timeout','180000',true);
  select * into strict v_operation from issue63_ops.operation limit 1;

  for v_manifest in
    select * from issue63_ops.file_manifest
    where operation_key=v_operation.operation_key
    order by load_type
  loop
    select
      count(*)::integer,
      count(distinct rut_norm)::integer,
      min(source_order)::integer,
      max(source_order)::integer,
      encode(extensions.digest(
        convert_to(coalesce(string_agg(payload_line,E'\n' order by source_order),''),'UTF8'),
        'sha256'
      ),'hex')
    into v_rows,v_distinct,v_min,v_max,v_payload_hash
    from issue63_ops.stage_rows
    where operation_key=v_operation.operation_key
      and file_name=v_manifest.file_name;

    select coalesce(jsonb_object_agg(x.estado_origen,x.n),'{}'::jsonb)
    into v_status_counts
    from (
      select estado_origen,count(*)::integer as n
      from issue63_ops.stage_rows
      where operation_key=v_operation.operation_key
        and file_name=v_manifest.file_name
      group by estado_origen
      order by estado_origen
    ) x;

    select coalesce(jsonb_object_agg(x.campaign_key,x.n),'{}'::jsonb)
    into v_campaign_counts
    from (
      select campaign_key,count(*)::integer as n
      from issue63_ops.stage_rows
      where operation_key=v_operation.operation_key
        and file_name=v_manifest.file_name
      group by campaign_key
      order by campaign_key
    ) x;

    if v_rows <> v_manifest.expected_rows
       or v_distinct <> v_manifest.expected_distinct_ruts
       or v_min <> 1
       or v_max <> v_manifest.expected_rows
       or v_payload_hash <> v_manifest.payload_sha256
       or v_status_counts <> v_manifest.expected_status_counts
       or v_campaign_counts <> v_manifest.expected_campaign_counts then
      raise exception 'Staged file % does not match its configured manifest',v_manifest.file_name
        using errcode = '55000';
    end if;
  end loop;

  select count(*)::integer into v_missing_assigned
  from issue63_ops.stage_rows a
  left join issue63_ops.stage_rows t
    on t.operation_key=a.operation_key
   and t.load_type='mensual'
   and t.rut_norm=a.rut_norm
   and t.campaign_key=a.campaign_key
  where a.operation_key=v_operation.operation_key
    and a.load_type='asignado'
    and t.rut_norm is null;

  select count(*)::integer into v_field_mismatches
  from issue63_ops.stage_rows a
  join issue63_ops.stage_rows t
    on t.operation_key=a.operation_key
   and t.load_type='mensual'
   and t.rut_norm=a.rut_norm
   and t.campaign_key=a.campaign_key
  where a.operation_key=v_operation.operation_key
    and a.load_type='asignado'
    and (a.rut,a.nombre,a.telefono_1,a.telefono_2,a.telefono_3,a.email,
         a.campaign_name,a.campaign_desc,a.estado_origen)
        is distinct from
        (t.rut,t.nombre,t.telefono_1,t.telefono_2,t.telefono_3,t.email,
         t.campaign_name,t.campaign_desc,t.estado_origen);

  if v_missing_assigned <> 0 or v_field_mismatches <> 0 then
    raise exception 'ASIGNADOS is not an exact subset of TOTAL'
      using errcode = '55000';
  end if;

  return jsonb_build_object(
    'ok',true,
    'operation_key',v_operation.operation_key,
    'period',v_operation.period,
    'files',(
      select jsonb_agg(jsonb_build_object(
        'file_name',m.file_name,
        'load_type',m.load_type,
        'expected_rows',m.expected_rows,
        'staged_rows',(select count(*) from issue63_ops.stage_rows s
          where s.operation_key=m.operation_key and s.file_name=m.file_name),
        'payload_sha256',m.payload_sha256
      ) order by m.load_type)
      from issue63_ops.file_manifest m
      where m.operation_key=v_operation.operation_key
    ),
    'assigned_subset',true
  );
end
$function$;

create or replace function public.crm_issue63_status(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_operation issue63_ops.operation;
  v_complete boolean;
  v_stage_valid boolean := false;
begin
  perform set_config('statement_timeout','180000',true);
  v_operation := issue63_ops.require_operation(p_token);
  select bool_and(
    issue63_ops.contiguous_rows(m.operation_key,m.file_name,m.expected_rows)=m.expected_rows
  ) into v_complete
  from issue63_ops.file_manifest m
  where m.operation_key=v_operation.operation_key;

  if coalesce(v_complete,false) then
    perform issue63_ops.validate_stage();
    v_stage_valid := true;
  end if;

  return jsonb_build_object(
    'ok',true,
    'issue',63,
    'operation_key',v_operation.operation_key,
    'period',v_operation.period,
    'status',v_operation.status,
    'expires_at',v_operation.expires_at,
    'stage_complete',coalesce(v_complete,false),
    'stage_valid',v_stage_valid,
    'canonical_apply_executed',v_operation.status in ('applied','rolled_back'),
    'files',(
      select jsonb_agg(jsonb_build_object(
        'file_name',m.file_name,
        'load_type',m.load_type,
        'expected_rows',m.expected_rows,
        'staged_rows',(select count(*) from issue63_ops.stage_rows s
          where s.operation_key=m.operation_key and s.file_name=m.file_name),
        'contiguous_rows',issue63_ops.contiguous_rows(
          m.operation_key,m.file_name,m.expected_rows
        ),
        'complete',issue63_ops.contiguous_rows(
          m.operation_key,m.file_name,m.expected_rows
        )=m.expected_rows
      ) order by m.load_type)
      from issue63_ops.file_manifest m
      where m.operation_key=v_operation.operation_key
    )
  );
end
$function$;

-- Cierra toda ejecución directa de helpers internos. Las RPC públicas sólo exponen
-- staging y estado agregado.
revoke all on function issue63_ops.require_operation(text) from public, anon, authenticated;
revoke all on function issue63_ops.configure_operation(text,text,text,timestamptz,jsonb,jsonb) from public, anon, authenticated;
revoke all on function issue63_ops.contiguous_rows(text,text,integer) from public, anon, authenticated;
revoke all on function issue63_ops.validate_stage() from public, anon, authenticated;

revoke all on function public.crm_issue63_stage_chunk(text,text,text,text,text,integer,text,text)
  from public, anon, authenticated;
grant execute on function public.crm_issue63_stage_chunk(text,text,text,text,text,integer,text,text)
  to anon;

revoke all on function public.crm_issue63_status(text)
  from public, anon, authenticated;
grant execute on function public.crm_issue63_status(text)
  to anon;
