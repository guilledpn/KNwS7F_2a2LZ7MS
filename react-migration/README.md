# React migration · Hito 2 parcial

Esta carpeta contiene la base experimental Vite + React + TypeScript para APP LLAMADOS.

## Estado

No es produccion. No reemplaza `index.html` ni `sw.js` de la app publicada.

La rama actual es experimental:

```txt
migration/vite-react-foundation
```

## Objetivo actual

- Crear estructura moderna sin tocar produccion.
- Mantener Graphite como base visual.
- Reproducir shell general: topbar, bottom nav y pantallas equivalentes.
- Dejar componentes base para Contactos, Stats, Importar, Ajustes y Sprint.
- Crear capa inicial `lib/supabase.ts` y `lib/crmApi.ts`.
- Hito 2 parcial: `ContactList` ya llama a `getContacts()`.

## Variables de entorno

Para probar contactos reales localmente, copiar `.env.example` como `.env.local`:

```bash
cd react-migration
cp .env.example .env.local
```

Luego editar `.env.local` y completar:

```txt
VITE_SUPABASE_ANON_KEY=...
```

Usar solo la anon/publishable key publica. Nunca usar service_role, JWT secret ni claves privadas.

## Como ejecutar localmente

```bash
cd react-migration
npm install
npm run dev
```

Para validar build productivo:

```bash
npm run build
```

Para revisar el build local:

```bash
npm run preview
```

## Validacion esperada

Sin `.env.local`, la app debe compilar y abrir, pero Contactos no mostrara datos reales.

Con `.env.local` y anon key publica valida, Contactos debe llamar a Supabase mediante `get_contacts_v2` y mostrar filas reales.

## GitHub Actions

El PR ejecuta automaticamente:

```bash
cd react-migration
npm install
npm run build
```

El check verde solo confirma compilacion. La validacion de datos reales requiere entorno local o preview con variable `VITE_SUPABASE_ANON_KEY` configurada.

## Regla principal

La migracion no debe redisenar la app. Primero debe reproducir App_llamados_v1.05 y recien despues mejorar arquitectura interna.

## Pendientes proximos

1. Hito 2: probar Contactos reales con `.env.local`.
2. Hito 3: Detalle y gestion.
3. Hito 4: Stats.
4. Hito 5: Importar, Ajustes y Sprint reales.
5. Hito 6: comparacion visual completa contra App_llamados_v1.05.
