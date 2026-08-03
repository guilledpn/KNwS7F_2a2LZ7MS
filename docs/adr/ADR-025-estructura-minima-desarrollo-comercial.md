# ADR-025 · Estructura mínima del desarrollo comercial

- Fecha: 2026-08-02
- Estado: <span style="color:red">Borrador · pendiente de revisión</span>
- LCD: LCD-20260802-01
- Issue: #34

## Contexto

ADR-024 estableció que el esquema físico `next_v03` no puede congelarse antes de definir el modelo mínimo de desarrollo comercial.

El Modelo Comercial aprobado ya contiene Persona, Relación Comercial, Tarea y Actividad. Este ADR completa el modelo mínimo de:

- Caso Comercial;
- Oportunidad;
- Cotización;
- Propuesta;
- Pipeline;
- CNS proyectados, sometidos y emitidos;
- Producto Contratado;
- vínculos opcionales de Tareas y Actividades con el desarrollo comercial.

El Diccionario del Dominio y `APP LLAMADOS · Modelo de negocio` constituyen antecedentes canónicos. Este LCD consolida esos antecedentes, resuelve vacíos y sustituye expresamente las hipótesis incompatibles surgidas durante el descubrimiento.

## 1. Estructura conceptual aprobada

```text
Persona
└── Relación Comercial
    └── Caso Comercial
        └── Oportunidades
            └── Cotizaciones
                └── Producto Contratado, cuando la Oportunidad se gana
```

La Propuesta permanece como conocimiento descriptivo del Caso y no como entidad estructurada.

El Caso Comercial representa un negocio indivisible y constituye la unidad canónica del Pipeline. Posee una sola etapa actual, una sola tarjeta operativa y un resultado final de Ganado o Perdido.

## 2. Caso Comercial

Un Caso Comercial representa un negocio concreto dentro de una Relación Comercial: un proceso de decisión que el Asesor administra y espera resolver como una unidad.

Reglas:

- una Relación Comercial puede existir sin Casos;
- una Relación Comercial puede contener varios Casos simultáneos o sucesivos;
- un Caso puede nacer en `Nuevo` antes de identificar una Oportunidad concreta;
- para nacer, el Caso debe estar vinculado a una Persona y poseer un Asesor propietario;
- un Caso puede contener cero, una o varias Oportunidades;
- varias Oportunidades pueden permanecer en un mismo Caso cuando son alternativas o componentes cuya decisión y avance se administran conjuntamente;
- dos desarrollos que necesiten etapas, tiempos, sometimientos, emisiones o resultados independientes deben constituir Casos distintos;
- la coincidencia de Persona, objetivo, fecha o producto no basta por sí sola para unir Casos;
- el Caso organiza el desarrollo comercial propio y no reemplaza las oportunidades formales exigidas por sistemas corporativos.

Cardinalidad conceptual:

```text
Relación Comercial 1 ── 0..N Casos Comerciales
Caso Comercial     1 ── 0..N Oportunidades
```

## 3. Oportunidad

Una Oportunidad representa una contratación potencial individualizable de un producto concreto evaluado dentro de un Caso.

Reglas:

- una necesidad general o conversación exploratoria sin producto potencial concreto no crea una Oportunidad;
- la Oportunidad nace cuando existe un producto potencial concreto y una posibilidad comercial que justifica evaluarlo;
- toda Oportunidad presupone una Relación Comercial y un Caso existentes;
- toda Oportunidad pertenece exactamente a un Caso actual;
- no existen Oportunidades sueltas fuera de un Caso;
- la Oportunidad conserva la identidad de la contratación potencial; el Caso conserva la identidad del negocio;
- mientras el Caso permanece activo, las Oportunidades son alternativas o componentes candidatos, no unidades independientes del Pipeline;
- al ganarse el Caso, las Oportunidades contratadas quedan identificadas como ganadas y las restantes quedan descartadas históricamente;
- al perderse el Caso, ninguna Oportunidad resulta ganada;
- todo traslado de una Oportunidad entre Casos conserva origen, fecha, actor e historia.

Cardinalidad:

```text
Caso Comercial 1 ── 0..N Oportunidades
Oportunidad    1 ── 1 Caso Comercial actual
```

## 4. Cotización

Una Cotización representa una configuración específica de una Oportunidad.

Reglas:

