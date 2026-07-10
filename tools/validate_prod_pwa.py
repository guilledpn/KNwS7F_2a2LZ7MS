#!/usr/bin/env python3
"""Validate APP LLAMADOS PROD PWA without changing data or runtime state."""
from __future__ import annotations

import json
import re
import shutil
import struct
import subprocess
import tempfile
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "index.html"
MANIFEST = ROOT / "manifest.webmanifest"
SW = ROOT / "sw.js"
BUILDER = ROOT / "tools" / "build_dev_snapshot.py"
PROD_URL = "https://lijibbhpyyptodneafdd.supabase.co"
DEV_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"
PROD_ID = "/KNwS7F_2a2LZ7MS/"
DEV_ID = "/KNwS7F_2a2LZ7MS/dev/"


class Parser(HTMLParser):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    require(data.startswith(b"\x89PNG\r\n\x1a\n"), f"{path}: firma PNG inválida")
    require(data[12:16] == b"IHDR", f"{path}: falta IHDR")
    return struct.unpack(">II", data[16:24])


def validate_inline_javascript(html: str) -> None:
    node = shutil.which("node")
    require(bool(node), "Node.js no está disponible para validar JavaScript")
    scripts = re.findall(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>", html, flags=re.IGNORECASE | re.DOTALL)
    require(len(scripts) >= 3, "No se detectaron todos los scripts inline esperados")
    with tempfile.TemporaryDirectory() as td:
        for index, source in enumerate(scripts, start=1):
            path = Path(td) / f"inline-{index}.js"
            path.write_text(source, encoding="utf-8")
            result = subprocess.run([node, "--check", str(path)], capture_output=True, text=True)
            require(result.returncode == 0, f"JavaScript inline {index} inválido:\n{result.stderr}")


def main() -> None:
    for path in (INDEX, MANIFEST, SW, BUILDER):
        require(path.exists(), f"Falta {path.relative_to(ROOT)}")

    html = INDEX.read_text(encoding="utf-8")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    sw = SW.read_text(encoding="utf-8")
    builder = BUILDER.read_text(encoding="utf-8")

    Parser().feed(html)
    require(html.lstrip().lower().startswith("<!doctype html>"), "index.html no comienza con doctype")
    require(html.count("<!-- PROD_PWA_METADATA_START -->") == 1, "Bloque PWA PROD faltante o duplicado")
    require(html.count("<!-- PROD_PWA_METADATA_END -->") == 1, "Cierre PWA PROD faltante o duplicado")
    require(html.count('<link rel="manifest" href="./manifest.webmanifest">') == 1, "Manifest PROD faltante o duplicado")
    require(html.count('id="prod-service-worker-registration"') == 1, "Registro SW PROD faltante o duplicado")
    require("navigator.serviceWorker.register('./sw.js', { scope: './' })" in html, "Registro del service worker incorrecto")
    require(PROD_URL in html, "El frontend PROD perdió su endpoint Supabase")
    require(DEV_URL not in html, "El frontend PROD contiene el endpoint DEV")
    require("APP_ENV = 'DEV'" not in html, "El frontend PROD contiene identidad DEV")

    required_manifest = {
        "id": PROD_ID,
        "name": "CRM FFVV App Llamados",
        "short_name": "CRM FFVV",
        "start_url": "./?pwa=prod-v105",
        "scope": "./",
        "display": "standalone",
        "theme_color": "#0f172a",
        "background_color": "#f6f9ff",
        "lang": "es-CL",
    }
    for key, expected in required_manifest.items():
        require(manifest.get(key) == expected, f"Manifest: {key} debe ser {expected!r}")
    require(manifest.get("id") != DEV_ID, "PROD y DEV comparten PWA id")

    icons = manifest.get("icons") or []
    declared = {(item.get("src"), item.get("sizes"), item.get("type")) for item in icons}
    require(("./icons/icon-192.png", "192x192", "image/png") in declared, "Falta icono PNG 192")
    require(("./icons/icon-512.png", "512x512", "image/png") in declared, "Falta icono PNG 512")
    require(png_dimensions(ROOT / "icons" / "icon-192.png") == (192, 192), "icon-192.png no mide 192x192")
    require(png_dimensions(ROOT / "icons" / "icon-512.png") == (512, 512), "icon-512.png no mide 512x512")

    require("App_llamados_v1.05-pwa-restored-20260710" in sw, "Versión PWA restaurada no trazable")
    require("self.addEventListener('install'" in sw, "SW sin install")
    require("self.addEventListener('activate'" in sw, "SW sin activate")
    require("self.addEventListener('fetch'" in sw, "SW sin fetch")
    require(DEV_URL not in sw, "Service worker PROD contiene endpoint DEV")

    require("Strip PROD-only install metadata" in builder, "El generador DEV no elimina metadatos PROD")
    require("prod-service-worker-registration" in builder, "El generador DEV no elimina el registro SW PROD")

    combined = "\n".join((html, MANIFEST.read_text(encoding="utf-8"), sw, builder)).lower()
    for forbidden in ("service_role", "jwt secret", "jwt_secret", "begin private key"):
        require(forbidden not in combined, f"Se detectó material sensible prohibido: {forbidden}")

    validate_inline_javascript(html)

    dev_manifest = ROOT / "dev" / "manifest.webmanifest"
    if dev_manifest.exists():
        dev = json.loads(dev_manifest.read_text(encoding="utf-8"))
        require(dev.get("id") == DEV_ID, "DEV perdió su PWA id independiente")
        require(dev.get("id") != manifest.get("id"), "PROD y DEV tienen el mismo PWA id")

    print("PASS: PROD PWA instalable, sintaxis válida, ambientes y credenciales aislados")


if __name__ == "__main__":
    main()
