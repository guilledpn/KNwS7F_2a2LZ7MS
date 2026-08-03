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
        └── Oportunidades
            └── Cotizaciones
```

La Propuesta no aparece como entidad estructurada. El contenido que el Asesor decide presentar vive de forma descriptiva en el historial del Caso Comercial y puede quedar respaldado por Actividades, notas y documentos asociados.

El Caso Comercial representa un negocio indivisible y constituye la unidad canónica del Pipeline. Posee una sola etapa actual, una sola tarjeta operativa y un resultado final de Ganado o Perdido. Las Oportunidades y Cotizaciones explican qué productos y configuraciones fueron evaluados dentro del negocio, pero no fragmentan su posición operativa.

## Decisiones aprobadas

### 1. Origen y criterio de agrupación del Caso Comercial

Un Caso Comercial representa un negocio concreto dentro de una Relación Comercial: un proceso de decisión que el Asesor administra y espera resolver como una unidad.

Reglas:

- una Relación Comercial puede existir sin Casos Comerciales;
- una Relación Comercial puede contener varios Casos simultáneos o sucesivos;
- un Caso puede nacer en etapa `Nuevo` antes de identificar una Oportunidad concreta;
- para nacer, el Caso debe estar vinculado a una Persona y poseer un Asesor propietario;
- un Caso puede agrupar cero, una o varias Oportunidades según su grado de definición y avance;
- varias Oportunidades pueden permanecer en un mismo Caso cuando son alternativas o componentes cuya decisión y avance se administran conjuntamente;
- la coincidencia de Persona, objetivo, necesidad, fecha o producto no basta por sí sola para unir Casos;
- dos desarrollos que necesitan avanzar, someterse, emitirse, ganarse o perderse de manera independiente deben constituir Casos distintos;
- el Caso organiza el desarrollo comercial propio y no reemplaza las oportunidades formales que pueda exigir la compañía.

Cardinalidad conceptual aprobada:

```text
Relación Comercial 1 ── 0..N Casos Comerciales
Caso Comercial     1 ── 0..N Oportunidades
```

La cardinalidad anterior `Caso Comercial 1 ── 1..N Oportunidades` queda sustituida: la etapa `Nuevo` permite registrar la existencia del negocio antes de completar sus definiciones.

### 2. Nacimiento, pertenencia y cardinalidad de la Oportunidad

Una Oportunidad representa una contratación potencial individualizable de un producto concreto evaluado dentro de un Caso Comercial.

Reglas:

- una necesidad general, interés difuso o conversación exploratoria sin producto potencial concreto no crea todavía una Oportunidad;
- la Oportunidad nace cuando se identifica un producto potencial concreto y existe una posibilidad comercial que justifica evaluarlo;
- toda Oportunidad presupone una Relación Comercial y un Caso Comercial existentes;
- toda Oportunidad pertenece exactamente a un Caso Comercial en cada momento;
- no existen Oportunidades sueltas fuera de un Caso;
- una Persona puede mantener varios Casos y varias Oportunidades simultáneamente dentro de su única Relación Comercial;
- la Oportunidad conserva la identidad del producto potencial; el Caso conserva la identidad del negocio;
- mientras el Caso permanece activo, las Oportunidades son alternativas o componentes candidatos del negocio, no unidades independientes del Pipeline;
- al ganarse el Caso, las Oportunidades contratadas quedan identificadas como ganadas y las restantes quedan descartadas históricamente;
- al perderse el Caso, ninguna Oportunidad resulta ganada;
- toda reclasificación o traslado posterior de una Oportunidad entre Casos debe conservar historia, origen, fecha y actor.

Cardinalidad conceptual aprobada:

```text
Caso Comercial 1 ── 0..N Oportunidades
Oportunidad    1 ── 1 Caso Comercial actual
```

### 3. Distinción entre Oportunidad y Cotización

Una Cotización representa una configuración específica de una Oportunidad. La Oportunidad conserva la identidad de la contratación potencial; las Cotizaciones representan alternativas concretas para materializarla.

Reglas:

- una Oportunidad puede existir antes de registrar su primera Cotización y posteriormente tener una o varias;
- dos Cotizaciones pertenecen a la misma Oportunidad cuando son configuraciones mutuamente excluyentes de una única contratación potencial;
- capital asegurado, prima, cobertura, régimen, aporte, costo, plazo u otra configuración distinta no crean por sí solos una nueva Oportunidad;
- dos desarrollos constituyen Oportunidades distintas cuando representan contrataciones individualizables que podrían celebrarse y persistir simultáneamente;
- pueden existir varias Oportunidades del mismo producto cuando representan contrataciones distintas;
- una diferencia impuesta por el CRM corporativo no redefine por sí sola el dominio propio;
- una Cotización pertenece exactamente a una Oportunidad;
- la Cotización no sustituye al Producto Contratado ni demuestra que la contratación ocurrió;
- cuando una Oportunidad se gana, queda identificada la Cotización elegida cuando corresponda y las demás Cotizaciones de esa Oportunidad quedan descartadas;
- las Cotizaciones no seleccionadas permanecen como antecedentes históricos de lo evaluado.

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

La etapa `Propuesta` del Pipeline no transforma a la Propuesta en una entidad. Sólo expresa que el negocio alcanzó un grado de elaboración que permite considerarlo como una propuesta comercial.

### 5. Caso Comercial como unidad indivisible del Pipeline

El Caso Comercial es la unidad canónica del Pipeline, de la navegación operativa y de la medición de CNS por etapa. Un Caso representa un solo negocio y ocupa íntegramente una sola etapa actual.

#### Etapa operativa

Reglas:

1. cada Caso posee exactamente una etapa actual mientras está activo;
2. el Kanban muestra una sola tarjeta por Caso;
3. mover la tarjeta cambia la etapa del Caso completo;
4. las Oportunidades no poseen etapas independientes dentro del Pipeline;
5. un Caso no puede aparecer simultáneamente en dos columnas;
6. las tarjetas del Kanban son vistas derivadas del Caso y nunca constituyen una fuente de verdad independiente;
7. todo cambio de etapa conserva etapa anterior, etapa nueva, fecha y actor;
8. la capa operativa debe responder directamente cuántos negocios y cuántos CNS se encuentran en cada etapa, usando el lenguaje habitual del Asesor.

No se utilizarán como lenguaje operativo principal categorías abstractas como `terminal`, `no terminal`, `concretado` o `no concretado`. El Asesor trabaja con negocios en etapas reconocibles, negocios ganados, negocios perdidos y CNS por etapa.

#### Resultado del Caso

El Caso posee un resultado final inequívoco:

```text
Ganado
Perdido
```

Reglas:

- un Caso está Ganado cuando alcanza la etapa `Emitido`;
- `Emitido` exige que al menos una Oportunidad haya sido plenamente aceptada por la compañía y se haya convertido en un producto vigente;
- un Caso está Perdido cuando se cierra sin obtener ninguna contratación;
- no existe un resultado de `parcialmente ganado`;
- obtener más o menos CNS que los proyectados modifica la realidad económica del Caso, pero no su condición de Ganado;
- al ganarse el Caso, se identifican las Oportunidades ganadas y las demás quedan descartadas;
- al perderse el Caso, todas sus Oportunidades quedan históricamente en el camino y ninguna se transforma en contratación;
- si una Oportunidad conserva una posibilidad comercial independiente después del cierre del Caso, debe originar un nuevo Caso antes de continuar su propio desarrollo;
- la reapertura, corrección o anulación de un resultado deberá conservar historia y se definirá antes del diseño físico.

Un Caso puede ganar más de una Oportunidad cuando las contrataciones se resuelven conjuntamente como parte del mismo negocio. Si el Asesor advierte que dos Oportunidades podrían ganarse en momentos distintos o requerir seguimientos independientes, debe separarlas en Casos distintos en lugar de mantener un Pipeline fragmentado.

#### Separación excepcional de una Oportunidad en un nuevo Caso

La posibilidad de que una Oportunidad inicialmente evaluada dentro de un Caso necesite avanzar con tiempos propios es real, pero extraordinaria y estadísticamente poco significativa. No debe imponer complejidad permanente al flujo normal.

Reglas:

- el flujo principal conserva un Caso indivisible;
- el Asesor puede separar explícitamente una Oportunidad y originar con ella un nuevo Caso;
- la Oportunidad deja de pertenecer al Caso anterior y pasa a pertenecer al nuevo Caso, conservando trazabilidad de origen;
- el nuevo Caso adquiere desde ese momento su propia etapa, proyección, resultado e historial operativo;
- la separación no duplica la Oportunidad, las Cotizaciones ni los CNS;
- el Caso de origen conserva el antecedente de que la Oportunidad fue evaluada inicialmente dentro de él;
- esta capacidad debe exponerse mediante divulgación progresiva y no complicar la interfaz habitual;
- los detalles físicos y de interfaz de la separación se decidirán después de validar las transiciones conceptuales.

La regla de simplificación es:

> Si dos desarrollos necesitan ocupar etapas diferentes o resolverse en tiempos independientes, son dos Casos Comerciales.

### 6. Etapas mínimas del Pipeline y requisitos de avance

El recorrido operativo normal del Caso Comercial es:

```text
Nuevo
→ Pendiente
→ Propuesta
→ En Firma
→ Sometido
→ Emitido
```

La secuencia describe el avance habitual del negocio. Las correcciones, retrocesos excepcionales, reaperturas y saltos justificados deberán conservar trazabilidad y se precisarán antes del diseño físico.

#### Nuevo

Permite registrar que existe un negocio aunque todavía falten sus definiciones.

Requisitos mínimos:

- Persona vinculada al Caso;
- Asesor propietario del negocio.

No requiere Oportunidades, Cotizaciones, proyección de CNS ni fechas estimadas.

#### Pendiente

Permite registrar que existe información suficiente para comenzar a elaborar una propuesta.

Requisitos mínimos:

- Persona vinculada al Caso;
- Asesor propietario del negocio.

No incorpora un bloqueo estructural adicional. Operativamente, el Asesor debiera haber dejado información descriptiva suficiente para retomar y continuar la elaboración, pero su ausencia no impide el cambio de etapa.

#### Propuesta

Permite registrar que existe una propuesta elaborada y potencialmente presentada al cliente.

Requisitos:

- proyección vigente de CNS;
- fecha estimada de sometimiento;
- fecha estimada de emisión.

La etapa no exige obligatoriamente una Cotización. Si el sistema detecta que ninguna Oportunidad posee una Cotización, debe solicitar confirmación al Asesor antes de completar el cambio, sin convertir esa ausencia en un bloqueo rígido.

#### En Firma

Permite registrar que el cliente aceptó una o más alternativas y se encuentra firmando la documentación contractual correspondiente.

Requisitos:

- proyección vigente de CNS;
- fecha estimada de sometimiento;
- fecha estimada de emisión;
- una o más Oportunidades aceptadas por el cliente;
- cada Oportunidad aceptada debe poseer una Cotización vigente seleccionada.

Las Oportunidades y Cotizaciones no seleccionadas permanecen como antecedentes históricos y dejan de formar parte de la configuración que está en firma.

#### Sometido

Permite registrar que el cliente aceptó y firmó uno o más contratos y que el negocio está siendo evaluado por la compañía o se encuentra a la espera de antecedentes adicionales.

Requisitos:

- una o más Oportunidades con documentación contractual firmada por el cliente;
- CNS efectivamente sometidos;
- fecha efectiva de sometimiento;
- proyección de CNS y fechas estimadas previamente registradas.

Ingresar a `Sometido` constituye una transición factual: registrar el sometimiento y cambiar la etapa forman una sola operación de negocio.

#### Emitido

Permite registrar que una o más contrataciones fueron plenamente aceptadas por la compañía y se transformaron en productos vigentes entre la compañía y el cliente, intermediados por el Asesor propietario del negocio.

Requisitos:

- una o más Oportunidades con contrato firmado por el cliente y aceptado por la compañía;
- identificación de las Oportunidades ganadas y de las Cotizaciones seleccionadas cuando corresponda;
- CNS efectivamente emitidos;
- fecha efectiva de emisión.

Ingresar a `Emitido` constituye una transición factual y determina automáticamente el resultado `Ganado` del Caso.

#### Proyección y fechas estimadas

La proyección manual de CNS, la fecha estimada de sometimiento y la fecha estimada de emisión:

- pueden registrarse opcionalmente desde `Nuevo` o `Pendiente`;
- son obligatorias desde `Propuesta` en adelante;
- pueden revisarse con trazabilidad cuando cambie la expectativa comercial;
- no se recalculan automáticamente desde Cotizaciones ni probabilidades.

#### Pérdida del negocio

`Perdido` no constituye una etapa adicional del Pipeline. Es un resultado de cierre alternativo a `Ganado`.

Reglas:

- un Caso puede marcarse `Perdido` desde cualquier etapa anterior a `Emitido`;
- al perderse, sale del Pipeline activo y conserva la última etapa alcanzada;
- debe conservar fecha y motivo de pérdida;
- conserva su proyección, Oportunidades, Cotizaciones, Actividades y demás antecedentes;
- ninguna Oportunidad del Caso se transforma en producto vigente;
- un Caso en `Emitido` no puede marcarse simplemente como `Perdido`; cualquier corrección o anulación posterior requiere una operación trazable específica.

Ejemplo:

```text
Última etapa alcanzada: En Firma
Resultado: Perdido
Motivo: cliente desistió
```

#### Movimientos, correcciones y reapertura

El modelo distingue entre movimiento operativo normal y corrección de un hecho factual.

Reglas:

- un Caso puede avanzar o retroceder normalmente entre `Nuevo`, `Pendiente`, `Propuesta` y `En Firma`, siempre que cumpla los requisitos de la etapa de destino;
- estos movimientos conservan etapa anterior, etapa nueva, fecha y actor, pero no requieren un motivo obligatorio;
- ingresar a `Sometido` exige registrar el sometimiento real y ambos efectos forman una sola operación de negocio;
- ingresar a `Emitido` exige registrar la emisión real, ambos efectos forman una sola operación y el Caso queda `Ganado`;
- abandonar `Sometido` hacia una etapa anterior es una corrección excepcional y exige motivo;
- el sometimiento histórico permanece registrado salvo que el propio hecho sea corregido o anulado explícitamente;
- un Caso `Emitido` no puede moverse mediante el flujo ordinario;
- corregir o anular una emisión exige una operación explícita, con motivo y trazabilidad, que preserve el hecho original y sus consecuencias;
- un Caso `Perdido` puede reabrirse dejando sin efecto su resultado vigente y recuperando la última etapa alcanzada;
- la reapertura conserva el cierre anterior y registra fecha, actor y motivo;
- no se crean estados adicionales ni una maquinaria paralela de versiones para representar estas correcciones.

La regla consolidada es:

> Los Casos pueden avanzar y retroceder normalmente entre Nuevo, Pendiente, Propuesta y En Firma, conservando historial. Sometido y Emitido requieren los hechos reales que los fundamentan. Abandonar una etapa factual constituye una corrección explícita y trazable, no un movimiento ordinario. Un Caso Perdido puede reabrirse recuperando su última etapa, mientras un Caso Emitido sólo puede modificarse mediante rectificación o anulación de la emisión.

### 7. Proyección y hechos reales de CNS

Los CNS constituyen una magnitud comercial y no una entidad autónoma. El Caso conserva la posición operativa de CNS correspondiente a su etapa actual y mantiene separados los antecedentes históricos de proyección, sometimiento y emisión.

Reglas:

- el Caso posee una proyección manual de CNS ingresada por el Asesor;
- la proyección no se calcula automáticamente desde Cotizaciones ni probabilidades;
- la proyección inicial se conserva como antecedente histórico;
- los CNS sometidos y los CNS emitidos son hechos reales distintos, con sus cantidades y fechas;
- ingresar a `Sometido` exige registrar el sometimiento real que fundamenta la etapa;
- ingresar a `Emitido` exige registrar la emisión real que fundamenta la etapa;
- registrar el hecho y cambiar la etapa constituyen una única operación de negocio: se aplican íntegramente o no se aplican;
- para la posición vigente, el Caso aporta CNS únicamente a su etapa actual;
- al avanzar el Caso, deja de aportar CNS a la etapa anterior;
- los valores anteriores permanecen disponibles como historia, pero no se suman nuevamente al stock vigente;
- una diferencia entre CNS proyectados, sometidos y emitidos refleja la evolución o modificación real del negocio y no crea saldos parciales entre etapas;
- los reportes de flujo pueden mostrar sometimientos y emisiones ocurridos durante un período como hechos distintos, pero no deben sumarlos como producción independiente;
- la estadística se deriva de los hechos canónicos y no gobierna la operación.

#### Representación conceptual mínima

El modelo mínimo distingue exactamente tres clases de información del Caso:

1. **Proyección vigente.** Contiene el monto manual de CNS proyectados, la fecha estimada de sometimiento y la fecha estimada de emisión. Puede revisarse durante el desarrollo comercial. La revisión más reciente gobierna la proyección operativa y cada valor anterior permanece trazable con fecha y actor.
2. **Sometimiento real.** Registra el monto efectivamente sometido y su fecha efectiva. Fundamenta la etapa `Sometido` y no reemplaza ni reescribe la proyección.
3. **Emisión real.** Registra el monto efectivamente emitido y su fecha efectiva. Fundamenta la etapa `Emitido`, determina el resultado `Ganado` y no reemplaza ni reescribe el sometimiento.

Reglas adicionales:

- no se crea una entidad autónoma `CNS` ni una estructura paralela de versiones;
- la proyección vigente pertenece al Caso completo y no se distribuye entre Oportunidades;
- una revisión modifica la expectativa actual, no los hechos reales ya ocurridos;
- los hechos de sometimiento y emisión sólo se corrigen o anulan mediante operaciones explícitas y trazables que conservan el registro original;
- para el stock operativo, el Caso usa la magnitud correspondiente a su etapa actual;
- para análisis histórico, proyección, sometimiento y emisión pueden compararse como valores sucesivos del mismo negocio, pero nunca sumarse como si fueran producción independiente.

La regla consolidada es:

> El Caso conserva una proyección vigente revisable con historial, un sometimiento real y una emisión real. Son tres hechos conceptualmente distintos, suficientes para operar el Pipeline y medir desviaciones sin crear entidades ni saldos adicionales.

Ejemplo:

```text
Caso Comercial: Protección y ahorro de Ana

