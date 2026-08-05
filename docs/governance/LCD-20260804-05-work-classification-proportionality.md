# LCD-20260804-05 · Clasificación y proporcionalidad del trabajo

- Estado: Candidato; pendiente de revisión y merge autorizado
- Fecha: 2026-08-04
- Issue: #65
- ADR: No aplica
- Tipo: Cambio documental de gobernanza de ingeniería

## Problema

Las reglas vigentes exigían buscar soluciones canónicas, diseñar el mínimo cambio completo y correcto y aplicar validación proporcional, pero no distinguían suficientemente entre clases de trabajo con objetivos y riesgos diferentes.

Esa ambigüedad podía convertir una necesidad operativa acotada en el desarrollo inmediato de una solución definitiva, agregar infraestructura específica innecesaria o aplicar a una operación los controles propios de desarrollo de producto.

## Decisión

Antes de diseñar o implementar, el trabajo se clasifica como:

1. operación rutinaria;
2. operación excepcional;
3. hotfix;
4. corrección estructural;
5. desarrollo de producto;
6. auditoría.

La categoría determina el proceso, el alcance, los controles y la evidencia proporcionales.

La ausencia, insuficiencia o defecto de una solución canónica no obliga por sí mismo a desarrollar inmediatamente su reemplazo definitivo. Una necesidad concreta y acotada puede resolverse mediante una operación excepcional temporal, segura, recuperable y trazable.

La operación excepcional:

- no se presenta como nueva fuente de verdad ni como solución canónica;
- preserva invariantes críticos;
- declara límites, autorización, verificación y recuperación;
- evita contratos o infraestructura durables salvo alcance separado;
- registra la mejora estructural pendiente sin convertirla automáticamente en precondición.

Una mejora estructural sólo es requisito previo cuando no existe una vía temporal con seguridad suficiente.

“Mínimo cambio completo y correcto” significa completo dentro del alcance explícitamente aprobado, no resolver todos los problemas relacionados que puedan separarse sin comprometer el objetivo inmediato.

## Distinción de categorías

- Una operación rutinaria ejecuta un procedimiento vigente y conocido.
- Una operación excepcional resuelve una necesidad planificada cuando la vía canónica no resulta apta.
- Un hotfix restaura continuidad ante una incidencia urgente actual.
- Una corrección estructural elimina una causa persistente.
- Un desarrollo de producto crea o amplía capacidades.
- Una auditoría evalúa un candidato congelado y es de sólo lectura por defecto.

Si el trabajo cambia de categoría, se detiene únicamente la expansión de alcance, se reclasifica y se obtiene la trazabilidad o autorización aplicable.

## Documentos modificados

- `AGENTS.md`;
- `docs/engineering/development-standards.md`;
- `docs/operations/chatgpt-project-instructions.md`;
- `docs/operations/emergency-hotfix-protocol.md`;
- `docs/governance/lcd-registry.md`;
- `PROJECT_MAP.md`.

## Fuera de alcance

No se modifican:

- Constitución;
- Arquitectura;
- Modelo del Dominio;
- Backlog y Roadmap;
- ADR;
- código, SQL, migraciones, pruebas o configuración;
- importador Legacy;
- LOCAL, DEV, STAGING o PROD;
- Issue #63 ni PR #64.

## Consecuencias

### Positivas

- reduce sobreingeniería y expansión silenciosa del alcance;
- permite resolver necesidades operativas sin desarrollar de inmediato la solución definitiva;
- conserva seguridad, invariantes, recuperación y trazabilidad;
- separa las operaciones excepcionales de los hotfix;
- mejora la interpretación de “mínimo cambio completo y correcto”.

### Riesgos

- una operación excepcional podría usarse para postergar indefinidamente una mejora estructural;
- una clasificación incorrecta podría reducir controles necesarios;
- mecanismos temporales podrían permanecer sin retiro o regularización.

### Mitigaciones

- límites y condición de retiro explícitos;
- Issue y evidencia proporcional;
- autorización de ambiente intacta;
- reclasificación obligatoria cuando el alcance se vuelve durable;
- las reglas no negociables de seguridad y protección de datos no se flexibilizan.

## Validación esperada

- revisión del diff documental;
- ausencia de cambios fuera de alcance;
- `Document governance`: PASS;
- PR completo y directo;
- merge sólo con autorización explícita.