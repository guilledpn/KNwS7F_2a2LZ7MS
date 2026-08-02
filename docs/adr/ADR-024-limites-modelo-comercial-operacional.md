# ADR-024 · Límites entre Modelo Comercial y Modelo Operacional de CRM Patrimonial Next

- Fecha: 2026-08-01
- Estado: Pendiente de revisión
- LCD: LCD-20260801-02
- Issue: #31

## Contexto

El diseño experimental `next_v02` mostró que varios conceptos estaban mezclando conocimiento del negocio con mecanismos de importación y conciliación. Esa mezcla dificultaba comprender el modelo, aumentaba el número de tablas técnicas y podía convertir observaciones de archivos en supuestos hechos comerciales.

El Índice del Modelo del Dominio ya preveía dos documentos especializados pendientes:

- Modelo Comercial, para describir la operación y los hechos comerciales;
- Modelo Operacional, para describir importadores, sincronizaciones, automatizaciones, campañas operativas, continuidad y migraciones.

La Matriz de Validación aprobada para `next_v03` exige fijar esa frontera antes de diseñar SQL.

## Decisión

### Modelo Comercial

Contendrá los conceptos y reglas que explican qué ocurre en el negocio con independencia de la tecnología utilizada:

- Persona;
- Asesor;
- Campaña mensual;
- Aparición en Campaña;
- Resultado Corporativo;
- Asignación;
- Relación Comercial;
- Responsabilidad del Asesor;
- autorización excepcional de responsabilidad simultánea;
- Actividad;
- Tarea.

El Modelo Comercial conserva hechos e invariantes del negocio. No describe archivos, staging, hashes, reintentos ni procesos de carga.

### Modelo Operacional

Contendrá los procesos y controles que incorporan, comparan y concilian información externa:

- ejecución de importaciones;
- cargas TOTAL y ASIGNADOS;
- validación de archivo y alcance;
- idempotencia;
- linaje de creación, observación y cambio;
- comparación entre snapshots sucesivos del mismo período y campaña;
- incidencias de conciliación;
- tratamiento de archivos incompletos;
- activación de una campaña posterior;
- continuidad y recuperación operativa.

El Modelo Operacional no redefine Persona, Campaña, Aparición, Asignación ni Relación Comercial. Sólo explica cómo los procesos observan o modifican esos hechos conforme a las reglas del Modelo Comercial.

### Criterio de entrada para `next_v03`

La aprobación del Modelo Comercial, el Modelo Operacional y la Matriz de Validación actuales es necesaria, pero no suficiente, para congelar el diseño físico de `next_v03`.

Antes de diseñar el esquema físico debe aprobarse, mediante un LCD posterior, el modelo mínimo de desarrollo comercial que defina:

- Caso Comercial;
- Oportunidad;
- Propuesta;
- Pipeline;
- límites de vinculación opcional de Tareas y Actividades con Relación Comercial, Caso Comercial y Oportunidad.

No es requisito definir todavía:

- experiencia de usuario detallada;
- nombres definitivos de todas las etapas;
- probabilidades comerciales;
- colores;
- automatizaciones;
- dashboards;
- reglas particulares de cada producto.

La hipótesis estructural de trabajo, pendiente de validación en ese LCD posterior, es que la Relación Comercial persiste, el Caso Comercial agrupa un desarrollo relacionado y la Oportunidad recorre el Pipeline.

## Invariantes principales

1. Una Persona existe independientemente de campañas e importaciones.
2. Una Persona posee como máximo una Relación Comercial persistente dentro del CRM.
3. Una Relación Comercial tiene normalmente un solo Asesor responsable vigente.
4. La responsabilidad simultánea de un segundo Asesor requiere autorización explícita y trazable de un usuario con rol Administrador.
5. La autorización no crea otra Relación Comercial.
6. Aparición y Asignación son hechos distintos.
7. Las cargas TOTAL son observaciones sucesivas e incrementales dentro de un mismo período.
8. La ausencia sólo se concilia entre cargas comparables del mismo período y campaña.
9. El cambio de período no genera incidencias por Personas que no reaparecen.
10. Los procesos registran cambios efectivos y linaje mínimo, no copias permanentes de cada fila idéntica.
11. `next_v03` no se congela antes de definir el modelo mínimo de Caso Comercial, Oportunidad, Propuesta y Pipeline.

## Administrador

`Administrador` no se incorpora por ahora como entidad comercial. Es un rol de autorización de un usuario del sistema.

El hecho relevante para el dominio es la autorización excepcional, que debe conservar:

- Relación Comercial afectada;
- Asesor adicional autorizado;
- identidad del usuario autorizante;
- fecha;
- motivo;
- vigencia o término, cuando corresponda.

La representación física de esta autorización se resolverá durante el diseño de `next_v03`.

## Consecuencias positivas

- El modelo comercial puede entenderse sin conocer el importador.
- Los procesos de carga no adquieren autoridad semántica sobre el negocio.
- Se reduce la tentación de almacenar observaciones negativas masivas.
- Las reglas pueden transformarse en pruebas conceptuales y luego en restricciones SQL.
- Los diagramas pueden organizarse por áreas sin inventar esquemas o microservicios.
- El esquema físico no se congela antes de resolver los conceptos comerciales que determinan sus cardinalidades y fuentes de verdad.

## Costos y pendientes

- El Diccionario del Dominio deberá incorporar posteriormente Asesor, Responsabilidad del Asesor, Autorización Excepcional, Importación e Incidencia de Conciliación.
- La identificación interna exacta de Campaña queda pendiente del diseño lógico.
- El umbral técnico para bloquear archivos aparentemente incompletos no es una regla del dominio.
- La estructura física del historial de datos de contacto queda pendiente.
- El LCD actual debe consolidarse y cerrarse antes de abrir el LCD del modelo mínimo de desarrollo comercial.
- La creación de `next_v03` no queda autorizada hasta aprobar los modelos y la matriz actuales y, posteriormente, el modelo mínimo de Caso Comercial, Oportunidad, Propuesta y Pipeline.

## Alternativas descartadas

### Un solo modelo con conceptos comerciales y técnicos

Descartado porque reproduce el acoplamiento observado en `next_v02`.

### Crear contextos o esquemas PostgreSQL separados inmediatamente

Descartado porque la separación documental no demuestra todavía una necesidad de separación física.

### Guardar una observación permanente por cada fila y por cada ausencia

Descartado por volumen, ambigüedad semántica y falta de una necesidad de negocio que lo justifique.

### Congelar `next_v03` antes de definir el desarrollo comercial mínimo

Descartado porque obligaría a fijar cardinalidades y vínculos de Tareas y Actividades sin haber definido Caso Comercial, Oportunidad, Propuesta ni el propietario real del Pipeline.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/operational-model.md`;
- `docs/domain/validation-matrix-next-v03.md`.
