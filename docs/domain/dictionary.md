# Diccionario del Dominio del CRM Patrimonial

- Estado: Aprobado y evolutivo
- Versión: 1.1
- Última reconciliación aprobada: 2026-08-04
- LCD: LCD-20260803-01 y LCD-20260804-01

Las definiciones extensas y reglas completas viven en los modelos especializados.

| Término | Definición canónica breve |
|---|---|
| Persona | Identidad natural central del CRM, independiente de campañas, relaciones y oportunidades |
| Prospecto / Contacto | Clasificaciones corporativas de una Persona; no crean entidades propias ni implican relación con el Asesor |
| Cliente de la Compañía | Persona que mantiene o mantuvo una relación contractual con la compañía |
| Cliente del Asesor | Persona con al menos un Producto Contratado vigente asociado al Asesor |
| Campaña | Agrupación corporativa y temporal que origina Apariciones |
| Aparición en Campaña | Hecho de que una Persona fue incluida en una Campaña y período determinados |
| Resultado Corporativo | Clasificación resumida `Gestionado` o `No Gestionado`; no sustituye la gestión interna |
| Asignación | Vínculo temporal entre una Aparición y un Asesor |
| Gestionabilidad | Decisión derivada sobre si una Persona integra la cola operativa conforme a la política vigente |
| Relación Comercial | Vínculo persistente entre Persona y organización asesora; no nace por una carga ni por un intento sin contacto efectivo |
| Responsabilidad del Asesor | Vigencia trazable del Asesor responsable de una Relación Comercial |
| Caso Comercial | Negocio concreto administrado como una unidad del Pipeline; puede contener 0..N Oportunidades |
| Oportunidad | Contratación potencial individualizable de un producto concreto dentro de un Caso |
| Cotización | Configuración específica y alternativa de una Oportunidad |
| Propuesta | Conocimiento descriptivo de lo presentado al cliente; no es una entidad estructurada en el modelo mínimo |
| Etapa del Caso | Posición vigente del Caso: `Nuevo`, `Pendiente`, `Propuesta`, `En Firma`, `Sometido` o `Emitido` |
| Resultado del Caso | `Ganado` al alcanzar `Emitido`, o `Perdido` antes de ello; no es una etapa |
| Producto Contratado | Entidad persistente nacida de una Oportunidad ganada y una Cotización seleccionada |
| Tarea | Acción futura planificada, con Personas objetivo y Asesor responsable |
| Actividad | Hecho real ocurrido, con Personas participantes y Asesor ejecutor |
| Contacto Trabajado | Métrica diaria derivada: Persona con al menos un Cambio Significativo de Estado en la fecha local |
| Cambio Significativo de Estado | Transición real de estado; excluye repeticiones y guardados sin cambio |
| Resultado Diario de Gestión | Último estado significativo de una Persona en una fecha local |
| Llamada Efectiva | Contacto Trabajado cuyo Resultado Diario es `Agenda` o `No agenda`; no prueba por sí solo una llamada técnica |
| Agendamiento | Contacto Trabajado cuyo Resultado Diario es `Agenda` |
| Meta Mensual de Agendamientos | Objetivo operativo configurable por mes desde Ajustes; gobierna el ritmo y las proyecciones del cockpit, pero no altera Agendamientos reales |
| Equivalencia Esperada por Agendamiento | Supuesto configurable que expresa CNS y pesos esperados por cada Agendamiento; no constituye CNS sometidos, emitidos o reconocidos ni ingreso devengado |
| Pulso Pecuniario Esperado | Vista derivada que multiplica Agendamientos por la Equivalencia Esperada vigente para una ventana temporal explícita |
| Conversión Efectiva | Agendamientos divididos por Llamadas Efectivas |
| Contactos Trabajados por Agendamiento | Contactos Trabajados divididos por Agendamientos |
| Ejecución de Importación | Proceso trazable que valida y aplica una fuente sin confundirla con el hecho de negocio |
| CNS | Magnitud comercial; se distinguen proyección, sometimiento, emisión y reconocimiento |
| Sometimiento | Hecho de ingreso contractual a evaluación de la compañía y etapa factual del Caso |
| Emisión | Hecho de aceptación plena por la compañía; determina `Emitido` y `Ganado` |
| CNS reconocidos | Reconocimiento posterior de producción; no se deduce automáticamente de la emisión |
| Capital | Magnitud patrimonial asociada a la contratación o a sus movimientos; no equivale a CNS |
| Movimiento de Capital | Inyección, traspaso, aporte, retiro, rescate u otro hecho esperado o materializado |
| Vehículo de Inversión | Marco jurídico, tributario, sucesorio, operativo y de costos de una inversión |
| Estrategia de Inversión | Asignación de activos y lógica financiera orientada a un objetivo, independiente del vehículo |
| Portafolio | Materialización de una estrategia mediante Posiciones |
| Posición | Participación porcentual o monetaria en una Serie específica de un Fondo |
| Fondo | Patrimonio de inversión colectiva que puede ofrecer varias Series |
| Serie | Clase concreta de participación, con elegibilidad, canal, costos y rentabilidad propios |
| Cartera Actual | Portafolio vigente de la Persona |
| Cartera Propuesta | Portafolio recomendado por el Asesor |
| Perfil de Riesgo | Clasificación declarada o analítica; la corporativa usa Conservador, Moderado y Agresivo |
