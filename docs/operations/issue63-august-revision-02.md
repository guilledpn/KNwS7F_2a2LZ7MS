# Carga controlada de agosto 2026 · revisión 02

- Estado: candidato listo para auditoría; PROD no ejecutado
- Issue: #63
- Rama: `ops/issue63-carga-202608-revision-02`
- Base: `main@969a40ba2c438455c34e3954870c4747fdc13bd4`
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
- contención Issue #43: evento 7960, snapshot `ISSUE43-PROD-2026-08-V1`, 286 Personas ocultas.

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
2. bloquea las tablas afectadas;
3. captura snapshots de rollback;
4. actualiza Personas y cinco campañas;
5. reemplaza exactamente Apariciones, estados y asignaciones, incluida la retirada;
6. reemplaza `monthly_source_order` con el orden TOTAL;
7. reconstruye la cola sin usar `rebuild_work_queue_for_period`;
8. conserva estados internos, comentarios, recordatorios, ingreso y `created_at` existentes;
9. mantiene ocultas las 286 Personas del Issue #43, salvo que ahora estén asignadas;
10. registra runs, progreso y guardrail;
11. valida conjuntos exactos antes de confirmar.

## Secuencia posterior a auditoría y autorización

### 1. Validación local

```powershell
python tools/issue63_stage_revision_02.py validate `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --report "C:\ruta-segura\issue63_validation.json"
```

Esperado: hashes y conteos exactos; `network_used=false`; `prod_modified=false`.

### 2. Instalar setup en PROD

Aplicar administrativamente las seis migraciones sólo tras aprobación. Verificar que las tablas canónicas no cambian, que `anon` sólo ejecuta staging/status y que no existe acceso directo a `issue63_ops`.

### 3. Preparar runtime local

```powershell
python tools/issue63_stage_revision_02.py prepare-runtime `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --output-dir "C:\ruta-segura\issue63-runtime" `
  --expires-hours 24
```

Genera un token temporal, SQL con sólo su hash y un manifiesto agregado. Ninguno se incorpora a Git.

### 4. Configurar y cargar sólo a staging

Ejecutar administrativamente `issue63_configure_runtime.sql`. Luego:

```powershell
$env:ISSUE63_SUPABASE_URL = "https://<proyecto>.supabase.co"
$env:ISSUE63_ANON_KEY = "<publishable-or-legacy-anon-key>"

python tools/issue63_stage_revision_02.py stage `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --token-file "C:\ruta-segura\issue63-runtime\.issue63_token" `
  --report "C:\ruta-segura\issue63_stage_report.json"
```

Durante esta fase sólo cambia `issue63_ops`; la carga es reanudable y la PWA puede seguir operativa.

### 5. Aplicación

Cerrar la PWA en computador y teléfono, repetir el preflight y ejecutar:

```sql
select issue63_ops.apply_operation();
```

Esperado:

- 84.912 Apariciones visibles y totales;
- 198 asignados exactos;
- 5 campañas;
- 84.912 órdenes TOTAL;
- 0 duplicados, referencias rotas o alteraciones de contexto existente;
- 0 Personas no asignadas de la contención visibles.

### 6. Smoke test

Ejecutar `issue63_ops.validate_applied()`, lecturas de asignados y primera página, filtros de campaña/mes/origen, ficha no destructiva, Stats, Importar, conteos independientes y revisión visual autenticada.

### 7. Rollback o aceptación

Antes de reanudar escrituras, cualquier falla obliga a:

```sql
select issue63_ops.rollback_operation();
```

El rollback usa snapshots y se bloquea si hubo actividad posterior. Tras aceptación, ejecutar `supabase/operations/issue63_cleanup.sql` y versionar la migración de retiro realmente aplicada antes del merge.

## Limitaciones

- No resuelve la causa estructural del Issue #43; preserva su contención.
- El rollback exacto exige mantener la PWA cerrada hasta aceptar o revertir.
- No existe STAGING independiente; los XLSX reales nunca se prueban en DEV.
- No cambia frontend, arquitectura ni Modelo del Dominio; no corresponde ADR ni LCD.
- PROD permanece intacto mientras este documento esté en estado candidato para auditoría.
