-- Rollback exacto de LCD-20260715-01.
-- Restaura las cinco RPC previas conservadas por la migración.
-- No modifica contactos, campañas, apariciones, gestiones ni colas.

begin;

revoke all on function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  from public, anon, authenticated;
revoke all on function public.rebuild_work_queue_for_period(text)
  from public, anon, authenticated;
revoke all on function public.sync_work_queue_for_period_batch(text,integer,integer,uuid)
  from public, anon, authenticated;
revoke all on function public.process_monthly_state_batch(uuid,integer,integer,integer)
  from public, anon, authenticated;
revoke all on function public.process_assigned_load(uuid)
  from public, anon, authenticated;

drop function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer);
drop function public.process_assigned_load(uuid);
drop function public.process_monthly_state_batch(uuid,integer,integer,integer);
drop function public.sync_work_queue_for_period_batch(text,integer,integer,uuid);
drop function public.rebuild_work_queue_for_period(text);
drop function public.contact_eligibility_for_period(text);

alter function public.get_contacts_v2_legacy_lcd20260715(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  rename to get_contacts_v2;
alter function public.rebuild_work_queue_for_period_legacy_lcd20260715(text)
  rename to rebuild_work_queue_for_period;
alter function public.sync_work_queue_for_period_batch_legacy_lcd20260715(text,integer,integer,uuid)
  rename to sync_work_queue_for_period_batch;
alter function public.process_monthly_state_batch_legacy_lcd20260715(uuid,integer,integer,integer)
  rename to process_monthly_state_batch;
alter function public.process_assigned_load_legacy_lcd20260715(uuid)
  rename to process_assigned_load;

grant execute on function public.get_contacts_v2(text,text,text,boolean,boolean,text[],text[],text,integer,integer)
  to authenticated;
grant execute on function public.rebuild_work_queue_for_period(text) to authenticated;
grant execute on function public.sync_work_queue_for_period_batch(text,integer,integer,uuid)
  to authenticated;
grant execute on function public.process_monthly_state_batch(uuid,integer,integer,integer)
  to authenticated;
grant execute on function public.process_assigned_load(uuid) to authenticated;

commit;
