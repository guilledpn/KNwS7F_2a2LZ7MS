# LCD-20260805-01 · Infraestructura independiente y shell ejecutable de Next

- Estado: Candidato
- Fecha: 2026-08-05
- Issue: #76
- ADR: ADR-028
- Tipo: Desarrollo de producto e infraestructura

## Objetivo

Crear la base física inicial de CRM Patrimonial Next sin reutilizar los ambientes, proyectos Supabase ni artefactos ejecutables de APP LLAMADOS Legacy, y entregar una shell local que el usuario pueda abrir y evaluar.

## Alcance ejecutado

- creación de `apps/crm-patrimonial/`;
- shell HTML/CSS/JavaScript navegable con identidad Next;
- PWA y service worker con alcance propio;
- scripts de arranque local para Windows y Python;
- configuración Supabase local en puertos 56320–56324;
- `.env.example` sin secretos;
- pruebas automáticas de estructura, PWA, puertos y ausencia de endpoints Legacy;
- workflow `Next shell` que valida y publica un artefacto descargable;
- ADR-028 y documentación de ambientes, corte y arranque;
- actualización de Arquitectura, Roadmap, mapa y registros.

## Hallazgo externo

Supabase informó costo mensual `USD 0` por proyecto en la organización actual, pero rechazó la creación de `crm-patrimonial-next-dev` porque el propietario ya alcanzó el límite de dos proyectos gratuitos activos. Esos dos proyectos corresponden a Legacy DEV y PROD.

No se pausó, eliminó ni modificó ningún proyecto. `NEXT-DEV`, `NEXT-STAGING` y `NEXT-PROD` permanecen no creados.

## Fuera de alcance

- esquema físico `next_v03`;
- SQL o migraciones de dominio;
- autenticación remota;
- importación o migración de datos reales;
- hosting público definitivo;
- creación o promoción de NEXT-PROD;
- cambios en APP LLAMADOS Legacy;
- corrección administrativa de LCD-20260804-05.

## Validación

- `python apps/crm-patrimonial/scripts/check.py`: 4 pruebas PASS;
- servidor local: HTTP 200 para `/` y `manifest.webmanifest`;
- manifest JSON válido;
- configuración TOML analizada correctamente;
- referencias a los proyectos `crm-ffvv-dev` y `crm-ffvv-v2`: ausentes del runtime Next;
- datos reales, PII y secretos: no incorporados.

No se pudo validar el arranque completo de Supabase local porque el entorno de ejecución disponible no posee Docker ni acceso a sus imágenes. La configuración queda lista para verificación en un equipo con Docker Desktop y Supabase CLI.

## Ambientes afectados

- Repositorio: rama del Issue #76.
- NEXT-LOCAL: shell creada; backend local configurado, no iniciado en este entorno.
- NEXT-DEV: no creado por límite externo.
- NEXT-STAGING: no creado.
- NEXT-PROD: no creado.
- LEGACY-DEV y LEGACY-PROD: sin cambios.

## Criterio de aprobación

El lote puede aprobarse cuando el PR conserve exclusivamente la infraestructura y documentación declaradas, `Document governance` y `Next shell` finalicen en PASS y el usuario acepte que la capacidad cloud se resuelva en un paso posterior sin reutilizar Legacy.
