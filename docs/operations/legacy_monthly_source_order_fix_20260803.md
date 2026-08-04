# Fix Legacy: orden canónico de bases mensuales

Fecha operativa: 2026-08-03 / 2026-08-04 UTC

Issue: #45

PR: #44

## Problema

Legacy conservaba import_order por aparición, pero la cola mezclaba órdenes
locales de campañas y períodos como si fueran una secuencia global. Pendientes
no comenzaba necesariamente desde arriba del archivo mensual TOTAL.

## Regla implementada

- monthly_source_order conserva la posición global por período y Persona.
- TOTAL y ASIGNADOS mantienen órdenes independientes.
- una carga ASIGNADOS no puede sobrescribir el orden mensual TOTAL;
- la activación actualiza sólo display_order de filas visibles por regla;
- no se ejecuta rebuild_work_queue_for_period durante el backfill;
- filtros y paginación continúan mediante get_contacts_v2.

La regla ya estaba aprobada en el Modelo Operacional. No se requirió ADR ni LCD
nuevo.

## Conciliación de migraciones

Se recuperaron desde supabase_migrations.schema_migrations las quince
migraciones realmente aplicadas a PROD el 3 de agosto, incluidas las compuertas
temporales de los Issues #36 y #45. Se agregó la migración productiva final:

- 20260804000446_fix_monthly_source_order_security_assignment.sql.

Esta última:

- restaura is_assigned=true en inserciones ASIGNADOS;
- conserva la asignación en conflictos;
- revoca la RPC auxiliar a PUBLIC, anon y authenticated;
- permite su ejecución sólo a service_role;
- no modifica membresía ni orden de la cola.

DEV recibió la definición equivalente y aprobó una prueba transaccional
revertida de asignación, no sobrescritura del TOTAL e invariancia de membresía.

## Fuentes canónicas del backfill

| Período | Archivo | Filas | RUT distintos | SHA-256 |
|---|---|---:|---:|---|
| 2026-07 | 202607_TOTAL_04_NM.xlsx | 75.317 | 75.308 | c41991ea46037aec2115cee8e07a1f9ca49ac48437de5af5b84d9d426427ec4f |
| 2026-08 | 202608_TOTAL_01_NM.xlsx | 28.186 | 28.186 | 813a17ca1c7f26ea971fa6e11004d096632bb0a1c5f473c35c63cd6b5ffaef19 |

monthly_source_order quedó con 103.494 filas: 75.308 de julio y 28.186
de agosto.

## Aplicación PROD

Operación: issue45-prod-2026-08-order-v1.

- snapshot reversible: crm_guardrail_events.event_id = 7962;
- aplicación: crm_guardrail_events.event_id = 7963;
- órdenes modificadas: 21.453;
- rebuild ejecutado: no.

### Invariantes

| Control | Antes | Después |
|---|---:|---:|
| Filas visibles | 53.635 | 53.635 |
| Asignados visibles | 54 | 54 |
| Pendientes vacíos | 53.478 | 53.478 |
| Filas ocultas del Issue #43 | 286 | 286 |
| Huella de membresía | f5078d947a63343b0f2fb6c90f074c5f | igual |
| Huella de orden | 635e3e033d702a5f064a71f7488cb95b | f4174d1485527d7a92d785935987c063 |

No cambiaron visibilidad, estados, origen, campaña, asignaciones ni historia.
get_contacts_v2 respondió ok=true, 53.478 resultados y una página de 50 filas
legible después de la activación.

## Rollback

El evento 7962 conserva previous_display_order y previous_updated_at por
work_item_id, contact_id y período para las 21.453 filas modificadas. El
rollback debe restaurar exclusivamente esos valores exactos; no debe inferir
otra vez el conjunto.

## Riesgo residual

El Issue #43 permanece abierto: una reconstrucción completa de agosto todavía
podría reinsertar Personas contenidas. Hasta resolver su regla estructural, no
se debe usar un rebuild como mecanismo de reordenamiento.
