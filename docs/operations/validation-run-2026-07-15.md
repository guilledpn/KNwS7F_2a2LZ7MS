# Ejecución local de la red mínima de seguridad

- Fecha: 2026-07-15
- LCD: LCD-20260714-02
- Issue: #16
- Pull Request: #18
- Rama: `test/lcd-20260714-02-legacy-safety-net`

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

## Estado actual

```text
Caracterización del repositorio        PASS
Validación PROD estructural nueva      Pendiente de ejecución local
Build DEV en workspace temporal        Pendiente de ejecución local
Validación de aislamiento DEV/PROD      Pendiente de ejecución local
```

La siguiente ejecución debe realizarse después de `git pull` con:

```text
python tools/run_legacy_safety_checks.py
```
