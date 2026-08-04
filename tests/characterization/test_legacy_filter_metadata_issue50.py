from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = (
    ROOT
    / "supabase"
    / "migrations"
    / "20260804051036_issue50_fix_legacy_filter_metadata.sql"
)


class LegacyFilterMetadataIssue50Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.sql = MIGRATION.read_text(encoding="utf-8")
        cls.html = (ROOT / "index.html").read_text(encoding="utf-8")
        cls.worker = (ROOT / "sw.js").read_text(encoding="utf-8")

    def test_migration_is_read_only_for_operational_data(self) -> None:
        lowered = self.sql.lower()
        for forbidden in (
            "insert into public.work_queue",
            "update public.work_queue",
            "delete from public.work_queue",
            "rebuild_work_queue_for_period",
            "create index",
        ):
            self.assertNotIn(forbidden, lowered)

    def test_result_counts_share_the_filtered_cte(self) -> None:
        self.assertIn("'result_total',v_total", self.sql)
        self.assertIn("'result_pending',v_result_pending", self.sql)
        self.assertIn("'result_assigned',v_result_assigned", self.sql)
        self.assertIn(
            "from filtered where estado_key = 'pendiente'", self.sql
        )
        self.assertIn("from filtered where origen = 'asignado'", self.sql)

    def test_options_avoid_large_contact_month_state_scan(self) -> None:
        options = self.sql[
            self.sql.index("create or replace function public.get_contacts_v2_filter_options"):
            self.sql.index("revoke all on function public.get_contacts_v2_filtered")
        ]
        self.assertIn("queue_options as materialized", options)
        self.assertIn("from public.campaigns cp", options)
        self.assertNotIn("contact_month_state", options)

    def test_function_permissions_remain_explicit(self) -> None:
        self.assertIn("security definer\nset search_path = ''", self.sql)
        self.assertIn("from public,anon,authenticated", self.sql)
        self.assertIn("to anon,authenticated", self.sql)

    def test_frontend_does_not_present_a_partial_sample_as_complete(self) -> None:
        load_campaigns = self.html[
            self.html.index("async function loadCampaigns()"):
            self.html.index("function setScreen", self.html.index("async function loadCampaigns()"))
        ]
        self.assertNotIn("p_limit:200", load_campaigns)
        self.assertIn("for(let attempt=0;attempt<2;attempt++)", load_campaigns)

    def test_reopening_filters_retries_options_after_transient_failure(self) -> None:
        self.assertIn("CAMPAIGN_OPTIONS_READY=false", self.html)
        self.assertIn("CAMPAIGN_OPTIONS_READY=true", self.html)
        self.assertIn(
            "async function openFilterSheet(){if(!CAMPAIGN_OPTIONS_READY)await loadCampaigns();",
            self.html,
        )

    def test_campaign_detail_wraps_and_ui_version_is_consistent(self) -> None:
        self.assertIn(".info-value.campaign-full", self.html)
        self.assertIn("'campaign-full'", self.html)
        self.assertIn("UI-20260804-10", self.worker)
        self.assertNotIn("UI-20260803-08", self.worker)


if __name__ == "__main__":
    unittest.main()
