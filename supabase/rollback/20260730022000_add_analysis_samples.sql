-- Rollback Issue #22 · Muestras de análisis
-- Elimina únicamente la infraestructura experimental. No toca contactos,
-- campañas, work_queue ni crm_log.

begin;

revoke all on function public.get_analysis_sample_v1(text,boolean,integer,integer)
  from public, anon, authenticated;
revoke all on function public.complete_analysis_sample_item_v1(uuid,numeric)
  from public, anon, authenticated;

drop function if exists public.complete_analysis_sample_item_v1(uuid,numeric);
drop function if exists public.get_analysis_sample_v1(text,boolean,integer,integer);

drop table if exists public.crm_analysis_sample_items;
drop table if exists public.crm_analysis_samples;

commit;
