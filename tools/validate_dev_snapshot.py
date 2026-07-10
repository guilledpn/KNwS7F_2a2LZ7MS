#!/usr/bin/env python3
"""Fail-fast checks for the generated modular DEV application."""
from __future__ import annotations

import json
import re
import subprocess
import tempfile
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEV = ROOT / "dev"
INDEX = DEV / "index.html"
MODULE_ROOT = DEV / "assets" / "app"

DEV_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"
PROD_URL = "https://lijibbhpyyptodneafdd.supabase.co"
MODULE_FILES = [
    "config/environment.js",
    "core/errors.js",
    "core/storage.js",
    "core/supabase-client.js",
    "core/auth.js",
    "core/pwa.js",
    "app.js",
]


class StrictEnoughHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.errors: list[str] = []
        self.seen_html = False
        self.seen_body = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "html":
            self.seen_html = True
        if tag == "body":
            self.seen_body = True

    def error(self, message: str) -> None:  # pragma: no cover
        self.errors.append(message)


def fail(message: str) -> None:
    raise SystemExit(f"DEV snapshot inválido: {message}")


def node_check(source: str, label: str) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as tmp:
        tmp.write(source)
        path = Path(tmp.name)
    try:
        check = subprocess.run(
            ["node", "--check", str(path)],
            text=True,
            capture_output=True,
            check=False,
        )
        if check.returncode != 0:
            fail(f"{label} no compila: {check.stderr.strip()}")
    finally:
        path.unlink(missing_ok=True)


