# Validación DEV · política canónica de gestionabilidad

- Fecha: 2026-07-15
- Estado: Pendiente de revisión
- LCD: LCD-20260715-01
- ADR: ADR-020
- Issue: #12
- Proyecto Supabase: `crm-ffvv-dev`
- Rama: `fix/lcd-20260715-01-unify-eligibility-policy`

## Restricciones observadas

- no se consultó ni modificó PROD;
- no se utilizaron secretos privados;
- no se ejecutó backfill con datos reales;
- los fixtures fueron ficticios y se revirtieron;
- la migración no reconstruyó la cola automáticamente.

## Estado previo de DEV

```json
{
  "contacts": 164,
  "contact_month_state": 443,
  "work_queue": 116,
  "crm_log": 13,
  "crm_events": 6,
  "contact_operational_state": 8,
  "active_period": "2026-07",
  "visible_queue_active": 14
}
```

Calidad de estado mensual:

```json
{
  "valid_status_rows": 4,
  "missing_or_invalid_status_rows": 439
}
```

## Migración

Migración aplicada en DEV:

```text
20260715054526 · unify_contact_eligibility_policy
```

La migración:

- conservó las cinco RPC previas con sufijo legacy;
- revocó acceso API a las copias legacy;
- conservó las firmas públicas existentes;
- creó un helper interno no ejecutable por `anon` ni `authenticated`;
- no modificó filas al aplicarse.

## Prueba transaccional de política

Resultado:

```json
{
  "status": "PASS",
  "validation": "canonical_eligibility_transactional_fixtures",
  "fixtures_rolled_back": true,
  "prod_accessed": false
}
```

Casos aprobados:

- asignado vigente;
- vigente no asignado aunque figure `No Gestionado`;
- histórico con última aparición `No Gestionado`;
- histórico con última aparición `Gestionado`;
- aparición más reciente sin estado válido;
- contacto nunca observado;
- conflicto en el último período con precedencia conservadora `Gestionado`;
- preservación de estado, ingreso, comentarios y recordatorio durante rebuild;
- ocultamiento por sincronización de lote;
- coherencia de `get_contacts_v2`.

No quedaron residuos de fixtures en contactos, campañas, staging, apariciones ni cola.

## Prueba transaccional de carga asignada

Resultado:

```json
{
  "status": "PASS",
  "validation": "assigned_import_transactional_fixture",
  "assignment_persisted": true,
  "corporate_status_preserved": true,
  "operational_state_mutations": 0,
  "fixtures_rolled_back": true,
  "prod_accessed": false
}
```

## Comparación de la proyección real

Antes del rebuild canónico:

```json
{
  "canonical_manageable": 14,
  "canonical_assigned": 13,
  "visible_queue": 14,
  "visible_queue_not_canonical": 0,
  "canonical_missing_from_visible_queue": 0
}
```

Distribución:

```json
{
  "assigned_current": 13,
  "active_unassigned": 100,
  "latest_no_gestionado": 1,
  "latest_gestionado": 1,
  "latest_status_missing": 49
}
```

La proyección existente ya coincidía con la política para los datos ficticios actuales.

## Rebuild real de DEV

Resultado:

```json
{
  "ok": true,
  "rule": "canonical_monthly_eligibility_v1",
  "period": "2026-07",
  "visible_total_rows": 14,
  "visible_assigned_rows": 13,
  "visible_rule_rows": 1,
  "valid_status_rows": 4,
  "missing_or_invalid_status_rows": 439,
  "missing_status_behavior": "fail_closed"
}
```

Hash de hechos de usuario en `work_queue` antes y después:

```text
bab5ab249ee465c40f284486fcacde7a
```

El hash incluye estado de gestión, ingreso, comentarios, recordatorio y fecha de creación. Permaneció idéntico.

## Consulta pública después del rebuild

```json
{
  "api_ok": true,
  "api_source": "get_contacts_v2_canonical_monthly_eligibility",
  "api_rule": "canonical_monthly_eligibility_v1",
  "api_base_total": 14,
  "api_result_total": 14,
  "api_rows": 14,
  "active_unassigned_leaks": 0
}
```

Recuentos de hechos después de la validación:

```json
{
  "contacts": 164,
  "contact_month_state": 443,
  "work_queue": 116,
  "crm_log": 13,
  "crm_events": 6,
  "contact_operational_state": 8
}
```

## Asesores Supabase

No apareció un hallazgo nuevo que bloquee este cambio.

Hallazgos relacionados:

- las RPC públicas son `SECURITY DEFINER` ejecutables por usuarios autenticados; esto es intencional en la arquitectura legacy actual;
- el helper interno no quedó expuesto;
- `norm_campaign_key` conserva un `search_path` mutable preexistente;
- existen índices/FK con oportunidades de optimización preexistentes.

Referencias de remediación:

- https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable
- https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys

## Resultado actual

```text
Migración DEV                     PASS
Permisos y firmas                PASS
Fixtures política                PASS
Fixture carga asignada           PASS
Rebuild DEV                      PASS
Preservación hechos del usuario  PASS
Backfill real                    NO EJECUTADO
PROD                             NO ACCEDIDO
Suite local del repositorio      PENDIENTE
Smoke test visual DEV            PENDIENTE
```

No corresponde promover a STAGING ni PROD hasta completar la suite local, el smoke test DEV, la revisión del PR y la validación de las fuentes reales.
