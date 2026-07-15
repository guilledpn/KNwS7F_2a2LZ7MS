from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests" / "characterization" / "fixtures" / "eligibility-policy-cases.json"


def canonical_monthly_policy(case: dict[str, object]) -> bool:
    """Policy governed by the current Architecture and Business Model.

    Assigned contacts remain visible. Discovery candidates must be absent from the
    active period and their latest corporate monthly status must be No Gestionado.
    """

    if bool(case["assigned_current"]):
        return True
    if bool(case["appears_active"]):
        return False
    return case["last_monthly_status"] == "No Gestionado"


def current_owner_aware_policy(case: dict[str, object]) -> bool:
    """Reference expression currently visible in DEV get_contacts_v2."""

    return any(
        (
            bool(case["assigned_current"]),
            bool(case["managed_by_me"]),
            bool(case["available_by_age"]),
        )
    )


class EligibilityPolicyCharacterizationTests(unittest.TestCase):
    """Keep the known policy divergence visible until the dedicated fix lands.

    These tests do not approve the owner-aware policy. They document that the
    canonical domain policy and one current DEV implementation produce different
    outcomes for concrete fictitious cases.
    """

    @classmethod
    def setUpClass(cls) -> None:
        cls.cases = json.loads(FIXTURE.read_text(encoding="utf-8"))

    def test_fixture_expectations_match_both_reference_policies(self) -> None:
        for case in self.cases:
            with self.subTest(case=case["id"], policy="canonical"):
                self.assertEqual(case["expected_canonical"], canonical_monthly_policy(case))
            with self.subTest(case=case["id"], policy="owner-aware"):
                self.assertEqual(case["expected_owner_aware"], current_owner_aware_policy(case))

    def test_known_divergence_is_not_silently_erased(self) -> None:
        divergent = [
            case["id"]
            for case in self.cases
            if canonical_monthly_policy(case) != current_owner_aware_policy(case)
        ]
        self.assertEqual(
            [
                "active-unassigned-no-history",
                "historical-gestionado-without-operational-state",
                "active-unassigned-managed-by-me",
            ],
            divergent,
        )

    def test_assignment_is_an_exception_in_both_policies(self) -> None:
        assigned = next(case for case in self.cases if case["id"] == "assigned-active")
        self.assertTrue(canonical_monthly_policy(assigned))
        self.assertTrue(current_owner_aware_policy(assigned))

    def test_canonical_policy_excludes_active_unassigned_contacts(self) -> None:
        active_unassigned = [
            case
            for case in self.cases
            if case["appears_active"] and not case["assigned_current"]
        ]
        self.assertTrue(active_unassigned)
        self.assertTrue(all(not canonical_monthly_policy(case) for case in active_unassigned))


if __name__ == "__main__":
    unittest.main()
