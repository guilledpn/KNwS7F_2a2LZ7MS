from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "dev" / "previews" / "stats-financial-v2.html"
GENERATED = ROOT / "dev" / "stats-v2.html"
CSS_SOURCE = ROOT / "src" / "dev" / "previews" / "stats-financial-v2.css"
CSS_GENERATED = ROOT / "dev" / "assets" / "previews" / "stats-financial-v2.css"
VIEW_SOURCE = ROOT / "src" / "dev" / "previews" / "stats-financial-view.js"
VIEW_GENERATED = ROOT / "dev" / "assets" / "previews" / "stats-financial-view.js"
RULES_SOURCE = ROOT / "src" / "dev" / "previews" / "stats-financial-rules.js"
RULES_GENERATED = ROOT / "dev" / "assets" / "previews" / "stats-financial-rules.js"
MIGRATION = ROOT / "supabase" / "migrations" / "20260805041040_issue67_clamp_stats_week_and_zero_goal.sql"


class StatsFinancialPreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = SOURCE.read_text(encoding="utf-8")
        cls.generated = GENERATED.read_text(encoding="utf-8")
        cls.css = CSS_SOURCE.read_text(encoding="utf-8")
        cls.generated_css = CSS_GENERATED.read_text(encoding="utf-8")
        cls.view = VIEW_SOURCE.read_text(encoding="utf-8")
        cls.generated_view = VIEW_GENERATED.read_text(encoding="utf-8")
        cls.rules = RULES_SOURCE.read_text(encoding="utf-8")
        cls.generated_rules = RULES_GENERATED.read_text(encoding="utf-8")
        cls.migration = MIGRATION.read_text(encoding="utf-8")

    def test_generated_copy_matches_canonical_source(self) -> None:
        self.assertEqual(self.source, self.generated)
        self.assertEqual(self.css, self.generated_css)
        self.assertEqual(self.view, self.generated_view)
        self.assertEqual(self.rules, self.generated_rules)

    def test_preview_is_dev_only(self) -> None:
        combined = self.source + self.view
        self.assertIn("xcujixexjbuqqzlbomgw", combined)
        self.assertNotIn("lijibbhpyyptodneafdd", combined)
        self.assertIn("./assets/app/config/environment.js", self.source)
        self.assertIn("./assets/previews/stats-financial-v2.css", self.source)
        self.assertIn("./assets/previews/stats-financial-rules.js", self.source)
        self.assertIn("./assets/previews/stats-financial-view.js", self.source)

    def test_uses_unified_stats_contract(self) -> None:
        self.assertIn("get_stats_cockpit_v1", self.view)
        self.assertIn("daily_person_outcome_v1", self.view)
        self.assertIn("agenda_expected_value_v1", self.view)

    def test_required_experience_rules_are_present(self) -> None:
        combined = self.source + self.view
        for marker in (
            "rules.streakForMonth",
            "rules.rhythmState",
            "rules.targetForWeek",
            'data-unit="agendas"',
            'data-unit="money"',
            "REFRESH_MS=30000",
            "Datos no disponibles",
            "CNS esperados",
            "Dinero esperado hoy",
        ):
            self.assertIn(marker, combined)

    def test_removed_copy_does_not_return(self) -> None:
        combined = self.source + self.view
        self.assertNotIn("Todo el dinero mostrado es estimado", combined)
        self.assertNotIn("Los datos se actualizan al final del día", combined)

    def test_migration_preserves_contract_and_corrects_boundaries(self) -> None:
        self.assertIn("to_regprocedure('public.get_stats_cockpit_v1()')", self.migration)
        self.assertIn("greatest(v_month_start", self.migration)
        self.assertIn("v_monthly_target <= 0", self.migration)
        self.assertNotIn("drop function", self.migration.lower())
        self.assertNotIn("service_role", self.migration.lower())

    def test_behavior_rules(self) -> None:
        script = f"""
        global.window = global;
        require({json.dumps(str(RULES_SOURCE))});
        const rules = global.StatsFinancialRules;
        function assert(condition, message) {{ if (!condition) throw new Error(message); }}
        function data(overrides = {{}}) {{
          const base = {{
            goal: {{ monthly_agendas: 189, normal_daily_agendas: 9, today_target_agendas: 9 }},
            month: {{ week_start: '2026-08-03', week_end: '2026-08-09', actual_agendas: 18, gap_to_pace: 0, remaining_agendas: 171, needed_daily_to_finish: 9 }},
            month_story: {{ today: '2026-08-04', series: [
              {{day:'2026-08-01',is_workday:false,daily_agendas:0,expected_cumulative:0}},
              {{day:'2026-08-02',is_workday:false,daily_agendas:0,expected_cumulative:0}},
              {{day:'2026-08-03',is_workday:true,daily_agendas:9,expected_cumulative:9}},
              {{day:'2026-08-04',is_workday:true,daily_agendas:0,expected_cumulative:18}},
              {{day:'2026-08-05',is_workday:true,daily_agendas:0,expected_cumulative:27}},
              {{day:'2026-08-06',is_workday:true,daily_agendas:0,expected_cumulative:36}},
              {{day:'2026-08-07',is_workday:true,daily_agendas:0,expected_cumulative:45}},
              {{day:'2026-08-08',is_workday:false,daily_agendas:0,expected_cumulative:45}},
              {{day:'2026-08-09',is_workday:false,daily_agendas:0,expected_cumulative:45}}
            ]}}
          }};
          return {{
            ...base,
            ...overrides,
            goal: {{...base.goal, ...(overrides.goal || {{}})}},
            month: {{...base.month, ...(overrides.month || {{}})}},
            month_story: {{...base.month_story, ...(overrides.month_story || {{}})}}
          }};
        }}
        assert(rules.targetForWeek(data()) === 45, 'La semana parcial debe sumar sólo días activos del mes');
        assert(rules.streakForMonth(data()).count === 1, 'El día actual incompleto no debe romper la racha previa');
        const completedToday = data({{month_story: {{today:'2026-08-04', series:data().month_story.series.map(row => row.day === '2026-08-04' ? {{...row,daily_agendas:9}} : row)}}}});
        assert(rules.streakForMonth(completedToday).count === 2, 'El día actual debe sumar al alcanzar su meta');
        assert(rules.streakForMonth(data({{goal:{{monthly_agendas:0}}}})).enabled === false, 'Meta 0 debe desactivar la racha');
        assert(rules.rhythmState(data({{goal:{{monthly_agendas:0}}}})).key === 'none', 'Estado sin meta');
        assert(rules.rhythmState(data({{month:{{remaining_agendas:0,actual_agendas:189}}}})).key === 'complete', 'Estado meta cumplida');
        assert(rules.rhythmState(data({{month:{{gap_to_pace:9}}}})).key === 'spectacular', 'Estado espectacular');
        assert(rules.rhythmState(data({{month:{{gap_to_pace:1}}}})).key === 'good', 'Estado vas bien');
        assert(rules.rhythmState(data({{month:{{gap_to_pace:-2,needed_daily_to_finish:9}}}})).key === 'recoverable', 'Estado recuperable');
        assert(rules.rhythmState(data({{month:{{gap_to_pace:-10,needed_daily_to_finish:10}}}})).key === 'effort', 'Estado esfuerzo adicional');
        """
        subprocess.run(["node", "-e", script], check=True, cwd=ROOT)


if __name__ == "__main__":
    unittest.main()
