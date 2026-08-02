# Matriz de Validación del Modelo · CRM Patrimonial Next v03

- Versión: 0.1
- Estado: Pendiente de revisión
- Fecha: 2026-08-01
- LCD: LCD-20260801-02
- ADR: ADR-024
- Issue: #31

## 1. Propósito

Transformar reglas del dominio expresadas en lenguaje natural en criterios verificables antes de diseñar el esquema físico `next_v03`.

Esta matriz es el puente entre:

```text
regla de negocio
→ modelo conceptual
→ caso de prueba
→ restricción o comportamiento implementado
```

No constituye todavía una especificación SQL.

## 2. Reglas de validación

| ID | Concepto | Regla del dominio | Debe permitir | Debe impedir | Prueba futura |
|---|---|---|---|---|---|
| MV-01 | Persona | Existe independientemente de Campañas, Asesores y Oportunidades | Persona manual sin Apariciones | Eliminar una Persona porque dejó de aparecer | T-V03-001 |
| MV-02 | Campaña | Representa una selección mensual concreta con identidad interna | Dos Campañas distintas en el mismo período | Identificarla sólo por prefijo o texto ambiguo | T-V03-002 |
| MV-03 | Aparición | Vincula una Persona con una Campaña concreta | Persona en varias Campañas del mismo mes | Duplicar la misma Aparición por cada TOTAL | T-V03-003 |
| MV-04 | Resultado Corporativo | Una Aparición válida tiene normalmente exactamente un resultado vigente; la ausencia sólo existe como inconsistencia explícita | Gestionado, No Gestionado o Aparición temporalmente incompleta con incidencia | Dos resultados vigentes, tercer estado inventado o ausencia silenciosa que gobierne gestionabilidad | T-V03-004 |
| MV-05 | Historial de resultado | Sólo se registra ante un cambio efectivo | Conservar resultado anterior, nuevo, fecha y carga | Crear historial por repetir el mismo valor | T-V03-005 |
| MV-06 | Asignación | Vincula temporalmente una Aparición con un Asesor y tiene normalmente una sola vigencia activa | Aparición sin Asignación, historial de cambios y conciliación ante ausencia comparable | Confundir Asignación con Relación Comercial o terminarla por una ausencia aislada | T-V03-006 |
| MV-07 | Orden de origen | TOTAL y ASIGNADOS tienen órdenes independientes | Posiciones distintas para la misma Persona | Que una carga sobrescriba el orden de la otra | T-V03-007 |
| MV-08 | Relación Comercial | Es única, persistente y nace cuando existe continuidad comercial propia | Relación sin Oportunidad, nacida por agenda o seguimiento acordado | Crear otra Relación al cambiar de Asesor o esperar al cierre para crearla | T-V03-008 |
| MV-09 | Responsabilidad del Asesor | Existe normalmente un único responsable principal vigente | Transferir responsabilidad y representar temporalmente una Relación sin responsable como transición o inconsistencia alertada | Dos responsables vigentes sin autorización o ausencia silenciosa de responsable | T-V03-009 |
| MV-10 | Autorización Excepcional | Un Administrador puede autorizar responsabilidad simultánea | Segundo responsable con motivo y trazabilidad | Crear otra Relación Comercial por la excepción | T-V03-010 |
| MV-11 | Actividad | Es un hecho efectivamente ocurrido, realizado por un Asesor y con una o varias Personas participantes | Intentos, reuniones grupales, notas opcionales y Actividades que originan una Relación o ejecutan Tareas | Actividad sin Persona, Asesor, Tipo, fecha efectiva o resultado estructurado; duplicar una acción por participante | T-V03-011 |
| MV-12 | Tarea | Es la previsión de una única Actividad futura, con una o varias Personas, Tipo y objetivo | Tarea individual o grupal, manual y excepcionalmente sin fecha | Tarea sin Persona, Asesor, Tipo u objetivo; categoría paralela que duplique el Tipo | T-V03-012 |
| MV-13 | Importación | Cada archivo genera una ejecución idempotente | Reintentar el mismo archivo sin duplicar | Aplicar dos veces los mismos efectos | T-V03-013 |
| MV-14 | Linaje | Los hechos indican creación, última observación y último cambio | Identificar qué carga creó o modificó | Guardar copias innecesarias de filas idénticas | T-V03-014 |
| MV-15 | Datos de contacto | La observación válida más reciente gobierna lo visible | Actualizar teléfono o correo | Mantener como vigente un dato retirado | T-V03-015 |
| MV-16 | Ausencia intra-período | Sólo se analiza entre cargas comparables del mismo período y Campaña | Incidencia por ausencia individual excepcional | Eliminar automáticamente Persona o Aparición | T-V03-016 |
| MV-17 | Cambio de período | Cada período crea sus propias Apariciones y termina la vigencia operativa de Asignaciones anteriores | Miles de ausencias normales entre meses | Generar incidencias por no reaparecer | T-V03-017 |
| MV-18 | Alcance del archivo | Se valida antes de comparar Personas | Detectar una Campaña completa faltante | Generar miles de incidencias individuales | T-V03-018 |
| MV-19 | Incidencia de Conciliación | Tiene tipo, estado y resoluciones limitadas | Mantenerla abierta hasta conocer el motivo | Resolver sin categoría ni trazabilidad | T-V03-019 |
| MV-20 | Reaparición | Puede cerrar una incidencia previa sin duplicar hechos | Cierre automático conservando historia | Crear otra Persona, Aparición o Asignación | T-V03-020 |
| MV-21 | Lead | Es una condición de una Relación Comercial previa a un Producto Contratado | Lead sin Oportunidad y Lead con Oportunidad | Crear una entidad Persona-Lead separada o exigir un cierre previo | T-V03-021 |
| MV-22 | Cliente del Asesor | Se deriva de una Relación con al menos un Producto Contratado vigente asociado al Asesor | Convertir la condición de Lead a Cliente sin cambiar la identidad de la Relación | Crear una segunda Relación al cerrar o emitir un negocio | T-V03-022 |
| MV-23 | Tipo de Actividad | Es el catálogo común para acciones previstas y realizadas | Usar el mismo Tipo en Tarea y Actividad y conservar diferencias entre previsto y realizado | Crear una Categoría de Tarea paralela que duplique el Tipo | T-V03-023 |
| MV-24 | Ejecución de Tarea | Ejecutar genera una Actividad vinculada que incluye a todas las Personas de la Tarea y la completa aunque no logre el objetivo comercial | Completar mediante una única Actividad y crear otra Tarea para un nuevo intento | Marcar ejecutada sin Actividad, omitir una Persona prevista o usar otro Asesor | T-V03-024 |
| MV-25 | Programación temporal | Fecha prevista y fecha límite son opcionales, pero su ausencia o vencimiento son visibles | Tarea válida sin fecha, clasificada como Sin programar; Tarea vencida clasificada como Atrasada | Convertir Sin programar o Atrasada en estados que sustituyan Pendiente | T-V03-025 |
| MV-26 | Texto y resultado | Objetivo, contexto y nota cumplen funciones diferentes | Objetivo obligatorio, contexto y nota de ejecución opcionales, resultado estructurado | Crear Nota de programación redundante o reemplazar el resultado por texto libre | T-V03-026 |
| MV-27 | Reprogramación y cancelación | No constituyen Actividades | Reprogramar con trazabilidad y cancelar con motivo | Inflar estadísticas creando Actividades por cambios administrativos | T-V03-027 |
| MV-28 | Compatibilidad Tipo–Resultado | Cada Tipo de Actividad admite sólo Resultados de Actividad compatibles | Llamada + No contestó; Reunión + Realizada | Llamada + Propuesta preparada u otra combinación incoherente | T-V03-028 |
| MV-29 | Consecuencias de Actividad | El Resultado describe lo ocurrido; los próximos pasos son hechos separados | Actividad que origina Tareas, Relación u Oportunidad trazables | Mezclar acción, resultado y consecuencia en una sola etiqueta | T-V03-029 |
| MV-30 | Métricas derivadas | Llamada efectiva, agendamiento y seguimiento se derivan de hechos persistentes | Derivar llamada efectiva desde Tipo y Resultado y agendamiento desde Actividad más Tarea futura | Guardar `Agenda reunión`, `Volver a llamar` o `Información enviada` como etiquetas ambiguas que sustituyan hechos | T-V03-030 |
| MV-31 | Ejecución múltiple | Una Actividad puede ejecutar varias Tareas compatibles cuyas Personas están comprendidas entre sus participantes y cuyo Asesor coincide | Una llamada real que completa varias Tareas sin duplicar la Actividad | Crear Actividades ficticias o completar Tareas con Personas ausentes | T-V03-031 |
| MV-32 | Reasignación de Tarea | El cambio de responsable es explícito y conserva historia | Reasignar una Tarea pendiente con Asesor anterior, nuevo, fecha y motivo | Reasignar automáticamente por transferencia de Relación o cambiar responsable silenciosamente | T-V03-032 |
| MV-33 | Corrección y anulación de Actividad | Una Actividad histórica no se elimina ni sobrescribe silenciosamente | Corregir o anular conservando original, cambio, responsable, fecha y motivo | Borrar el registro o reemplazarlo sin trazabilidad | T-V03-033 |
| MV-34 | Efectos de anulación | Una Actividad anulada queda fuera de métricas y no sostiene consecuencias por sí sola | Mantener trazabilidad y advertir consecuencias para revisión | Contarla, usarla para completar Tareas o eliminar automáticamente hechos posteriores | T-V03-034 |
| MV-35 | Modificación de Tarea | Las Tareas Pendientes pueden cambiar con historial; las cerradas sólo se rectifican explícitamente | Modificar compromiso futuro conservando cambios sustantivos | Reescribir silenciosamente una Tarea Completada o Cancelada | T-V03-035 |
| MV-36 | Participación múltiple | Una única acción real o futura puede involucrar a una o varias Personas sin duplicarse | Una reunión o Tarea grupal con varios participantes | Crear una Actividad o Tarea idéntica por cada Persona | T-V03-036 |
| MV-37 | Consecuencias individualizadas | La participación grupal no produce automáticamente el mismo efecto comercial para todos | Crear Relación u Oportunidad sólo para la Persona con continuidad propia | Crear Relaciones para todos los participantes por el solo hecho de asistir | T-V03-037 |
| MV-38 | Tarea grupal sin Relación previa | Una Tarea puede incluir Personas sin Relación Comercial y no la crea por sí sola | Programar una reunión grupal con un acompañante aún sin Relación | Exigir Relación previa o crearla automáticamente por programar | T-V03-038 |

