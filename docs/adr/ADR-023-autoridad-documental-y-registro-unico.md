# ADR-023 · Autoridad documental y registro único de identificadores

- Fecha: 2026-08-01
- Estado: Aprobado
- LCD: LCD-20260801-01
- Issue: #28
- Refinamiento: ADR-026 · LCD-20260803-01

## Contexto

Google Drive y GitHub evolucionaron parcialmente en paralelo. Ambos contenían decisiones válidas, pero utilizaron los mismos identificadores ADR y LCD para contenidos diferentes. Además, algunos estados operativos recientes estaban actualizados sólo en Drive y cambios técnicos posteriores sólo en GitHub.

La divergencia hacía imposible determinar la fuente vigente únicamente desde la fecha de modificación y podía producir nuevas decisiones sobre una base documental incorrecta.

## Decisión

1. Adoptar una sola autoridad editable por artefacto.
2. Mantener GitHub como fuente canónica para conocimiento propio versionable, ingeniería y registros maestros.
3. Mantener Drive como fuente canónica para archivos originales, evidencia externa, datos sensibles y material no apto para Git.
4. Reconocer un único espacio de nombres para ADR y otro para LCD en todo el proyecto.
5. Convertir `docs/governance/adr-registry.md` y `docs/governance/lcd-registry.md` en registros canónicos.
6. Exigir la reserva del identificador antes de crear rama, documento o decisión.
7. Mantener una sola ubicación durante cualquier migración y retirar la anterior inmediatamente después del merge validado.
8. No reescribir commits ni Pull Requests históricos; registrar equivalencias explícitas.

## Reconciliación aprobada

- La decisión de monorepo pasa de su alias histórico ADR-018 a ADR-021.
- La decisión Docs-as-Code pasa de su alias histórico ADR-019 a ADR-022.
- El lote de gobernanza del PR #9 pasa de su alias histórico LCD-20260713-01 a LCD-20260713-03.
- El lote de inventario y transición del PR #11 pasa de su alias histórico LCD-20260713-02 a LCD-20260713-04.
- ADR-018, ADR-019, LCD-20260713-01 y LCD-20260713-02 conservan los significados inscritos previamente en Drive.

## Invariantes documentales

- Un identificador representa una sola decisión o lote durante toda la vida del proyecto.
- Un documento posee una sola ubicación editable canónica.
- Una copia histórica nunca reemplaza silenciosamente a la fuente canónica.
- Una divergencia detectada bloquea el merge del lote que intente apoyarse en ella.
- El estado `Aprobado` no se deduce de un commit aislado; requiere el mecanismo de aprobación definido para la ubicación canónica.
- Las fuentes sensibles nunca se trasladan al repositorio público por conveniencia documental.

## Consecuencias

### Positivas

- Los nuevos LCD y ADR no pueden chocar entre Drive y GitHub.
- La autoridad se consulta en un punto único y versionado.
- La migración documental puede realizarse gradualmente sin crear dos verdades.
- Se conserva la historia completa sin alterar commits antiguos.

### Costos

- Los documentos vivos de Drive requieren migración individual y validada.
- Una migración exige retirar la copia anterior después del merge.
- Las referencias históricas necesitan aliases explícitos.

## Controles

- Revisión obligatoria de registros antes de asignar identificadores.
- Actualización del índice único de autoridad en todo cambio de estructura.
- Prueba documental de unicidad en una etapa posterior.
- Revisión del diff para asegurar que los lotes documentales no alteren runtime sin declararlo.
- Prohibición de fusionar una colisión no resuelta.

## Alternativas descartadas

### Mantener dos registros coordinados manualmente

Descartado porque fue la causa directa de la divergencia.

### Renumerar las decisiones de Drive

Descartado porque Drive contenía el registro histórico previo y decisiones de mayor jerarquía ya enlazadas a esos números.

### Reescribir la historia Git

Descartado porque rompería trazabilidad de commits y Pull Requests. Se utilizan aliases y archivos de compatibilidad.

### Declarar toda la carpeta de Drive obsoleta

Descartado porque Drive sigue siendo necesario para fuentes sensibles, evidencia externa, respaldos y material corporativo. ADR-026 sí retira de allí los documentos propios migrados.

## Refinamiento posterior

ADR-026 demostró que incluso un registro presentado como referencia podía confundirse con la autoridad. Desde LCD-20260803-01 no existe catálogo separado, Registro Maestro paralelo ni documento superior vivo en Drive.
