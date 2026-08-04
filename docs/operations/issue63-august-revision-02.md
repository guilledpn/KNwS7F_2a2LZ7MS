# Carga controlada de agosto 2026 · revisión 02

- Estado: candidato en auditoría; PROD no ejecutado
- Issue: #63
- Rama: `ops/issue63-carga-202608-revision-02`
- Base auditada inicialmente: `main@969a40ba2c438455c34e3954870c4747fdc13bd4`
- Período: `2026-08`

## Propósito

Reconciliar en APP LLAMADOS Legacy las fuentes corporativas:

- `202608_TOTAL_02_NM.xlsx`;
- `202608_ASIGNADO_02_NM.xlsx`.

Los XLSX contienen PII y permanecen exclusivamente en Drive y en el computador que ejecute la operación. GitHub conserva código, hashes, conteos agregados y trazabilidad.

| Archivo | Filas | RUT distintos | SHA-256 XLSX | SHA-256 payload |
|---|---:|---:|---|---|
| `202608_TOTAL_02_NM.xlsx` | 84.912 | 84.912 | `116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd` | `81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef` |
| `202608_ASIGNADO_02_NM.xlsx` | 198 | 198 | `43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019` | `201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76` |

## Preflight del candidato

`TOTAL_01 → TOTAL_02`:

- 28.186 pares Persona/campaña conservados;
- 56.726 agregados;
- 0 retirados;
- 2.260 transiciones `No Gestionado → Gestionado`;
- cinco campañas segmentadas.

`ASIGNADO_01 → ASIGNADO_02`:

- 145 asignaciones agregadas;
- 53 conservadas;
- 1 retirada;
- 198 asignados finales exactos.

Estado PROD de referencia, obtenido sólo por lectura:

- período activo `2026-08`;
- 28.186 Apariciones visibles y totales;
- 54 asignados;
- 4 campañas;
- staging público 0;
- runs 17 y 18 en `done` para TOTAL 01 y ASIGNADO 01;
- contención Issue #43: evento 7960, snapshot `ISSUE43-PROD-2026-08-V1`, 286 Personas ocultas;
- 0 referencias de agosto desde `crm_analysis_sample_items` hacia `work_queue`.

Cualquier divergencia aborta la aplicación antes de modificar datos canónicos.

## Diseño

### Infraestructura temporal

Las seis migraciones `20260804214500` a `20260804214550` crean:

- esquema no expuesto `issue63_ops`;
- staging y snapshots con RLS, sin acceso directo de roles cliente;
- RPC pública `crm_issue63_stage_chunk`, limitada a staging;
- RPC pública `crm_issue63_status`, sólo con conteos agregados;
- funciones administrativas internas para configurar, aplicar, validar y revertir.

Las RPC públicas verifican rol `anon`, token SHA-256, expiración, período, nombres, hashes y rangos. `PUBLIC` y `authenticated` no poseen `EXECUTE`. Instalar las migraciones no configura una operación ni modifica datos canónicos.

### Staging reanudable

`tools/issue63_stage_revision_02.py` valida localmente los XLSX y carga lotes al staging interno. No puede llamar a `apply_operation`, rollback ni cleanup. Los módulos auxiliares contienen el contrato, la normalización y el cliente RPC.

### Aplicación atómica

`issue63_ops.apply_operation()`:

1. valida staging y estado previo exactos;
2. bloquea tablas canónicas, historia y referencias externas relevantes;
3. captura snapshots de rollback y la secuencia de runs;
4. actualiza Personas y cinco campañas;
5. reemplaza exactamente Apariciones, estados y asignaciones, incluida la retirada;
6. reemplaza `monthly_source_order` con el orden TOTAL;
7. reconstruye la cola sin usar `rebuild_work_queue_for_period`;
8. conserva `work_item_id`, estados internos, comentarios, recordatorios, ingreso y `created_at` existentes;
9. mantiene ocultas las 286 Personas del Issue #43, salvo que ahora estén asignadas;
10. registra runs, progreso y guardrail;
11. valida conjuntos exactos antes de confirmar.

### Rollback

El rollback:

- se ejecuta sólo mientras la PWA continúa cerrada;
- bloquea las mismas superficies antes de comprobar escrituras posteriores;
- restaura por snapshots, incluidos IDs, timestamps, `search_text`, `telefono_activo_idx`, runs, progreso y secuencia;
- elimina sólo Personas creadas por esta operación y sin referencias externas;
- compara el estado restaurado contra los snapshots antes de confirmar;
- conserva intencionalmente los eventos de guardrail como auditoría de la operación y del rollback.

Por ello, “rollback exacto” significa identidad exacta de las tablas operativas afectadas y de su secuencia; el historial de auditoría es deliberadamente aditivo.

## Secuencia posterior a auditoría y nueva autorización PROD

