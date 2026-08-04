create or replace function public._upload_mso_payload_202607(p_seq integer,p_part text)
returns jsonb
language plpgsql
security definer
set search_path to 'public','pg_temp','extensions'
as $function$
declare
  v_actual text;
begin
  if p_seq is distinct from 5 or length(p_part) is distinct from 96953 then
    raise exception 'payload part rejected';
  end if;
  v_actual := encode(extensions.digest(convert_to(p_part,'UTF8'),'sha256'),'hex');
  if v_actual is distinct from '066c8cb69cf5ab25d28e74b0b5852797dec6d0c5d7dc7c4f7277a8d8911cd4f1' then
    raise exception 'payload digest rejected';
  end if;
  insert into public._mso_payload_202607(seq,part)
  values(p_seq,p_part)
  on conflict(seq) do update set part=excluded.part,created_at=now();
  return jsonb_build_object('ok',true,'seq',p_seq,'length',length(p_part));
end
$function$;
revoke all on function public._upload_mso_payload_202607(integer,text) from public;
grant execute on function public._upload_mso_payload_202607(integer,text) to anon;
