# CRM Patrimonial Next · shell ejecutable

Primera superficie ejecutable de Next. Es un artefacto de **Etapa A**: valida la separación física del frontend, la PWA y la configuración local. No implementa todavía el esquema `next_v03` ni escribe hechos comerciales.

## Abrir en Windows

1. Descarga o clona la rama del Issue #76.
2. Abre `apps/crm-patrimonial/`.
3. Ejecuta `start-next.cmd`.
4. El navegador abrirá `http://127.0.0.1:4173`.

Requiere Python 3, disponible mediante `py` o `python`.

## Verificación

```powershell
python scripts/check.py
```

## Supabase local independiente

La configuración vive en `supabase/config.toml` y usa los puertos 56320–56324. Desde esta carpeta, con Docker Desktop y Supabase CLI instalados:

```powershell
supabase --help
supabase start -x realtime,storage-api,imgproxy,logflare,vector,supavisor
```

No se deben copiar referencias, claves ni endpoints de los proyectos Legacy.

## Límites de esta entrega

- datos exclusivamente ficticios;
- navegación y acciones de demostración;
- sin autenticación remota;
- sin esquema físico de dominio;
- sin migración;
- sin despliegue productivo.
