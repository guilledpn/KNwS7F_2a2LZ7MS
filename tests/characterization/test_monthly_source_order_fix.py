from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class MonthlySourceOrderFixTests(unittest.TestCase):
    def test_prod_migration_history_is_versioned(self):
        expected = {
            "20260803031514_issue36_controlled_rebuild_gate.sql",
            "20260803032731_issue36_optimize_controlled_finalize_v4.sql",
            "20260803034013_issue36_hidden_august_ingest_gate.sql",
            "20260803034151_issue36_hidden_august_activation_gate.sql",
            "20260803034429_fix_issue36_hidden_ingest_delimiters.sql",
            "20260803034534_reduce_issue36_hidden_chunk_to_50.sql",
            "20260803041146_remove_issue36_temporary_operation_gates.sql",
            "20260803220701_fix_legacy_monthly_source_order.sql",
            "20260803222011_open_monthly_source_order_payload_202607.sql",
            "20260803223053_open_hash_locked_monthly_source_order_payload_upload.sql",
            "20260803223329_fix_hash_locked_monthly_source_order_payload_upload.sql",
            "20260803223442_widen_hash_locked_monthly_source_order_payload_upload.sql",
            "20260803223509_restore_hash_locked_monthly_source_order_payload_parts.sql",
            "20260803223837_extend_hash_locked_monthly_source_order_payload_upload.sql",
            "20260803230452_harden_monthly_source_order_capture.sql",
            "20260804000446_fix_monthly_source_order_security_assignment.sql",
        }
        migrations = ROOT / "supabase" / "migrations"
        self.assertTrue(expected.issubset({path.name for path in migrations.glob("*.sql")}))

    def test_final_migration_preserves_assigned_fact(self):
        migration = (
            ROOT
            / "supabase"
            / "migrations"
            / "20260804000446_fix_monthly_source_order_security_assignment.sql"
        ).read_text(encoding="utf-8")

        self.assertIn(
            "lower(trim(coalesce(s.load_type,''))) in ('asignado','assigned')",
            migration,
        )
        self.assertIn(
            "is_assigned = public.contact_month_state.is_assigned",
            migration,
        )
        self.assertIn("or excluded.is_assigned", migration)

    def test_order_helper_is_internal(self):
        migration = (
            ROOT
            / "supabase"
            / "migrations"
            / "20260804000446_fix_monthly_source_order_security_assignment.sql"
        ).read_text(encoding="utf-8")

        self.assertIn(
            "revoke all on function public.apply_monthly_source_order_to_queue(text)",
            migration,
        )
        self.assertIn("from public,anon,authenticated", migration)
        self.assertIn("to service_role", migration)
        self.assertNotIn(
            "grant execute on function public.apply_monthly_source_order_to_queue(text)\n"
            "  to authenticated",
            migration,
        )

    def test_activation_helper_cannot_change_queue_membership(self):
        migration = (
            ROOT
            / "supabase"
            / "migrations"
            / "20260803230452_harden_monthly_source_order_capture.sql"
        ).read_text(encoding="utf-8")
        start = migration.index(
            "create or replace function public.apply_monthly_source_order_to_queue"
        )
        end = migration.index(
            "-- The canonical rebuild uses monthly_source_order", start
        )
        helper = migration[start:end]

        self.assertIn("update public.work_queue w", helper)
        self.assertIn("set display_order =", helper)
        self.assertIn("and w.visible", helper)
        self.assertIn("and w.origen = 'regla'", helper)
        self.assertNotIn("insert into public.work_queue", helper)
        self.assertNotIn("delete from public.work_queue", helper)
        self.assertNotIn("set visible=", helper)


if __name__ == "__main__":
    unittest.main()
