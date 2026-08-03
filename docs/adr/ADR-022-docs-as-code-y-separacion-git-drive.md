# ADR-022 · Docs-as-Code y separación Git/Drive

- Fecha original: 2026-07-13
- Estado: Aprobado
- LCD canónico: LCD-20260713-03
- Issue original: #7
- Aprobación original: Pull Request #9
- Reconciliación de identificador: LCD-20260801-01 · Issue #28
- Refinamiento: ADR-026 · LCD-20260803-01
- Alias histórico no canónico: ADR-019 / LCD-20260713-01 en GitHub anterior a la reconciliación

## Contexto

La documentación del proyecto creció en Google Drive mediante documentos independientes, índices, bitácoras, matrices y controles visuales de cambios. Ese sistema entrega flexibilidad, pero aumenta la duplicación, la desincronización y la fatiga documental.

El código y las decisiones que lo gobiernan necesitan evolucionar de forma trazable dentro del mismo control de versiones. Al mismo tiempo, bases de campaña, manuales, PDFs, folletos, archivos regulatorios y evidencias externas no son adecuados para un repositorio público.

## Decisión

Adoptar un sistema híbrido con autoridad exclusiva por artefacto.

### GitHub

Fuente canónica para:

- conocimiento propio y versionable del proyecto, una vez migrado y validado;
- ADR y registros maestros;
- diagramas Mermaid;
- procedimientos operativos;
- migraciones, código y pruebas;
- historial técnico mediante commits, Pull Requests y Releases.

### Google Drive

Fuente canónica para:

- bases originales y archivos con datos personales;
- manuales y documentación corporativa externa;
- PDFs y fuentes regulatorias;
- folletos y presentaciones;
- evidencias y respaldos;
- archivos no adecuados para Git.

Cada documento tiene un solo lugar editable canónico. No se mantienen versiones editables paralelas.

## Lotes documentales

El identificador LCD se conserva como unidad de cambio semántico y trazabilidad.

En documentación versionada por Git:

- la rama representa contenido pendiente;
- el diff muestra cambios;
- el Pull Request concentra revisión;
- el merge autorizado representa aprobación;
- no se usa color rojo como mecanismo principal de revisión.

## Consecuencias positivas

- Documentación y código pueden cambiar en el mismo lote.
- Se reduce el historial manual duplicado.
- Las decisiones quedan enlazadas a Issues, commits y Pull Requests.
- Markdown y Mermaid son legibles por humanos, IA y herramientas.
- Las fuentes sensibles permanecen fuera del repositorio público.

## Riesgos

- Una migración inmediata puede perder formato o referencias.
- Git no reemplaza la justificación de las decisiones ni las fuentes externas.
- El repositorio puede llenarse de binarios inadecuados.
- Una copia prematura puede presentarse erróneamente como canónica.

## Controles

- Migrar documentos gradualmente y mediante LCD.
- No retirar el original hasta validar la nueva versión.
- Mantener un índice de autoridad único dentro de `document-authority.md`.
- Mantener índices de referencias hacia Drive.
- Prohibir datos personales, secretos y material reservado en Git.
- Aplicar ADR-023 para identificadores y autoridad.

ADR-026 elimina la excepción transitoria de documentos superiores y registros paralelos en Drive: GitHub contiene todo el conocimiento propio versionable y Drive sólo fuentes/evidencia no publicables.

## Nota de reconciliación

Esta decisión apareció históricamente en GitHub como ADR-019 y LCD-20260713-01. Esos identificadores ya pertenecían al Registro Maestro y al lote de métricas operativas en Drive. La decisión conserva su aprobación original, pero su identidad definitiva es ADR-022 dentro de LCD-20260713-03.