## 3. Casos conceptuales obligatorios

### CV-01 · Persona sin campaña

**Dado** que una Persona fue creada manualmente  
**Cuando** nunca aparece en una Campaña  
**Entonces** la Persona permanece válida y no requiere Aparición.

### CV-02 · Repetición sin cambios

```text
TOTAL_01:
Ana · Propensión Integral · No Gestionado

TOTAL_02:
Ana · Propensión Integral · No Gestionado
```

Resultado esperado:

- una Persona;
- una Aparición;
- cero eventos de cambio;
- última observación actualizada.

### CV-03 · Cambio corporativo

```text
TOTAL_01:
Ana · No Gestionado

TOTAL_02:
Ana · Gestionado
```

Resultado esperado:

- una Aparición;
- resultado vigente Gestionado;
- un evento No Gestionado → Gestionado;
- linaje hacia TOTAL_02.

### CV-04 · Nueva Persona dentro del mes

```text
TOTAL_01:
Ana

TOTAL_02:
Ana
Pedro
```

Resultado esperado:

- Ana no se duplica;
- Pedro se incorpora;
- se crea la Aparición correspondiente a Pedro.

### CV-05 · Ausencia individual comparable

```text
TOTAL_01 agosto · Propensión Integral:
Ana
Pedro
María

TOTAL_02 agosto · Propensión Integral:
Ana
María
```

