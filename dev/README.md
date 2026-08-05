# APP LLAMADOS DEV

Artefacto DEV autónomo generado desde el commit `adb03a99cfd6`.

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

## Preview candidato de Stats financiero

Issue: `#67`.

- Ruta DEV: <https://guilledpn.github.io/KNwS7F_2a2LZ7MS/dev/stats-v2.html>
- Fuente canónica: `src/dev/previews/stats-financial-v2.html`.
- Reglas verificables: `src/dev/previews/stats-financial-rules.js`.
- Copias generadas: `dev/stats-v2.html` y `dev/assets/previews/stats-financial-rules.js`.
- Contrato de lectura: `get_stats_cockpit_v1` en `crm-ffvv-dev`.

La ruta es una superficie de validación aislada: no reemplaza Stats en la aplicación principal, no modifica PROD y no persiste Rachas, CNS ni dinero derivados.

Publicar y validar:

```bash
python tools/publish_dev_previews.py
python -m unittest -v tests/test_stats_financial_preview.py
```

## Identidad instalable

- PWA id: `/KNwS7F_2a2LZ7MS/dev/`
- Nombre: `APP LLAMADOS DEV`
- Iconos amarillos: 192 px, 512 px y SVG.
