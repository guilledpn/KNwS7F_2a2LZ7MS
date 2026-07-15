# AS-IS · APP LLAMADOS Legacy

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Representar la arquitectura y el flujo técnico actuales de APP LLAMADOS sin reinterpretarlos como si ya existiera una separación hexagonal.

## Vista general actual

```mermaid
flowchart LR
    USER["Usuario en escritorio o móvil"] --> PAGES["GitHub Pages"]

    subgraph REPO["Repositorio actual"]
        ROOT["Raíz productiva"]
        INDEX["index.html\nUI + coordinación + lógica legacy"]
        PWA["manifest + service worker + iconos"]
        AUX["stats + reset + rescate + sprint"]
        SRCDEV["src/dev\nmodularización parcial"]
        TOOLS["tools\nbuild + parches + validadores"]
        DEVART["dev\nartefacto generado"]
        WORKFLOWS["GitHub Actions"]
        SQL["supabase\nmigraciones y funciones"]
    end

    PAGES --> ROOT
    ROOT --> INDEX
    ROOT --> PWA
    ROOT --> AUX

    INDEX --> AUTH["Supabase Auth"]
    INDEX --> DB["PostgreSQL + RLS"]
    INDEX --> RPC["RPC"]

    SRCDEV --> TOOLS
    INDEX --> TOOLS
    TOOLS --> DEVART
    WORKFLOWS --> TOOLS
    WORKFLOWS --> ROOT
    WORKFLOWS --> DEVART
    SQL --> DB
    SQL --> RPC
```

## Flujo operativo simplificado

```mermaid
flowchart TD
    EXCEL["Base mensual o asignada"] --> IMPORT["Importador legacy"]
    IMPORT --> CONTACTS["Contactos e historia mensual"]
    IMPORT --> QUEUE["Cola de trabajo"]

    QUEUE --> LIST["Lista y filtros en la PWA"]
    CONTACTS --> DETAIL["Detalle del contacto"]
    LIST --> DETAIL

    DETAIL --> ACTION["Registrar gestión"]
    ACTION --> LOG["Historial de gestiones"]
    ACTION --> TASKS["Recordatorios y tareas"]
    LOG --> STATS["Estadísticas derivadas"]
    TASKS --> STATS
```

## Dependencias y acoplamientos relevantes

```mermaid
flowchart TD
    UI["Interfaz"] --> LEGACY["Lógica legacy"]
    LEGACY --> DATA["Acceso a Supabase"]
    LEGACY --> STORAGE["Almacenamiento local"]
    LEGACY --> PWAAPI["APIs del navegador y PWA"]
    LEGACY --> IMPORTS["Procesamiento de importaciones"]

    NOTE["Las responsabilidades están parcialmente mezcladas\ny el dominio comercial continúa acoplado al frontend"]
    LEGACY -. evidencia .-> NOTE
```

## Lectura arquitectónica

- La raíz del repositorio es simultáneamente fuente manual y artefacto publicado de PROD.
- `index.html` concentra interfaz, coordinación y parte relevante de la lógica legacy.
- Supabase presta autenticación, persistencia, RLS y RPC.
- `src/dev/` contiene modularización parcial, pero no constituye CRM Patrimonial Next.
- `dev/` es un artefacto construido desde PROD, módulos DEV y herramientas Python.
- Los workflows actuales pueden validar, construir y también confirmar cambios generados en `main`.

## Qué no afirma este diagrama

- No afirma que toda la lógica esté exclusivamente en `index.html`.
- No afirma que la arquitectura actual sea hexagonal.
- No considera `dev/` una aplicación independiente.
- No autoriza mover la raíz productiva.
- No corrige ni redefine reglas de negocio.

## Pendientes de refinamiento

- mapear con mayor detalle las funciones de `stats.html`, `sprint.js`, `reset.html` y `rescate.html`;
- inventariar cada workflow y herramienta con su consumidor;
- representar tablas y RPC críticas después de la auditoría de Supabase;
- agregar el flujo exacto de importación y cálculo de gestionabilidad una vez documentado y validado.
