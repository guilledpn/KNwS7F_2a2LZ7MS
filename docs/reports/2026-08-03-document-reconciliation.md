# Informe de conciliación y migración documental

- Proyecto: CRM Patrimonial / APP LLAMADOS
- Fecha: 2026-08-03
- Alcance: GitHub, Google Drive, documentos rectores, ADR/LCD, Roadmap y trazabilidad administrativa
- LCD: LCD-20260803-01
- ADR: ADR-026
- Issue: #40

## 1. Resultado ejecutivo

La conciliación quedó completada con una regla verificable: **cada artefacto vive en una sola ubicación**.

- GitHub contiene todo el conocimiento propio, publicable y versionable.
- Drive conserva exclusivamente datos reales, respaldos, fuentes externas/corporativas y evidencia no apta para el repositorio público.
- Se eliminó el Registro Maestro paralelo y toda copia documental migrada de Drive.
- Se fusionaron funciones documentales duplicadas: autoridad y catálogo ahora son un solo documento; ADR-001…020 forman una sola bitácora histórica.
- Dos documentos de Drive no se migraron como archivos nuevos porque duplicaban el modelo y el backlog: su conocimiento válido fue absorbido.
- Se retiraron tres documentos Git obsoletos que competían con documentos rectores actuales.
- El estado del Legacy se actualizó hasta el Issue #39 sin perder `UI-20260803-07`.
- ADR-025/LCD-20260802-01 fueron conciliados, aprobados y fusionados en el PR #35.
- Issues #34 y #12 se cerraron con evidencia; Issue #38 permanece correctamente abierto.

No se modificó Supabase, DEV, STAGING ni PROD durante esta conciliación.

## 2. Fuentes revisadas

### GitHub

- `main` hasta el commit de merge del PR #35;
- Issues #12 y #22 a #39;
- PR #19, #20, #21 y #35;
- commits y archivos del runtime Legacy;
- 24 pruebas de caracterización, validadores y documentación existente.

### Drive

- raíz `App_llamados_crm`;
- Constitución, Arquitectura, Roadmap, Bitácora, Modelo de negocio y Acuerdos;
- carpeta Modelo del dominio: Índice, Diccionario, Modelo Patrimonial y Modelo de Productos;
- Registro Maestro Sheet;
- `Bases_maestras`, respaldos y carga controlada julio/agosto;
- carpeta Productos Consorcio, su matriz y 20 PDFs corporativos.

### Adjuntos de la conversación

Las exportaciones PDF de Constitución, Arquitectura y Roadmap se revisaron como insumos. Eran anteriores a los Google Docs vivos y no se trataron como autoridad.

## 3. Conciliaciones de contenido

### 3.1 ADR-025 y desarrollo comercial

El PR #35 estaba detrás de `main`; una fusión ingenua habría eliminado cambios recientes del Legacy. La rama se concilió con `main` antes de aprobar el contenido y preservó `UI-20260803-07` del Issue #39.

Se resolvieron las cinco diferencias registradas en Issue #34:

| Diferencia | Regla conciliada |
|---|---|
| Caso histórico exigía 1..N Oportunidades | Caso vigente admite 0..N |
| CNS/capital de Cotización competían con la proyección del Caso | Son valores descriptivos; la proyección viva pertenece al Caso y no se suma automáticamente |
| Emisión, capital y CNS reconocidos aparecían mezclados | Son hechos distintos; reconocimiento y capital quedan fuera del lote sin ser negados |
| Cierre Ganado podía ocurrir antes de sometimiento/emisión | `Ganado` ocurre sólo al alcanzar `Emitido` |
| Oportunidades aparecían sólo como complementarias | Pueden ser complementarias o alternativas; Cotizaciones configuran un mismo contrato potencial |

ADR-025, Modelo Comercial y Matriz de Validación pasaron a `Aprobado`. PR #35 fue actualizado, marcado listo y fusionado; Issue #34 quedó cerrado.

