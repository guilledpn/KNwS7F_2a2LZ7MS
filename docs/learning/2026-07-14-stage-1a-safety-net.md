# Evidencia de aprendizaje · Red mínima de seguridad del Legacy

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Práctica realizada

Preparación de una red técnica de seguridad antes de reorganizar APP LLAMADOS.

## Conceptos introducidos y aplicados

### Superficie crítica

Conjunto de archivos, servicios y automatizaciones cuya alteración puede afectar la continuidad operativa.

Aplicación en el proyecto:

- raíz publicada por GitHub Pages;
- PWA productiva;
- build DEV;
- validadores;
- Supabase;
- workflows con escritura.

### Smoke test

Verificación breve y amplia de que las rutas esenciales siguen operativas. No reemplaza pruebas exhaustivas.

Aplicación:

- checklist DEV con escritura ficticia;
- revisión PROD no destructiva;
- clasificación PASS, FAIL, BLOQUEADO y LIMITACIÓN.

### Prueba de caracterización

Prueba que registra el comportamiento observado antes de modificarlo.

Aplicación:

- contratos de archivos productivos;
- separación de endpoints;
- comportamiento mutante actual de workflows;
- divergencia conocida de gestionabilidad.

### Fixture

Conjunto controlado de datos ficticios utilizado para ejecutar una prueba de forma repetible.

Aplicación:

- casos de gestionabilidad sin RUT ni datos personales reales.

### Runner

Programa que coordina la ejecución de varias pruebas y validadores.

Aplicación:

- `tools/run_legacy_safety_checks.py`;
- ejecución de `unittest`;
- validación local de PROD;
- build DEV dentro de una copia temporal.

### Workspace temporal

Copia descartable del repositorio utilizada para construir o modificar artefactos sin ensuciar el working tree original.

### Workflow mutante

Automatización capaz de escribir commits o modificar el repositorio.

Aplicación:

- `build-dev-snapshot.yml`;
- `restore-prod-pwa.yml`.

### Deriva o drift

Diferencia no controlada entre ambientes, implementaciones o documentación.

Aplicación:

- tres funciones de DEV expresan políticas de gestionabilidad diferentes.

### Bloqueado no es PASS

Una prueba que no pudo ejecutarse por falta de herramienta o acceso no entrega evidencia positiva.

Aplicación:

- el contenedor del asistente no pudo clonar GitHub por resolución DNS;
- la sintaxis fue validada separadamente;
- la suite completa debe ejecutarse en el clon local antes del merge.

## Evidencia concreta

- rama `test/lcd-20260714-02-legacy-safety-net`;
- `.gitignore` preventivo;
- inventario de superficie crítica;
- smoke test documentado;
- auditoría de workflows y seguridad;
- pruebas `unittest`;
- fixtures de gestionabilidad;
- runner aislado;
- actualización del Issue #12 para descartar formalmente la regla de 203 contactos.

## Competencias observadas

| Competencia | Evidencia | Estado sugerido |
|---|---|---|
| Git y ramas | Continuación del Issue #16 en una nueva rama técnica | Guiado |
| Pull Requests | Separación entre sublote visual y sublote técnico | Guiado |
| Pruebas | Comprensión inicial de smoke test y caracterización | Introducido |
| Arquitectura | Relación entre superficie crítica, despliegue y continuidad | Guiado |
| Seguridad | Diferencia entre clave publicable y secreto privado | Introducido |
| Operación | Comprensión de PASS, FAIL, BLOQUEADO y rollback | Guiado |
| Dominio | Uso de la jerarquía documental para resolver políticas divergentes | Guiado |

## Próxima práctica

1. sincronizar la rama local;
2. ejecutar `python tools/run_legacy_safety_checks.py`;
3. leer la salida y clasificar cualquier falla;
4. revisar el Draft PR;
5. aprobar la red mínima sólo cuando exista un PASS reproducible.
