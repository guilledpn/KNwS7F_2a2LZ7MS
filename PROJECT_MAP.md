# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

Estado: Vigente  
Último LCD aprobado: LCD-20260714-02  
Lote en revisión: LCD-20260715-01

## Propósito

Entregar una vista breve y actualizada del proyecto, sus productos, ambientes, documentos y dirección arquitectónica.

## Producto conceptual

CRM Patrimonial.

## Productos operativos

### APP LLAMADOS · Legacy

Aplicación productiva actual. Debe mantenerse estable mientras se corrigen bugs y se incorporan mejoras acotadas.

### CRM Patrimonial Next

Nueva generación en descubrimiento, documentación y diseño. Se construirá progresivamente sin imponer su arquitectura sobre el legacy mediante una reescritura abrupta.

## Diferencias esenciales

- **Producto:** APP LLAMADOS Legacy o CRM Patrimonial Next.
- **Ambiente:** DEV, STAGING o PROD.
- **Versión:** identificación concreta de una entrega, por ejemplo `1.6.2` o `0.1.0-alpha.1`.

Cada producto puede tener sus propios ambientes y versiones.

## Estrategia técnica aprobada

- Monorepo.
- DDD estratégico y táctico.
- Arquitectura hexagonal.
- Monolito modular.
- Strangler Fig Pattern para la transición.
- GitHub Flow con ramas breves y Pull Requests.
- Conventional Commits y Semantic Versioning.
- Docs-as-Code para ingeniería.

## Contextos de dominio candidatos

1. Identidad y Contactabilidad.
2. Adquisición y Campañas.
3. Gestión Operativa.
4. Gestión Comercial.
5. Catálogo de Productos.
6. Productos Contratados y Postventa.
7. Patrimonio e Inversiones.
8. Proyección y Analítica.

Estos contextos están pendientes de validación formal antes del diseño físico.

## Repositorios de conocimiento

### GitHub · Repositorio canónico de ingeniería

Contendrá progresivamente:

- código;
- migraciones;
- documentación canónica en Markdown;
- ADR;
- diagramas Mermaid;
- pruebas;
- Issues, Pull Requests y Releases.

### Google Drive · Repositorio de fuentes y evidencias

Mantendrá:

- manuales y folletos;
- PDFs corporativos;
- fuentes regulatorias;
- archivos de trabajo no adecuados para Git;
- evidencias y respaldos documentales.

No se mantendrán dos copias editables del mismo documento canónico.

## Documentos aprobados de arquitectura de transición

### Inventario y plan

- `docs/architecture/current-repository-inventory.md`
- `docs/architecture/product-environment-deployment-matrix.md`
- `docs/architecture/target-monorepo-structure.md`
- `docs/architecture/reversible-monorepo-migration-plan.md`

Aprobados mediante Pull Request #11.

### Mapas visuales

- `docs/architecture/diagrams/README.md`
- `docs/architecture/diagrams/as-is-app-llamados.md`
- `docs/architecture/diagrams/to-be-crm-patrimonial-next.md`
- `docs/architecture/diagrams/migration-legacy-to-next.md`
- `docs/architecture/diagrams/applied-case-agenda.md`

Aprobados mediante Pull Request #17.

### Red mínima de seguridad Legacy

- `docs/architecture/legacy-automation-security-audit.md`
- `docs/architecture/prod-pwa-validator-drift.md`
- `docs/operations/legacy-critical-surface.md`
- `docs/operations/legacy-smoke-test.md`
- `tests/characterization/`
- `tools/run_legacy_safety_checks.py`

Aprobada mediante Pull Request #18. Issue #16 cerrado.

### Gestionabilidad canónica · En revisión

- `docs/architecture/contact-eligibility-policy.md`
- `docs/operations/monthly-status-backfill.md`
- `docs/operations/validation-run-2026-07-15-eligibility.md`
- `supabase/migrations/20260715054526_unify_contact_eligibility_policy.sql`
- `supabase/migrations/20260715060415_bound_eligibility_to_evaluation_period.sql`
- `supabase/migrations/20260715063727_refine_last_valid_status_and_manual_contacts.sql`
- `supabase/rollback/20260715_unify_contact_eligibility_policy.sql`
- `supabase/tests/20260715_contact_eligibility_policy.sql`
- `tools/generate_monthly_status_backfill.py`