### 3.2 Estado real del Legacy

Se adoptó la evidencia más reciente de Issues/PR y runtime:

| Tema | Estado conciliado |
|---|---|
| Gestionabilidad | Implementada y promovida mediante PR #19/#20; Issue #12 cerrado como completado |
| Métricas diarias | Derivadas por Persona/día y promovidas a PROD |
| Muestra analítica | 125 Personas distintas / 25 estratos, implementada en Issues #22/#23 |
| Edición vs. gestión | Separación corregida; datos ficticios saneados en Issues #26/#27 |
| Carga julio/agosto | Completada y conciliada en Issue #36 |
| Campaña inválida | 13.826 filas de cola retiradas sin borrar historia en Issue #37 |
| Exclusión persistente | Sigue pendiente en Issue #38; no se presenta como resuelta |
| Navegación | `UI-20260803-07` aprobada en Issue #39 |
| `get_contacts_v2` | Defecto semántico de metadatos detectado en Issue #36; pendiente de Issue/fix propio |

El Roadmap dejó de afirmar que toda la Fase 1 está pendiente y diferencia implementación, deuda administrativa y brechas reales.

### 3.3 Activación de campaña

La regla antigua decía que los primeros contactos válidos del período siguiente desactivaban la campaña anterior. El Modelo Operacional se actualizó con la operación realmente utilizada en Issue #36: activación explícita, posterior a validación y conciliación del conjunto, con fecha, actor y ejecuciones asociadas. Una fila o carga parcial no cambia el período por sí sola.

### 3.4 Gobierno documental

La excepción de “espejo navegable” fue eliminada. ADR-026 refina ADR-022 y ADR-023:

- no hay sincronización posterior al merge;
- no hay catálogo separado;
- no hay Registro Maestro en Drive;
- ramas y PR son el único espacio de borrador documental;
- una exportación de conversación no tiene autoridad.

El validador ahora falla si los archivos rectores vuelven a referenciar el catálogo retirado, un espejo navegable o su sincronización.

## 4. Migración Drive → GitHub

| Origen de Drive | Destino / tratamiento | Uso vigente |
|---|---|---|
| Constitución | `docs/project/constitution.md` | Principios rectores |
| Arquitectura | `docs/architecture/crm-patrimonial.md` | Arquitectura integral Legacy/Next |
| Backlog y Roadmap | `docs/project/backlog-roadmap.md` | Estado, pendientes y prioridad |
| Índice del Modelo del Dominio | `docs/domain/README.md` | Entrada y separación de modelos |
| Diccionario | `docs/domain/dictionary.md` | Lenguaje ubicuo |
| Modelo Patrimonial | `docs/domain/patrimonial-model.md` | Estrategias, vehículos, portafolios y evolución |
| Modelo de Productos | `docs/domain/product-model.md` | Estructura transversal; fuentes Consorcio quedan en Drive |
| Bitácora ADR-001…020 | `docs/adr/ADR-001-020-historical-decisions.md` | Historia consolidada y refinamientos |
| Normalizador de bases | `tools/normalize_campaign_bases.py` | Herramienta genérica publicable, sin datos ni secretos |
| APP LLAMADOS · Modelo de negocio | Absorbido; no se creó otro archivo | Reglas válidas incorporadas en modelos, Arquitectura y política de elegibilidad |
| Acuerdos funcionales y backlog vivo | Absorbido; no se creó otro archivo | Reglas operativas en `AGENTS.md`; pendientes vigentes en Roadmap |
| Registro Maestro Sheet | Retirado sin reemplazo paralelo | Sus funciones las cumplen los registros Git y el índice de autoridad |

Después del merge validado se eliminaron permanentemente de Drive los once documentos propios, el Sheet paralelo y el normalizador migrado. Git conserva el contenido conciliado y su historia futura; Drive no conserva copia recuperable de esos archivos retirados.

Las carpetas `Modelo del dominio` y `Modelo de Productos` se renombraron como carpetas de fuentes para que no aparenten contener modelos canónicos.

