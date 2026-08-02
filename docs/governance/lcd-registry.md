# Registro canónico de Lotes de Cambio Documental

- Estado: Vigente
- Fecha de reconciliación: 2026-08-01
- Última actualización: 2026-08-02
- LCD rector: LCD-20260801-01
- Último LCD: LCD-20260802-01
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
| LCD-20260711-01 | 2026-07-11 | Crear el Índice del Modelo del Dominio y la estructura documental inicial | Aprobado | Índice del Modelo del Dominio en Drive | — |
| LCD-20260712-01 | 2026-07-12 | Crear y organizar el Modelo de Productos y catálogo Consorcio | Pendiente de revisión | ADR-017 y documentos de Drive | — |
| LCD-20260713-01 | 2026-07-13 | Corregir métricas operativas derivadas por Persona y día | Aprobado y promovido a PROD | ADR-018 de Drive y migraciones productivas | — |
| LCD-20260713-02 | 2026-07-13 | Crear Registro Maestro y navegación documental | Aprobado como antecedente del sistema reconciliado | ADR-019 de Drive y Registro Maestro | — |
| LCD-20260713-03 | 2026-07-13 | Adoptar monorepo, Docs-as-Code y programa de aprendizaje | Aprobado | Pull Request #9; ADR-021 y ADR-022 | En GitHub histórico figuró como LCD-20260713-01 |
| LCD-20260713-04 | 2026-07-13 | Inventariar el repositorio y planificar la transición reversible | Aprobado | Pull Request #11 | En GitHub histórico figuró como LCD-20260713-02 |
| LCD-20260714-01 | 2026-07-14 | Cerrar Etapa 0 y preparar protección del Legacy | Aprobado | Pull Request #15 | — |
| LCD-20260714-02 | 2026-07-14 | Mapear arquitectura y crear red mínima de seguridad Legacy | Aprobado | Pull Requests #17 y #18 | — |
| LCD-20260715-01 | 2026-07-15 | Unificar gestionabilidad, ejecutar backfill y promover a PROD | Promovido y validado técnicamente; revisión documental y smoke visual pendientes | ADR-020, Pull Requests #19 y #20, Registro Maestro de Drive | — |
| LCD-20260716-01 | 2026-07-16 | Crear material educativo y diagnóstico de arquitectura de datos | Pendiente de revisión | Pull Request borrador #21 | — |
| LCD-20260801-01 | 2026-08-01 | Reconciliar Drive y GitHub, corregir colisiones y fijar autoridad documental | Aprobado por autorización explícita del usuario; implementación documental trazada en Issue #28 | Issue #28 y Pull Requests #29 y #30 | — |
| LCD-20260801-02 | 2026-08-01 | Crear los modelos Comercial y Operacional mínimos y la Matriz de Validación de Next v03 | Aprobado | Issue #31 y Pull Requests #32 y #33 | — |
| LCD-20260802-01 | 2026-08-02 | Definir el modelo mínimo de Caso Comercial, Oportunidad, Propuesta y Pipeline | <span style="color:red">En elaboración · pendiente de revisión</span> | Issue #34 y rama `docs/lcd-20260802-01-commercial-development-model` | — |

## Próxima asignación

El próximo LCD debe calcularse desde la fecha efectiva de apertura y este registro. No se infiere desde el número del último Pull Request ni desde archivos aislados de Drive.

## Relación con Drive

El Google Sheet «Registro Maestro de Lotes de Cambio Documental del CRM Patrimonial» se mantiene como espejo navegable durante la transición. Ante una divergencia posterior a LCD-20260801-01, gobierna este archivo versionado y la divergencia bloquea nuevas asignaciones hasta ser corregida.
