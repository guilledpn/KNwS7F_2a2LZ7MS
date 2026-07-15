# Smoke test repetible · APP LLAMADOS Legacy

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Comprobar rápidamente que las capacidades esenciales de APP LLAMADOS siguen disponibles después de un cambio.

Un **smoke test** es una verificación breve y amplia. No demuestra que todo el sistema esté correcto; demuestra que no está evidentemente roto y que las rutas críticas continúan operativas.

## Ambientes

| Ambiente | Datos | Uso permitido en este checklist |
|---|---|---|
| DEV | Ficticios | Pruebas con escritura y cambios de estado |
| PROD | Reales | Sólo lectura o verificación no destructiva, salvo autorización explícita |

## Precondiciones

- rama y commit bajo prueba identificados;
- navegador con consola disponible;
- credenciales DEV válidas;
- confirmación visual de que DEV muestra identidad `DEV`;
- ningún secreto privado copiado en terminal, issue o captura;
- para PROD, autorización expresa si alguna prueba pudiera escribir.

## Registro de ejecución

```text
Fecha y hora:
Ejecutor:
Rama:
Commit:
Ambiente:
URL:
Resultado general: PASS / FAIL / BLOQUEADO
Incidencias relacionadas:
```

## A. Controles automatizados locales

Ejecutar desde la raíz del repositorio:

```bash
python tools/run_legacy_safety_checks.py
```

Resultado esperado:

```text
PASS: repository characterization
PASS: PROD validation
PASS: isolated DEV build and validation
```

Si falta Node.js, el resultado debe clasificarse como `BLOQUEADO`, no como `PASS`.

## B. Smoke test visual en DEV

### B1. Identidad y aislamiento

- [ ] La aplicación abre bajo la ruta `/dev/`.
- [ ] El título o interfaz muestra `DEV`.
- [ ] Se muestra la advertencia de datos ficticios/no productivos.
- [ ] No aparece identidad visual de PROD.
- [ ] La consola no informa que DEV contiene el endpoint PROD.

Resultado: `PASS / FAIL / BLOQUEADO`

### B2. Autenticación

- [ ] La pantalla de acceso carga.
- [ ] Un inicio de sesión DEV válido permite entrar.
- [ ] Una contraseña inválida produce un mensaje controlado.
- [ ] Cerrar sesión vuelve a la pantalla de acceso.

No utilizar credenciales PROD.

Resultado: `PASS / FAIL / BLOQUEADO`

### B3. Contactos y búsqueda

- [ ] La lista de contactos carga sin error.
- [ ] El total y los chips muestran valores.
- [ ] Buscar por nombre devuelve coincidencias ficticias.
- [ ] Buscar por RUT ficticio devuelve coincidencias.
- [ ] Limpiar búsqueda restaura la lista.

Resultado: `PASS / FAIL / BLOQUEADO`

### B4. Detalle del contacto

- [ ] Un contacto abre su detalle.
- [ ] Se muestran identidad, teléfonos, correo y campaña cuando existan.
- [ ] Navegar al contacto anterior/siguiente funciona.
- [ ] Cerrar detalle vuelve a la lista.

Resultado: `PASS / FAIL / BLOQUEADO`

### B5. Registro de gestión en DEV

Usar exclusivamente un contacto ficticio reservado para pruebas.

- [ ] Cambiar a `Agenda` guarda el estado.
- [ ] Volver a abrir conserva el estado.
- [ ] Cambiar a otro estado genera una nueva transición.
- [ ] Comentarios ficticios se guardan.
- [ ] Ingreso estimado ficticio se guarda.
- [ ] Stats refleja la gestión según el comportamiento actual.

Registrar el identificador ficticio utilizado para poder limpiar o revertir.

Resultado: `PASS / FAIL / BLOQUEADO`

### B6. Teléfono activo