## 5. Contenido que permanece exclusivamente en Drive

### Datos y operación

- `Bases_maestras`: originales `.xls/.xlsx`, normalizados y archivos históricos con datos reales.
- `Backup_bases_maestras` y `Backup_producción`.
- `CARGA_CONTROLADA_JULIO_AGOSTO_2026_V2`, ZIP, manifiesto, script específico, log, resultados y tres bases normalizadas.
- carpetas/ZIP de correcciones históricas de cargas.

Estos artefactos sirven como datos, respaldo o evidencia; no gobiernan el dominio ni sustituyen procedimientos Git.

### Productos Consorcio

Permanece el Sheet `Índice y Matriz de Productos Consorcio` y las fuentes: `Crédito Hipotecario`, `Seguro Gold`, `APV Aplicado`, `Tributación Seguros de Vida I/II`, `Coberturas Adicionales I/II`, `Plan Plus y Cuenta Duo`, `Nivelación`, `Crédito de Consumo`, `Seguro Hogar`, `Vida Ahorro Total`, `Introducción al APV`, `Seguros de Salud Con/Sin DPFS`, `Fondos Mutuos`, `Seguro Vida Futura`, `Nuestros Productos APV`, `Seguro Auto` y `Vida Ahorro Más`.

Son fuentes corporativas/terceras. El modelo propio está en GitHub y enlaza conceptualmente estas fuentes sin copiarlas.

## 6. Inventario y uso de documentos GitHub

### Entradas y gobierno

| Archivo | Uso / acción |
|---|---|
| `README.md` | Entrada pública; actualizado para Legacy + Next |
| `PROJECT_MAP.md` | Mapa breve y estado actual; actualizado hasta Issue #39 |
| `AGENTS.md` | Reglas obligatorias; actualizado a ADR-026 y rutas canónicas |
| `docs/governance/document-authority.md` | Regla e índice único; absorbió el catálogo eliminado |
| `docs/governance/lcd-registry.md` | Registro único de 14 LCD; actualizado hasta LCD-20260803-01 |
| `docs/governance/adr-registry.md` | Registro único de 26 ADR; actualizado a ubicaciones Git |

### Documentos rectores y dominio

| Archivo | Uso / acción |
|---|---|
| `docs/project/constitution.md` | Nuevo desde Drive, reconciliado |
| `docs/project/backlog-roadmap.md` | Nuevo desde Drive, reescrito según estado real |
| `docs/architecture/crm-patrimonial.md` | Nuevo desde Drive, reconciliado con ADR-024/025 y Legacy actual |
| `docs/domain/README.md` | Nuevo índice único del dominio |
| `docs/domain/dictionary.md` | Nuevo Diccionario actualizado |
| `docs/domain/commercial-model.md` | Aprobado; absorbió Modelo de negocio y ADR-025 |
| `docs/domain/operational-model.md` | Aprobado; corregida activación de campaña |
| `docs/domain/patrimonial-model.md` | Nuevo desde Drive, sin contradecir ADR-025 |
| `docs/domain/product-model.md` | Nuevo desde Drive; separa modelo y fuentes Consorcio |
| `docs/domain/validation-matrix-next-v03.md` | Aprobada; puente regla → prueba antes de SQL |

### ADR

| Archivo(s) | Uso / acción |
|---|---|
| `docs/adr/ADR-001-020-historical-decisions.md` | Nueva bitácora histórica consolidada |
| `ADR-018-monorepo-*` y `ADR-019-docs-as-code-*` | Punteros históricos; actualizados a la bitácora Git |
| `ADR-021-monorepo-*` | Monorepo y transición Legacy/Next; se conserva |
| `ADR-022-docs-as-code-*` | Separación Git/Drive; refinado por ADR-026 |
| `ADR-023-autoridad-*` | Identificadores/autoridad; refinado por ADR-026 |
| `ADR-024-limites-*` | Separación Comercial/Operacional; se conserva |
| `ADR-025-estructura-*` | Aprobado después de resolver cinco divergencias |
| `ADR-026-ubicacion-*` | Nueva decisión: ubicación única sin espejos |

