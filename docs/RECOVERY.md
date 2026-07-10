# APP LLAMADOS · Recovery

## Version estable base

App_llamados_v1.05 · 2026-07-09 · Graphite · Supabase nuevo.

## Branches relevantes

- main
- backup-main-before-App_llamados_v1_05-20260709
- restore-v62-look-functional
- docs/app-llamados-operational-guardrails

## Recuperacion rapida

1. Detener cambios nuevos.
2. Revisar `main/index.html`.
3. Confirmar que el titulo HTML indique la version esperada.
4. Revisar `sw.js`.
5. Probar con parametro de version en la URL.
6. Si se ve una version vieja, limpiar cache o datos del sitio.

URL de prueba:

```txt
https://guilledpn.github.io/KNwS7F_2a2LZ7MS/?v=App_llamados_v1_05
```

## Cuando GitHub esta correcto pero el navegador no

Causa probable: cache local o service worker anterior.

Acciones:

- cerrar pestanas de la app;
- abrir con parametro nuevo;
- probar modo incognito;
- borrar datos del sitio `guilledpn.github.io`;
- reinstalar acceso directo si corresponde.

## Checklist despues de recuperar

- Login funciona.
- Contactos carga.
- Lista real visible.
- Detalle abre.
- Bottom nav correcto.
- Sprint aparece.
- Stats abre.
- Importar abre.
- Ajustes muestra version.
- Movil y escritorio cargan.

## Regla final

La recuperacion debe restaurar una version completa y aprobada. No debe cambiar la experiencia visual sin permiso explicito.