Proyección inicial: 140 CNS
Sometimiento real: 135 CNS
Emisión real: 128 CNS
Etapa actual: Emitido
Resultado: Ganado
```

La posición vigente computa 128 CNS en `Emitido`. Los 140 CNS proyectados y los 135 CNS sometidos se conservan como antecedentes para medir desviaciones, pero no permanecen ocupando columnas anteriores.

### 8. Oportunidades y Cotizaciones al resolverse el negocio

Cuando el Caso se gana:

```text
Caso Ganado
├── Oportunidad ganada
│   └── Cotización seleccionada
├── Oportunidad ganada opcional
│   └── Cotización seleccionada
└── Oportunidades descartadas
    └── Cotizaciones no seleccionadas
```

Reglas:

- una Oportunidad ganada identifica la contratación obtenida;
- las Oportunidades no ganadas quedan descartadas dentro de ese Caso;
- cuando una Oportunidad posee varias Cotizaciones, la elegida queda identificada y las demás se descartan;
- los descartes no borran los antecedentes ni requieren crear entidades adicionales;
- una Oportunidad descartada sólo puede continuar comercialmente si se separa trazablemente en un nuevo Caso;
- el Producto Contratado, cuando corresponda, será el resultado persistente de la Oportunidad ganada y no será sustituido por la Cotización.

### 9. Decisiones sustituidas dentro de este mismo borrador

Las decisiones aprobadas en este ADR reemplazan expresamente las hipótesis intermedias del presente LCD que proponían:

- exigir al menos una Oportunidad para crear un Caso;
- conservar una etapa individual por Oportunidad;
- mostrar varias tarjetas del mismo Caso en distintas columnas;
- dividir o reunir tarjetas del Caso según la etapa de sus Oportunidades;
- distribuir la proyección del Caso entre tarjetas u Oportunidades para representar etapas simultáneas;
- mantener saldos parciales de CNS entre etapas;
- derivar el cierre del Caso desde una mezcla de resultados independientes de sus Oportunidades;
- considerar `Perdido` como una etapa adicional del recorrido ordinario.

Esas hipótesis quedan descartadas y no deben trasladarse al Modelo Comercial, a la Matriz de Validación ni al diseño físico.

### 10. Criterio de seguridad antes del diseño físico

Esta decisión no autoriza todavía tablas ni SQL. Antes de diseñar `next_v03`, el modelo deberá demostrar mediante transiciones deterministas y pruebas reproducibles que mantiene simultáneamente estas invariantes:

- cada Caso pertenece a una Relación Comercial, está vinculado a una Persona y posee un Asesor propietario;
- un Caso puede existir sin Oportunidades en sus primeras etapas;
- cada Oportunidad pertenece exactamente a un Caso actual;
- cada Caso activo posee una única etapa actual;
- cada Caso aparece una sola vez en el Pipeline;
- mover un Caso no duplica ni pierde Oportunidades, Cotizaciones o CNS;
- `Propuesta`, `En Firma`, `Sometido` y `Emitido` poseen los requisitos mínimos aprobados;
- los movimientos ordinarios entre `Nuevo`, `Pendiente`, `Propuesta` y `En Firma` conservan historia y respetan los requisitos de destino;
- una etapa factual no existe sin el hecho real que la fundamenta;
- la transición hacia una etapa factual se aplica íntegramente o no se aplica;
- abandonar `Sometido` exige una corrección explícita y motivada;
- un Caso `Emitido` sólo puede cambiar mediante rectificación o anulación explícita de la emisión;
- reabrir un Caso `Perdido` recupera su última etapa y conserva íntegramente el cierre anterior;
- existe una sola proyección vigente del Caso, cuyas revisiones conservan historia;
- el sometimiento real y la emisión real son hechos distintos que no se sobrescriben entre sí ni reescriben la proyección;
- corregir o anular un sometimiento o una emisión conserva el hecho original y la trazabilidad de la corrección;
- el stock vigente computa cada Caso y sus CNS en una sola etapa;
- la proyección inicial se conserva como antecedente y no se suma como producción adicional;
- las diferencias entre proyección, sometimiento y emisión no crean saldos parciales;
- un Caso en `Emitido` posee al menos una Oportunidad ganada y su resultado es `Ganado`;
- un Caso `Perdido` no posee Oportunidades ganadas y conserva su última etapa alcanzada;
- al ganar una Oportunidad se identifica la Cotización seleccionada cuando corresponda y las restantes quedan descartadas;
- separar una Oportunidad en un nuevo Caso no duplica hechos y conserva su origen;
- dos desarrollos que requieren etapas o tiempos independientes pertenecen a Casos distintos;
- los totales por etapa y período pueden reconstruirse exclusivamente desde hechos canónicos.

Si estas reglas no pueden expresarse mediante un conjunto pequeño de transiciones deterministas y pruebas reproducibles, el diseño físico deberá detenerse y simplificarse antes de crear tablas.

## Preguntas pendientes del lote

1. Cómo se vinculan opcionalmente Tareas y Actividades con Relación Comercial, Caso Comercial y Oportunidad.
2. Cómo representar el historial descriptivo del Caso sin crear entidades artificiales ni perder trazabilidad.
3. Cómo se materializa la separación trazable de una Oportunidad en un nuevo Caso.
4. Cómo se relacionan la Oportunidad ganada, la Cotización seleccionada y el Producto Contratado.
5. Cómo distinguir en el diseño lógico las restricciones verdaderamente invariantes de las advertencias o heurísticas de compatibilidad.

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
- una Relación puede persistir sin Caso y un Caso puede existir inicialmente sin Oportunidades;
- toda Oportunidad pertenece exactamente a un Caso actual y puede trasladarse sólo con trazabilidad;
- la Oportunidad conserva una contratación potencial individualizable y la Cotización una configuración específica;
- la Propuesta permanece como conocimiento descriptivo del Caso y no como entidad estructurada;
- el Caso es la unidad indivisible del Pipeline, posee una sola etapa y aparece en una sola tarjeta;
- las etapas mínimas son `Nuevo`, `Pendiente`, `Propuesta`, `En Firma`, `Sometido` y `Emitido`;
- la proyección de CNS y las fechas estimadas son obligatorias desde `Propuesta`;
- `En Firma`, `Sometido` y `Emitido` exigen evidencia creciente de aceptación del cliente y de la compañía;
- `Emitido` determina el resultado `Ganado`;
- `Perdido` es un resultado de cierre y conserva la última etapa alcanzada;
- los movimientos ordinarios previos a `Sometido` son reversibles con historial, mientras las etapas factuales sólo se corrigen mediante operaciones explícitas;
- un Caso `Perdido` puede reabrirse sin borrar su cierre anterior y un Caso `Emitido` sólo puede rectificarse o anularse de forma trazable;
- las Oportunidades ganadas identifican las contrataciones obtenidas y las demás quedan descartadas;
- las Cotizaciones no seleccionadas permanecen como antecedentes históricos;
- los CNS proyectados son una estimación manual del Caso y no una fórmula automática;
- el Caso conserva una proyección vigente con historial de revisiones, un sometimiento real y una emisión real como hechos distintos;
- la proyección, el sometimiento y la emisión no se sobrescriben ni se duplican en la posición vigente;
- una Oportunidad que necesite tiempos independientes origina un nuevo Caso en vez de fragmentar el Pipeline;
- las situaciones extraordinarias se resuelven mediante una capacidad excepcional trazable y no mediante complejidad permanente del modelo;
- el Modelo Comercial y la Matriz de Validación incorporarán estas decisiones durante la consolidación del LCD;
- las demás hipótesis de este borrador no constituyen reglas del dominio hasta su aprobación explícita.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.
