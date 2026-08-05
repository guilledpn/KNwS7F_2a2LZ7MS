# AGENTS.md · Router de trabajo del CRM Patrimonial

- Estado: Vigente
- Último LCD vigente: LCD-20260805-01
- Gobernanza documental: ADR-023 y ADR-026
- Última conciliación: 2026-08-05

## Propósito

Este archivo enruta el trabajo. No repite los estándares técnicos, los procedimientos operativos ni las decisiones históricas.

La autoridad vive en las fuentes canónicas del repositorio. Ante una diferencia, prevalece el documento de mayor jerarquía y la fuente especializada de la materia.

## Autoridad

1. Constitución.
2. Arquitectura.
3. Modelo del Dominio.
4. Backlog y Roadmap.
5. ADR, LCD y registros.
6. Estándares y procedimientos.

Fuentes principales:

| Pregunta | Fuente |
|---|---|
| Principios del proyecto | `docs/project/constitution.md` |
| Arquitectura Legacy/Next | `docs/architecture/crm-patrimonial.md` |
| Conceptos, hechos e invariantes | `docs/domain/README.md` y modelos especializados |
| Prioridades y pendientes | `docs/project/backlog-roadmap.md` |
| Autoridad y ubicación documental | `docs/governance/document-authority.md` |
| Identificadores y estado ADR | `docs/governance/adr-registry.md` |
| Identificadores y estado LCD | `docs/governance/lcd-registry.md` |
| Desarrollo, código, SQL y calidad | `docs/engineering/development-standards.md` |
| Ejecución de una operación | procedimiento aplicable en `docs/operations/` |
| Historia de una decisión | ADR o LCD |
| Evidencia de una ejecución pasada | `docs/evidence/` |

Confirma el `main` vigente y consulta sólo las fuentes necesarias para el alcance. Amplía la lectura cuando aparezca una duda concreta o una divergencia.

## Clasificación

Antes de actuar, clasifica la tarea por su objetivo inmediato:

| Categoría | Ruta principal |
|---|---|
| Operación rutinaria | procedimiento vigente → preflight → autorización → ejecución → verificación → registro |
| Operación excepcional | objetivo acotado → mecanismo temporal mínimo → recuperación → autorización → ejecución → verificación → retiro o archivo |
| Hotfix | `docs/operations/emergency-hotfix-protocol.md` |
| Corrección estructural | Issue → estándar de desarrollo → rama → implementación → pruebas → PR |
| Desarrollo de producto | dominio/arquitectura → diseño → estándar de desarrollo → implementación → pruebas → PR |
| Auditoría | candidato congelado y evidencia; sólo lectura por defecto |

La clasificación selecciona el procedimiento. No acumula automáticamente requisitos de otras categorías.

Una operación rutinaria o excepcional que no modifique artefactos canónicos, contratos ni comportamiento permanente no requiere por defecto Issue, LCD, ADR, rama, Pull Request ni auditoría independiente.

Si la operación comienza a crear una capacidad durable o a cambiar contratos, detén sólo esa expansión y reclasifícala.

## Reglas no negociables

- El dominio gobierna; la tecnología lo representa.
- No inventar conceptos, estados, procesos, tablas o reglas de negocio.
- APP LLAMADOS Legacy es productivo y frágil: preservar comportamiento fuera del alcance.
- No usar PROD para experimentar.
- Toda escritura en PROD requiere autorización explícita, alcance exacto, recuperación y verificación.
- LOCAL y DEV usan datos ficticios o sanitizados; DEV nunca apunta a PROD.
- No almacenar PII, bases reales, secretos ni información patrimonial sensible en Git.
- `main` permanece estable; los cambios versionados se realizan en rama y mediante Pull Request.
- Ante incertidumbre material, detener sólo el trabajo dependiente; no inventar la pieza faltante.
- La documentación y la gobernanza protegen el resultado operativo; no lo sustituyen.

## Trazabilidad

### Cambio versionado o permanente

Aplicar `docs/engineering/development-standards.md`. Requiere Issue, rama, commits lógicos, validación y Pull Request. LCD o ADR sólo cuando corresponda por la naturaleza del cambio.

### Operación sin cambio canónico

Conservar un registro suficiente para reconstruir:

- origen y alcance;
- ambiente y autorización;
- mecanismo ejecutado;
- resultado y conciliación;
- recuperación disponible;
- limitaciones o mejora pendiente.

Si un artefacto temporal debe permanecer en el repositorio, esa parte sigue la ruta de cambio versionado.

## Cierre

Informar de forma proporcional:

- qué cambió y qué no;
- qué se validó y qué no;
- ambientes afectados;
- evidencia;
- riesgos, limitaciones y pendientes.
