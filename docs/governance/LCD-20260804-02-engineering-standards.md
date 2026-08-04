# LCD-20260804-02 · Estándares de desarrollo e instrucciones operativas

- Identificador: LCD-20260804-02
- Fecha: 2026-08-04
- Estado: Aprobado
- Motivo: separar las instrucciones breves de ChatGPT de las reglas canónicas extensas de ingeniería
- Autorización: aprobación explícita del usuario en la conversación del proyecto
- Issues relacionados: #40, #56 y #57

## Problema

Las instrucciones del proyecto en ChatGPT admiten un máximo de 8.000 caracteres.

La propuesta completa de gobernanza, desarrollo, seguridad y validación superaba ese límite. Comprimirla hasta hacerla críptica habría debilitado las reglas y creado una copia difícil de mantener.

Además, la conciliación documental había tratado dos normalizadores de Drive como residuos eliminables sin comprobar que el usuario los utiliza operativamente.

## Decisión

Se adopta una estructura de tres niveles:

1. las instrucciones de proyecto de ChatGPT actúan como puerta de entrada y permanecen bajo 8.000 caracteres;
2. `AGENTS.md` orienta a cualquier agente dentro del repositorio;
3. `docs/engineering/development-standards.md` contiene el estándar técnico completo.

Las instrucciones de ChatGPT no reemplazan las fuentes canónicas. Antes de desarrollar, corregir, auditar o promover, el agente debe consultar desde `main` los documentos aplicables.

## Artefactos

### Creados

- `docs/engineering/development-standards.md`;
- `docs/operations/chatgpt-project-instructions.md`;
- `docs/governance/LCD-20260804-02-engineering-standards.md`.

### Actualizados

- `AGENTS.md`;
- `PROJECT_MAP.md`;
- `docs/governance/document-authority.md`;
- `docs/governance/lcd-registry.md`;
- `docs/project/backlog-roadmap.md`.

### Trazabilidad operativa

- Issue #56: automatización gradual de quality gates;
- Issue #57: auditoría de equivalencia y distribución de normalizadores;
- Issue #40: cierre de la migración documental y reclasificación de copias operativas.

## Reglas aprobadas

- mínimo cambio completo y correcto;
- no refactorizar ampliamente como efecto secundario de un fix;
- no cambiar contratos sin declarar impacto;
- no duplicar reglas semánticas ni crear implementaciones paralelas sin transición;
- prohibición de deuda técnica silenciosa;
- datos externos desconocidos como `unknown` y validación de frontera;
- controles proporcionales al alcance;
- controles omitidos registrados como `No aplica`;
- preservación estricta del Legacy;
- continuidad operativa antes de retirar herramientas;
- evidencia verificable para declarar `PASS`.

## Normalizadores de Drive

La carpeta `Modelo del dominio` fue renombrada manualmente como `Fuentes y evidencia del dominio`.

Los scripts:

- `normalizar_bases_campanas.py`;
- `normalizar_bases_campanas_sin_fechas.py`;

se conservan porque forman parte del flujo del usuario.

`tools/normalize_campaign_bases.py` continúa como implementación canónica versionada. Issue #57 determinará equivalencia, distribución y eventual retiro o conservación de las copias operativas.

No se autoriza eliminar esos scripts antes de validar reemplazo y continuidad.

## Impacto

- Constitución: sin cambios.
- Arquitectura: sin cambios.
- Modelo del Dominio: sin cambios.
- Código de aplicación: sin cambios.
- Supabase y ambientes: sin cambios.
- Backlog: se registran Issues #56 y #57.
- Gobernanza: se agrega LCD-20260804-02.
- ADR: no corresponde; no se adopta una decisión arquitectónica nueva.

## Validación requerida

- unicidad del identificador LCD;
- vínculos internos existentes;
- instrucciones canónicas bajo 8.000 caracteres;
- ausencia de PII y secretos;
- `python tools/validate_document_governance.py`;
- revisión del diff documental;
- ningún cambio en código de aplicación o ambientes.
