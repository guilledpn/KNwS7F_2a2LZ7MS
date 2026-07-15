# Ejecución local de la red mínima de seguridad

- Fecha: 2026-07-15
- LCD: LCD-20260714-02
- Issue: #16
- Pull Request: #18
- Rama: `test/lcd-20260714-02-legacy-safety-net`
- Estado final: `PASS`

## Primera ejecución

Resultado:

- 10 pruebas aprobadas;
- 1 falso positivo en el control de secretos;
- la suite se detuvo por política fail-fast.

Clasificación:

```text
Limitación de la prueba · detector autorreferencial
```

Corrección aplicada:

- excluir validadores de la búsqueda de sus propias firmas;
- mantener por separado una prueba que exige que los validadores conserven esas firmas.

## Segunda ejecución

Resultado:

- 12 pruebas de caracterización aprobadas;
- fallo posterior en `tools/validate_prod_pwa.py`;
- DEV no alcanzó a construirse por política fail-fast.

Mensaje:

```text
Versión PWA restaurada no trazable
```

Diagnóstico:

- el service worker vigente sí conserva `APP_VERSION` y `PATCH_ID`;
- el validador histórico exige una versión anterior literal;
- el restaurador histórico conserva la misma versión anterior;
- modificar esos archivos podría activar un workflow mutante con escritura en `main`.

Clasificación:

```text
Contrato de prueba obsoleto + deriva entre restaurador y shell PROD vigente
```

Control aplicado:

- agregar `tools/validate_prod_shell_readonly.py`;
- actualizar el runner para usar el nuevo validador;
- no modificar el restaurador, el validador histórico ni el workflow productivo.

## Tercera ejecución

Resultado:

- 12 pruebas de caracterización aprobadas;
- el nuevo validador de PROD se detuvo al buscar un comentario histórico en `build_dev_snapshot.py`;
- el comportamiento ejecutable de sanitización DEV sí estaba presente.

Diagnóstico:

- la expectativa dependía del texto de un comentario;
- `build_dev_snapshot.py` conserva las llamadas reales a `re.sub` que eliminan los metadatos PWA productivos y el registro del service worker productivo.

Clasificación:

```text
Contrato de prueba frágil · expectativa basada en comentario y no en comportamiento
```

Corrección aplicada:

- analizar el AST de `build_dev_snapshot.py`;
- validar las llamadas ejecutables a `re.sub` independientemente de comentarios, espacios o formato.

## Cuarta ejecución

Resultado:

- 12 pruebas de caracterización aprobadas;
- validación estructural de PROD en `PASS`;
- fallo al construir DEV dentro del workspace temporal;
- Windows informó `PermissionError: [WinError 5] Acceso denegado` al eliminar `dev/assets/app/config`.

Diagnóstico:

- la copia temporal heredó atributos que impedían borrar una carpeta;
- el checkout original y los archivos productivos no fueron modificados;
- el fallo ocurrió antes de completar la construcción aislada de DEV.

Clasificación:

```text
Entorno bloqueado · permisos heredados en workspace temporal de Windows
```

Corrección aplicada:

- normalizar permisos de escritura únicamente dentro de la copia temporal;
- mantener intacto `tools/build_dev_snapshot.py`, utilizado por un workflow mutante;
- agregar una prueba de regresión para exigir la normalización de permisos.

## Ejecución final aprobada

Entorno observado:

- Windows;
- PowerShell;
- Python 3.13;
- commit bajo prueba: `cdfddae`;
- comando: `python tools/run_legacy_safety_checks.py`.

Resultado:

```text
Repository characterization             PASS · 13 tests · OK
Read-only PROD shell validation         PASS
Isolated DEV build                      PASS
DEV assigned-status patch               PASS
DEV PWA identity                        PASS
DEV snapshot validation                 PASS
DEV/PROD environment isolation          PASS
```

Evidencia final emitida por el runner:

```json
{
  "status": "PASS",
  "prod_modified": false,
  "dev_build_workspace": "temporary",
  "network_required": false,
  "prod_data_accessed": false,
  "checks": [
    "repository_characterization",
    "prod_shell_validation",
    "isolated_dev_build",
    "dev_snapshot_validation",
    "environment_isolation"
  ]
}
```

La validación confirmó además:

- `APP_VERSION`: `App_llamados_v1.05-lcd-20260713-01-stats`;
- `PATCH_ID`: `LCD-20260713-01`;
- ningún endpoint PROD dentro del artefacto DEV;
- integraciones externas deshabilitadas por defecto en DEV;
- ninguna dependencia de runtime de DEV respecto de PROD;
- ningún acceso a Supabase ni a datos reales;
- ningún archivo productivo modificado;
- ningún workflow activado por la ejecución local.

## Conclusión

El sublote técnico de red mínima de seguridad cumple su contrato local y puede avanzar a revisión del Pull Request.

Este resultado no corrige ni modifica la divergencia funcional de gestionabilidad, que permanece separada en el Issue #12.
