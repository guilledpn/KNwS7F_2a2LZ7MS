# Nota de autenticación DEV

El proyecto Supabase DEV es independiente de producción.

Eso significa que los usuarios de producción no existen automáticamente en DEV.

Para entrar a la app DEV hay dos caminos:

1. Usar magic link desde la pantalla de login DEV si Supabase Auth permite crear usuario por OTP.
2. Crear manualmente el usuario en Supabase DEV desde Authentication.

No copiar usuarios reales masivamente.

No usar service_role ni secretos en frontend.
