from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "supabase" / "migrations" / "20260804012917_legacy_server_filters.sql"


class LegacyServerFilterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sql = MIGRATION.read_text(encoding="utf-8")
        cls.html = (ROOT / "index.html").read_text(encoding="utf-8")

    def test_rpc_is_additive_and_read_only(self) -> None:
        self.assertIn("create or replace function public.get_contacts_v2_filtered", self.sql)
        self.assertIn("create or replace function public.get_contacts_v2_filter_options", self.sql)
        lowered = self.sql.lower()
        for forbidden in (
            "insert into public.work_queue",
            "update public.work_queue",
            "delete from public.work_queue",
            "rebuild_work_queue_for_period",
        ):
            self.assertNotIn(forbidden, lowered)

    def test_rpc_filters_before_limit_and_offset(self) -> None:
        filtered = self.sql.index("filtered as materialized")
        page = self.sql.index("page as (", filtered)
        limit = self.sql.index("limit v_limit offset v_offset", page)
        self.assertLess(filtered, page)
        self.assertLess(page, limit)
        for parameter in (
            "p_states",
            "p_types",
            "p_months",
            "p_campaigns",
            "p_campaign_desc_keys",
            "p_reminder",
        ):
            self.assertIn(parameter, self.sql)

    def test_rpc_permissions_are_explicit(self) -> None:
        self.assertIn("security definer\nset search_path = ''", self.sql)
        self.assertIn("from public,anon,authenticated", self.sql)
        self.assertIn("to anon,authenticated", self.sql)

    def test_frontend_uses_server_filters_with_legacy_fallback(self) -> None:
        self.assertIn("sb.rpc('get_contacts_v2_filtered'", self.html)
        self.assertIn("sb.rpc('get_contacts_v2_filter_options'", self.html)
        self.assertIn("isMissingFilteredRpc", self.html)
        self.assertIn("sb.rpc('get_contacts_v2'", self.html)
        self.assertNotIn("if(hasNonV2EstadoFilters(fstate))items=clientPostFilter(items,fstate);", self.html)

    def test_historical_situation_options_are_not_offered(self) -> None:
        filter_slice = self.html[
            self.html.index("const FILTER_SECTIONS"):self.html.index("function detectChip")
        ]
        self.assertNotIn("no_gestionables", filter_slice)
        self.assertNotIn("Todos históricos", filter_slice)


if __name__ == "__main__":
    unittest.main()
