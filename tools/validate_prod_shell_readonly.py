#!/usr/bin/env python3
"""Validate the current APP LLAMADOS PROD shell without mutating files or data.

This validator is intentionally independent from ``restore_prod_pwa.py`` and from
its workflow. It characterizes the productive shell that is currently versioned,
without applying a historical restoration patch or requiring network access.
"""
from __future__ import annotations

import ast
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


def validate_inline_javascript(html: str) -> int:
    node = shutil.which("node")
    require(bool(node), "Node.js no está disponible para validar JavaScript")
    scripts = re.findall(
        r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>",
        html,
        flags=re.IGNORECASE | re.DOTALL,
    )
    require(len(scripts) >= 3, "No se detectaron todos los scripts inline esperados")
    with tempfile.TemporaryDirectory() as temporary:
        for number, source in enumerate(scripts, start=1):
            path = Path(temporary) / f"inline-{number}.js"
            path.write_text(source, encoding="utf-8")
            result = subprocess.run(
                [node, "--check", str(path)],
                capture_output=True,
                text=True,
                check=False,
            )
            require(
                result.returncode == 0,
                f"JavaScript inline {number} inválido:\n{result.stderr}",
            )
    return len(scripts)


def extract_single_constant(source: str, name: str) -> str:
    matches = re.findall(
        rf"^const\s+{re.escape(name)}\s*=\s*['\"]([^'\"]+)['\"]\s*;",
        source,
        flags=re.MULTILINE,
    )
    require(len(matches) == 1, f"Service worker: {name} ausente o duplicado")
    return matches[0]


def validate_dev_builder_sanitizer(source: str) -> None:
    """Verify executable sanitizers instead of relying on historical comments."""
    try:
        tree = ast.parse(source, filename=str(BUILDER))
    except SyntaxError as error:
        raise RuntimeError(f"El generador DEV no compila: {error}") from error

    re_sub_patterns: list[str] = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        function = node.func
        is_re_sub = (
            isinstance(function, ast.Attribute)
            and function.attr == "sub"
            and isinstance(function.value, ast.Name)
            and function.value.id == "re"
        )
        if not is_re_sub or not node.args:
            continue
        pattern = node.args[0]
        if isinstance(pattern, ast.Constant) and isinstance(pattern.value, str):
            re_sub_patterns.append(pattern.value)

    removes_prod_metadata = any(
        "PROD_PWA_METADATA_START" in pattern
        and "PROD_PWA_METADATA_END" in pattern
        for pattern in re_sub_patterns
    )
    removes_prod_registration = any(
        "prod-service-worker-registration" in pattern
        and "</script>" in pattern
        for pattern in re_sub_patterns
    )

    require(
        removes_prod_metadata,
        "El generador DEV no contiene una sanitización ejecutable del bloque PWA PROD",
    )
    require(
        removes_prod_registration,
        "El generador DEV no contiene una sanitización ejecutable del registro SW PROD",
    )


def main() -> None:
    for path in (INDEX, MANIFEST, SW, BUILDER):
        require(path.exists(), f"Falta {path.relative_to(ROOT)}")

    html = INDEX.read_text(encoding="utf-8")
    manifest_text = MANIFEST.read_text(encoding="utf-8")
    manifest = json.loads(manifest_text)
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

    app_version = extract_single_constant(sw, "APP_VERSION")
    patch_id = extract_single_constant(sw, "PATCH_ID")
    require(app_version.startswith("App_llamados_v1.05-"), "APP_VERSION no identifica APP LLAMADOS v1.05")
    require(patch_id.lower() in app_version.lower(), "APP_VERSION no referencia el PATCH_ID vigente")
    require("data-crm-stats-metrics-patch" in sw, "Service worker sin trazabilidad del parche Stats")
    require("self.addEventListener('install'" in sw, "SW sin install")
    require("self.addEventListener('activate'" in sw, "SW sin activate")
    require("self.addEventListener('fetch'" in sw, "SW sin fetch")
    require(DEV_URL not in sw, "Service worker PROD contiene endpoint DEV")

    validate_dev_builder_sanitizer(builder)

    forbidden = (
        "service" + "_role",
        "jwt" + " secret",
        "jwt" + "_secret",
        "-----begin " + "private key-----",
    )
    combined = "\n".join((html, manifest_text, sw, builder)).lower()
    for marker in forbidden:
        require(marker not in combined, f"Se detectó material sensible prohibido: {marker}")

    inline_count = validate_inline_javascript(html)

    dev_manifest = ROOT / "dev" / "manifest.webmanifest"
    if dev_manifest.exists():
        dev = json.loads(dev_manifest.read_text(encoding="utf-8"))
        require(dev.get("id") == DEV_ID, "DEV perdió su PWA id independiente")
        require(dev.get("id") != manifest.get("id"), "PROD y DEV tienen el mismo PWA id")

    print(
        json.dumps(
            {
                "status": "PASS",
                "validation": "read_only_prod_shell",
                "app_version": app_version,
                "patch_id": patch_id,
                "inline_scripts_checked": inline_count,
                "network_required": False,
                "prod_data_accessed": False,
                "files_modified": False,
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
