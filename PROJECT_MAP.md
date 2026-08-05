# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

- Estado: Vigente
- Último LCD aprobado: LCD-20260804-05
- Cambio candidato actual: LCD-20260805-01 · ADR-028 · Issue #76
- Última entrega Legacy: `UI-20260804-10` · Issue #52 · PR #53
- Pendientes abiertos relevantes: Issues #38, #54, #56, #57 y #76; PR #21

## Productos

| Producto | Estado | Propósito |
|---|---|---|
| APP LLAMADOS Legacy | Productivo y estable | Operación actual hasta el corte total hacia Next |
| CRM Patrimonial Next | Modelo conceptual aprobado; shell local candidata | Reemplazo prioritario de Legacy y evolución patrimonial posterior |

La transición usa monorepo, Strangler Fig, DDD, arquitectura hexagonal y monolito modular. ADR-028 precisa que compartir repositorio no significa compartir runtime ni ambientes.

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

## Infraestructura de Next

Etapa A candidata mediante Issue #76:

- workspace: `apps/crm-patrimonial/`;
- shell PWA ejecutable en `http://127.0.0.1:4173`;
- arranque Windows: `apps\crm-patrimonial\start-next.cmd`;
- Supabase local reservado en puertos 56320–56324;
- workflow propio `Next shell` con artefacto descargable;
- ninguna referencia runtime a `crm-ffvv-dev` ni `crm-ffvv-v2`;
- NEXT-DEV, NEXT-STAGING y NEXT-PROD no creados todavía.

El intento de crear NEXT-DEV fue bloqueado por el límite de dos proyectos gratuitos activos. Legacy no fue pausado ni modificado.

## Modelo de Next

ADR-024 separa Modelo Comercial y Modelo Operacional. ADR-025 aprueba Caso, Oportunidad, Cotización, Pipeline, CNS y Producto Contratado. El diseño físico `next_v03` todavía requiere un LCD propio.

ADR-028 candidato establece:

- un monorepo y dos productos con runtime independiente;
- ambientes `NEXT-LOCAL`, `NEXT-DEV`, `NEXT-STAGING` y `NEXT-PROD` separados de Legacy;
- desarrollo y ensayos previos sin doble escritura real;
- corte operativo total: Next pasa a ser la única aplicación diaria y Legacy queda temporalmente como consulta o rollback.

## Ambientes

- LEGACY-DEV y LEGACY-PROD: proyectos actuales de APP LLAMADOS.
- NEXT-LOCAL: shell creada; backend local configurado, pendiente de arranque con Docker.
- NEXT-DEV: no creado por límite Supabase.
- NEXT-STAGING: no creado.
- NEXT-PROD: no creado.

La matriz detallada está en `docs/architecture/product-environment-deployment-matrix.md`.

## Prioridad

1. Aprobar la infraestructura independiente de Issue #76.
2. Resolver capacidad cloud y crear NEXT-DEV sin reutilizar Legacy.
3. Abrir el LCD del esquema físico mínimo `next_v03`.
4. Construir la vertical completa de llamados y gestión diaria.
5. Ensayar migración, conciliación, rollback y corte total.
6. Mantener Legacy sólo con operaciones y hotfix imprescindibles mientras siga siendo la aplicación activa.

El estado y detalle autoritativos viven en el Roadmap y en los registros `lcd-registry.md` y `adr-registry.md`.
