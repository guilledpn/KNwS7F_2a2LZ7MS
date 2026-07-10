#!/usr/bin/env python3
"""Build an autonomous modular DEV artifact from the current production HTML.

PROD remains the visual/functional reference during this migration, but the generated
/dev application receives its own runtime modules, configuration, storage, auth and
PWA bootstrap. The browser never downloads or rewrites /index.html at runtime.
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
SOURCE_ICON = ROOT / "icons" / "icon.svg"
MODULE_SOURCE = ROOT / "src" / "dev"
DEV_DIR = ROOT / "dev"
DEV_INDEX = DEV_DIR / "index.html"
DEV_ICON = DEV_DIR / "icons" / "icon.svg"
MODULE_DEST = DEV_DIR / "assets" / "app"

DEV_SUPABASE_URL = "https://xcujixexjbuqqzlbomgw.supabase.co"
DEV_SUPABASE_KEY = "sb_publishable_eCchzuWGoCSl_Vnvyv_cYg_0A2CTDK8"
PROD_SUPABASE_URL = "https://lijibbhpyyptodneafdd.supabase.co"

MODULE_FILES = [
    "config/environment.js",
    "core/errors.js",
    "core/storage.js",
    "core/supabase-client.js",
    "core/auth.js",
    "core/pwa.js",
    "app.js",
]


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return text.replace(old, new, 1)


def regex_replace_once(
    text: str,
    pattern: str,
    replacement: str,
    label: str,
    *,
    flags: int = re.MULTILINE,
) -> str:
    result, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise RuntimeError(f"{label}: se esperaba 1 coincidencia y se encontraron {count}")
    return result


def copy_runtime_modules(source_sha: str) -> list[str]:
    missing = [path for path in MODULE_FILES if not (MODULE_SOURCE / path).exists()]
    if missing:
        raise RuntimeError("Faltan módulos DEV: " + ", ".join(missing))

    if MODULE_DEST.exists():
        shutil.rmtree(MODULE_DEST)
    shutil.copytree(MODULE_SOURCE, MODULE_DEST)

    environment_path = MODULE_DEST / "config" / "environment.js"
    environment = environment_path.read_text(encoding="utf-8")
    environment = replace_once(environment, "__APP_BUILD__", source_sha, "build id modular")
    environment = replace_once(
        environment,
        "__DEV_SUPABASE_PUBLISHABLE_KEY__",
        DEV_SUPABASE_KEY,
        "publishable key modular",
    )
    environment_path.write_text(environment, encoding="utf-8")

    return ["./assets/app/" + path for path in MODULE_FILES]


def build() -> None:
    if not SOURCE.exists():
        raise RuntimeError("No existe index.html productivo")
    if not SOURCE_ICON.exists():
        raise RuntimeError("No existe icons/icon.svg")
    if not MODULE_SOURCE.exists():
        raise RuntimeError("No existe src/dev")

    html = SOURCE.read_text(encoding="utf-8")
    source_sha = os.getenv("GITHUB_SHA", "local")[:12]
    built_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    module_web_paths = copy_runtime_modules(source_sha)

    # El artefacto DEV no hereda metadatos ni registro PWA de PROD.
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
    module_tags = "\n".join(f'<script src="{path}"></script>' for path in module_web_paths)
    html = replace_once(
        html,
        "</head>",
        f"{dev_css}\n{module_tags}\n</head>",
        "módulos y estilos DEV",
    )
    html = replace_once(html, "<body>", '<body data-app-env="dev">', "marca de ambiente")
    html = replace_once(
        html,
        '<div class="login-sub">Acceso privado</div>',
        '<div class="login-sub">Acceso privado · DEV</div>',
        "login DEV",
    )

    config_bridge = """// ════════════════════════════════════════════════════════════════════
