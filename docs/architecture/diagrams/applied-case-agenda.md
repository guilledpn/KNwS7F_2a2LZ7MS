# Caso aplicado · Registrar Agenda y programar seguimiento

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Acompañar la arquitectura conceptual con una operación reconocible del CRM: el usuario conversa con una persona, marca el resultado `Agenda` y, si corresponde, programa un seguimiento con fecha y hora.

Este documento contiene dos vistas paralelas:

1. **AS-IS verificado:** comportamiento observado en APP LLAMADOS Legacy y en sus RPC productivas.
2. **TO-BE candidato:** ejemplo de cómo podrían distribuirse las responsabilidades en CRM Patrimonial Next.

La vista futura es ilustrativa. No aprueba todavía una entidad `Reunión`, un agregado, estados definitivos ni una integración obligatoria con Google Calendar o Google Tasks.

## Distinción necesaria en el producto actual

En APP LLAMADOS, `Agenda` y `Recordatorio` no son hoy el mismo hecho:

- `Agenda` es un estado nuevo de la gestión realizada al contacto;
- el recordatorio contiene título, fecha y hora;
- Google Tasks es una integración opcional mediante webhook;
- marcar `Agenda` no crea por sí solo una cita de calendario.

## AS-IS verificado · Qué ocurre hoy

**Tipo:** diagrama de secuencia operativo.

**Lectura:** de arriba hacia abajo. Las flechas representan llamadas que ocurren durante la ejecución actual.

```mermaid
sequenceDiagram
    actor U as Usuario
    participant UI as index.html
    participant G as save_gestion_v2
    participant WQ as work_queue
    participant LOG as crm_log
    participant EV as crm_events y sprint
    participant T as Webhook Google Tasks
    participant R as save_reminder_v2

    U->>UI: Abre el contacto y pulsa Agenda
    UI->>UI: setEstado agenda
    UI->>G: Estado Agenda, ingreso y comentarios
    G->>WQ: Actualiza estado de gestión
    G->>LOG: Registra estado anterior y nuevo
    G->>EV: Registra evento analítico
    G-->>UI: Confirma work item y evento
    UI->>UI: Refresca lista, conteos, meta y Stats

    opt Usuario programa seguimiento
        U->>UI: Ingresa título, fecha y hora
        U->>UI: Pulsa Tasks
        UI->>T: Envía datos del contacto y seguimiento
        T-->>UI: Confirma envío
        UI->>R: Guarda título y fecha hora
        R->>WQ: Actualiza recordatorio del work item
        R-->>UI: Confirma guardado
    end
```

### Responsabilidades actuales observadas

| Elemento actual | Responsabilidad real |
|---|---|
| `index.html` | Dibuja la interfaz, cambia el estado local, coordina las llamadas y refresca conteos. |
| `save_gestion_v2` | Localiza el work item, actualiza la gestión y crea trazabilidad operacional y analítica. |
| `work_queue` | Conserva el estado vigente, comentarios, ingreso estimado y recordatorio del trabajo actual. |
| `crm_log` | Conserva el cambio desde el estado anterior al estado nuevo. |
| `crm_events` | Registra un evento analítico de gestión guardada. |
| Sprint activo | Incrementa llamadas y agendas cuando corresponde. |
| Webhook de Google Tasks | Recibe opcionalmente los datos para crear una tarea externa. |
| `save_reminder_v2` | Guarda título y fecha hora del recordatorio en el work item. |

### Lectura arquitectónica del AS-IS

El sistema actual funciona, pero las responsabilidades no están separadas en capas hexagonales explícitas:

```mermaid
flowchart LR
    USER[Usuario] --> PAGE[index.html]
    PAGE --> LOCAL[Estado local y coordinación]
    PAGE --> RPC[RPC de Supabase]
    RPC --> DATA[Persistencia y trazabilidad]
    PAGE --> EXT[Webhook externo opcional]
```

La regla de negocio `qué significa Agenda` aparece distribuida entre etiquetas de interfaz, JavaScript, funciones SQL y métricas derivadas. El diagrama describe ese hecho; no lo juzga ni lo modifica.