Resultado esperado:

- Pedro y su Aparición no se eliminan;
- se crea una Incidencia de Conciliación individual.

### CV-06 · Campaña completa ausente

```text
TOTAL_01 agosto:
Propensión Integral
Profesionales
Segmento Joven

TOTAL_02 agosto:
Propensión Integral
Profesionales
```

Resultado esperado:

- no se crean incidencias por cada Persona de Segmento Joven;
- se crea una incidencia de alcance;
- la ejecución puede quedar bloqueada o rechazada.

### CV-07 · Cambio de período

```text
Julio:
66.500 Personas

Agosto:
42.000 Personas
```

Resultado esperado:

- Julio conserva sus Apariciones;
- Agosto crea su conjunto propio;
- las Personas no observadas en agosto no generan incidencias;
- las Asignaciones de julio dejan de estar operativamente vigentes sin incidencias individuales.

### CV-08 · Asignado coincidente

```text
TOTAL agosto:
Ana · Propensión Integral

ASIGNADOS agosto:
Ana · Propensión Integral · Guillermo
```

Resultado esperado:

- una Persona;
- una Aparición;
- una Asignación;
- órdenes TOTAL y ASIGNADOS independientes.

### CV-09 · Asignado sin coincidencia única

**Dado** que una Persona aparece en dos Campañas del mismo mes  
**Y** la fila ASIGNADOS no permite determinar cuál corresponde  
**Entonces** no se adivina la Aparición y se crea una incidencia.