- una Oportunidad puede existir antes de su primera Cotización y luego tener una o varias;
- varias Cotizaciones pertenecen a la misma Oportunidad cuando son configuraciones mutuamente excluyentes de una única contratación potencial;
- diferencias de capital, prima, cobertura, régimen, aporte, costo, plazo u otra configuración no crean por sí solas una nueva Oportunidad;
- existen Oportunidades distintas cuando representan contratos individualizables que podrían celebrarse y persistir simultáneamente;
- pueden existir varias Oportunidades del mismo producto;
- una diferencia impuesta por un CRM corporativo no redefine el dominio propio;
- cada Cotización pertenece exactamente a una Oportunidad;
- una Cotización no sustituye al Producto Contratado ni demuestra que la contratación ocurrió;
- cuando una Oportunidad se gana, queda identificada una única Cotización seleccionada y las demás permanecen descartadas como antecedentes históricos.

Cardinalidad:

```text
Oportunidad 1 ── 0..N Cotizaciones
Cotización  1 ── 1 Oportunidad
```

### Flexibilidad para el diseño lógico

El diseño debe distinguir entre:

- invariantes del dominio;
- advertencias de consistencia;
- recomendaciones operativas.

Una taxonomía todavía incompleta no debe transformarse prematuramente en una restricción física irreversible. Las reclasificaciones y excepciones confirmadas deben conservar trazabilidad.

## 5. Propuesta

La Propuesta representa lo que el Asesor decide presentar al cliente dentro de un Caso.

En el modelo mínimo:

- vive como descripción comprensible dentro del Caso;
- puede apoyarse en Oportunidades, Cotizaciones, Tareas, Actividades, notas y documentos;
- no constituye una entidad estructurada independiente;
- no se crean entidades `Propuesta`, `Alternativa de Propuesta`, `Versión de Propuesta`, `Composición de Propuesta` ni `Historial de Propuesta`;
- preparar, enviar o presentar información puede registrarse mediante Tareas y Actividades vinculadas al Caso;
- un documento, correo, simulación o PDF puede conservarse como evidencia, pero no convierte automáticamente la Propuesta en entidad;
- el sistema no debe generar ni validar combinatoriamente todas las propuestas posibles;
- si la operación futura exige identidad, versionado, aceptación, vigencia, reutilización o trazabilidad regulatoria propia, su promoción a entidad requerirá otro LCD.

La etapa `Propuesta` del Pipeline expresa el grado de elaboración del negocio y no modifica esta decisión.

## 6. Pipeline, etapa y resultado del Caso

El Caso es la unidad canónica del Pipeline, de la navegación operativa y de la medición de CNS por etapa.

Reglas:

- cada Caso activo posee exactamente una etapa actual;
- el Kanban muestra una sola tarjeta por Caso;
- mover la tarjeta cambia la etapa del Caso completo;
- las Oportunidades no poseen etapas independientes;
- un Caso no puede aparecer simultáneamente en dos columnas;
- la tarjeta es una vista derivada y no una fuente de verdad;
- todo cambio de etapa conserva etapa anterior, etapa nueva, fecha y actor;
- la capa operativa debe responder cuántos negocios y cuántos CNS existen en cada etapa usando lenguaje comercial reconocible.

No se utilizarán como lenguaje operativo principal categorías abstractas como `terminal`, `no terminal`, `concretado` o `no concretado`.

### Resultado

```text
Ganado
Perdido
```

- un Caso está Ganado cuando alcanza `Emitido`;
- un Caso está Perdido cuando se cierra sin obtener ninguna contratación;
- no existe `parcialmente ganado`;
- emitir más o menos CNS que los proyectados no altera la condición de Ganado;
- un Caso Ganado identifica sus Oportunidades ganadas y descarta históricamente las restantes;
- un Caso Perdido no posee Oportunidades ganadas;
- una Oportunidad que conserve una posibilidad independiente después del cierre debe separarse en otro Caso antes de continuar.

Un Caso puede ganar más de una Oportunidad cuando las contrataciones se resuelven conjuntamente. Si podrían ganarse en momentos distintos o requerir seguimientos independientes, deben ser Casos distintos.

## 7. Etapas mínimas

```text
Nuevo
→ Pendiente
→ Propuesta
→ En Firma
→ Sometido
→ Emitido
```

### Nuevo

