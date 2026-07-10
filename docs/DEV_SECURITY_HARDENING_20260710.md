# APP LLAMADOS · Blindaje de Supabase DEV

Fecha: 2026-07-10  
Ambiente: DEV  
Proyecto Supabase: `crm-ffvv-dev` (`xcujixexjbuqqzlbomgw`)  
Aplicación: https://guilledpn.github.io/KNwS7F_2a2LZ7MS/dev/

## Objetivo

Cerrar el acceso anónimo a tablas y RPC de Supabase DEV sin alterar PROD ni interrumpir el funcionamiento del usuario autenticado.

## Estado anterior

- 16 tablas del esquema `public` sin RLS.
- Rol `anon` con permisos de lectura, inserción, actualización y eliminación.
- 16 RPC propias de la aplicación ejecutables por `anon`.
- El login de la interfaz ocultaba la aplicación, pero la base no exigía autenticación.

## Cambio aplicado

Migración Supabase registrada:

`20260710051034_dev_auth_boundary_hardening`

Archivo versionado:

`supabase/migrations/20260710051034_dev_auth_boundary_hardening.sql`

La migración:

1. activa RLS en todas las tablas públicas;
2. revoca todos los privilegios DML de `anon`;
3. crea una política de acceso para usuarios autenticados;
4. conserva SELECT, INSERT, UPDATE y DELETE para `authenticated`;
5. revoca EXECUTE público y anónimo sobre las RPC propias del esquema `public`;
6. mantiene las RPC disponibles para usuarios autenticados;
7. fija `search_path = public, pg_temp` en las funciones `SECURITY DEFINER`;
8. endurece los privilegios por defecto para objetos futuros.

Las funciones internas pertenecientes a la extensión `pg_trgm` no se consideran RPC de la aplicación ni acceden por sí solas a los datos del CRM.

## Validación ejecutada

Resultado de catálogo:

- tablas públicas: 16;
- tablas con RLS: 16;
- tablas con DML para `anon`: 0;
- políticas autenticadas: 16;
- RPC propias revisadas: 16;
- RPC propias ejecutables por `anon`: 0;
- RPC propias ejecutables por `authenticated`: 16;
- funciones `SECURITY DEFINER` sin `search_path` fijo: 0.

Pruebas de ejecución:

- `anon` intentando leer `contacts`: **permiso denegado**;
- `anon` intentando ejecutar `active_period()`: **permiso denegado**;
- sesión autenticada leyendo `contacts`: **160 filas visibles**;
- sesión autenticada ejecutando `active_period()`: **2026-07**;
- sesión autenticada ejecutando `get_contacts_v2_months()`: respuesta correcta.

## Alcance y límites

- PROD no fue modificado.
- `main` no fue modificado.
- La trazabilidad vive en la rama `dev/security-auth-boundary`.
- La política actual es adecuada para un CRM personal con un único usuario autenticado.
- Antes de incorporar más usuarios, se debe implementar autorización por propietario o rol, no solo autenticación.
- El blindaje equivalente de PROD requiere una migración separada y una validación protegida; no debe copiarse automáticamente sin revisar las políticas productivas existentes.

## Pruebas repetibles

Archivo:

`supabase/tests/dev_auth_boundary_checks.sql`

El test falla explícitamente si encuentra:

- una tabla pública sin RLS;
- permisos DML para `anon`;
- RPC propias ejecutables por `anon`;
- funciones `SECURITY DEFINER` sin `search_path` fijo;
- tablas sin la política autenticada acordada.
