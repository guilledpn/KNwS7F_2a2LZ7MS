from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROD_URL = "https://lijibbhpyyptodneafdd.supabase.co"
DEV_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"


class RepositoryContractTests(unittest.TestCase):
    """Characterize repository contracts that must survive the migration."""

    def read(self, relative_path: str) -> str:
        path = ROOT / relative_path
        self.assertTrue(path.exists(), f"Missing required file: {relative_path}")
        return path.read_text(encoding="utf-8")

    def test_productive_root_files_exist(self) -> None:
        required = [
            "index.html",
            "manifest.webmanifest",
            "sw.js",
            ".nojekyll",
            "icons/icon.svg",
            "icons/icon-192.png",
            "icons/icon-512.png",
            "tools/build_dev_snapshot.py",
            "tools/validate_prod_pwa.py",
            "tools/validate_dev_snapshot.py",
            "src/dev/config/environment.js",
        ]
        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual([], missing, f"Critical repository surface changed: {missing}")

    def test_prod_frontend_uses_only_prod_endpoint(self) -> None:
        html = self.read("index.html")
        self.assertIn(PROD_URL, html)
        self.assertNotIn(DEV_URL, html)
        self.assertNotIn("APP_ENV = 'DEV'", html)
        self.assertEqual(1, html.count('href="./manifest.webmanifest"'))
        self.assertEqual(1, html.count('id="prod-service-worker-registration"'))

    def test_dev_source_uses_only_dev_endpoint(self) -> None:
        environment = self.read("src/dev/config/environment.js")
        self.assertIn("appEnv: 'DEV'", environment)
        self.assertIn(DEV_URL, environment)
        self.assertNotIn(PROD_URL, environment)
        self.assertIn("externalIntegrationsEnabledByDefault: false", environment)
        self.assertIn("storageNamespace: 'crm_ffvv_dev_'", environment)
        self.assertIn("location.pathname.includes('/dev/')", environment)

    def test_builder_declares_isolation_guards(self) -> None:
        builder = self.read("tools/build_dev_snapshot.py")
        self.assertIn(DEV_URL, builder)
        self.assertIn(PROD_URL, builder)
        self.assertIn('"endpoint PROD": PROD_SUPABASE_URL', builder)
        self.assertIn('"service role": "service" + "_role"', builder)
        self.assertIn('DEV_DIR = ROOT / "dev"', builder)
        self.assertIn('SOURCE = ROOT / "index.html"', builder)
        self.assertIn('MODULE_SOURCE = ROOT / "src" / "dev"', builder)

    def test_current_workflows_are_explicitly_mutating(self) -> None:
        dev_workflow = self.read(".github/workflows/build-dev-snapshot.yml")
        prod_workflow = self.read(".github/workflows/restore-prod-pwa.yml")

        self.assertIn("contents: write", dev_workflow)
        self.assertIn("git push origin HEAD:main", dev_workflow)
        self.assertIn("git add dev/", dev_workflow)

        self.assertIn("contents: write", prod_workflow)
        self.assertIn("git push origin HEAD:main", prod_workflow)
        self.assertIn("Commit protected PROD patch", prod_workflow)

    def test_gitignore_protects_local_material_without_hiding_versioned_artifacts(self) -> None:
        ignore = self.read(".gitignore")
        for required_pattern in (".env", ".env.*", "node_modules/", "__pycache__/", ".venv/"):
            self.assertIn(required_pattern, ignore)

        self.assertIn("# dev/", ignore)
        self.assertIn("# diagnostics/", ignore)
        self.assertIn("# releases/", ignore)
        self.assertNotIn("\ndev/\n", f"\n{ignore}\n")

    def test_runtime_and_configuration_do_not_contain_private_secret_markers(self) -> None:
        # Security validators are intentionally excluded from this scan because they
        # contain the forbidden signatures as detection rules. Scanning a detector
        # for its own signature would create a self-referential false positive.
        files = [
            "index.html",
            "manifest.webmanifest",
            "sw.js",
            "src/dev/config/environment.js",
            "src/dev/core/errors.js",
            "src/dev/core/storage.js",
            "src/dev/core/supabase-client.js",
            "src/dev/core/auth.js",
            "src/dev/core/pwa.js",
            "src/dev/app.js",
            "tools/build_dev_snapshot.py",
        ]
        forbidden = (
            "-----begin private key-----",
            "jwt_secret=",
            "jwt secret:",
            "service_role=",
            "service role:",
        )
        for relative_path in files:
            text = self.read(relative_path).lower()
            for marker in forbidden:
                self.assertNotIn(marker, text, f"Forbidden marker in {relative_path}: {marker}")

    def test_security_validators_retain_sensitive_material_guards(self) -> None:
        prod_validator = self.read("tools/validate_prod_pwa.py").lower()
        dev_validator = self.read("tools/validate_dev_snapshot.py").lower()

        self.assertIn("service_role", prod_validator)
        self.assertIn("begin private key", prod_validator)
        self.assertIn("service_role", dev_validator)
        self.assertIn("private key", dev_validator)


if __name__ == "__main__":
    unittest.main()
