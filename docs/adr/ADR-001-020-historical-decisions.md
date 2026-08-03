# Decisiones históricas ADR-001 a ADR-020

- Estado: Historia canónica consolidada
- Período: 2026-07-11 a 2026-07-15
- Migración: LCD-20260803-01
- Fuente histórica retirada: Bitácora Arquitectónica de Google Drive

Este archivo conserva en un solo lugar las decisiones anteriores a la adopción completa de Docs-as-Code. El estado vigente de los conceptos vive en los modelos del dominio; ante una diferencia, gobierna la decisión posterior que la refine o sustituya, especialmente ADR-024 y ADR-025.

| ADR | Decisión histórica | Estado / refinamiento vigente |
|---|---|---|
| ADR-001 | Caso Comercial como estrategia patrimonial | Aprobada; refinada por ADR-025: negocio indivisible, 0..N Oportunidades |
| ADR-002 | Oportunidad como contratación potencial individualizable | Aprobada y vigente |
| ADR-003 | Cotización como configuración de una Oportunidad | Aprobada; CNS descriptivos no gobiernan la proyección del Caso |
| ADR-004 | Separación entre Estrategia y Vehículo de Inversión | Aprobada y vigente |
| ADR-005 | Portafolio como concepto transversal | Aprobada y vigente |
| ADR-006 | Posiciones sobre Series de Fondos | Aprobada y vigente |
| ADR-007 | Producto Contratado como entidad persistente | Aprobada; refinada por ADR-025 |
| ADR-008 | Emisión, capital y CNS como hechos distintos | Aprobada y vigente |
| ADR-009 | Proyección como vista global del Asesor | Aprobada; el Caso conserva su proyección viva y la vista global la agrega |
| ADR-010 | Historial detallado para APV | Aprobada como dirección evolutiva |
| ADR-011 | Actividades vinculables a Casos y Oportunidades | Aprobada; Persona y Asesor son vínculos esenciales |
| ADR-012 | Oportunidades complementarias o alternativas | Aprobada y vigente |
| ADR-013 | Cliente de la Compañía y Cliente del Asesor | Aprobada y vigente |
| ADR-014 | Series determinadas por Producto | Aprobada, sujeta a catálogo vigente |
| ADR-015 | Rentabilidad con definición, período, fuente y fecha | Aprobada; verificación normativa APV pendiente |
| ADR-016 | Perfil de Riesgo corporativo | Aprobada: Conservador, Moderado y Agresivo |
| ADR-017 | Estructura transversal del Modelo de Productos | Estructura aprobada; catálogo Consorcio en revisión continua |
| ADR-018 | Métricas operativas derivadas por Persona y día | Aprobada y promovida a PROD |
| ADR-019 | Registro Maestro y navegación documental | Obsoleta por ADR-026; el Sheet espejo fue retirado |
| ADR-020 | Política canónica única de gestionabilidad | Aprobada, implementada y promovida mediante PR #19/#20 |

## Detalle normativo preservado

### ADR-018 · Métricas por Persona y día

- Contacto Trabajado: como máximo una vez por Persona y fecha local.
- Llamada Efectiva: Resultado Diario `Agenda` o `No agenda`.
- Agendamiento: Resultado Diario `Agenda`.
- Conversión Efectiva: Agendamientos / Llamadas Efectivas.
- Los eventos de guardado se conservan como trazabilidad, pero no son resultados independientes.

Implementada en DEV y PROD mediante las RPC y migraciones versionadas; el rollback vive en `supabase/rollback/`.

### ADR-020 · Gestionabilidad

- Asignación propia vigente habilita.
- Aparición en campaña activa sin asignación propia impide descubrimiento.
- Fuera de la campaña activa, gobierna la última aparición corporativa válida.
- `No Gestionado` habilita; `Gestionado` excluye preventivamente.
- Estado corporativo ausente o inválido falla de forma conservadora.
- Gestión interna no sustituye el resultado corporativo ni concede gestionabilidad.

La política ejecutable y sus validaciones se describen en `docs/architecture/contact-eligibility-policy.md`.

## Evidencia histórica

La validación detallada, conteos, migraciones y promociones se conservan en Issues, PR, commits, `docs/operations/`, `docs/PROD_metricas_operativas_diarias_20260713.md` y scripts de rollback. No se duplican íntegramente en esta bitácora.
