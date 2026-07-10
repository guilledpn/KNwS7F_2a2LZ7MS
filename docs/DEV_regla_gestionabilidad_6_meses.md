# DEV · Regla de gestionabilidad de 6 meses

Fecha de implementación en DEV: 2026-07-10  
Supabase: `crm-ffvv-dev` (`xcujixexjbuqqzlbomgw`)  
PROD: **no modificado**.

## Regla funcional corregida

Un contacto es gestionable cuando cumple al menos una de estas condiciones:

1. Está asignado en el período activo.
2. Su última gestión sustantiva fue realizada por el usuario actual.
3. No registra una gestión sustantiva de otro ejecutivo —o de autor desconocido— durante los últimos 6 meses calendario.

La asignación vigente y la gestión propia tienen prioridad sobre la ventana de 6 meses.

`Pendiente` no cuenta como gestión sustantiva. Sí cuentan `Agenda`, `No agenda`, `Volver a llamar`, `No contactado`, `Contacto Inválido` y `Gestionado`.

La aparición en una campaña no determina por sí sola la gestionabilidad. Cuando la última gestión corresponde a otra persona o no tiene autor conocido, el contacto vuelve a ser elegible en `última_gestión + 6 meses calendario`, incluyendo esa fecha.

## Implementación aplicada en DEV

- Tabla persistente: `public.contact_operational_state`.
- `crm_log` ahora registra `created_by` con el usuario autenticado.
- `contact_operational_state` conserva `last_managed_by` además de fecha, estado y próxima elegibilidad.
- Trigger en `public.crm_log`: `trg_sync_contact_operational_state_from_log`.
- Función de sincronización: `sync_contact_operational_state_from_log()`.
- Función administrativa de reconstrucción: `rebuild_contact_operational_state()`; no ejecutable desde el cliente autenticado.
- RPC de lectura reemplazada, conservando firma: `get_contacts_v2(...)`.
- RPC de guardado `save_gestion_v2(...)` registra explícitamente al autor en `crm_log` y `crm_events`.
- Migración Supabase aplicada: `correct_eligibility_for_self_managed_contacts`.
- RLS continúa habilitado; no se expusieron claves privadas ni acceso anónimo.

`work_queue` no es la fuente de verdad de la gestionabilidad. Continúa siendo una cola activa/reconstruible; `contacts` conserva la identidad canónica y `contact_operational_state` conserva el estado operativo.

## Comportamiento de presentación

- Asignado vigente: aparece como `Asignado` y conserva el estado de su cola actual.
- Gestionado por el usuario actual: aparece como `Gestionado por mí` y conserva su último estado, por ejemplo `Agenda` o `No agenda`.
- Gestión ajena o desconocida de más de 6 meses: reaparece como `Pendiente`, disponible por regla.
- Gestión ajena o desconocida reciente: no aparece entre los gestionables, salvo que esté asignado.

## Casos verificados en DEV

- Sin gestión conocida: disponible por regla.
- Gestión `Pendiente`: sigue disponible por regla.
- Gestión propia reciente y no asignado: sigue gestionable y conserva su estado.
- Gestión ajena/desconocida reciente y no asignado: no gestionable.
- Gestión ajena/desconocida de más de 6 meses y no asignado: disponible por regla.
- Gestión reciente y asignado: sigue gestionable por asignación.
- Búsqueda por RUT de un contacto histórico fuera de `work_queue`: funciona.

Datos de prueba sanitizados usados:

- `10000015-4`: gestión propia reciente, no asignado; aparece como `Gestionado por mí` y `No agenda`.
- `10000013-2`: gestión reciente de autor desconocido, no asignado; no aparece entre gestionables.
- `10000017-6`: gestión antigua de autor desconocido; nuevamente elegible.
- `10000001-1`: gestión reciente, pero asignado; sigue apareciendo.
- `10000014-3`: sin gestión sustantiva / solo `Pendiente`.

## Bloqueador antes de STAGING/PROD

La promoción requiere que el historial permita distinguir razonablemente entre gestión propia y gestión ajena. Los registros históricos sin autor se tratan conservadoramente como gestión de autor desconocido y bloquean durante 6 meses.

Antes de promover se debe:

1. recuperar o inferir `created_by` desde `crm_events` cuando exista;
2. definir cómo tratar registros antiguos sin autor;
3. probar rendimiento con volumen comparable a PROD;
4. ejecutar smoke test completo en STAGING;
5. preparar rollback de funciones y columnas nuevas.

## Rollback conceptual

- Restaurar las definiciones anteriores de `get_contacts_v2` y `save_gestion_v2`.
- Restaurar las funciones de sincronización/reconstrucción anteriores.
- Mantener temporalmente `created_by`, `last_managed_by` y `contact_operational_state` para no perder información hasta confirmar el rollback.

La eliminación de columnas o de la tabla no forma parte del rollback inmediato y requeriría confirmación explícita.