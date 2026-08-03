# ADR-026 · Ubicación documental única sin espejos

- Fecha: 2026-08-03
- Estado: Aprobado
- LCD: LCD-20260803-01
- Issue: #40
- Motivo: eliminar la fragilidad detectada al conciliar GitHub y Drive

## Contexto

ADR-022 y ADR-023 declararon una autoridad editable por artefacto, pero conservaron durante la transición un Registro Maestro de Drive como espejo navegable. Ese Sheet incorporó ADR-025 y LCD-20260802-01 antes de que el PR #35 fuese fusionado, mientras `main` aún terminaba en ADR-024. La excepción produjo una divergencia real y bloqueó la auditoría del Roadmap.

Una regla que depende de distinguir manualmente entre “canónico”, “espejo”, “candidato” y “exportación reciente” no es suficientemente robusta para este proyecto.

## Decisión

1. Cada artefacto tiene una sola ubicación editable y una sola copia vigente.
2. GitHub es el destino predeterminado de todo conocimiento propio, publicable y versionable.
3. Drive se usa exclusivamente para datos, material sensible o reservado, archivos de terceros, respaldos, fuentes externas y binarios no apropiados para Git.
4. No se mantienen espejos, copias navegables, documentos paralelos ni sincronización bidireccional.
5. Un enlace puede apuntar a la ubicación canónica, pero no reproducir su contenido.
6. Los borradores Git existen en ramas/PR; no se copian a Drive.
7. Las exportaciones adjuntas a conversaciones son insumos temporales, nunca autoridad.
8. Una migración cambia autoridad sólo después de merge validado; en ese momento la copia anterior se elimina, no se archiva como aparente versión vigente.

## Distribución

| Sólo GitHub | Sólo Drive |
|---|---|
| Constitución, Arquitectura, Roadmap, modelos, diccionario, ADR/LCD, procedimientos, diagramas, código, pruebas y herramientas genéricas | Bases de campaña, PII, respaldos, evidencia operativa no publicable, PDFs/manuales corporativos, fuentes regulatorias/terceros y archivos grandes |

## Migración ejecutada

- Constitución, Arquitectura, Roadmap, Índice, Diccionario, Modelo Patrimonial y Modelo de Productos se conciliaron y migraron a Markdown.
- Bitácora ADR-001…020 se consolidó en un único archivo histórico.
- `APP LLAMADOS · Modelo de negocio` y `Acuerdos funcionales y backlog vivo` se absorbieron en modelos, reglas, Arquitectura y Roadmap; no se conservaron como documentos duplicados.
- El normalizador genérico de bases se migró a `tools/normalize_campaign_bases.py`.
- El Registro Maestro Sheet y las copias documentales de Drive se retiraron después del merge.
- Fuentes de Productos Consorcio, bases, respaldos y evidencia permanecieron en Drive.

## Consecuencias

### Positivas

- La ubicación define inequívocamente la autoridad.
- Ramas, diff, PR y merge concentran el ciclo documental.
- Se reduce la cantidad de documentos y el trabajo de sincronización.
- Una revisión puede validar la estructura completa desde el repositorio.

### Costos y límites

- Los documentos públicos no pueden incluir datos personales ni material reservado.
- Algunas decisiones deberán enlazar fuentes en Drive sin copiar su contenido.
- El historial de una copia eliminada de Drive deja de estar disponible allí; Git conserva el contenido migrado y sus cambios posteriores.

## Refinamientos

- Refina ADR-022: mantiene la separación Git/Drive, elimina cualquier ambigüedad transitoria.
- Refina ADR-023: suprime catálogo separado, espejo navegable y documentos superiores vivos en Drive.
- Declara obsoleta ADR-019 como arquitectura vigente; sólo conserva valor histórico.

## Control

El validador documental comprueba registros, ADR, enlaces rectores y ausencia de referencias normativas a espejos. `docs/governance/document-authority.md` funciona además como índice único; no existe un catálogo paralelo.
