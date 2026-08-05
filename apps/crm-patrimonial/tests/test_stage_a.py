from __future__ import annotations

import json
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class StageAInfrastructureTests(unittest.TestCase):
    def test_required_shell_files_exist(self) -> None:
        for relative in (
            "index.html",
            "assets/styles.css",
            "assets/app.js",
            "manifest.webmanifest",
            "sw.js",
            "scripts/run_local.py",
            "supabase/config.toml",
        ):
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_manifest_is_scoped_to_next(self) -> None:
        manifest = json.loads((ROOT / "manifest.webmanifest").read_text(encoding="utf-8"))
        self.assertEqual(manifest["name"], "CRM Patrimonial Next")
        self.assertEqual(manifest["scope"], "./")
        self.assertEqual(manifest["display"], "standalone")

    def test_local_supabase_uses_independent_ports(self) -> None:
        config = tomllib.loads((ROOT / "supabase/config.toml").read_text(encoding="utf-8"))
        self.assertEqual(config["project_id"], "crm-patrimonial-next-local")
        ports = {config["api"]["port"], config["db"]["port"], config["db"]["shadow_port"], config["studio"]["port"], config["inbucket"]["port"]}
        self.assertEqual(len(ports), 5)
        self.assertTrue(all(56320 <= port <= 56324 for port in ports))

    def test_shell_has_no_legacy_runtime_reference(self) -> None:
        inspected = [ROOT / "index.html", ROOT / "assets/app.js", ROOT / ".env.example"]
        forbidden = ("xcujixexjbuqqzlbomgw", "lijibbhpyyptodneafdd", "crm-ffvv-dev", "crm-ffvv-v2")
        joined = "\n".join(path.read_text(encoding="utf-8") for path in inspected)
        for value in forbidden:
            self.assertNotIn(value, joined)


if __name__ == "__main__":
    unittest.main()
