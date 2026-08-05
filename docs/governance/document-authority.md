# Autoridad e índice documental del CRM Patrimonial

- Estado: Aprobado
- Última actualización: 2026-08-05
- LCD: LCD-20260803-01, LCD-20260804-02 y LCD-20260805-01
- ADR: ADR-023 y ADR-026

## Regla fundamental

> Cada materia tiene una fuente editable canónica. Las copias, resúmenes, decisiones históricas y evidencias no pueden evolucionar como autoridad paralela.

Una rama o Pull Request contiene un candidato. El merge aprobado incorpora el cambio a `main`.

## Jerarquía semántica

1. Constitución.
2. Arquitectura.
3. Modelo del Dominio.
4. Backlog y Roadmap.
5. ADR, LCD y registros.
6. Estándares y procedimientos.

La ubicación de un archivo no altera esta jerarquía.

## Fuente principal por materia

| Materia | Fuente canónica |
|---|---|
| Principios del proyecto | `docs/project/constitution.md` |
| Arquitectura integral | `docs/architecture/crm-patrimonial.md` |
| Conceptos, hechos e invariantes | `docs/domain/README.md` y modelos especializados |
| Prioridades y estado planificado | `docs/project/backlog-roadmap.md` |
| Decisiones arquitectónicas | `docs/adr/` y `docs/governance/adr-registry.md` |
| Cambios documentales aprobados | `docs/governance/LCD-*` y `docs/governance/lcd-registry.md` |
| Enrutamiento del trabajo | `AGENTS.md` |
| Desarrollo y calidad técnica | `docs/engineering/development-standards.md` |
| Procedimientos operativos vigentes | `docs/operations/` |
| Evidencia técnica histórica | `docs/evidence/` |
| Estado resumido del proyecto | `PROJECT_MAP.md` |
| Instrucciones copiables de ChatGPT | `docs/operations/chatgpt-project-instructions.md`, subordinadas a `AGENTS.md` |

Cada pregunta debe resolverse primero en su fuente principal. Un documento de menor nivel puede enlazarla, pero no redefinirla.

## Clases documentales

### Normas vigentes

Constitución, Arquitectura, Modelo del Dominio, Roadmap, `AGENTS.md` y estándar de desarrollo.

### Procedimientos vigentes

Runbooks y protocolos de `docs/operations/`. Explican cómo ejecutar una operación concreta y no redefinen la política general.

### Decisiones históricas

ADR y LCD explican por qué se adoptó o cambió una norma. No deben usarse como una segunda versión de la regla vigente.

Todo ADR o LCD puede conservar lenguaje normativo propio de su decisión, pero la conducta actual se consulta en el documento canónico que esa decisión modificó.

### Evidencia histórica

Informes de validación, resultados de ejecuciones, cierres técnicos y registros fechados viven en `docs/evidence/`. Demuestran qué ocurrió; no son procedimientos vigentes.

### Copias operativas

Una copia necesaria para trabajar debe:

- identificar su fuente canónica;
- no introducir reglas nuevas;
- no evolucionar independientemente;
- no presentarse como versión editable vigente.

Las instrucciones de ChatGPT son una copia operativa de este tipo.

## GitHub y Drive

### GitHub

Única autoridad para:

- documentos propios y publicables;
- ADR, LCD, estándares y procedimientos;
- código, migraciones, pruebas y herramientas;
- evidencia técnica publicable;
- trazabilidad mediante Issues, ramas, commits y Pull Requests.

### Drive

Única autoridad para:

- bases originales y normalizadas con datos reales;
- PII e información patrimonial sensible;
- documentos corporativos o de terceros;
- fuentes regulatorias y evidencia externa;
- respaldos, archivos grandes y material no publicable.

GitHub puede enlazar fuentes de Drive, pero no copiar datos reservados. Drive no mantiene copias editables de documentos canónicos de GitHub.

## Índice principal

### Proyecto y arquitectura

- `docs/project/constitution.md`
- `docs/architecture/crm-patrimonial.md`
- `docs/architecture/current-repository-inventory.md`
- `docs/architecture/product-environment-deployment-matrix.md`
- `docs/architecture/target-monorepo-structure.md`

### Dominio

- `docs/domain/README.md`
- `docs/domain/dictionary.md`
- `docs/domain/commercial-model.md`
- `docs/domain/operational-model.md`
- `docs/domain/patrimonial-model.md`
- `docs/domain/product-model.md`

### Gobernanza

- `docs/governance/document-authority.md`
- `docs/governance/adr-registry.md`
- `docs/governance/lcd-registry.md`
- `docs/adr/`
- `docs/governance/LCD-*`

### Trabajo y operación

- `AGENTS.md`
- `docs/engineering/development-standards.md`
- `docs/operations/`
- `docs/evidence/`
- `PROJECT_MAP.md`

## Artefactos implementables y evidencia

Código, migraciones, pruebas y herramientas viven en las rutas técnicas del repositorio, entre ellas:

- `releases/`;
- `supabase/`;
- `tests/`;
- `tools/`;
- fuentes y artefactos clasificados por el inventario vigente.

La evidencia sensible o con datos reales permanece en Drive.

## Divergencias

Si dos documentos parecen gobernar la misma materia:

1. identificar la fuente principal de la tabla anterior;
2. detener sólo el trabajo que dependa de la divergencia;
3. tratar el otro documento como copia, decisión histórica, procedimiento o evidencia;
4. corregir la duplicación en un cambio documental;
5. no eliminar una copia operativa hasta comprobar uso y reemplazo.

Los registros `lcd-registry.md` y `adr-registry.md` son la única autoridad para identificadores y estado de decisiones.
