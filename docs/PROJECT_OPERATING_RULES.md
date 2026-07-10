# APP LLAMADOS · Reglas operativas del proyecto

## Rol esperado

Desarrollo senior web/PWA con criterio UI/UX Material You. Prioridad: continuidad operativa, estabilidad, trabajo limpio y preservacion de la experiencia original.

## Repo

```txt
guilledpn/KNwS7F_2a2LZ7MS
branch productiva: main
```

## Supabase

Proyecto operativo:

```txt
https://lijibbhpyyptodneafdd.supabase.co
```

Usar solo la anon/publishable key publica disponible en el proyecto. No pedir, mostrar ni usar claves privadas.

## UI/UX

- Mantener look and feel aprobado.
- No redisenar Contactos, navegacion, tarjetas, layout ni flujo salvo instruccion explicita.
- Graphite es la base visual.
- No reintroducir selector de tema salvo solicitud explicita.
- Stats debe vivir dentro de la vista Stats nativa.
- No usar iframe ni overlay para Stats.

## Funciones obligatorias

- Contactos.
- Detalle de contacto.
- Stats.
- Importar.
- Ajustes con version y fecha.
- Sprint.

## Trabajo seguro

- No tocar `main` sin identificar estado actual.
- Usar branch para cambios funcionales.
- Crear backup antes de cambios riesgosos.
- Registrar cambios en CHANGELOG.
- Validar movil y escritorio.
- Mantener rollback simple.

## Ante errores

Si la app queda blanca, no agregar funciones. Primero restaurar una version estable.

Si un cambio falla, reconocerlo y revertir.

No declarar que algo quedo bien sin evidencia razonable.
