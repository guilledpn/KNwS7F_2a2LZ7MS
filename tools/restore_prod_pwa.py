#!/usr/bin/env python3
"""Restore the minimal installable PWA shell for APP LLAMADOS PROD.

This script is intentionally idempotent. It only touches PWA metadata,
icons, the simple service-worker version marker, and the DEV snapshot
sanitizer needed to prevent PROD PWA metadata from leaking into DEV.
"""
from __future__ import annotations

import json
import math
import re
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "index.html"
MANIFEST = ROOT / "manifest.webmanifest"
SW = ROOT / "sw.js"
BUILDER = ROOT / "tools" / "build_dev_snapshot.py"
ICONS = ROOT / "icons"

PROD_PWA_ID = "/KNwS7F_2a2LZ7MS/"
PROD_SUPABASE_URL = "https://lijibbhpyyptodneafdd.supabase.co"
DEV_SUPABASE_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"
VERSION = "App_llamados_v1.05-pwa-restored-20260710"

NAVY = (9, 38, 87, 255)
BLUE = (109, 166, 242, 255)
DARK = (4, 22, 51, 255)
WHITE = (255, 253, 247, 255)
TRANSPARENT = (0, 0, 0, 0)

PWA_METADATA = """<!-- PROD_PWA_METADATA_START -->
<meta name="theme-color" content="#0f172a">
<meta name="application-name" content="CRM FFVV App Llamados">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="CRM FFVV">
<link rel="manifest" href="./manifest.webmanifest">
<link rel="icon" type="image/png" sizes="192x192" href="./icons/icon-192.png">
<link rel="apple-touch-icon" sizes="192x192" href="./icons/icon-192.png">
<!-- PROD_PWA_METADATA_END -->"""

SW_REGISTRATION = """<script id="prod-service-worker-registration">
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js', { scope: './' })
      .catch(error => console.warn('PROD service worker:', error));
  });
}
</script>"""

DEV_SANITIZER = r'''    # Strip PROD-only install metadata before creating the autonomous DEV artifact.
    html = re.sub(
        r"\n?<!-- PROD_PWA_METADATA_START -->.*?<!-- PROD_PWA_METADATA_END -->\n?",
        "\n",
        html,
        count=1,
        flags=re.DOTALL,
    )
    html = re.sub(
        r"\n?<script id=\"prod-service-worker-registration\">.*?</script>\n?",
        "\n",
        html,
        count=1,
        flags=re.DOTALL,
    )
'''


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return text.replace(old, new, 1)


def png_chunk(kind: bytes, data: bytes) -> bytes:
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def inside_rounded_square(x: float, y: float, margin: float = 0.055, radius: float = 0.205) -> bool:
    left, right = margin, 1.0 - margin
    top, bottom = margin, 1.0 - margin
    if left + radius <= x <= right - radius and top <= y <= bottom:
        return True
    if left <= x <= right and top + radius <= y <= bottom - radius:
        return True
    corners = (
        (left + radius, top + radius),
        (right - radius, top + radius),
        (left + radius, bottom - radius),
        (right - radius, bottom - radius),
    )
    return any((x - cx) ** 2 + (y - cy) ** 2 <= radius**2 for cx, cy in corners)


def icon_pixel(x: float, y: float) -> tuple[int, int, int, int]:
    if not inside_rounded_square(x, y):
        return TRANSPARENT
    dx, dy = x - 0.5, y - 0.5
    radius = math.hypot(dx, dy)
    color = NAVY
    if 0.235 <= radius <= 0.335:
        color = BLUE
    for nx, ny in ((0.5, 0.17), (0.83, 0.5), (0.5, 0.83), (0.17, 0.5)):
        if (x - nx) ** 2 + (y - ny) ** 2 <= 0.053**2:
            color = WHITE
    if abs(dx) + abs(dy) <= 0.19:
        color = DARK
    if radius <= 0.055:
        color = BLUE
    return color


def write_png(path: Path, size: int) -> None:
    rows = bytearray()
    for py in range(size):
        rows.append(0)
        y = (py + 0.5) / size
        for px in range(size):
            x = (px + 0.5) / size
            rows.extend(icon_pixel(x, y))
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    payload = signature + png_chunk(b"IHDR", ihdr) + png_chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + png_chunk(b"IEND", b"")
    path.write_bytes(payload)


def patch_index() -> None:
    html = INDEX.read_text(encoding="utf-8")
    if PROD_SUPABASE_URL not in html:
        raise RuntimeError("Bloqueo: index.html no apunta a Supabase PROD")
    if DEV_SUPABASE_URL in html:
        raise RuntimeError("Bloqueo: index.html contiene el endpoint Supabase DEV")

    html = re.sub(
        r"\n?<!-- PROD_PWA_METADATA_START -->.*?<!-- PROD_PWA_METADATA_END -->\n?",
        "\n",
        html,
        flags=re.DOTALL,
    )
    viewport = '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">'
    html = replace_once(html, viewport, viewport + "\n" + PWA_METADATA, "viewport PROD")

    html = re.sub(
        r"\n?<script id=\"prod-service-worker-registration\">.*?</script>\n?",
        "\n",
        html,
        flags=re.DOTALL,
    )
    html = replace_once(html, "</body>", SW_REGISTRATION + "\n</body>", "registro service worker PROD")
    INDEX.write_text(html.rstrip() + "\n", encoding="utf-8")


def patch_manifest() -> None:
    manifest = {
        "id": PROD_PWA_ID,
        "name": "CRM FFVV App Llamados",
        "short_name": "CRM FFVV",
        "description": "CRM personal de llamados y seguimiento comercial",
        "start_url": "./?pwa=prod-v105",
        "scope": "./",
        "display": "standalone",
        "orientation": "portrait",
        "background_color": "#f6f9ff",
        "theme_color": "#0f172a",
        "lang": "es-CL",
        "categories": ["business", "productivity"],
        "icons": [
            {"src": "./icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any"},
            {"src": "./icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable"},
            {"src": "./icons/icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any"},
        ],
    }
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def patch_service_worker() -> None:
    sw = SW.read_text(encoding="utf-8")
    sw, count = re.subn(r"^const APP_VERSION='[^']*';$", f"const APP_VERSION='{VERSION}';", sw, count=1, flags=re.MULTILINE)
    if count != 1:
        raise RuntimeError("No se pudo actualizar la versión del service worker")
    SW.write_text(sw.rstrip() + "\n", encoding="utf-8")


def patch_dev_builder() -> None:
    builder = BUILDER.read_text(encoding="utf-8")
    if "Strip PROD-only install metadata" in builder:
        return
    marker = "    built_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()\n\n"
    builder = replace_once(builder, marker, marker + DEV_SANITIZER + "\n", "sanitizador DEV")
    BUILDER.write_text(builder, encoding="utf-8")


def main() -> None:
    for path in (INDEX, MANIFEST, SW, BUILDER):
        if not path.exists():
            raise RuntimeError(f"Falta archivo requerido: {path.relative_to(ROOT)}")
    ICONS.mkdir(parents=True, exist_ok=True)
    patch_index()
    patch_manifest()
    patch_service_worker()
    write_png(ICONS / "icon-192.png", 192)
    write_png(ICONS / "icon-512.png", 512)
    patch_dev_builder()
    print("PASS: restauración PWA PROD aplicada de forma determinista")


if __name__ == "__main__":
    main()
