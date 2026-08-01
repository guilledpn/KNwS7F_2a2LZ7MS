# Autoridad documental del CRM Patrimonial

- Estado: Aprobado
- Fecha: 2026-08-01
- LCD: LCD-20260801-01
- ADR: ADR-023
- Issue: #28

## 1. Propósito

Establecer una única autoridad para cada artefacto documental y eliminar la posibilidad de que Google Drive y GitHub mantengan versiones editables divergentes del mismo conocimiento.

Esta norma no cambia la jerarquía documental del proyecto. La Constitución, la Arquitectura, el Modelo del Dominio, el Backlog y la Bitácora conservan su precedencia semántica con independencia de la plataforma en la que viva su versión canónica.

## 2. Regla fundamental

> Cada artefacto posee una sola ubicación editable canónica.

Una copia, exportación, respaldo, enlace, evidencia o versión histórica nunca adquiere autoridad por ser más reciente o estar en otra plataforma.

## 3. Distribución de autoridad

### 3.1 GitHub

GitHub es la fuente canónica para el conocimiento propio y versionable creado por el proyecto:

- Constitución, Arquitectura y modelos del dominio cuando completen su migración validada;
- Backlog y Roadmap;
- ADR y registros de decisiones;
- registros maestros de LCD y ADR;
- diagramas Mermaid;
- procedimientos operativos y de despliegue;
- documentación técnica y educativa;
- código, migraciones, pruebas y herramientas;
- trazabilidad mediante Issues, ramas, commits, Pull Requests y Releases.

La ubicación canónica de los documentos versionables se registra en `docs/governance/document-catalog.md` o en el índice especializado que lo sustituya.

### 3.2 Google Drive

Google Drive es la fuente canónica para fuentes y evidencias que no deben vivir en el repositorio Git:

- bases originales y normalizadas de campañas;
- archivos con datos personales o información sensible;
- manuales, folletos y documentos corporativos externos;
- PDFs, fuentes regulatorias y antecedentes de terceros;
- evidencias externas, respaldos y archivos grandes;
- matrices operativas que requieran Google Sheets mientras no exista una migración aprobada.

GitHub conserva índices y enlaces hacia estas fuentes, pero no duplica su contenido editable.

### 3.3 Repositorio público

Mientras `guilledpn/KNwS7F_2a2LZ7MS` sea público, queda prohibido incorporar:

- datos personales reales;
- bases de campaña;
- secretos o credenciales;
- documentación corporativa reservada;
- información patrimonial sensible;
- cualquier archivo cuya publicación no haya sido autorizada.

## 4. Transición de documentos actualmente vivos en Drive

Los documentos superiores que aún viven en Drive conservan autoridad hasta completar, para cada uno, este proceso:

1. exportación íntegra a Markdown;
2. reconciliación con decisiones posteriores;
3. revisión mediante Pull Request;
4. validación de contenido y enlaces;
5. merge aprobado;
6. actualización del catálogo documental;
7. conversión de la copia de Drive en referencia archivada o puntero no editable.

No basta con copiar un archivo para cambiar su autoridad.

## 5. Identificadores únicos

Los espacios de nombres `LCD-AAAAMMDD-NN` y `ADR-NNN` son únicos para todo el proyecto.

Antes de crear una rama, documento, Issue o ADR:

1. consultar `docs/governance/lcd-registry.md` y `docs/governance/adr-registry.md`;
2. reservar allí el identificador en la rama del lote;
3. verificar que no aparezca con otro significado en Drive ni GitHub;
4. usar ese mismo identificador en todos los documentos y commits del lote.

Un identificador reservado nunca se reutiliza para otro propósito, aunque el trabajo sea cancelado. Se marca `Cancelado`, `Sustituido` u `Obsoleto`.

## 6. Registros maestros

- `docs/governance/lcd-registry.md` es el registro canónico de LCD.
- `docs/governance/adr-registry.md` es el registro canónico de ADR.
- El Registro Maestro de Google Sheets queda como espejo navegable y referencia histórica durante la transición.
- La Bitácora de Drive conserva la historia anterior a esta reconciliación hasta que sea migrada y validada.

Los registros nunca sustituyen el contenido completo de una decisión o de un documento del dominio: indican identidad, estado, autoridad y ubicación.

## 7. Estados y aprobación

En GitHub:

- rama y Pull Request abierto: contenido pendiente;
- diff: mecanismo de revisión;
- merge autorizado: aprobación del lote;
- Release o despliegue: promoción operativa, cuando corresponda.

En Drive, el color rojo se mantiene exclusivamente para contenido del último LCD pendiente mientras existan documentos canónicos vivos allí. El rojo deja de aplicarse al documento una vez que su autoridad migra a GitHub.

## 8. Colisiones históricas reconciliadas

| Identificador conflictivo en GitHub histórico | Identificador canónico definitivo | Decisión |
|---|---|---|
| ADR-018 | ADR-021 | Monorepo y transición Legacy/Next |
| ADR-019 | ADR-022 | Docs-as-Code y separación Git/Drive |
| LCD-20260713-01 | LCD-20260713-03 | Gobernanza inicial del monorepo |
| LCD-20260713-02 | LCD-20260713-04 | Inventario y plan reversible del repositorio |

Los identificadores originales de Drive conservan su significado:

- ADR-018 y LCD-20260713-01: métricas operativas derivadas por Persona y día;
- ADR-019 y LCD-20260713-02: Registro Maestro y navegación documental.

Los commits y Pull Requests históricos no se reescriben. Los archivos vigentes y registros actuales contienen la equivalencia definitiva.

## 9. Control preventivo

Toda revisión documental debe comprobar:

- identificador reservado y único;
- una sola ubicación editable canónica;
- enlaces cruzados válidos;
- ausencia de información sensible en Git;
- actualización de los registros maestros;
- actualización del catálogo cuando cambia la autoridad;
- ausencia de copias paralelas presentadas como vigentes.

Una colisión detectada bloquea el merge hasta ser resuelta.