### CV-10 · Transferencia de responsabilidad

**Dado** que Guillermo es responsable vigente de una Relación  
**Cuando** la responsabilidad se transfiere a Carolina  
**Entonces** termina la responsabilidad de Guillermo, comienza la de Carolina y se conserva una sola Relación Comercial.

### CV-11 · Responsabilidad simultánea autorizada

**Dado** que Guillermo es responsable vigente  
**Y** un usuario Administrador autoriza a Carolina como responsable adicional  
**Entonces** existen dos responsabilidades vigentes y una autorización trazable, pero una sola Relación Comercial.

### CV-12 · Responsabilidad simultánea no autorizada

**Dado** que una Relación ya tiene responsable vigente  
**Cuando** se intenta agregar otro sin autorización  
**Entonces** la operación se rechaza.

### CV-13 · Tarea manual sin fecha

**Dado** que existen una Persona, un Asesor y un Tipo de Actividad  
**Cuando** se crea manualmente una Tarea con objetivo, pero sin Actividad de origen ni programación temporal  
**Entonces** la Tarea es válida, permanece Pendiente y queda visiblemente clasificada como Sin programar.

### CV-14 · Tarea inconsistente

**Dado** que una Actividad tiene como participantes a Ana y Pedro y fue realizada por Guillermo  
**Cuando** se intenta usarla para ejecutar una Tarea que incluye a María o cuyo responsable es Carolina  
**Entonces** la operación se rechaza.

Toda Persona de la Tarea debe estar incluida en la Actividad y el Asesor debe coincidir.

### CV-15 · Reintento del mismo archivo

**Dado** un archivo TOTAL ya aplicado  
**Cuando** se procesa nuevamente con el mismo hash  
**Entonces** no se crean Personas, Apariciones, cambios ni incidencias duplicadas.

### CV-16 · Relación temporalmente sin responsable

**Dado** que una Relación Comercial existe y una transferencia quedó incompleta o existe una inconsistencia heredada  
**Cuando** no hay responsable principal vigente  
**Entonces** la Relación se conserva, no se inventa un Asesor y se genera una alerta o pendiente explícito de asignación.

La ausencia de responsable no puede permanecer como situación silenciosa normal.

### CV-17 · Aparición sin resultado válido

**Dado** que una fuente informa que Ana apareció en una Campaña  
**Y** el resultado viene vacío, inválido o no puede determinarse  
**Entonces** se conserva la Aparición como inconsistencia explícita, se genera una incidencia y no se considera gestionable hasta resolverla.

El sistema no inventa `Gestionado`, `No Gestionado` ni un tercer estado como `Desconocido`.

### CV-18 · Nacimiento de Relación por agenda

**Dado** que Ana sólo existe como Persona asignada  
**Cuando** conversa con Guillermo y acepta una reunión futura  
**Entonces** la Actividad queda registrada, nace una única Relación Comercial y Ana puede clasificarse como Lead.

No es necesario esperar una propuesta ni el cierre de un negocio.

### CV-19 · Conversación sin continuidad

**Dado** que Ana conversa con Guillermo  
**Y** rechaza continuar, recibir información o agendar otro contacto  
**Entonces** se registra la Actividad, pero no nace una Relación Comercial.

### CV-20 · Lead sin Oportunidad

**Dado** que existe una Relación Comercial por seguimiento acordado  
**Y** todavía no se identifica un producto concreto  
**Entonces** la Relación es válida y puede clasificarse como Lead sin Oportunidad.

