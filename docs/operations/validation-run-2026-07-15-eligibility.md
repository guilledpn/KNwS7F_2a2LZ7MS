# Validación DEV · política canónica de gestionabilidad

- Fecha: 2026-07-15
- Estado: Pendiente de revisión
- LCD: LCD-20260715-01
- ADR: ADR-020 y su enmienda
- Issue: #12
- Proyecto Supabase: `crm-ffvv-dev`
- Rama: `fix/lcd-20260715-01-unify-eligibility-policy`

## Restricciones observadas

- no se consultó ni modificó PROD;
- no se utilizaron secretos privados;
- no se ejecutó backfill con datos reales;
- los fixtures fueron ficticios y se revirtieron;
- las migraciones de política no modificaron hechos al aplicarse;
- cada rebuild fue explícito y auditado.

## Estado base de DEV

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

Calidad de estado mensual por fila:

```json
{
  "valid_status_rows": 4,
  "missing_or_invalid_status_rows": 439
}
```

## Migraciones aplicadas en DEV

```text
20260715054526 · unify_contact_eligibility_policy
20260715…       · bound_eligibility_to_evaluation_period
20260715…       · refine_last_valid_status_and_manual_contacts
```

Las migraciones:

- conservaron las cinco RPC previas con sufijo legacy;
- revocaron acceso API a las copias legacy;
- conservaron las firmas públicas existentes;
- crearon un helper interno no ejecutable por `anon` ni `authenticated`;
- limitaron la historia al período evaluado;
- cambiaron la búsqueda desde “última aparición” a “último estado corporativo válido”;
- reconocieron como gestionable al contacto sin ninguna aparición corporativa;
- mantuvieron fail-closed para contactos corporativos que nunca poseen un estado válido.

## Pruebas transaccionales

### Política canónica base

```json
{
  "status": "PASS",
  "validation": "canonical_eligibility_transactional_fixtures",
  "fixtures_rolled_back": true,
  "prod_accessed": false
}
```

### Carga asignada

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

### Frontera temporal

```json
{
  "status": "PASS",
  "validation": "eligibility_temporal_boundary",
  "future_appearance_ignored_for_prior_period": true,
  "fixtures_rolled_back": true,
  "prod_accessed": false
}
```

### Último estado válido y contacto manual

```json
{
  "status": "PASS",
  "validation": "last_valid_status_and_manual_contacts",
  "newer_invalid_status_ignored": true,
  "manual_contact_gestionable": true,
  "observed_without_valid_status_fail_closed": true,
  "fixtures_rolled_back": true,
  "prod_accessed": false
}
```

Este último fixture comprobó:

- mayo `No Gestionado` + junio sin estado + ausencia en julio → gestionable por mayo;
- aparición corporativa sin ningún estado válido → no gestionable;
- contacto sin apariciones → gestionable como `manual_contact`;
- rebuild de un contacto manual con `cms_id` y `campaign_id` nulos;
- rollback completo sin residuos.

## Proyección real de DEV después del refinamiento

Distribución canónica:

```json
{
  "assigned_current": 13,
  "active_unassigned": 100,
  "latest_no_gestionado": 1,
  "latest_gestionado": 1,
  "latest_status_missing": 49,
  "manual_contact": 0
}
```

Resultado:

```json
{
  "canonical_manageable": 14,
  "visible_queue": 14,
  "visible_queue_not_canonical": 0,
  "canonical_missing_from_visible_queue": 0,
  "active_unassigned_leaks": 0
}
```

El dataset ficticio actual no contiene contactos manuales, pero el caso fue validado mediante fixture.

## Rebuild real de DEV

La cola fue reconstruida después del refinamiento. Los resultados anteriores y posteriores fueron idénticos:

- 14 gestionables;
- 13 asignados;
- 1 por último estado válido `No Gestionado`;
- 0 contactos visibles fuera de la política;
- 0 contactos canónicos ausentes de la cola.

Hash de hechos de usuario calculado con estado, ingreso, comentarios y recordatorios antes y después del rebuild:

```text
130db7bdc57febfa05e9cf475490cce2
```

El hash permaneció idéntico.

## Interpretación de la deuda de datos

Las 439 filas sin estado válido ya no bloquean necesariamente al contacto si existe un estado corporativo válido anterior.

La política distingue:

- fila reciente inválida + estado válido anterior → utiliza el estado anterior;
- apariciones corporativas sin ningún estado válido → fail-closed;
- ausencia total de apariciones → contacto manual gestionable.

El backfill sigue siendo necesario para recuperar hechos corporativos faltantes y evitar clasificaciones incompletas, pero no debe confundirse con una reimportación completa.

## Recuentos preservados

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

Hallazgos relacionados y preexistentes:

- RPC públicas `SECURITY DEFINER` ejecutables por usuarios autenticados;
- `norm_campaign_key` con `search_path` mutable;
- índices/FK con oportunidades de optimización.

Referencias:

- https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable
- https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys

## Resultado actual

```text
Migraciones DEV                  PASS
Permisos y firmas               PASS
Fixtures política               PASS
Fixture carga asignada          PASS
Frontera temporal               PASS
Último estado válido            PASS
Contacto manual                 PASS
Rebuild DEV                     PASS
Preservación hechos usuario     PASS
Backfill real                   NO EJECUTADO
PROD                            NO ACCEDIDO
Suite local repositorio         PENDIENTE
Smoke test visual DEV           PENDIENTE
```

No corresponde promover a STAGING ni PROD hasta completar la suite local, el smoke test DEV, la revisión del PR y la validación de las fuentes reales.
