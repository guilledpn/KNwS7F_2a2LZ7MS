# APP LLAMADOS · Ambientes PROD y DEV

Fecha: 2026-07-10

## Objetivo

Separar el trabajo diario de producción del trabajo experimental de desarrollo.

La app productiva debe seguir estable y usable todos los días. El ambiente DEV existe para probar cambios, romper cosas, ensayar cargas y validar nuevas funciones sin riesgo operativo.

## Ambientes

### Producción

- Uso: trabajo real diario.
- GitHub branch: `main`.
- URL: `https://guilledpn.github.io/KNwS7F_2a2LZ7MS/`
- Supabase project: `crm-ffvv-v2`.
- Supabase project id: `lijibbhpyyptodneafdd`.
- Supabase URL: `https://lijibbhpyyptodneafdd.supabase.co`.
- Datos: reales.
- Regla: no experimentar aquí.

### Desarrollo

- Uso: pruebas, desarrollo, QA y experimentación.
- Supabase project: `crm-ffvv-dev`.
- Supabase project id: `xcujixexjbuqqzlbomgw`.
- Supabase URL: `https://xcujixexjbuqqzlbomgw.supabase.co`.
- Región: `sa-east-1`.
- Costo informado por Supabase al crear: USD 0 mensual.
- Datos: ficticios/sanitizados.
- Estado inicial validado:
  - `contacts`: 160 filas.
  - `contact_month_state`: 439 filas.
  - `work_queue`: 111 filas.
  - `crm_log`: 4 filas.
  - período activo: `2026-07`.
- RPC validadas:
  - `get_contacts_v2` responde `ok=true`.
  - `get_stats_v1` responde `ok=true`.

## Regla central

La app DEV jamás debe apuntar a Supabase producción.

La app PROD jamás debe apuntar a Supabase DEV.

## Estado actual de implementación

Ya existe el backend DEV:

- tablas base;
- índices compactos;
- funciones/RPC principales;
- datos semilla ficticios;
- carga staging con `TRUNCATE` para limpieza;
- `work_queue` activa reconstruible;
- Stats básico compatible con la app actual.

Pendiente:

- publicar una URL web DEV separada.

El intento de crear automáticamente un bootstrap `/dev/index.html` fue bloqueado por controles del conector porque implicaba manejar una credencial pública de Supabase desde una página. La publishable/anon key pública del proyecto DEV debe configurarse de forma segura/manual en el frontend DEV.

## Próximo paso recomendado

Crear la app DEV web como copia controlada de `App_llamados_v1.05`, con estas diferencias visibles y obligatorias:

1. Supabase URL DEV:
   - `https://xcujixexjbuqqzlbomgw.supabase.co`
2. Publishable/anon key pública del proyecto DEV.
3. Banner visible:
   - `DEV · No productivo`
4. Versión visible en Ajustes:
   - `App_llamados_DEV_v1.05-base`
5. LocalStorage separado para configuraciones DEV.
6. Sin service worker propio hasta validar comportamiento.
7. No usar datos reales en DEV salvo muestra sanitizada explícitamente autorizada.

## Flujo futuro de trabajo

1. Se implementa mejora en DEV.
2. Se prueba en URL DEV.
3. Si funciona, se documenta.
4. Se crea PR hacia `main`.
5. Se valida checklist.
6. Recién entonces se promueve a producción.

## Checklist mínimo antes de promover desde DEV a PROD

- Login funciona.
- Contactos carga.
- Búsqueda funciona.
- Detalle abre.
- Guardar gestión funciona.
- Teléfono activo se guarda.
- Recordatorio se guarda.
- Stats carga.
- Sprint existe.
- Importar abre.
- Ajustes muestra versión/fecha.
- Mobile y escritorio revisados.
- Supabase PROD no fue tocado durante pruebas.

## Criterio de seguridad

No se debe publicar una preview visual que no sea funcional como si fuera QA real.

No se debe reemplazar producción por una recuperación, maqueta o app paralela.

No se deben usar claves privadas, service_role, JWT secret ni secretos de Supabase en frontend.
