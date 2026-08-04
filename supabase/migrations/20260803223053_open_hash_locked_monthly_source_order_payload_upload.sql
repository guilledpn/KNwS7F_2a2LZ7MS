create or replace function public._upload_mso_payload_202607(p_seq integer,p_part text)
returns jsonb
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $function$
declare
  v_expected text;
  v_expected_length integer;
  v_actual text;
begin
  v_expected := case p_seq
    when 5 then '6b0f6ebcd11764219527d7da113cb97d1fbc91e078ab5f377da7c9481b9a4796'
    when 6 then '3a81892e7dce0b23534ed2e434a0739125c5cba86610b9d104ffa8e4a85c82de'
    when 7 then '1f84d3d5bbc3804cbd804047e7872f934481e27cd76af383a2abc2ac74dcb737'
    when 8 then 'c6a90c5a2d281684ecc9f96be85de0f121c9375cba89727084d4426bac6b35d9'
    when 9 then '3012e8823afbf8b226d1be302940da1c76edd36f6de266cccc368159b961a44f'
    when 10 then 'd6c69dc54a95d4dacb6931636dc0d4a7a370e77d2cc8a3728dcb0a1cdb4ae344'
    when 11 then '8fd9ed60ad9aed2a09b9870486b8e5f97c427598ee19eac5d8fe6087873c97bb'
    else null
  end;
  v_expected_length := case when p_seq between 5 and 10 then 14000 when p_seq=11 then 12953 else null end;
  if v_expected is null or length(p_part) is distinct from v_expected_length then
    raise exception 'payload part rejected';
  end if;
  v_actual := encode(digest(convert_to(p_part,'UTF8'),'sha256'),'hex');
  if v_actual is distinct from v_expected then
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