### CV-21 · Conversión a Cliente del Asesor

**Dado** que Ana posee una Relación Comercial y una Oportunidad ganada  
**Cuando** nace un Producto Contratado vigente asociado a Guillermo  
**Entonces** Ana pasa a clasificarse como Cliente del Asesor sin crear otra Persona ni otra Relación Comercial.

### CV-22 · Ausencia en ASIGNADOS comparable

```text
ASIGNADOS_01 agosto:
Ana · Guillermo

ASIGNADOS_02 agosto:
Ana no aparece
```

Resultado esperado:

- no se elimina la Asignación histórica;
- no se registra término automático;
- se genera una incidencia de conciliación;
- una resolución confirmada puede registrar el término;
- una reaparición posterior cierra la incidencia sin duplicar la Asignación.

### CV-23 · Ejecución sin lograr el objetivo

**Dado** que existe una Tarea Pendiente de Tipo Llamada cuyo objetivo es solicitar documentos  
**Cuando** Guillermo realiza la llamada y Ana no contesta  
**Entonces** se crea una Actividad de ejecución con resultado `No contestó` y la Tarea queda Completada.

Si se requiere volver a intentar, se crea una nueva Tarea; no se mantiene abierta la anterior ni se le agregan múltiples ejecuciones.

### CV-24 · Completar sin Actividad

**Dado** que existe una Tarea Pendiente  
**Cuando** se intenta marcarla como ejecutada o Completada sin registrar una Actividad vinculada  
**Entonces** la operación se rechaza.

La cancelación constituye un flujo diferente y no requiere Actividad.

### CV-25 · Cancelación y reprogramación

**Dado** que existe una Tarea Pendiente  
**Cuando** se reprograma  
**Entonces** conserva trazabilidad del cambio y no se crea una Actividad.

**Cuando** se cancela  
**Entonces** conserva fecha, responsable y motivo de cancelación, sin crear una Actividad ni afectar estadísticas de gestión.

### CV-26 · Objetivo, contexto y nota

**Dado** que se programa una Tarea  
**Entonces** debe registrar un objetivo y puede registrar contexto opcional, sin una Nota de programación separada.

**Cuando** se ejecuta  
**Entonces** la Actividad registra un resultado estructurado y puede añadir una nota de ejecución opcional; la nota no sustituye el resultado.

### CV-27 · Tipo previsto y Tipo realizado

**Dado** que una Tarea conserva un Tipo de Actividad previsto  
**Cuando** su Actividad de ejecución registra el Tipo realmente realizado  
**Entonces** ambos valores se conservan y la ejecución no sobrescribe retroactivamente el Tipo previsto.

La regla operativa exacta para autorizar o advertir diferencias entre ambos queda pendiente del diseño lógico.

### CV-28 · Resultado incompatible con el Tipo

**Dado** que se registra una Actividad de Tipo Llamada  
**Cuando** se intenta asignar el resultado `Propuesta preparada`  
**Entonces** la operación se rechaza por incompatibilidad entre Tipo y Resultado.

### CV-29 · Agenda como consecuencia separada

**Dado** que Guillermo realiza una Llamada a Ana  
**Y** el resultado es `Conversación efectiva`  
**Cuando** ambos acuerdan una reunión futura  
**Entonces** se conserva la Actividad de Llamada, nace la Relación Comercial cuando corresponda y se crea una Tarea futura de Tipo Reunión.

`Agenda reunión` no sustituye el Resultado de la Llamada ni la Tarea creada.

### CV-30 · Volver a llamar como nueva Tarea

**Dado** que Guillermo ejecuta una Tarea de Llamada  
**Y** la Actividad resultante indica `No contestó`  
**Cuando** decide realizar otro intento  
**Entonces** la primera Tarea queda Completada y se crea otra Tarea de Tipo Llamada.

`Volver a llamar` no se registra como Resultado de la primera Actividad.

### CV-31 · Una Actividad ejecuta varias Tareas

**Dado** que Ana tiene dos Tareas Pendientes asignadas a Guillermo:

- Llamar para confirmar la reunión;
- Llamar para solicitar liquidaciones.

**Cuando** Guillermo realiza una única Llamada y aborda ambos objetivos  
**Entonces** se registra una sola Actividad y ésta puede completar ambas Tareas.