### Arquitectura técnica

| Archivo(s) | Uso / estado |
|---|---|
| `contact-eligibility-policy.md` | Política única ejecutable del Legacy |
| `current-repository-inventory.md` | Foto AS-IS; referencia de autoridad corregida |
| `product-environment-deployment-matrix.md` | Productos, ambientes y promoción |
| `target-monorepo-structure.md` | Estructura objetivo; referencia de autoridad corregida |
| `reversible-monorepo-migration-plan.md` | Plan reversible; referencia de autoridad corregida |
| `legacy-automation-security-audit.md` | Riesgos de automatización/seguridad; fuente canónica corregida |
| `prod-pwa-validator-drift.md` | Evidencia histórica de deriva de versión |
| `diagrams/README.md`, `applied-case-agenda.md`, `as-is-app-llamados.md`, `migration-legacy-to-next.md`, `to-be-crm-patrimonial-next.md` | Mapas visuales; se conservan como vistas de arquitectura |

### Operación y runtime

| Archivo(s) | Uso / estado |
|---|---|
| `docs/CHANGELOG.md` | Historia humana; actualizado con Issues #26/#27/#36/#37/#39 |
| `docs/DATABASE.md` | Arquitectura de base Legacy; se conserva |
| `docs/ENVIRONMENTS.md` | Separación de ambientes; se conserva |
| `docs/RECOVERY.md` | Recuperación histórica del Legacy; se conserva |
| `docs/RELEASE_PROTOCOL.md` | Promoción y rollback; se conserva |
| `docs/DEV_ASSIGNED_IMPORT_STATUS_20260710.md` | Evidencia histórica DEV |
| `docs/DEV_ISOLATION_20260710.md` | Evidencia de aislamiento DEV |
| `docs/DEV_SECURITY_HARDENING_20260710.md` | Evidencia de hardening DEV |
| `docs/DEV_metricas_operativas_diarias.md` | Evidencia de métricas DEV |
| `docs/DEV_regla_gestionabilidad_6_meses.md` | Antecedente histórico sustituido por política canónica; no gobierna |
| `docs/PROD_metricas_operativas_diarias_20260713.md` | Evidencia de promoción PROD |
| `docs/operations/legacy-critical-surface.md` | Contrato de superficie crítica Legacy |
| `docs/operations/legacy-smoke-test.md` | Procedimiento de smoke test |
| `docs/operations/monthly-status-backfill.md` | Procedimiento de backfill exacto |
| `docs/operations/session-checkpoint.md` | Checkpoint operativo heredado; se conserva como evidencia |
| `docs/operations/validation-run-2026-07-15-eligibility.md` | Evidencia de promoción de gestionabilidad |
| `docs/operations/validation-run-2026-07-15.md` | Evidencia de validación del lote |
| `dev/README.md` | Entrada al snapshot DEV |
| `releases/README.md` | Criterio de snapshots/releases |
| `tests/characterization/README.md` | Alcance de la red de caracterización |

### Aprendizaje

| Archivo | Uso / estado |
|---|---|
| `docs/learning/README.md` | Entrada; último LCD actualizado |
| `learning-log.md` | Evidencia cronológica de aprendizaje |
| `skills-matrix.md` | Competencias por evidencia |
| `2026-07-14-stage-0-closure.md` | Cierre educativo de etapa 0 |
| `2026-07-14-stage-1a-safety-net.md` | Evidencia educativa del safety net |

### Documentos eliminados de GitHub

