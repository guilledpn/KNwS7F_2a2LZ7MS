# ADR-028 · Infraestructura independiente y corte total de CRM Patrimonial Next

- Fecha: 2026-08-05
- Estado: Candidato
- LCD: LCD-20260805-01
- Issue: #76

## Contexto

APP LLAMADOS Legacy continúa siendo la herramienta productiva, pero su frontend, sus tablas y sus mecanismos de despliegue acumulan acoplamientos que elevan el costo de mantener la operación. El ambiente denominado DEV pertenece a Legacy y se construye parcialmente desde la aplicación productiva; no constituye una plataforma adecuada para iniciar CRM Patrimonial Next.

El objetivo inmediato de Next es reemplazar la jornada completa de llamados y gestión cotidiana, no dividir el trabajo diario entre dos aplicaciones. Durante el desarrollo ambos productos coexistirán técnicamente, pero la operación real no debe fragmentarse por campaña, contacto ni subconjunto de datos.

ADR-021 ya aprobó el monorepo y la transición gradual. Debe precisarse cómo se separan los runtimes y cómo ocurre el corte operativo.

## Decisión

### 1. Un monorepo, dos productos independientes

CRM Patrimonial Next permanece en el repositorio `guilledpn/KNwS7F_2a2LZ7MS`, bajo `apps/crm-patrimonial/`.

Compartir repositorio no implica compartir runtime. Next posee de forma independiente:

- frontend y PWA;
- configuración y variables de ambiente;
- backend y base de datos;
- migraciones y seeds;
- autenticación, RLS y claves publicables;
- pruebas, build y artefactos;
- despliegue, dominio, caché y service worker;
- observabilidad, respaldo y rollback.

No se crea un repositorio nuevo. Esa alternativa duplicaría gobernanza, Issues, registros ADR/LCD, CI y trazabilidad sin resolver la separación de ambientes. Un cambio futuro de repositorio requerirá evidencia de impedimento real y otra ADR.

### 2. Ambientes propios de Next

La topología objetivo es:

```text
APP LLAMADOS Legacy
├── LEGACY-DEV
└── LEGACY-PROD

CRM Patrimonial Next
├── NEXT-LOCAL
├── NEXT-DEV
├── NEXT-STAGING
└── NEXT-PROD
```

Ningún ambiente Next puede reutilizar el proyecto Supabase, endpoints, claves, tablas, almacenamiento o autenticación de Legacy.

`NEXT-LOCAL` vive en `apps/crm-patrimonial/` y usa una configuración Supabase local con puertos propios. `NEXT-DEV`, `NEXT-STAGING` y `NEXT-PROD` requerirán proyectos remotos distintos y sólo existirán cuando hayan sido creados y verificados.

### 3. Corte operativo total

La transición no reparte la gestión diaria entre aplicaciones.

Antes del corte:

- Legacy continúa siendo la única aplicación operativa;
- Next se construye y valida con datos ficticios, sanitizados y ensayos reproducibles;
- no existe doble escritura de gestiones reales.

En el corte autorizado:

- se congela la escritura en Legacy;
- se captura y concilia el estado final;
- se ejecuta la migración completa necesaria para trabajar;
- Next se convierte en la única aplicación de gestión diaria;
- Legacy queda temporalmente disponible sólo para consulta o rollback;
- no se reabre escritura simultánea salvo recuperación expresamente autorizada.

### 4. Primera entrega ejecutable

Etapa A crea una shell navegable y PWA local en `apps/crm-patrimonial/`, con datos ficticios y sin conexión a Legacy. Su propósito es permitir inspección visual, validar identidad de producto y comprobar el aislamiento técnico antes del esquema físico `next_v03`.

La shell no representa todavía Actividades, Personas, colas ni CNS persistentes y no autoriza inferir el esquema.

### 5. Capacidad cloud

El intento de crear `crm-patrimonial-next-dev` en la organización Supabase actual fue rechazado porque los dos proyectos gratuitos activos ya están ocupados por Legacy DEV y PROD.

No se pausa, elimina ni transforma un proyecto Legacy como efecto implícito. Para crear los ambientes remotos se deberá elegir explícitamente una de estas vías:

- ampliar la capacidad del plan u organización actual;
- usar otra organización Supabase autorizada;
- pausar un proyecto Legacy sólo después de comprobar que no es requerido por trabajo concurrente y contar con autorización expresa.

## Alternativas rechazadas

### Reutilizar LEGACY-DEV

Rechazada porque perpetúa acoplamientos, mezcla contratos y vuelve ambiguas las migraciones y pruebas.

### Crear Next en otro repositorio

Rechazada en esta etapa porque contradice sin necesidad el monorepo aprobado y no aporta independencia de backend por sí sola.

### Pilotear por campañas o contactos

Rechazada porque obliga a consultar, registrar y conciliar dos aplicaciones durante la jornada y crea riesgo de doble llamada, doble tarea e historial fragmentado.

## Consecuencias

### Positivas

- Next puede evolucionar sin modificar el runtime de Legacy;
- el reemplazo operativo tiene una frontera clara;
- se evita deuda por doble escritura y sincronización bidireccional;
- la primera superficie puede evaluarse desde ahora;
- la infraestructura queda preparada para `next_v03`.

### Costos y riesgos

- mantener ambientes remotos separados puede requerir capacidad Supabase adicional;
- el corte total exige migración ensayada, conciliación y rollback;
- la shell local no sustituye una preview remota ni valida todavía Docker/Supabase local;
- la convivencia técnica previa al corte requiere disciplina para no reutilizar componentes Legacy por comodidad.

## Verificación requerida antes de aprobar

- shell ejecutable desde Windows;
- pruebas de aislamiento en PASS;
- configuración Supabase local sin secretos y con puertos exclusivos;
- workflow de validación y artefacto descargable;
- documentación y registros actualizados;
- diff sin cambios en Legacy, LEGACY-DEV ni LEGACY-PROD.
