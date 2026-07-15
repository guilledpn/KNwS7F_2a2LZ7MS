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

## Convención visual

- **AS-IS** representa hechos observados. Las inferencias se indican expresamente.
- **TO-BE** representa decisiones aprobadas o propuestas pendientes de validación.
- **TRANSICIÓN** representa secuencia, controles, coexistencia y rollback.
- El código Mermaid es la fuente canónica.
- SVG y PNG, cuando existan, son artefactos derivados.

## Regla de actualización

Un diagrama debe actualizarse cuando cambie alguno de estos elementos:

- producto o ambiente real;
- fuente canónica o artefacto generado;
- mecanismo de despliegue;
- dependencia arquitectónica;
- etapa de migración;
- concepto o frontera del dominio representada.
