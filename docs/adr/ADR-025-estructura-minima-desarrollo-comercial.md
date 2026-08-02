# ADR-025 · Estructura mínima del desarrollo comercial

- Fecha: 2026-08-02
- Estado: <span style="color:red">Borrador · pendiente de revisión</span>
- LCD: LCD-20260802-01
- Issue: #34

## Contexto

ADR-024 estableció que el esquema físico `next_v03` no puede congelarse antes de definir el modelo mínimo de desarrollo comercial.

El Modelo Comercial aprobado ya contiene Persona, Relación Comercial, Tarea y Actividad, pero todavía no fija completamente las fronteras, cardinalidades ni ciclos de vida de:

- Caso Comercial;
- Oportunidad;
- Cotización;
- Propuesta;
- Pipeline.

Tampoco determina hasta qué nivel una Tarea o Actividad puede vincularse opcionalmente con esos conceptos sin perder su vínculo principal con las Personas involucradas y el Asesor responsable o ejecutor.

El Diccionario del Dominio y `APP LLAMADOS · Modelo de negocio` ya contienen antecedentes aprobados o canónicos sobre Caso Comercial, Oportunidad, Cotización y Propuesta. Este LCD no parte desde una hoja en blanco: debe consolidar esos antecedentes, resolver sus vacíos y corregir únicamente las contradicciones que se detecten.

## Hipótesis estructural de trabajo

La estructura general todavía se encuentra en validación:

```text
Persona
└── Relación Comercial
    └── Caso Comercial
        └── Oportunidad
            ├── Pipeline
            ├── Cotizaciones
            └── Propuestas relacionadas
```

Esta representación no fija todavía todas las cardinalidades ni la propiedad definitiva de Cotizaciones, Propuestas y Pipeline.

## Decisiones aprobadas

### 1. Origen y criterio de agrupación del Caso Comercial

Un Caso Comercial representa un objetivo, necesidad o proceso de decisión concreto de una Persona dentro de una Relación Comercial.

Reglas:

- una Relación Comercial puede existir sin Casos Comerciales;
- una Relación Comercial puede contener varios Casos Comerciales simultáneos o sucesivos;
- un Caso Comercial no nace vacío: nace cuando se identifica al menos una Oportunidad concreta asociada al objetivo, necesidad o proceso de decisión;
- un Caso Comercial agrupa una o más Oportunidades;
- varias Oportunidades pertenecen al mismo Caso cuando responden al mismo objetivo, necesidad o proceso de decisión y su evaluación conjunta, complementaria o alternativa forma parte de un mismo desarrollo comercial;
- que dos productos se trabajen al mismo tiempo no basta para afirmar que pertenecen al mismo Caso;
- que dos Oportunidades correspondan a productos distintos no obliga a separarlas si responden al mismo objetivo;
- que dos Oportunidades correspondan al mismo producto no obliga a unirlas si responden a objetivos o procesos de decisión distintos;
- antes de identificar una Oportunidad puede existir una Relación Comercial o una condición Lead sin Oportunidad, pero todavía no existe un Caso Comercial;
- el Caso organiza el desarrollo comercial propio y no reemplaza las Oportunidades formales que pueda exigir la compañía.

Ejemplos:

```text
Objetivo: inversión de largo plazo
Caso Comercial: estrategia de inversión de largo plazo
Oportunidades:
- APV
- CUI
- Fondo Mutuo
```

Las Oportunidades pueden ser complementarias o alternativas dentro del mismo objetivo.

```text
Objetivo 1: proteger económicamente a la familia
Caso Comercial 1: protección familiar
Oportunidad: Seguro de Vida

Objetivo 2: mejorar la pensión futura
Caso Comercial 2: ahorro previsional
Oportunidad: APV
```

Aunque ambas Oportunidades se trabajen en una misma reunión, pertenecen a Casos distintos porque responden a objetivos diferentes.

Cardinalidad conceptual aprobada para esta parte:

```text
Relación Comercial 1 ── 0..N Casos Comerciales
Caso Comercial     1 ── 1..N Oportunidades
```

La cardinalidad inversa de Oportunidad hacia Caso Comercial y la posibilidad de mover o reclasificar una Oportunidad se resolverán en las siguientes decisiones del lote.

## Preguntas pendientes del lote

1. Qué hecho exacto da origen a una Oportunidad y si toda Oportunidad debe pertenecer exactamente a un Caso Comercial.
2. Si la Oportunidad representa siempre una contratación potencial individualizable por producto.
3. Cómo distinguir contrataciones distintas, alternativas y configuraciones de una misma contratación.
4. Si una Propuesta pertenece a una Oportunidad, a un Caso o puede presentar elementos de ambos.
5. Cómo se relacionan Propuesta y Cotización y si ambas conservan versiones.
6. Qué concepto recorre realmente el Pipeline.
7. Qué estados son hechos persistentes y cuáles son vistas derivadas.
8. Cómo se cierran, descartan, reemplazan, reclasifican o reabren Casos y Oportunidades sin borrar historia.
9. Cómo se vinculan opcionalmente Tareas y Actividades con Relación Comercial, Caso Comercial y Oportunidad.

## Límites del lote

No se decidirán todavía:

- nombres físicos de tablas o columnas;
- SQL;
- UX detallada;
- colores;
- dashboards;
- automatizaciones;
- probabilidades definitivas;
- reglas particulares de cada producto;
- cambios en APP LLAMADOS Legacy, DEV, STAGING o PROD.

## Consecuencias actuales

- `next_v03` continúa bloqueado para diseño físico definitivo;
- el Caso Comercial queda diferenciado de la Relación Comercial y de la Oportunidad;
- una Relación puede persistir sin Caso y un Caso no puede persistir sin al menos una Oportunidad asociada;
- el criterio de agrupación es semántico —objetivo, necesidad o proceso de decisión— y no meramente temporal ni técnico;
- el Modelo Comercial y la Matriz de Validación deben incorporar esta decisión durante la consolidación del LCD;
- las demás hipótesis de este borrador no constituyen reglas del dominio hasta su aprobación explícita.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.
