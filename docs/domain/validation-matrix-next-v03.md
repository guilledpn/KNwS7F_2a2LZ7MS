# Matriz de Validación del Modelo · CRM Patrimonial Next v03

- Versión: 0.2
- Estado: <span style="color:red">Extensión pendiente de revisión · LCD-20260802-01</span>
- Fecha: 2026-08-03
- LCD aprobado de origen: LCD-20260801-02
- LCD en revisión: <span style="color:red">LCD-20260802-01</span>
- ADR: ADR-024 y <span style="color:red">ADR-025</span>
- Issues: #31 y #34
- Motivo del cambio: incorporar reglas verificables del modelo mínimo de desarrollo comercial.

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
| MV-03 | Aparición | Vincula una Persona con una Campaña concreta | Persona en varias Campañas del mismo mes | Duplicar la misma Aparición por cada TOTAL o ASIGNADOS | T-V03-003 |
| MV-04 | Resultado Corporativo | Una Aparición válida tiene normalmente exactamente un resultado vigente; la ausencia sólo existe como inconsistencia explícita | Gestionado, No Gestionado o Aparición temporalmente incompleta con incidencia | Dos resultados vigentes, tercer estado inventado o ausencia silenciosa que gobierne gestionabilidad | T-V03-004 |
| MV-05 | Historial de resultado | Sólo se registra ante un cambio efectivo | Conservar resultado anterior, nuevo, fecha y carga | Crear historial por repetir el mismo valor | T-V03-005 |
| MV-06 | Asignación | Vincula temporalmente una Aparición con un Asesor, puede nacer desde ASIGNADOS sin TOTAL previo y tiene normalmente una sola vigencia activa | ASIGNADOS antes de TOTAL, historial de cambios y vigencia pendiente de conciliación ante ausencia comparable | Confundir Asignación con Relación Comercial o terminarla por una ausencia aislada | T-V03-006 |
| MV-07 | Posición por fuente | TOTAL y ASIGNADOS pueden conservar posiciones propias en listas distintas | Posiciones diferentes para la misma Persona | Heredar o sobrescribir una posición con la otra fuente | T-V03-007 |
| MV-08 | Relación Comercial | Es única, persistente y nace cuando existe continuidad comercial propia | Relación sin Oportunidad, nacida por agenda o seguimiento acordado | Crear otra Relación al cambiar de Asesor o esperar al cierre para crearla | T-V03-008 |
| MV-09 | Responsabilidad del Asesor | Existe normalmente un único responsable principal vigente | Transferir responsabilidad y representar temporalmente una Relación sin responsable como transición o inconsistencia alertada | Dos responsables vigentes sin autorización o ausencia silenciosa de responsable | T-V03-009 |
| MV-10 | Autorización Excepcional | Un Administrador puede autorizar responsabilidad simultánea | Segundo responsable con motivo y trazabilidad | Crear otra Relación Comercial por la excepción | T-V03-010 |
| MV-11 | Actividad | Es un hecho efectivamente ocurrido, ejecutado por un Asesor y con una o varias Personas participantes | Intentos, reuniones grupales, notas opcionales y Actividades que originan una Relación o ejecutan Tareas | Actividad sin Persona, Asesor ejecutor, Tipo, fecha efectiva o resultado estructurado; duplicar una acción por participante | T-V03-011 |
| MV-12 | Tarea | Es la previsión de una única Actividad futura, con una o varias Personas objetivo, Tipo y objetivo | Tarea individual o grupal, manual y excepcionalmente sin fecha | Tarea sin Persona, Asesor responsable, Tipo u objetivo; categoría paralela que duplique el Tipo | T-V03-012 |
| MV-13 | Importación | Cada archivo genera una ejecución idempotente | Reintentar el mismo archivo sin duplicar | Aplicar dos veces los mismos efectos | T-V03-013 |
| MV-14 | Linaje | Los hechos indican creación, última observación y último cambio | Identificar qué carga creó o modificó | Guardar copias innecesarias de filas idénticas | T-V03-014 |
| MV-15 | Datos de contacto | La observación válida más reciente, provenga de TOTAL o ASIGNADOS, gobierna lo visible | Actualizar teléfono o correo | Mantener como vigente un dato retirado | T-V03-015 |
| MV-16 | Ausencia intra-período | Sólo se analiza entre cargas comparables del mismo período y Campaña activa | Incidencia por ausencia individual excepcional | Eliminar automáticamente Persona o Aparición | T-V03-016 |
| MV-17 | Cambio de período | Cada período crea sus propias Apariciones y termina la vigencia operativa de Asignaciones anteriores | Miles de ausencias normales entre meses | Generar incidencias por no reaparecer | T-V03-017 |
| MV-18 | Alcance del archivo | Se valida antes de comparar Personas | Detectar una Campaña, segmento o bloque anómalo faltante | Generar miles de incidencias individuales | T-V03-018 |
| MV-19 | Incidencia de Conciliación | Es un único concepto con alcance individual o de conjunto y conserva tipo, evidencia, estado, resolución y trazabilidad | Vincularla a filas, Personas, hechos o conjuntos según el problema | Resolver sin categoría, evidencia ni trazabilidad | T-V03-019 |
| MV-20 | Reaparición | Puede cerrar una incidencia previa sin duplicar hechos | Cierre automático conservando historia | Crear otra Persona, Aparición o Asignación | T-V03-020 |
| MV-21 | Lead | Es una condición de una Relación Comercial previa a un Producto Contratado | Lead sin Oportunidad y Lead con Oportunidad | Crear una entidad Persona-Lead separada o exigir un cierre previo | T-V03-021 |
| MV-22 | Cliente del Asesor | Se deriva de una Relación con al menos un Producto Contratado vigente asociado al Asesor | Convertir la condición de Lead a Cliente sin cambiar la identidad de la Relación | Crear una segunda Relación al cerrar o emitir un negocio | T-V03-022 |
| MV-23 | Tipo de Actividad | Es el catálogo común para acciones previstas y realizadas | Usar el mismo Tipo en Tarea y Actividad y conservar diferencias entre previsto y realizado | Crear una Categoría de Tarea paralela que duplique el Tipo | T-V03-023 |
| MV-24 | Ejecución de Tarea | Ejecutar genera una Actividad vinculada que incluye a todas las Personas objetivo de la Tarea y la completa aunque no logre el objetivo comercial | Completar mediante una única Actividad y crear otra Tarea para un nuevo intento | Marcar ejecutada sin Actividad, omitir una Persona objetivo o usar un Asesor ejecutor distinto del responsable vigente | T-V03-024 |
| MV-25 | Programación temporal | Fecha prevista y fecha límite son opcionales, pero su ausencia o vencimiento son visibles | Tarea válida sin fecha, clasificada como Sin programar; Tarea vencida clasificada como Atrasada | Convertir Sin programar o Atrasada en estados que sustituyan Pendiente | T-V03-025 |
| MV-26 | Texto y resultado | Objetivo, contexto y nota cumplen funciones diferentes | Objetivo obligatorio, contexto y nota de ejecución opcionales, resultado estructurado | Crear Nota de programación redundante o reemplazar el resultado por texto libre | T-V03-026 |
| MV-27 | Reprogramación y cancelación | No constituyen Actividades | Reprogramar con trazabilidad y cancelar con motivo | Inflar estadísticas creando Actividades por cambios administrativos | T-V03-027 |
| MV-28 | Compatibilidad Tipo–Resultado | Cada Tipo de Actividad admite sólo Resultados de Actividad compatibles | Llamada + No contestó; Reunión + Realizada | Llamada + Propuesta preparada u otra combinación incoherente | T-V03-028 |
| MV-29 | Consecuencias de Actividad | El Resultado describe lo ocurrido; los próximos pasos son hechos separados | Actividad que origina Tareas, Relación u Oportunidad trazables | Mezclar acción, resultado y consecuencia en una sola etiqueta | T-V03-029 |
| MV-30 | Métricas derivadas | Llamada efectiva, agendamiento y seguimiento se derivan de hechos persistentes | Derivar llamada efectiva desde Tipo y Resultado y agendamiento desde Actividad más Tarea futura | Guardar `Agenda reunión`, `Volver a llamar` o `Información enviada` como etiquetas ambiguas que sustituyan hechos | T-V03-030 |
| MV-31 | Ejecución múltiple | Una Actividad puede ejecutar varias Tareas compatibles cuyas Personas objetivo están comprendidas entre sus participantes y cuyo Asesor ejecutor coincide con el responsable de cada Tarea | Una llamada real que completa varias Tareas sin duplicar la Actividad | Crear Actividades ficticias o completar Tareas con Personas ausentes o Asesor incompatible | T-V03-031 |
| MV-32 | Reasignación de Tarea | El cambio de responsable es explícito y conserva historia | Reasignar una Tarea pendiente con Asesor anterior, nuevo, fecha y motivo | Reasignar automáticamente por transferencia de Relación o cambiar responsable silenciosamente | T-V03-032 |
| MV-33 | Corrección y anulación de Actividad | Una Actividad histórica no se elimina ni sobrescribe silenciosamente | Corregir o anular conservando original, cambio, actor o usuario, fecha y motivo | Borrar el registro o reemplazarlo sin trazabilidad | T-V03-033 |
| MV-34 | Efectos de anulación | Una Actividad anulada queda fuera de métricas y no sostiene consecuencias por sí sola | Mantener trazabilidad y advertir consecuencias para revisión | Contarla, usarla para completar Tareas o eliminar automáticamente hechos posteriores | T-V03-034 |
| MV-35 | Modificación de Tarea | Las Tareas Pendientes pueden cambiar con historial; las cerradas sólo se rectifican explícitamente | Modificar compromiso futuro conservando cambios sustantivos | Reescribir silenciosamente una Tarea Completada o Cancelada | T-V03-035 |
| MV-36 | Participación múltiple | Una única acción real o futura puede involucrar a una o varias Personas sin duplicarse | Una reunión o Tarea grupal con varios participantes | Crear una Actividad o Tarea idéntica por cada Persona | T-V03-036 |
| MV-37 | Consecuencias individualizadas | La participación grupal no produce automáticamente el mismo efecto comercial para todos | Crear Relación u Oportunidad sólo para la Persona con continuidad propia | Crear Relaciones para todos los participantes por el solo hecho de asistir | T-V03-037 |
| MV-38 | Tarea grupal sin Relación previa | Una Tarea puede incluir Personas sin Relación Comercial y no la crea por sí sola | Programar una reunión grupal con un acompañante aún sin Relación | Exigir Relación previa o crearla automáticamente por programar | T-V03-038 |
| MV-39 | Origen hacia otra Persona | Una Actividad puede originar una Tarea para Personas que no participaron en ella | Conversación con Ana que origina una Tarea para llamar a Pedro | Incorporar retroactivamente a Pedro como participante o crearle una Relación por la referencia | T-V03-039 |
| MV-40 | Simplicidad operativa | Las capacidades excepcionales no deben dominar el flujo frecuente | Ejecutar una Tarea individual sin gestionar controles grupales o excepcionales | Obligar a resolver casos raros en cada registro | T-V03-040 |
| MV-41 | Equivalencia de fuentes | TOTAL y ASIGNADOS observan los mismos hechos comerciales básicos; ASIGNADOS agrega la Asignación | Procesar ASIGNADOS antes o después de TOTAL sin Apariciones incompletas | Tratar ASIGNADOS como una fuente dependiente o semánticamente distinta | T-V03-041 |
| MV-42 | Orden propio de ASIGNADOS | La posición de ASIGNADOS pertenece a la lista reducida del Asesor | Conservar un orden propio del Asesor | Copiar el orden TOTAL o usarlo como sustituto | T-V03-042 |
| MV-43 | Asignación ausente en Campaña activa | Una ausencia posterior comparable es una discrepancia y no un término cierto | Mantener visible la Asignación como pendiente de conciliación y excluirla temporalmente de la cola normal | Terminarla automáticamente o mantenerla como gestionable confirmada | T-V03-043 |
| MV-44 | Agrupación de incidencias | Una anomalía común de archivo, Campaña, segmento o conjunto se representa primero mediante una incidencia de alcance | Una incidencia de alcance que agrupa miles de filas potencialmente afectadas | Crear incidencias individuales masivas por la misma causa mientras el problema de alcance siga abierto | T-V03-044 |
| MV-45 | Ejecución Aplicada | Una ejecución Aplicada incorporó o confirmó todos sus efectos válidos y no conserva incidencias abiertas | Filas reiteradas sin cambio dentro de una carga válida | Marcar Aplicada una ejecución con hechos dudosos pendientes | T-V03-045 |
| MV-46 | Aplicación parcial controlada | Aplicada con incidencias sólo procede cuando las anomalías son individuales, aisladas y separables | Aplicar hechos inequívocos y dejar lo dudoso pendiente | Usar aplicación parcial ante una anomalía que compromete el alcance general | T-V03-046 |
| MV-47 | Rechazo y fallo | Rechazada corresponde a una falla crítica de la fuente; Fallida, a un error técnico | Distinguir validación de negocio de interrupción técnica | Dejar efectos canónicos en una ejecución Rechazada o efectos parciales silenciosos en una Fallida | T-V03-047 |
| MV-48 | Atomicidad de aplicación | Cada efecto queda aplicado o pendiente y la ejecución final no puede quedar ambiguamente a medias | Recuperación explícita después de un fallo | Considerar exitosa una ejecución técnicamente incompleta | T-V03-048 |
| MV-49 | Retiro confirmado según fuente | TOTAL y ASIGNADOS producen consecuencias distintas al confirmar un retiro | Conservar Aparición en TOTAL y terminar Asignación en ASIGNADOS | Eliminar la Aparición histórica o tratar ambos retiros como equivalentes | T-V03-049 |
| MV-50 | Resolución y cierre de incidencia | `Sin explicación disponible` mantiene abierta la incidencia; la reaparición puede cerrarla automáticamente | Cierre automático trazable sin duplicar hechos | Registrar falta de explicación como resolución o inventar el motivo de la ausencia | T-V03-050 |
| MV-51 | Corrección posterior a la aplicación | Un defecto descubierto después de aplicar se corrige o compensa con trazabilidad | Nueva acción correctiva que preserve el antecedente | Borrar, reescribir o presentar como nunca aplicada la ejecución anterior | T-V03-051 |
| MV-52 | Caso Comercial | Representa un negocio indivisible y pertenece a Persona, Relación Comercial y Asesor propietario | Caso Nuevo sin Oportunidades | Caso sin Persona, Relación o Asesor | T-V03-052 |
| MV-53 | Pertenencia de Oportunidad | Toda Oportunidad pertenece exactamente a un Caso actual | Caso con cero o varias Oportunidades y traslado trazable | Oportunidad suelta o vinculada simultáneamente a varios Casos | T-V03-053 |
| MV-54 | Cotización | Es una configuración específica y pertenece exactamente a una Oportunidad | Varias configuraciones mutuamente excluyentes | Cotización sin Oportunidad o usada como Producto Contratado | T-V03-054 |
| MV-55 | Coexistencia comercial | Contratos que pueden celebrarse y persistir simultáneamente son Oportunidades distintas | Dos Oportunidades del mismo producto | Unir contrataciones independientes por coincidir en producto o fecha | T-V03-055 |
| MV-56 | Propuesta | Permanece como conocimiento descriptivo del Caso | Descripción, documentos y Actividades de preparación | Crear automáticamente entidades Propuesta, versión o composición | T-V03-056 |
| MV-57 | Unidad del Pipeline | El Caso posee una única etapa actual y una sola tarjeta | Una tarjeta derivada por Caso | Etapas por Oportunidad o el mismo Caso en varias columnas | T-V03-057 |
| MV-58 | Etapa Propuesta | Exige proyección vigente y fechas estimadas | Avanzar sin Cotización mediante confirmación | Avanzar sin CNS proyectados o fechas | T-V03-058 |
| MV-59 | Etapa En Firma | Exige Oportunidades aceptadas y una Cotización seleccionada para cada una | Varias Oportunidades aceptadas conjuntamente | En Firma sin alternativa aceptada o Cotización seleccionada | T-V03-059 |
| MV-60 | Etapa Sometido | Exige contrato firmado, CNS sometidos y fecha efectiva en una operación atómica | Diferencia entre proyección y sometimiento | Etapa Sometido sin hecho real o aplicación parcial | T-V03-060 |
| MV-61 | Etapa Emitido | Exige aceptación de compañía, CNS emitidos, fecha efectiva y Productos Contratados | Varias Oportunidades ganadas y varios Productos | Emitido sin Ganado, sin Producto o sin hecho real | T-V03-061 |
| MV-62 | Resultado Perdido | Es cierre, no etapa, y conserva la última etapa alcanzada | Reabrir con trazabilidad | Caso Perdido con Oportunidades ganadas | T-V03-062 |
| MV-63 | Movimientos y correcciones | Los movimientos ordinarios son reversibles antes de Sometido; hechos factuales sólo se corrigen explícitamente | Retroceder entre etapas comerciales y rectificar hechos | Sobrescribir sometimiento, emisión o cierre | T-V03-063 |
| MV-64 | CNS del Caso | Proyección, sometimiento y emisión son conocimientos distintos | Valores diferentes y revisiones trazables | Sobrescribirlos o crear saldos parciales automáticos | T-V03-064 |
| MV-65 | Doble conteo de CNS | El Caso aporta la magnitud correspondiente únicamente a su etapa actual | Reportes históricos de flujo separados del stock | Computar el mismo monto simultáneamente en varias etapas | T-V03-065 |
| MV-66 | Contexto de Tarea y Actividad | Personas y Asesor son esenciales; Relación, Casos y Oportunidades son opcionales | Tarea o Actividad sin Caso | Registro sin Persona o Asesor, o creación automática de contexto | T-V03-066 |
| MV-67 | Planificación y ejecución | La Tarea conserva contexto previsto y la Actividad contexto real | Actividad que corrige el contexto heredado | Sobrescribir silenciosamente la Tarea | T-V03-067 |
| MV-68 | Historial del Caso | Es una vista derivada de hechos y notas descriptivas | Cronología reconstruida y descripción vigente editable | Crear entidad Historial o reemplazar hechos por notas | T-V03-068 |
| MV-69 | Separación de Oportunidad | Traslada la Oportunidad sin copiarla y conserva trazabilidad | Nuevo Caso con misma Persona, Relación y Asesor por defecto | Duplicar identidad, Cotizaciones o historia | T-V03-069 |
| MV-70 | Proyección al separar | Ambos Casos deben revisar expresamente sus proyecciones | Redistribución manual coherente | Duplicar CNS proyectados entre origen y destino | T-V03-070 |
| MV-71 | Oportunidad ganada | Identifica exactamente una Cotización seleccionada | Descartar históricamente las restantes | Cero o varias Cotizaciones seleccionadas | T-V03-071 |
| MV-72 | Producto Contratado | Cada Oportunidad ganada origina exactamente uno al entrar en vigencia | Varios Productos por varias Oportunidades ganadas | Producto sin Oportunidad de origen o dos por la misma Oportunidad | T-V03-072 |
| MV-73 | Coherencia del cierre | Emitido posee al menos una Oportunidad ganada; Perdido ninguna | Ganar varias Oportunidades conjuntamente | Emitido sin ganadas o Perdido con ganadas | T-V03-073 |
| MV-74 | Evolución posterior | El Producto Contratado evoluciona sin reescribir antecedentes | Modificación o término posterior | Cambiar retroactivamente Cotización o resultado Ganado | T-V03-074 |
| MV-75 | Clasificación de reglas | Invariantes bloquean, advertencias requieren confirmación y recomendaciones no gobiernan validez | Confirmar una situación dudosa válida | Convertir toda heurística en restricción rígida | T-V03-075 |
| MV-76 | Advertencia por salto | Puede omitirse una etapa previa si se cumplen requisitos de destino | Salto confirmado y trazable | Saltar sin antecedentes obligatorios | T-V03-076 |
| MV-77 | Compatibilidad aparente | Una taxonomía incompleta genera advertencia y opción de reclasificar | Confirmar o separar productos coherentemente | Rechazar automáticamente por heurística no aprobada | T-V03-077 |
| MV-78 | Simplicidad de separación | La operación excepcional no domina el flujo normal | Divulgación progresiva para separar | Exigir revisar separación en cada Caso | T-V03-078 |

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

