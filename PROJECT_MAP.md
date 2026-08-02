# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

Estado: Vigente  
Último LCD aprobado: LCD-20260801-02  
Lotes pendientes relevantes: LCD-20260712-01, cierre documental/visual de LCD-20260715-01 y LCD-20260716-01

## Propósito

Entregar una vista breve y actualizada del proyecto, sus productos, ambientes, documentos y dirección arquitectónica.

## Producto conceptual

CRM Patrimonial.

## Productos operativos

### APP LLAMADOS · Legacy

Aplicación productiva actual. Debe mantenerse estable mientras se corrigen bugs y se incorporan mejoras acotadas.

### CRM Patrimonial Next

Nueva generación en descubrimiento, validación conceptual y diseño experimental. Se construirá progresivamente sin imponer su arquitectura sobre el Legacy mediante una reescritura abrupta.

## Diferencias esenciales

- **Producto:** APP LLAMADOS Legacy o CRM Patrimonial Next.
- **Ambiente:** local, DEV, STAGING o PROD.
- **Versión:** identificación concreta de una entrega.

Cada producto puede tener sus propios ambientes y versiones.

## Estrategia técnica aprobada

- Monorepo: ADR-021.
- Docs-as-Code y separación Git/Drive: ADR-022.
- Autoridad documental e identificadores únicos: ADR-023.
- DDD estratégico y táctico.
- Arquitectura hexagonal.
- Monolito modular.
- Strangler Fig Pattern para la transición.
- GitHub Flow con ramas breves y Pull Requests.
- Conventional Commits y Semantic Versioning.

## Decisión de dominio aprobada

ADR-024 establece la separación entre:

- Modelo Comercial: hechos, conceptos e invariantes del negocio;
- Modelo Operacional: importaciones, validación, idempotencia, linaje y conciliación.

La decisión y sus documentos fueron aprobados mediante LCD-20260801-02 y Pull Requests #32 y #33.

## Contextos de dominio candidatos

1. Identidad y Contactabilidad.
2. Adquisición y Campañas.
3. Gestión Operativa.
4. Gestión Comercial.
5. Catálogo de Productos.
6. Productos Contratados y Postventa.
7. Patrimonio e Inversiones.
8. Proyección y Analítica.

Estos contextos permanecen sujetos a validación formal antes del diseño físico definitivo. Los documentos Comercial y Operacional no crean por sí solos esquemas PostgreSQL, microservicios ni contextos delimitados definitivos.

## Autoridad documental

### GitHub

Fuente canónica para conocimiento propio versionable, ingeniería, ADR nuevos, registros maestros, diagramas, procedimientos, código, migraciones, pruebas e historial técnico.

Registros rectores:

- `docs/governance/document-authority.md`;
- `docs/governance/document-catalog.md`;
- `docs/governance/lcd-registry.md`;
- `docs/governance/adr-registry.md`.

### Google Drive

Fuente canónica para bases de campaña, datos sensibles, manuales, PDFs, fuentes regulatorias, evidencia externa, respaldos y archivos no aptos para el repositorio público.

Los documentos superiores que aún viven en Drive conservan autoridad hasta completar su migración individual, validada y registrada en el catálogo.

No se mantienen dos copias editables del mismo artefacto.

## Reconciliación histórica de identificadores

| Referencia histórica de GitHub | Identidad canónica |
|---|---|
| ADR-018 Monorepo | ADR-021 |
| ADR-019 Docs-as-Code | ADR-022 |
| LCD-20260713-01 del PR #9 | LCD-20260713-03 |
| LCD-20260713-02 del PR #11 | LCD-20260713-04 |

ADR-018, ADR-019, LCD-20260713-01 y LCD-20260713-02 mantienen los significados registrados previamente en Drive.

## Documentos aprobados de arquitectura de transición

### Inventario y plan · LCD-20260713-04

- `docs/architecture/current-repository-inventory.md`
- `docs/architecture/product-environment-deployment-matrix.md`
- `docs/architecture/target-monorepo-structure.md`
- `docs/architecture/reversible-monorepo-migration-plan.md`

