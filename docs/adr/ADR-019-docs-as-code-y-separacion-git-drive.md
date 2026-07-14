# ADR-019 · Docs-as-Code y separación Git/Drive

- Fecha: 2026-07-13
- Estado: Pendiente de revisión
- LCD: LCD-20260713-01
- Issue: #7

## Contexto

La documentación del proyecto creció en Google Drive mediante documentos independientes, índices, bitácoras, matrices y controles visuales de cambios. Este sistema entrega flexibilidad, pero aumenta la duplicación, la desincronización y la fatiga documental.

El código y las decisiones que lo gobiernan necesitan evolucionar de forma trazable dentro del mismo control de versiones. Al mismo tiempo, manuales, PDFs, folletos, archivos regulatorios y evidencias externas no son adecuados para Git.

## Decisión

Adoptar un sistema híbrido:

### GitHub

Fuente canónica progresiva para:

- Constitución y arquitectura de ingeniería en Markdown;
- modelos del dominio versionables;
- ADR;
- diagramas Mermaid;
- procedimientos operativos;
- migraciones, código y pruebas;
- historial técnico mediante commits, Pull Requests y Releases.

### Google Drive

Fuente canónica para:

- manuales y documentación corporativa externa;
- PDFs y fuentes regulatorias;
- folletos y presentaciones;
- evidencias documentales;
- archivos de trabajo y respaldo no adecuados para Git.

Cada documento tendrá un único lugar canónico. No se mantendrán versiones editables paralelas en Git y Drive.

## Lotes documentales

El identificador LCD se conservará como unidad de cambio semántico y trazabilidad.

En documentación versionada por Git:

- la rama representa contenido pendiente;
- el diff muestra cambios;
- el Pull Request concentra revisión;
- el merge representa aprobación;
- deja de ser necesario colorear el contenido pendiente en rojo.

## Consecuencias positivas

- Documentación y código pueden cambiar en el mismo lote.
- Se reduce el historial manual duplicado.
- Las decisiones quedan enlazadas a Issues, commits y Pull Requests.
- Markdown y Mermaid son legibles por humanos, IA y herramientas.

## Riesgos

- Una migración total inmediata puede perder formato o referencias.
- Git no reemplaza ADR, justificaciones ni fuentes externas.
- El repositorio puede llenarse de archivos binarios inadecuados.

## Controles

- Migrar documentos de forma gradual.
- No eliminar originales hasta validar la nueva fuente canónica.
- Mantener índices de referencias hacia Drive.
- Prohibir datos personales reales y secretos en Git.
