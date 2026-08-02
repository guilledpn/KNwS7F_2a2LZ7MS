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

El Diccionario del Dominio y `APP LLAMADOS · Modelo de negocio` contienen antecedentes canónicos sobre estos conceptos. Este LCD no parte desde una hoja en blanco: consolida esos antecedentes, resuelve sus vacíos y corrige sólo las contradicciones detectadas.

## Hipótesis estructural de trabajo

La estructura mínima actualmente aprobada es:

```text
Persona
└── Relación Comercial
    └── Caso Comercial
        └── Oportunidad
            └── Cotizaciones
```

La Propuesta no aparece como entidad estructurada. El contenido que el Asesor decide presentar vive de forma descriptiva en el historial del Caso Comercial y puede quedar respaldado por Actividades, notas y documentos asociados.

El Pipeline se opera desde el Caso Comercial, pero las etapas se conservan por Oportunidad para permitir avances distintos. Las tarjetas del Kanban son proyecciones derivadas del Caso agrupadas por etapa; no constituyen entidades persistentes.

## Decisiones aprobadas

### 1. Origen y criterio de agrupación del Caso Comercial

Un Caso Comercial representa un objetivo, necesidad o proceso de decisión concreto de una Persona dentro de una Relación Comercial.

Reglas:

- una Relación Comercial puede existir sin Casos Comerciales;
- una Relación Comercial puede contener varios Casos simultáneos o sucesivos;
- un Caso no nace vacío: nace cuando se identifica al menos una Oportunidad concreta asociada a su objetivo, necesidad o proceso de decisión;
- un Caso agrupa una o más Oportunidades;
- varias Oportunidades pertenecen al mismo Caso cuando responden al mismo objetivo, necesidad o proceso de decisión y forman parte de un mismo desarrollo comercial conjunto, complementario o alternativo;
- la coincidencia temporal o de producto no basta por sí sola para unir o separar Casos;
- antes de identificar una Oportunidad puede existir una Relación Comercial o una condición Lead sin Oportunidad, pero todavía no existe un Caso;
- el Caso organiza el desarrollo comercial propio y no reemplaza las Oportunidades formales que pueda exigir la compañía.

Cardinalidad conceptual aprobada:

```text
Relación Comercial 1 ── 0..N Casos Comerciales
Caso Comercial     1 ── 1..N Oportunidades
```

### 2. Nacimiento, pertenencia y cardinalidad de la Oportunidad

Una Oportunidad representa una contratación potencial individualizable de un producto concreto para la cual existe un desarrollo comercial real que seguir.

Reglas:

- una necesidad general, interés difuso o conversación exploratoria sin producto potencial concreto no crea todavía una Oportunidad;
- la Oportunidad nace cuando se identifica un producto potencial concreto dentro de una Relación Comercial y existe una intención, necesidad o posibilidad comercial que justifica su seguimiento;
- toda Oportunidad presupone una Relación Comercial existente;
- toda Oportunidad pertenece exactamente a un Caso Comercial;
- no existen Oportunidades sueltas fuera de un Caso;
- la primera Oportunidad de un objetivo, necesidad o proceso de decisión origina o identifica simultáneamente el Caso correspondiente;
- una Persona puede mantener varios Casos y varias Oportunidades abiertas simultáneamente dentro de su única Relación Comercial;
- la Oportunidad conserva el desarrollo comercial de un producto concreto; el Caso conserva el objetivo, necesidad o proceso de decisión que explica por qué esa Oportunidad existe y cómo se relaciona con otras;
- toda reclasificación posterior de una Oportunidad entre Casos debe conservar historia.

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
- una diferencia impuesta por el CRM corporativo no redefine por sí sola el dominio propio;
- una Cotización pertenece exactamente a una Oportunidad;
- la Cotización no sustituye al Producto Contratado ni demuestra que la contratación ocurrió.

Cardinalidad conceptual aprobada:

```text
Oportunidad 1 ── 0..N Cotizaciones
Cotización  1 ── 1 Oportunidad
```

#### Antecedente de flexibilidad para el diseño lógico y físico

Una regla semánticamente correcta puede volverse excesivamente rígida si se traduce prematuramente en restricciones físicas irreversibles o bloqueos de interfaz basados en una taxonomía todavía incompleta.

Criterios orientadores:

- la base debe preservar la coherencia sin impedir correcciones o reclasificaciones trazables;
- una posible incompatibilidad entre productos o configuraciones debe poder advertirse antes de convertirse automáticamente en rechazo;
- la experiencia podrá pedir confirmación y ofrecer separar o reclasificar;
- toda separación, traslado o reclasificación debe conservar historia y referencias corporativas;
- flexibilidad no equivale a ausencia de modelo: toda excepción confirmada debe quedar explícita y trazable;
- no se aprueba todavía un mecanismo técnico concreto de advertencia, excepción u override.

