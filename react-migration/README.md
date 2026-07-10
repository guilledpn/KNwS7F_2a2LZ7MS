# React migration · Hito 1

Esta carpeta contiene la base experimental Vite + React + TypeScript para APP LLAMADOS.

## Estado

No es produccion. No reemplaza `index.html` ni `sw.js` de la app publicada.

## Objetivo del hito 1

- Crear estructura moderna sin tocar produccion.
- Mantener Graphite como base visual.
- Reproducir shell general: topbar, bottom nav y pantallas equivalentes.
- Dejar componentes base para Contactos, Stats, Importar, Ajustes y Sprint.
- Crear capa inicial `lib/supabase.ts` y `lib/crmApi.ts`.

## Como ejecutar localmente

```bash
cd react-migration
npm install
npm run dev
npm run build
```

## Regla principal

La migracion no debe redisenar la app. Primero debe reproducir App_llamados_v1.05 y recien despues mejorar arquitectura interna.

## Pendientes proximos

1. Hito 2: Contactos reales desde Supabase.
2. Hito 3: Detalle y gestion.
3. Hito 4: Stats.
4. Hito 5: Importar, Ajustes y Sprint reales.
5. Hito 6: comparacion visual completa contra App_llamados_v1.05.
