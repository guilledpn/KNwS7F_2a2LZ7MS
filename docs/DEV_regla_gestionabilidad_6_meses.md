# DEV · Regla de gestionabilidad de 6 meses

Fecha de implementación en DEV: 2026-07-10  
Supabase: `crm-ffvv-dev` (`xcujixexjbuqqzlbomgw`)  
PROD: **no modificado**.

## Regla funcional

Un contacto es gestionable cuando cumple al menos una de estas condiciones:

1. Está asignado en el período activo.
2. No registra una gestión sustantiva durante los últimos 6 meses calendario.

La asignación vigente tiene prioridad sobre la ventana de 6 meses.

`Pendiente` no cuenta como gestión sustantiva. Sí cuentan `Agenda`, `No agenda`, `Volver a llamar`, `No contactado`, `Contacto Inválido` y `Gestionado`.

La aparición en una campaña no determina por sí sola la gestionabilidad. El contacto vuelve a ser elegible en `última_gestión + 6 meses calendario`, incluyendo esa fecha.

## Implementación aplicada en DEV

- Tabla persistente nueva: `public.contact_operational_state`.
- Trigger en `public.crm_log`: `trg_sync_contact_operational_state_from_log`.
- Función de sincronización: `sync_contact_operational_state_from_log()`.
- Función administrativa de reconstrucción: `rebuild_contact_operational_state()`; no ejecutable desde el cliente autenticado.
- RPC de lectura reemplazada, conservando firma: `get_contacts_v2(...)`.
- RPC de página completa actualizada: `get_contacts_v2_all_page(...)`.
- Importador de asignados actualizado: `process_assigned_load(uuid)` registra el estado operativo importado sin fabricar eventos para Stats.
- RLS habilitado en `contact_operational_state`; acceso solo para usuarios autenticados.
- Índices agregados para elegibilidad y última gestión.

`work_queue` deja de ser la fuente de verdad de la gestionabilidad. Continúa siendo una cola activa/reconstruible; `contacts` conserva la identidad canónica y `contact_operational_state` conserva el estado operativo.

## Casos verificados en DEV

- Sin gestión conocida: disponible por regla.
- Gestión `Pendiente`: sigue disponible por regla.
- Gestión sustantiva reciente y no asignado: no gestionable.
- Gestión sustantiva de más de 6 meses y no asignado: disponible por regla.
- Gestión sustantiva reciente y asignado: sigue gestionable por asignación.
- Búsqueda por RUT de un contacto histórico fuera de `work_queue`: funciona.
- Filtros `Gestionables`, `No gestionables`, `Todos`, `Pendientes`, `Asignados` y meses: responden correctamente.

Datos de prueba sanitizados usados:

- `10000014-3`: sin gestión sustantiva / solo Pendiente.
- `10000013-2`: gestión reciente no asignada.
- `10000017-6`: gestión antigua, nuevamente elegible.
- `10000001-1`: gestión reciente, pero asignado.

La consulta principal fue medida en la base DEV pequeña con aproximadamente 20 ms de ejecución. Debe volver a medirse con volumen comparable a PROD antes de promoción.

## Bloqueador antes de STAGING/PROD

PROD nuevo no contiene el historial operativo completo de la base anterior. Con la regla correcta, un contacto sin antecedente de gestión se considera gestionable. Por ello, antes de promover se debe definir y cargar una línea base confiable de la **última gestión conocida por contacto**, o aceptar explícitamente que todo antecedente desconocido quede disponible.

No ejecutar esta promoción directamente en PROD sin:

1. migración o línea base de última gestión;
2. prueba de rendimiento con el volumen real;
3. smoke test completo en STAGING;
4. plan de rollback de funciones y tabla operativa.

## Rollback conceptual

- Restaurar las definiciones anteriores de `get_contacts_v2`, `get_contacts_v2_all_page` y `process_assigned_load`.
- Deshabilitar/eliminar el trigger de `crm_log`.
- Mantener temporalmente `contact_operational_state` para no perder información hasta confirmar el rollback.

La eliminación de la tabla no forma parte del rollback inmediato y requeriría confirmación explícita.