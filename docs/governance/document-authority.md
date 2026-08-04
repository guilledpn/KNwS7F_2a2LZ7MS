# Autoridad e índice documental del CRM Patrimonial

- Estado: Aprobado
- Última actualización: 2026-08-04
- LCD: LCD-20260803-01, LCD-20260804-01 y LCD-20260804-02
- ADR: ADR-023, ADR-026 y ADR-027

## Regla fundamental

> Cada artefacto posee una sola ubicación editable y una sola copia vigente.

GitHub es la opción predeterminada. Drive se utiliza cuando el contenido no debe publicarse o no es apropiado para Git.

No existen espejos, sincronización bidireccional ni copias navegables paralelas presentadas como autoridad.

Una copia operativa o distribución puede existir cuando sea necesaria para trabajar, siempre que identifique su fuente canónica, no evolucione independientemente y no se presente como versión editable vigente.

## GitHub

Única autoridad para conocimiento propio, publicable y versionable:

- documentos rectores y modelos;
- ADR y LCD;
- estándares, procedimientos, diagramas y evidencia técnica publicable;
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
- matrices de trabajo reservadas que dependan de Sheets.

GitHub puede enlazar estas fuentes, pero no copiar contenido reservado. Drive no copia documentos canónicos de GitHub.

La carpeta `App_llamados_crm/Fuentes y evidencia del dominio` contiene fuentes para estudiar y validar el dominio; no es el Modelo del Dominio canónico.

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
| `docs/architecture/current-repository-inventory.md` | Inventario técnico AS-IS |
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
| `docs/governance/document-authority.md` | Regla e índice actual |
| `docs/governance/LCD-20260804-01-closure.md` | Cierre del lote estadístico |
| `docs/governance/LCD-20260804-02-engineering-standards.md` | Alcance y aprobación del estándar de ingeniería |
| `PROJECT_MAP.md` | Mapa breve para orientación |

### Nivel 6 · Operación, ingeniería y aprendizaje

| Documento o conjunto | Uso |
|---|---|
| `AGENTS.md` | Punto de entrada obligatorio para agentes y colaboradores |
| `docs/engineering/development-standards.md` | Estándares canónicos de desarrollo y calidad |
| `docs/operations/chatgpt-project-instructions.md` | Texto canónico de las instrucciones de proyecto de ChatGPT |
| `docs/operations/` | Procedimientos, smoke tests y validaciones |
| `docs/learning/` | Registro educativo; no gobierna el dominio |
| documentos técnicos raíz de `docs/` | Ambientes, base, recuperación, releases y entregas históricas |
| `docs/CHANGELOG.md` | Historia humana de la aplicación productiva |
| `releases/`, `supabase/`, `tests/` y `tools/` | Artefactos implementables y verificables |

## Fuentes exclusivas de Drive

| Conjunto | Uso | Regla |
|---|---|---|
| `Bases_maestras` y respaldos | originales, normalizados y evidencia de campaña | Nunca Git público |
| `CARGA_CONTROLADA_*` | evidencia operativa y datos de una carga | No se presenta como procedimiento canónico si está obsoleto |
| `Productos Consorcio` | PDFs, manuales, fichas y matriz corporativa | Fuente del Modelo de Productos, no copia del modelo |
| `Fuentes y evidencia del dominio` | fuentes externas y corporativas usadas para validar conocimiento | No contiene el Modelo del Dominio canónico |
| Backups y archivos grandes | recuperación y evidencia | Mantener control de acceso y período |

La carpeta Drive `App_llamados_crm` es un repositorio de fuentes y evidencia, no un repositorio documental paralelo.

## Copias operativas de normalizadores

En Drive permanecen:

- `Bases_maestras/normalizar_bases_campanas.py`;
- `Bases_maestras/normalizar_bases_campanas_sin_fechas.py`.

El usuario confirmó que ambos forman parte de su flujo operativo.

`tools/normalize_campaign_bases.py` es la implementación canónica versionada en GitHub, pero esa autoridad no permite eliminar las copias operativas antes de comprobar equivalencia y reemplazo.

Issue #57 gobierna:

- la comparación funcional;
- la identificación de la fuente canónica;
- el mecanismo de distribución y actualización;
- la eventual conservación, sustitución o retiro de las copias.

Mientras #57 permanezca abierto:

- los scripts de Drive no se eliminan;
- no se editan como una línea de desarrollo paralela;
- no se presume equivalencia sin pruebas;
- la continuidad operativa tiene prioridad.

La carpeta `Modelo del dominio` fue renombrada manualmente por el usuario como `Fuentes y evidencia del dominio` el 2026-08-04. La acción documental pendiente del Issue #40 quedó completada.

## Identificadores

Los espacios `LCD-AAAAMMDD-NN` y `ADR-NNN` son únicos.

Antes de iniciar un lote:

1. revisar `lcd-registry.md` y `adr-registry.md`;
2. reservar el siguiente identificador libre;
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
- actualización del estado documental cuando cambia la realidad;
- evidencia de validación antes del merge;
- preservación de herramientas operativas hasta validar reemplazo.

Una copia adjunta o exportada nunca adquiere autoridad por sí sola.

Si aparece una copia presentada como canónica, se detiene el trabajo dependiente hasta clasificarla. Esto no autoriza su eliminación automática.

## Migración entre ubicaciones

1. identificar uso, autoridad y restricciones;
2. congelar el original como fuente editable cuando corresponda;
3. preparar y reconciliar el candidato en una rama;
4. validar equivalencia, seguridad y continuidad operativa;
5. fusionar el PR;
6. retirar o reclasificar el original sólo cuando exista reemplazo validado;
7. verificar que quede una única fuente editable canónica.

No existe una fase posterior de sincronización bidireccional.
