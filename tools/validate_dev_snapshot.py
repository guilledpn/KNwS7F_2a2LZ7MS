#!/usr/bin/env python3
"""Fail-fast checks for the generated DEV application."""
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

DEV_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"
PROD_URL = "https://lijibbhpyyptodneafdd.supabase.co"


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


def validate_javascript(html: str) -> int:
    blocks = re.findall(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>", html, flags=re.I | re.S)
    if not blocks:
        fail("no se encontraron scripts inline")
    for number, block in enumerate(blocks, start=1):
        with tempfile.NamedTemporaryFile("w", suffix=f"-{number}.js", encoding="utf-8", delete=False) as tmp:
            tmp.write(block)
            path = Path(tmp.name)
        try:
            check = subprocess.run(
                ["node", "--check", str(path)],
                text=True,
                capture_output=True,
                check=False,
            )
            if check.returncode != 0:
                fail(f"JavaScript #{number} no compila: {check.stderr.strip()}")
        finally:
            path.unlink(missing_ok=True)
    return len(blocks)


def main() -> None:
    required = [
        INDEX,
        DEV / "manifest.webmanifest",
        DEV / "sw.js",
        DEV / "icons" / "icon.svg",
        DEV / "build-info.json",
        DEV / "README.md",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.exists()]
    if missing:
        fail("faltan archivos: " + ", ".join(missing))

    html = INDEX.read_text(encoding="utf-8")
    checks = {
        "endpoint Supabase DEV": DEV_URL in html,
        "ausencia endpoint PROD": PROD_URL not in html,
        "sin loader de index productivo": "fetch('../index.html" not in html,
        "sin document.write": "document.write(html)" not in html,
        "marca estructural DEV": 'data-app-env="dev"' in html,
        "invariante APP_ENV": "const APP_ENV = 'DEV';" in html,
        "manifest propio": 'href="./manifest.webmanifest"' in html,
        "service worker propio": "register('./sw.js',{scope:'./'})" in html,
        "almacenamiento DEV": "crm_ffvv_dev_" in html,
        "sin webhook MacroDroid productivo": "trigger.macrodroid.com" not in html,
        "sin webhook Tasks productivo": "script.google.com/macros" not in html,
        "advertencia visible DEV": "AMBIENTE DEV · Datos ficticios · No productivo" in html,
    }
    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        fail("fallaron controles: " + ", ".join(failed))

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

    sw = (DEV / "sw.js").read_text(encoding="utf-8")
    if "app-llamados-dev-" not in sw or "url.origin!==self.location.origin" not in sw:
        fail("service worker DEV no está correctamente aislado")
    if "../" in sw:
        fail("service worker DEV referencia rutas superiores")

    script_count = validate_javascript(html)
    print(json.dumps({
        "status": "PASS",
        "environment": "DEV",
        "inline_scripts_checked": script_count,
        "runtime_dependency_on_prod": False,
        "prod_endpoint_present": False,
        "external_webhooks_enabled_by_default": False,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
