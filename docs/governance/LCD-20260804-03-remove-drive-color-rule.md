# LCD-20260804-03 · Retiro de convención visual heredada de Drive

- Estado: Aprobado
- Fecha: 2026-08-04
- Issue: #59
- Pull Request: #60
- ADR: No corresponde

## Motivo

Las instrucciones operativas vigentes conservaron la regla:

> El rojo significa exclusivamente contenido pendiente de revisión del último LCD.

Esa convención pertenecía al mecanismo anterior de revisión de documentos editables en Google Drive. Después de la migración a Docs-as-Code, los cambios pendientes se representan mediante ramas, commits, Pull Requests, estado documental y revisión explícita; el color del texto no constituye un mecanismo de gobernanza.

Mantener la regla podía inducir a aplicar una convención visual obsoleta en archivos Markdown o en documentos que ya no utilizan ese flujo.

## Decisión

Retirar la regla de:

- `AGENTS.md`;
- `docs/operations/chatgpt-project-instructions.md`.

No reemplazarla por otra regla cromática.

La condición pendiente o aprobada de un cambio se determina mediante:

- estado del LCD o ADR;
- rama y Pull Request;
- registros canónicos;
- evidencia de revisión y merge.

## Alcance

También se actualizan:

- `docs/governance/lcd-registry.md`;
- `PROJECT_MAP.md`.

No se modifican documentos históricos que describan cómo funcionaba el mecanismo anterior.

## Impacto

- Constitución: sin cambios.
- Arquitectura: sin cambios.
- Modelo del Dominio: sin cambios.
- Backlog y Roadmap: sin cambios.
- Código de aplicación: sin cambios.
- Supabase, DEV, STAGING y PROD: sin cambios.

## Validación

- ausencia de la regla en las instrucciones operativas vigentes;
- conservación de la trazabilidad histórica;
- validación `Document governance` del Pull Request;
- diff limitado a documentación.
