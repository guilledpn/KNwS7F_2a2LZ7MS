# Promoción a PROD · Métricas operativas diarias

**LCD:** LCD-20260713-01  
**Fecha:** 2026-07-13  
**Ambiente:** PROD  
**Supabase:** `crm-ffvv-v2` (`lijibbhpyyptodneafdd`)  
**Estado:** promovido y validado técnicamente.

## Alcance

Se corrigió la interpretación de las métricas operativas para que los guardados automáticos y las repeticiones de estado no se contabilicen como llamadas o agendamientos independientes.

Reglas promovidas:

- Contacto Trabajado: una Persona con al menos un cambio significativo de estado en la fecha; máximo una vez por día.
- Llamada Efectiva: resultado diario final `Agenda` o `No agenda`.
- Agendamiento: resultado diario final `Agenda`.
- Conversión Efectiva: Agendamientos / Llamadas Efectivas.
- Contactos Trabajados por Agendamiento: Contactos Trabajados / Agendamientos.

## Implementación

### Base de datos

Migración aplicada: `prod_daily_management_metrics`.

Archivo versionado:

- `supabase/migrations/20260713222000_prod_daily_management_metrics.sql`

Objetos agregados:

- `crm_management_state_key(text)`
- `crm_contact_day_outcomes_v1`
- `get_management_metrics_v1(integer)`
- `get_daily_management_report_v1(date)`

`get_stats_v1` se preservó sin reemplazo para mantener continuidad del cockpit, calendario, metas, ajustes manuales y analítica histórica existente.

No se modificaron ni eliminaron registros de `crm_log`, `crm_events`, contactos, campañas o ajustes mensuales.

### Interfaz

- `assets/app/features/stats-metrics-patch-prod.js`
- `sw.js`, versión `App_llamados_v1.05-lcd-20260713-01-stats`

La pantalla muestra:

- Trabajados hoy
- Llamadas efectivas
- Agendamientos hoy
- Conversión efectiva
- Trabajados / agenda

El informe diario y el chip de meta consumen el mismo resultado diario derivado.

## Pruebas y controles

Aprobados:

- ejecución de `get_management_metrics_v1`;
- ejecución de `get_daily_management_report_v1`;
- continuidad de `get_stats_v1`;
- coherencia entre métricas e informe diario;
- denegación de las RPC nuevas al rol `anon`;
- acceso de las RPC nuevas para `authenticated`;
- helper y vista interna sin exposición directa al cliente;
- validación sintáctica JavaScript;
- simulación de ejecución del parche de interfaz;
- invalidación de caché y activación del nuevo service worker.

Foto del último chequeo técnico, mientras la operación continuaba:

- 78 Contactos Trabajados;
- 19 Llamadas Efectivas;
- 7 Agendamientos;
- 12 No agenda;
- 36,8 % de Conversión Efectiva;
- 11,14 Contactos Trabajados por Agendamiento.

El mes contenía 8 Agendamientos derivados y un ajuste inicial conservado de 6, totalizando 14 al momento del chequeo.

Los valores son dinámicos y pueden aumentar con gestiones posteriores.

## Seguridad

Las nuevas RPC no son ejecutables por `anon`. El rol `authenticated` puede ejecutar únicamente los contratos públicos requeridos. La vista derivada y el helper no se exponen directamente al cliente.

El asesor de Supabase mantiene advertencias preexistentes sobre permisos amplios, funciones antiguas `SECURITY DEFINER`, políticas RLS y algunos índices. No se detectó una alerta nueva que bloquee este cambio; su revisión permanece como auditoría transversal separada.

## Rollback

Script versionado:

- `supabase/rollback/20260713_prod_daily_management_metrics.sql`

El rollback elimina exclusivamente los objetos nuevos de métricas. No modifica hechos históricos.

## Limitación de validación

La sesión autenticada de la PWA instalada debe abrirse o recargarse para recibir el nuevo service worker. Las pruebas de base, permisos, repositorio, sintaxis y ejecución simulada quedaron aprobadas; la inspección visual final depende de la sesión instalada del usuario.
