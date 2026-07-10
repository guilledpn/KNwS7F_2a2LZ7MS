#!/usr/bin/env python3
"""Validate that DEV installs as a PWA distinct from PROD."""
from __future__ import annotations

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEV = ROOT / "dev"
PWA_ID = "/KNwS7F_2a2LZ7MS/dev/"


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise SystemExit(f"PNG inválido: {path}")
    return struct.unpack(">II", data[16:24])


def fail(message: str) -> None:
    raise SystemExit("Identidad PWA DEV inválida: " + message)


def main() -> None:
    required = {
        "index": DEV / "index.html",
        "manifest": DEV / "manifest.webmanifest",
        "sw": DEV / "sw.js",
        "build_info": DEV / "build-info.json",
        "svg": DEV / "icons" / "icon.svg",
        "png192": DEV / "icons" / "icon-192.png",
        "png512": DEV / "icons" / "icon-512.png",
    }
    missing = [name for name, path in required.items() if not path.exists()]
    if missing:
        fail("faltan archivos: " + ", ".join(missing))

    manifest = json.loads(required["manifest"].read_text(encoding="utf-8"))
    if manifest.get("id") != PWA_ID:
        fail("el manifest no tiene un id exclusivo de DEV")
    if manifest.get("name") != "APP LLAMADOS DEV" or manifest.get("short_name") != "LLAMADOS DEV":
        fail("nombre instalable incorrecto")
    sources = {item.get("src") for item in manifest.get("icons", [])}
    expected_sources = {"./icons/icon.svg", "./icons/icon-192.png", "./icons/icon-512.png"}
    if not expected_sources.issubset(sources):
        fail("manifest sin iconos DEV completos")

    if png_size(required["png192"]) != (192, 192):
        fail("icon-192.png tiene dimensiones incorrectas")
    if png_size(required["png512"]) != (512, 512):
        fail("icon-512.png tiene dimensiones incorrectas")

    svg = required["svg"].read_text(encoding="utf-8").lower()
    if "#f59e0b" not in svg or "#172033" not in svg:
        fail("icono SVG no usa identidad amarilla DEV")

    html = required["index"].read_text(encoding="utf-8")
    if './icons/icon-192.png' not in html:
        fail("HTML sin favicon amarillo DEV")
    if "APP LLAMADOS DEV" not in html:
        fail("HTML sin nombre DEV")

    sw = required["sw"].read_text(encoding="utf-8")
    if "./icons/icon-192.png" not in sw or "./icons/icon-512.png" not in sw:
        fail("service worker no precarga iconos DEV")

    info = json.loads(required["build_info"].read_text(encoding="utf-8"))
    if info.get("pwa_id") != PWA_ID:
        fail("build-info sin PWA id")
    if info.get("pwa_identity_distinct_from_prod") is not True:
        fail("build-info no declara separación de identidad")
    if info.get("icon_theme") != "dev_yellow":
        fail("build-info sin tema amarillo")

    print(json.dumps({
        "status": "PASS",
        "environment": "DEV",
        "pwa_id": PWA_ID,
        "name": manifest["name"],
        "icon_theme": "dev_yellow",
        "png_icons": ["192x192", "512x512"],
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
