-- Rollback técnico de LCD-20260713-01 en PROD.
-- No afecta crm_log, crm_events, contactos ni get_stats_v1.

revoke all on function public.get_daily_management_report_v1(date) from public, anon, authenticated;
revoke all on function public.get_management_metrics_v1(integer) from public, anon, authenticated;

drop function if exists public.get_daily_management_report_v1(date);
drop function if exists public.get_management_metrics_v1(integer);
drop view if exists public.crm_contact_day_outcomes_v1;
drop function if exists public.crm_management_state_key(text);