//  DEV MODULAR RUNTIME · capa temporal de compatibilidad
// ════════════════════════════════════════════════════════════════════
const DEV_RUNTIME = window.AppDev;
if(!DEV_RUNTIME || !DEV_RUNTIME.ready){
  throw new Error('APP LLAMADOS DEV: runtime modular no inicializado');
}
const DEV_ENV = DEV_RUNTIME.environment;
const DEV_STORAGE = DEV_RUNTIME.storage;
const DEV_ERRORS = DEV_RUNTIME.errors;
const DEV_AUTH = DEV_RUNTIME.auth;
const APP_ENV = DEV_ENV.appEnv;
const APP_BUILD = DEV_ENV.buildId;
const SUPABASE_URL = DEV_ENV.supabaseUrl;
const SUPABASE_ANON_KEY = DEV_ENV.supabasePublishableKey;
const PAGE = DEV_ENV.pageSize;
const CONTACTS_V2_CACHE_VERSION = DEV_ENV.contactsCacheVersion;
const DEFAULT_MACRODROID_URL = DEV_ENV.macroDroidUrl;
const DEFAULT_TASKS_WEBHOOK_URL = DEV_ENV.tasksWebhookUrl;
// ════════════════════════════════════════════════════════════════════
"""
    html = regex_replace_once(
        html,
        r"// ═+\n//  CONFIG .*?\n// ═+\n",
        config_bridge,
        "puente modular de configuración",
        flags=re.MULTILINE | re.DOTALL,
    )
    html = replace_once(
        html,
        "const isConfigured = /^https?:\\/\\//.test(SUPABASE_URL) && !/TU-PROYECTO/.test(SUPABASE_URL) && !/TU-ANON-KEY/.test(SUPABASE_ANON_KEY);\n"
        "const sb = (window.supabase && isConfigured) ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;",
        "const isConfigured = DEV_RUNTIME.supabase.isConfigured();\n"
        "const sb = DEV_RUNTIME.supabase.getClient();",
        "cliente Supabase modular",
    )

    auth_bridge = """// ── auth modular con compatibilidad de UI ──
function showLogin(){$('login').classList.add('on');}
function showApp(){$('login').classList.remove('on');bootData();}
async function doLogin(){
  const email=($('login-email').value||'').trim(),pass=$('login-pass').value||'';
  if(!email||!pass){$('login-err').textContent='Ingresa correo y contraseña.';return;}
  $('login-btn').disabled=true;$('login-err').textContent='';
  try{await DEV_AUTH.signIn(email,pass);}
  catch(error){DEV_ERRORS.report(error,{source:'ui.doLogin'});$('login-err').textContent=error.message||String(error);}
  finally{$('login-btn').disabled=false;}
}
async function doMagic(){
  const email=($('login-email').value||'').trim();
  if(!email){$('login-err').textContent='Ingresa tu correo.';return;}
  try{await DEV_AUTH.signInWithOtp(email);toast('Enlace enviado, revisa tu correo');}
  catch(error){DEV_ERRORS.report(error,{source:'ui.doMagic'});toast(error.message||String(error));}
}
async function signOut(){
  try{await DEV_AUTH.signOut();}
  catch(error){DEV_ERRORS.report(error,{source:'ui.signOut'});toast('No se pudo cerrar sesión: '+(error.message||error));}
  finally{closeSettings();}
}
let booted=false;
async function bootData(){
  if(booted)return;booted=true;
  applyPalette(activePalette,true);
  const pp=$('period-pill');if(pp)pp.textContent=monthLabel(period).split(' ')[0];
  const ip=$('import-period');if(ip)ip.textContent=`${monthLabel(period)} · ${period}`;
  renderSteps();
  renderFilters();
  renderContactsSkeleton('Preparando contactos…');
  const contactsPromise=loadQueue(true);
  const auxPromise=Promise.allSettled([loadCampaigns(),refreshGoal()]).then(()=>{if($('filter-sheet')?.classList.contains('on'))renderFilterSheet();});
  await contactsPromise;
  auxPromise.catch(error=>DEV_ERRORS.report(error,{source:'bootData.aux'}));
}
async function initAuth(){
  applyPalette(activePalette,true);
  if(!DEV_AUTH.isConfigured()){showLogin();const w=$('login-config-warn');if(w)w.style.display='block';const b=$('login-btn');if(b)b.disabled=true;return;}
  try{
    const session=await DEV_AUTH.getSession();
    if(session)showApp();else showLogin();
    DEV_AUTH.onChange((_event,nextSession)=>{if(nextSession)showApp();else showLogin();});
  }catch(error){
    DEV_ERRORS.report(error,{source:'ui.initAuth'});
    showLogin();
    $('login-err').textContent='Error de conexión: '+(error.message||error);
  }
}
initAuth();"""
    html = regex_replace_once(
        html,
        r"// ── auth ──\n.*?\ninitAuth\(\);",
        auth_bridge,
        "autenticación modular",
        flags=re.MULTILINE | re.DOTALL,
    )

    # Todo acceso local del monolito pasa por el adaptador. Se mantienen las claves
    # existentes para conservar preferencias y Sprint del DEV ya instalado.
    html = html.replace("localStorage.getItem(", "DEV_STORAGE.getRaw(")
    html = html.replace("localStorage.setItem(", "DEV_STORAGE.setRaw(")
    html = html.replace("localStorage.removeItem(", "DEV_STORAGE.removeRaw(")
    html = html.replace("crm_ffvv_", "crm_ffvv_dev_")
    html = html.replace("recovery_crm_20260709_sprint_v2", "recovery_crm_dev_20260709_sprint_v2")
    html = html.replace("App_llamados_v1.05", "App_llamados_DEV · v1.05")
    html = html.replace(
        "App_llamados_DEV · v1.05 · 2026-07-09 · Graphite · Supabase nuevo",
        f"App_llamados_DEV · v1.05 · build {source_sha} · modular foundation",
    )

    combined_runtime = html + "\n" + "\n".join(
        (MODULE_DEST / path).read_text(encoding="utf-8") for path in MODULE_FILES
    )
    forbidden = {
        "endpoint PROD": PROD_SUPABASE_URL,
        "loader de PROD": "fetch('../index.html",
        "reescritura de documento": "document.write(html)",
        "service role": "service_role",
        "clave privada": "BEGIN PRIVATE KEY",
    }
    for label, value in forbidden.items():
        if value.lower() in combined_runtime.lower():
            raise RuntimeError(f"Snapshot inseguro: contiene {label}")
    if DEV_SUPABASE_URL not in combined_runtime:
        raise RuntimeError("Snapshot sin endpoint DEV")
    if "__DEV_SUPABASE_PUBLISHABLE_KEY__" in combined_runtime or "__APP_BUILD__" in combined_runtime:
        raise RuntimeError("Snapshot contiene placeholders sin resolver")
    if "./manifest.webmanifest" not in html:
        raise RuntimeError("Snapshot sin manifest DEV")
    if "DEV_RUNTIME.supabase.getClient()" not in html:
        raise RuntimeError("Snapshot sin cliente Supabase modular")
    if "DEV_AUTH.signIn" not in html:
        raise RuntimeError("Snapshot sin autenticación modular")
    if "localStorage." in html:
        raise RuntimeError("Snapshot mantiene acceso directo a localStorage")

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
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    module_shell_json = json.dumps(module_web_paths, ensure_ascii=False, separators=(",", ":"))
    sw = f"""'use strict';
