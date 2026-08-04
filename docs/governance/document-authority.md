# Autoridad e índice documental del CRM Patrimonial

- Estado: Aprobado
- Última actualización: 2026-08-04
- LCD: LCD-20260803-01 y LCD-20260804-01
- ADR: ADR-023, ADR-026 y ADR-027

## Regla fundamental

> Cada artefacto posee una sola ubicación editable y una sola copia vigente.

GitHub es la opción predeterminada. Drive sólo se utiliza cuando el contenido no debe publicarse o no es apropiado para Git. No existen espejos, sincronización bidireccional ni copias navegables paralelas.

## GitHub

Única autoridad para conocimiento propio, publicable y versionable:

- documentos rectores y modelos;
- ADR y LCD;
- procedimientos, diagramas y evidencia técnica publicable;
- código, migraciones, pruebas y herramientas genéricas;
- trazabilidad mediante Issues, ramas, commits, PR y Releases.

Una rama o PR contiene un candidato. El merge aprobado incorpora el cambio canónico.

## Drive

Única autoridad para:

- bases originales y normalizadas con datos reales;
- archivos con PII o información patrimonial sensible;
- manuales, fichas, PDFs y documentos corporativos o de terceros;
- fuentes regulatorias y evidencia externa;
- respaldos, archivos grandes y resultados operativos no publicables;
- matrices de trabajo que dependan de Sheets y contengan material reservado.

GitHub puede enlazar estas fuentes, pero no copiar su contenido. Drive no copia documentos canónicos de GitHub.

## Prohibiciones del repositorio público

- datos personales reales;
- bases de campaña;
- secretos, tokens o credenciales privadas;
- documentación corporativa reservada;
- información patrimonial sensible;
- binarios de terceros sin autorización de publicación.

## Índice canónico

### Nivel 1 · Constitución

| Documento | Uso |
|---|---|
| `docs/project/constitution.md` | Principios que gobiernan todas las decisiones |

### Nivel 2 · Arquitectura

| Documento | Uso |
|---|---|
| `docs/architecture/crm-patrimonial.md` | Arquitectura integral Legacy/Next |
| `docs/architecture/contact-eligibility-policy.md` | Política ejecutable de gestionabilidad |
| `docs/architecture/current-repository-inventory.md` | Inventario técnico AS-IS de la transición |
| `docs/architecture/product-environment-deployment-matrix.md` | Separación producto/ambiente/despliegue |
| `docs/architecture/target-monorepo-structure.md` | Estructura objetivo del monorepo |
| `docs/architecture/reversible-monorepo-migration-plan.md` | Secuencia reversible de transición |
| `docs/architecture/diagrams/` | Mapas AS-IS, TO-BE y transición |
| `docs/architecture/legacy-automation-security-audit.md` | Auditoría de automatizaciones Legacy |
| `docs/architecture/prod-pwa-validator-drift.md` | Riesgo de deriva del validador productivo |

### Nivel 3 · Modelo del Dominio

| Documento | Uso |
|---|---|
| `docs/domain/README.md` | Entrada y separación de responsabilidades |
| `docs/domain/dictionary.md` | Lenguaje ubicuo |
| `docs/domain/commercial-model.md` | Reglas comerciales |
| `docs/domain/operational-model.md` | Reglas de importación y conciliación |
| `docs/domain/patrimonial-model.md` | Conocimiento patrimonial |
| `docs/domain/product-model.md` | Estructura transversal de productos |
| `docs/domain/validation-matrix-next-v03.md` | Criterios verificables de Next |

### Nivel 4 · Planificación

| Documento | Uso |
|---|---|
| `docs/project/backlog-roadmap.md` | Estado real, pendientes y prioridad |

### Nivel 5 · Decisiones y gobernanza

| Documento | Uso |
|---|---|
| `docs/adr/ADR-001-020-historical-decisions.md` | Historia consolidada anterior a Docs-as-Code |
| `docs/adr/ADR-021-*` a `ADR-027-*` | Decisiones completas actuales |
| `docs/governance/adr-registry.md` | Identificadores y estado de ADR |
| `docs/governance/lcd-registry.md` | Identificadores y estado de LCD |
| `docs/governance/document-authority.md` | Regla e índice actual; no hay catálogo separado |
| `docs/governance/LCD-20260804-01-closure.md` | Cierre y limitación residual del lote estadístico |
| `PROJECT_MAP.md` | Mapa breve para orientación |

