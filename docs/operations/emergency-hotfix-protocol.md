# Protocolo abreviado de hotfix en Legacy

Estado: vigente

Este procedimiento se usa sólo para una incidencia operativa urgente que afecte
APP LLAMADOS Legacy. No reemplaza el flujo normal de desarrollo ni autoriza por
sí mismo escrituras en PROD.

## Resultado mínimo exigible

Un hotfix no se considera terminado sólo porque la aplicación vuelva a
funcionar. Debe dejar una cadena reproducible:

Issue → autorización → preflight → snapshot/rollback → aplicación → smoke test → regularización GitHub

## Secuencia

1. **Issue**
   - describir el defecto, impacto, evidencia y alcance mínimo;
   - distinguir contención inmediata de solución estructural;
   - enlazar incidentes o decisiones relacionadas.
2. **Autorización**
   - registrar ambiente y operación exacta autorizada;
   - PROD no se modifica por inferencia ni por autorización genérica previa.
3. **Preflight**
   - identificar proyecto y período activos;
   - confirmar staging, sesiones o importaciones concurrentes;
   - contar el conjunto exacto;
   - comprobar invariantes y caso de control;
   - detenerse ante cualquier divergencia.
4. **Snapshot y rollback**
   - capturar claves exactas y valores previos antes de mutar;
   - escribir un rollback que use esa instantánea y no vuelva a inferir filas;
   - conservar fingerprints de los datos que no deben cambiar.
5. **Aplicación**
   - ejecutar una transacción idempotente;
   - modificar sólo los campos autorizados;
   - incluir guardas que provoquen rollback automático.
6. **Smoke test**
   - probar la ruta afectada y las superficies críticas relacionadas;
   - verificar conteos, fingerprints y ausencia de residuos temporales;
   - comprobar explícitamente hotfix anteriores que puedan solaparse.
7. **Regularización obligatoria**
   - crear o actualizar rama y PR;
   - versionar toda migración realmente aplicada, incluso compuertas temporales;
   - agregar regresión y procedimiento operativo;
   - conciliar nombres, versiones y hashes entre PROD y GitHub;
   - no cerrar el Issue hasta que GitHub pueda reconstruir el backend.

## Reglas de detención

Se detiene el hotfix si:

- aparece una carga o escritura concurrente no prevista;
- el conjunto deja de coincidir con el preflight;
- no existe rollback exacto;
- una operación puede revertir otra contención vigente;
- la rama no conserva la última realidad de Legacy;
- el smoke test modifica membresía, estados o historia fuera del alcance.

## Después de la emergencia

La contención puede ejecutarse antes del PR sólo cuando la continuidad operativa
lo exige. La excepción termina inmediatamente después del smoke test: la
regularización en GitHub pasa a ser el siguiente trabajo obligatorio y debe
completarse antes de considerar cerrado el cambio.
