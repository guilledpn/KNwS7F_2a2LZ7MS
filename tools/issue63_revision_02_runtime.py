"""Runtime local para configurar y cargar exclusivamente staging del Issue #63."""
from __future__ import annotations

import json
import os
import secrets
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Sequence

from issue63_revision_02_model import (
    ASSIGNED_SPEC,
    ISSUE,
    OPERATION_KEY,
    PERIOD,
    PROD_PRIOR_STATE,
    TOTAL_SPEC,
    ParsedFile,
    sha256_bytes,
)


def _manifest(total: ParsedFile, assigned: ParsedFile) -> list[dict[str, object]]:
    return [
        {
            "file_name": parsed.spec.file_name,
            "load_type": parsed.spec.load_type,
            "xlsx_sha256": parsed.xlsx_sha256,
            "payload_sha256": parsed.payload_sha256,
            "expected_rows": len(parsed.payload_lines),
            "expected_distinct_ruts": parsed.distinct_ruts,
            "expected_status_counts": parsed.status_counts,
            "expected_campaign_counts": parsed.campaign_counts,
        }
        for parsed in (total, assigned)
    ]


def _sql_json_literal(value: object) -> str:
    serialized = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return "'" + serialized.replace("'", "''") + "'::jsonb"


def prepare_runtime(
    total: ParsedFile,
    assigned: ParsedFile,
    output: Path,
    expires_hours: int,
) -> dict[str, object]:
    if not 1 <= expires_hours <= 72:
        raise ValueError("La expiración del runtime debe estar entre 1 y 72 horas")

    output.mkdir(parents=True, exist_ok=True)
    token_path = output / ".issue63_token"
    sql_path = output / "issue63_configure_runtime.sql"
    manifest_path = output / "issue63_runtime_manifest.json"
    if any(path.exists() for path in (token_path, sql_path, manifest_path)):
        raise ValueError("El runtime ya existe; no se sobrescribe")

    token = secrets.token_urlsafe(48)
    token_hash = sha256_bytes(token.encode())
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expires_hours)
    manifest = _manifest(total, assigned)
    arguments = [
        f"'{OPERATION_KEY}'",
        f"'{PERIOD}'",
        f"'{token_hash}'",
        f"'{expires_at.isoformat()}'::timestamptz",
        _sql_json_literal(manifest),
        _sql_json_literal(PROD_PRIOR_STATE),
    ]
    sql = "select issue63_ops.configure_operation(\n  " + ",\n  ".join(arguments) + "\n);\n"

    token_path.write_text(token, encoding="utf-8")
    os.chmod(token_path, 0o600)
    sql_path.write_text(sql, encoding="utf-8")

    public_manifest: dict[str, object] = {
        "issue": ISSUE,
        "operation_key": OPERATION_KEY,
        "expires_at": expires_at.isoformat(),
        "files": [total.public_summary(), assigned.public_summary()],
        "contains_pii": False,
        "contains_token": False,
    }
    manifest_path.write_text(
        json.dumps(public_manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return public_manifest


class RpcClient:
    def __init__(self, url: str, key: str, token: str):
        self.url = url.rstrip("/")
        self.key = key
        self.token = token

    def call(
        self,
        function_name: str,
        payload: dict[str, object],
        timeout: int = 90,
    ) -> dict[str, object]:
        request = urllib.request.Request(
            f"{self.url}/rest/v1/rpc/{function_name}",
            data=json.dumps(payload).encode(),
            method="POST",
            headers={
                "apikey": self.key,
                "Authorization": f"Bearer {self.key}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                result = json.loads(response.read().decode())
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as exc:
            detail = getattr(exc, "read", lambda: b"")().decode(errors="replace")
            raise RuntimeError(
                f"RPC {function_name} falló: {exc}; {detail[:500]}"
            ) from exc
        if not isinstance(result, dict) or result.get("ok") is not True:
            raise RuntimeError(f"Respuesta RPC inválida: {result}")
        return result

    def status(self) -> dict[str, object]:
        return self.call("crm_issue63_status", {"p_token": self.token}, 180)

    def stage(
        self,
        parsed: ParsedFile,
        start_order: int,
        lines: Sequence[str],
    ) -> dict[str, object]:
        tsv = "\n".join(lines)
        return self.call(
            "crm_issue63_stage_chunk",
            {
                "p_token": self.token,
                "p_file_name": parsed.spec.file_name,
                "p_load_type": parsed.spec.load_type,
                "p_period": PERIOD,
                "p_xlsx_sha256": parsed.xlsx_sha256,
                "p_start_order": start_order,
                "p_chunk_sha256": sha256_bytes(tsv.encode()),
                "p_tsv": tsv,
            },
        )


def _progress(status: dict[str, object], file_name: str) -> int:
    files = status.get("files", [])
    if isinstance(files, list):
        for item in files:
            if isinstance(item, dict) and item.get("file_name") == file_name:
                return int(item.get("contiguous_rows", 0))
    return 0


def stage_file(
    client: RpcClient,
    parsed: ParsedFile,
    chunk_size: int = 500,
) -> dict[str, object]:
    if not 1 <= chunk_size <= 500:
        raise ValueError("chunk_size debe estar entre 1 y 500")
    completed = _progress(client.status(), parsed.spec.file_name)
    started = time.monotonic()
    while completed < len(parsed.payload_lines):
        end = min(completed + chunk_size, len(parsed.payload_lines))
        result = client.stage(
            parsed,
            completed + 1,
            parsed.payload_lines[completed:end],
        )
        new_completed = int(result.get("contiguous_rows", 0))
        if new_completed <= completed:
            raise RuntimeError("El progreso remoto no avanzó")
        completed = new_completed
        if completed % 5_000 == 0 or completed == len(parsed.payload_lines):
            print(f"{parsed.spec.file_name}: {completed:,}/{len(parsed.payload_lines):,}")
    return {
        "file_name": parsed.spec.file_name,
        "staged_rows": completed,
        "elapsed_seconds": round(time.monotonic() - started, 2),
    }


def write_report(path: Path | None, value: dict[str, object]) -> None:
    if path:
        path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


def required_secret(cli_value: str | None, environment_name: str) -> str:
    value = cli_value or os.environ.get(environment_name, "")
    if not value:
        raise ValueError(f"Falta {environment_name}")
    return value


__all__ = [
    "ASSIGNED_SPEC",
    "ISSUE",
    "OPERATION_KEY",
    "PERIOD",
    "PROD_PRIOR_STATE",
    "TOTAL_SPEC",
    "RpcClient",
    "prepare_runtime",
    "required_secret",
    "stage_file",
    "write_report",
]