### CV-08 · ASIGNADOS observa los mismos hechos

```text
ASIGNADOS agosto:
Ana · Propensión Integral · No Gestionado · Guillermo

TOTAL agosto, cargado después:
Ana · Propensión Integral · No Gestionado
Pedro · Propensión Integral · No Gestionado
```

Resultado esperado:

- ASIGNADOS puede crear Persona, Campaña, Aparición, Resultado Corporativo, datos de contacto y Asignación para Ana;
- no se crea una Aparición incompleta ni una incidencia por falta de TOTAL previo;
- TOTAL no duplica a Ana y agrega la Aparición de Pedro;
- una Persona, una Aparición y una Asignación para Ana.

### CV-09 · Asignado sin identidad única de Campaña

**Dado** que la fila ASIGNADOS no permite determinar de manera única la Campaña concreta  
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

**Dado** que una Actividad tiene como participantes a Ana y Pedro y fue ejecutada por Guillermo  
**Cuando** se intenta usarla para ejecutar una Tarea que incluye a María o cuyo responsable es Carolina  
**Entonces** la operación se rechaza.

Toda Persona objetivo de la Tarea debe estar incluida en la Actividad de ejecución y el Asesor ejecutor debe coincidir con el responsable vigente.

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

### CV-22 · Ausencia en ASIGNADOS comparable dentro de Campaña activa

