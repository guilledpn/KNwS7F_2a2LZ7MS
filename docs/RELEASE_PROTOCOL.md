# APP LLAMADOS · Protocolo de releases

## Principio central

Produccion debe ser reproducible desde GitHub. La version publicada no debe depender de cache del navegador, Storage externo, wrappers ni archivos locales no versionados.

## Flujo obligatorio

1. Identificar commit actual de main.
2. Crear respaldo de main si el cambio toca produccion.
3. Trabajar en una rama separada.
4. Cambiar solo lo necesario.
5. Validar login, Contactos, Detalle, Stats, Importar, Ajustes y Sprint.
6. Registrar version, fecha, archivos y motivo.
7. Promover a main solo con aprobacion o si el cambio es documental sin riesgo.

## Branches

Usar nombres claros:

- feature/nombre-corto
- fix/nombre-corto
- docs/nombre-corto
- recovery/nombre-corto

## Checklist antes de main

- Login funciona.
- Contactos carga de entrada.
- La lista muestra datos reales.
- Filtros abren y cierran.
- Detalle abre y vuelve.
- Guardar gestion no rompe lista.
- Sprint aparece y opera.
- Stats carga.
- Importar abre.
- Ajustes muestra version y fecha.
- Movil y escritorio cargan.
- Service worker no sirve una version vieja.

## Rollback

Rollback valido:

- volver a una rama backup-main-before-version-fecha;
- volver a un commit estable;
- restaurar index.html completo desde releases;
- revertir commit completo.

Rollback no valido:

- reemplazar por una app recovery distinta sin permiso;
- usar wrappers que cargan otra app;
- reconstruir UI desde memoria;
- depender de cache del navegador.

## Version base recuperada

App_llamados_v1.05 · 2026-07-09 · Graphite · Supabase nuevo.