Significa que existe un negocio, aunque aún falten sus definiciones.

Requiere únicamente:

- Persona vinculada;
- Asesor propietario.

No requiere Oportunidades, Cotizaciones, CNS ni fechas estimadas.

### Pendiente

Significa que existe información suficiente para comenzar a elaborar una propuesta.

Requiere únicamente:

- Persona vinculada;
- Asesor propietario.

El Asesor debiera dejar información descriptiva suficiente para retomar el trabajo, pero su ausencia no bloquea la etapa.

### Propuesta

Significa que existe una propuesta elaborada y potencialmente presentada al cliente.

Requiere:

- proyección vigente de CNS;
- fecha estimada de sometimiento;
- fecha estimada de emisión.

No exige una Cotización. Si ninguna Oportunidad posee una Cotización, el sistema debe solicitar confirmación sin bloquear rígidamente el cambio.

### En Firma

Significa que el cliente aceptó una o más alternativas y está firmando.

Requiere:

- proyección vigente de CNS;
- fecha estimada de sometimiento;
- fecha estimada de emisión;
- una o más Oportunidades aceptadas por el cliente;
- una Cotización vigente seleccionada para cada Oportunidad aceptada.

Las alternativas no seleccionadas permanecen como antecedentes históricos.

### Sometido

Significa que el cliente aceptó y firmó uno o más contratos y que la compañía los está evaluando o espera antecedentes.

Requiere:

- una o más Oportunidades con documentación contractual firmada por el cliente;
- CNS efectivamente sometidos;
- fecha efectiva de sometimiento;
- proyección y fechas estimadas previamente registradas.

Registrar el sometimiento y cambiar la etapa constituyen una única operación de negocio.

### Emitido

Significa que una o más contrataciones fueron plenamente aceptadas por la compañía y se transformaron en productos vigentes.

Requiere:

- una o más Oportunidades con contrato firmado y aceptado por la compañía;
- identificación de las Oportunidades ganadas;
- una Cotización seleccionada para cada Oportunidad ganada;
- un Producto Contratado por cada Oportunidad ganada;
- CNS efectivamente emitidos;
- fecha efectiva de emisión.

Registrar la emisión y cambiar la etapa constituyen una única operación y determinan automáticamente el resultado `Ganado`.

### Proyección y fechas

La proyección de CNS, la fecha estimada de sometimiento y la fecha estimada de emisión:

- son opcionales en `Nuevo` y `Pendiente`;
- son obligatorias desde `Propuesta`;
- pueden revisarse con trazabilidad;
- no se calculan automáticamente desde Cotizaciones ni probabilidades.

### Perdido

`Perdido` no es una etapa.

- puede registrarse desde cualquier etapa anterior a `Emitido`;
- el Caso sale del Pipeline activo y conserva la última etapa alcanzada;
- conserva fecha y motivo de pérdida;
- conserva proyección, Oportunidades, Cotizaciones, Tareas, Actividades y demás antecedentes;
- ninguna Oportunidad se transforma en Producto Contratado;
- un Caso `Emitido` no puede marcarse simplemente como `Perdido`.

## 8. Movimientos, correcciones y reapertura

- un Caso puede avanzar o retroceder normalmente entre `Nuevo`, `Pendiente`, `Propuesta` y `En Firma`, cumpliendo los requisitos de destino;
- estos movimientos conservan etapa anterior, etapa nueva, fecha y actor, sin exigir motivo obligatorio;
- ingresar a `Sometido` exige registrar el sometimiento real;
- ingresar a `Emitido` exige registrar la emisión real y deja el Caso Ganado;
- abandonar `Sometido` es una corrección excepcional y exige motivo;
- el sometimiento histórico permanece salvo que el propio hecho sea corregido o anulado explícitamente;
- un Caso `Emitido` no puede moverse mediante el flujo ordinario;
- corregir o anular una emisión exige una operación explícita, motivada y trazable que preserve el hecho original y sus consecuencias;
- un Caso `Perdido` puede reabrirse recuperando su última etapa;
- la reapertura conserva el cierre anterior y registra fecha, actor y motivo;
- no se crean estados adicionales ni una maquinaria paralela de versiones.

> Los movimientos ordinarios son reversibles antes de `Sometido`. Las etapas factuales sólo se abandonan mediante correcciones explícitas y trazables.