```text
ASIGNADOS_01 agosto:
Ana · Guillermo

ASIGNADOS_02 agosto comparable:
Ana no aparece
```

Resultado esperado:

- no se elimina la Asignación histórica;
- no se registra término automático;
- su vigencia actual queda pendiente de conciliación;
- se genera una incidencia;
- Ana permanece visible, pero queda fuera de la cola normal de gestionables;
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
**Entonces** conserva fecha, actor o usuario y motivo de cancelación, sin crear una Actividad ni afectar estadísticas de gestión.

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
**Entonces** se conservan el valor original, el valor corregido, la fecha, el actor o usuario que corrige y el motivo.

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
**Entonces** la operación se rechaza y cualquier rectificación debe registrarse explícitamente con actor o usuario, fecha y motivo.

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

### CV-39 · Referido que no participó en la Actividad de origen

**Dado** que Guillermo conversa con Ana  
**Y** Ana informa que su hermano Pedro también está interesado y solicita que lo contacten  
**Cuando** la Actividad con Ana origina una Tarea para llamar a Pedro  
**Entonces** Pedro es Persona objetivo de la Tarea, pero no participante de la conversación anterior.

La referencia no crea una Relación Comercial para Pedro. La futura llamada que incluya a Pedro será la Actividad que ejecute la Tarea.