const CACHE_NAME='app-llamados-dev-{source_sha}';
const SHELL=['./','./index.html','./manifest.webmanifest','./icons/icon.svg'];
const MODULE_SHELL={module_shell_json};

self.addEventListener('install',event=>{{
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(SHELL.concat(MODULE_SHELL))));
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
        "architecture": "modular-foundation",
        "legacy_ui_compatibility_layer": True,
        "runtime_modules": MODULE_FILES,
    }
    (DEV_DIR / "build-info.json").write_text(
        json.dumps(build_info, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    readme = f"""# APP LLAMADOS DEV

Artefacto DEV autónomo generado desde el commit `{source_sha}`.

- Supabase: `crm-ffvv-dev`
- URL: <https://guilledpn.github.io/KNwS7F_2a2LZ7MS/dev/>
- Arquitectura: fundación modular con capa temporal de compatibilidad de UI.
- Configuración, errores, almacenamiento, Supabase, auth y PWA viven en `src/dev/`.
- Los módulos se copian a `dev/assets/app/`; no se cargan desde PROD.
- No descarga ni modifica `../index.html` en tiempo de ejecución.
- Los webhooks externos quedan desactivados por defecto.

No editar `dev/index.html` ni `dev/assets/app/` manualmente. Regenerar con:

```bash
python tools/build_dev_snapshot.py
python tools/enhance_dev_pwa_identity.py
python tools/validate_dev_snapshot.py
python tools/validate_dev_pwa_identity.py
```
"""
    (DEV_DIR / "README.md").write_text(readme, encoding="utf-8")


if __name__ == "__main__":
    build()
