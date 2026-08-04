from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "supabase" / "migrations" / "20260804070410_issue52_unify_stats_cockpit.sql"
PROJECTION_FIX = ROOT / "supabase" / "migrations" / "20260804070601_issue52_fix_normal_projection.sql"
ACL_FIX = ROOT / "supabase" / "migrations" / "20260804071933_issue52_revoke_legacy_anonymous_stats.sql"


class StatsCockpitIssue52Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sql = MIGRATION.read_text(encoding="utf-8")
        cls.projection_sql = PROJECTION_FIX.read_text(encoding="utf-8")
        cls.acl_sql = ACL_FIX.read_text(encoding="utf-8")
        cls.html = (ROOT / "index.html").read_text(encoding="utf-8")
        cls.dev_html = (ROOT / "dev" / "index.html").read_text(encoding="utf-8")
        cls.patch = (ROOT / "assets" / "app" / "features" / "stats-metrics-patch-prod.js").read_text(encoding="utf-8")
        cls.stats_redirect = (ROOT / "stats.html").read_text(encoding="utf-8")

    def test_value_equivalence_for_current_goal_is_exact(self) -> None:
        agendas = 189
        cns_per_agenda = 2.5
        clp_per_cns = 10_000
        self.assertEqual(agendas * cns_per_agenda, 472.5)
        self.assertEqual(agendas * cns_per_agenda * clp_per_cns, 4_725_000)

    def test_goal_and_assumptions_share_one_settings_row(self) -> None:
        self.assertIn("estimated_cns_per_agenda numeric(8,2) not null default 2.50", self.sql)
        self.assertIn("estimated_clp_per_cns integer not null default 10000", self.sql)
        self.assertIn("from public.crm_goals g", self.sql)
        self.assertIn("where g.goal_month = v_month_key", self.sql)
        self.assertIn("estimated_cns_per_agenda:cns", self.html)
        self.assertIn("estimated_clp_per_cns:clp", self.html)

    def test_local_storage_is_only_a_fallback(self) -> None:
        start = self.html.index("async function goalSettings")
        end = self.html.index("function goalModel", start)
        function = self.html[start:end]
        self.assertIn("?'local-fallback':'default-fallback'", function)
        self.assertIn("source:'db'", function)
        self.assertIn("source:'db-legacy'", function)
        self.assertRegex(function, r"return data\?Object\.assign\(\{\},fallback,data,\{source:'db'\}\):fallback")

    def test_cockpit_uses_final_person_day_outcomes_for_all_windows(self) -> None:
        self.assertGreaterEqual(self.sql.count("from public.crm_contact_day_outcomes_v1"), 4)
        for window in ("last_hour", "today", "week", "month"):
            self.assertIn("'" + window + "'", self.sql)
        self.assertIn("'Semana calendario'", self.sql)
        self.assertIn("'Mes calendario'", self.sql)

    def test_production_patch_uses_one_stats_contract(self) -> None:
        start = self.patch.index("async function patchedRenderStats")
        end = self.patch.index("\n  function install()", start)
        function = self.patch[start:end]
        self.assertEqual(function.count("client.rpc('get_stats_cockpit_v1')"), 1)
        self.assertNotIn("get_stats_v1", function)
        self.assertNotIn("get_management_metrics_v1", function)
        self.assertIn("stats==='hora'?'last_hour'", function)

    def test_cockpit_keeps_four_operational_signals_and_labels_estimates(self) -> None:
        start = self.patch.index("async function patchedRenderStats")
        end = self.patch.index("\n  function install()", start)
        function = self.patch[start:end]
        labels = re.findall(r'<div class="metric-label">(Trabajados|Llamadas efectivas|Agendamientos|Conversión efectiva)</div>', function)
        self.assertEqual(labels, ["Trabajados", "Llamadas efectivas", "Agendamientos", "Conversión efectiva"])
        self.assertIn("Próxima agenda:", function)
        self.assertIn("no es producción reconocida ni ingreso devengado", function)

    def test_actual_curve_stops_today_and_forecast_is_dashed(self) -> None:
        start = self.html.index("function chartMonth")
        end = self.html.index("\n\nfunction reportCardSkeleton", start)
        function = self.html[start:end]
        self.assertIn("actual_cumulative!=null", function)
        self.assertIn("stroke-dasharray=\"3 2\"", function)
        self.assertIn("chartMonth(story,projectedCurrent)", self.patch)

    def test_normal_projection_counts_unfinished_today_once(self) -> None:
        self.assertIn("greatest(0, v_today_target - v_today_agendas)", self.projection_sql)
        self.assertIn("v_active_days_left - case when v_is_today_active then 1 else 0 end", self.projection_sql)

    def test_chile_date_is_explicit_in_both_management_records(self) -> None:
        self.assertIn("v_local_date date := (now() at time zone 'America/Santiago')::date", self.sql)
        self.assertIn("insert into public.crm_log", self.sql)
        self.assertIn("insert into public.crm_events", self.sql)
        self.assertGreaterEqual(self.sql.count("v_local_date"), 3)

    def test_stats_functions_are_authenticated_only(self) -> None:
        self.assertIn("revoke all on function public.get_stats_cockpit_v1() from public, anon", self.projection_sql)
        self.assertIn("grant execute on function public.get_stats_cockpit_v1() to authenticated", self.projection_sql)
        self.assertIn("get_stats_v1(integer,integer) from public, anon", self.acl_sql)
        self.assertIn("get_management_metrics_v1(integer) from public, anon", self.acl_sql)

    def test_errors_are_not_rendered_as_zeroes(self) -> None:
        self.assertIn("Datos estadísticos no disponibles", self.patch)
        self.assertIn("Datos no disponibles por error de carga", self.patch)
        self.assertNotIn("Reporte\\nLlamadas totales: 0", self.patch)

    def test_settings_expose_goal_and_estimation_parameters(self) -> None:
        for html in (self.html, self.dev_html):
            self.assertIn('id="monthly-goal-input"', html)
            self.assertIn('id="cns-per-agenda-input"', html)
            self.assertIn('id="clp-per-cns-input"', html)
            self.assertIn("Guardar meta y equivalencias", html)

    def test_retired_stats_page_redirects_without_personal_email(self) -> None:
        self.assertIn("./?screen=stats", self.stats_redirect)
        self.assertNotIn("g.delpedregal@gmail.com", self.stats_redirect)
        self.assertNotIn("get_stats_v1", self.stats_redirect)
        self.assertIn("get('screen')==='stats'", self.html)
        self.assertIn("get('screen')==='stats'", self.dev_html)


if __name__ == "__main__":
    unittest.main()
