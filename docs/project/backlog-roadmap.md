# Backlog y Roadmap del CRM Patrimonial

- Estado: Vigente
- Versión aprobada: 2.2
- Extensión candidata: 2.3 · LCD-20260805-01
- Última actualización candidata: 2026-08-05

Este documento ordena resultados y pendientes. Los Issues contienen ejecución y evidencia; el Modelo del Dominio contiene las reglas.

## Estado de productos

- APP LLAMADOS Legacy: productivo, versión visible `UI-20260804-10`; continúa como única aplicación operativa hasta el corte.
- CRM Patrimonial Next: modelo conceptual mínimo aprobado; shell local e infraestructura inicial candidatas mediante Issue #76; diseño físico aún no autorizado.

## Dirección prioritaria

El costo operativo de mantener Legacy hace prioritario construir Next como reemplazo completo de la jornada diaria de llamados. Legacy recibe sólo operaciones, hotfix y correcciones imprescindibles mientras siga activo.

La transición no divide contactos ni campañas entre aplicaciones. Next se desarrolla aisladamente y, cuando alcance equivalencia operativa útil, reemplaza a Legacy mediante un corte total ensayado.

## Fase 0 · Fundamentos y gobernanza

Estado: completada.

- Constitución, Arquitectura, Modelo del Dominio y Roadmap en GitHub.
- Monorepo y transición Legacy/Next: ADR-021.
- Docs-as-Code y autoridad única: ADR-022, ADR-023 y ADR-026.
- Registros únicos de LCD y ADR.
- Safety net del Legacy.
- Estándares canónicos de desarrollo y calidad.

Pendiente administrativo: revisar o cerrar el material educativo del PR #21.

## Fase 1 · Continuidad mínima del Legacy

Estado: operación transitoria hasta el corte.

Completado: gestionabilidad, asignados, métricas, navegación, filtros, cockpit y carga julio/agosto. Permanecen pendientes #38, #54 y el defecto semántico de `get_contacts_v2`.

Regla de prioridad: sólo ejecutar en Legacy trabajo necesario para mantener la jornada, proteger datos, cargar campañas o resolver incidentes que no puedan esperar a Next.

## Fase 2A · Infraestructura independiente de Next

Estado: candidato en Issue #76.

Completado en la rama:

- `apps/crm-patrimonial/` como fuente independiente;
- shell PWA ejecutable con datos ficticios;
- scripts de arranque para Windows;
- configuración Supabase local en puertos propios;
- pruebas de aislamiento;
- workflow y artefacto descargable;
- ADR-028 y guía de ambientes.

Pendiente:

- aprobar el lote;
- resolver capacidad Supabase;
- crear y verificar NEXT-DEV;
- elegir hosting remoto independiente para previews;
- iniciar y comprobar el stack Supabase local en un equipo con Docker.

## Fase 2B · Esquema físico `next_v03`

Estado: siguiente lote de producto.

Objetivo: diseñar el núcleo físico mínimo compatible con el dominio aprobado y con la vertical de llamados, sin copiar la estructura Legacy.

Debe incluir pruebas reproducibles, RLS, contratos de aplicación, migraciones y seeds ficticios. No modifica datos reales ni NEXT-PROD.

## Fase 2C · Vertical de reemplazo operativo

Estado: pendiente y prioritario.

Circuito mínimo completo:

```text
Importar → Cola → Persona → Llamar → Registrar Actividad
→ Crear Tarea o Agenda → Continuar → Consultar historial y métricas
```

Debe permitir una jornada completa sin abrir Legacy. Relación Comercial, Caso y Oportunidad aparecen sólo cuando los hechos del negocio los justifican.

## Fase 2D · Migración y corte total

Estado: pendiente.

- migración reproducible hacia NEXT-STAGING;
- conciliación de Personas, campañas, asignaciones, actividades, tareas y agenda;
- pruebas de volumen y rendimiento;
- rollback verificado;
- congelamiento de escritura Legacy;
- migración final;
- habilitación NEXT-PROD;
- Legacy temporalmente de sólo lectura.

No se adopta un piloto por subconjunto de contactos como modalidad diaria.

## Fase 3 · Perfil patrimonial progresivo

Estado: pendiente después del reemplazo operativo inicial.

- datos personales mínimos y sanitización;
- propiedades, inversiones, créditos y relaciones bancarias;
- objetivos, deseos y riesgos;
- historial de activos y compromisos;
- política de privacidad, acceso, exportación y borrado.

## Fase 4 · Catálogo y flujos de productos

Estado: estructura creada; auditoría de catálogo pendiente.

- completar matriz Consorcio desde fuentes vigentes;
- estados y requisitos por familia;
- cotizaciones, contratación, sometimiento y emisión;
- CNS, capital y reconocimiento;
- datos mínimos del Producto Contratado.

## Fase 5 · Proyección y analítica

Estado: pendiente para Next.

- proyección por Caso y período;
- CNS proyectados, sometidos, emitidos y reconocidos;
- capital esperado y materializado;
- pipeline y escenarios;
- equivalencia operativa por Agendamiento separada de proyecciones comerciales.

## Fase 6 · Productos Contratados y postventa

Estado: pendiente.

- múltiples productos del mismo tipo;
- modificaciones e historial;
- aportes, fondos, suspensión, rescate y término;
- nuevas oportunidades desde productos vigentes.

## Fase 7 · Contexto relacional opcional

Estado: pendiente y no prioritario.

- vínculos familiares, referidos, socios u otros;
- origen y notas del vínculo;
- navegación entre Personas relacionadas.

## Backlog transversal

- seguridad y privacidad patrimonial;
- hosting y STAGING reproducibles de Next;
- desacoplamiento de `main` y publicación productiva Legacy;
- observabilidad y rollback de cargas;
- validación móvil y escritorio;
- automatización gradual de quality gates: Issue #56;
- auditoría de normalizadores operativos: Issue #57.

## Prioridad recomendada

1. Revisar y aprobar Issue #76.
2. Resolver capacidad cloud y crear NEXT-DEV.
3. Abrir el LCD de `next_v03`.
4. Implementar la vertical completa de llamados.
5. Ensayar migración y corte total.
6. Atender Legacy sólo según urgencia operacional mientras siga activo.
7. Continuar las capacidades patrimoniales sobre la base Next.

Toda iniciativa debe representar negocio real, reducir carga, proteger continuidad y evitar otra fuente de verdad.
