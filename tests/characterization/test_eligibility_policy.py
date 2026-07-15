from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests" / "characterization" / "fixtures" / "eligibility-policy-cases.json"
MIGRATION = ROOT / "supabase" / "migrations" / "20260715_unify_contact_eligibility_policy.sql"
REFINEMENT = (
    ROOT
    / "supabase"
    / "migrations"
    / "20260715_refine_last_valid_status_and_manual_contacts.sql"
)


def canonical_monthly_policy(case: dict[str, object]) -> tuple[bool, str]:
    """Return the domain-governed eligibility result and reason."""

    if bool(case["assigned_current"]):
        return True, "assigned_current"
    if bool(case["appears_active"]):
        return False, "active_unassigned"

    status = case["last_valid_status"]
    if status == "No Gestionado":
        return True, "latest_no_gestionado"
    if status == "Gestionado":
        return False, "latest_gestionado"
    if not bool(case["has_corporate_appearance"]):
        return True, "manual_contact"
    return False, "latest_status_missing"


class EligibilityPolicyTests(unittest.TestCase):
    """Protect ADR-020 and its domain refinement."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.cases = json.loads(FIXTURE.read_text(encoding="utf-8"))
        cls.migration = MIGRATION.read_text(encoding="utf-8")
        cls.refinement = REFINEMENT.read_text(encoding="utf-8")

    def test_fixture_expectations_match_canonical_policy(self) -> None:
        for case in self.cases:
            with self.subTest(case=case["id"]):
                actual_gestionable, actual_reason = canonical_monthly_policy(case)
                self.assertEqual(case["expected_gestionable"], actual_gestionable)
                self.assertEqual(case["expected_reason"], actual_reason)

    def test_assignment_is_the_only_active_period_exception(self) -> None:
        active_unassigned = [
            case
            for case in self.cases
            if case["appears_active"] and not case["assigned_current"]
        ]
        self.assertTrue(active_unassigned)
        self.assertTrue(
            all(not canonical_monthly_policy(case)[0] for case in active_unassigned)
        )

    def test_internal_management_does_not_grant_eligibility(self) -> None:
        managed_by_me = [case for case in self.cases if case["managed_by_me"]]
        self.assertTrue(managed_by_me)
        self.assertTrue(
            all(not canonical_monthly_policy(case)[0] for case in managed_by_me)
        )

    def test_newer_invalid_appearance_does_not_hide_last_valid_status(self) -> None:
        case = next(
            case
            for case in self.cases
            if case["id"] == "newer-invalid-older-no-gestionado"
        )
        self.assertEqual((True, "latest_no_gestionado"), canonical_monthly_policy(case))

    def test_observed_contact_without_any_valid_status_fails_closed(self) -> None:
        case = next(
            case
            for case in self.cases
            if case["id"] == "observed-without-valid-status"
        )
        self.assertEqual((False, "latest_status_missing"), canonical_monthly_policy(case))

    def test_manual_contact_is_gestionable(self) -> None:
        case = next(case for case in self.cases if case["id"] == "manual-contact")
        self.assertEqual((True, "manual_contact"), canonical_monthly_policy(case))

    def test_all_runtime_paths_use_the_same_database_policy(self) -> None:
        helper_call = "public.contact_eligibility_for_period"
        for function_name in (
            "get_contacts_v2",
            "rebuild_work_queue_for_period",
            "sync_work_queue_for_period_batch",
        ):
            marker = f"create function public.{function_name}"
            start = self.migration.index(marker)
            next_function = self.migration.find("\ncreate function public.", start + len(marker))
            section = self.migration[start : next_function if next_function >= 0 else None]
            self.assertIn(helper_call, section, function_name)

    def test_refinement_uses_last_valid_status_with_temporal_boundary(self) -> None:
        normalized = " ".join(self.refinement.split())
        self.assertIn("cms.period <= p_period", normalized)
        self.assertIn("valid_status_rows", normalized)
        self.assertIn("latest_valid_period", normalized)
        self.assertIn("latest_valid_status", normalized)
        self.assertIn("manual_contact", normalized)
        self.assertIn("latest_status_missing", normalized)

    def test_assigned_import_does_not_create_operational_management(self) -> None:
        marker = "create function public.process_assigned_load"
        start = self.migration.index(marker)
        section = self.migration[
            start : self.migration.index("\ncreate function public.get_contacts_v2", start)
        ]
        self.assertIn("'operational_state_mutations', 0", section)
        self.assertNotIn("insert into public.contact_operational_state", section.lower())
        self.assertNotIn("update public.contact_operational_state", section.lower())

    def test_rollback_restores_legacy_functions(self) -> None:
        rollback = (
            ROOT
            / "supabase"
            / "rollback"
            / "20260715_unify_contact_eligibility_policy.sql"
        ).read_text(encoding="utf-8")
        for function_name in (
            "get_contacts_v2",
            "rebuild_work_queue_for_period",
            "sync_work_queue_for_period_batch",
            "process_monthly_state_batch",
            "process_assigned_load",
        ):
            self.assertIn(
                f"rename to {function_name};",
                rollback,
                function_name,
            )


if __name__ == "__main__":
    unittest.main()
