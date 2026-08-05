# LCD-20260805-01 · Clasificación selectiva y vía operativa abreviada

- Estado: Candidato; pendiente de revisión y merge autorizado
- Fecha: 2026-08-05
- Issue: #84
- ADR: No aplica
- Tipo: Cambio documental de gobernanza e ingeniería

## Problema

LCD-20260804-05 incorporó una clasificación del trabajo y reconoció la operación excepcional como vía legítima. Sin embargo, las instrucciones y el estándar conservaron obligaciones universales que seguían aplicando el flujo completo de ingeniería a operaciones rutinarias y excepcionales.

La clasificación se utilizaba como una capa adicional en vez de seleccionar el procedimiento. Esto producía:

- relectura documental amplia y repetitiva;
- investigación estructural antes de resolver una necesidad operativa;
- Issues, ramas, PR y auditorías sin cambios canónicos;
- pruebas no relacionadas con los invariantes afectados;
- infraestructura durable para operaciones puntuales;
- demora del resultado operativo.

## Decisión

La clasificación gobierna el procedimiento aplicable. Las reglas propias de una categoría no se acumulan automáticamente con las de las demás.

Se distinguen dos trazas principales:

### Cambio versionado o permanente

```text
Issue → LCD/ADR cuando corresponda → rama → documentos/código → pruebas → PR → merge aprobado → promoción
```

### Operación rutinaria o excepcional sin cambios canónicos

```text
Objetivo → preflight → mecanismo mínimo → recuperación → autorización → ejecución → verificación → registro
```

La vía operativa abreviada no requiere por defecto:

- investigación estructural completa;
- desarrollo de una capacidad reutilizable;
- LCD o ADR;
- modificación del Roadmap;
- múltiples ambientes de promoción;
- auditoría independiente;
- rama o Pull Request;
- pruebas no relacionadas con los invariantes afectados.

Un control adicional sólo se incorpora cuando protege un riesgo concreto y declarado.

## Alcance de las categorías

### Operación rutinaria

Ejecuta un procedimiento vigente y conocido. Requiere preflight, autorización del ambiente, ejecución, verificación y registro.

### Operación excepcional

Resuelve una necesidad concreta cuando la vía vigente no existe, falla o no es segura para el caso. Puede usar un mecanismo temporal mínimo con recuperación y retiro explícitos. No exige corregir inmediatamente la causa estructural separable.

### Hotfix

Restaura continuidad ante una incidencia urgente actual. Utiliza contención mínima, rollback, smoke test y regularización posterior.

### Corrección estructural

Elimina una causa persistente. Recorre Issue, diseño, implementación, regresión, PR y promoción aplicable.

### Desarrollo de producto

Crea o amplía una capacidad durable. Recorre el flujo completo de producto e ingeniería.

### Auditoría

Evalúa un candidato o estado congelado y es de sólo lectura por defecto.

## Lectura documental

Antes de trabajar se confirma el `main` vigente y se consultan las fuentes necesarias para el alcance real.

Los documentos rectores forman el contexto, pero no se releen íntegramente en cada operación cuando su contenido ya es conocido y no existe indicio de cambio o conflicto.

Una operación rutinaria o excepcional prioriza:

- procedimiento aplicable;
- estado real del producto y ambiente;
- contratos e invariantes afectados;
- antecedentes directos;
- defectos y contenciones que puedan solaparse.

La lectura se amplía sólo ante una duda concreta de autoridad, dominio, arquitectura o gobernanza.

## Git y trazabilidad

Issue, rama y Pull Request son obligatorios para cambios en artefactos canónicos, código, SQL versionado, contratos, configuración o comportamiento permanente.

Una operación sobre datos mediante un procedimiento vigente o artefacto temporal conserva registro operativo suficiente para reconstruir:

- origen;
- alcance;
- autorización;
- ejecución;
- resultado;
- recuperación.

Si un artefacto temporal debe permanecer en el repositorio, esa parte se separa y sigue el flujo versionado.

## Validación

La categoría selecciona los controles aplicables. Los controles propios de otras categorías quedan excluidos y no requieren justificación individual.

Un control esperado dentro de la categoría seleccionada que se omita se registra como `No aplica` con motivo.

Una operación sobre datos valida el mecanismo, conjunto, invariantes y recuperación. No hereda automáticamente build, UI, contratos o pruebas de software no afectados.

## Consecuencias

### Positivas

- reduce sobreingeniería y demora;
- preserva controles críticos sin convertirlos en infraestructura;
- permite resolver operaciones acotadas antes de una mejora estructural separable;
- diferencia trazabilidad operativa de gobernanza documental;
- reduce lecturas, herramientas y pruebas irrelevantes;
- mantiene `main` estable y protege PROD.

### Riesgo

La vía abreviada podría utilizarse para postergar indefinidamente una corrección estructural.

### Mitigación

La operación excepcional debe declarar límites, recuperación, condición de retiro y mejora pendiente. Si crea una capacidad durable o cambia contratos, se reclasifica.

## Documentos modificados

- `AGENTS.md`;
- `docs/engineering/development-standards.md`;
- `docs/operations/chatgpt-project-instructions.md`;
- `docs/governance/lcd-registry.md`;
- `PROJECT_MAP.md`.

## Reconciliación adicional

Se corrige el registro de `LCD-20260804-05`, que ya fue aprobado y fusionado mediante Issue #65, PR #66 y commit `d5da04503f73cf6a82397e53fcc018de8dcdfc1f`, pero permanecía descrito como candidato.

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
- Issue #63 ni PR #64;
- bases de campaña ni PII.

## Validación requerida

- revisión del diff;
- ausencia de archivos fuera de alcance;
- ausencia de PII y secretos;
- coherencia entre instrucciones, estándar, `AGENTS.md`, registro y mapa;
- `Document governance`: PASS.

Otros controles técnicos: No aplica, porque el lote modifica exclusivamente documentación.

## Aprobación

La autorización del usuario para implementar estos cambios aprueba el contenido candidato. El merge del Pull Request incorpora la decisión a `main`.