Implementada y validada únicamente en DEV dentro del Issue #12.

## Estructura objetivo tentativa

```text
KNwS7F_2a2LZ7MS/
├── apps/
│   ├── app-llamados/
│   └── crm-patrimonial/
├── packages/
├── docs/
│   ├── governance/
│   ├── domain/
│   ├── architecture/
│   ├── adr/
│   ├── operations/
│   └── learning/
├── supabase/
├── tools/
└── .github/
```

Esta estructura es un destino. No se moverán archivos productivos hasta completar inventario, pruebas y plan de transición.

## Estado actual de la transición

### Completado

- decisión de monorepo;
- separación conceptual Legacy/Next;
- adopción de Docs-as-Code;
- programa de aprendizaje;
- flujo Issue → rama → commits → PR → review → merge;
- inventario técnico del repositorio;
- matriz Producto × Ambiente × Despliegue;
- estructura objetivo detallada;
- plan reversible de migración;
- Etapa 0: documentar y congelar supuestos;
- checkpoint de cierre y reanudación de sesiones;
- mapas AS-IS, TO-BE y TRANSICIÓN;
- primer caso visual aplicado: `Agenda`;
- Etapa 1A: red mínima de seguridad de APP LLAMADOS Legacy.

### En curso · Issue #12

- ADR-020 y LCD-20260715-01;
- política canónica única de gestionabilidad;
- migración y rollback versionados;
- implementación aplicada sólo en DEV;
- fixtures SQL y pruebas Python;
- generador local de backfill dirigido;
- validación de fuentes mensuales definitivas;
- suite local y smoke test DEV pendientes.

### No iniciado

- promoción de gestionabilidad a STAGING;
- migración o backfill de gestionabilidad en PROD;
- movimientos físicos de carpetas;
- modificación de workflows productivos;
- esqueleto de CRM Patrimonial Next;
- cambios en GitHub Pages;
- desacoplamiento de `main` y PROD.

## Flujo de trabajo

Issue → Rama → Commits → Pull Request → Pruebas → Revisión → Merge → Release → Despliegue.

## Lotes relevantes

### LCD-20260713-01 · Aprobado

- establecer gobernanza del monorepo;
- crear reglas para agentes;
- crear mapa del proyecto;
- registrar ADR principales;
- crear programa de aprendizaje;
- no mover ni alterar todavía la aplicación productiva.

### LCD-20260713-02 · Aprobado

- inventariar el repositorio actual;
- separar producto, ambiente, versión y despliegue;
- diseñar la estructura objetivo;
- preparar una migración reversible;
- actualizar evidencias de aprendizaje.

Aprobación: Pull Request #11.

### LCD-20260714-01 · Aprobado

- cerrar formalmente la Etapa 0;
- registrar checkpoint de sesión;
- preparar la Etapa 1 sin mover archivos productivos;
- actualizar trazabilidad y evidencias de aprendizaje.

Aprobación: Pull Request #15.

### LCD-20260714-02 · Aprobado

- crear mapas arquitectónicos y casos aplicados;
- inventariar la superficie crítica del legacy;
- agregar smoke test y pruebas de caracterización;
- auditar automatización, `.gitignore` y secretos;
- crear una red mínima de seguridad sin tocar PROD.

Aprobaciones: Pull Requests #17 y #18. Issue #16 cerrado.

### LCD-20260715-01 · En revisión

- unificar la política canónica de gestionabilidad;
- excluir vigentes no asignados;
- preservar asignaciones propias y hechos del usuario;
- preparar backfill histórico exacto y trazable;
- validar en DEV antes de STAGING o PROD.

Issue rector: #12. PROD no ha sido consultado ni modificado.
