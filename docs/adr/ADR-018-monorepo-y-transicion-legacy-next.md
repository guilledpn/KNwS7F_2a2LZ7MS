# ADR-018 · Monorepo y transición Legacy/Next

- Fecha: 2026-07-13
- Estado: Aprobado
- LCD: LCD-20260713-01
- Issue: #7
- Aprobación: Pull Request #9

## Contexto

APP LLAMADOS está en producción y requiere mantenimiento continuo. CRM Patrimonial representa una nueva generación con un modelo del dominio y una arquitectura sustancialmente distintos.

Separar ambos trabajos sólo mediante ramas permanentes produciría historias divergentes y difíciles de integrar. Dividirlos inmediatamente en repositorios independientes aumentaría la fragmentación documental y operativa.

## Decisión

Mantener un único repositorio y evolucionarlo progresivamente hacia un monorepo con dos aplicaciones identificables:

- APP LLAMADOS Legacy.
- CRM Patrimonial Next.

La transición seguirá Strangler Fig Pattern. El legacy continuará recibiendo correcciones y mejoras acotadas. Las capacidades nuevas se construirán en módulos de la nueva arquitectura y sustituirán gradualmente funciones antiguas cuando estén validadas.

No se crearán ramas permanentes `legacy` y `next`. La separación vive en carpetas, módulos, despliegues y versiones; las ramas de trabajo serán breves.

## Consecuencias positivas

- Una única fuente de ingeniería.
- Documentación y código trazables en el mismo historial.
- Transición observable y gradual.
- Posibilidad de compartir herramientas, pruebas y componentes.
- Menor carga administrativa para un equipo pequeño.

## Riesgos

- El repositorio puede crecer y volverse confuso sin límites claros.
- Los despliegues de ambas aplicaciones deben quedar inequívocamente separados.
- Una reorganización apresurada podría romper producción.

## Controles

- No mover archivos productivos en este ADR.
- Inventariar primero el repositorio y los despliegues.
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