- [ ] Seleccionar un teléfono lo marca como activo.
- [ ] Recargar conserva la selección.
- [ ] Cambiar de teléfono actualiza la selección.
- [ ] No se ejecuta una llamada real durante la prueba.

Resultado: `PASS / FAIL / BLOQUEADO`

### B7. Recordatorio e integración externa

- [ ] Título, fecha y hora pueden editarse.
- [ ] El recordatorio se guarda en DEV.
- [ ] Las integraciones externas están deshabilitadas por defecto.
- [ ] No se envía una tarea real sin configurar deliberadamente un webhook ficticio.

Resultado: `PASS / FAIL / BLOQUEADO`

### B8. Stats

- [ ] La vista Stats abre.
- [ ] Los períodos Hoy, Semana y Mes responden.
- [ ] Las métricas no muestran errores de consulta.
- [ ] El informe diario carga.
- [ ] Copiar reporte funciona.

Resultado: `PASS / FAIL / BLOQUEADO`

### B9. Importar y Ajustes

- [ ] Importar abre sin iniciar automáticamente una carga.
- [ ] El selector de período es visible.
- [ ] Ajustes abre y cierra.
- [ ] Los campos de integraciones externas no contienen secretos privados.
- [ ] No se carga ningún Excel real en este smoke test.

Resultado: `PASS / FAIL / BLOQUEADO`

### B10. PWA

- [ ] La aplicación puede abrirse en ventana instalada o navegador.
- [ ] El service worker no controla rutas superiores a `/dev/`.
- [ ] La identidad instalada de DEV es distinguible de PROD.
- [ ] Una recarga mantiene la aplicación operativa.

Resultado: `PASS / FAIL / BLOQUEADO`

## C. Smoke test visual no destructivo en PROD

Ejecutar sólo cuando el cambio podría afectar publicación o shell PWA.

- [ ] La URL productiva responde.
- [ ] La identidad no dice DEV.
- [ ] La pantalla de login o sesión activa carga.
- [ ] La lista abre sin ejecutar una gestión.
- [ ] Un detalle puede abrirse y cerrarse sin editar.
- [ ] Manifest e íconos cargan.
- [ ] No aparece el endpoint DEV en la consola o recursos.

No cambiar estados, comentarios, recordatorios, teléfono activo ni datos de contacto.

Resultado: `PASS / FAIL / BLOQUEADO`

## D. Revisión móvil y escritorio

### Móvil

- [ ] La navegación inferior es visible.
- [ ] El detalle no queda cortado.
- [ ] Inputs y botones son utilizables.
- [ ] El teclado no oculta el campo activo permanentemente.

### Escritorio

- [ ] La aplicación conserva el ancho previsto.
- [ ] No aparecen scrolls horizontales inesperados.
- [ ] Los diálogos y paneles son accesibles.

## E. Clasificación de resultados

| Clasificación | Significado |
|---|---|
| PASS | El comportamiento esperado fue observado. |
| FAIL · Regresión | Algo que funcionaba dejó de funcionar por el cambio. |
| FAIL · Bug conocido | El fallo ya existía y está trazado en un Issue. |
| BLOQUEADO | No pudo probarse por falta de herramienta, credencial o dato ficticio. |
| LIMITACIÓN | La prueba no cubre suficientemente el riesgo. |

Nunca convertir un `BLOQUEADO` en `PASS` por ausencia de evidencia.

## F. Rollback del smoke test

- revertir estados y recordatorios creados en el contacto ficticio;
- eliminar archivos temporales locales;
- no borrar logs de PROD;
- si el cambio probado produjo una regresión, volver al commit estable o revertir el PR;
- registrar la evidencia y el motivo del rollback.

## G. Criterio de aprobación

El cambio puede avanzar cuando:

- los controles automatizados pasan;
- los pasos DEV relevantes pasan;
- los pasos PROD no destructivos pasan cuando correspondan;
- no quedan fallas sin clasificar;
- existe rollback claro;
- el resultado queda asociado al PR o Issue.
