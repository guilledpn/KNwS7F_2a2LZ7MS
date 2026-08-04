# Backlog y Roadmap del CRM Patrimonial

- Estado: Vigente
- Versión: 2.1
- Última actualización: 2026-08-04
- LCD: LCD-20260803-01 y LCD-20260804-01

Este documento ordena resultados y pendientes. Los Issues contienen ejecución y evidencia; el Modelo del Dominio contiene las reglas. No se duplican detalles técnicos aquí.

## Estado de productos

- APP LLAMADOS Legacy: productivo, versión visible `UI-20260804-10`; cockpit estadístico y backend asociados promovidos mediante PR #53.
- CRM Patrimonial Next: modelo conceptual mínimo aprobado; diseño físico aún no autorizado.

## Fase 0 · Fundamentos y gobernanza

Estado: completada.

- Constitución, Arquitectura, Modelo del Dominio y Roadmap en GitHub.
- Monorepo y transición Legacy/Next: ADR-021.
- Docs-as-Code y autoridad única: ADR-022, ADR-023 y ADR-026.
- Registros únicos de LCD y ADR.
- Inventario, mapas AS-IS/TO-BE y plan reversible.
- Safety net del Legacy.

Pendiente administrativo: revisar o cerrar el material educativo del PR #21.

## Fase 1 · Corrección de reglas y continuidad del Legacy

Estado: sustancialmente completada; quedan dos brechas funcionales explícitas y una aceptación visual postdespliegue.

| Resultado | Estado real al 2026-08-04 | Evidencia |
|---|---|---|
| Gestionabilidad por última aparición válida | Implementada y promovida | ADR-020, PR #19 y #20 |
| Asignados propios visibles | Implementado | Política de elegibilidad y tests |
| Conciliación externa sin inventar gestión interna | Implementada en modelo y runtime | Issues #24 a #27 |
| Métricas por Persona/día | Implementadas en DEV y PROD | ADR-018, LCD-20260713-01 |
| Analítica de muestra estratificada | Implementada | Issues #22 y #23 |
| Separación edición de ficha / gestión | Implementada y saneada en PROD | Issues #26 y #27 |
| Carga julio/agosto y activación | Ejecutada y conciliada | Issue #36 |
| Campaña inválida excluida de cola actual | Aplicado en PROD como corrección controlada | Issue #37 |
| Exclusión persistente de campañas inválidas | Pendiente de diseño e implementación | Issue #38 |
| Navegación contextual y retorno exacto | Implementado y aprobado en PROD | Issue #39, `UI-20260803-07` |
| Metadatos semánticos de `get_contacts_v2` | Defecto conocido; pendiente de Issue propio | Hallazgo del Issue #36 |
| Contrato unificado y cockpit motivacional de estadísticas | Implementado, probado y promovido a PROD | LCD-20260804-01, ADR-027, Issue #52, PR #53, `UI-20260804-10` |
| Smoke visual autenticado postdespliegue del cockpit | Pendiente; no reabre el lote aprobado | Issue #54 |

La antigua regla de “término automático de campaña por primera carga siguiente” no se presume vigente: el Modelo Operacional exige alcance comparable y conciliación explícita. La caducidad temporal de la cola tampoco debe confundirse con el historial de la Persona.

## Fase 2 · Modelo relacional mínimo en DEV

Estado: definición conceptual completada; implementación no iniciada.

Completado documentalmente:

- Persona, Relación Comercial, Responsabilidad, Tarea y Actividad;
- Caso con 0..N Oportunidades;
- Cotización, Pipeline, CNS y Producto Contratado;
- Matriz de Validación Next v03;
- separación Comercial/Operacional.

Siguiente resultado: diseñar, mediante LCD propio, el esquema físico mínimo `next_v03` y sus pruebas reproducibles. No modificar PROD.

## Fase 3 · Perfil patrimonial progresivo

Estado: pendiente.

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

Estado: pendiente para Next, salvo métricas Legacy y cockpit motivacional ya promovidos.

- proyección por Caso y período;
- CNS proyectados, sometidos, emitidos y reconocidos;
- capital esperado y materializado;
- pipeline y escenarios mensual, trimestral y anual;
- mantener separada la equivalencia operativa por Agendamiento de las proyecciones comerciales por Caso.

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
- STAGING reproducible;
- desacoplamiento de `main` y publicación productiva;
- observabilidad y rollback de cargas;
- validación móvil y escritorio;
- conservación de evidencia final de cada operación antes de borrar temporales.

## Prioridad recomendada

1. Completar manualmente las tres acciones de Drive registradas en Issue #40; el conector mantiene `403 appNotAuthorizedToFile`.
2. Ejecutar el smoke visual autenticado postdespliegue del cockpit mediante Issue #54.
3. Diseñar y cerrar Issue #38 sin experimentar en PROD.
4. Registrar y corregir el defecto semántico de `get_contacts_v2` observado en Issue #36.
5. Definir el LCD de diseño físico mínimo `next_v03`.
6. Revisar PR #21 y decidir si su material se integra, reduce o descarta.

Toda iniciativa debe demostrar que representa negocio real, reduce carga, protege continuidad, puede probarse en DEV y evita crear otra fuente de verdad.