def validate_inline_javascript(html: str) -> int:
    blocks = re.findall(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>", html, flags=re.I | re.S)
    if not blocks:
        fail("no se encontraron scripts inline")
    for number, block in enumerate(blocks, start=1):
        node_check(block, f"JavaScript inline #{number}")
    return len(blocks)


def main() -> None:
    module_paths = [MODULE_ROOT / path for path in MODULE_FILES]
    required = [
        INDEX,
        DEV / "manifest.webmanifest",
        DEV / "sw.js",
        DEV / "icons" / "icon.svg",
        DEV / "icons" / "icon-192.png",
        DEV / "icons" / "icon-512.png",
        DEV / "build-info.json",
        DEV / "README.md",
        *module_paths,
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.exists()]
    if missing:
        fail("faltan archivos: " + ", ".join(missing))

    html = INDEX.read_text(encoding="utf-8")
    module_sources = {
        path: (MODULE_ROOT / path).read_text(encoding="utf-8")
        for path in MODULE_FILES
    }
    combined = html + "\n" + "\n".join(module_sources.values())

    checks = {
        "endpoint Supabase DEV": DEV_URL in combined,
        "ausencia endpoint PROD": PROD_URL not in combined,
        "sin loader de index productivo": "fetch('../index.html" not in combined,
        "sin document.write": "document.write(html)" not in combined,
        "marca estructural DEV": 'data-app-env="dev"' in html,
        "runtime modular": "const DEV_RUNTIME = window.AppDev;" in html,
        "cliente Supabase modular": "DEV_RUNTIME.supabase.getClient()" in html,
        "sin createClient directo en UI": "createClient(" not in html,
        "auth modular": "DEV_AUTH.signIn" in html and "DEV_AUTH.getSession" in html,
        "storage modular": "const DEV_STORAGE = DEV_RUNTIME.storage;" in html,
        "sin localStorage directo en UI": "localStorage." not in html,
        "manifest propio": 'href="./manifest.webmanifest"' in html,
        "sin registro PWA inline legado": 'id="dev-service-worker-registration"' not in html,
        "módulo PWA": "namespace.pwa = Object.freeze" in module_sources["core/pwa.js"],
        "sin webhook MacroDroid productivo": "trigger.macrodroid.com" not in combined,
        "sin webhook Tasks productivo": "script.google.com/macros" not in combined,
        "advertencia visible DEV": "AMBIENTE DEV · Datos ficticios · No productivo" in html,
        "sin placeholders": "__APP_BUILD__" not in combined and "__DEV_SUPABASE_PUBLISHABLE_KEY__" not in combined,
    }
    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        fail("fallaron controles: " + ", ".join(failed))

    expected_tags = [
        f'<script src="./assets/app/{path}"></script>'
        for path in MODULE_FILES
    ]
    positions = [html.find(tag) for tag in expected_tags]
    if any(position < 0 for position in positions):
        fail("faltan etiquetas de módulos DEV")
    if positions != sorted(positions) or len(set(positions)) != len(positions):
        fail("orden de carga modular inválido")
    legacy_script = html.find("<script>\n'use strict';")
    if legacy_script < 0 or any(position > legacy_script for position in positions):
        fail("los módulos no cargan antes de la capa de compatibilidad")

    parser = StrictEnoughHTMLParser()
    parser.feed(html)
    parser.close()
    if parser.errors or not parser.seen_html or not parser.seen_body:
        fail("estructura HTML incompleta")

    manifest = json.loads((DEV / "manifest.webmanifest").read_text(encoding="utf-8"))
    if manifest.get("scope") != "./" or manifest.get("start_url") != "./":
        fail("manifest fuera del scope /dev/")
    if "DEV" not in manifest.get("name", ""):
        fail("manifest sin identidad DEV")

    build_info = json.loads((DEV / "build-info.json").read_text(encoding="utf-8"))
    if build_info.get("environment") != "DEV":
        fail("build-info sin ambiente DEV")
    if build_info.get("runtime_dependency_on_prod") is not False:
        fail("build-info declara dependencia de PROD")
    if build_info.get("external_webhooks_enabled_by_default") is not False:
        fail("integraciones externas activas por defecto")
    if build_info.get("architecture") != "modular-foundation":
        fail("build-info sin arquitectura modular")
    if build_info.get("runtime_modules") != MODULE_FILES:
        fail("build-info no coincide con módulos publicados")

    environment = module_sources["config/environment.js"]
    if "appEnv: 'DEV'" not in environment or "externalIntegrationsEnabledByDefault: false" not in environment:
        fail("environment.js no fija límites DEV")
    if "sb_publishable_" not in environment:
        fail("environment.js no contiene publishable key DEV")
    if "service_role" in environment.lower() or "private key" in environment.lower():
        fail("environment.js contiene material sensible prohibido")

    supabase_module = module_sources["core/supabase-client.js"]
    if supabase_module.count("createClient(") != 1:
        fail("cliente Supabase duplicado o ausente")
    if "persistSession: true" not in supabase_module:
        fail("cliente Supabase no preserva sesión")

    auth_module = module_sources["core/auth.js"]
    for operation in ("getSession", "signInWithPassword", "signInWithOtp", "signOut", "onAuthStateChange"):
        if operation not in auth_module:
            fail(f"auth.js no implementa {operation}")

    storage_module = module_sources["core/storage.js"]
    if "storageNamespace" not in storage_module or "resolveKey" not in storage_module:
        fail("storage.js no garantiza namespace DEV")

    sw = (DEV / "sw.js").read_text(encoding="utf-8")
    if "app-llamados-dev-" not in sw or "url.origin!==self.location.origin" not in sw:
        fail("service worker DEV no está correctamente aislado")
    if "../" in sw:
        fail("service worker DEV referencia rutas superiores")
    for path in MODULE_FILES:
        if f"./assets/app/{path}" not in sw:
            fail(f"service worker no precarga el módulo {path}")

    inline_count = validate_inline_javascript(html)
    for path, source in module_sources.items():
        node_check(source, f"Módulo {path}")

    print(json.dumps({
        "status": "PASS",
        "environment": "DEV",
        "architecture": "modular-foundation",
        "inline_scripts_checked": inline_count,
        "runtime_modules_checked": len(MODULE_FILES),
        "runtime_dependency_on_prod": False,
        "prod_endpoint_present": False,
        "external_webhooks_enabled_by_default": False,
        "direct_supabase_client_in_ui": False,
        "direct_local_storage_in_ui": False,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
