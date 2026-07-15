# Backfill dirigido de estado corporativo mensual

- Fecha: 2026-07-15
- Estado: Pendiente de revisión
- LCD: LCD-20260715-01
- Issue: #12
- Ambiente actual: preparación y validación en DEV

## Propósito

Completar `contact_month_state.estado_origen` desde las bases mensuales originales sin reimportar contactos, borrar gestiones ni actualizar identidad, teléfonos o correos.

Un **backfill** es una actualización dirigida de hechos históricos faltantes. No es una nueva importación completa.

## Datos permitidos

El artefacto generado contiene únicamente:

- RUT normalizado;
- período `AAAA-MM`;
- `campaign_key`;
- `Gestionado` o `No Gestionado`;
- nombre y hash SHA-256 de la fuente;
- número de fila de origen.

No contiene nombres de personas, teléfonos ni correos.

Aun así, el RUT es un identificador personal. Por eso los archivos `*.backfill.sql` son locales, sensibles y están ignorados por Git.

## Fuentes localizadas

Se localizaron en el RDP bases para abril, mayo, junio y julio de 2026.

La fuente encontrada para mayo incluye `desactualizado` en su nombre. No puede utilizarse para PROD hasta comprobar que sea la fuente corporativa definitiva o reemplazarla por la versión correcta.

## Generación

Ejecutar desde la raíz del repositorio:

```powershell
python tools/generate_monthly_status_backfill.py `
  --source 2026-04="local-data/abril.xlsx" `
  --source 2026-05="local-data/mayo.xlsx" `
  --source 2026-06="local-data/junio.xlsx" `
  --source 2026-07="local-data/julio.xlsx" `
  --output "local-data/lcd-20260715-01.backfill.sql"
```

El generador:

1. lee `.xlsx` o `.csv` sin conectarse a Supabase;
2. detecta `RUT`, `Nombre de Campaña`, `Gestionado/Estado` y, cuando existe, `Mes`;
3. filtra cada fuente por el período declarado;
4. normaliza RUT y campaña con el mismo contrato de la base;
5. rechaza estados distintos de `Gestionado/No Gestionado`;
6. rechaza duplicados contradictorios;
7. calcula SHA-256 de cada archivo;
8. produce un SQL local con preflight obligatorio.

## Preflight del SQL generado

Antes de actualizar, el SQL exige que cada fila coincida exactamente con una sola aparición existente mediante:

```text
contacts.rut_norm
+ campaigns.period
+ campaigns.campaign_key
+ contact_month_state.contact_id/campaign_id/period
```

Si falta una coincidencia o aparece una ambigüedad, la transacción aborta completa.

No existe fallback por:

- nombre;
- teléfono;
- correo;
- similitud textual;
- orden de importación;
- campaña aproximada.

## Aplicación

Orden obligatorio para STAGING y PROD:

1. verificar respaldo y último estado estable;
2. aplicar la migración de política canónica;
3. ejecutar el SQL de backfill consolidado dentro de una transacción;
4. comprobar que todas las filas fueron actualizadas;
5. reconstruir `work_queue` del período activo;
6. comparar recuentos y hechos antes/después;
7. ejecutar smoke test;
8. registrar evidencia y rollback.

El SQL generado ya ejecuta el rebuild dentro de la misma transacción después de completar las coincidencias exactas.

## Invariantes de preservación

El backfill no debe modificar:

- `contacts`;
- `crm_log`;
- `crm_events`;
- `contact_operational_state`;
- `estado_gestion` existente;
- ingresos estimados;
- comentarios;
- recordatorios;
- teléfono activo;
- identidad o datos de contacto.

Sólo actualiza `contact_month_state.estado_origen` y luego reconstruye campos derivados de visibilidad/origen/contexto en `work_queue`.

## Validación en DEV

DEV usa RUT ficticios que no se corresponden con las bases reales. Por eso el backfill no se ejecutó con fuentes reales allí.

Se validaron mediante fixtures transaccionales:

- coincidencia exacta;
- rechazo de conflictos;
- filtrado mensual de XLSX;
- exclusión de PII adicional;
- política fail-closed;
- rebuild sin pérdida de estado del usuario;
- rollback total de fixtures.

## Rollback

### Antes del commit

Cualquier error de preflight o actualización provoca `ROLLBACK` automático de toda la transacción.

### Después del commit

Para revertir el backfill se requiere un artefacto inverso generado desde un snapshot previo de `estado_origen`. Ese snapshot debe prepararse y validarse antes de PROD.

Para revertir la lógica, utilizar:

```text
supabase/rollback/20260715_unify_contact_eligibility_policy.sql
```

Restaurar la lógica no revierte por sí mismo los hechos históricos completados. Son operaciones separadas y deben conservar trazabilidad independiente.

## Estado actual

- generador versionado;
- pruebas ficticias aprobadas;
- migración aplicada sólo en DEV;
- fuentes reales no aplicadas;
- PROD no consultado ni modificado;
- fuente definitiva de mayo pendiente de aclaración.
