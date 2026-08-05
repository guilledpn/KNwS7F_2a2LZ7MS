from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SETUP_PARTS = [
    ROOT / "supabase" / "operations" / f"issue63_setup_{index:02d}_{name}.sql"
    for index, name in (
        (1, "schema"),
        (2, "staging"),
        (3, "applied_validation"),
        (4, "apply_preflight"),
        (5, "apply_mutation"),
        (6, "rollback_validation"),
        (7, "rollback"),
    )
]
CLEANUP = ROOT / "supabase" / "operations" / "issue63_cleanup.sql"
TOOLS = [
    ROOT / "tools" / "issue63_stage_revision_02.py",
    ROOT / "tools" / "issue63_revision_02_model.py",
    ROOT / "tools" / "issue63_revision_02_runtime.py",
]


def load_model():
    tools_dir = str(TOOLS[1].parent)
    if tools_dir not in sys.path:
        sys.path.insert(0, tools_dir)
    spec = importlib.util.spec_from_file_location("issue63_revision_02_model", TOOLS[1])
    if spec is None or spec.loader is None:
        raise RuntimeError("No fue posible cargar el ejecutor")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class Issue63AugustRevision02Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sql = "\n".join(path.read_text(encoding="utf-8") for path in SETUP_PARTS)
        cls.cleanup = CLEANUP.read_text(encoding="utf-8")
        cls.tool = "\n".join(path.read_text(encoding="utf-8") for path in TOOLS)
        cls.module = load_model()

    def test_artifacts_and_hash_contract(self):
        self.assertTrue(all(path.is_file() for path in SETUP_PARTS))
        self.assertTrue(CLEANUP.is_file())
        self.assertTrue(all(path.is_file() for path in TOOLS))
        for value in (
            "202608_TOTAL_02_NM.xlsx",
            "84912",
            "116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd",
            "81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef",
            "202608_ASIGNADO_02_NM.xlsx",
            "198",
            "43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019",
            "201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76",
        ):
            self.assertIn(value, self.sql + self.tool)

    def test_operation_is_not_a_durable_migration(self):
        migrations = ROOT / "supabase" / "migrations"
        self.assertFalse(any(migrations.glob("*_issue63_*.sql")))
        self.assertIn("Operación excepcional, no migración durable", self.sql)
        self.assertEqual(len(SETUP_PARTS), 7)

    def test_no_credentials_or_real_files(self):
        content = self.sql + self.tool
        self.assertNotIn("lijibbhpyyptodneafdd.supabase.co", content)
        self.assertNotIn("eyJhbGciOi", content)
        self.assertNotIn("service_role", content.lower())
        self.assertFalse(any(ROOT.rglob("202608_*_02_NM.xlsx")))

    def test_security_surface_is_minimal(self):
        self.assertIn("revoke all on schema issue63_ops from public, anon, authenticated", self.sql)
        for table in (
            "operation",
            "file_manifest",
            "stage_rows",
            "snapshot_contacts",
            "snapshot_campaigns",
            "snapshot_cms",
            "snapshot_monthly_order",
            "snapshot_work_queue",
            "snapshot_import_runs",
            "snapshot_import_progress",
        ):
            self.assertIn(f"alter table issue63_ops.{table} enable row level security", self.sql)
        self.assertIn("coalesce(auth.jwt()->>'role','') <> 'anon'", self.sql)
        self.assertIn("grant execute on function public.crm_issue63_stage_chunk", self.sql)
        self.assertIn("grant execute on function public.crm_issue63_status(text) to anon", self.sql)
        self.assertNotIn("to authenticated", self.sql)

    def test_stage_rpc_is_isolated_from_canonical_tables(self):
        start = self.sql.index("create or replace function public.crm_issue63_stage_chunk")
        end = self.sql.index("create or replace function issue63_ops.validate_stage", start)
        rpc = self.sql[start:end]
        self.assertIn("insert into issue63_ops.stage_rows", rpc)
        for forbidden in (
            "public.contacts",
            "public.campaigns",
            "public.contact_month_state",
            "public.work_queue",
            "rebuild_work_queue_for_period",
        ):
            self.assertNotIn(forbidden, rpc)

    def test_apply_replaces_assignment_and_preserves_containment(self):
        self.assertEqual(self.module.PROD_PRIOR_STATE["assigned_added"], 145)
        self.assertEqual(self.module.PROD_PRIOR_STATE["assigned_removed"], 1)
        self.assertEqual(self.module.PROD_PRIOR_STATE["assigned_common"], 53)
        self.assertEqual(self.module.PROD_PRIOR_STATE["containment_rows"], 286)
        apply_sql = self.sql[self.sql.index("create or replace function issue63_ops.apply_operation") :]
        self.assertIn("is_assigned=excluded.is_assigned", apply_sql)
        self.assertIn("jsonb_array_elements(e.details->'rows')", apply_sql)
        self.assertIn("e.assigned_current or not exists", apply_sql)
        self.assertIn("lock table public.crm_log in share row exclusive mode", apply_sql)
        self.assertIn("delete from public.crm_import_runs current", apply_sql)
        runs_start = apply_sql.index("delete from public.crm_import_runs current")
        runs_end = apply_sql.index("insert into public.crm_import_progress", runs_start)
        self.assertNotIn("on conflict(file_name,load_type,period)", apply_sql[runs_start:runs_end])
        self.assertNotIn("rebuild_work_queue_for_period", apply_sql)

    def test_validation_preserves_work_item_identity_and_context(self):
        start = self.sql.index("create or replace function issue63_ops.validate_applied")
        end = self.sql.index("create or replace function issue63_ops.apply_operation", start)
        validation = self.sql[start:end]
        self.assertIn("left join public.work_queue w on w.work_item_id=s.work_item_id", validation)
        self.assertIn("w.work_item_id is null", validation)
        self.assertIn("v_preserved_context_mismatches <> 0", validation)

    def test_rollback_is_contractual_not_physically_exact(self):
        rollback = self.sql[self.sql.index("create or replace function issue63_ops.rollback_operation") :]
        self.assertNotIn("disable trigger", rollback.lower())
        self.assertNotIn("session_replication_role", rollback.lower())
        self.assertNotIn("pg_catalog.setval", rollback)
        self.assertNotIn("search_text=", rollback)
        self.assertIn("telefono_activo_idx=snapshot.telefono_activo_idx", rollback)
        self.assertIn("Rollback blocked: PROD received writes", rollback)
        self.assertIn("August entities acquired analysis references", rollback)
        self.assertIn("new contacts acquired external references", rollback)

    def test_rollback_validation_declares_technical_nonrequirements(self):
        self.assertIn("technical_identity_not_required", self.sql)
        for value in (
            "contacts.search_text",
            "contacts.updated_at",
            "sequence gaps",
            "guardrail events",
        ):
            self.assertIn(value, self.sql)
        self.assertIn("contacts_business_mismatch", self.sql)

    def test_normalization_and_subset(self):
        module = self.module
        self.assertEqual(module.normalize_rut("12.345.678-k"), "12345678K")
        self.assertEqual(module.format_rut("12345678K"), "12345678-K")
        self.assertEqual(module.clean_campaign_description("2. PROFESIONALES"), "Profesionales")
        self.assertEqual(module.slug("Campaña · Propensión integral"), "campana-propension-integral")
        line = "1K\t1-K\tUno\t\t\t\t\tCampaña\tSegmento\tcampana\tNo Gestionado"
        total = module.ParsedFile(module.TOTAL_SPEC, Path("t"), (line,), "0" * 64, "1" * 64, 1, {"No Gestionado": 1}, {"campana": 1})
        assigned = module.ParsedFile(module.ASSIGNED_SPEC, Path("a"), (line,), "2" * 64, "3" * 64, 1, {"No Gestionado": 1}, {"campana": 1})
        self.assertEqual(module.validate_relationship(total, assigned)["missing"], 0)

    def test_runtime_and_cli_guards(self):
        module = self.module
        from issue63_revision_02_runtime import prepare_runtime
        total = module.ParsedFile(module.TOTAL_SPEC, Path("t"), (), module.TOTAL_SPEC.expected_xlsx_sha256, module.TOTAL_SPEC.expected_payload_sha256, 0, {}, {})
        assigned = module.ParsedFile(module.ASSIGNED_SPEC, Path("a"), (), module.ASSIGNED_SPEC.expected_xlsx_sha256, module.ASSIGNED_SPEC.expected_payload_sha256, 0, {}, {})
        with tempfile.TemporaryDirectory() as directory:
            prepare_runtime(total, assigned, Path(directory), 1)
            with self.assertRaises(ValueError):
                prepare_runtime(total, assigned, Path(directory), 1)
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                prepare_runtime(total, assigned, Path(directory), 0)
            with self.assertRaises(ValueError):
                prepare_runtime(total, assigned, Path(directory), 73)
        cli = TOOLS[0].read_text(encoding="utf-8")
        for forbidden in ('add_parser("apply")', 'add_parser("rollback")', 'add_parser("cleanup")'):
            self.assertNotIn(forbidden, cli)
        self.assertIn("v_status not in ('applied','rolled_back')", self.cleanup)
        self.assertIn("drop schema if exists issue63_ops cascade", self.cleanup)


if __name__ == "__main__":
    unittest.main()
