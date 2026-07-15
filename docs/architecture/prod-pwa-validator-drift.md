# Deriva entre el shell PROD y su restaurador histórico

- Fecha: 2026-07-15
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16
- Pull Request: #18

## Propósito

Registrar un hallazgo detectado al ejecutar por primera vez la red mínima de seguridad de APP LLAMADOS Legacy.

## Resultado observado

Las doce pruebas de caracterización del repositorio finalizaron correctamente. La siguiente etapa falló al ejecutar:

```text
python tools/validate_prod_pwa.py
```

El validador exigía literalmente:

```text
App_llamados_v1.05-pwa-restored-20260710
```

El `sw.js` productivo versionado declara actualmente:

```text
APP_VERSION = App_llamados_v1.05-lcd-20260713-01-stats
PATCH_ID = LCD-20260713-01
```

## Clasificación

```text
Contrato de prueba obsoleto + deriva entre restaurador y artefacto productivo vigente
```

No se observó pérdida de trazabilidad en el service worker. La trazabilidad existe, pero cambió después de la restauración histórica de la PWA.

## Riesgo arquitectónico

`tools/validate_prod_pwa.py` y `tools/restore_prod_pwa.py` pertenecen al workflow mutante `.github/workflows/restore-prod-pwa.yml`.

Ese workflow:

- se activa por cambios en esos archivos;
- tiene permiso `contents: write`;
- puede aplicar el restaurador;
- puede confirmar cambios productivos directamente en `main`.

Modificar el validador histórico dentro del PR #18 podría activar una modificación automática de PROD. Por ello no se actualizan en este lote:

- `tools/validate_prod_pwa.py`;
- `tools/restore_prod_pwa.py`;
- `.github/workflows/restore-prod-pwa.yml`.

## Control aplicado en el Issue #16

Se agrega:

```text
tools/validate_prod_shell_readonly.py
```

Este validador:

- sólo lee archivos del checkout;
- no ejecuta el restaurador;
- no accede a Supabase;
- no requiere red;
- no modifica PROD ni DEV;
- valida estructura PWA, endpoints, manifest, íconos y JavaScript;
- comprueba que `APP_VERSION` y `PATCH_ID` sean únicos y coherentes;
- evita depender de una cadena histórica exacta.

El runner `tools/run_legacy_safety_checks.py` utiliza este validador tanto sobre el checkout local como sobre la copia temporal donde se construye DEV.

## Decisión posterior requerida

En una etapa separada y controlada se deberá:

1. decidir si `restore_prod_pwa.py` sigue siendo un restaurador vigente o debe archivarse como herramienta histórica;
2. alinear el validador productivo con el mecanismo de release actual;
3. desacoplar validación de restauración y publicación;
4. impedir que una validación ordinaria genere cambios productivos;
5. probar rollback antes de modificar el workflow.

## Regla de seguridad

Hasta resolver esa deuda técnica, `tools/validate_prod_pwa.py` no debe usarse como validador general de la versión productiva vigente fuera de su workflow histórico.