## 9. CNS

Los CNS son una magnitud comercial y no una entidad autónoma.

El Caso conserva exactamente tres clases de información:

1. **Proyección vigente.** Monto manual de CNS proyectados, fecha estimada de sometimiento y fecha estimada de emisión. La revisión más reciente gobierna la operación y las anteriores permanecen trazables con fecha y actor.
2. **Sometimiento real.** Monto efectivamente sometido y fecha efectiva. Fundamenta `Sometido` y no reescribe la proyección.
3. **Emisión real.** Monto efectivamente emitido y fecha efectiva. Fundamenta `Emitido`, determina `Ganado` y no reescribe el sometimiento.

Reglas:

- no se crea una entidad `CNS` ni una estructura paralela de versiones;
- la proyección pertenece al Caso completo y no se distribuye entre Oportunidades;
- una revisión modifica la expectativa actual, no hechos reales ya ocurridos;
- sometimiento y emisión sólo se corrigen o anulan mediante operaciones explícitas y trazables;
- para el stock operativo, el Caso aporta CNS únicamente a su etapa actual;
- los valores previos permanecen como historia, pero no se suman nuevamente;
- las diferencias entre proyección, sometimiento y emisión expresan la evolución real del negocio y no crean saldos parciales;
- los reportes de flujo pueden mostrar hechos ocurridos en un período, pero no sumarlos como producción independiente.

Ejemplo:

```text
Proyección inicial: 140 CNS
Sometimiento real: 135 CNS
Emisión real: 128 CNS
Etapa actual: Emitido
Resultado: Ganado
```

La posición vigente computa 128 CNS en `Emitido`.

## 10. Tareas y Actividades

Toda Tarea o Actividad conserva siempre:

- una o varias Personas;
- un Asesor responsable o ejecutor;
- Tipo, objetivo o resultado y temporalidad conforme al Modelo Operacional.

Puede vincularse adicionalmente a:

- Relación Comercial;
- uno o más Casos;
- una o más Oportunidades.

Reglas:

- estos vínculos comerciales son contextuales y opcionales;
- una Tarea o Actividad puede existir sin Caso ni Oportunidad;
- vincularla no crea automáticamente una Relación, Caso u Oportunidad;
- toda Oportunidad vinculada debe pertenecer a uno de los Casos vinculados o permitir derivar inequívocamente su Caso actual;
- la Relación Comercial no se duplica como fuente de verdad cuando puede derivarse inequívocamente;
- la Tarea conserva el contexto previsto;
- la Actividad conserva el contexto real de lo ocurrido;
- al ejecutar una Tarea, la Actividad puede heredar sus vínculos como propuesta inicial, pero debe corregirlos cuando la acción real trató otro contexto;
- una diferencia entre planificación y ejecución no sobrescribe silenciosamente la Tarea;
- una acción puede tratar varios Casos u Oportunidades, aunque el flujo habitual optimiza un solo Caso y expone la selección múltiple mediante divulgación progresiva.

## 11. Historial descriptivo del Caso

No se crea una entidad independiente llamada `Historial`.

El Caso conserva:

- una descripción o resumen vigente, editable por el Asesor;
- notas descriptivas fechadas cuando sea necesario conservar contexto;
- Tareas y Actividades vinculadas;
- cambios de etapa y resultado;
- revisiones de proyección;
- hechos de sometimiento y emisión;
- referencias documentales cuando correspondan.

La vista histórica se deriva cronológicamente de esos antecedentes.

Reglas:

- editar la descripción vigente no altera los hechos históricos;
- una nota complementa el contexto, pero no sustituye una Actividad, un cambio de etapa ni otro hecho estructurado;
- las notas no poseen estados, aprobaciones ni ciclo de vida propio;
- la Propuesta continúa siendo conocimiento descriptivo y no una entidad;
- documentos o correos pueden conservarse como evidencia sin transformarse en la fuente de verdad del Caso.

## 12. Separación de una Oportunidad en un nuevo Caso

La separación es una operación excepcional y explícita.

Reglas:

