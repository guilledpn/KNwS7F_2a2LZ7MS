# Checkpoint de cierre y reanudación de sesiones

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-01
- Issue: #14

## Propósito

Evitar que una pausa haga perder el estado real del trabajo. El checkpoint complementa Issues, Pull Requests, ADR y la Bitácora Arquitectónica.

## Cierre de sesión

1. Identificar la rama activa.
2. Revisar si existen cambios locales.
3. Publicar los commits que deban conservarse.
4. Registrar Issue, rama y Pull Request.
5. Indicar si el PR está Draft, Ready, fusionado o cerrado.
6. Confirmar si hubo cambios en DEV, STAGING o PROD.
7. Registrar pruebas y resultados.
8. Registrar rollback disponible.
9. Eliminar ramas residuales sólo después de confirmar el merge.
10. Escribir la próxima acción concreta.

## Reanudación de sesión

1. Cambiar a `main`.
2. Ejecutar Fetch y Pull cuando corresponda.
3. Revisar el último commit de `main`.
4. Comprobar Pull Requests abiertos y recientemente fusionados.
5. Comprobar Issues activos.
6. Identificar ramas residuales.
7. Abrir el checkpoint anterior.
8. Verificar que el ambiente real coincida con lo documentado.
9. Detenerse ante cualquier inconsistencia.
10. Crear o cambiar a la rama de la tarea que continúa.

## Plantilla mínima

```text
Fecha y hora:
Producto:
Ambiente:
Último main estable:
Issue activo:
Rama activa:
Pull Request:
Estado del PR:
Cambios locales pendientes:
Pruebas ejecutadas:
Cambios operativos realizados:
Rollback disponible:
Riesgos o inconsistencias:
Próxima acción concreta:
```

## Ramas fusionadas

```text
Confirmar Merged
→ cambiar a main
→ Fetch/Pull
→ comprobar el commit integrado
→ eliminar rama remota residual
→ eliminar rama local residual
→ registrar el cierre
```

Eliminar una rama fusionada no elimina los cambios incorporados a `main`.

## Interrupciones por incidentes

Un incidente productivo puede interrumpir una tarea arquitectónica, pero debe conservar Issue, rama, diagnóstico y rollback propios. Un hotfix incompleto no se mezcla con un lote documental o de migración.

## Checkpoint actual

- Último lote aprobado: LCD-20260713-02 mediante PR #11.
- Issue activo de migración: #14.
- Rama del lote: `docs/lcd-20260714-01-close-stage-0`.
- Etapa 0: aprobada y pendiente de cierre documental.
- Etapa 1: preparación documental; pruebas aún no implementadas.
- Incidente de gestionabilidad: separado y pendiente de tratamiento posterior.
- Próxima acción: revisar el cierre de Etapa 0 y el alcance inicial de Etapa 1.
