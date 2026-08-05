# Checkpoint de cierre y reanudación de sesiones

- Estado: Procedimiento vigente
- Última actualización: 2026-08-05

## Propósito

Conservar el estado necesario para cerrar o reanudar un trabajo versionado sin convertir el checkpoint en una segunda fuente de verdad.

Los Issues, Pull Requests y el repositorio conservan el estado oficial. Este documento sólo define una plantilla operativa.

## Cuándo usarlo

Usar cuando una tarea versionada se interrumpe y no queda resuelta únicamente por el estado visible del Issue o Pull Request.

No es obligatorio para operaciones breves que concluyen en la misma sesión y ya poseen registro operativo suficiente.

## Cierre

Registrar sólo:

- fecha y producto;
- ambiente afectado;
- `main` consultado;
- Issue, rama y Pull Request cuando existan;
- último commit relevante;
- validaciones ejecutadas;
- cambios operativos realizados;
- recuperación disponible;
- bloqueo o riesgo;
- próxima acción concreta.

## Reanudación

1. confirmar el `main` vigente;
2. revisar el Issue y Pull Request relacionados;
3. comprobar la rama o commit registrado;
4. verificar que el ambiente real coincida con el checkpoint;
5. continuar desde la próxima acción;
6. detener sólo el trabajo dependiente ante una divergencia.

## Plantilla

```text
Fecha y hora:
Producto:
Ambiente:
Main consultado:
Issue:
Rama:
Pull Request:
Último commit:
Validaciones:
Cambios operativos:
Recuperación:
Riesgo o bloqueo:
Próxima acción:
```

No copiar en el checkpoint PII, secretos, bases reales ni logs extensos.