El futuro diseño lógico debe distinguir entre invariantes del dominio, heurísticas de consistencia y advertencias de calidad de datos.

### 4. Propuesta como conocimiento descriptivo del Caso Comercial

La Propuesta representa lo que el Asesor decide presentar al cliente dentro de un Caso Comercial. Puede reunir una o más alternativas basadas en Oportunidades y Cotizaciones, pero en el modelo mínimo no constituye una entidad estructurada independiente.

Reglas:

- la Propuesta vive como descripción comprensible dentro del historial del Caso Comercial;
- el Asesor debe poder dejar por escrito qué presentó, por qué y en qué contexto, porque no puede depender de su memoria para reconstruirlo posteriormente;
- no se modelan combinaciones estructuradas de Oportunidades, Cotizaciones y alternativas de Propuesta;
- no se crean entidades `Propuesta`, `Alternativa de Propuesta`, `Versión de Propuesta` ni `Historial de Propuesta` en `next_v03`;
- las Oportunidades y Cotizaciones continúan siendo hechos estructurados independientes aunque sean mencionados en la descripción;
- preparar, enviar o presentar información puede registrarse mediante Tareas y Actividades vinculadas al Caso, con notas descriptivas y, cuando corresponda, referencias a documentos o archivos;
- la Actividad registra que la presentación o envío ocurrió; su nota puede describir el contenido presentado;
- un documento, correo, simulación o PDF puede conservarse como evidencia o referencia, pero no convierte automáticamente a la Propuesta en una entidad;
- el historial del Caso puede construirse desde Actividades, Tareas, notas y otros hechos vinculados sin crear una entidad técnica llamada `Historial`;
- el sistema no debe generar, enumerar ni validar combinatoriamente todas las propuestas posibles;
- el sistema tampoco debe exigir que toda descripción de lo presentado se descomponga en referencias estructuradas a cada Oportunidad o Cotización;
- si la operación futura demuestra una necesidad real de identidad, versionado, aceptación, vigencia, reutilización o trazabilidad regulatoria propia de la Propuesta, su promoción a entidad requerirá un LCD posterior.

Esta decisión refina la definición previa del Diccionario: `Propuesta` continúa siendo un concepto válido del lenguaje comercial, pero no toda noción del negocio debe transformarse en una entidad persistente y estructurada.

### 5. Pipeline operado por Caso y desagregado por Oportunidad

El Caso Comercial es la unidad de negocio, navegación y contexto operativo del Asesor. Las Oportunidades conservan su etapa individual porque distintas contrataciones del mismo Caso pueden avanzar, someterse, emitirse, descartarse o cerrarse en momentos distintos.

El Kanban no persiste tarjetas independientes. Cada tarjeta es una vista derivada del Caso Comercial y de las Oportunidades que comparten una misma etapa.

Reglas primarias:

1. **Caso unificado por defecto.** Cuando todas las Oportunidades de un Caso comparten etapa, el Kanban muestra una sola tarjeta del Caso.
2. **Movimiento principal simple.** Mover esa tarjeta cambia a la nueva etapa todas las Oportunidades representadas por ella.
3. **Separación explícita.** El Asesor puede entrar al Caso y mover una o más Oportunidades a otra etapa. Esta acción excepcional divide la representación del Caso en tarjetas vinculadas.
4. **Movimiento posterior a la separación.** Arrastrar una tarjeta dividida mueve sólo las Oportunidades que esa tarjeta representa.
5. **Movimiento total disponible.** `Mover todo el Caso` es una acción explícita que vuelve a mover conjuntamente todas sus Oportunidades, aunque estén distribuidas en varias etapas.
6. **Navegación única.** Todas las tarjetas vinculadas abren el mismo Caso Comercial; ninguna abre una subentidad aislada como destino principal.
7. **Sin duplicación de hechos.** La existencia de varias tarjetas no crea varios Casos ni duplica Oportunidades. La agrupación se deriva conceptualmente por `(Caso Comercial, etapa)`.
8. **Trazabilidad.** Todo cambio de etapa conserva la etapa anterior, la nueva, la fecha y el actor. No existen movimientos silenciosos.

Ejemplo:

```text
Caso Comercial: protección y ahorro de Ana

Propuesta
└── Vida Ahorro · 100 CNS proyectados

Sometida
└── APV · 40 CNS sometidos
```

Ambas tarjetas pertenecen al mismo Caso y abren su contexto completo.

#### Proyección y hechos reales de CNS

Los CNS proyectados representan una estimación comercial manual del Asesor. No se calculan automáticamente desde Cotizaciones ni mediante una fórmula obligatoria de probabilidades.

Reglas:

