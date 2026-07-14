# Matriz de competencias

Última actualización: 2026-07-13  
LCD: LCD-20260713-01

Los estados iniciales son una primera estimación y deberán ajustarse mediante evidencia práctica.

## Nivel 1 · Git y repositorio

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Repositorio | Introducido | Reconoce el repositorio como contenedor del proyecto | Explicar qué pertenece y qué no pertenece al repositorio |
| Working tree | Pendiente | — | Revisar cambios locales en VS Code o GitHub Desktop |
| Staging area | Pendiente | — | Seleccionar archivos para un commit |
| Commit | Introducido | Distingue su función general | Crear y revisar un commit con Conventional Commits |
| Push / Pull | Pendiente | — | Publicar y sincronizar una rama |
| Rama | Introducido | Comprende la idea de trabajo aislado | Crear y cambiar de rama localmente |
| Merge | Introducido | Distingue integración de cambios | Revisar y aprobar un merge mediante PR |
| Conflicto | Pendiente | — | Resolver un conflicto controlado |
| Tag | Pendiente | — | Crear una etiqueta de versión |
| Release | Introducido | Conoce su relación con una versión | Publicar una release PATCH |
| Diff | Introducido | Ha visto diferencias en herramientas | Revisar un PR archivo por archivo |
| `.gitignore` | Pendiente | — | Auditar archivos que no deben versionarse |

## Nivel 2 · Colaboración y gestión

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Issue | Introducido | Issue #7 creado para el primer lote | Revisar y mejorar sus criterios de aceptación |
| Criterios de aceptación | Introducido | Han sido utilizados en tareas previas | Formularlos para un bug real |
| Backlog | Guiado | Existe Backlog y Roadmap documental | Migrar una tarea concreta a GitHub Issues |
| GitHub Project | Pendiente | — | Crear tablero inicial |
| Pull Request | Pendiente | — | Revisar el PR del LCD-20260713-01 |
| Draft PR | Pendiente | — | Utilizarlo en un lote todavía incompleto |
| Review | Pendiente | — | Comentar y aprobar cambios |
| Checklist | Introducido | Se usan smoke tests y controles | Aplicar checklist de PR |
| Trazabilidad LCD–Issue–PR–Release | Introducido | LCD e Issue #7 enlazados | Completar cadena con PR y merge |

## Nivel 3 · Desarrollo y calidad

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Bug | Operativo | Ha identificado y validado bugs reales | Formular uno como Issue reproducible |
| Feature | Guiado | Ha definido mejoras funcionales | Separar necesidad, diseño e implementación |
| Refactor | Introducido | Comprende su propósito general | Refactor pequeño protegido por pruebas |
| Deuda técnica | Introducido | Reconoce limitaciones del legacy | Registrar deuda sin confundirla con bug |
| Prueba de caracterización | Pendiente | — | Proteger una regla existente de APP LLAMADOS |
| Prueba unitaria | Introducido | Conoce el concepto de caja negra | Ejecutar una prueba real |
| Prueba de integración | Pendiente | — | Probar adaptador contra DEV |
| Prueba end-to-end | Pendiente | — | Definir un flujo crítico completo |
| Regresión | Introducido | Comprende que un arreglo no debe romper lo anterior | Agregar prueba a un bug corregido |
| Smoke test | Guiado | Ha ejecutado smoke tests con acompañamiento | Crear checklist reutilizable |
| Lint / Build | Pendiente | — | Identificar herramientas existentes |
| CI/CD | Introducido | Conoce su propósito general | Crear primera verificación automática no destructiva |

## Nivel 4 · Arquitectura y dominio

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Dominio | Operativo | Participa activamente en el modelo del negocio | Identificar frontera de una regla nueva |
| Lenguaje ubicuo | Guiado | Ha definido conceptos y corregido ambigüedades | Normalizar términos en el Diccionario |
| Subdominio | Introducido | — | Clasificar capacidades del CRM |
| Bounded Context | Introducido | Se propusieron contextos candidatos | Taller formal de mapa de contextos |
| Entidad | Guiado | Reconoce Persona, Caso y Oportunidad | Distinguir entidad de objeto de valor |
| Objeto de valor | Pendiente | — | Modelar RUT, dinero o período |
| Agregado / raíz | Pendiente | — | Identificar invariantes transaccionales |
| Invariante | Introducido | Ha formulado reglas obligatorias | Convertir una regla en prueba |
| Servicio de dominio | Pendiente | — | Identificar una lógica sin entidad natural |
| Caso de uso | Introducido | Comprende la coordinación de acciones | Diseñar `EvaluarGestionabilidad` |
| Puerto | Introducido | Conoce la analogía de contrato | Definir un puerto de repositorio |
| Adaptador | Introducido | Reconoce Supabase y UI como tecnología externa | Diseñar un adaptador falso y uno real |
| Repositorio DDD | Pendiente | — | Diferenciarlo de repositorio Git |
| Monolito modular | Introducido | Decisión aprobada | Validar límites de módulos |
| Arquitectura hexagonal | Introducido | Decisión aprobada | Diseñar primera vertical completa |

## Nivel 5 · Operación

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| DEV / STAGING / PROD | Guiado | Ha trabajado con ambientes separados | Formalizar matriz Producto × Ambiente |
| Despliegue | Guiado | Ha promovido cambios con acompañamiento | Documentar un despliegue completo |
| Migración | Introducido | Ha trabajado con cambios de base | Diseñar una migración reversible |
| Rollback | Introducido | Conoce la necesidad | Ejecutar ensayo controlado en DEV |
| Backup | Introducido | Reconoce que Git no respalda datos | Definir estrategia 3-2-1 y backups Supabase |
| Restore | Pendiente | — | Probar restauración de un respaldo ficticio |
| Logs | Introducido | Ha usado diagnósticos | Identificar logs de un incidente |
| Observabilidad | Pendiente | — | Definir métricas mínimas |
| Incidente | Guiado | Ha gestionado fallas productivas | Registrar incidente estructuradamente |
| Hotfix | Introducido | Comprende su urgencia y alcance | Ejecutar flujo completo con rama hotfix |
| Continuidad operativa | Operativo | Es prioridad explícita y aplicada | Formalizar checklist de promoción |
| Recuperación ante desastres | Pendiente | — | Crear plan mínimo y probarlo |