### CV-40 · Flujo frecuente sin complejidad excepcional

**Dado** que Guillermo ejecuta una Tarea individual de Llamada para Ana  
**Cuando** registra el resultado  
**Entonces** la aplicación completa la Tarea mediante una Actividad sin exigir gestionar participantes adicionales, otras Tareas o Personas distintas.

Las capacidades excepcionales deben permanecer disponibles mediante acciones secundarias o divulgación progresiva.

### CV-41 · ASIGNADOS antes de TOTAL

**Dado** que se carga primero un archivo ASIGNADOS válido con las mismas columnas comerciales de TOTAL  
**Cuando** la fila identifica a Ana, su Campaña, Resultado Corporativo, datos de contacto y Asesor  
**Entonces** el sistema crea o actualiza todos esos hechos y registra la Asignación sin esperar TOTAL.

La llegada posterior de TOTAL vuelve a observar los mismos hechos sin duplicarlos.

### CV-42 · Posiciones independientes

**Dado** que Ana ocupa la posición 10.532 en TOTAL y la posición 17 en ASIGNADOS de Guillermo  
**Cuando** se procesan ambos archivos  
**Entonces** ambas posiciones se conservan en sus respectivos ámbitos.

Ninguna posición sustituye ni deriva de la otra.

### CV-43 · Ausencia sospechosa y alcance

