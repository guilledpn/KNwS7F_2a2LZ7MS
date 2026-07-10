# Publicación app DEV

Fecha: 2026-07-10

## Objetivo

Publicar una segunda app en:

`/dev/`

conectada exclusivamente al proyecto Supabase DEV.

## Implementación

El archivo `dev/index.html` actúa como loader controlado:

1. Carga el `index.html` productivo desde la raíz.
2. Reemplaza la configuración Supabase por el proyecto DEV:
   - URL: `https://xcujixexjbuqqzlbomgw.supabase.co`
3. Mantiene la UI original de producción.
4. Agrega marca visual:
   - `DEV · NO PRODUCTIVO`
5. Cambia la versión visible a DEV.

## Restricciones

- No modifica `index.html` productivo.
- No modifica `sw.js`.
- No crea un service worker DEV.
- No toca Supabase producción.
- No usa service_role, JWT secret ni claves privadas.

## Nota sobre la publishable key

La app DEV usa la publishable key pública del proyecto DEV. Esta clave es apropiada para frontend y no es una clave privada.

## Validación pendiente

Después de mergear este PR, probar:

- abrir `https://guilledpn.github.io/KNwS7F_2a2LZ7MS/dev/`;
- iniciar sesión o usar magic link en Supabase DEV;
- confirmar banner DEV;
- confirmar que Contactos carga 111 filas de cola activa;
- confirmar que Stats carga;
- confirmar que Ajustes muestra marca DEV;
- confirmar que producción sigue intacta.
