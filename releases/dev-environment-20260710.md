# DEV environment · 2026-07-10

Se agrega ambiente DEV paralelo para APP LLAMADOS.

## Backend

- Supabase DEV: `crm-ffvv-dev`
- Project ID: `xcujixexjbuqqzlbomgw`
- Región: `sa-east-1`
- Datos ficticios.

## Frontend

- Endpoint previsto: `/dev/`
- Loader DEV que reutiliza la UI productiva y reemplaza la configuración Supabase por DEV.
- Banner visible: `DEV · NO PRODUCTIVO`.

## Seguridad

- Producción no se modifica.
- Supabase producción no se toca.
- No se usan claves privadas.