**Dado** que una carga posterior comparable de la misma Campaña activa omite a una Persona antes presente  
**Entonces** se genera una conciliación individual sin eliminar ni terminar automáticamente el hecho anterior.

**Dado** que la carga omite una cantidad masiva, una Campaña o una sección reconocible  
**Entonces** se genera primero una incidencia de alcance y se evalúa bloquear o rechazar el archivo, sin crear miles de incidencias individuales.

### CV-44 · Una incidencia de alcance agrupa la anomalía común

**Dado** que una carga posterior omite 8.000 Personas pertenecientes a una misma Campaña o sección reconocible  
**Cuando** la anomalía puede explicarse por un único problema de archivo o alcance  
**Entonces** se crea una sola Incidencia de Conciliación de alcance y no 8.000 incidencias individuales.

Mientras la incidencia de alcance permanezca abierta, no se generan incidencias individuales por la misma causa. Si después se confirma que el archivo era correcto y sólo algunas filas requieren revisión, se crean únicamente las incidencias individuales correspondientes.

### CV-45 · Ejecución Aplicada sin incidencias

**Dado** que una carga válida contiene filas nuevas y filas que reiteran hechos ya conocidos  
**Cuando** todos sus efectos válidos se incorporan o confirman sin anomalías pendientes  
**Entonces** la Ejecución queda Aplicada y no conserva incidencias abiertas.

### CV-46 · Aplicación parcial controlada

**Dado** un archivo ASIGNADOS con 165 filas  
**Y** 164 filas inequívocas y una fila cuya Campaña es ambigua  
**Cuando** la anomalía individual no pone en duda el alcance general del archivo  
**Entonces** se aplican las 164 filas inequívocas, la fila ambigua queda pendiente con incidencia y la Ejecución queda Aplicada con incidencias.

Ningún hecho dudoso se inventa ni se aplica parcialmente.

### CV-47 · Rechazo por anomalía de alcance

**Dado** que una carga omite una Campaña completa o presenta una reducción masiva sospechosa  
**Cuando** no puede confiarse en la integridad general del archivo  
**Entonces** la Ejecución queda Rechazada y no modifica hechos canónicos.

### CV-48 · Fallo técnico sin efectos parciales silenciosos

**Dado** que una carga válida comienza su procesamiento  
**Cuando** una interrupción técnica impide completarlo  
**Entonces** la Ejecución queda Fallida y no se considera Aplicada ni Aplicada con incidencias.

La implementación debe revertir los efectos parciales o mantener la ejecución bloqueada para recuperación explícita antes de confirmar cualquier aplicación.

### CV-49 · Retiro confirmado con consecuencias distintas

**Dado** que una Persona deja de aparecer en TOTAL dentro de una Campaña activa  
**Y** la compañía confirma que fue retirada de ese universo  
**Entonces** se conserva la Persona, la Aparición histórica y el último Resultado Corporativo conocido, y se registra el retiro corporativo sin eliminar el hecho previo.

**Dado** que una Aparición deja de aparecer en ASIGNADOS  
**Y** se confirma que ya no pertenece a Guillermo  
**Entonces** termina la Asignación vigente, se conserva su historial y deja de ser gestionable por esa Asignación.

### CV-50 · Falta de explicación y reaparición

**Dado** que una ausencia no puede explicarse  
**Entonces** la incidencia permanece abierta y `Sin explicación disponible` no se registra como resolución.

**Cuando** la Persona reaparece después en una carga comparable  
**Entonces** la incidencia puede cerrarse automáticamente, sin duplicar Persona, Aparición ni Asignación y sin inventar el motivo de la ausencia anterior.

### CV-51 · Problema descubierto después de aplicar

**Dado** que una ejecución fue aplicada  
**Y** después se confirma que el archivo estaba incompleto o contenía un error relevante  
**Entonces** se registra una corrección o compensación posterior trazable.

La aplicación anterior no se borra ni se reescribe como si nunca hubiera ocurrido.

### CV-52 · Caso Nuevo sin Oportunidades

**Dado** que Ana posee una Relación Comercial y Guillermo es su Asesor responsable  
**Cuando** se identifica un negocio todavía impreciso  
**Entonces** puede crearse un Caso en `Nuevo` vinculado a Ana, su Relación y Guillermo, sin Oportunidades, Cotizaciones, CNS ni fechas.

### CV-53 · Oportunidad siempre dentro de un Caso

**Dado** que existe un producto potencial concreto  
**Cuando** se crea una Oportunidad  
**Entonces** debe pertenecer exactamente a un Caso actual.

Se rechaza crearla suelta o vincularla simultáneamente a dos Casos.

### CV-54 · Configuraciones de una misma contratación

