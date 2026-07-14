# Inventario técnico actual del repositorio

- Fecha: 2026-07-13
- Estado: Pendiente de revisión
- LCD: LCD-20260713-02
- Issue: #10

## Propósito

Describir la estructura técnica existente antes de realizar cualquier movimiento físico hacia el monorepo objetivo.

Este inventario distingue tres niveles de certeza:

- **Verificado:** observado directamente en el repositorio, su documentación o sus workflows.
- **Inferido:** conclusión razonable que todavía requiere comprobación específica.
- **Pendiente:** información que aún debe auditarse.

## Resumen ejecutivo

El repositorio cumple actualmente cuatro funciones simultáneas:

1. fuente del frontend productivo de APP LLAMADOS;
2. destino de publicación de GitHub Pages;
3. espacio de construcción y publicación de una variante DEV aislada;
4. repositorio de migraciones, herramientas, diagnósticos y documentación.

Esta superposición explica por qué una reorganización directa de carpetas podría romper producción. La raíz del repositorio no es sólo código fuente: también es actualmente el artefacto publicado de PROD.

## Publicación y backend actuales

### GitHub Pages · Verificado

La documentación actual declara:

- rama de publicación: `main`;
- carpeta publicada: `/root`;
- URL esperada: `https://guilledpn.github.io/KNwS7F_2a2LZ7MS/`.

Consecuencia: mover `index.html`, `manifest.webmanifest`, `sw.js` o los íconos sin cambiar simultáneamente la estrategia de despliegue puede dejar PROD fuera de servicio.

### Supabase · Verificado

APP LLAMADOS utiliza Supabase para:

- autenticación;
- PostgreSQL;
- Row Level Security;
- RPC.

Los datos reales no viven en GitHub. El repositorio contiene frontend, migraciones, herramientas y referencias de configuración.

## Estructura superior observada

```text
KNwS7F_2a2LZ7MS/
├── .github/
├── assets/
├── dev/
├── diagnostics/
├── docs/
├── icons/
├── releases/
├── src/
├── supabase/
├── tools/
├── .nojekyll
├── AGENTS.md
├── PROJECT_MAP.md
├── README.md
├── index.html
├── manifest.webmanifest
├── rescate.html
├── reset.html
├── sprint.js
├── stats.html
└── sw.js
```

La lista corresponde a los elementos superiores observados y verificados durante el inventario. El contenido interno completo de algunas carpetas queda sujeto a auditoría detallada posterior.

## Clasificación por zona

### 1. Raíz productiva de APP LLAMADOS Legacy

| Elemento | Función actual | Estado | Criticidad |
|---|---|---|---|
| `index.html` | Aplicación productiva principal; combina UI y lógica legacy | Verificado | Crítica |
| `manifest.webmanifest` | Identidad e instalación de la PWA productiva | Verificado | Crítica |
| `sw.js` | Service worker productivo | Verificado | Crítica |
| `icons/` | Íconos de la PWA productiva | Verificado | Alta |
| `assets/` | Recursos estáticos productivos | Inferido; requiere detalle | Alta |
| `.nojekyll` | Control de publicación de GitHub Pages | Verificado visualmente | Media |
| `reset.html` | Herramienta o pantalla auxiliar | Verificado como archivo; función por auditar | Media |
| `rescate.html` | Herramienta o pantalla auxiliar | Verificado como archivo; función por auditar | Media |
| `stats.html` | Vista auxiliar de estadísticas | Verificado como archivo; función por auditar | Media |
| `sprint.js` | Lógica auxiliar legacy | Verificado como archivo; función por auditar | Media |

### 2. APP LLAMADOS DEV

| Elemento | Función actual | Estado | Criticidad |
|---|---|---|---|
| `dev/` | Artefacto DEV aislado y publicable | Verificado | Alta |
| `src/dev/` | Fuente modular utilizada para construir DEV | Verificado | Alta |
| `tools/build_dev_snapshot.py` | Genera `dev/index.html` desde el `index.html` productivo y copia módulos desde `src/dev/` | Verificado | Alta |
| `tools/enhance_dev_pwa_identity.py` | Diferencia visual y PWA de DEV | Verificado por workflow | Media |
| validadores `validate_dev_*` | Comprueban aislamiento y estructura del artefacto DEV | Verificado por workflow | Alta |

El build actual de DEV utiliza PROD como referencia visual y funcional, pero sustituye configuración, almacenamiento, autenticación y bootstrap PWA mediante módulos propios.

Dependencia actual relevante:

```text
index.html de PROD
        +
src/dev/
        +
herramientas Python
        ↓
dev/ generado
```

Por lo tanto, `dev/` no debe confundirse con la fuente canónica de una segunda aplicación completamente independiente. Hoy es un artefacto derivado durante una migración modular.

### 3. Automatización y workflows

#### `.github/workflows/build-dev-snapshot.yml` · Verificado

Responsabilidades actuales:

