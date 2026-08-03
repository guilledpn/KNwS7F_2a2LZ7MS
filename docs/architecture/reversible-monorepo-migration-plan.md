# Plan reversible de migración al monorepo

- Fecha original: 2026-07-13
- Estado: Vigente
- LCD de origen canónico: LCD-20260713-04
- Alias histórico en GitHub: LCD-20260713-02
- Actualizaciones: LCD-20260714-01, LCD-20260714-02 y LCD-20260801-01
- Issue original: #10
- Aprobación: Pull Request #11

## Propósito

Transformar gradualmente el repositorio actual en un monorepo profesional sin interrumpir APP LLAMADOS PROD ni mezclar su mantenimiento con el desarrollo de CRM Patrimonial Next.

## Regla rectora

Ninguna mejora estructural justifica comprometer continuidad operativa.

Cada etapa debe cumplir:

1. alcance limitado;
2. pruebas previas;
3. diff revisable;
4. despliegue controlado;
5. smoke test;
6. rollback explícito;
7. trazabilidad mediante Issue, rama, Pull Request y merge.

Desde LCD-20260801-01, todo lote debe además reservar su LCD/ADR en los registros canónicos y comprobar que cada artefacto posee una sola ubicación editable canónica.

## Estado cero

Antes de mover archivos:

- PROD se publica desde `main:/root`;
- la raíz contiene la PWA productiva;
- `dev/` es un artefacto derivado;
- `src/dev/` contiene modularización parcial;
- workflows pueden escribir commits automáticos;
- no existe todavía CRM Patrimonial Next como aplicación.

## Etapa 0 · Documentar y congelar supuestos

### Objetivo

Comprender estructura, despliegues y dependencias.

### Acciones

- completar inventario;
- registrar matriz Producto × Ambiente × Despliegue;
- identificar archivos críticos;
- documentar estructura objetivo;
- listar información pendiente.

### Validación

- Pull Request documental;
- cero cambios en aplicación o workflows productivos;
- cero cambios en Supabase.

### Rollback

Revertir el merge documental si la decisión no representa lo aprobado.

### Estado

Completada mediante LCD-20260713-04 y Pull Request #11. El cierre formal quedó registrado en LCD-20260714-01 y Pull Request #15.

## Etapa 1 · Proteger el comportamiento actual

### Objetivo

Crear una red de seguridad antes de reorganizar.

### Acciones

- seleccionar flujos críticos de APP LLAMADOS;
- crear pruebas de caracterización;
- documentar smoke tests repetibles;
- registrar archivos productivos esperados;
- auditar `.gitignore` y ausencia de secretos;
- identificar qué workflows modifican `main`.

### Pruebas mínimas

- carga de la PWA;
- autenticación DEV con datos ficticios;
- búsqueda y carga de contactos;
- cálculo de gestionabilidad;
- tareas y estados principales;
- aislamiento de endpoints DEV/PROD;
- instalación PWA.

### Validación

Las pruebas deben pasar sin cambiar comportamiento funcional.

### Rollback

Eliminar únicamente las pruebas o configuraciones agregadas mediante revert del PR.

### Estado

Etapa 1A completada mediante LCD-20260714-02 y Pull Request #18. Existe red mínima de caracterización, validador estructural de PROD de sólo lectura y runner de seguridad Legacy.

## Etapa 2 · Clasificar fuente y artefacto

### Objetivo

Determinar qué archivos son editables y cuáles deben generarse.

### Acciones

Para cada archivo relevante, registrar:

- propietario;
- fuente canónica;
- proceso de construcción;
- artefacto resultante;
- consumidor;
- ambiente;
- posibilidad de regeneración.

### Decisión documental incorporada

ADR-023, ADR-026 y `docs/governance/document-authority.md` clasifican la autoridad documental. Continúa pendiente clasificar exhaustivamente artefactos ejecutables, diagnósticos y releases.

### Decisión esperada

Definir si `dev/`, diagnósticos y releases deben:

- permanecer versionados;
- convertirse en artefactos de Actions;
- publicarse en una rama de despliegue;
- archivarse como Releases.

### Rollback

No se mueve nada durante esta etapa; sólo se registra clasificación.

## Etapa 3 · Crear el esqueleto del monorepo sin mover PROD

### Objetivo

Introducir las nuevas fronteras sin alterar rutas productivas.

### Acciones

- crear `apps/app-llamados/README.md`;
- crear `apps/crm-patrimonial/README.md`;
- crear `packages/README.md`;
- organizar documentación nueva;
- agregar plantillas de Issues y Pull Requests;
- mantener raíz, `dev/`, workflows productivos y Supabase intactos.

### Validación

- GitHub Pages continúa funcionando;
- workflows actuales pasan;
- no cambia el contenido productivo.

### Rollback

Revertir el PR; las carpetas nuevas no son consumidas por producción.

## Etapa 4 · Encapsular APP LLAMADOS Legacy

### Objetivo

Establecer una fuente propia del Legacy sin dejar de publicar en la raíz.

### Estrategia

Aplicar primero un modelo de copia controlada:

```text
apps/app-llamados/src
        ↓ build validado
raíz productiva compatible
```

### Acciones

- copiar, no mover, fuentes productivas a la nueva zona;
- crear build determinista;
- comparar resultado con PROD actual;
- probar en DEV;
- mantener temporalmente la raíz como destino de publicación;
- prohibir ediciones manuales divergentes.

### Condición de aprobación

El build debe generar un artefacto funcionalmente equivalente y pasar pruebas de caracterización.

### Rollback

- restaurar edición directa de la raíz desde el commit estable anterior;
- desactivar el nuevo build;
- no modificar backend.

## Etapa 5 · Normalizar automatización y ramas

### Objetivo

Separar validación, integración, release y despliegue.