**Dado** que Ana evalúa un mismo seguro con capitales de UF 2.000, UF 3.000 y UF 4.000  
**Y** sólo puede contratar una de esas configuraciones  
**Entonces** existe una Oportunidad con tres Cotizaciones.

### CV-55 · Dos contrataciones simultáneas

**Dado** que Ana puede contratar simultáneamente un APV y un seguro de vida  
**Entonces** se representan mediante dos Oportunidades, aunque se administren dentro del mismo Caso si avanzan y se resuelven conjuntamente.

### CV-56 · Propuesta descriptiva

**Dado** que Guillermo prepara una recomendación combinando Oportunidades, Cotizaciones y documentos  
**Entonces** puede conservar la descripción, las Actividades y las evidencias dentro del Caso.

No nace automáticamente una entidad Propuesta ni versiones estructuradas.

### CV-57 · Una sola tarjeta por Caso

**Dado** que un Caso contiene tres Oportunidades  
**Cuando** está en `Propuesta`  
**Entonces** el Kanban muestra una única tarjeta del Caso en `Propuesta`.

No aparecen tres tarjetas ni etapas independientes por Oportunidad.

### CV-58 · Ingreso a Propuesta

**Dado** un Caso en `Pendiente`  
**Y** una proyección de 80 CNS con fechas estimadas de sometimiento y emisión  
**Cuando** no existe todavía una Cotización  
**Entonces** el sistema advierte y permite continuar con confirmación.

Sin proyección o fechas, la operación se rechaza.

### CV-59 · Ingreso a En Firma

**Dado** que el cliente aceptó dos contrataciones dentro del mismo Caso  
**Cuando** cada Oportunidad aceptada tiene exactamente una Cotización seleccionada  
**Entonces** el Caso puede avanzar a `En Firma`.

Si falta una selección, la operación se rechaza.

### CV-60 · Sometimiento atómico

**Dado** un Caso en `En Firma` con contratos firmados  
**Cuando** se registran 76 CNS sometidos y la fecha efectiva  
**Entonces** el hecho y el cambio a `Sometido` se aplican juntos.

Una interrupción no puede dejar CNS registrados sin etapa ni etapa sin CNS.

### CV-61 · Emisión y Productos Contratados

**Dado** un Caso Sometido con dos Oportunidades aceptadas por la compañía  
**Cuando** se registran CNS emitidos, fecha efectiva, una Cotización seleccionada y un Producto Contratado por cada Oportunidad ganada  
**Entonces** el Caso pasa a `Emitido` y queda `Ganado`.

### CV-62 · Cierre Perdido y reapertura

**Dado** un Caso en `Propuesta` que se cierra sin contratación  
**Entonces** queda `Perdido`, conserva la etapa `Propuesta`, la fecha y el motivo.

**Cuando** se reabre  
**Entonces** recupera `Propuesta` y conserva el cierre anterior con trazabilidad.

### CV-63 · Corrección posterior a Sometido

**Dado** un Caso en `Sometido`  
**Cuando** se detecta que el registro fue erróneo  
**Entonces** sólo puede abandonar la etapa mediante una corrección explícita y motivada que preserve el sometimiento original.

### CV-64 · Evolución de CNS sin saldos parciales

```text
Proyección: 140 CNS
Sometimiento: 135 CNS
Emisión: 128 CNS
```

**Entonces** los tres valores permanecen como hechos distintos y la posición vigente computa 128 CNS en `Emitido`.

No se crean 5 CNS pendientes de sometimiento ni 7 CNS pendientes de emisión.

### CV-65 · Stock y flujo separados

**Dado** que un Caso fue sometido en agosto y emitido en agosto  
**Entonces** el flujo histórico puede mostrar ambos hechos.

El stock vigente lo cuenta una sola vez en `Emitido`, sin sumar sometimiento y emisión como producción adicional.

### CV-66 · Tarea sin Caso

**Dado** que Ana es Persona y Guillermo Asesor  
**Cuando** se crea una Tarea de llamada exploratoria sin Caso ni Oportunidad  
**Entonces** la Tarea es válida.

Crear o vincular la Tarea no crea automáticamente una Relación, Caso u Oportunidad.

### CV-67 · Contexto real distinto del previsto

**Dado** que una Tarea estaba prevista para el Caso A  
**Cuando** la llamada real trató el Caso B  
**Entonces** la Actividad registra el Caso B y la Tarea conserva el Caso A como planificación original.

El sistema advierte la diferencia y no sobrescribe silenciosamente la Tarea.

### CV-68 · Historial reconstruido

**Dado** que un Caso posee descripción vigente, notas, Actividades, cambios de etapa, una revisión de proyección y un sometimiento  
**Cuando** se abre su historial  
**Entonces** la cronología se reconstruye desde esos antecedentes.

Editar la descripción vigente no modifica los hechos previos ni crea una entidad Historial.

### CV-69 · Separación sin duplicación

**Dado** un Caso con Oportunidades A y B  
**Cuando** B necesita tiempos independientes  
**Entonces** B se traslada a un nuevo Caso, conserva identidad y Cotizaciones y deja de pertenecer al Caso original.

Ambos Casos conservan origen, destino, fecha y actor.

### CV-70 · Revisión de proyecciones al separar

**Dado** un Caso con proyección de 100 CNS  
**Cuando** una Oportunidad se separa  
**Entonces** el Asesor debe revisar la proyección de ambos Casos.

La suma o distribución resultante no puede conservar 100 CNS en ambos Casos por duplicación automática.

### CV-71 · Selección única al ganar

**Dado** una Oportunidad con tres Cotizaciones  
**Cuando** la Oportunidad resulta ganada  
**Entonces** queda exactamente una Cotización seleccionada y las otras dos permanecen descartadas históricamente.

### CV-72 · Un Producto por Oportunidad ganada

