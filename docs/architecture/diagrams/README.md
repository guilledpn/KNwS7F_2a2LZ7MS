# Diagramas de arquitectura y transición

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Mantener una representación visual y versionada de:

1. la arquitectura actual de APP LLAMADOS Legacy;
2. la arquitectura base deseada para CRM Patrimonial Next;
3. la transición reversible entre ambos productos.

Los diagramas complementan la documentación escrita. No reemplazan el Modelo del Dominio, los ADR ni los documentos operativos.

## Vistas

- [`as-is-app-llamados.md`](./as-is-app-llamados.md): estado actual verificado del legacy, sus despliegues y acoplamientos.
- [`to-be-crm-patrimonial-next.md`](./to-be-crm-patrimonial-next.md): arquitectura objetivo con dominio, aplicación, puertos y adaptadores.
- [`migration-legacy-to-next.md`](./migration-legacy-to-next.md): mapa de etapas y posición actual de la transición.
- [`applied-case-agenda.md`](./applied-case-agenda.md): caso paralelo conceptual y aplicado para registrar `Agenda` y programar seguimiento.

## Convención visual

- **AS-IS** representa hechos observados. Las inferencias se indican expresamente.
- **TO-BE** representa decisiones aprobadas o propuestas pendientes de validación.
- **TRANSICIÓN** representa secuencia, controles, coexistencia y rollback.
- El código Mermaid es la fuente canónica.
- SVG y PNG, cuando existan, son artefactos derivados.

## Pareja conceptual y aplicada

Cuando una vista conceptual sea importante para comprender el proyecto, debe acompañarse con uno o más casos aplicados.

```text
vista conceptual
+
caso aplicado AS-IS verificado
+
caso aplicado TO-BE candidato
+
explicación de diferencias
```

Reglas:

- la vista conceptual explica responsabilidades, fronteras y dependencias;
- el caso aplicado muestra qué ocurre en una operación reconocible del CRM;
- el AS-IS aplicado debe basarse en código, datos, RPC, workflows o comportamiento observado;
- el TO-BE aplicado debe marcar expresamente los conceptos todavía candidatos;
- un ejemplo futuro no constituye por sí solo una decisión del Modelo del Dominio;
- cuando el dominio sea aprobado, el ejemplo debe actualizarse para representar esa decisión;
- una misma operación puede tener varios diagramas complementarios: estructura, secuencia, datos y despliegue.

## Tipos de diagrama

Cada diagrama debe declarar qué representa antes del bloque Mermaid.

| Tipo | Qué representa | Qué no debe inferirse |
|---|---|---|
| Capas o arquitectura | Responsabilidades y dirección de dependencias | No necesariamente orden temporal de ejecución |
| Mapa de módulos | Fronteras internas de conocimiento y responsabilidad | No una cadena obligatoria de procesos |
| Flujo operativo | Secuencia de pasos de una operación concreta | No la estructura completa del sistema |
| Secuencia aplicada | Participantes y llamadas de un caso concreto | No que todas las reglas del dominio estén aprobadas |
| Despliegue | Productos, artefactos, ambientes e infraestructura | No las reglas del negocio |
| Migración | Etapas, coexistencia, controles y rollback | No que todas las etapas estén implementadas |

## Significado de flechas y contenedores

- Flecha continua: uso, invocación, dependencia o secuencia según la leyenda local.
- Flecha discontinua con `implementa`: una tecnología satisface un contrato interno.
- Flecha discontinua con `estado`, `nota` o `control`: relación explicativa, no flujo de negocio.
- Contenedor: frontera o agrupación conceptual; no implica por sí solo una base de datos, proceso o despliegue separado.
- Ausencia de flecha: no significa que dos elementos jamás se relacionen; puede significar que la relación aún no fue validada.

## Reglas de claridad

Cada vista debe incluir:

1. propósito;
2. tipo de diagrama;
3. punto desde el cual debe leerse;
4. leyenda de términos técnicos no evidentes;
5. explicación inmediatamente posterior;
6. advertencia sobre lo que el diagrama no representa;
7. estado de certeza: verificado, inferido, candidato o pendiente;
8. vínculo a un caso aplicado cuando ayude a comprender el concepto.

Un mapa estructural no debe dibujarse como una secuencia lineal si eso puede interpretarse como un proceso.

## Regla de actualización

Un diagrama debe actualizarse cuando cambie alguno de estos elementos:

- producto o ambiente real;
- fuente canónica o artefacto generado;
- mecanismo de despliegue;
- dependencia arquitectónica;
- etapa de migración;
- concepto o frontera del dominio representada;
- comportamiento real del caso aplicado;
- decisión aprobada que reemplace un supuesto candidato.