# APP LLAMADOS · Arquitectura

## Estado actual

La version productiva App_llamados_v1.05 es una PWA CRM FFVV publicada desde GitHub Pages.

Actualmente la app vive principalmente en:

- `index.html`: UI, estilos, logica de cliente y llamadas a Supabase.
- `sw.js`: service worker simple.
- `manifest.webmanifest`: metadata PWA.
- assets e iconos del repo.

## Fuente canonica

La fuente canonica productiva debe ser el repositorio GitHub:

```txt
guilledpn/KNwS7F_2a2LZ7MS
branch main
```

No se debe tratar cache local, Supabase Storage ni archivos descargados como fuente principal.

## Componentes funcionales

### Contactos

Vista principal. Carga contactos reales desde Supabase. Usa RPCs para paginacion y filtros. Debe cargar de entrada.

### Detalle de contacto

Muestra datos del contacto, telefonos, email, campana, estado de gestion, comentarios, ingreso estimado y recordatorio.

### Stats

Vista nativa dentro de la app. Debe contar una historia operativa: que hice hoy, que falta para la meta, ritmo mensual y escenarios de cierre.

### Importar

Entrada para cargas mensuales o asignadas. Las cargas grandes deben procesarse con staging, lotes y checkpoints.

### Ajustes

Debe mostrar version y fecha. Debe permitir configuracion operativa. No debe reintroducir selector de tema salvo instruccion explicita.

### Sprint

Funcion de bloques de trabajo. Debe estar disponible sin romper navegacion ni topbar.

## Riesgo actual

El archivo `index.html` es monolitico. Esto dificulta revisar cambios, validar diffs, aislar errores y mantener estabilidad.

## Arquitectura objetivo

Migrar a Vite + React en una rama separada, sin tocar produccion hasta validar.

Estructura objetivo sugerida:

```txt
src/
  components/
    ContactList.tsx
    ContactDetail.tsx
    Stats.tsx
    Import.tsx
    Settings.tsx
    Sprint.tsx
  lib/
    supabase.ts
    crmApi.ts
    formatters.ts
    storage.ts
  styles/
    tokens.css
    graphite.css
    layout.css
  App.tsx
  main.tsx

docs/
  ARCHITECTURE.md
  DATABASE.md
  CHANGELOG.md
  RECOVERY.md
  RELEASE_PROTOCOL.md

releases/
  App_llamados_v1.05.html
```

## Regla de migracion

La migracion a React no debe redisenar la app. Debe reproducir primero la experiencia aprobada en App_llamados_v1.05 y solo despues mejorar arquitectura interna.
