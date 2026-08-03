# Fix Legacy: orden canónico de bases mensuales

Fecha: 2026-08-03

## Problema

Legacy conservaba `import_order` al leer el Excel, pero la cola operativa terminaba reutilizando órdenes de distintos períodos y contextos de campaña como si fueran una sola secuencia global. En consecuencia, el filtro **Pendientes** podía comenzar por una descripción posterior de la base aunque todavía existieran contactos gestionables cerca del inicio del archivo mensual.

## Alcance del fix

El cambio es aditivo y no modifica la interfaz Legacy.

- Se crea `public.monthly_source_order` para conservar la fila global original por período y contacto.
- Los contactos por regla se ordenan primero por antigüedad de la base de origen y luego por la fila canónica dentro de esa base.
- Los contactos asignados conservan su orden propio.
- Las cargas ASIGNADOS (`source_priority = 9999`) no pueden reemplazar el orden canónico de la base mensual TOTAL.
- Los filtros y la paginación continúan usando `get_contacts_v2` y `work_queue.display_order`.

## Fuentes canónicas usadas en el backfill

| Período | Archivo | Filas del archivo | Contactos con orden almacenado | SHA-256 |
|---|---:|---:|---:|---|
| 2026-07 | `202607_TOTAL_04_NM.xlsx` | 75.317 | 24.629 gestionables por regla usados por la cola de agosto | `c41991ea46037aec2115cee8e07a1f9ca49ac48437de5af5b84d9d426427ec4f` |
| 2026-08 | `202608_TOTAL_01_NM.xlsx` | 28.186 | 28.186 | `5a35c4c4d574b37a676a5653eeaa08487a8504dc3331026959ac381da72bc78c` |

## Validación PROD

Antes y después del cambio se conservaron exactamente:

| Invariante | Resultado |
|---|---:|
| Filas visibles | 53.635 |
| Asignados visibles | 54 |
| Gestionables por regla visibles | 53.581 |
| Pendientes | 53.553 |
| Huella de membresía, estados, origen y campaña | `07a45b9b63381b621cbb4aa87964ff27` |

Cambió solamente la huella de orden:

- antes: `9cc2dd78dfd25ecc053beb8e816ae539`
- después: `7f940c109c31b6d441304033d13e013a`

La primera página de 50 Pendientes pasó de mostrar 49 contactos de **Propensión integral** y 1 de **Excliente de vida** a mostrar contactos de **Ciclo de vida - protección**, comenzando desde las primeras filas gestionables de la base de agosto.

## Hallazgo separado

La cola de agosto ya contenía 766 filas visibles duplicadas respecto del contacto: 28.952 filas de origen agosto para 28.186 contactos distintos. Este fix no las creó ni las eliminó. La primera página devuelve 50 filas pero 48 contactos distintos debido a dos duplicados preexistentes.

La deduplicación debe tratarse como una corrección independiente porque podría afectar restricciones, historial y estados operativos.

## Seguridad y rollback

- No se modificaron `contacts`, estados de gestión, asignaciones, campañas, visibilidad ni historial.
- El backfill histórico actualizó únicamente `work_queue.display_order` y la tabla auxiliar de orden.
- La tabla auxiliar puede dejar de usarse restaurando las definiciones previas de las funciones; no es necesario borrar datos para desactivar el comportamiento.
- El orden mixto histórico anterior no se considera una fuente canónica y no se garantiza su reconstrucción exacta.
- Las cargas futuras capturan el orden del TOTAL automáticamente y excluyen explícitamente ASIGNADOS.

## Archivos de migración

- `supabase/migrations/20260803223000_fix_legacy_monthly_source_order.sql`
- `supabase/migrations/20260803234500_harden_monthly_source_order_capture.sql`
