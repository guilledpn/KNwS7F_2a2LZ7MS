# Métricas operativas diarias en DEV

LCD: `LCD-20260713-01`  
Fecha: 2026-07-13  
Ambiente: DEV  
Supabase: `crm-ffvv-dev` (`xcujixexjbuqqzlbomgw`)  
PROD: **no modificado**.

## Contrato funcional

Las estadísticas se derivan por Persona y fecha local (`America/Santiago`):

- **Contacto trabajado:** Persona con al menos un cambio significativo de estado; cuenta una vez por día.
- **Resultado diario de gestión:** último cambio significativo de estado de la Persona en el día.
- **Llamada efectiva:** resultado final `Agenda` o `No agenda`.
- **Agendamiento:** resultado final `Agenda`.
- **Conversión efectiva:** Agendamientos / Llamadas efectivas.
- **Trabajados por agenda:** Contactos trabajados / Agendamientos.

Un cambio es significativo cuando el estado nuevo normalizado difiere del estado anterior normalizado. Los autoguardados, repeticiones del mismo estado y modificaciones de comentarios o ingreso sin transición de estado no crean un nuevo trabajado.

## Implementación en base DEV

Migraciones:

- `20260713211651_derive_daily_management_outcomes.sql`
- `20260713212253_harden_daily_management_metric_helper.sql`

Objetos principales:

- `crm_management_state_key(text)`: normalización interna de estados.
- `crm_contact_day_outcomes_v1`: resultado final derivado por Persona y día.
- `get_daily_management_report_v1(date)`: informe diario unificado.
- `get_stats_v1(integer, integer)`: estadísticas corregidas con compatibilidad temporal de campos legacy.

El cliente autenticado puede ejecutar solo las RPC públicas de lectura. La vista derivada y el helper interno no están expuestos directamente a `anon` ni `authenticated`.

## Implementación en interfaz DEV

- `dev/assets/app/features/stats-metrics-patch.js`
- `dev/assets/app/app.js`
- `dev/sw.js`

Las tarjetas muestran:

- Trabajados hoy.
- Llamadas efectivas.
- Agendamientos hoy.
- Conversión efectiva.
- Trabajados / agenda.

El informe diario y el chip de meta consumen la misma fuente derivada. El service worker publica un nuevo identificador de caché para evitar que DEV conserve la versión anterior.

## Validación automatizada

Casos probados dentro de una transacción revertida:

1. `Agenda → Agenda` por autoguardado: 1 trabajado, 1 efectiva, 1 agenda.
2. `No contactado → Pendiente → No contactado`: 1 trabajado, resultado final No contactado, 0 efectivas.
3. `Agenda → No agenda`: 1 trabajado, 1 efectiva, 0 agendas.
4. Guardado solo de comentario sin transición: excluido.
5. Repetición del mismo estado sin transición: excluida.

Resultado esperado y obtenido:

- 3 trabajados.
- 2 llamadas efectivas.
- 1 agendamiento.
- 1 No agenda.
- 1 No contactado.
- 0 filas de prueba residuales después del rollback.

También aprobaron:

- sintaxis JavaScript del parche, cargador y service worker;
- prueba de ejecución del parche con RPC simuladas y verificación de etiquetas, valores, informe y chip de meta;
- permisos: `anon` sin acceso; `authenticated` con acceso a las RPC; vista y helper no expuestos;
- ejecución de `get_stats_v1(30, null)` en aproximadamente 19 ms sobre la base DEV pequeña.

## Estado

Implementado y validado en DEV. No promover directamente a PROD. El siguiente paso de promoción es preparar STAGING y ejecutar smoke test manual en dispositivo, seguido del protocolo seguro de producción.
