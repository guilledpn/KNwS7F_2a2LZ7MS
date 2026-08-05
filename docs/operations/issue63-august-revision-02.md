# Carga controlada de agosto 2026 · revisión 02

- Estado: candidato reducido listo para auditoría independiente; PROD no ejecutado
- Clasificación: operación excepcional planificada
- Issue: #63
- Base original de preparación: `main@d5da04503f73cf6a82397e53fcc018de8dcdfc1f`
- Base efectiva de republicación: `main@5eb21b19268d99fb27122f2a91968897cb61ebd3`
- Período: `2026-08`

## Propósito

Reconciliar en APP LLAMADOS Legacy las fuentes corporativas `202608_TOTAL_02_NM.xlsx` y `202608_ASIGNADO_02_NM.xlsx` sin usar el importador acumulativo ni `rebuild_work_queue_for_period`.

Los XLSX y la PII permanecen exclusivamente en Drive y en el computador de ejecución. GitHub conserva código, hashes, conteos agregados y procedimiento.

## Fuentes auditadas

| Archivo | Filas/RUT | SHA-256 XLSX | SHA-256 payload |
|---|---:|---|---|
| `202608_TOTAL_02_NM.xlsx` | 84.912 | `116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd` | `81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef` |
| `202608_ASIGNADO_02_NM.xlsx` | 198 | `43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019` | `201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76` |

Delta esperado: 56.726 altas TOTAL, 0 bajas TOTAL, 2.260 transiciones a `Gestionado`, 145 altas ASIGNADO, 53 conservadas y una baja.

## Diseño mínimo

Los siete archivos `supabase/operations/issue63_setup_01_schema.sql` a
`issue63_setup_07_rollback.sql`, aplicados en orden, crean temporalmente:

- esquema privado `issue63_ops`;
- staging hash-locked;
- snapshots contractuales;
- RPC de staging y estado para `anon` con token temporal;
- funciones administrativas no expuestas para aplicación y rollback.

La aplicación es atómica, reemplaza el conjunto exacto de asignaciones y orden TOTAL, reconstruye la cola desde la política canónica y preserva las 286 exclusiones del Issue #43 salvo asignación vigente.

El rollback restaura hechos e identidad operativa. No pretende reproducir gaps de secuencia, eventos de auditoría, `contacts.updated_at` ni `contacts.search_text`; estos últimos se regeneran mediante triggers canónicos. No deshabilita triggers ni utiliza `session_replication_role`.


## Evidencia de preparación

Validaciones ejecutadas sobre el checkout completo de `main@d5da04503f73cf6a82397e53fcc018de8dcdfc1f`:

El candidato fue recuperado y republicado sobre `main@5eb21b19268d99fb27122f2a91968897cb61ebd3`. Los cuatro commits intermedios modifican exclusivamente rutas `dev/`, `src/dev/`, una migración y pruebas de Stats sin solaparse con los 13 archivos de esta operación. La republicación conserva el candidato como un único commit lógico.

- ZIP del checkout: SHA-256 `573d375cfb8b7045ecf2599d2df2f2a3fa07550e9c725e01de40c353630e65ab`;
- `python tools/run_legacy_safety_checks.py`: PASS, 75 pruebas de caracterización;
- shell PROD de sólo lectura, build DEV y aislamiento DEV/PROD: PASS;
- `py_compile` de las tres herramientas: PASS;
- validación de ambos XLSX reales y de su relación: PASS;
- siete archivos setup SQL compilados en DEV, en orden: PASS;
- 10/10 tablas temporales con RLS, sin DML cliente y esquema sin `USAGE`: PASS;
- sólo `crm_issue63_stage_chunk` y `crm_issue63_status` ejecutables por `anon`: PASS;
- configuración hash-locked, token, staging parcial y reintento idempotente: PASS;
- prueba sintética transaccional `apply → validate → rollback`: PASS;
- cinco campañas, cambio de estado, alta/baja de asignación, contención y orden: PASS;
- creación y eliminación por rollback de Personas nuevas sin referencias: PASS;
- cleanup DEV: PASS; sin esquema, RPC, datos sintéticos ni residuos.

La prueba detectó que DEV no posee la restricción única de PROD en `crm_import_runs(file_name, load_type, period)`. El candidato no depende de esa restricción: concilia los runs mediante borrado acotado e inserción, cubierto por snapshot y rollback.

PROD sólo fue consultado en modo lectura. No se instalaron objetos, no se cargó staging y no se ejecutó ninguna aplicación productiva.

## Secuencia autorizable

1. Ejecutar validación local de los XLSX.
2. Aplicar administrativamente, en orden:
   - `issue63_setup_01_schema.sql`;
   - `issue63_setup_02_staging.sql`;
   - `issue63_setup_03_applied_validation.sql`;
   - `issue63_setup_04_apply_preflight.sql`;
   - `issue63_setup_05_apply_mutation.sql`;
   - `issue63_setup_06_rollback_validation.sql`;
   - `issue63_setup_07_rollback.sql`.
3. Confirmar que sólo existen objetos temporales y permisos previstos.
4. Generar runtime y token local.
5. Ejecutar el SQL de configuración generado.
6. Cargar TOTAL y ASIGNADO sólo a staging.
7. Confirmar `stage_complete=true` y `stage_valid=true`.
8. Cerrar la PWA en computador y teléfono.
9. Repetir preflight PROD; cualquier divergencia produce NO-GO.
10. Ejecutar `select issue63_ops.apply_operation();`.
11. Validar mediante consultas independientes y smoke test autenticado no destructivo.
12. Ante cualquier falla, ejecutar `select issue63_ops.rollback_operation();` sin reabrir la PWA.
13. Tras aceptación o rollback, ejecutar `issue63_cleanup.sql`.
14. Confirmar ausencia de `issue63_ops` y `crm_issue63_*`.
15. Registrar evidencia en Issue #63 y fusionar sólo después del cierre completo.

## Comandos locales

```powershell
python tools/issue63_stage_revision_02.py validate `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --report "C:\ruta-segura\issue63_validation.json"
```

```powershell
python tools/issue63_stage_revision_02.py prepare-runtime `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --output-dir "C:\ruta-segura\issue63-runtime" `
  --expires-hours 24
```

```powershell
$env:ISSUE63_SUPABASE_URL = "https://<proyecto>.supabase.co"
$env:ISSUE63_ANON_KEY = "<publishable-or-legacy-anon-key>"
python tools/issue63_stage_revision_02.py stage `
  --total "C:\ruta\202608_TOTAL_02_NM.xlsx" `
  --assigned "C:\ruta\202608_ASIGNADO_02_NM.xlsx" `
  --token-file "C:\ruta-segura\issue63-runtime\.issue63_token" `
  --report "C:\ruta-segura\issue63_stage_report.json"
```

## Alcance excluido

- no cambia frontend, PWA, contratos generales ni Modelo del Dominio;
- no corrige estructuralmente el importador;
- no resuelve el Issue #43;
- no usa `service_role`, JWT secret ni claves privadas;
- no autoriza escrituras PROD por sí mismo;
- no corresponde ADR ni LCD.
