-- Rollback Issue #24 · restaura la regla original: sólo muestras active pueden grabarse.

begin;

create or replace function public.complete_analysis_sample_item_v1(
  p_sample_item_id uuid,
  p_ingreso numeric default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_sample_id uuid;
  v_sample_key text;
  v_total integer := 0;
  v_completed integer := 0;
  v_pending integer := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  update public.crm_analysis_sample_items i
     set completed_at = coalesce(i.completed_at, now()),
         captured_income = coalesce(p_ingreso,0)
    from public.crm_analysis_samples s
   where i.sample_item_id = p_sample_item_id
     and s.sample_id = i.sample_id
     and s.status = 'active'
  returning i.sample_id, s.sample_key
       into v_sample_id, v_sample_key;

  if v_sample_id is null then
    return jsonb_build_object(
      'ok', false,
      'code', 'SAMPLE_ITEM_NOT_FOUND_OR_INACTIVE',
      'sample_item_id', p_sample_item_id
    );
  end if;

  select
    count(*),
    count(*) filter (where completed_at is not null),
    count(*) filter (where completed_at is null)
  into v_total, v_completed, v_pending
  from public.crm_analysis_sample_items
  where sample_id = v_sample_id;

  if v_pending = 0 then
    update public.crm_analysis_samples
       set status = 'completed', updated_at = now()
     where sample_id = v_sample_id
       and status = 'active';
  else
    update public.crm_analysis_samples
       set updated_at = now()
     where sample_id = v_sample_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'sample_key', v_sample_key,
    'sample_total', v_total,
    'sample_completed', v_completed,
    'sample_pending', v_pending
  );
end
$function$;

revoke all on function public.complete_analysis_sample_item_v1(uuid,numeric)
  from public, anon, authenticated;
grant execute on function public.complete_analysis_sample_item_v1(uuid,numeric)
  to authenticated;

commit;
