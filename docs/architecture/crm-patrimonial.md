# Arquitectura del CRM Patrimonial

- Estado: Aprobada y evolutiva
- Versión vigente: 1.0
- Extensión candidata: 1.1 · LCD-20260805-01
- Última reconciliación aprobada: 2026-08-03
- ADR rectoras aprobadas: ADR-021, ADR-022, ADR-024, ADR-025 y ADR-026
- ADR candidata: ADR-028

## Propósito

Traducir la Constitución y el Modelo del Dominio a una arquitectura comprensible, auditable y evolutiva para APP LLAMADOS Legacy y CRM Patrimonial Next.

## Principios

- Persona es la identidad central.
- La información corporativa externa se separa del conocimiento interno propio.
- Las campañas alimentan el CRM, pero no gobiernan la vida completa de una Persona.
- La cola operativa es temporal y reconstruible; la Relación Comercial es persistente.
- Los hechos se almacenan; vistas, estadísticas y proyecciones se calculan.
- La complejidad sólo se incorpora cuando representa una necesidad real.
- Todo diseño se valida en el ambiente del producto correspondiente antes de considerar STAGING o PROD.
- El dominio no depende de UI, Supabase, PostgreSQL ni otros detalles de infraestructura.
- Compartir repositorio no autoriza compartir runtime, base de datos, claves ni ambientes.

## Productos y transición

### APP LLAMADOS Legacy

PWA productiva actual. Se preserva mediante operaciones necesarias, parches pequeños, pruebas de caracterización y smoke tests. Mientras siga activa, es la única aplicación donde se registran gestiones reales.

### CRM Patrimonial Next

Nueva generación con modelo conceptual mínimo aprobado. Su prioridad inmediata es reemplazar completamente la jornada de llamados y gestión cotidiana; después evolucionará hacia las capacidades patrimoniales completas.

El código fuente inicial vive en `apps/crm-patrimonial/`. La shell de Etapa A posee PWA, configuración, validaciones y artefacto propios, sin conexión a Legacy.

La transición usa monorepo y Strangler Fig para el desarrollo, pero no divide la operación diaria. Antes del corte ambos productos pueden existir técnicamente; después del corte autorizado Next es la única aplicación operativa y Legacy queda temporalmente como consulta o rollback.

## Separación de productos y ambientes

```text
APP LLAMADOS Legacy
├── LEGACY-DEV
└── LEGACY-PROD

CRM Patrimonial Next
├── NEXT-LOCAL
├── NEXT-DEV
├── NEXT-STAGING
└── NEXT-PROD
```

Cada ambiente Next tiene frontend, PWA, variables, proyecto Supabase, migraciones, Auth, RLS, claves, storage, artefactos, despliegue y rollback propios.

Queda prohibido:

- apuntar Next hacia `crm-ffvv-dev` o `crm-ffvv-v2`;
- copiar tablas Legacy como contrato físico inicial;
- utilizar `dev/` como fuente de Next;
- compartir service worker, caché o identidad PWA;
- registrar gestiones reales simultáneamente en Legacy y Next;
- llamar subconjuntos de contactos desde aplicaciones distintas durante la operación normal.

## Estado de infraestructura

| Ambiente | Estado | Evidencia |
|---|---|---|
| NEXT-LOCAL | Shell creada; backend configurado, no iniciado en este entorno | `apps/crm-patrimonial/` y pruebas de Issue #76 |
| NEXT-DEV | No creado; bloqueado por límite de proyectos Supabase | Intento de creación registrado en LCD-20260805-01 |
| NEXT-STAGING | No creado | Requiere candidato validado en NEXT-DEV |
| NEXT-PROD | No creado | Requiere ensayo de corte, rollback y autorización |

Los proyectos remotos previstos son `crm-patrimonial-next-dev`, `crm-patrimonial-next-staging` y `crm-patrimonial-next-prod`, preferentemente en São Paulo.

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

## Datos e importaciones

- Los originales y datos personales permanecen fuera del repositorio público.
- Cada Ejecución de Importación conserva origen, hash, período, validaciones, resultado y linaje.
- Staging es transitorio; las tablas canónicas conservan hechos; las colas y cachés son proyecciones reconstruibles.
- Una carga nunca convierte silenciosamente gestión corporativa en actividad interna.
- Operaciones masivas requieren validación previa, idempotencia, conciliación y rollback verificable.

## Corte hacia Next

El corte requiere, como mínimo:

1. vertical de llamados completa y aceptada;
2. migración reproducible ensayada;
3. conciliación de Personas, campañas, asignaciones, historial, tareas y agenda;
4. captura final y congelamiento de escritura Legacy;
5. rollback probado;
6. habilitación de NEXT-PROD;
7. smoke test y jornada operativa íntegra en Next.

Legacy no se retira inmediatamente: permanece congelado durante la ventana de recuperación, sin convertirse en una segunda aplicación de trabajo.

## Documentación

- GitHub es la única ubicación editable para conocimiento propio versionable.
- Drive es la única ubicación para datos, fuentes externas, respaldos y material no publicable.
- No existen espejos documentales.
- `docs/governance/document-authority.md` contiene el índice de autoridad y las reglas operativas.

## Decisiones aún pendientes

- capacidad y creación de proyectos Supabase remotos de Next;
- hosting y dominios independientes de la shell y aplicaciones Next;
- esquema físico y SQL reproducible de `next_v03`;
- límites definitivos de módulos y contextos;
- RLS, índices y estrategia de migración Legacy → Next;
- privacidad detallada de información patrimonial;
- diseño completo de la primera vertical de llamados;
- mecanismo persistente para excluir campañas inválidas de la gestionabilidad mientras Legacy siga activo.

Estas decisiones requieren sus propios lotes y no se infieren de la shell de Etapa A.
