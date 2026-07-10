# APP LLAMADOS · Separación profesional de DEV

Fecha: 2026-07-10  
Ambiente: DEV  
URL: <https://guilledpn.github.io/KNwS7F_2a2LZ7MS/dev/>

## Problema corregido

La versión anterior de `dev/index.html` era un loader. En cada apertura descargaba `../index.html`, reemplazaba en memoria el endpoint y la clave pública de Supabase, insertaba estilos DEV y ejecutaba `document.write()`.

Esto significaba que DEV dependía de PROD en tiempo de ejecución y podía romperse o apuntar al ambiente incorrecto si cambiaba el formato del archivo productivo.

## Arquitectura nueva

`/dev/` pasa a ser un artefacto estático autónomo generado en build time:

- `dev/index.html`: copia materializada e independiente;
- `dev/manifest.webmanifest`: instalación PWA con nombre y scope DEV;
- `dev/sw.js`: service worker limitado a `/dev/`;
- `dev/icons/icon.svg`: icono propio del artefacto;
- `dev/build-info.json`: trazabilidad del commit fuente;
- `dev/README.md`: reglas del artefacto generado.

La app DEV ya no descarga, reescribe ni ejecuta `../index.html`.

## Aislamientos implementados

1. Endpoint y publishable key exclusivos de `crm-ffvv-dev`.
2. Invariante de ejecución que detiene la app si la configuración no corresponde a DEV.
3. Claves `localStorage` con namespace `crm_ffvv_dev_`.
4. Estado local de Sprint separado de PROD.
5. Service worker con scope `./`, equivalente a `/dev/`.
6. Manifest, caché e icono independientes.
7. Webhooks de MacroDroid y Google Tasks vacíos por defecto para evitar efectos reales durante pruebas.
8. Marca DEV visible en login, título y ajustes.
9. `robots=noindex,nofollow,noarchive`.

## Proceso de generación

El generador está en:

`tools/build_dev_snapshot.py`

El validador está en:

`tools/validate_dev_snapshot.py`

La automatización está en:

`.github/workflows/build-dev-snapshot.yml`

Puede ejecutarse manualmente mediante `workflow_dispatch`. La primera incorporación a `main` también ejecuta el build automáticamente.

## Controles de seguridad del build

El build falla si:

- no encuentra exactamente los puntos esperados del archivo fuente;
- aparece la URL de Supabase PROD en el artefacto DEV;
- permanece el loader `fetch('../index.html')`;
- permanece `document.write(html)`;
- faltan manifest o service worker DEV;
- aparecen los webhooks reales como valores predeterminados;
- el JavaScript generado no supera `node --check`;
- la estructura HTML básica no puede analizarse;
- el workflow intenta modificar archivos fuera de `dev/`.

## Alcance

Esta etapa separa el despliegue y la configuración de ambientes. No modulariza todavía el monolito HTML/JS; esa será la siguiente fase de arquitectura.

PROD conserva su `index.html`, `sw.js` y manifest actuales sin modificaciones funcionales.
