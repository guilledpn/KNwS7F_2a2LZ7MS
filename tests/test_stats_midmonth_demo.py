from __future__ import annotations

import re
import unittest
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "dev" / "previews" / "stats-financial-midmonth-demo.html"
GENERATED = ROOT / "dev" / "stats-v2-midmonth-demo.html"


class HtmlSmokeParser(HTMLParser):
    pass


class StatsMidmonthDemoTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = SOURCE.read_text(encoding="utf-8")
        cls.generated = GENERATED.read_text(encoding="utf-8")

    def test_generated_copy_matches_canonical_source(self) -> None:
        self.assertEqual(self.source, self.generated)

    def test_is_explicitly_fictitious_and_dev_only(self) -> None:
        required = (
            "SIMULACIÓN DEV",
            "Datos completamente ficticios",
            "14 AGO 2026 · 13:00",
            "Issue #69",
        )
        for text in required:
            self.assertIn(text, self.source)

    def test_uses_legacy_goal_and_midmonth_values(self) -> None:
        required = (
            "Meta mensual Legacy: 189 agendas",
            "$125.000",
            "$225.000",
            "5 agendas",
            "44",
            "$1.100.000",
            "89",
            "$2.225.000",
            "Ritmo ideal a hoy: 90",
        )
        for text in required:
            self.assertIn(text, self.source)

    def test_gap_streak_and_projections_are_visible(self) -> None:
        required = (
            "Racha del mes: 6 días",
            "−1 agenda",
            "−2,5",
            "−$25.000",
            "187",
            "192",
        )
        for text in required:
            self.assertIn(text, self.source)

    def test_no_supabase_or_secret_surface(self) -> None:
        forbidden = (
            "supabase.co",
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY",
            "createClient(",
            ".rpc(",
            "service_role",
            "sb_publishable_",
        )
        lowered = self.source.lower()
        for token in forbidden:
            self.assertNotIn(token.lower(), lowered)

    def test_html_parses_and_contains_single_inline_script(self) -> None:
        parser = HtmlSmokeParser()
        parser.feed(self.source)
        scripts = re.findall(r"<script>(.*?)</script>", self.source, flags=re.DOTALL)
        self.assertEqual(len(scripts), 1)
        self.assertIn("renderChart();", scripts[0])
        self.assertIn("data-unit=\"money\"", self.source)
        self.assertIn("data-period=\"week\"", self.source)

    def test_equivalences_are_mathematically_consistent(self) -> None:
        agendas_today = 5
        agendas_week = 44
        agendas_month = 89
        cns_per_agenda = 2.5
        clp_per_cns = 10_000
        clp_per_agenda = cns_per_agenda * clp_per_cns
        self.assertEqual(agendas_today * clp_per_agenda, 125_000)
        self.assertEqual(agendas_week * clp_per_agenda, 1_100_000)
        self.assertEqual(agendas_month * clp_per_agenda, 2_225_000)
        self.assertEqual((90 - agendas_month) * clp_per_agenda, 25_000)


if __name__ == "__main__":
    unittest.main()