**Dado** un Caso Emitido con dos Oportunidades ganadas  
**Entonces** existen exactamente dos Productos Contratados, cada uno vinculado a su Oportunidad y Cotización de origen.

### CV-73 · Coherencia Ganado y Perdido

**Dado** un Caso `Emitido`  
**Entonces** posee al menos una Oportunidad ganada.

**Dado** un Caso `Perdido`  
**Entonces** no posee ninguna Oportunidad ganada ni Producto Contratado originado por ese cierre.

### CV-74 · Evolución posterior del contrato

**Dado** un Producto Contratado que posteriormente se modifica o termina  
**Entonces** conserva su Cotización y Oportunidad de origen.

El cambio posterior no convierte retroactivamente el Caso Ganado en Perdido.

### CV-75 · Invariante, advertencia y recomendación

**Dado** un Caso sin Asesor  
**Entonces** la creación se bloquea por invariante.

**Dado** un Caso que avanza a `Propuesta` sin Cotización, pero con proyección y fechas  
**Entonces** se exige confirmación por advertencia.

**Dado** un Caso en `Pendiente` sin descripción suficiente  
**Entonces** se recomienda completar el contexto, pero no se bloquea ni exige confirmación.

### CV-76 · Salto válido de etapa

**Dado** un Caso en `Nuevo` que ya cumple todos los requisitos de `En Firma`  
**Cuando** se intenta mover directamente  
**Entonces** el sistema advierte el salto y permite confirmarlo.

No puede omitir los requisitos obligatorios de la etapa de destino.

### CV-77 · Compatibilidad aparente de productos

**Dado** que una combinación parece incoherente según una taxonomía todavía incompleta  
**Entonces** el sistema advierte y permite confirmar, reclasificar o separar trazablemente.

No rechaza automáticamente salvo que se viole una invariante aprobada.

### CV-78 · Flujo normal sin separación visible

**Dado** un Caso frecuente con una Oportunidad que avanza como unidad  
**Cuando** el Asesor lo gestiona  
**Entonces** no debe resolver controles de separación ni múltiples Casos.

La separación permanece como acción secundaria excepcional.

## 4. Clasificación de decisiones

### Confirmadas para `next_v03`

- Persona independiente;
- Campaña mensual concreta;
- Aparición distinta de Asignación;
- toda Aparición válida normalmente tiene un único Resultado Corporativo vigente;
- la falta de resultado es una inconsistencia explícita, conciliable y no gestionable, nunca un tercer estado;
- Resultado Corporativo separado de la gestión propia;
- TOTAL y ASIGNADOS observan los mismos hechos comerciales básicos;
- ASIGNADOS agrega la pertenencia temporal al Asesor y puede procesarse antes o después de TOTAL;
- posición propia de ASIGNADOS dentro de la lista del Asesor, independiente de cualquier posición TOTAL;
- una Aparición tiene normalmente como máximo una Asignación vigente;
- la ausencia en ASIGNADOS comparable dentro de una Campaña activa deja la vigencia pendiente de conciliación y no produce término automático;
- la Asignación pendiente permanece visible, pero fuera de la cola normal de gestionables hasta confirmar continuidad;
- un retiro confirmado en TOTAL conserva Persona, Aparición histórica y último Resultado Corporativo conocido;
- un retiro confirmado en ASIGNADOS termina la Asignación vigente y conserva su historial;
- existe un único concepto Incidencia de Conciliación con alcance individual o de conjunto;
- toda incidencia conserva tipo, evidencia, estado, resolución y trazabilidad hacia las Ejecuciones de Importación relacionadas;
- `Sin explicación disponible` no es una resolución y mantiene abierta la incidencia;
- una reaparición posterior puede cerrar automáticamente una incidencia sin duplicar hechos ni explicar retroactivamente la ausencia;
- una incidencia de alcance agrupa anomalías comunes de archivo, Campaña, segmento o conjunto y evita incidencias individuales masivas por la misma causa mientras permanezca abierta;
- las ausencias masivas o estructuradas se tratan primero como posible problema de alcance;
- una Ejecución Aplicada incorporó o confirmó todos sus efectos válidos y no conserva incidencias abiertas;
- Aplicada con incidencias representa una aplicación parcial controlada exclusivamente ante anomalías individuales aisladas y separables;
- una Ejecución Rechazada no modifica hechos canónicos porque la fuente falló una validación crítica de estructura, contenido o alcance;
- una Ejecución Fallida representa un error técnico y no puede dejar efectos canónicos parciales silenciosos;
- cada efecto de importación queda aplicado o pendiente, nunca ambiguamente aplicado a medias;
- una incidencia de alcance abierta bloquea normalmente la aplicación de la carga;
- un defecto descubierto después de aplicar se corrige o compensa con trazabilidad y no borra la aplicación anterior;
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
- Asesor responsable de Tarea y Asesor ejecutor de Actividad como funciones distintas;
- interacción grupal representada mediante una sola Actividad o Tarea;
- consecuencias comerciales evaluadas individualmente por Persona;
- Tarea grupal válida aunque alguna Persona no posea Relación previa;
- una Actividad puede originar una Tarea para Personas que no participaron en ella;
- la referencia de origen no altera participantes ni crea una Relación para la Persona objetivo;
- catálogo común de Tipos de Actividad para Tarea y Actividad;
- cada Tipo de Actividad define los Resultados estructurados compatibles;
- el Resultado describe lo ocurrido y no las consecuencias posteriores;
- Tarea con Tipo y objetivo obligatorios y contexto opcional;
- ausencia de una Nota de programación separada;
- programación temporal opcional, pero visible cuando falta o vence;
- cada Tarea ejecutada se vincula a una única Actividad;
- una Actividad puede ejecutar varias Tareas compatibles cuyas Personas objetivo están entre sus participantes;
- no se duplican Actividades para representar una sola acción real;
- ejecución completa la Tarea aunque no alcance el objetivo comercial;
- cada nuevo intento requiere una nueva Tarea;
- resultado estructurado y nota libre de Actividad separados;
- creación de Tareas, Relaciones, Casos u Oportunidades como hechos separados de la Actividad que los origina;
- llamada efectiva, agendamiento y seguimiento como métricas derivadas;
- reprogramación y cancelación no constituyen Actividades;
- reasignación de Tarea explícita y con historial;
- transferencia de Relación Comercial sin reasignación automática de Tareas pendientes;
- Actividad inmutable en forma silenciosa y corregible o anulable sólo con trazabilidad;
- Actividad anulada excluida de métricas y de justificación de consecuencias;
- consecuencias de una Actividad corregida o anulada sujetas a revisión, no a borrado automático;
- cambios sustantivos de Tarea Pendiente con historial y rectificación explícita de Tareas cerradas;
- flujo habitual optimizado para una Persona, una Tarea, una Actividad y un Caso;
- capacidades excepcionales expuestas sólo mediante divulgación progresiva;
- nuevos casos hipotéticos incorporados al dominio sólo cuando alteren cardinalidad, invariantes, fuente de verdad o trazabilidad relevante;
- cargas TOTAL sucesivas e incrementales;
- comparación de ausencias sólo dentro del mismo período y Campaña activa comparable;
- cambio de período sin incidencias masivas;
- linaje mínimo e historial sólo ante cambios efectivos;
- Caso Comercial como negocio indivisible y unidad canónica del Pipeline;
- Caso inicialmente válido sin Oportunidades;
- Oportunidad como contratación potencial individualizable y perteneciente exactamente a un Caso;
- Cotización como configuración específica de una Oportunidad;
- Propuesta como conocimiento descriptivo y no entidad estructurada;
- una única etapa y tarjeta por Caso;
- etapas `Nuevo`, `Pendiente`, `Propuesta`, `En Firma`, `Sometido` y `Emitido`;
- `Ganado` y `Perdido` como resultados, con `Perdido` fuera del catálogo de etapas;
- requisitos obligatorios por etapa y atomicidad de Sometido y Emitido;
- correcciones factuales y reaperturas trazables;
- proyección vigente, sometimiento real y emisión real como conocimientos distintos;
- ausencia de doble conteo y saldos parciales automáticos de CNS;
- Personas y Asesor como vínculos esenciales de Tareas y Actividades y contexto comercial opcional;
- Tarea como contexto previsto y Actividad como contexto real;
- historial del Caso como vista derivada y notas sin ciclo de vida propio;
- separación de Oportunidad como traslado excepcional sin duplicación;
- una Cotización seleccionada y un Producto Contratado por cada Oportunidad ganada;
- evolución posterior del Producto Contratado sin reescritura de antecedentes;
- clasificación explícita de invariantes, advertencias y recomendaciones.

