#!/usr/bin/env python3
"""Give the generated DEV snapshot a distinct installable PWA identity."""
from __future__ import annotations

import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEV = ROOT / "dev"
INDEX = DEV / "index.html"
MANIFEST = DEV / "manifest.webmanifest"
SW = DEV / "sw.js"
BUILD_INFO = DEV / "build-info.json"
README = DEV / "README.md"
ICONS = DEV / "icons"

PWA_ID = "/KNwS7F_2a2LZ7MS/dev/"
YELLOW = (245, 158, 11, 255)
NAVY = (23, 32, 51, 255)
WHITE = (255, 253, 247, 255)
TRANSPARENT = (0, 0, 0, 0)


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

    cx = cy = 0.5
    dx, dy = x - cx, y - cy
    radius = math.hypot(dx, dy)

    color = YELLOW
    if 0.235 <= radius <= 0.335:
        color = NAVY

    node_radius = 0.053
    for nx, ny in ((0.5, 0.17), (0.83, 0.5), (0.5, 0.83), (0.17, 0.5)):
        if (x - nx) ** 2 + (y - ny) ** 2 <= node_radius**2:
            color = WHITE

    if abs(dx) + abs(dy) <= 0.19:
        color = NAVY

    # Small central DEV signal: a yellow core inside the dark diamond.
    if radius <= 0.055:
        color = YELLOW
    return color


def write_png(path: Path, size: int) -> None:
    rows = bytearray()
    for py in range(size):
        rows.append(0)  # PNG filter: none
        y = (py + 0.5) / size
        for px in range(size):
            x = (px + 0.5) / size
            rows.extend(icon_pixel(x, y))

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    data = signature + png_chunk(b"IHDR", ihdr) + png_chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + png_chunk(b"IEND", b"")
    path.write_bytes(data)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return text.replace(old, new, 1)


def main() -> None:
    for path in (INDEX, MANIFEST, SW, BUILD_INFO):
        if not path.exists():
            raise RuntimeError(f"Falta artefacto DEV: {path.relative_to(ROOT)}")

    ICONS.mkdir(parents=True, exist_ok=True)
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<rect x="28" y="28" width="456" height="456" rx="108" fill="#f59e0b"/>
<circle cx="256" cy="256" r="146" fill="none" stroke="#172033" stroke-width="48"/>
<path d="M256 159l97 97-97 97-97-97z" fill="#172033"/>
<circle cx="256" cy="256" r="28" fill="#f59e0b"/>
<g fill="#fffdf7"><circle cx="256" cy="87" r="30"/><circle cx="425" cy="256" r="30"/><circle cx="256" cy="425" r="30"/><circle cx="87" cy="256" r="30"/></g>
</svg>
"""
    (ICONS / "icon.svg").write_text(svg, encoding="utf-8")
    write_png(ICONS / "icon-192.png", 192)
    write_png(ICONS / "icon-512.png", 512)

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    manifest.update(
        {
            "id": PWA_ID,
            "name": "APP LLAMADOS DEV",
            "short_name": "LLAMADOS DEV",
            "description": "Ambiente DEV aislado de APP LLAMADOS",
            "categories": ["business", "productivity"],
            "icons": [
                {"src": "./icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any"},
                {"src": "./icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable"},
                {"src": "./icons/icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any maskable"},
            ],
        }
    )
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    html = INDEX.read_text(encoding="utf-8")
    icon_links = (
        '<link rel="icon" type="image/png" sizes="192x192" href="./icons/icon-192.png">\n'
        '<link rel="apple-touch-icon" sizes="192x192" href="./icons/icon-192.png">\n'
    )
    html = replace_once(html, '<link rel="manifest" href="./manifest.webmanifest">', '<link rel="manifest" href="./manifest.webmanifest">\n' + icon_links.rstrip(), "iconos HTML")
    INDEX.write_text(html, encoding="utf-8")

    sw = SW.read_text(encoding="utf-8")
    sw = replace_once(
        sw,
        "const SHELL=['./','./index.html','./manifest.webmanifest','./icons/icon.svg'];",
        "const SHELL=['./','./index.html','./manifest.webmanifest','./icons/icon.svg','./icons/icon-192.png','./icons/icon-512.png'];",
        "shell PWA",
    )
    SW.write_text(sw, encoding="utf-8")

    build_info = json.loads(BUILD_INFO.read_text(encoding="utf-8"))
    build_info["pwa_id"] = PWA_ID
    build_info["pwa_identity_distinct_from_prod"] = True
    build_info["icon_theme"] = "dev_yellow"
    BUILD_INFO.write_text(json.dumps(build_info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if README.exists():
        readme = README.read_text(encoding="utf-8")
        readme += "\n## Identidad instalable\n\n- PWA id: `" + PWA_ID + "`\n- Nombre: `APP LLAMADOS DEV`\n- Iconos amarillos: 192 px, 512 px y SVG.\n"
        README.write_text(readme, encoding="utf-8")


if __name__ == "__main__":
    main()
