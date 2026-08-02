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
| MV-11 | Actividad | Es un hecho de una Persona realizado por un Asesor y puede existir antes de la Relación | Intentos, conversaciones sin continuidad y Actividades que originan una Relación | Actividad sin Persona o Asesor | T-V03-011 |
| MV-12 | Tarea | Puede ser manual o nacer de una Actividad | Tarea sin Actividad previa | Vincular Actividad de otra Persona o Asesor | T-V03-012 |
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

### CV-13 · Tarea manual

**Dado** que existe una Persona y un Asesor  
**Cuando** se crea una Tarea sin Actividad de origen  
**Entonces** la Tarea es válida.

### CV-14 · Tarea inconsistente

**Dado** que una Actividad pertenece a Ana y Guillermo  
**Cuando** se intenta usar como origen de una Tarea de Pedro o Carolina  
**Entonces** la operación se rechaza.

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
- cargas TOTAL sucesivas e incrementales;
- comparación de ausencias sólo dentro del mismo período y Campaña comparable;
- cambio de período sin incidencias masivas;
- linaje mínimo e historial sólo ante cambios efectivos;
- Tarea y Actividad coherentes por Persona y Asesor.

### Pendientes de diseño lógico o técnico

- clave lógica exacta de Campaña;
- forma física de la Autorización Excepcional;
- reglas exactas para derivar Lead, Cliente del Asesor y Relación dormida;
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