### Pendientes de diseño lógico o técnico

- clave lógica exacta de Campaña;
- forma física de la Autorización Excepcional;
- reglas exactas para derivar Lead, Cliente del Asesor y Relación dormida;
- catálogo inicial de Tipos y Resultados de Actividad;
- regla exacta cuando el Tipo realizado difiere del Tipo previsto;
- criterios exactos de compatibilidad para que una Actividad ejecute varias Tareas;
- experiencia asistida y simple para asociar opcionalmente varias Tareas, Personas, Casos u Oportunidades a una Actividad;
- mecanismo de divulgación progresiva para crear una Tarea hacia otra Persona desde una Actividad;
- representación física de las relaciones muchos-a-muchos entre Personas, Actividades, Tareas, Casos y Oportunidades;
- necesidad de atributos de participación, como rol o participante principal;
- derivación de métricas por acción y por Persona en Actividades grupales;
- representación física del historial de reprogramaciones;
- representación física del historial de responsables de Tarea;
- representación física de correcciones y anulaciones de Actividad;
- revisión operativa de consecuencias originadas por una Actividad posteriormente corregida o anulada;
- representación física de cambios significativos y rectificaciones de Tarea;
- representación física de Incidencia de Conciliación y sus alcances;
- representación física y UX de Asignaciones pendientes de conciliación;
- representación física de los estados de Ejecución de Importación;
- mecanismo transaccional y de recuperación ante fallos técnicos;
- formato y límites de objetivo, contexto, descripción, notas y evidencia documental;
- umbral de archivo incompleto;
- estructura del historial de datos de contacto;
- representación física de Caso, Oportunidad, Cotización, etapa y resultado;
- representación física del historial de etapas, proyecciones, sometimientos, emisiones, correcciones y reaperturas;
- mecanismo técnico de advertencias confirmables y recomendaciones;
- mecanismo transaccional de separación de una Oportunidad sin duplicación;
- representación física del origen del Producto Contratado;
- reglas particulares y ciclo posterior de Productos Contratados;
- nombres de tablas y columnas;
- restricciones SQL;
- índices;
- RLS;
- estrategia de migración desde Legacy.

## 5. Criterio para diseñar `next_v03`

El diseño físico puede comenzar sólo cuando:

1. esta matriz ampliada sea aprobada;
2. el Modelo Comercial ampliado sea aprobado;
3. el Modelo Operacional sea aprobado y permanezca coherente con estas reglas;
4. las contradicciones con documentos superiores estén resueltas;
5. los pendientes técnicos estén claramente separados de las reglas del dominio;
6. ADR-025 y LCD-20260802-01 completen revisión, equivalencia documental y aprobación formal;
7. las transiciones y casos conceptuales aquí descritos puedan expresarse mediante pruebas reproducibles sin introducir estados o entidades no aprobados.

Mientras LCD-20260802-01 permanezca en revisión, `next_v03` continúa bloqueado para diseño físico y SQL.

No es necesario completar antes de ese diseño la experiencia de usuario detallada, probabilidades, colores, automatizaciones, dashboards ni reglas particulares de cada producto.