## TO-BE candidato · Cómo podrían separarse las responsabilidades

**Tipo:** ejemplo aplicado de arquitectura hexagonal.

**Lectura:** de izquierda a derecha durante la ejecución. La arquitectura estable continúa leyéndose desde el dominio hacia afuera.

Los nombres `AgendarReunión`, `ReuniónAgendada` y `Puerto de Calendario` son candidatos pedagógicos pendientes de validación en el Modelo del Dominio.

```mermaid
sequenceDiagram
    actor U as Usuario
    participant WEB as Adaptador web
    participant IN as Puerto de entrada
    participant APP as Caso de uso AgendarReunión
    participant DOM as Dominio
    participant REP as Puerto de reuniones
    participant CAL as Puerto de calendario
    participant DB as Adaptador Supabase
    participant EXT as Adaptador calendario externo

    U->>WEB: Selecciona persona, fecha, hora y notas
    WEB->>IN: Solicita agendar reunión
    IN->>APP: Ejecuta comando
    APP->>DOM: Propone crear o modificar la reunión
    DOM->>DOM: Aplica reglas aprobadas del negocio
    DOM-->>APP: Entrega resultado o rechazo explicado
    APP->>REP: Guarda el hecho validado
    REP->>DB: Usa implementación configurada
    DB-->>APP: Confirma persistencia

    opt Sincronización externa habilitada
        APP->>CAL: Solicita crear evento externo
        CAL->>EXT: Usa implementación configurada
        EXT-->>APP: Devuelve identificador o error
    end

    APP-->>IN: Devuelve resultado del caso de uso
    IN-->>WEB: Respuesta para la interfaz
    WEB-->>U: Muestra confirmación o explicación
```

## Correspondencia entre conceptos y el caso aplicado

| Concepto arquitectónico | Ejemplo aplicado candidato |
|---|---|
| Dominio | Decide qué constituye una reunión válida y qué hechos deben conservarse. |
| Aplicación | Coordina el caso de uso completo y sus transacciones. |
| Puerto de entrada | Contrato para solicitar `AgendarReunión`. |
| Puerto de salida | Contrato para guardar la reunión o sincronizar un calendario. |
| Adaptador web | Convierte formulario o clics en un comando de aplicación. |
| Adaptador Supabase | Traduce el puerto de persistencia a tablas, RPC o transacciones concretas. |
| Adaptador externo | Traduce el puerto de calendario a Google Calendar, Tasks u otro proveedor. |
| Composición | Decide al arrancar qué adaptadores concretos satisfacen cada puerto. |

## Comparación resumida

```mermaid
flowchart TB
    subgraph CURRENT[AS-IS Legacy]
        C1[index.html coordina]
        C2[RPC guarda y registra]
        C3[Webhook Tasks opcional]
        C1 --> C2
        C1 --> C3
    end

    subgraph TARGET[TO-BE candidato]
        T1[Adaptador web]
        T2[Caso de uso]
        T3[Dominio]
        T4[Puertos]
        T5[Adaptadores concretos]
        T1 --> T2
        T2 --> T3
        T2 --> T4
        T5 -. implementa .-> T4
    end
```

## Decisiones que este ejemplo no toma

- No decide si `Agenda` seguirá siendo un estado, un resultado de gestión o una reunión independiente.
- No decide si una reunión pertenece a Persona, Caso Comercial, Oportunidad u otro agregado.
- No decide si el proveedor externo será Google Tasks, Google Calendar u otro.
- No obliga a sincronizar externamente todas las agendas.
- No define aún reglas de reprogramación, cancelación, asistentes, zona horaria o conflictos.
- No reemplaza el levantamiento formal del dominio.

## Uso esperado

Este patrón debe repetirse para capacidades relevantes:

```text
vista conceptual
+
caso aplicado AS-IS verificado
+
caso aplicado TO-BE candidato
+
explicación de diferencias
```

Los futuros casos pueden incluir importación mensual, evaluación de gestionabilidad, registro de una llamada, creación de una oportunidad y contratación de un producto.