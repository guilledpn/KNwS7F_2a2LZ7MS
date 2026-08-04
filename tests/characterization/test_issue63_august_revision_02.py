from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
MIGRATIONS = sorted((ROOT / "supabase" / "migrations").glob("202608042145*_issue63_revision_02_*.sql"))
FILES = [
    ROOT / "tools" / "issue63_stage_revision_02.py",
    ROOT / "tools" / "issue63_revision_02_model.py",
    ROOT / "tools" / "issue63_revision_02_runtime.py",
]
CLEANUP = ROOT / "supabase" / "operations" / "issue63_cleanup.sql"


def load_cli():
    spec = importlib.util.spec_from_file_location("issue63_stage_revision_02", FILES[0])
    if spec is None or spec.loader is None:
        raise RuntimeError("No fue posible cargar el ejecutor")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class Issue63AugustRevision02Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sql = "\n".join(p.read_text(encoding="utf-8") for p in MIGRATIONS)
        cls.tool = "\n".join(p.read_text(encoding="utf-8") for p in FILES)
        cls.cleanup = CLEANUP.read_text(encoding="utf-8")
        cls.module = load_cli()

    def test_artifacts_and_hash_contract(self):
        self.assertEqual(len(MIGRATIONS), 6)
        self.assertTrue(all(p.is_file() for p in FILES + [CLEANUP]))
        for name, rows, xlsx_hash, payload_hash in (
            ("202608_TOTAL_02_NM.xlsx", 84912,
             "116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd",
             "81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef"),
            ("202608_ASIGNADO_02_NM.xlsx", 198,
             "43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019",
             "201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76"),
        ):
            for value in (name, str(rows), xlsx_hash, payload_hash):
                self.assertIn(value, self.sql + self.tool)

    def test_no_credentials_or_real_files(self):
        content = self.sql + self.tool
        self.assertNotIn("lijibbhpyyptodneafdd.supabase.co", content)
        self.assertNotIn("eyJhbGciOi", content)
        self.assertNotIn("service_role", content.lower())
        self.assertFalse(any(ROOT.rglob("202608_*_02_NM.xlsx")))

    def test_security_surface(self):
        self.assertIn("revoke all on schema issue63_ops from public, anon, authenticated", self.sql)
        for table in ("operation", "file_manifest", "stage_rows", "snapshot_contacts",
                      "snapshot_campaigns", "snapshot_cms", "snapshot_monthly_order",
                      "snapshot_work_queue", "snapshot_import_runs", "snapshot_import_progress"):
            self.assertIn(f"alter table issue63_ops.{table} enable row level security", self.sql)
        self.assertIn("coalesce(auth.jwt()->>'role','') <> 'anon'", self.sql)
        self.assertIn("grant execute on function public.crm_issue63_stage_chunk", self.sql)
        self.assertIn("grant execute on function public.crm_issue63_status(text)", self.sql)
        self.assertNotIn("to authenticated", self.sql)

    def test_stage_rpc_is_isolated(self):
        start = self.sql.index("create or replace function public.crm_issue63_stage_chunk")
        end = self.sql.index("create or replace function issue63_ops.validate_stage", start)
        rpc = self.sql[start:end]
        self.assertIn("insert into issue63_ops.stage_rows", rpc)
        for forbidden in ("public.contacts", "public.campaigns", "public.contact_month_state",
                          "public.work_queue", "rebuild_work_queue_for_period"):
            self.assertNotIn(forbidden, rpc)

    def test_apply_replaces_assignment_and_preserves_containment(self):
        self.assertEqual(self.module.PROD_PRIOR_STATE["assigned_added"], 145)
        self.assertEqual(self.module.PROD_PRIOR_STATE["assigned_removed"], 1)
        self.assertEqual(self.module.PROD_PRIOR_STATE["assigned_common"], 53)
        self.assertEqual(self.module.PROD_PRIOR_STATE["containment_rows"], 286)
        start = self.sql.index("create or replace function issue63_ops.apply_operation")
        apply_sql = self.sql[start:]
        self.assertIn("is_assigned=excluded.is_assigned", apply_sql)
        self.assertIn("jsonb_array_elements(e.details->'rows')", apply_sql)
        self.assertIn("e.assigned_current or not exists", apply_sql)
        self.assertNotIn("rebuild_work_queue_for_period", apply_sql)

    def test_validation_and_rollback_are_exact(self):
        for check in ("v_assigned_missing <> 0", "v_assigned_extra <> 0",
                      "v_order_mismatches <> 0", "v_preserved_context_mismatches <> 0",
                      "v_containment_nonassigned_visible <> 0"):
            self.assertIn(check, self.sql)
        self.assertNotIn("jsonb_object_length", self.sql)
        self.assertIn("Rollback blocked: PROD received writes", self.sql)
        for snapshot in ("snapshot_contacts", "snapshot_work_queue", "snapshot_cms"):
            self.assertIn(f"issue63_ops.{snapshot}", self.sql)

    def test_normalization_and_subset(self):
        m = self.module
        self.assertEqual(m.normalize_rut("12.345.678-k"), "12345678K")
        self.assertEqual(m.format_rut("12345678K"), "12345678-K")
        self.assertEqual(m.clean_campaign_description("2. PROFESIONALES"), "Profesionales")
        self.assertEqual(m.slug("Campaña · Propensión integral"), "campana-propension-integral")
        line = "1K\t1-K\tUno\t\t\t\t\tCampaña\tSegmento\tcampana\tNo Gestionado"
        total = m.ParsedFile(m.TOTAL_SPEC, Path("t"), (line,), "0"*64, "1"*64, 1,
                             {"No Gestionado":1}, {"campana":1})
        assigned = m.ParsedFile(m.ASSIGNED_SPEC, Path("a"), (line,), "2"*64, "3"*64, 1,
                                {"No Gestionado":1}, {"campana":1})
        self.assertEqual(m.validate_relationship(total, assigned)["missing"], 0)

    def test_runtime_and_cleanup_guards(self):
        m = self.module
        total = m.ParsedFile(m.TOTAL_SPEC, Path("t"), (), m.TOTAL_SPEC.expected_xlsx_sha256,
                             m.TOTAL_SPEC.expected_payload_sha256, 0, {}, {})
        assigned = m.ParsedFile(m.ASSIGNED_SPEC, Path("a"), (), m.ASSIGNED_SPEC.expected_xlsx_sha256,
                                m.ASSIGNED_SPEC.expected_payload_sha256, 0, {}, {})
        with tempfile.TemporaryDirectory() as td:
            m.prepare_runtime(total, assigned, Path(td), 1)
            with self.assertRaises(ValueError):
                m.prepare_runtime(total, assigned, Path(td), 1)
        self.assertIn("v_status not in ('applied','rolled_back')", self.cleanup)
        self.assertIn("drop schema if exists issue63_ops cascade", self.cleanup)


if __name__ == "__main__":
    unittest.main()