No se crean dos Actividades ficticias para representar una sola llamada real. La interfaz debe permitir este vínculo de forma opcional y asistida, sin complejizar el flujo normal de ejecución de una Tarea.

### CV-32 · Transferencia de Relación con Tarea pendiente

**Dado** que Guillermo es responsable de la Relación Comercial de Ana  
**Y** existe una Tarea Pendiente asignada a Guillermo  
**Cuando** la Relación Comercial se transfiere a Carolina  
**Entonces** la Tarea no cambia automáticamente de responsable y queda visible para resolución.

La Tarea puede:

- reasignarse explícitamente a Carolina, conservando Asesor anterior, nuevo, fecha y motivo;
- cancelarse;
- permanecer excepcionalmente con Guillermo mediante una decisión explícita.

Una Actividad de ejecución debe ser realizada por el Asesor responsable vigente de la Tarea en ese momento.

### CV-33 · Corrección de Actividad

**Dado** que Guillermo registró una Llamada con resultado `Conversación efectiva`  
**Y** luego advierte que el resultado correcto era `No contestó`  
**Cuando** corrige la Actividad  
**Entonces** se conservan el valor original, el valor corregido, la fecha, el responsable y el motivo.

Para la operación y las métricas gobierna la versión corregida, sin borrar el antecedente original.

### CV-34 · Anulación con consecuencias previas

**Dado** que una Actividad fue registrada en la Persona equivocada  
**Y** esa Actividad había completado una Tarea o ayudado a originar una Relación Comercial  
**Cuando** se anula con motivo trazable  
**Entonces** deja de contar para métricas y de sostener por sí sola esas consecuencias.

La Actividad permanece auditable y las consecuencias quedan advertidas para revisión; no se eliminan automáticamente porque pueden haber sido confirmadas por otros hechos.

### CV-35 · Modificación de Tarea según estado

**Dado** que una Tarea está Pendiente  
**Cuando** cambia su Tipo, objetivo, responsable, Personas o programación temporal  
**Entonces** el cambio es válido y conserva la historia sustantiva del compromiso.

**Dado** que una Tarea está Completada o Cancelada  
**Cuando** se intenta reescribirla como si siguiera Pendiente  
**Entonces** la operación se rechaza y cualquier rectificación debe registrarse explícitamente con responsable, fecha y motivo.

### CV-36 · Reunión con varias Personas

**Dado** que Guillermo se reúne simultáneamente con Ana y Pedro  
**Cuando** registra la reunión realizada  
**Entonces** existe una sola Actividad con Ana y Pedro como participantes.

No se crean dos reuniones idénticas ni se duplica el tiempo trabajado.

### CV-37 · Consecuencias diferentes por participante

**Dado** que Ana y Pedro participan en la misma reunión  
**Y** Ana ya posee Relación Comercial  
**Y** Pedro sólo acompaña inicialmente  
**Cuando** Pedro manifiesta interés propio y acuerda continuidad  
**Entonces** la Actividad sigue siendo única, la Relación de Ana permanece y puede nacer una Relación Comercial para Pedro.

Si Pedro no acuerda continuidad, su sola participación no crea una Relación.

### CV-38 · Tarea grupal sin Relación previa

**Dado** que Ana posee Relación Comercial y Pedro todavía no  
**Cuando** se programa una única Tarea de Reunión para ambos  
**Entonces** la Tarea es válida, incluye a Ana y Pedro y no crea automáticamente una Relación Comercial para Pedro.

La Actividad de ejecución deberá incluir a ambos para completar esa Tarea grupal.

## 4. Clasificación de decisiones

### Confirmadas para `next_v03`

