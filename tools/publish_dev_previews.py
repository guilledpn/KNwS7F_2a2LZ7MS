#!/usr/bin/env python3
"""Publica previews canónicos de src/dev/previews en el artefacto /dev."""
from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "src" / "dev" / "previews"
DEV_DIR = ROOT / "dev"
PREVIEWS = {
    "stats-financial-v2.html": "stats-v2.html",
}
ASSETS = {
    "stats-financial-v2.css": "assets/previews/stats-financial-v2.css",
    "stats-financial-rules.js": "assets/previews/stats-financial-rules.js",
    "stats-financial-view.js": "assets/previews/stats-financial-view.js",
}


def publish() -> None:
    missing = [name for name in (*PREVIEWS, *ASSETS) if not (SOURCE_DIR / name).is_file()]
    if missing:
        raise RuntimeError("Faltan previews canónicos: " + ", ".join(missing))
    DEV_DIR.mkdir(parents=True, exist_ok=True)
    for source_name, destination_name in {**PREVIEWS, **ASSETS}.items():
        destination = DEV_DIR / destination_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(SOURCE_DIR / source_name, destination)


if __name__ == "__main__":
    publish()
