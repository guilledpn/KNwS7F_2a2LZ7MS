# Registro canónico de Decisiones Arquitectónicas

- Estado: Vigente
- Fecha de reconciliación: 2026-08-01
- LCD rector: LCD-20260801-01
- Issue: #28

Este archivo gobierna la asignación de identificadores ADR. Las decisiones ADR-001 a ADR-020 permanecen íntegramente en la Bitácora Arquitectónica de Drive hasta que esa bitácora sea migrada y validada.

## Registro

| ADR | Decisión | Estado | Ubicación canónica actual | LCD |
|---|---|---|---|---|
| ADR-001 | Caso Comercial como estrategia patrimonial | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-002 | Oportunidad como contratación potencial individualizable | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-003 | Cotización como configuración de una Oportunidad | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-004 | Separación entre Estrategia y Vehículo de Inversión | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-005 | Portafolio como concepto transversal | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-006 | Las Posiciones pertenecen a Series de Fondos | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-007 | Producto Contratado como entidad persistente | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-008 | Emisión, capital y CNS como hechos distintos | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-009 | Proyección como vista global del ejecutivo | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-010 | Historial detallado para productos APV | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-011 | Actividades vinculables a Casos y Oportunidades | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-012 | Oportunidades como hipótesis complementarias o alternativas | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-013 | Doble capa del concepto Cliente | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-014 | Series determinadas por Producto | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-015 | Definición explícita de métricas de rentabilidad | Aprobado con verificación normativa pendiente | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-016 | Perfil de Riesgo corporativo | Aprobado | Bitácora Arquitectónica en Drive | Documentación fundacional |
| ADR-017 | Estructura canónica del Modelo de Productos | Pendiente de revisión | Bitácora Arquitectónica en Drive | LCD-20260712-01 |
| ADR-018 | Métricas operativas derivadas por Persona y día | Aprobado y promovido | Bitácora Arquitectónica en Drive | LCD-20260713-01 |
| ADR-019 | Registro Maestro y navegación documental | Aprobado como antecedente del sistema reconciliado | Bitácora Arquitectónica en Drive | LCD-20260713-02 |
| ADR-020 | Política canónica única de gestionabilidad | Promovido; revisión documental pendiente | Bitácora de Drive y documentación técnica GitHub | LCD-20260715-01 |
| ADR-021 | Monorepo y transición Legacy/Next | Aprobado | `docs/adr/ADR-021-monorepo-y-transicion-legacy-next.md` | LCD-20260713-03 |
| ADR-022 | Docs-as-Code y separación Git/Drive | Aprobado | `docs/adr/ADR-022-docs-as-code-y-separacion-git-drive.md` | LCD-20260713-03 |
| ADR-023 | Autoridad documental y registro único de identificadores | Aprobado | `docs/adr/ADR-023-autoridad-documental-y-registro-unico.md` | LCD-20260801-01 |
| ADR-024 | Límites entre Modelo Comercial y Modelo Operacional de CRM Patrimonial Next | Reservado · pendiente de revisión | `docs/adr/ADR-024-limites-modelo-comercial-operacional.md` | LCD-20260801-02 |

## Colisiones históricas resueltas

| Archivo o referencia histórica | Interpretación histórica | Identificador canónico |
|---|---|---|
| `docs/adr/ADR-018-monorepo-y-transicion-legacy-next.md` anterior a la reconciliación | Monorepo y transición Legacy/Next | ADR-021 |
| `docs/adr/ADR-019-docs-as-code-y-separacion-git-drive.md` anterior a la reconciliación | Docs-as-Code y separación Git/Drive | ADR-022 |

ADR-018 y ADR-019 conservan exclusivamente los significados registrados en la Bitácora de Drive. Los archivos históricos con nombres conflictivos se mantienen como punteros de compatibilidad y no como decisiones canónicas.

## Regla de asignación

1. Revisar este registro y la Bitácora histórica.
2. Reservar el siguiente número libre en la rama del LCD.
3. No asignar el número desde una carpeta, PR o conversación aislada.
4. No reutilizar números cancelados.
5. Toda nueva ADR debe indicar LCD, fecha, estado, contexto, decisión, consecuencias y ubicación canónica.
