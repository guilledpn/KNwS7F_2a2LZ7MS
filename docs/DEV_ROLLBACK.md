# Rollback app DEV

La publicación DEV agrega una carpeta aislada `/dev/`.

Para revertir:

1. Eliminar `dev/index.html`.
2. Eliminar `dev/README.md` si corresponde.
3. Mantener producción intacta.

La app productiva vive en `/index.html` y no debe depender de `/dev/`.
