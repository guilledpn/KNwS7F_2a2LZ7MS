# Registro canónico de Lotes de Cambio Documental

- Estado: Vigente
- Fecha de reconciliación: 2026-08-01
- Última actualización: 2026-08-05
- LCD rector: LCD-20260801-01
- Último LCD: LCD-20260805-01
- Issue: #28

Este archivo es la autoridad para asignar y consultar identificadores LCD. Los registros históricos de Drive y los Pull Requests se conservan como evidencia, pero no pueden crear una secuencia paralela.

## Regla de asignación

1. Revisar este registro antes de abrir el lote.
2. Utilizar la fecha real de apertura y el siguiente correlativo libre de ese día.
3. Incorporar la reserva en la rama del lote antes de crear otros documentos.
4. No reutilizar identificadores cancelados o sustituidos.
5. Registrar aliases históricos únicamente en la columna correspondiente; un alias no es un identificador vigente.

## Registro

| LCD canónico | Fecha | Motivo | Estado | Evidencia principal | Alias histórico |
|---|---|---|---|---|---|
| LCD-20260711-01 | 2026-07-11 | Crear el Índice del Modelo del Dominio y la estructura documental inicial | Aprobado | `docs/domain/README.md` | — |
| LCD-20260712-01 | 2026-07-12 | Crear y organizar el Modelo de Productos y catálogo Consorcio | Estructura aprobada; catálogo en revisión continua | ADR-017, `docs/domain/product-model.md` y fuentes Consorcio en Drive | — |
| LCD-20260713-01 | 2026-07-13 | Corregir métricas operativas derivadas por Persona y día | Aprobado y promovido a PROD | ADR-018 consolidada y migraciones productivas | — |
| LCD-20260713-02 | 2026-07-13 | Crear Registro Maestro y navegación documental | Obsoleto como mecanismo vigente por ADR-026 | ADR-019 consolidada; historia Git/Drive | — |
| LCD-20260713-03 | 2026-07-13 | Adoptar monorepo, Docs-as-Code y programa de aprendizaje | Aprobado | Pull Request #9; ADR-021 y ADR-022 | En GitHub histórico figuró como LCD-20260713-01 |
| LCD-20260713-04 | 2026-07-13 | Inventariar el repositorio y planificar la transición reversible | Aprobado | Pull Request #11 | En GitHub histórico figuró como LCD-20260713-02 |
| LCD-20260714-01 | 2026-07-14 | Cerrar Etapa 0 y preparar protección del Legacy | Aprobado | Pull Request #15 | — |
| LCD-20260714-02 | 2026-07-14 | Mapear arquitectura y crear red mínima de seguridad Legacy | Aprobado | Pull Requests #17 y #18 | — |
| LCD-20260715-01 | 2026-07-15 | Unificar gestionabilidad, ejecutar backfill y promover a PROD | Aprobado, promovido y documentado | ADR-020, Pull Requests #19 y #20, pruebas y validaciones versionadas | — |
| LCD-20260716-01 | 2026-07-16 | Crear material educativo y diagnóstico de arquitectura de datos | Pendiente de revisión | Pull Request borrador #21 | — |
| LCD-20260801-01 | 2026-08-01 | Reconciliar Drive y GitHub, corregir colisiones y fijar autoridad documental | Aprobado por autorización explícita del usuario; implementación documental trazada en Issue #28 | Issue #28 y Pull Requests #29 y #30 | — |
| LCD-20260801-02 | 2026-08-01 | Crear los modelos Comercial y Operacional mínimos y la Matriz de Validación de Next v03 | Aprobado | Issue #31 y Pull Requests #32 y #33 | — |
| LCD-20260802-01 | 2026-08-02 | Definir el modelo mínimo de Caso Comercial, Oportunidad, Propuesta y Pipeline | Aprobado; equivalencia histórica resuelta | Issue #34 y Pull Request #35 | — |
| LCD-20260803-01 | 2026-08-03 | Conciliar y migrar la documentación a una ubicación única sin espejos | Aprobado | Issue #40, ADR-026, informe de conciliación y Pull Request #41 | — |
| LCD-20260804-01 | 2026-08-04 | Unificar el contrato de estadísticas y documentar el pulso motivacional de CNS y pesos esperados por Agendamiento | Aprobado y promovido a PROD; aceptación visual postdespliegue separada en Issue #54 | Issue #52, ADR-027, PR #53, commit `d688f6ff1c483b2f8e409165acde3db80644d787` y `docs/governance/LCD-20260804-01-closure.md` | — |
| LCD-20260804-02 | 2026-08-04 | Crear estándares canónicos de desarrollo, reducir las instrucciones de proyecto y preservar la continuidad operativa de herramientas | Aprobado por autorización explícita del usuario | `docs/governance/LCD-20260804-02-engineering-standards.md`, Issues #40, #56 y #57 y Pull Request #58 | — |
| LCD-20260804-03 | 2026-08-04 | Retirar de las instrucciones vigentes la convención visual de revisión heredada de Drive | Aprobado por autorización explícita del usuario | Issue #59, Pull Request #60 y `docs/governance/LCD-20260804-03-remove-drive-color-rule.md` | — |
| LCD-20260804-04 | 2026-08-04 | Reforzar seguridad Supabase, gestión de incertidumbre, clasificación física y disciplina Git/PR | Aprobado por autorización explícita del usuario | Issue #61, Pull Request #62 y `docs/governance/LCD-20260804-04-engineering-hardening.md` | — |
| LCD-20260804-05 | 2026-08-04 | Clasificar el trabajo y aplicar controles proporcionales, incluyendo operaciones excepcionales acotadas | Candidato; pendiente de revisión y merge autorizado | Issue #65 y `docs/governance/LCD-20260804-05-work-classification-proportionality.md` | — |
| LCD-20260805-01 | 2026-08-05 | Crear infraestructura independiente y shell ejecutable de CRM Patrimonial Next | Candidato; ambientes cloud remotos bloqueados por límite Supabase | Issue #76, ADR-028 y rama `feat/issue76-next-independent-infrastructure` | — |

## Próxima asignación

El próximo LCD debe calcularse desde la fecha efectiva de apertura y este registro. No se infiere desde el número del último Pull Request ni desde archivos aislados de Drive.

## Relación con Drive

Drive no mantiene un registro LCD paralelo. Las fuentes o evidencias no publicables pueden enlazarse desde la columna correspondiente, pero nunca asignan identificadores ni estados.