- construye el artefacto DEV;
- aplica parches de DEV;
- valida módulos, identidad y aislamiento;
- comprueba que el proceso no modifique PROD;
- genera diagnósticos;
- en `main`, puede confirmar automáticamente cambios generados dentro de `dev/`.

#### `.github/workflows/restore-prod-pwa.yml` · Verificado

Responsabilidades actuales:

- valida que PROD use el endpoint productivo;
- aplica un parche determinista a la PWA productiva;
- valida HTML, JavaScript, manifest, íconos y aislamiento;
- reconstruye DEV para detectar contaminación cruzada;
- restringe los archivos que puede modificar;
- en `main`, puede confirmar automáticamente cambios productivos.

### 4. Herramientas

`tools/` contiene scripts para:

- construir snapshots;
- aplicar parches;
- diferenciar ambientes;
- validar artefactos;
- proteger PROD y DEV.

Estado: existencia y varias funciones verificadas. Falta inventariar exhaustivamente cada script, su consumidor y si sigue vigente.

### 5. Base de datos

`supabase/` representa la infraestructura versionada de base de datos.

Elementos esperables y pendientes de auditoría detallada:

- migraciones;
- funciones;
- pruebas SQL;
- seeds o datos ficticios;
- configuración local.

Regla: el contenido de `supabase/` puede describir y transformar el esquema, pero no debe contener datos personales reales ni secretos.

### 6. Documentación

`docs/` contiene actualmente dos generaciones documentales:

- documentación operativa y diagnóstica previa;
- nueva documentación Docs-as-Code: ADR, arquitectura y aprendizaje.

Debe evitarse una reorganización masiva hasta identificar qué archivos son canónicos, históricos, evidencias o artefactos generados.

### 7. Diagnósticos y releases

| Carpeta | Interpretación actual | Estado |
|---|---|---|
| `diagnostics/` | Resultados o certificados generados por validaciones | Verificado parcialmente |
| `releases/` | Snapshots, respaldos o material de versiones | Pendiente de inventario detallado |

Los diagnósticos no deben convertirse en fuente de verdad del producto. Las releases deben distinguir entre artefactos históricos, respaldos y entregas oficiales.

## Hallazgos arquitectónicos

### H-01 · La raíz es simultáneamente fuente y artefacto productivo

Esto dificulta reorganizar carpetas y aumenta el riesgo de que una mejora estructural afecte el despliegue.

### H-02 · DEV se construye desde PROD

Es una estrategia segura para preservar comportamiento durante la modularización, pero todavía no representa la separación final Legacy/Next.

### H-03 · Los workflows escriben en el repositorio

Los workflows actuales no sólo validan: también pueden crear commits automáticos en `main`. Esto fue útil para construir y proteger snapshots, pero debe revisarse al adoptar GitHub Flow y una rama principal protegida.

### H-04 · `main` es código integrado y canal de publicación

Un merge documental puede activar workflows según sus filtros; un cambio productivo puede publicarse inmediatamente. Deben distinguirse integración, release y despliegue.

### H-05 · Existe modularización parcial, no arquitectura hexagonal completa

`src/dev/` ya separa configuración, errores, almacenamiento, cliente Supabase, autenticación y PWA. Es una base de transición valiosa, pero el dominio comercial continúa mayormente acoplado al HTML legacy.

## Riesgos actuales

| Riesgo | Probabilidad | Impacto | Control inmediato |
|---|---:|---:|---|
| Mover archivos raíz y romper GitHub Pages | Alta | Crítico | No mover durante este LCD |
| Confundir `dev/` generado con fuente canónica | Media | Alto | Documentar origen y build |
| Workflows que escriben en `main` durante una reorganización | Media | Alto | Auditar triggers antes de mover |
| Mezclar APP LLAMADOS Next con DEV legacy | Alta | Alto | Usar nombres de producto explícitos |
| Duplicar fuentes entre raíz, `dev/` y `src/dev/` | Alta | Medio | Definir fuente y artefacto por archivo |
| Conservar herramientas obsoletas indefinidamente | Media | Medio | Clasificar vigencia y consumidores |
| Versionar accidentalmente secretos o datos | Baja, con alto impacto | Crítico | Mantener prohibiciones y auditar `.gitignore` |

## Información pendiente de verificar

1. listado exhaustivo de archivos dentro de `assets/`, `releases/`, `supabase/`, `tools/` y documentación histórica;
2. configuración exacta de GitHub Pages y dominios asociados;
3. reglas de protección de `main`;
4. todos los workflows y sus permisos;
5. forma exacta en que se publica y accede a `dev/`;
6. existencia real de STAGING;
7. relación entre migraciones SQL y los proyectos Supabase DEV/PROD;
8. política actual de backups y restauración;
9. artefactos que pueden eliminarse, archivarse o regenerarse.

## Conclusión

La estructura actual contiene mecanismos útiles de aislamiento y validación, pero está organizada alrededor de la publicación directa de APP LLAMADOS desde la raíz. La transición al monorepo debe preservar esa compatibilidad hasta que exista un despliegue alternativo probado.
