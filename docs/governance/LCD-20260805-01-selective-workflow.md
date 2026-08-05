# LCD-20260805-01 · Clasificación selectiva y consolidación de autoridad operativa

- Estado: Aprobado por autorización explícita del usuario; incorporación mediante PR #85
- Fecha: 2026-08-05
- Issue: #84
- ADR: No aplica
- Tipo: Cambio documental de gobernanza e ingeniería

## Problema

La documentación distinguía categorías de trabajo, pero varias superficies repetían autoridad, flujo, Git, ambientes, validación y cierre:

- `AGENTS.md`;
- instrucciones de ChatGPT;
- estándar de desarrollo;
- `PROJECT_MAP.md`;
- índice de autoridad documental.

Además, `docs/operations/` mezclaba procedimientos vigentes con evidencia fechada de ejecuciones pasadas.

La duplicación hacía que una clasificación proporcional se aplicara como una capa adicional y generaba relectura, sincronización manual, divergencias y sobreingeniería.

## Decisión

### 1. La clasificación selecciona el procedimiento

Las categorías no acumulan automáticamente requisitos de otras categorías.

Operación rutinaria o excepcional sin cambio canónico:

```text
Objetivo → preflight → mecanismo mínimo → recuperación → autorización → ejecución → verificación → registro
```

Cambio versionado o permanente:

```text
Issue → diseño → rama → implementación → pruebas → Pull Request → promoción autorizada
```

LCD, ADR, auditoría independiente y ambientes adicionales se incorporan sólo cuando corresponden a la naturaleza o riesgo real del trabajo.

### 2. Dos superficies normativas generales

Se reducen las instrucciones generales activas a:

- `AGENTS.md`: router de trabajo;
- `docs/engineering/development-standards.md`: única norma técnica general.

Las demás superficies cumplen funciones subordinadas:

- instrucciones de ChatGPT: copia operativa sin reglas nuevas;
- `document-authority.md`: índice y asignación de autoridad;
- `PROJECT_MAP.md`: resumen de estado;
- `docs/operations/`: procedimientos concretos;
- ADR/LCD: decisiones históricas;
- `docs/evidence/`: evidencia histórica.

### 3. Separación de procedimientos y evidencia

Se trasladan desde `docs/operations/` a `docs/evidence/legacy/`:

- `legacy_monthly_source_order_fix_20260803.md`;
- `validation-run-2026-07-15.md`;
- `validation-run-2026-07-15-eligibility.md`.

El movimiento no cambia su contenido técnico ni su valor probatorio. Sólo corrige su clasificación documental.

`session-checkpoint.md` se conserva como procedimiento, pero se elimina el checkpoint histórico incrustado y queda como plantilla mínima.

### 4. Lectura por alcance

Antes de trabajar se confirma el `main` vigente y se consulta la fuente principal de la materia. No se releen íntegramente todos los documentos rectores salvo duda concreta o divergencia.

## Fuente principal por pregunta

| Pregunta | Fuente |
|---|---|
| ¿Cómo enruto la tarea? | `AGENTS.md` |
| ¿Cómo desarrollo o modifico código/SQL? | `docs/engineering/development-standards.md` |
| ¿Cómo ejecuto una operación? | procedimiento en `docs/operations/` |
| ¿Por qué se tomó una decisión? | ADR o LCD |
| ¿Qué ocurrió en una ejecución pasada? | `docs/evidence/` |
| ¿Dónde vive cada artefacto? | `docs/governance/document-authority.md` |
| ¿Cuál es el estado resumido? | `PROJECT_MAP.md` |

## Documentos modificados

- `AGENTS.md`;
- `PROJECT_MAP.md`;
- `docs/engineering/development-standards.md`;
- `docs/governance/document-authority.md`;
- `docs/governance/lcd-registry.md`;
- `docs/operations/chatgpt-project-instructions.md`;
- `docs/operations/session-checkpoint.md`;
- este LCD.

Se crea `docs/evidence/legacy/README.md` y se reclasifican tres informes históricos.

## Reconciliación

`LCD-20260804-05` queda registrado como aprobado mediante Issue #65, PR #66 y commit `d5da04503f73cf6a82397e53fcc018de8dcdfc1f`.

## Fuera de alcance

No se modifican:

- Constitución;
- Arquitectura;
- Modelo del Dominio;
- Backlog y Roadmap;
- ADR;
- código, SQL, migraciones, pruebas o configuración;
- importador Legacy;
- LOCAL, DEV, STAGING o PROD;
- bases de campaña, PII o evidencia reservada;
- Issue #63 ni PR #64.

## Consecuencias

### Positivas

- una fuente principal por materia;
- menos lectura y sincronización manual;
- menor riesgo de reglas divergentes;
- procedimientos separados de evidencia histórica;
- operaciones acotadas sin flujo de desarrollo innecesario.

### Riesgo

Una copia subordinada puede quedar desactualizada.

### Mitigación

La copia debe declarar su subordinación y no puede introducir reglas nuevas. La revisión documental compara responsabilidades y enlaces, no obliga a duplicar texto.

## Validación

- diff y archivos reclasificados revisados;
- ausencia de PII y secretos;
- enlaces y responsabilidades coherentes;
- `Document governance`: PASS requerido;
- controles de runtime: No aplica.

## Aprobación

La autorización del usuario aprueba la reducción documental. El merge del PR #85 incorpora la decisión a `main`.
