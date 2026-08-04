from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = (
    ROOT
    / "supabase"
    / "migrations"
    / "20260804042524_optimize_legacy_month_filters_issue48.sql"
)


class LegacyMonthFilterPerformanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sql = MIGRATION.read_text(encoding="utf-8")

    def test_months_are_aggregated_once_before_filtering(self) -> None:
        month_selected = self.sql.index("month_selected as materialized")
        candidates = self.sql.index("candidates as materialized", month_selected)
        filtered = self.sql.index("filtered as materialized", candidates)
        page = self.sql.index("page as (", filtered)
        self.assertLess(month_selected, candidates)
        self.assertLess(candidates, filtered)
        self.assertLess(filtered, page)
        self.assertIn("count(distinct mm.period)::integer as matched_periods", self.sql)
        self.assertIn("left join month_selected ms on ms.contact_id = b.contact_id", self.sql)

    def test_all_mode_does_not_run_a_correlated_count_per_contact(self) -> None:
        lowered = self.sql.lower()
        self.assertNotIn("select count(distinct mm.period)\n            from", lowered)
        self.assertIn("coalesce(ms.matched_periods,0) = v_month_count", lowered)

    def test_only_mode_checks_outside_months_after_candidates(self) -> None:
        candidates = self.sql.index("candidates as materialized")
        filtered = self.sql.index("filtered as materialized", candidates)
        outside = self.sql.index("outside_month.contact_id = c.contact_id", filtered)
        self.assertLess(candidates, filtered)
        self.assertLess(filtered, outside)

    def test_migration_preserves_read_only_contract_and_permissions(self) -> None:
        lowered = self.sql.lower()
        for forbidden in (
            "insert into public.work_queue",
            "update public.work_queue",
            "delete from public.work_queue",
            "rebuild_work_queue_for_period",
            "create index",
        ):
            self.assertNotIn(forbidden, lowered)
        self.assertIn("security definer\nset search_path = ''", self.sql)
        self.assertIn("from public,anon,authenticated", self.sql)
        self.assertIn("to anon,authenticated", self.sql)

    def test_function_signature_and_ordering_remain_stable(self) -> None:
        self.assertIn("create or replace function public.get_contacts_v2_filtered", self.sql)
        self.assertIn("limit v_limit offset v_offset", self.sql)
        self.assertIn("coalesce(f.display_order,2147483647)", self.sql)
        self.assertIn("'source','get_contacts_v2_filtered_issue48'", self.sql)


if __name__ == "__main__":
    unittest.main()
