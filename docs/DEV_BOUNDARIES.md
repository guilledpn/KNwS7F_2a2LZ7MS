# Límites entre DEV y PROD

## DEV

Se puede:

- probar UI;
- romper flujos;
- ensayar RPC;
- cargar archivos de prueba;
- borrar datos ficticios;
- probar arquitectura nueva.

No se debe:

- usar datos reales sin sanitizar;
- conectar a Supabase producción;
- promover cambios sin checklist.

## PROD

Se usa solo para trabajo real.

No se experimenta en producción.
