# TRANSICIÓN · APP LLAMADOS Legacy hacia CRM Patrimonial Next

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Mostrar dónde estamos, qué protege cada etapa y cómo coexistirán Legacy y Next durante una sustitución gradual y reversible.

## Mapa general

```mermaid
flowchart LR
    S0["Etapa 0\nInventariar y planificar\nCOMPLETADA"] --> S1["Etapa 1\nProteger comportamiento\nEN CURSO"]
    S1 --> S2["Etapa 2\nClasificar fuente y artefacto"]
    S2 --> S3["Etapa 3\nCrear esqueleto del monorepo"]
    S3 --> S4["Etapa 4\nEncapsular Legacy"]
    S4 --> S5["Etapa 5\nNormalizar automatización"]
    S5 --> S6["Etapa 6\nCrear Next en DEV"]
    S6 --> S7["Etapa 7\nSustitución gradual"]
    S7 --> S8["Etapa 8\nDesacoplar la raíz"]
    S8 --> S9["Etapa 9\nLimpieza y cierre"]
```

## Posición actual

```mermaid
flowchart TD
    DONE["Etapa 0 aprobada\nInventario + matriz + estructura + plan"] --> NOW["Etapa 1A activa\nDiagramas + superficie crítica + smoke tests + caracterización"]
    NOW --> GATE["Puerta de aprobación\nRed mínima de seguridad repetible"]
    GATE --> NEXT["Siguiente etapa autorizable\nClasificar fuente y artefacto"]

    INCIDENT["Incidente de gestionabilidad"] --> SEPARATE["Trazabilidad y rama propias"]
    SEPARATE --> LATER["Corrección posterior con diagnóstico y rollback"]

    NOW -. no mezcla .-> INCIDENT
```

## Coexistencia durante la transición

```mermaid
flowchart LR
    USER["Usuario"] --> LEGACY["APP LLAMADOS Legacy\nproducto operativo"]

    subgraph REPO["Monorepo en transición"]
        LEGACYSRC["Fuente del legacy"]
        NEXTSRC["CRM Patrimonial Next"]
        TESTS["Pruebas de caracterización"]
        DOCS["Modelo + arquitectura + ADR"]
    end

    LEGACYSRC --> BUILDLEGACY["Build compatible"]
    BUILDLEGACY --> ROOT["Raíz productiva temporal"]
    ROOT --> LEGACY

    NEXTSRC --> NEXTDEV["Next en DEV con datos ficticios"]
    TESTS --> LEGACYSRC
    DOCS --> LEGACYSRC
    DOCS --> NEXTSRC

    NEXTDEV -. capacidad validada .-> STRANGLE["Sustitución gradual"]
    LEGACY -. camino preservado .-> STRANGLE
```

## Ciclo por capacidad

```mermaid
flowchart LR
    C1["Seleccionar capacidad"] --> C2["Caracterizar Legacy"]
    C2 --> C3["Validar modelo del dominio"]
    C3 --> C4["Implementar en Next"]
    C4 --> C5["Ejecutar en paralelo"]
    C5 --> C6["Comparar resultados"]
    C6 --> C7["Redirigir uso"]
    C7 --> C8["Observar estabilidad"]
    C8 --> C9["Retirar camino antiguo"]

    C6 -->|"Diferencias no explicadas"| ROLLBACK["Volver al camino Legacy"]
    C8 -->|"Regresión"| ROLLBACK
```

## Controles que acompañan todas las etapas

```mermaid
flowchart TB
    CHANGE["Cambio propuesto"] --> DOC["Documentar"]
    DOC --> TEST["Probar sin tocar PROD"]
    TEST --> REVIEW["Revisar diff y resultados"]
    REVIEW --> APPROVE["Aprobar"]
    APPROVE --> APPLY["Aplicar de forma controlada"]
    APPLY --> SMOKE["Smoke test"]
    SMOKE --> TRACE["Registrar trazabilidad"]

    TEST -->|"Falla no explicada"| STOP["Detener migración"]
    REVIEW -->|"Sin rollback"| STOP
    APPLY -->|"Inconsistencia"| STOP
```

## Regla de lectura

- Las etapas describen autorizaciones progresivas, no fechas rígidas.
- Completar una etapa no obliga a ejecutar inmediatamente la siguiente.
- Legacy permanece operativo mientras Next se construye y valida.
- Una capacidad sólo se retira del legacy después de demostrar equivalencia y estabilidad.
- Los incidentes productivos interrumpen la migración, pero no se mezclan documental ni técnicamente con ella.
