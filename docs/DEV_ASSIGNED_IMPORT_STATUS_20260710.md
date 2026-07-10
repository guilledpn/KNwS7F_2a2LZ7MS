# DEV · Estado de origen en cargas de asignados

Fecha: 2026-07-10

## Regla funcional

- `Gestionado` en el archivo de asignados se importa como estado neutral `Gestionado`.
- `No Gestionado` se importa como `Pendiente`.
- Una reimportación no reemplaza estados posteriores como `Agenda`, `No agenda`, `Volver a llamar`, `No contactado` o `Contacto Inválido`.
- La aplicación permite filtrar y visualizar `Gestionado`, pero no seleccionarlo manualmente como resultado de una gestión.
- La importación no crea registros falsos en `crm_log` ni `crm_events`.

## Prueba sintética ejecutada en Supabase DEV

Primera importación:

- Total: 150
- Gestionado: 115
- Pendiente: 35
- Nulos: 0

Prueba de idempotencia y preservación:

- Se cambiaron tres filas a `Agenda`, `No agenda` y `Volver a llamar`.
- Se repitió la misma carga.
- Resultado: 112 `Gestionado`, 35 `Pendiente` y los tres estados posteriores preservados.

Los 150 contactos sintéticos, su campaña, staging, estados mensuales y cola fueron eliminados después de la prueba.

## Ambientes

- Supabase DEV: función corregida mediante migración `assigned_import_respects_source_status`.
- PROD: no modificado por este desarrollo.