| Archivo retirado | Motivo / destino de conocimiento |
|---|---|
| `docs/ARCHITECTURE.md` | Describía sólo v1.05 y una migración React antigua; absorbido por Arquitectura integral e inventario |
| `docs/PENDING.md` | Backlog del 2026-07-09 desactualizado; reemplazado por Roadmap |
| `docs/PROJECT_OPERATING_RULES.md` | Duplicaba AGENTS y superficie Legacy; absorbido |
| `docs/governance/document-catalog.md` | Duplicaba autoridad y permitía transición ambigua; absorbido por `document-authority.md` |

## 7. Validaciones

- `tools/validate_document_governance.py`: PASS, 14 LCD, 26 ADR, sin duplicados.
- 24 pruebas de caracterización: PASS.
- `tools/run_legacy_safety_checks.py`: PASS.
- validaciones de shell PROD, build/aislamiento DEV y PWA: PASS.
- `tools/normalize_campaign_bases.py`: compila sin dependencias externas y fue migrado sin modificar su lógica.
- `git diff --check`: PASS.
- no se accedió ni modificó ningún ambiente Supabase.

## 8. Observaciones y sugerencias

### Acciones de simplificación ya realizadas

1. Autoridad + catálogo: fusionados en un solo documento.
2. ADR-001…020: una bitácora, no veinte archivos nuevos.
3. Modelo de negocio y Acuerdos: absorbidos, no duplicados.
4. Arquitectura Legacy, Pendientes y Reglas operativas antiguas: retirados después de absorber su contenido útil.

### Sugerencias siguientes

1. **No dividir más el núcleo rector.** Constitución, Arquitectura, índice/modelos del dominio y Roadmap cumplen funciones distintas y forman un conjunto pequeño y suficiente.
2. **Reducir la Matriz de Validación cuando existan pruebas ejecutables.** Con más de novecientas líneas, debería evolucionar hacia casos automatizados y conservar sólo el índice semántico; no dividirla hoy, porque antes de SQL sigue siendo el puente de revisión.
3. **Adelgazar ADR-025 después del diseño físico.** Hoy la redundancia con el Modelo Comercial ayuda a revisar la decisión. Una vez estabilizada y probada, la ADR puede conservar contexto/decisión/consecuencias y delegar detalles al modelo.
4. **Consolidar evidencia operativa por release.** Los documentos `DEV_*`, `PROD_*` y validaciones fechadas son útiles, pero su crecimiento puede controlarse mediante un informe por release y artefactos automáticos. No fusionar retrospectivamente hasta confirmar enlaces externos.
5. **Revisar `docs/learning/` con PR #21.** Si el aprendizaje sigue activo, mantener README + matriz + log y absorber los cierres de etapa en el log. Si no, archivar toda la carpeta como evidencia histórica.
6. **Crear un Issue para `get_contacts_v2`.** El defecto de metadatos observado en Issue #36 no debe quedar sólo en un comentario.
7. **Resolver Issue #38 antes de otra carga.** La corrección manual de Issue #37 puede revertirse con un rebuild si la exclusión no se vuelve persistente.
8. **Preservar el artefacto final de cargas.** Drive contiene un paquete denominado V2 y evidencia parcial, mientras el Issue #36 describe una secuencia posterior V3–V6. Para futuras cargas, guardar exactamente el paquete final ejecutado, su hash y el resultado; retirar variantes intermedias sólo después.
9. **Etiquetar evidencia obsoleta.** `DEV_regla_gestionabilidad_6_meses.md` y el paquete V2 no deben borrarse mientras tengan valor de auditoría, pero deben mantenerse claramente como antecedentes no vigentes.

## 9. Pendientes reales después de la conciliación

- Issue #38: exclusión persistente de campañas inválidas, primero en DEV.
- defecto semántico de metadatos de `get_contacts_v2`: crear Issue y corregir.
- PR #21: decidir integración, reducción o cierre.
- diseño físico `next_v03`: abrir un LCD propio con pruebas reproducibles.
- completar auditoría del catálogo Consorcio y verificación normativa de rentabilidades APV.

No queda pendiente ninguna migración de documentos propios entre Drive y GitHub.
