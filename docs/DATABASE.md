# APP LLAMADOS · Base de datos

## Supabase productivo

Proyecto operativo:

```txt
https://lijibbhpyyptodneafdd.supabase.co
```

Usar solo anon/publishable key publica disponible en el proyecto. Nunca usar service_role, JWT secret ni claves privadas en cliente.

## Modelo mental simple

La base separa cinco mundos:

1. Datos maestros.
2. Apariciones mensuales.
3. Cola operativa.
4. Gestion y estadisticas.
5. Importacion y control.

## Tablas principales

### contacts

Ficha unica del contacto/persona.

Contiene RUT, nombre, telefonos, email, telefono activo, texto de busqueda y fechas de actualizacion.

Fuente de verdad para datos personales vigentes.

### campaigns

Catalogo de campanas o bases.

Evita repetir nombres y descripciones largas en cada fila de contacto.

### contact_month_state

Registra apariciones de un contacto en un periodo/campana.

Ejemplo: un contacto puede existir una sola vez en `contacts`, pero aparecer en febrero, marzo y julio en `contact_month_state`.

Sirve para historia mensual, filtros por mes y reglas de visibilidad.

### work_queue

Cola operativa de trabajo.

Define que contactos son trabajables en un periodo y guarda el estado operativo actual usado por la app: estado de gestion, comentarios, ingreso estimado y recordatorio.

Observacion importante: conceptualmente esta tabla mezcla cola derivable con estado persistente. Funciona, pero debe tratarse con cuidado. No se debe reconstruir brutalmente sin preservar gestion.

### crm_log

Bitacora de cambios de gestion.

Guarda movimientos como Pendiente -> No contactado -> Volver a llamar -> Agenda.

### crm_events

Eventos enriquecidos para analitica y Stats.

Sirve para responder preguntas como: que hice hoy, cuantas agendas logre, que paso por sprint, a que ritmo cierro el mes.

### staging_contacts

Tabla temporal de entrada para importaciones.

Los archivos grandes primero llegan a staging, luego se normalizan y procesan hacia tablas finales.

### crm_import_runs y crm_import_progress

Control de cargas, estado, cantidad de filas y checkpoint para retomar cargas sin empezar desde cero.

### crm_goals, crm_goal_settings, crm_daily_goals

Metas mensuales, reglas generales y metas especificas por dia.

### crm_holidays

Feriados y dias especiales para ajustar metas.

### crm_stats_adjustments

Ajustes manuales de estadisticas. Por ejemplo, agendas existentes antes de que una metrica quedara automatizada.

## Por que hay mas filas que contactos

Un contacto unico puede aparecer en varios meses.

Ejemplo:

```txt
contacts: 1 fila
contact_month_state: varias apariciones
work_queue: una o mas filas operativas
crm_log: varios cambios
crm_events: varios eventos analiticos
```

Por eso puede haber cerca de 275 mil contactos unicos y mas de 500 mil apariciones historicas.

## Fuente de verdad recomendada

```txt
Datos personales              contacts
Apariciones mensuales         contact_month_state
Campanas                      campaigns
Estado actual de gestion      work_queue actualmente; idealmente tabla futura separada
Historial de gestiones        crm_log
Analitica                     crm_events
Metas                         crm_goals / crm_goal_settings / crm_daily_goals
Importacion temporal          staging_contacts
```

## Mejora estructural recomendada

Crear en el futuro una tabla especifica para estado persistente de gestion, por ejemplo:

```txt
contact_management_state
```

Objetivo: que `work_queue` pueda ser reconstruible sin arriesgar comentarios, estados ni recordatorios.
