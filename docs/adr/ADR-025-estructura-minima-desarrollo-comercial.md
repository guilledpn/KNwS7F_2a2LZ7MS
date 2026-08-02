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

Esta representación no fija todavía la propiedad definitiva de Propuestas y Pipeline.

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

### 2. Nacimiento, pertenencia y cardinalidad de la Oportunidad

Una Oportunidad representa una contratación potencial individualizable de un producto concreto para la cual existe un desarrollo comercial real que seguir.

Reglas:

- una necesidad general, interés difuso o conversación exploratoria sin producto potencial concreto no crea todavía una Oportunidad;
- la Oportunidad nace cuando se identifica un producto potencial concreto dentro de una Relación Comercial y existe una intención, necesidad o posibilidad comercial que justifica su seguimiento;
- toda Oportunidad presupone una Relación Comercial existente;
- toda Oportunidad pertenece exactamente a un Caso Comercial;
- no existen Oportunidades sueltas fuera de un Caso Comercial;
- cuando se identifica la primera Oportunidad de un objetivo, necesidad o proceso de decisión, nace o se identifica simultáneamente el Caso Comercial correspondiente;
- un Caso Comercial contiene una o más Oportunidades;
- una Persona puede mantener varios Casos y varias Oportunidades abiertas simultáneamente dentro de su única Relación Comercial;
- la Oportunidad conserva el desarrollo comercial de un producto concreto; el Caso conserva el objetivo, necesidad o proceso de decisión que explica por qué esa Oportunidad existe y cómo se relaciona con otras;
- el movimiento o reclasificación posterior de una Oportunidad entre Casos deberá conservar historia y se resolverá junto con los ciclos de vida.

Cardinalidad conceptual aprobada:

```text
Relación Comercial 1 ── 0..N Casos Comerciales
Caso Comercial     1 ── 1..N Oportunidades
Oportunidad        1 ── 1 Caso Comercial
```

### 3. Distinción entre Oportunidad y Cotización

Una Cotización representa una configuración específica de una Oportunidad. La Oportunidad conserva la identidad de la contratación potencial; las Cotizaciones representan alternativas concretas para materializar esa misma contratación.

Reglas:

- una Oportunidad puede existir antes de registrar su primera Cotización y posteriormente tener una o varias;
- dos Cotizaciones pertenecen a la misma Oportunidad cuando son configuraciones mutuamente excluyentes de una única contratación potencial;
- capital asegurado, prima, cobertura, régimen, aporte, costo, plazo u otra configuración distinta no crean por sí solos una nueva Oportunidad;
- dos desarrollos constituyen Oportunidades distintas cuando representan contrataciones individualizables que podrían celebrarse y persistir simultáneamente;
- pueden existir varias Oportunidades del mismo producto cuando representan contrataciones distintas y compatibles;
- una diferencia impuesta por el CRM corporativo no redefine por sí sola el dominio propio: cuando el sistema externo exige oportunidades separadas para alternativas de una misma contratación, CRM Patrimonial conserva la unidad de la Oportunidad propia y registra por separado las referencias corporativas necesarias;
- una Cotización pertenece exactamente a una Oportunidad;
- la Cotización no sustituye al Producto Contratado ni demuestra que la contratación ocurrió;
- la relación entre Cotización y Propuesta se resolverá en la siguiente decisión del lote.

Ejemplo de una Oportunidad con varias Cotizaciones:

```text
Oportunidad: contratar un Vida Ahorro Total
Cotizaciones alternativas:
- cobertura UF 1.000
- cobertura UF 2.000
- cobertura UF 3.000
```

Las tres configuraciones compiten por materializar una única contratación potencial.

Ejemplo de Oportunidades distintas del mismo producto:

```text
Oportunidad 1: seguro destinado a protección familiar
Oportunidad 2: seguro independiente destinado a planificación sucesoria
```

Si ambas contrataciones pueden celebrarse y persistir simultáneamente, no son Cotizaciones alternativas de una única Oportunidad.

Cardinalidad conceptual aprobada:

```text
Oportunidad 1 ── 0..N Cotizaciones
Cotización  1 ── 1 Oportunidad
```

#### Antecedente de flexibilidad para el diseño lógico y físico

Se registra una inquietud de diseño: una regla semánticamente correcta puede volverse excesivamente rígida si se traduce prematuramente en restricciones físicas irreversibles o en bloqueos de interfaz basados en una clasificación de productos todavía incompleta.

Criterios orientadores para la etapa posterior:

- la base debe preservar la coherencia del dominio sin impedir correcciones o reclasificaciones trazables;
- una posible incompatibilidad entre productos o configuraciones debe poder detectarse como advertencia antes de convertirse automáticamente en rechazo;
- la experiencia podrá preguntar, por ejemplo, si elementos de distinta índole pertenecen realmente a la misma Oportunidad y ofrecer separarlos o reclasificarlos;
- toda separación, traslado o reclasificación posterior debe conservar la historia y las referencias corporativas;
- no debe confundirse flexibilidad con ausencia de modelo: una excepción confirmada debe quedar explícita y trazable;
- todavía no se aprueba un mecanismo técnico concreto de advertencia, excepción u override, ni se afirma que cualquier mezcla de productos sea válida.

Este antecedente no modifica la definición aprobada de Oportunidad y Cotización. Obliga a que el futuro diseño lógico distinga entre invariantes del dominio, heurísticas de consistencia y advertencias de calidad de datos, evitando convertir una taxonomía todavía evolutiva en un bloqueo estructural innecesario.

## Preguntas pendientes del lote

1. Si una Propuesta pertenece a una Oportunidad, a un Caso o puede presentar elementos de ambos.
2. Cómo se relacionan Propuesta y Cotización y si ambas conservan versiones.
3. Qué concepto recorre realmente el Pipeline.
4. Qué estados son hechos persistentes y cuáles son vistas derivadas.
5. Cómo se cierran, descartan, reemplazan, reclasifican o reabren Casos y Oportunidades sin borrar historia.
6. Cómo se vinculan opcionalmente Tareas y Actividades con Relación Comercial, Caso Comercial y Oportunidad.
7. Cómo distinguir en el diseño lógico las restricciones verdaderamente invariantes de las advertencias o heurísticas de compatibilidad de productos.

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
- mecanismo técnico definitivo de advertencias o excepciones;
- cambios en APP LLAMADOS Legacy, DEV, STAGING o PROD.

## Consecuencias actuales

- `next_v03` continúa bloqueado para diseño físico definitivo;
- el Caso Comercial queda diferenciado de la Relación Comercial y de la Oportunidad;
- una Relación puede persistir sin Caso y un Caso no puede persistir sin al menos una Oportunidad asociada;
- toda Oportunidad pertenece exactamente a un Caso y no puede existir como elemento comercial suelto;
- la primera Oportunidad concreta origina o identifica simultáneamente el Caso correspondiente;
- la Oportunidad conserva una contratación potencial individualizable y la Cotización una configuración específica de esa contratación;
- alternativas mutuamente excluyentes permanecen en una Oportunidad, mientras contrataciones que pueden coexistir se representan como Oportunidades distintas;
- el criterio de agrupación es semántico —objetivo, necesidad, proceso de decisión y contratación posible— y no meramente temporal ni técnico;
- el futuro diseño lógico no podrá convertir heurísticas de compatibilidad o taxonomías evolutivas en bloqueos irreversibles sin una decisión posterior explícita;
- el Modelo Comercial y la Matriz de Validación incorporarán estas decisiones durante la consolidación del LCD;
- las demás hipótesis de este borrador no constituyen reglas del dominio hasta su aprobación explícita.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.