### Acciones

- impedir que verificaciones ordinarias creen commits inesperados en `main`;
- usar workflows de validación en Pull Requests;
- publicar artefactos mediante un proceso explícito;
- evaluar rama `gh-pages` o GitHub Pages Actions;
- proteger `main` cuando el flujo esté probado;
- exigir checks antes de merge.

### Avance

El workflow `document-governance.yml` ya valida documentación con permisos `contents: read` y sin publicar ni confirmar cambios. No resuelve todavía los workflows históricos que pueden escribir artefactos.

### Validación

- un PR documental no modifica artefactos;
- un PR de aplicación ejecuta pruebas sin publicar PROD;
- sólo una promoción autorizada despliega.

### Rollback

Restaurar workflows anteriores desde el tag estable y revalidar PROD.

## Etapa 6 · Crear CRM Patrimonial Next en DEV

### Objetivo

Construir la primera aplicación nueva sin acoplarla al Legacy.

### Acciones

- crear estructura mínima en `apps/crm-patrimonial/`;
- validar contextos delimitados iniciales;
- implementar una vertical hexagonal pequeña;
- utilizar datos ficticios;
- crear puertos y adaptadores mínimos;
- no reutilizar tablas o reglas sólo por conveniencia.

### Estado previo

Existe un laboratorio PostgreSQL local y versiones experimentales del modelo físico. Es evidencia de aprendizaje y validación, no una aplicación Next ni un ambiente DEV remoto.

### Primera vertical candidata

`EvaluarGestionabilidad`, porque:

- es una regla conocida;
- conecta Persona, Campaña y Gestión Operativa;
- permite pruebas de dominio;
- no requiere perfil patrimonial sensible;
- facilita comparar Legacy y Next.

La vertical exacta debe revisarse después de cerrar el modelo conceptual mínimo; no se implementa sólo por figurar como candidata histórica.

### Validación

- pruebas unitarias y de aplicación;
- adaptador falso;
- adaptador DEV;
- comparación con casos conocidos del Legacy.

### Rollback

Eliminar el módulo experimental sin afectar APP LLAMADOS.

## Etapa 7 · Sustitución gradual mediante Strangler Fig

### Objetivo

Transferir capacidades desde el Legacy hacia Next de una en una.

### Ciclo por capacidad

1. seleccionar comportamiento;
2. caracterizar Legacy;
3. modelar dominio;
4. implementar en Next;
5. ejecutar en paralelo;
6. comparar resultados;
7. redirigir tráfico o uso;
8. observar;
9. retirar código antiguo sólo después de estabilidad.

### Orden tentativo

1. importación y conciliación;
2. identidad y datos de contacto;
3. gestionabilidad y cola;
4. actividades y tareas;
5. relación comercial;
6. casos y oportunidades;
7. catálogo y productos contratados;
8. perfil patrimonial;
9. proyección y analítica.

Este orden es tentativo y no gobierna el descubrimiento del dominio.

### Rollback

Cada capacidad conserva temporalmente el camino Legacy hasta superar un período definido de estabilidad.

## Etapa 8 · Desacoplar la raíz del producto

### Objetivo

Lograr que la raíz del repositorio deje de ser fuente manual y artefacto productivo simultáneamente.

### Condiciones previas

- build reproducible;
- despliegue alternativo probado;
- pruebas y smoke test automatizados;
- rollback demostrado;
- backups verificados;
- URLs y PWA validadas;
- aprobación explícita.

### Acciones posibles

- desplegar mediante GitHub Pages Actions;
- publicar desde una rama dedicada;
- usar artefactos construidos;
- mantener rutas compatibles o redirecciones.

### Rollback

Volver al tag productivo anterior y restaurar configuración `main:/root`.

## Etapa 9 · Limpieza y cierre

### Acciones

- retirar duplicados sólo cuando no tengan consumidores;
- archivar herramientas obsoletas;
- limpiar diagnósticos regenerables;
- documentar rutas definitivas;
- actualizar README, PROJECT_MAP y ADR;
- comprobar que Drive y Git no mantienen dos copias canónicas editables.

## Controles transversales

### Gobernanza documental

- reservar LCD y ADR antes de crear artefactos;
- mantener registros únicos en GitHub;
- actualizar el catálogo cuando cambia autoridad;
- bloquear el merge si el validador detecta colisiones;
- conservar Drive para fuentes y evidencia no aptas para Git.

### Seguridad

- ningún secreto en Git;
- ningún dato real en DEV;
- ninguna migración DEV contra PROD;
- revisión de RLS antes de datos patrimoniales.

### Base de datos

- migraciones hacia adelante y rollback cuando sea viable;
- snapshots antes de cambios estructurales;
- seeds ficticios;
- prueba de restauración;
- separación explícita de proyectos.

### Operación

- tag previo a promociones relevantes;
- checklist de release;
- smoke test;
- registro de incidente;
- métricas de salud.

## Criterio de detención

La migración se detiene inmediatamente si:

- no puede identificarse la fuente canónica;
- un workflow modifica archivos inesperados;
- DEV apunta a PROD;
- una prueba de caracterización falla sin explicación;
- el rollback no está disponible;
- cambia una regla de negocio no documentada;
- aparece una inconsistencia entre repositorio, documentos canónicos y operación real;
- existe una colisión no resuelta de LCD o ADR.

## Próxima decisión

Continuar el descubrimiento y validación del modelo conceptual de Next antes de crear su esqueleto ejecutable. Ningún movimiento físico se autoriza por esta actualización documental.

## Nota histórica

Este plan fue aprobado originalmente en el Pull Request #11 bajo el identificador conflictivo `LCD-20260713-02`. La reconciliación conserva su contenido y aprobación, pero fija `LCD-20260713-04` como lote de origen canónico.
