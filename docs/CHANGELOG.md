# APP LLAMADOS · Changelog

Registro humano y tecnico de versiones.

## App_llamados_v1.05-ui-20260803-07 · 2026-08-03

### Tipo

Mejora de navegación productiva aprobada visualmente.

### Cambios

- Contactos conserva su raíz sin flecha.
- Stats e Importar usan retorno contextual con objetivo táctil de 44 px.
- El regreso restaura contacto exacto y posición de scroll cuando corresponde.
- La barra derecha conserva el orden `Sprint → Hoy → Ajustes`.
- Ajustes preserva el contexto del contacto.

### Evidencia

Issue #39, parche `assets/app/features/stats-navigation-patch-prod.js`, service worker y safety checks.

## Operación julio/agosto · 2026-08-03

- La carga controlada de julio/agosto fue completada y conciliada (Issue #36).
- La campaña inválida de junio fue retirada de la cola actual sin borrar sus Apariciones históricas (Issue #37).
- La solución persistente para excluir campañas inválidas permanece abierta en Issue #38.
- Se corrigió la separación entre edición de ficha y eventos reales de gestión, incluida limpieza controlada de datos ficticios (Issues #26 y #27).

## App_llamados_v1.05 · 2026-07-09

### Tipo

Recovery productivo aprobado.

### Motivo

Restaurar una version funcional despues del incidente causado por la integracion incorrecta de Cockpit/Stats y por la perdida de fuente canonica entre GitHub, Supabase Storage y cache local.

### Cambios principales

- Se publico una app canonica en `index.html`.
- Se uso como referencia visual la linea v62/recovery aprobada.
- Se mantuvo Graphite como base visual.
- Se conecto a Supabase nuevo `lijibbhpyyptodneafdd`.
- Se mantuvo Contactos, Detalle, Stats, Importar, Ajustes y Sprint.
- Ajustes muestra version visible.
- Service worker simplificado para evitar cache vieja.

### Observaciones

- La app sigue siendo un HTML grande y monolitico.
- El siguiente paso tecnico recomendado es migrar a Vite + React en una rama separada.
- No se debe seguir aumentando el HTML monolitico salvo parches urgentes.

### Rollback conocido

- Branch de respaldo previo: `backup-main-before-App_llamados_v1_05-20260709`.
- Version aprobada local usada: `recovery_crm_20260709_V3(1).html`.

## Incidente previo

### Sintoma

Produccion mostro UI incompleta o equivocada y en algunos momentos no cargo Contactos correctamente.

### Causa general

La version real de la app estaba distribuida entre GitHub, dependencias externas, Storage antiguo y cache. GitHub no contenia siempre una fuente completa y autosuficiente.

### Leccion

Cada release debe vivir completo en GitHub y debe poder restaurarse sin depender del navegador ni de Storage externo.
