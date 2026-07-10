# Pendientes del proyecto APP LLAMADOS

Fecha: 2026-07-09
Estado base: `App_llamados_v1.05`
Producción: `main` · GitHub Pages
Supabase: `lijibbhpyyptodneafdd`

Este documento deja estipulados los pendientes después de la recuperación de Supabase y del intento fallido de preview React. La regla principal sigue siendo: **preservar la app funcional actual y avanzar solo con cambios auditables, mínimos y reversibles**.

---

## 1. Estado actual confirmado

### App productiva

- `App_llamados_v1.05` funciona y debe considerarse la versión estable actual.
- No se debe reemplazar la UI productiva por una preview, maqueta, wrapper o app paralela.
- Producción sigue publicada desde `index.html` en `main`.

### Supabase

- Se redujo el tamaño de la base viva.
- `work_queue` fue reducida a la cola del período activo.
- `staging_contacts` fue compactada y corregida para evitar bloat futuro.
- `get_contacts_v2` fue probado después del rescate y respondió correctamente.
- El dashboard de Supabase mostró `Database itself` cerca de `0.44 GB`, bajo el límite anterior de `0.5 GB`.

### React

- La rama `migration/vite-react-foundation` existe, pero **no está aprobada como migración funcional**.
- La preview visual aproximada fue eliminada porque no respetaba la paridad visual ni funcional con `App_llamados_v1.05`.
- Cualquier nueva migración React debe partir desde paridad 1:1, no desde placeholders.

---

## 2. Pendientes críticos

### 2.1 Monitorear Supabase después del rescate

Pendiente:

- Verificar durante las próximas horas/día que Supabase Billing/Usage refleje la baja real.
- Confirmar que `Database itself` se mantiene bajo el límite operativo.
- Observar WAL y System, que pueden quedar elevados temporalmente después de `DELETE`, `VACUUM FULL` y cambios de índices.

Criterio de éxito:

- Supabase deja de mostrar restricción por exceso de uso.
- La app carga Contactos sin degradación.
- La base se mantiene con margen razonable.

No hacer:

- No ejecutar más limpiezas masivas si la app está funcionando.
- No borrar `contact_month_state` ni `contacts` sin plan de archivo/backup.

---

### 2.2 Validar flujos funcionales básicos de App_llamados_v1.05

Pendiente:

- Contactos: abrir lista.
- Buscar por nombre/RUT/teléfono.
- Abrir detalle.
- Guardar una gestión simple.
- Stats: abrir y revisar que no falle.
- Importar: solo abrir vista, sin hacer carga real por ahora.
- Ajustes: abrir y confirmar versión visible.
- Sprint: confirmar que aparece y corre.

Criterio de éxito:

- La app sigue operativa después del rescate de base.

---

## 3. Pendientes Supabase / base de datos

### 3.1 Rediseñar responsabilidad de `work_queue`

Problema actual:

- `work_queue` había acumulado meses históricos completos.
- Eso la convirtió en una tabla espejo de `contact_month_state`, lo que consumió espacio y volvió más cara la operación.

Pendiente arquitectónico:

Separar claramente:

1. `contact_month_state`: historial de aparición mensual/campaña.
2. Estado operativo persistente: estado de gestión, comentario, recordatorio, teléfono activo, ingresos, etc.
3. `work_queue`: cola visible/reconstruible del período activo.

Opciones futuras:

- Crear una tabla `contact_operational_state` o equivalente.
- Mantener `work_queue` solo como cola activa/reconstruible.
- Evitar que una importación reconstruya todos los meses en `work_queue`.

Regla:

- No eliminar `work_queue` mientras `get_contacts_v2` dependa de ella.
- No mover estado persistente sin migración probada y rollback.

---

### 3.2 Staging e importaciones

Hecho:

- `staging_contacts` fue compactada.
- Se corrigieron funciones de limpieza para usar `TRUNCATE` cuando corresponde.

Pendiente:

- Probar una carga real futura con monitoreo.
- Confirmar que al terminar una carga `staging_contacts` vuelve a tamaño bajo.
- Confirmar que `crm_import_runs` y `crm_import_progress` registran el proceso correctamente.
- Revisar si `crm_import_progress` debería usar `run_id` o `import_session_id` como clave principal futura.

No hacer:

- No reiniciar cargas masivas desde cero si pueden retomarse.
- No usar operaciones masivas no paginadas.

---

### 3.3 Índices

Hecho:

- Se eliminaron índices redundantes/no usados de mayor impacto.

Pendiente:

- Recolectar uso real de índices durante algunos días.
- Revisar si `idx_contacts_search_text_trgm_fast` efectivamente mejora búsqueda con `LIKE '%texto%'`.
- Revisar índices de `contact_month_state` después de más uso real.
- No seguir eliminando índices por tamaño solamente; primero mirar uso y planes.

---

### 3.4 Historial mensual

Pendiente:

- Definir política de retención.
- Decidir cuántos meses deben quedar vivos en `contact_month_state`.
- Si se archivan meses antiguos, hacerlo con exportación verificable antes de borrar.

Criterio sugerido:

- Mantener en Supabase los meses necesarios para operación y estadísticas recientes.
- Archivar histórico frío fuera de la base viva si el límite vuelve a ser problema.

---

## 4. Pendientes React / migración frontend

### 4.1 Congelar la rama React actual como experimento

Estado:

- `migration/vite-react-foundation` compila y tiene CI.
- No es paridad funcional.
- No debe ser mergeada como reemplazo productivo.

Pendiente:

- Marcar explícitamente el PR como experimental/no aprobable si sigue abierto.
- No usar esa preview como base visual aprobada.

---

### 4.2 Reiniciar migración con estrategia correcta

Regla nueva:

- Primero paridad 1:1 con `App_llamados_v1.05`.
- Después modularización.
- Después mejoras.

La migración correcta debe reproducir antes de reemplazar:

- Login.
- Topbar.
- Íconos reales.
- Bottom nav real.
- Contactos reales.
- Detalle funcional.
- Gestión.
- Stats actual.
- Importar completo.
- Ajustes completos.
- Sprint.
- Estética Graphite.
- Comportamiento móvil.

No hacer:

- No construir pantallas placeholder.
- No publicar preview visual si no reproduce la app actual.
- No conectar una app incompleta a Supabase real como si fuera QA funcional.

---

## 5. Pendientes de documentación

Actualizar documentos existentes cuando corresponda:

- `docs/CHANGELOG.md`: registrar rescate de Supabase y eliminación de preview visual.
- `docs/DATABASE.md`: reflejar la regla nueva de `work_queue` activa/reconstruible.
- `docs/RECOVERY.md`: agregar procedimiento de revisión de caché/PWA y rescate Supabase.
- `docs/RELEASE_PROTOCOL.md`: reforzar que preview visual no equivale a release.

---

## 6. Orden recomendado de próximos trabajos

1. No tocar nada más si la app productiva está funcionando.
2. Esperar confirmación del dashboard Supabase/billing.
3. Hacer validación manual corta de flujos básicos.
4. Documentar rescate de Supabase en changelog.
5. Solo después, diseñar migración React 1:1.
6. Antes de una carga real futura, monitorear `staging_contacts`, `work_queue` y tamaño de base.

---

## 7. Regla de oro actualizada

Si la app funciona y Supabase está bajo control, no hacer cambios funcionales por impulso.

Cualquier cambio futuro debe cumplir:

- rama separada;
- cambio mínimo;
- rollback claro;
- validación de sintaxis/build;
- validación móvil/escritorio;
- versión visible si afecta app;
- no tocar producción sin evidencia;
- no reconstruir UI desde memoria.