- la Oportunidad se traslada; no se copia;
- conserva su identidad y sus Cotizaciones;
- el nuevo Caso pertenece a la misma Persona y Relación Comercial;
- conserva por defecto el mismo Asesor propietario;
- comienza por defecto en la etapa que tenía el Caso original al momento de la separación;
- si esa etapa exige proyección, fechas, Oportunidades aceptadas o Cotización seleccionada, el nuevo Caso debe cumplir los requisitos correspondientes;
- las proyecciones del Caso original y del nuevo Caso deben revisarse explícitamente para impedir la duplicación de CNS;
- los hechos anteriores permanecen en el contexto donde ocurrieron y no se reescriben retroactivamente;
- ambos Casos conservan la referencia de separación, fecha, actor, Caso de origen y Caso de destino;
- después de la separación, cada Caso avanza, se gana o se pierde independientemente;
- la capacidad debe exponerse mediante divulgación progresiva y no complicar el flujo habitual.

> Si dos desarrollos necesitan ocupar etapas diferentes o resolverse en tiempos independientes, son dos Casos Comerciales.

## 13. Oportunidad ganada, Cotización seleccionada y Producto Contratado

```text
Caso Emitido y Ganado
└── Oportunidad ganada
    └── Cotización seleccionada
        └── Producto Contratado
```

Reglas:

- un Caso `Emitido` posee al menos una Oportunidad ganada;
- cada Oportunidad ganada representa una contratación obtenida;
- cada Oportunidad ganada identifica exactamente una Cotización seleccionada;
- las demás Cotizaciones quedan descartadas históricamente;
- cada Oportunidad ganada origina exactamente un Producto Contratado;
- varias Oportunidades ganadas originan varios Productos Contratados;
- el Producto Contratado nace cuando la compañía acepta plenamente el contrato y éste entra en vigencia;
- conserva referencia al Caso, la Oportunidad y la Cotización de origen;
- la Cotización permanece como antecedente de lo ofrecido y no se transforma en Producto Contratado;
- el Producto Contratado puede evolucionar posteriormente de manera independiente;
- modificaciones, vigencia o término posteriores no reescriben la Cotización ni cambian retroactivamente el resultado Ganado del Caso.

Cardinalidad:

```text
Oportunidad ganada  1 ── 1 Producto Contratado
Producto Contratado 1 ── 1 Oportunidad de origen
```

## 14. Invariantes, advertencias y recomendaciones

### Invariantes bloqueantes

El sistema debe impedir:

- Caso sin Persona, Relación Comercial o Asesor propietario;
- Oportunidad vinculada simultáneamente a más de un Caso actual;
- Cotización sin Oportunidad;
- Caso activo en más de una etapa;
- ingreso a `Propuesta` sin proyección de CNS y fechas estimadas;
- ingreso a `En Firma` sin al menos una Oportunidad aceptada y su Cotización seleccionada;
- ingreso a `Sometido` sin contrato firmado, CNS sometidos y fecha real;
- ingreso a `Emitido` sin aceptación de la compañía, CNS emitidos, fecha real y Producto Contratado;
- Caso `Emitido` sin resultado `Ganado`;
- Caso `Perdido` con Oportunidades ganadas;
- Oportunidad ganada con más de una Cotización seleccionada;
- duplicar Oportunidades, Cotizaciones o CNS durante una separación;
- sobrescribir silenciosamente etapas, resultados, sometimientos o emisiones;
- computar simultáneamente la misma magnitud de CNS en varias etapas.

### Advertencias confirmables

El sistema advierte, pero permite continuar con confirmación, ante:

- mover a `Propuesta` sin ninguna Cotización;
- combinación aparentemente incoherente de productos o configuraciones dentro de una Oportunidad;
- salto de etapas anteriores cuando se cumplen los requisitos de destino;
- modificación importante de proyección o fechas;
- Tarea o Actividad cuyo contexto real difiere del previsto;
- separación que podría duplicar inicialmente la proyección entre dos Casos.

### Recomendaciones operativas

No bloquean ni exigen confirmación:

- dejar una descripción suficiente al pasar a `Pendiente`;
- registrar proyección y fechas desde `Nuevo` o `Pendiente`;
- vincular Tareas y Actividades al Caso u Oportunidad cuando aporte contexto;
- separar una Oportunidad sólo cuando necesite tiempos independientes;
- dejar una nota breve que explique decisiones comerciales relevantes.

## 15. Decisiones sustituidas

Este ADR sustituye expresamente las hipótesis intermedias que proponían:

- exigir al menos una Oportunidad para crear un Caso;
- mantener etapas individuales por Oportunidad;
- mostrar varias tarjetas del mismo Caso en distintas columnas;
- dividir o reunir tarjetas según las etapas de las Oportunidades;
- distribuir la proyección entre tarjetas u Oportunidades para representar etapas simultáneas;
- mantener saldos parciales de CNS entre etapas;
- derivar el cierre desde una mezcla de resultados independientes de Oportunidades;
- considerar `Perdido` como una etapa;
- crear entidades estructuradas para Propuesta o Historial;
- duplicar una Oportunidad al separarla en otro Caso.

Estas hipótesis no deben trasladarse al Modelo Comercial, a la Matriz de Validación ni al diseño físico.

## 16. Criterio de seguridad antes del diseño físico

Este ADR no autoriza todavía tablas ni SQL.

Antes de diseñar `next_v03`, las reglas aprobadas deben expresarse mediante una matriz de transiciones y pruebas reproducibles que demuestren, como mínimo:

- cardinalidades y pertenencias aprobadas;
- una sola etapa y una sola tarjeta por Caso;
- requisitos de cada etapa;
- atomicidad de sometimiento y emisión;
- correcciones y reaperturas trazables;
- una sola proyección vigente con historial;
- sometimiento y emisión como hechos distintos;
- ausencia de doble conteo de CNS;
- coherencia de Oportunidades ganadas, Cotizaciones seleccionadas y Productos Contratados;
- separación sin duplicación;
- vínculos contextuales coherentes de Tareas y Actividades;
- reconstrucción del historial desde hechos canónicos;
- clasificación explícita entre invariantes, advertencias y recomendaciones.

Si estas reglas no pueden expresarse mediante un conjunto pequeño de transiciones deterministas y pruebas reproducibles, el diseño físico debe detenerse y simplificarse.

## Preguntas pendientes del lote

No quedan preguntas estructurales pendientes para el modelo mínimo de desarrollo comercial.

Antes de cerrar el LCD corresponde:

1. consolidar estas decisiones en `docs/domain/commercial-model.md`;
2. ampliar `docs/domain/validation-matrix-next-v03.md` con reglas y casos de prueba;
3. revisar equivalencia con los antecedentes canónicos y registrar cualquier refinamiento explícito;
4. aprobar ADR-025 y los documentos derivados;
5. actualizar registros, catálogo y espejos documentales aplicables;
6. fusionar el PR y cerrar el Issue.

## Límites del lote

No se deciden todavía:

- nombres físicos de tablas o columnas;
- SQL;
- UX detallada;
- colores;
- dashboards;
- automatizaciones;
- probabilidades definitivas;
- reglas particulares de cada producto;
- mecanismo técnico definitivo de advertencias o excepciones;
- estructura definitiva de almacenamiento documental;
- cambios en APP LLAMADOS Legacy, DEV, STAGING o PROD.

## Consecuencias

- el Caso Comercial es la unidad indivisible del Pipeline;
- una Relación puede persistir sin Caso y un Caso puede existir inicialmente sin Oportunidades;
- toda Oportunidad pertenece exactamente a un Caso actual;
- la Oportunidad representa una contratación potencial y la Cotización una configuración específica;
- la Propuesta y el Historial permanecen como conocimiento descriptivo y vistas derivadas, no como entidades artificiales;
- las etapas son `Nuevo`, `Pendiente`, `Propuesta`, `En Firma`, `Sometido` y `Emitido`;
- `Emitido` determina `Ganado` y `Perdido` conserva la última etapa alcanzada;
- los movimientos previos a `Sometido` son reversibles con historial;
- las etapas factuales sólo se corrigen mediante operaciones explícitas;
- el Caso conserva una proyección vigente con historial, un sometimiento real y una emisión real;
- Tareas y Actividades conservan Personas y Asesor, y pueden vincularse opcionalmente al contexto comercial;
- una Oportunidad puede separarse trazablemente en un nuevo Caso sin duplicación;
- cada Oportunidad ganada origina un Producto Contratado y selecciona una única Cotización;
- invariantes, advertencias y recomendaciones quedan diferenciados;
- `next_v03` continúa bloqueado para diseño físico hasta consolidar el Modelo Comercial y la Matriz de Validación;
- no se modificó APP LLAMADOS Legacy ni ningún ambiente.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.
