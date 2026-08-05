# Arranque de ambientes de CRM Patrimonial Next

- Estado: Candidato
- Fecha: 2026-08-05
- LCD: LCD-20260805-01
- ADR: ADR-028
- Issue: #76

## Propósito

Abrir la shell ejecutable de Next y preparar su infraestructura local sin utilizar los proyectos, claves, tablas ni datos de APP LLAMADOS Legacy.

## 1. Abrir la shell en Windows

Desde el repositorio:

```text
apps\crm-patrimonial\start-next.cmd
```

El script inicia un servidor sólo en la máquina local y abre:

```text
http://127.0.0.1:4173
```

Alternativa PowerShell:

```powershell
cd apps/crm-patrimonial
.\start-next.ps1
```

Alternativa directa:

```powershell
python scripts/run_local.py
```

Cerrar la consola detiene el servidor.

## 2. Ejecutar validaciones

```powershell
cd apps/crm-patrimonial
python scripts/check.py
```

Las pruebas comprueban:

- archivos mínimos de la shell;
- identidad y alcance PWA;
- puertos locales independientes;
- ausencia de referencias a los proyectos Supabase Legacy.

## 3. Iniciar Supabase local

Requisitos:

- Docker Desktop activo;
- Supabase CLI vigente;
- ejecución desde `apps/crm-patrimonial/`.

Primero descubrir la versión y los comandos disponibles:

```powershell
supabase --version
supabase --help
supabase start --help
```

Después iniciar la selección mínima de servicios:

```powershell
supabase start -x realtime,storage-api,imgproxy,logflare,vector,supavisor
```

Puertos reservados:

| Servicio | Puerto |
|---|---:|
| API | 56321 |
| PostgreSQL | 56322 |
| Studio | 56323 |
| Mailpit/Inbucket | 56324 |
| Shadow database | 56320 |

No copiar al `.env` claves de `crm-ffvv-dev` ni `crm-ffvv-v2`. Las claves locales se obtienen desde la salida de `supabase start`.

## 4. Ambientes remotos reservados

| Ambiente | Nombre previsto | Estado |
|---|---|---|
| NEXT-DEV | `crm-patrimonial-next-dev` | Bloqueado por límite de proyectos activos |
| NEXT-STAGING | `crm-patrimonial-next-staging` | No creado |
| NEXT-PROD | `crm-patrimonial-next-prod` | No creado |

Cada proyecto remoto debe usar región São Paulo salvo una decisión posterior justificada y tendrá sus propias claves, Auth, RLS, migraciones, storage y backups.

## 5. Resolución del límite Supabase

La organización actual ya posee dos proyectos gratuitos activos. Las vías admisibles son:

1. ampliar la capacidad del plan u organización;
2. crear los proyectos en otra organización autorizada;
3. pausar un proyecto Legacy sólo con autorización expresa y después de comprobar que no existe trabajo concurrente que dependa de él.

Nunca eliminar ni reutilizar LEGACY-PROD. No apuntar Next hacia una base Legacy como solución temporal.

## 6. Artefacto ejecutable de CI

El workflow `.github/workflows/next-shell.yml` ejecuta las pruebas y publica el artefacto `crm-patrimonial-next-local` durante 14 días. Tras abrir el PR, puede descargarse desde la ejecución del workflow y abrirse con `start-next.cmd`.

## 7. Límite de la shell

La shell contiene datos ficticios y acciones de demostración. No registra Actividades, no crea Personas y no representa el esquema físico. Su función es permitir evaluación visual y comprobar la separación de producto.
