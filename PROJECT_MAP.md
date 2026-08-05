# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

- Estado: Vigente
- Último LCD vigente: LCD-20260805-01
- Última entrega Legacy: `UI-20260804-10` · Issue #52 · PR #53
- Pendientes abiertos relevantes: Issues #38, #54, #56 y #57; PR #21

## Productos

| Producto | Estado | Propósito |
|---|---|---|
| APP LLAMADOS Legacy | Productivo | Operación actual de contactos, gestión, Stats, Importar, Ajustes y Sprint |
| CRM Patrimonial Next | Modelo conceptual aprobado | Nueva generación desarrollada gradualmente, sin reescritura abrupta de Legacy |

La transición usa monorepo, Strangler Fig, DDD, arquitectura hexagonal y monolito modular. Decisiones principales: ADR-021 y ADR-022.

## Fuentes de orientación

| Necesidad | Fuente |
|---|---|
| Principios | `docs/project/constitution.md` |
| Arquitectura | `docs/architecture/crm-patrimonial.md` |
| Dominio | `docs/domain/README.md` |
| Roadmap | `docs/project/backlog-roadmap.md` |
| Enrutamiento del trabajo | `AGENTS.md` |
| Desarrollo y calidad | `docs/engineering/development-standards.md` |
| Procedimientos | `docs/operations/` |
| Evidencia histórica | `docs/evidence/` |
| Autoridad documental | `docs/governance/document-authority.md` |

`PROJECT_MAP.md` resume el estado; no define reglas de ejecución.

## Autoridad de artefactos

- GitHub: documentos propios, código, migraciones, pruebas, herramientas y evidencia técnica publicable.
- Drive: bases reales, PII, fuentes corporativas o externas, respaldos y material no publicable.
- Cada artefacto tiene una sola ubicación editable canónica.

ADR-026 gobierna la separación. Las instrucciones de ChatGPT son una copia operativa subordinada a `AGENTS.md`.

## Modelo de Next

ADR-024 separa:

- Modelo Comercial: conceptos, hechos e invariantes del negocio.
- Modelo Operacional: importaciones, validación, idempotencia, linaje y conciliación.

ADR-025 define:

- Caso como unidad del Pipeline;
- 0..N Oportunidades por Caso;
- Cotización como configuración;
- etapas `Nuevo → Pendiente → Propuesta → En Firma → Sometido → Emitido`;
- `Ganado` sólo en `Emitido` y `Perdido` como resultado;
- separación entre proyección, sometimiento, emisión y reconocimiento de CNS;
- Producto Contratado desde Oportunidad ganada;
- Tareas/Actividades con Persona y Asesor esenciales.

El diseño físico `next_v03` requiere un LCD propio; la documentación conceptual no autoriza SQL ni cambios de runtime.

## Estado Legacy

- política única de gestionabilidad implementada;
- métricas por Persona/día en PROD;
- edición de ficha separada de gestión;
- orden mensual canónico incorporado;
- contrato estadístico unificado y `UI-20260804-10` promovidos;
- Issue #38 mantiene la corrección persistente de campaña inválida;
- Issue #54 mantiene la aceptación visual autenticada pendiente;
- el defecto semántico residual de `get_contacts_v2` requiere tratamiento separado.

## Ambientes

- LOCAL: análisis y pruebas locales.
- DEV: datos ficticios o sanitizados.
- STAGING: candidatos validados cuando corresponda.
- PROD: operación real.

La matriz autoritativa vive en `docs/architecture/product-environment-deployment-matrix.md`.

## Próximos pasos

1. Completar Issue #54.
2. Resolver Issue #38.
3. Auditar normalizadores mediante Issue #57.
4. Automatizar quality gates mediante Issue #56.
5. Registrar y corregir la semántica residual de `get_contacts_v2`.
6. Abrir el lote físico mínimo de `next_v03`.
7. Decidir el destino del PR educativo #21.

El detalle autoritativo vive en el Roadmap y en los registros ADR/LCD.
