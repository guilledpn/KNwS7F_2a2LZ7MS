# Arquitectura del CRM Patrimonial

- Estado: Aprobada y evolutiva
- Versión: 1.0
- Última reconciliación: 2026-08-03
- LCD: LCD-20260803-01
- ADR rectoras: ADR-021, ADR-022, ADR-024, ADR-025 y ADR-026

## Propósito

Traducir la Constitución y el Modelo del Dominio a una arquitectura comprensible, auditable y evolutiva para APP LLAMADOS Legacy y CRM Patrimonial Next.

## Principios

- Persona es la identidad central.
- La información corporativa externa se separa del conocimiento interno propio.
- Las campañas alimentan el CRM, pero no gobiernan la vida completa de una Persona.
- La cola operativa es temporal y reconstruible; la Relación Comercial es persistente.
- Los hechos se almacenan; vistas, estadísticas y proyecciones se calculan.
- La complejidad sólo se incorpora cuando representa una necesidad real.
- Todo diseño nuevo se valida en DEV antes de considerar STAGING o PROD.
- El dominio no depende de UI, Supabase, PostgreSQL ni otros detalles de infraestructura.

## Productos y transición

### APP LLAMADOS Legacy

PWA productiva actual. Se preserva estable mediante parches pequeños, pruebas de caracterización y smoke tests. La superficie crítica y su procedimiento de validación viven en `docs/operations/legacy-critical-surface.md` y `docs/operations/legacy-smoke-test.md`.

### CRM Patrimonial Next

Nueva generación en descubrimiento y validación conceptual. La transición usa monorepo y Strangler Fig: las capacidades nuevas se incorporan por verticales verificables, sin una reescritura abrupta del Legacy.

## Capas conceptuales

| Capa | Responsabilidad |
|---|---|
| Corporativa masiva | Campañas, Apariciones, resultados corporativos, Asignaciones y fuentes de importación |
| Operativa | Cola, Tareas, Actividades, conciliaciones, alertas y ejecución del trabajo |
| Comercial | Relación Comercial, Caso, Oportunidad, Cotización, Pipeline, CNS y Producto Contratado |
| Patrimonial | Perfil, objetivos, estrategias, vehículos, portafolios, posiciones y movimientos de capital |
| Vistas del Asesor | Agenda, pipeline, proyección, stats y dashboards derivados |

## Dependencias

La arquitectura objetivo es un monolito modular con puertos y adaptadores:

```text
Adaptadores → Aplicación → Dominio
```

- Dominio: conceptos, invariantes y hechos.
- Aplicación: casos de uso y coordinación transaccional.
- Puertos: necesidades de persistencia, identidad, archivos e integraciones.
- Adaptadores: UI, Supabase/PostgreSQL, importadores y servicios externos.

Los contextos candidatos se validan antes de convertirse en límites físicos: Identidad y Contactabilidad, Adquisición y Campañas, Gestión Operativa, Gestión Comercial, Catálogo de Productos, Productos Contratados y Postventa, Patrimonio e Inversiones, Proyección y Analítica.

## Reglas estructurales vigentes

- La gestionabilidad se deriva mediante la política única de `docs/architecture/contact-eligibility-policy.md`.
- Una Asignación propia vigente es una excepción explícita de gestionabilidad.
- Campaña, Aparición, Asignación, Relación Comercial y gestión interna son hechos diferentes.
- Caso Comercial es la unidad del Pipeline y posee una sola etapa y tarjeta.
- Un Caso contiene 0..N Oportunidades complementarias o alternativas.
- Cotización es una configuración de una Oportunidad; no es el Producto Contratado.
- `Ganado` ocurre sólo al llegar a `Emitido`.
- CNS proyectados, sometidos, emitidos y reconocidos, además del capital, son hechos distintos.
- Tareas y Actividades siempre conservan Persona y Asesor; sus vínculos comerciales son contextuales.
- Producto Contratado nace de una Oportunidad ganada y continúa con identidad e historial propios.

El detalle normativo vive en los modelos Comercial, Operacional, Patrimonial y de Productos; esta Arquitectura no los duplica.

## Datos e importaciones

- Los originales y datos personales permanecen fuera del repositorio público.
- Cada Ejecución de Importación conserva origen, hash, período, validaciones, resultado y linaje.
- Staging es transitorio; las tablas canónicas conservan hechos; las colas y cachés son proyecciones reconstruibles.
- Una carga nunca convierte silenciosamente gestión corporativa en actividad interna.
- Operaciones masivas requieren validación previa, idempotencia, conciliación y rollback verificable.

## Ambientes

| Ambiente | Uso | Regla |
|---|---|---|
| Local | análisis y pruebas sin datos reales | No depende de PROD |
| DEV | laboratorio de diseño, migraciones, importadores y UI | Datos ficticios o sanitizados |
| STAGING | candidato ya validado en DEV | Escenarios controlados |
| PROD | operación real | Nunca se experimenta; cambios mínimos, trazables y aprobados |

## Documentación

- GitHub es la única ubicación editable para conocimiento propio versionable.
- Drive es la única ubicación para datos, fuentes externas, respaldos y material no publicable.
- No existen espejos documentales.
- `docs/governance/document-authority.md` contiene el índice de autoridad y las reglas operativas.

## Decisiones aún pendientes

- esquema físico y SQL reproducible de `next_v03`;
- límites definitivos de módulos y contextos;
- RLS, índices y estrategia de migración Legacy → Next;
- privacidad detallada de información patrimonial;
- producto mínimo de la primera vertical funcional;
- mecanismo persistente para excluir campañas inválidas de la gestionabilidad (Issue #38).

Estas decisiones requieren su propio LCD y no se infieren de esta Arquitectura.
