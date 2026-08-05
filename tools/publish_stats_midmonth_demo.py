#!/usr/bin/env python3
"""Publish the isolated mid-month Stats simulation into /dev.

The source is canonical. The /dev file is a generated GitHub Pages artifact.
No database connection, authentication token or production data is involved.
"""
from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "dev" / "previews" / "stats-financial-midmonth-demo.html"
DESTINATION = ROOT / "dev" / "stats-v2-midmonth-demo.html"


def publish() -> None:
    if not SOURCE.exists():
        raise RuntimeError(f"Missing canonical source: {SOURCE}")
    content = SOURCE.read_text(encoding="utf-8")
    forbidden = (
        "supabase.co",
        "SUPABASE_URL",
        "SUPABASE_ANON_KEY",
        "createClient(",
        ".rpc(",
        "service_role",
    )
    present = [token for token in forbidden if token.lower() in content.lower()]
    if present:
        raise RuntimeError("Simulation must remain disconnected from Supabase: " + ", ".join(present))
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SOURCE, DESTINATION)
    print(f"Published {SOURCE.relative_to(ROOT)} -> {DESTINATION.relative_to(ROOT)}")


if __name__ == "__main__":
    publish()
