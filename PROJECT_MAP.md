# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

- Estado: Vigente
- Último LCD aprobado: LCD-20260803-01
- Última entrega Legacy: `App_llamados_v1.05-ui-20260803-07` · Issue #39
- Pendientes abiertos relevantes: Issues #38 y #40; PR #21

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
| 6 | `AGENTS.md`, procedimientos y documentación técnica |

El índice detallado vive en `docs/governance/document-authority.md`.

## Autoridad documental

- GitHub: única ubicación de documentos propios, ADR/LCD, procedimientos, código, migraciones, pruebas y herramientas.
- Drive: única ubicación de datos reales, bases, respaldos, fuentes de terceros, manuales, PDFs y material reservado.
- No existen espejos ni copias editables paralelas. ADR-026.

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

## Estado Legacy al 2026-08-03

- política única de gestionabilidad implementada y promovida;
- métricas por Persona/día en PROD;
- muestra analítica estratificada disponible;
- edición de ficha separada de gestión real y datos ficticios saneados;
- carga julio/agosto completada y conciliada;
- campaña inválida retirada de la cola actual, con solución persistente pendiente en Issue #38;
- navegación contextual y retorno exacto aprobados mediante Issue #39;
- defecto semántico conocido en metadatos de `get_contacts_v2`, pendiente de registrar/corregir.

## Ambientes

- Local: análisis y pruebas sin datos reales.
- DEV: experimentación con datos ficticios o sanitizados.
- STAGING: candidatos ya validados en DEV.
- PROD: operación real; nunca experimental.

La matriz detallada está en `docs/architecture/product-environment-deployment-matrix.md`.

## Flujo

```text
Descubrir → Validar → Documentar → Diseñar → Implementar
```

Ejecución trazable:

```text
Issue → LCD/ADR → rama → documentos/código → pruebas → PR → merge aprobado → promoción
```

## Próximos pasos

1. Completar las dos acciones manuales de Drive registradas en Issue #40.
2. Resolver Issue #38 en DEV.
3. Registrar y corregir la semántica de `get_contacts_v2` observada en Issue #36.
4. Abrir el lote de diseño físico mínimo `next_v03`.
5. Decidir el destino del PR educativo #21.

El estado y detalle autoritativos viven en el Roadmap y en los registros `lcd-registry.md` y `adr-registry.md`.
