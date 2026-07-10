# Releases

Esta carpeta debe guardar versiones completas recuperables de la app.

Objetivo:

- permitir restaurar una version sin depender de cache local;
- conservar HTML productivo completo cuando la app siga siendo monolitica;
- documentar que version corresponde a que commit;
- facilitar auditoria futura.

Convencion sugerida:

```txt
releases/App_llamados_v1.05.html
releases/App_llamados_v1.06.html
```

Cada release debe tener entrada en `docs/CHANGELOG.md`.
