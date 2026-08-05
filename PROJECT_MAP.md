# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

- Estado: Vigente
- Último LCD aprobado: LCD-20260805-01
- Última entrega Legacy: `UI-20260804-10` · Issue #52 · PR #53
- Pendientes abiertos relevantes: Issues #38, #54, #56 y #57; PR #21

## Productos

| Producto | Estado | Propósito |
|---|---|---|
| APP LLAMADOS Legacy | Productivo y estable | Operación actual de contactos, gestión, Stats, Importar, Ajustes y Sprint |
| CRM Patrimonial Next | Modelo conceptual aprobado | Nueva generación, desarrollada por verticales sin reescritura abrupta |

La transición usa monorepo, Strangler Fig, DDD, arquitectura hexagonal y monolito modular. Decisiones: ADR-021 y ADR-022.

## Documentos rectores

| Jerarquía | Documento |
|---:|---|
| 1 | `docs/project/constitution.md` |
| 2 | `docs/architecture/crm-patrimonial.md` |
| 3 | `docs/domain/README.md` y modelos especializados |
| 4 | `docs/project/backlog-roadmap.md` |
| 5 | `docs/adr/` y registros de gobernanza |
| 6 | `AGENTS.md`, `docs/engineering/development-standards.md`, procedimientos e instrucciones |

El índice detallado vive en `docs/governance/document-authority.md`.

## Autoridad documental

- GitHub: única ubicación de documentos propios, ADR/LCD, estándares, procedimientos, código, migraciones, pruebas y herramientas.
- Drive: única ubicación de datos reales, bases, respaldos, fuentes de terceros, manuales, PDFs y material reservado.
- No existen espejos ni copias editables paralelas. Una copia operativa puede existir si identifica su fuente y no evoluciona como autoridad.
- La carpeta de Drive se denomina `Fuentes y evidencia del dominio`.

ADR-026 y LCD-20260804-02 gobiernan esta separación.

## Ingeniería y agentes

- `AGENTS.md` es el punto de entrada para agentes y colaboradores.
- `docs/engineering/development-standards.md` contiene las reglas técnicas completas.
- `docs/operations/chatgpt-project-instructions.md` contiene la versión canónica, breve y copiable de las instrucciones del proyecto.
- LCD-20260804-04 refuerza RLS y permisos Supabase, gestión de incertidumbre, clasificación física de artefactos y disciplina de commits/PR.
- LCD-20260804-05 clasifica el trabajo y reconoce la operación excepcional como vía temporal legítima.
- LCD-20260805-01 establece que la clasificación selecciona el procedimiento y excluye por defecto los controles propios de otras categorías. También habilita una vía operativa abreviada y limita Issue, rama, PR, LCD y auditoría a los casos que realmente los requieren.
- Issue #56 gobierna la automatización gradual de quality gates.
- Issue #57 gobierna la auditoría y distribución de los normalizadores operativos.

Las instrucciones de ChatGPT no reemplazan las fuentes del repositorio.

## Modelo de Next

ADR-024 separa:

- Modelo Comercial: conceptos, hechos e invariantes del negocio.
- Modelo Operacional: importaciones, validación, idempotencia, linaje y conciliación.

ADR-025 aprueba:

- Caso como negocio indivisible, unidad del Pipeline y contenedor de 0..N Oportunidades;
- Oportunidades complementarias o alternativas;
- Cotización como configuración;
- etapas `Nuevo → Pendiente → Propuesta → En Firma → Sometido → Emitido`;
- `Ganado` sólo en `Emitido` y `Perdido` como resultado;
- proyección, sometimiento, emisión, reconocimiento de CNS y capital como conocimientos distintos;
- Producto Contratado desde Oportunidad ganada y Cotización seleccionada;
- Tareas/Actividades con Persona y Asesor esenciales y contexto comercial opcional.

El diseño físico `next_v03` todavía requiere un LCD propio; la documentación aprobada no autoriza SQL ni cambios de runtime.

## Estado Legacy al 2026-08-04

- política única de gestionabilidad implementada y promovida;
- métricas por Persona/día en PROD;
- muestra analítica estratificada disponible;
- edición de ficha separada de gestión real y datos ficticios saneados;
- carga julio/agosto completada y conciliada;
- campaña inválida retirada de la cola actual, con solución persistente pendiente en Issue #38;
- navegación contextual y retorno exacto aprobados mediante Issue #39;
- filtros mensuales y metadatos de campaña corregidos hasta PR #51, con defecto semántico residual de `get_contacts_v2` aún pendiente de Issue propio;
- contrato estadístico unificado, equivalencias motivacionales y `UI-20260804-10` promovidos mediante LCD-20260804-01, ADR-027, Issue #52 y PR #53;
- smoke visual autenticado postdespliegue pendiente en Issue #54, sin reabrir el lote aprobado.

## Ambientes

- Local: análisis y pruebas sin datos reales.
- DEV: experimentación con datos ficticios o sanitizados.
- STAGING: candidatos ya validados en DEV cuando la categoría lo requiera.
- PROD: operación real; nunca experimental.

La matriz detallada está en `docs/architecture/product-environment-deployment-matrix.md`.

## Flujo

La clasificación se realiza antes de elegir el procedimiento.

Cambio versionado o permanente:

```text
Issue → LCD/ADR cuando corresponda → rama → documentos/código → pruebas → PR → merge aprobado → promoción
```

Operación rutinaria o excepcional sin cambios canónicos:

```text
Objetivo → preflight → mecanismo mínimo → recuperación → autorización → ejecución → verificación → registro
```

La segunda vía no requiere por defecto Issue, rama, PR, LCD, ADR ni auditoría independiente. Esos controles se incorporan sólo cuando la operación cambia artefactos permanentes o un riesgo concreto los hace necesarios.

## Próximos pasos

1. Ejecutar la aceptación visual autenticada de Issue #54.
2. Diseñar y cerrar Issue #38 sin experimentar en PROD.
3. Auditar las copias operativas de normalizadores mediante Issue #57.
4. Automatizar gradualmente quality gates mediante Issue #56.
5. Registrar y corregir la semántica de `get_contacts_v2` observada en Issue #36.
6. Abrir el lote de diseño físico mínimo `next_v03`.
7. Decidir el destino del PR educativo #21.

El estado y detalle autoritativos viven en el Roadmap y en los registros `lcd-registry.md` y `adr-registry.md`.