La PWA puede permanecer operativa durante validación, instalación y staging. Debe cerrarse antes del preflight final y mantenerse cerrada, sin excepción, hasta decidir aceptación o rollback y terminar el cleanup.

### 1. Validar archivos localmente

```powershell
python tools/issue63_stage_revision_02.py validate `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --report "C:\ruta-segura\issue63_validation.json"
```

Esperado: hashes y conteos exactos; `network_used=false`; `prod_modified=false`.

### 2. Instalar las seis migraciones exactas

Aplicar administrativamente y byte por byte las seis migraciones del PR, en orden. No ejecutar todavía configuración ni aplicación.

### 3. Confirmar que la instalación no cambió estado canónico

Repetir conteos y fingerprints de Personas, Apariciones, campañas, orden, cola, historia, runs, progreso y staging. Comprobar RLS, permisos, exposición Data API y ausencia de DML de roles cliente.

### 4. Crear token y runtime local

```powershell
python tools/issue63_stage_revision_02.py prepare-runtime `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --output-dir "C:\ruta-segura\issue63-runtime" `
  --expires-hours 24
```

Genera un token temporal, SQL con sólo su hash y un manifiesto agregado. Ninguno se incorpora a Git.

### 5. Configurar administrativamente

Ejecutar `issue63_configure_runtime.sql`. Confirmar operación única, período, expiración y manifiesto hash-locked.

### 6. Cargar sólo a staging

```powershell
$env:ISSUE63_SUPABASE_URL = "https://<proyecto>.supabase.co"
$env:ISSUE63_ANON_KEY = "<publishable-or-legacy-anon-key>"

python tools/issue63_stage_revision_02.py stage `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --token-file "C:\ruta-segura\issue63-runtime\.issue63_token" `
  --report "C:\ruta-segura\issue63_stage_report.json"
```

Durante esta fase sólo cambia `issue63_ops`; la carga es reanudable.

### 7. Validar staging

Ejecutar `crm_issue63_status` mediante la CLI y confirmar `stage_complete=true`, `stage_valid=true`, hashes, conteos y relación ASIGNADO ⊂ TOTAL.

### 8. Cerrar la PWA

Cerrar completamente la PWA en computador y teléfono. No reabrirla hasta terminar el paso 14.

### 9. Repetir preflight PROD

Repetir todas las consultas independientes de sólo lectura. Deben coincidir con el contrato, incluida la contención #43, staging público 0 y referencias externas 0. Una divergencia produce NO-GO.

### 10. Ejecutar aplicación atómica

```sql
select issue63_ops.apply_operation();
```

### 11. Validar mediante consultas independientes

No basta `validate_applied()`. Comparar de forma independiente:

- 84.912 Apariciones visibles y totales;
- 198 asignados exactos, con delta 145/53/1;
- 5 campañas y conteos por campaña/estado;
- 84.912 órdenes TOTAL, sin discrepancias;
- orden ASIGNADO independiente;
- membresía de cola según política canónica y contención #43;
- 0 duplicados, CMS inexistentes o pérdida de `work_item_id` y contexto;
- fingerprints de `crm_log` y `crm_events` sin cambios.

### 12. Realizar smoke test autenticado

Probar primera página, asignados, filtros de campaña/mes/origen, ficha no destructiva, Stats e Importar en escritorio y teléfono, sin generar una gestión.

### 13. Decidir rollback o aceptación

La PWA continúa cerrada. Ante cualquier falla:

```sql
select issue63_ops.rollback_operation();
```

Confirmar el resultado de `validate_rollback()` y los fingerprints previos. Sólo si toda validación y smoke test pasan se acepta la carga.

### 14. Ejecutar cleanup

Aplicar `supabase/operations/issue63_cleanup.sql`. Confirmar ausencia de `issue63_ops` y `crm_issue63_*`. Recién entonces puede reanudarse la operación normal.

### 15. Versionar el retiro realmente aplicado

Agregar la migración de retiro con el SQL exacto ejecutado en PROD. No fusionar antes de que GitHub reproduzca el backend final.

### 16. Actualizar Issue y PR

Registrar commit, comandos, resultados, tiempos, fingerprints, smoke test, decisión de aceptación o rollback, cleanup y riesgo residual, sin PII.

### 17. Fusionar sólo después del cierre completo

Mantener el PR en borrador hasta terminar la operación. Fusionar únicamente cuando PROD esté validado, el cleanup esté versionado y la autorización utilizada quede cerrada.

## Limitaciones

- No resuelve la causa estructural del Issue #43; preserva su contención.
- No existe STAGING independiente; los XLSX reales nunca se prueban en DEV.
- Los eventos de guardrail son trazabilidad intencional y no se eliminan en rollback.
- No cambia frontend, Arquitectura, Modelo del Dominio ni Roadmap; no corresponde ADR ni LCD.
- PROD permanece intacto mientras este documento esté en estado candidato para auditoría.