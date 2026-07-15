# TO-BE · CRM Patrimonial Next

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Representar la arquitectura base deseada para CRM Patrimonial Next: monolito modular, DDD y arquitectura hexagonal, con dependencias dirigidas hacia el dominio.

## Vista hexagonal simplificada

```mermaid
flowchart LR
    WEB["Adaptador web"] --> APP["Aplicación\ncasos de uso"]
    IMPORT["Adaptador de importación"] --> APP
    APIIN["API o integración de entrada"] --> APP

    APP --> DOMAIN["Dominio\nentidades + objetos de valor + reglas"]
    APP --> PORTS["Puertos internos"]

    SUPA["Adaptador Supabase"] -. implementa .-> PORTS
    EXTERNAL["Adaptadores externos"] -. implementa .-> PORTS
    MEMORY["Adaptadores falsos para pruebas"] -. implementa .-> PORTS

    COMPOSE["Composición"] --> WEB
    COMPOSE --> IMPORT
    COMPOSE --> SUPA
    COMPOSE --> EXTERNAL
```

## Dirección de dependencias

```mermaid
flowchart TD
    OUTER["Tecnología externa"] --> ADAPTERS["Adaptadores"]
    ADAPTERS --> APPLICATION["Aplicación"]
    APPLICATION --> DOMAIN["Dominio"]

    RULE["El dominio no conoce HTML, Supabase, HTTP, Excel ni almacenamiento"]
    DOMAIN -. protege .-> RULE
```

## Monolito modular por contextos

```mermaid
flowchart TB
    subgraph PRODUCT["CRM Patrimonial Next"]
        ID["Identidad y Contactabilidad"]
        CAMPAIGNS["Adquisición y Campañas"]
        OPS["Gestión Operativa"]
        COMMERCIAL["Gestión Comercial"]
        CATALOG["Catálogo de Productos"]
        CONTRACTS["Productos Contratados y Postventa"]
        INVESTMENTS["Patrimonio e Inversiones"]
        ANALYTICS["Proyección y Analítica"]
    end

    ID --> CAMPAIGNS
    CAMPAIGNS --> OPS
    OPS --> COMMERCIAL
    CATALOG --> COMMERCIAL
    COMMERCIAL --> CONTRACTS
    CONTRACTS --> INVESTMENTS
    INVESTMENTS --> ANALYTICS

    NOTE["Fronteras candidatas\npendientes de validación formal"]
    PRODUCT -. estado .-> NOTE
```

## Patrón interno de un contexto

```mermaid
flowchart LR
    IN["Adaptadores de entrada"] --> UC["Casos de uso"]
    UC --> ENT["Entidades y reglas"]
    UC --> PORT["Puertos"]
    OUT["Adaptadores de salida"] -. implementan .-> PORT
```

## Reglas arquitectónicas

- El dominio representa conocimiento, invariantes y comportamiento del negocio.
- La aplicación coordina casos de uso y transacciones, sin detalles visuales.
- Los puertos expresan capacidades requeridas por el interior.
- Los adaptadores traducen entre contratos internos y tecnologías externas.
- Supabase es infraestructura; no gobierna el modelo del dominio.
- Los contextos comparten repositorio y despliegue, pero conservan fronteras explícitas.
- No se extraen paquetes compartidos antes de demostrar reutilización real.
- DEV usa datos ficticios y nunca apunta a PROD.

## Primera vertical candidata

```mermaid
flowchart LR
    INPUT["Persona + campañas + período"] --> USECASE["EvaluarGestionabilidad"]
    USECASE --> RULES["Reglas del dominio"]
    RULES --> RESULT["Gestionable o no gestionable\ncon explicación"]

    REPO["Puerto de historial de campañas"] --> USECASE
    CLOCK["Puerto de período vigente"] --> USECASE
    FAKE["Adaptadores falsos"] -. implementan .-> REPO
    DEV["Adaptadores DEV"] -. implementan .-> REPO
```

Esta vertical es candidata, no una implementación aprobada. Primero deben validarse sus conceptos, reglas y fuentes canónicas.