### Nivel 6 · Operación, aprendizaje e implementación

- `AGENTS.md`: reglas obligatorias para colaboradores y agentes.
- `docs/operations/`: procedimientos, smoke tests y validaciones.
- `docs/learning/`: registro educativo; no gobierna el dominio.
- documentos técnicos raíz de `docs/`: ambiente, base, recuperación, releases y entregas históricas.
- `docs/CHANGELOG.md`: historia humana de la app productiva.
- `releases/`, `supabase/`, `tests/` y `tools/`: artefactos implementables y verificables.

## Fuentes exclusivas de Drive

| Conjunto | Uso | Regla |
|---|---|---|
| `Bases_maestras` y respaldos | originales, normalizados y evidencia de campaña | Nunca Git público |
| `CARGA_CONTROLADA_*` | evidencia operativa y datos de una carga | No se presenta como procedimiento canónico si está obsoleto |
| `Productos Consorcio` | PDFs, manuales, fichas y matriz corporativa | Fuente del Modelo de Productos, no copia del modelo |
| Backups y archivos grandes | recuperación y evidencia | Mantener control de acceso y período |

La carpeta Drive `App_llamados_crm` es un repositorio de fuentes y evidencia, no un repositorio documental paralelo.

### Incidencia de permisos pendiente · Issue #40

La raíz ya no contiene documentos rectores ni registros paralelos. Drive rechazó con `403 appNotAuthorizedToFile` las tres operaciones manuales pendientes, incluido un nuevo intento autorizado el 2026-08-04:

1. eliminar `Bases_maestras/normalizar_bases_campanas.py` (ID `1ytKRhDZRRRPzvInFzUTxTk-FNIjVVq9V`);
2. eliminar `Bases_maestras/normalizar_bases_campanas_sin_fechas.py` (ID `1CJotsub_-bdtE9EUZa7r1DK4y5Yi4zmL`);
3. renombrar la carpeta contenedora `Modelo del dominio` (ID `1dZjlZlJvnb3A8D0Cqf5au96uSgO6F14t`) como `Fuentes y evidencia del dominio`.

Ambos scripts residuales carecen de autoridad; el único normalizador canónico es `tools/normalize_campaign_bases.py`. La carpeta conserva únicamente fuentes y evidencia, pero su nombre histórico puede inducir a interpretarla como repositorio canónico. El Issue #40 permanece abierto hasta que el usuario complete las tres acciones manualmente o vuelva a autorizar explícitamente los elementos para la aplicación conectada.

## Identificadores

Los espacios `LCD-AAAAMMDD-NN` y `ADR-NNN` son únicos. Antes de iniciar un lote:

1. revisar `lcd-registry.md` y `adr-registry.md`;
2. reservar el siguiente identificador libre en la rama;
3. no derivarlo de un PR, conversación o archivo aislado;
4. no reutilizar identificadores cancelados;
5. mantener la misma identidad en Issue, documentos, commits y PR.

## Control preventivo

Toda revisión comprueba:

- una ubicación editable por artefacto;
- identificadores registrados y únicos;
- enlaces cruzados válidos;
- ausencia de PII, secretos y material reservado;
- ausencia de referencias a espejos o catálogos retirados;
- actualización del Roadmap cuando cambia el estado real;
- evidencia de validación antes del merge.

Una copia adjunta o exportada nunca adquiere autoridad. Si aparece una copia paralela presentada como vigente, se detiene el trabajo dependiente hasta eliminar o reclasificar la duplicación.

## Migración entre ubicaciones

1. congelar el original;
2. preparar y reconciliar el candidato en una rama;
3. validar equivalencia y seguridad;
4. fusionar el PR;
5. retirar inmediatamente el original de la ubicación anterior;
6. verificar que sólo quede la ubicación decidida.

No existe una fase posterior de “sincronización”.
