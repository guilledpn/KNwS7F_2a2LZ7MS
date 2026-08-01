# ADR-021 · Monorepo y transición Legacy/Next

- Fecha original: 2026-07-13
- Estado: Aprobado
- LCD canónico: LCD-20260713-03
- Issue original: #7
- Aprobación original: Pull Request #9
- Reconciliación de identificador: LCD-20260801-01 · Issue #28
- Alias histórico no canónico: ADR-018 / LCD-20260713-01 en GitHub anterior a la reconciliación

## Contexto

APP LLAMADOS está en producción y requiere mantenimiento continuo. CRM Patrimonial representa una nueva generación con un modelo del dominio y una arquitectura sustancialmente distintos.

Separar ambos trabajos sólo mediante ramas permanentes produciría historias divergentes y difíciles de integrar. Dividirlos inmediatamente en repositorios independientes aumentaría la fragmentación documental y operativa.

## Decisión

Mantener un único repositorio y evolucionarlo progresivamente hacia un monorepo con dos aplicaciones identificables:

- APP LLAMADOS Legacy;
- CRM Patrimonial Next.

La transición seguirá Strangler Fig Pattern. El Legacy continuará recibiendo correcciones y mejoras acotadas. Las capacidades nuevas se construirán en módulos de la nueva arquitectura y sustituirán gradualmente funciones antiguas cuando estén validadas.

No se crearán ramas permanentes `legacy` y `next`. La separación vive en carpetas, módulos, despliegues y versiones; las ramas de trabajo serán breves.

## Consecuencias positivas

- Una única fuente de ingeniería.
- Documentación y código trazables en el mismo historial.
- Transición observable y gradual.
- Posibilidad de compartir herramientas, pruebas y componentes cuando exista reutilización real.
- Menor carga administrativa para un equipo pequeño.

## Riesgos

- El repositorio puede crecer y volverse confuso sin límites claros.
- Los despliegues de ambas aplicaciones deben quedar inequívocamente separados.
- Una reorganización apresurada podría romper producción.

## Controles

- No mover archivos productivos sin un lote específico.
- Inventariar primero repositorio y despliegues.
- Incorporar pruebas de caracterización.
- Diseñar la estructura destino antes de migrar.
- Ejecutar cambios por lotes pequeños y reversibles.

## Alternativas descartadas

### Dos repositorios inmediatos

Descartado por fragmentar documentación, decisiones y transición antes de conocer las fronteras técnicas definitivas.

### Dos ramas permanentes

Descartado por crear divergencia prolongada y fusiones difíciles.

### Reescritura total

Descartado por comprometer continuidad operativa y aumentar el riesgo de pérdida funcional.

## Nota de reconciliación

Esta decisión apareció históricamente en GitHub como ADR-018 y LCD-20260713-01. Esos identificadores ya pertenecían, respectivamente, a la decisión de métricas operativas y a su lote en la Bitácora y el Registro Maestro de Drive. La reconciliación preserva el contenido y la aprobación original, pero asigna definitivamente ADR-021 y LCD-20260713-03.
