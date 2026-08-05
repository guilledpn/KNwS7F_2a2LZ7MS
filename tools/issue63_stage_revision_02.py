#!/usr/bin/env python3
"""Valida los archivos y carga exclusivamente el staging temporal del Issue #63."""
from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from issue63_revision_02_model import (  # noqa: E402
    ASSIGNED_SPEC,
    ISSUE,
    TOTAL_SPEC,
    validate_inputs,
)
from issue63_revision_02_runtime import (  # noqa: E402
    RpcClient,
    prepare_runtime,
    required_secret,
    stage_file,
    write_report,
)


def add_files(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--total", type=Path, default=Path(TOTAL_SPEC.file_name))
    parser.add_argument("--assigned", type=Path, default=Path(ASSIGNED_SPEC.file_name))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate_parser = subparsers.add_parser("validate")
    add_files(validate_parser)
    validate_parser.add_argument("--report", type=Path)

    runtime_parser = subparsers.add_parser("prepare-runtime")
    add_files(runtime_parser)
    runtime_parser.add_argument("--output-dir", type=Path, required=True)
    runtime_parser.add_argument("--expires-hours", type=int, default=24)

    stage_parser = subparsers.add_parser("stage")
    add_files(stage_parser)
    stage_parser.add_argument("--token-file", type=Path, required=True)
    stage_parser.add_argument("--supabase-url")
    stage_parser.add_argument("--anon-key")
    stage_parser.add_argument("--report", type=Path, default=Path("issue63_stage_report.json"))

    status_parser = subparsers.add_parser("status")
    status_parser.add_argument("--token-file", type=Path, required=True)
    status_parser.add_argument("--supabase-url")
    status_parser.add_argument("--anon-key")

    args = parser.parse_args()
    try:
        if args.command in ("validate", "prepare-runtime", "stage"):
            total, assigned, relationship = validate_inputs(args.total, args.assigned)

        if args.command == "validate":
            report: dict[str, object] = {
                "issue": ISSUE,
                "mode": "validation_only",
                "files": [total.public_summary(), assigned.public_summary()],
                "relationship": relationship,
                "network_used": False,
                "prod_modified": False,
                "contains_pii": False,
            }
            write_report(args.report, report)
            print(json.dumps(report, ensure_ascii=False, indent=2))
            return 0

        if args.command == "prepare-runtime":
            result = prepare_runtime(
                total,
                assigned,
                args.output_dir,
                args.expires_hours,
            )
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0

        token = args.token_file.read_text(encoding="utf-8").strip()
        if len(token) < 40:
            raise ValueError("Token temporal inválido")
        client = RpcClient(
            required_secret(args.supabase_url, "ISSUE63_SUPABASE_URL"),
            required_secret(args.anon_key, "ISSUE63_ANON_KEY"),
            token,
        )

        if args.command == "status":
            print(json.dumps(client.status(), ensure_ascii=False, indent=2))
            return 0

        remote_before = client.status()
        uploads = [stage_file(client, total), stage_file(client, assigned)]
        remote_after = client.status()
        report = {
            "issue": ISSUE,
            "mode": "stage_only",
            "remote_before": remote_before,
            "uploads": uploads,
            "remote_after": remote_after,
            "canonical_apply_executed": False,
            "contains_pii": False,
            "contains_credentials": False,
        }
        write_report(args.report, report)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    except (ValueError, RuntimeError, FileNotFoundError, zipfile.BadZipFile) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
