# Auditoría de automatización y seguridad del Legacy

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Registrar riesgos y controles de automatización, versionado y separación de ambientes antes de reorganizar APP LLAMADOS.

Esta auditoría no modifica workflows ni backend. Describe el estado observado y propone controles posteriores.

## Alcance revisado

- `.gitignore`;
- `.github/workflows/build-dev-snapshot.yml`;
- `.github/workflows/restore-prod-pwa.yml`;
- `tools/build_dev_snapshot.py`;
- `tools/validate_dev_snapshot.py`;
- `tools/validate_prod_pwa.py`;
- `src/dev/config/environment.js`;
- relación entre `main`, GitHub Pages, PROD y DEV;
- políticas de gestionabilidad observadas en DEV.

## Terminología

| Término | Significado |
|---|---|
| Workflow | Automatización declarada en GitHub Actions. |
| Trigger | Evento que inicia un workflow, por ejemplo un push. |
| Permiso `contents: write` | Autoriza a la automatización a crear commits o modificar referencias. |
| Workflow mutante | Workflow que puede modificar el repositorio, no sólo leer o validar. |
| Fail-fast | Detenerse en cuanto se detecta una condición insegura. |
| Secret scanning | Detección de credenciales o material sensible versionado. |
| Caracterización | Prueba que registra el comportamiento actual antes de cambiarlo. |
| Drift o deriva | Diferencia no controlada entre ambientes, código o documentación. |

## Resumen ejecutivo

Estado general: **riesgo controlable, pero no apto todavía para reorganización física**.

Controles positivos existentes:

- validadores explícitos de PROD y DEV;
- endpoints separados;
- identidad PWA distinta;
- DEV deshabilita integraciones externas por defecto;
- scripts rechazan `service_role`, JWT Secret y claves privadas;
- workflows restringen archivos modificables;
- build DEV comprueba que no modifica PROD.

Riesgos relevantes:

- no existía `.gitignore`;
- dos workflows tienen `contents: write`;
- ambos pueden crear commits directamente en `main`;
- `main` es simultáneamente rama integrada y canal productivo;
- DEV se genera desde la fuente productiva;
- existen políticas de gestionabilidad divergentes en funciones de DEV.

## A-01 · Ausencia de `.gitignore`

### Evidencia

No existía `.gitignore` en `main` al comenzar la auditoría.

### Riesgo

Versionado accidental de:

- `.env`;
- entornos virtuales;
- `node_modules`;
- datos descargados;
- resultados de pruebas;
- archivos temporales del editor.

### Control aplicado

Se agrega un `.gitignore` conservador.

No se ignoran todavía:

```text
dev/
diagnostics/
releases/
```

porque actualmente contienen elementos versionados y su reclasificación pertenece a una etapa posterior.

## A-02 · Workflow de build DEV con escritura

### Evidencia

`build-dev-snapshot.yml` declara:

```text
permissions:
  contents: write
```

Puede:

- construir `dev/`;
- confirmar diagnósticos en ramas;
- certificar una validación;
- confirmar `dev/` directamente en `main`.

### Riesgo

Una automatización de build puede cambiar la historia del repositorio y publicar un artefacto sin pasar por un PR independiente.

### Controles existentes

- filtros de rutas;
- verificación de que sólo cambie `dev/`;
- validadores de identidad y aislamiento;
- `concurrency` para evitar ejecuciones superpuestas equivalentes.

### Recomendación posterior

Separar conceptualmente:

```text
validate → build artifact → publish
```

La publicación debería requerir una decisión explícita o un mecanismo de release, no ser una consecuencia implícita de integrar cambios.

No se modifica el workflow en este LCD.

## A-03 · Workflow PROD con escritura directa

### Evidencia

`restore-prod-pwa.yml`:

- corre en `main` para rutas específicas;
- valida el endpoint productivo;
- aplica un parche determinista;
- restringe el diff permitido;
- crea un commit directo en `main`.

### Riesgo

La automatización puede modificar archivos productivos después de un merge. El commit integrado por el usuario no necesariamente es el último commit publicado.

### Controles existentes

- lista cerrada de archivos permitidos;
- validación de manifest, íconos, service worker y endpoints;
- reconstrucción de DEV para detectar contaminación cruzada;
- fallo ante archivos inesperados.

### Recomendación posterior

Convertir el parche productivo en:

- validación reproducible;
- artefacto generado;
- promoción explícita;
- rollback identificable.

No se modifica el workflow en este LCD.

## A-04 · Separación DEV/PROD

### Evidencia positiva

`src/dev/config/environment.js`:

- declara `appEnv: 'DEV'`;
- apunta al proyecto DEV;
- rechaza el project ref de PROD;
- exige ejecutarse bajo `/dev/`;
- usa namespace local `crm_ffvv_dev_`;
- deshabilita integraciones externas por defecto.

Los validadores comprueban además:

- endpoint DEV presente;
- endpoint PROD ausente;
- PWA id independiente;
- service worker acotado;
- ausencia de webhooks productivos;
- ausencia de material sensible prohibido.

### Riesgo residual

DEV sigue tomando `index.html` productivo como referencia de construcción. Una modificación estructural de PROD puede romper el build DEV aunque los datos estén separados.

### Control requerido

Toda reorganización debe ejecutar el build DEV en un workspace temporal y comprobar que PROD queda sin cambios.

## A-05 · Claves publicables y secretos

### Distinción

Una **clave publicable** puede estar en un cliente web cuando el acceso efectivo está protegido por RLS. No equivale a una clave privada.

Material prohibido:

- `service_role`;
- JWT Secret;
- claves privadas;
- contraseñas;
- tokens personales;
- archivos `.env` reales.

### Estado observado

Los scripts de validación buscan material prohibido. No se realizó una afirmación exhaustiva sobre toda la historia Git; esta rama agrega controles preventivos y pruebas textuales sobre la superficie crítica.

### Pendiente posterior

Habilitar o verificar secret scanning en GitHub y auditar la historia completa con una herramienta especializada.

## A-06 · Deriva de política de gestionabilidad

### Fuente canónica

La Arquitectura y el Modelo de Negocio establecen:

- última aparición `No Gestionado` → potencialmente gestionable;
- última aparición `Gestionado` → no gestionable preventivamente;
- presencia en campaña activa excluye descubrimiento;
- asignación propia es excepción.

### Implementaciones observadas en DEV

`get_contacts_v2` usa:

```text
asignado
OR gestionado por el usuario actual
OR disponible por antigüedad de gestión
```

`rebuild_work_queue_for_period` usa:

```text
asignado
OR última aparición No Gestionado y ausencia en período activo
```

`sync_work_queue_for_period_batch` inserta contactos del lote mensual como visibles sin aplicar la política completa.

### Clasificación

```text
Bug conocido + deriva entre funciones
```

### Decisión de este LCD

- documentar la divergencia;
- crear una prueba de caracterización que la haga visible;
- no corregir funciones dentro del Issue #16;
- mantener el incidente en una rama e Issue separados.

## A-07 · `main` es integración y despliegue

### Riesgo

Un merge a `main` puede:

- publicar inmediatamente GitHub Pages;
- activar workflows;
- generar commits posteriores;
- cambiar `dev/` o archivos productivos según rutas.

### Control inmediato

Antes de fusionar cambios:

1. revisar rutas afectadas;
2. identificar workflows activables;
3. ejecutar pruebas locales;
4. realizar smoke test;
5. observar commits automáticos posteriores;
6. registrar el estado estable final.

## Matriz de riesgos

| ID | Riesgo | Probabilidad | Impacto | Estado |
|---|---|---:|---:|---|
| A-01 | Versionar archivos locales o secretos | Media | Crítico | Mitigación inicial agregada |
| A-02 | Build DEV escribe en `main` | Media | Alto | Documentado; pendiente rediseño |
| A-03 | Workflow PROD escribe en `main` | Baja/Media | Crítico | Controles fuertes; pendiente separación |
| A-04 | Contaminación DEV/PROD | Baja | Crítico | Controles existentes + pruebas |
| A-05 | Material sensible en historia Git | Desconocida | Crítico | Auditoría exhaustiva pendiente |
| A-06 | Política de gestionabilidad divergente | Alta | Alto | Bug conocido separado |
| A-07 | Merge equivale a despliegue | Alta | Alto | Procedimiento y smoke test |

## Acciones permitidas en este sublote

- agregar `.gitignore`;
- agregar documentación;
- agregar pruebas locales no destructivas;
- agregar un runner que trabaje en copia temporal;
- abrir un Issue separado por la deriva de gestionabilidad.

## Acciones no permitidas

- cambiar triggers o permisos de workflows;
- modificar GitHub Pages;
- aplicar migraciones a PROD;
- corregir la gestionabilidad;
- mover archivos raíz;
- eliminar artefactos versionados.

## Criterio de cierre

La auditoría se considera suficiente para esta etapa cuando:

- los riesgos están trazados;
- las pruebas detectan pérdida de archivos críticos y mezcla de ambientes;
- el build DEV puede validarse en copia temporal;
- el smoke test es repetible;
- la deriva de gestionabilidad tiene Issue separado;
- ninguna acción del lote modifica PROD.
