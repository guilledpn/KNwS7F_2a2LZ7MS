# Matriz de competencias

Última actualización: 2026-07-13  
LCD: LCD-20260713-02

Los estados se ajustan mediante evidencia práctica observada durante el trabajo real.

## Nivel 1 · Git y repositorio

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Repositorio | Guiado | Navegó el repositorio en VS Code y GitHub Desktop; distinguió repositorio de aplicación | Clasificar archivos del inventario técnico |
| Working tree | Guiado | Identificó `CHANGES` vacío como ausencia de modificaciones locales pendientes | Crear una modificación local controlada |
| Staging area | Pendiente | — | Seleccionar manualmente archivos para un commit |
| Commit | Introducido | Revisó el historial de siete commits y su propósito | Crear su primer commit atómico |
| Push / Pull | Guiado | Sincronizó la rama y utilizó Fetch/Pull durante la revisión | Publicar una rama creada localmente |
| Rama | Guiado | Cambió entre `main` y la rama del LCD y verificó la rama activa | Crear una rama desde GitHub Desktop |
| Merge | Guiado | Completó el merge del Pull Request #9 hacia `main` | Repetir merge verificando checks y estrategia |
| Conflicto | Pendiente | — | Resolver un conflicto controlado |
| Tag | Pendiente | — | Crear una etiqueta de versión |
| Release | Introducido | Conoce su relación con una versión | Publicar una release PATCH |
| Diff | Guiado | Comparó rama contra `main` y revisó archivos verdes agregados en Desktop y VS Code | Revisar un diff con adiciones y eliminaciones |
| `.gitignore` | Pendiente | — | Auditar archivos que no deben versionarse |

## Nivel 2 · Colaboración y gestión

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Issue | Guiado | Revisó Issue #7 y participa ahora en Issue #10 | Formular criterios para una tarea técnica concreta |
| Criterios de aceptación | Introducido | Revisó criterios del primer lote | Evaluar uno por uno los criterios del Issue #10 |
| Backlog | Guiado | Existe Backlog documental y tareas trasladadas a Issues | Clasificar nuevos hallazgos como Issues separados |
| GitHub Project | Pendiente | — | Crear tablero inicial cuando exista volumen suficiente |
| Pull Request | Guiado | Revisó y fusionó el PR #9 | Revisar el PR del LCD-20260713-02 |
| Draft PR | Guiado | Identificó el estado Draft y su paso a Ready for review | Mantener el segundo PR en borrador hasta completar inventario |
| Review | Guiado | Ejecutó un review de prueba en el PR #9 | Dejar un comentario específico y resolverlo |
| Checklist | Guiado | Verificó archivos, alcance y ausencia de cambios productivos | Completar checklist del segundo lote |
| Trazabilidad LCD–Issue–PR–Release | Guiado | Completó LCD-20260713-01 → Issue #7 → PR #9 → merge | Extender la cadena hasta una Release real |

## Nivel 3 · Desarrollo y calidad

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| Bug | Operativo | Ha identificado y validado bugs reales | Formular uno como Issue reproducible |
| Feature | Guiado | Ha definido mejoras funcionales | Separar necesidad, diseño e implementación |
| Refactor | Introducido | Comprende su propósito general | Refactor pequeño protegido por pruebas |
| Deuda técnica | Guiado | Identifica límites del `index.html` y mezcla entre fuente y artefacto | Registrar deudas descubiertas en el inventario |
| Prueba de caracterización | Pendiente | — | Proteger una regla existente de APP LLAMADOS |
| Prueba unitaria | Introducido | Conoce el concepto de caja negra | Ejecutar una prueba real |
| Prueba de integración | Pendiente | — | Probar adaptador contra DEV |
| Prueba end-to-end | Pendiente | — | Definir un flujo crítico completo |
| Regresión | Introducido | Comprende que un arreglo no debe romper lo anterior | Agregar prueba a un bug corregido |
| Smoke test | Guiado | Ha ejecutado smoke tests con acompañamiento | Crear checklist reutilizable |
| Lint / Build | Introducido | Reconoció workflows de build y validación existentes | Ejecutar localmente un validador seguro |
| CI/CD | Introducido | Revisó que Actions construyen DEV y protegen PROD | Distinguir validación, integración y despliegue |

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
| Monolito modular | Guiado | Aprobó ADR-018 y revisa la estructura objetivo | Validar límites de módulos propuestos |
| Arquitectura hexagonal | Introducido | Decisión aprobada | Diseñar primera vertical completa |

## Nivel 5 · Operación

| Competencia | Estado | Evidencia disponible | Próxima práctica |
|---|---|---|---|
| DEV / STAGING / PROD | Guiado | Diferencia ambientes y revisa la matriz Producto × Ambiente | Validar qué ambientes existen realmente |
| Despliegue | Guiado | Ha promovido cambios con acompañamiento y revisó GitHub Pages | Documentar un despliegue completo |
| Migración | Guiado | Está revisando un plan reversible de reorganización | Ejecutar una etapa documental sin mover PROD |
| Rollback | Introducido | Conoce la necesidad y revisa rollback por etapa | Ejecutar ensayo controlado en DEV |
| Backup | Introducido | Reconoce que Git no respalda datos | Definir estrategia 3-2-1 y backups Supabase |
| Restore | Pendiente | — | Probar restauración de un respaldo ficticio |
| Logs | Introducido | Ha usado diagnósticos | Identificar logs de un incidente |
| Observabilidad | Pendiente | — | Definir métricas mínimas |
| Incidente | Guiado | Ha gestionado fallas productivas | Registrar incidente estructuradamente |
| Hotfix | Introducido | Comprende su urgencia y alcance | Ejecutar flujo completo con rama hotfix |
| Continuidad operativa | Operativo | Es prioridad explícita y aplicada | Formalizar checklist de promoción |
| Recuperación ante desastres | Pendiente | — | Crear plan mínimo y probarlo |