Aprobados mediante Pull Request #11.

### Mapas visuales y red de seguridad · LCD-20260714-02

- `docs/architecture/diagrams/`
- `docs/architecture/legacy-automation-security-audit.md`
- `docs/architecture/prod-pwa-validator-drift.md`
- `docs/operations/legacy-critical-surface.md`
- `docs/operations/legacy-smoke-test.md`
- `tests/characterization/`
- `tools/run_legacy_safety_checks.py`

Aprobados mediante Pull Requests #17 y #18.

### Gestionabilidad canónica · LCD-20260715-01

- política ADR-020 promovida a PROD;
- 536.275 estados corporativos aplicados con trazabilidad;
- cola canónica validada técnicamente;
- migraciones, rollback, pruebas y documentación versionados;
- revisión documental final y smoke visual autenticado aún pendientes en el registro.

### Mejoras operativas posteriores

El repositorio contiene cambios de julio de 2026 para muestras de análisis y separación entre edición de ficha y eventos de gestión. Esos cambios forman parte de la evolución del Legacy y deben incorporarse al futuro registro histórico detallado sin alterar el Modelo de Next.

## Modelo de Next aprobado

LCD-20260801-02 incorporó como documentos canónicos, únicos y versionados:

- `docs/domain/commercial-model.md`;
- `docs/domain/operational-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.

Estos documentos organizan Persona, Campaña, Aparición, Asignación, Asesor, Relación Comercial, Responsabilidad del Asesor, Actividad, Tarea, importaciones y conciliaciones. No autorizan todavía SQL ni cambios de runtime.

## Estado actual de la transición

### Completado

- separación conceptual Legacy/Next;
- decisión de monorepo y estrategia Strangler;
- Docs-as-Code para conocimiento versionable;
- inventario técnico y plan reversible;
- mapas AS-IS, TO-BE y transición;
- red mínima de seguridad del Legacy;
- política canónica de gestionabilidad promovida técnicamente;
- reconciliación documental Drive/GitHub;
- registros únicos de LCD y ADR;
- catálogo de autoridad documental;
- laboratorio local PostgreSQL y experimentación conceptual de Next iniciados;
- Modelo Comercial, Modelo Operacional, ADR-024 y Matriz de Validación aprobados y versionados.

### En curso

- preparación del LCD para definir el modelo mínimo de Caso Comercial, Oportunidad, Propuesta y Pipeline;
- revisión del material educativo del PR #21;
- cierre documental y visual de LCD-20260715-01;
- migración progresiva de documentos superiores de Drive a Markdown.

### No iniciado o no completado

- diseño físico `next_v03`;
- SQL reproducible de Next;
- movimientos físicos definitivos hacia la estructura objetivo;
- desacoplamiento de `main` y la publicación productiva;
- STAGING plenamente establecido para Next;
- primera vertical funcional de CRM Patrimonial Next;
- migración de datos desde Legacy a Next;
- retiro seguro del Legacy.

## Flujo de trabajo

Issue → reserva de LCD/ADR → rama → documentación → diseño → implementación → pruebas → Pull Request → revisión → merge autorizado → release o despliegue cuando corresponda.

## Lotes relevantes

- `LCD-20260713-03`: gobernanza del monorepo, ADR-021 y ADR-022; PR #9.
- `LCD-20260713-04`: inventario y transición reversible; PR #11.
- `LCD-20260714-01`: cierre de Etapa 0; PR #15.
- `LCD-20260714-02`: mapas y safety net; PR #17 y #18.
- `LCD-20260715-01`: gestionabilidad y backfill PROD; PR #19 y #20.
- `LCD-20260716-01`: guías educativas de base de datos; PR #21, pendiente.
- `LCD-20260801-01`: reconciliación documental y prevención de colisiones; Issue #28, PR #29 y #30.
- `LCD-20260801-02`: modelos Comercial y Operacional mínimos y Matriz de Validación Next v03; Issue #31 y Pull Requests #32 y #33, aprobado.

El detalle autoritativo vive en `docs/governance/lcd-registry.md`.
