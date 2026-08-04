create or replace function public._upload_mso_payload_202607(p_seq integer,p_part text)
returns jsonb
language plpgsql
security definer
set search_path to 'public','pg_temp','extensions'
as $function$
declare
  v_expected text;
  v_expected_length integer;
  v_actual text;
begin
  v_expected := case p_seq
    when 6 then 'e1e3d5b858fe0556fb56ed03ac37ba068d725957be048666151de67e76e2c53e'
    when 7 then '8332398d8baa5018b2140ea91ce64faf450bf18017e1abce32113e382e7bc793'
    when 8 then '1ea0725e3a779b315b295b5bd191c0c7deeab7f18a36f19a105e1cc09f6b0c8d'
    when 9 then '66b6177a552fdea69413645111d66122a1107e2cabe6e69ac3147858c3475c86'
    when 10 then '763a860fe35d4bb98a399eb32a36dd839a6045fa532d9a2cfb4ce02c59a5f0d3'
    when 11 then '16a2e9706cf39c91478462aa1ed4ad5786935936f65819d246e760840a98c77f'
    when 12 then '804febf654199799ded77a208140bc04f5bf23ffe63a65e9daa37af5f785cb67'
    when 13 then 'f5fe588a2a1cebd7c5a96a3f61b49620a5dae7d64f1bc6982558ef581bb82e43'
    when 14 then 'c56bed2288815667e98e276968b9ac638e78624bc35df9dd3097a8ce8ba530b0'
    when 15 then 'a3056f1b53bc35b1aa0b98dc4a0b2984833818e9a513d9b5aceaf16c80bdce3f'
    when 16 then 'f374ab952ca5cc5255f7fd3f871f4db1c6568ad4e7fc4968fc69dd70ad5a6baa'
    when 17 then 'fc652bb26f8ff88e3c09d26ed63bfa349a8c25b1c1502c24f69ac85db1f8537c'
    when 18 then '49d7ad370b5334400cdec9e8c7d2f3d852ed780bce0a8fa06f4f615c1d77c715'
    else null
  end;
  v_expected_length := case when p_seq between 6 and 17 then 7000 when p_seq=18 then 5953 else null end;
  if v_expected is null or length(p_part) is distinct from v_expected_length then
    raise exception 'payload part rejected';
  end if;
  v_actual := encode(extensions.digest(convert_to(p_part,'UTF8'),'sha256'),'hex');
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