- el Caso posee una cifra manual de CNS proyectados;
- por defecto, la proyección se maneja como un único monto con una fecha prevista de sometimiento y una fecha prevista de emisión;
- cuando el Caso realmente requiera más de un monto o más de una fecha, el Asesor puede dividir manualmente la proyección en componentes temporales;
- al separar Oportunidades entre etapas, el sistema debe solicitar únicamente la distribución necesaria para evitar atribuir el mismo monto a más de una tarjeta;
- la suma de las distribuciones vigentes debe coincidir con el total manual proyectado del Caso;
- una separación redistribuye la proyección: no la recalcula desde productos, Cotizaciones ni probabilidades;
- CNS sometidos y CNS emitidos son hechos reales distintos de la proyección y conservan sus propias cantidades y fechas;
- una misma contratación puede registrar un sometimiento y una emisión en fechas diferentes, y un Caso puede contener varios sometimientos o emisiones;
- los indicadores por etapa y por período son cálculos derivados; nunca constituyen la fuente de verdad.

Conceptualmente deben distinguirse:

```text
Proyección manual vigente
≠ CNS efectivamente sometidos
≠ CNS efectivamente emitidos
```

La representación física de los componentes temporales de proyección y de los hechos reales de sometimiento y emisión se definirá durante el diseño lógico, no en este ADR.

#### Criterio de seguridad antes del diseño físico

Esta decisión no autoriza todavía tablas ni SQL. Antes de diseñar `next_v03`, el modelo deberá demostrar con casos de prueba que mantiene simultáneamente estas invariantes:

- cada Oportunidad pertenece a un único Caso y posee una única etapa actual;
- las tarjetas del Kanban se derivan y nunca se convierten en fuente de verdad;
- mover una tarjeta no duplica ni pierde Oportunidades;
- separar y volver a unificar conserva historia;
- la proyección manual no se duplica al aparecer el Caso en varias columnas;
- la suma de distribuciones de proyección coincide con el total vigente del Caso;
- proyección, sometimiento y emisión no se sobrescriben entre sí;
- los totales por etapa y período pueden reconstruirse exclusivamente desde hechos canónicos.

Si estas reglas no pueden expresarse mediante un conjunto pequeño de transiciones deterministas y pruebas reproducibles, el diseño físico deberá detenerse y simplificarse antes de crear tablas.

## Preguntas pendientes del lote

1. Cuáles son las etapas mínimas del Pipeline y cuáles de ellas son terminales.
2. Cómo se cierran, descartan, reemplazan, reclasifican o reabren Casos y Oportunidades sin borrar historia.
3. Cómo se vinculan opcionalmente Tareas y Actividades con Relación Comercial, Caso Comercial y Oportunidad.
4. Cómo representar el historial descriptivo del Caso sin crear entidades artificiales ni perder trazabilidad.
5. Cómo representar lógicamente la proyección manual, sus divisiones temporales y los hechos reales de sometimiento y emisión con el menor número de conceptos posible.
6. Cómo distinguir en el diseño lógico las restricciones verdaderamente invariantes de las advertencias o heurísticas de compatibilidad.

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
- estructura documental o de archivos definitiva para evidencias;
- cambios en APP LLAMADOS Legacy, DEV, STAGING o PROD.

## Consecuencias actuales

- `next_v03` continúa bloqueado para diseño físico definitivo;
- el Caso Comercial queda diferenciado de la Relación Comercial y de la Oportunidad;
- una Relación puede persistir sin Caso y un Caso no puede persistir sin al menos una Oportunidad asociada;
- toda Oportunidad pertenece exactamente a un Caso;
- la Oportunidad conserva una contratación potencial individualizable y la Cotización una configuración específica de esa contratación;
- alternativas mutuamente excluyentes permanecen en una Oportunidad, mientras contrataciones que pueden coexistir se representan como Oportunidades distintas;
- la Propuesta permanece como conocimiento descriptivo del Caso y no como entidad estructurada del modelo mínimo;
- el Caso es la unidad de negocio y navegación del Pipeline, mientras la etapa se conserva por Oportunidad;
- las tarjetas del Kanban son vistas derivadas agrupadas por Caso y etapa, no entidades persistentes;
- el flujo frecuente mantiene una sola tarjeta y un solo movimiento; la separación por Oportunidad es una acción secundaria explícita;
- los CNS proyectados son una estimación manual del Caso y no una fórmula automática;
- proyección, sometimiento y emisión se conservan como conceptos distintos;
- el diseño físico deberá probar las invariantes de movimiento, distribución y reconstrucción antes de crear tablas;
- el futuro diseño lógico no podrá convertir heurísticas evolutivas en bloqueos irreversibles sin una decisión posterior explícita;
- el Modelo Comercial y la Matriz de Validación incorporarán estas decisiones durante la consolidación del LCD;
- las demás hipótesis de este borrador no constituyen reglas del dominio hasta su aprobación explícita.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.
