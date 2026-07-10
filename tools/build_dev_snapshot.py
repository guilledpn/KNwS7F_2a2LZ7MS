#!/usr/bin/env python3
"""Build an isolated DEV snapshot from the current production HTML.

This is a build-time copy. The generated /dev/index.html never fetches,
rewrites, or depends on /index.html at runtime.
"""
from __future__ import annotations

import json
import os
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "index.html"
DEV_DIR = ROOT / "dev"
DEV_INDEX = DEV_DIR / "index.html"
DEV_ICON = DEV_DIR / "icons" / "icon.svg"
SOURCE_ICON = ROOT / "icons" / "icon.svg"

DEV_SUPABASE_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"
DEV_SUPABASE_KEY = "sb_publishable_eCchzuWGoCSl_Vnvyv_cYg_0A2CTDK8"
PROD_SUPABASE_URL = "https://lijibbhpyyptodneafdd.supabase.co"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return text.replace(old, new, 1)


def regex_replace_once(text: str, pattern: str, replacement: str, label: str) -> str:
    result, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise RuntimeError(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return result


def build() -> None:
    if not SOURCE.exists():
        raise RuntimeError("No existe index.html productivo")
    if not SOURCE_ICON.exists():
        raise RuntimeError("No existe icons/icon.svg")

    html = SOURCE.read_text(encoding="utf-8")
    source_sha = os.getenv("GITHUB_SHA", "local")[:12]
    built_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    html = replace_once(
        html,
        '<title>App_llamados_v1.05</title>',
        '<title>APP LLAMADOS DEV · v1.05</title>',
        "título",
    )
    html = replace_once(
        html,
        '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">',
        '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">\n'
        '<meta name="robots" content="noindex,nofollow,noarchive">\n'
        '<meta name="theme-color" content="#f59e0b">\n'
        '<link rel="manifest" href="./manifest.webmanifest">',
        "metadatos DEV",
    )

    dev_css = """
<style id="dev-environment-style">
  body[data-app-env="dev"] .top-title:after{content:"DEV";display:inline-flex;vertical-align:middle;margin-left:8px;height:18px;padding:0 7px;border-radius:9px;align-items:center;background:#f59e0b;color:#111827;font:800 10px/18px Roboto,system-ui,sans-serif;letter-spacing:.08em}
  body[data-app-env="dev"] .login-logo:after{content:" DEV";color:#f59e0b;font-weight:800}
  body[data-app-env="dev"] .settings-body:before{content:"AMBIENTE DEV · Datos ficticios · No productivo";display:block;margin:0 0 12px;padding:10px 12px;border-radius:14px;background:#fef3c7;color:#92400e;font-weight:800;font-size:12px;letter-spacing:.04em}
</style>
""".strip()
    html = replace_once(html, "</head>", f"{dev_css}\n</head>", "estilos DEV")
    html = replace_once(html, "<body>", '<body data-app-env="dev">', "marca de ambiente")
    html = replace_once(html, "<div class=\"login-sub\">Acceso privado</div>", "<div class=\"login-sub\">Acceso privado · DEV</div>", "login DEV")

    html = regex_replace_once(
        html,
        r"^const SUPABASE_URL\s*=\s*'[^']*';[^\n]*$",
        f"const SUPABASE_URL      = '{DEV_SUPABASE_URL}';   // Supabase DEV",
        "URL Supabase",
    )
    html = regex_replace_once(
        html,
        r"^const SUPABASE_ANON_KEY\s*=\s*[^;]+;[^\n]*$",
        f"const SUPABASE_ANON_KEY = '{DEV_SUPABASE_KEY}'; // publishable key DEV",
        "publishable key",
    )
    html = regex_replace_once(
        html,
        r"^const DEFAULT_MACRODROID_URL\s*=\s*'[^']*';[^\n]*$",
        "const DEFAULT_MACRODROID_URL = ''; // DEV: integración externa desactivada por defecto",
        "webhook MacroDroid",
    )
    html = regex_replace_once(
        html,
        r"^const DEFAULT_TASKS_WEBHOOK_URL\s*=\s*'[^']*';[^\n]*$",
        "const DEFAULT_TASKS_WEBHOOK_URL = ''; // DEV: integración externa desactivada por defecto",
        "webhook Tasks",
    )
    html = replace_once(
        html,
        "const PAGE = 50;",
        "const APP_ENV = 'DEV';\nconst APP_BUILD = '" + source_sha + "';\nconst PAGE = 50;",
        "identidad de build",
    )

    # El almacenamiento web es por origen, no por ruta. DEV debe usar claves propias.
    html = html.replace("crm_ffvv_", "crm_ffvv_dev_")
    html = html.replace("recovery_crm_20260709_sprint_v2", "recovery_crm_dev_20260709_sprint_v2")
    html = html.replace("App_llamados_v1.05", "App_llamados_DEV · v1.05")
    html = html.replace(
        "App_llamados_DEV · v1.05 · 2026-07-09 · Graphite · Supabase nuevo",
        f"App_llamados_DEV · v1.05 · build {source_sha} · Supabase DEV",
    )

    invariant = f"""
if(APP_ENV!=='DEV'||SUPABASE_URL!=='{DEV_SUPABASE_URL}'){{
  throw new Error('Bloqueo de seguridad: configuración DEV inválida');
}}
""".strip()
    html = replace_once(
        html,
        "const isConfigured =",
        f"{invariant}\n\nconst isConfigured =",
        "invariante de ambiente",
    )

    sw_registration = """
<script id="dev-service-worker-registration">
if('serviceWorker' in navigator){
  window.addEventListener('load',()=>{
    navigator.serviceWorker.register('./sw.js',{scope:'./'}).catch(err=>console.warn('DEV service worker:',err));
  });
}
</script>
""".strip()
    html = replace_once(html, "</body>", f"{sw_registration}\n</body>", "registro service worker")

    forbidden = {
        "endpoint PROD": PROD_SUPABASE_URL,
        "loader de PROD": "fetch('../index.html",
        "reescritura de documento": "document.write(html)",
    }
    for label, value in forbidden.items():
        if value in html:
            raise RuntimeError(f"Snapshot inseguro: contiene {label}")
    if DEV_SUPABASE_URL not in html:
        raise RuntimeError("Snapshot sin endpoint DEV")
    if "./manifest.webmanifest" not in html or "./sw.js" not in html:
        raise RuntimeError("Snapshot sin PWA DEV aislada")

    DEV_DIR.mkdir(parents=True, exist_ok=True)
    DEV_INDEX.write_text(html.rstrip() + "\n", encoding="utf-8")
    DEV_ICON.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE_ICON, DEV_ICON)

    manifest = {
        "id": "./",
        "name": "APP LLAMADOS DEV",
        "short_name": "LLAMADOS DEV",
        "description": "Ambiente de desarrollo no productivo de APP LLAMADOS",
        "start_url": "./",
        "scope": "./",
        "display": "standalone",
        "background_color": "#f7f8fa",
        "theme_color": "#f59e0b",
        "lang": "es-CL",
        "icons": [
            {"src": "./icons/icon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any maskable"}
        ],
    }
    (DEV_DIR / "manifest.webmanifest").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    sw = f"""'use strict';
const CACHE_NAME='app-llamados-dev-{source_sha}';
const SHELL=['./','./index.html','./manifest.webmanifest','./icons/icon.svg'];

self.addEventListener('install',event=>{{
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(SHELL)));
}});

self.addEventListener('activate',event=>{{
  event.waitUntil((async()=>{{
    const keys=await caches.keys();
    await Promise.all(keys.filter(key=>key.startsWith('app-llamados-dev-')&&key!==CACHE_NAME).map(key=>caches.delete(key)));
    await self.clients.claim();
  }})());
}});

self.addEventListener('fetch',event=>{{
  const req=event.request;
  if(req.method!=='GET')return;
  const url=new URL(req.url);
  if(url.origin!==self.location.origin)return;
  if(req.mode==='navigate'){{
    event.respondWith(fetch(req).then(res=>{{
      const copy=res.clone();
      caches.open(CACHE_NAME).then(cache=>cache.put('./index.html',copy));
      return res;
    }}).catch(()=>caches.match('./index.html')));
    return;
  }}
  event.respondWith(caches.match(req).then(hit=>hit||fetch(req)));
}});
"""
    (DEV_DIR / "sw.js").write_text(sw, encoding="utf-8")

    build_info = {
        "environment": "DEV",
        "source_commit": source_sha,
        "built_at_utc": built_at,
        "supabase_project": "crm-ffvv-dev",
        "supabase_ref": "xcujixexjbuqqzlbomgw",
        "runtime_dependency_on_prod": False,
        "external_webhooks_enabled_by_default": False,
    }
    (DEV_DIR / "build-info.json").write_text(
        json.dumps(build_info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    readme = f"""# APP LLAMADOS DEV

Artefacto DEV autónomo generado desde el commit `{source_sha}`.

- Supabase: `crm-ffvv-dev`
- URL: <https://guilledpn.github.io/KNwS7F_2a2LZ7MS/dev/>
- No descarga ni modifica `../index.html` en tiempo de ejecución.
- Usa manifest, icono, service worker y claves de `localStorage` propios.
- Los webhooks externos quedan desactivados por defecto.

No editar `dev/index.html` manualmente. Regenerar con:

```bash
python tools/build_dev_snapshot.py
python tools/validate_dev_snapshot.py
```
"""
    (DEV_DIR / "README.md").write_text(readme, encoding="utf-8")


if __name__ == "__main__":
    build()