- Persona independiente;
- Campaña mensual concreta;
- Aparición distinta de Asignación;
- toda Aparición válida normalmente tiene un único Resultado Corporativo vigente;
- la falta de resultado es una inconsistencia explícita, conciliable y no gestionable, nunca un tercer estado;
- Resultado Corporativo separado de la gestión propia;
- órdenes TOTAL y ASIGNADOS independientes;
- una Aparición tiene normalmente como máximo una Asignación vigente;
- la ausencia en ASIGNADOS comparable genera conciliación y no término automático;
- el cambio de período termina la vigencia operativa de Asignaciones anteriores sin incidencias individuales;
- Relación Comercial única;
- la Relación nace con continuidad comercial propia y no requiere propuesta ni cierre;
- Lead es una condición de la Relación Comercial, no una entidad separada;
- puede existir Lead sin Oportunidad;
- Cliente del Asesor se deriva de un Producto Contratado vigente sin crear otra Relación;
- responsabilidad de Asesor con historial;
- responsable principal normalmente vigente y ausencia temporal sólo como excepción explícita y alertada;
- responsabilidad simultánea sólo con autorización;
- Tarea como previsión de una única Actividad futura;
- Actividad y Tarea con una o varias Personas;
- interacción grupal representada mediante una sola Actividad o Tarea;
- consecuencias comerciales evaluadas individualmente por Persona;
- Tarea grupal válida aunque alguna Persona no posea Relación previa;
- catálogo común de Tipos de Actividad para Tarea y Actividad;
- cada Tipo de Actividad define los Resultados estructurados compatibles;
- el Resultado describe lo ocurrido y no las consecuencias posteriores;
- Tarea con Tipo y objetivo obligatorios y contexto opcional;
- ausencia de una Nota de programación separada;
- programación temporal opcional, pero visible cuando falta o vence;
- cada Tarea ejecutada se vincula a una única Actividad;
- una Actividad puede ejecutar varias Tareas compatibles cuyas Personas están entre sus participantes;
- no se duplican Actividades para representar una sola acción real;
- ejecución completa la Tarea aunque no alcance el objetivo comercial;
- cada nuevo intento requiere una nueva Tarea;
- resultado estructurado y nota libre de Actividad separados;
- creación de Tareas, Relaciones u Oportunidades como hechos separados de la Actividad que los origina;
- llamada efectiva, agendamiento y seguimiento como métricas derivadas;
- reprogramación y cancelación no constituyen Actividades;
- reasignación de Tarea explícita y con historial;
- transferencia de Relación Comercial sin reasignación automática de Tareas pendientes;
- Actividad inmutable en forma silenciosa y corregible o anulable sólo con trazabilidad;
- Actividad anulada excluida de métricas y de justificación de consecuencias;
- consecuencias de una Actividad corregida o anulada sujetas a revisión, no a borrado automático;
- cambios sustantivos de Tarea Pendiente con historial y rectificación explícita de Tareas cerradas;
- cargas TOTAL sucesivas e incrementales;
- comparación de ausencias sólo dentro del mismo período y Campaña comparable;
- cambio de período sin incidencias masivas;
- linaje mínimo e historial sólo ante cambios efectivos.

### Pendientes de diseño lógico o técnico

- clave lógica exacta de Campaña;
- forma física de la Autorización Excepcional;
- reglas exactas para derivar Lead, Cliente del Asesor y Relación dormida;
- catálogo inicial de Tipos y Resultados de Actividad;
- regla exacta cuando el Tipo realizado difiere del Tipo previsto;
- criterios exactos de compatibilidad para que una Actividad ejecute varias Tareas;
- experiencia asistida y simple para asociar opcionalmente varias Tareas o Personas a una Actividad;
- representación física de la relación muchos-a-muchos entre Personas, Actividades y Tareas;
- necesidad de atributos de participación, como rol o participante principal;
- derivación de métricas por acción y por Persona en Actividades grupales;
- representación física del historial de reprogramaciones;
- representación física del historial de responsables de Tarea;
- representación física de correcciones y anulaciones de Actividad;
- revisión operativa de consecuencias originadas por una Actividad posteriormente corregida o anulada;
- representación física de cambios significativos y rectificaciones de Tarea;
- formato y límites de objetivo, contexto y nota de ejecución;
- umbral de archivo incompleto;
- estructura del historial de datos de contacto;
- nombres de tablas y columnas;
- restricciones SQL;
- índices;
- RLS;
- estrategia de migración desde Legacy.

## 5. Criterio para diseñar `next_v03`

El diseño físico puede comenzar sólo cuando:

1. esta matriz sea aprobada;
2. el Modelo Comercial sea aprobado;
3. el Modelo Operacional sea aprobado;
4. las contradicciones con documentos superiores estén resueltas;
5. los pendientes técnicos estén claramente separados de las reglas del dominio.
