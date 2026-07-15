#!/usr/bin/env python3
"""Run the minimum APP LLAMADOS Legacy safety net without touching PROD.

The DEV build is executed in a temporary workspace so the versioned ``dev/``
artifact and the productive root remain unchanged in the caller's checkout.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXCLUDED_COPY_NAMES = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    ".tmp",
}

DEV_COMMANDS = [
    ["tools/build_dev_snapshot.py"],
    ["tools/patch_dev_assigned_status.py"],
    ["tools/enhance_dev_pwa_identity.py"],
    ["tools/validate_dev_snapshot.py"],
    ["tools/validate_dev_assigned_status.py"],
    ["tools/validate_dev_pwa_identity.py"],
    ["tools/validate_prod_pwa.py"],
]


def run(command: list[str], *, cwd: Path, label: str) -> None:
    printable = " ".join(command)
    print(f"\n== {label} ==\n$ {printable}")
    result = subprocess.run(command, cwd=cwd, text=True, check=False)
    if result.returncode != 0:
        raise SystemExit(f"FAIL: {label} returned {result.returncode}")


def copy_repository_to_temp(destination: Path) -> Path:
    workspace = destination / "repo"

    def ignore(_directory: str, names: list[str]) -> set[str]:
        return {name for name in names if name in EXCLUDED_COPY_NAMES}

    shutil.copytree(ROOT, workspace, ignore=ignore)
    return workspace


def require_runtime() -> None:
    if shutil.which("node") is None:
        raise SystemExit("BLOQUEADO: Node.js is required by the existing JavaScript validators")
    if sys.version_info < (3, 11):
        raise SystemExit("BLOQUEADO: Python 3.11 or newer is required")


def main() -> None:
    require_runtime()

    run(
        [
            sys.executable,
            "-m",
            "unittest",
            "discover",
            "-s",
            "tests/characterization",
            "-p",
            "test_*.py",
            "-v",
        ],
        cwd=ROOT,
        label="Repository characterization",
    )

    run(
        [sys.executable, "tools/validate_prod_pwa.py"],
        cwd=ROOT,
        label="Read-only PROD shell validation",
    )

    with tempfile.TemporaryDirectory(prefix="app-llamados-safety-") as temporary:
        workspace = copy_repository_to_temp(Path(temporary))
        environment = os.environ.copy()
        environment.setdefault("GITHUB_SHA", "local-safety-check")

        for relative_command in DEV_COMMANDS:
            command = [sys.executable, *relative_command]
            printable = " ".join(command)
            label = relative_command[0]
            print(f"\n== Isolated DEV: {label} ==\n$ {printable}")
            result = subprocess.run(
                command,
                cwd=workspace,
                env=environment,
                text=True,
                check=False,
            )
            if result.returncode != 0:
                raise SystemExit(f"FAIL: isolated command {label} returned {result.returncode}")

    print(
        json.dumps(
            {
                "status": "PASS",
                "prod_modified": False,
                "dev_build_workspace": "temporary",
                "network_required": False,
                "prod_data_accessed": False,
                "checks": [
                    "repository_characterization",
                    "prod_shell_validation",
                    "isolated_dev_build",
                    "dev_snapshot_validation",
                    "environment_isolation",
                ],
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
