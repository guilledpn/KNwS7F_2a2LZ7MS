# AGENTS.md · Reglas de trabajo del CRM Patrimonial

Estado: Vigente  
Último LCD aprobado: LCD-20260801-01  
Gobernanza documental: ADR-023  
Reconciliación: Issue #28

## Propósito

Este archivo orienta a cualquier asistente de IA o colaborador que trabaje en el repositorio. No reemplaza la Constitución, la Arquitectura ni el Modelo del Dominio.

## Jerarquía documental

1. Constitución.
2. Arquitectura.
3. Modelo del Dominio.
4. Backlog y Roadmap.
5. Bitácora Arquitectónica y ADR.
6. Instrucciones operativas.

La ubicación técnica de un documento no altera su jerarquía semántica.

## Flujo obligatorio

Descubrir → Validar → Documentar → Diseñar → Implementar.

Antes de modificar código:

1. comprender el problema de negocio;
2. identificar conceptos o reglas afectados;
3. determinar qué documentos canónicos deben cambiar;
4. registrar la decisión cuando corresponda;
5. diseñar el cambio;
6. implementar y probar.

## Identificadores y control documental

Antes de crear una rama, documento, ADR o lote:

1. revisar `docs/governance/lcd-registry.md`;
2. revisar `docs/governance/adr-registry.md` cuando exista una decisión;
3. reservar el identificador único en la rama del lote;
4. verificar que no exista con otro significado en Drive ni GitHub;
5. usar el mismo identificador en todos los artefactos del cambio.

Nunca se inventa un LCD o ADR desde una conversación, un archivo aislado o el número de un Pull Request. Un identificador reservado no se reutiliza.

Una colisión o divergencia documental bloquea el trabajo dependiente hasta ser reconciliada.

## Autoridad documental

Gobiernan:

- `docs/governance/document-authority.md`;
- `docs/governance/document-catalog.md`;
- `docs/governance/lcd-registry.md`;
- `docs/governance/adr-registry.md`.

Reglas:

- cada artefacto tiene una sola ubicación editable canónica;
- GitHub es canónico para conocimiento propio versionable, ingeniería, código, migraciones, pruebas y registros maestros;
- Drive es canónico para fuentes originales, bases de campaña, evidencia externa, archivos sensibles y material no apto para Git;
- los documentos superiores que todavía viven en Drive mantienen autoridad hasta completar su migración validada;
- no se mantienen copias editables paralelas;
- una exportación o copia no cambia por sí sola la autoridad.

## Estrategia del producto

- El repositorio evolucionará como monorepo.
- APP LLAMADOS se mantiene como aplicación Legacy operativa.
- CRM Patrimonial Next se desarrolla como nueva generación.
- La transición se realizará gradualmente mediante Strangler Fig Pattern.
- La arquitectura objetivo es DDD + arquitectura hexagonal + monolito modular.

Decisiones canónicas: ADR-021 y ADR-022. Los archivos históricos nombrados ADR-018 y ADR-019 son sólo aliases de compatibilidad.

## Reglas Git

- `main` debe permanecer estable y revisable.
- No experimentar directamente en `main`.
- Cada cambio comienza en un Issue y una rama breve.
- Usar Conventional Commits.
- Abrir Pull Request antes de fusionar.
- El merge autorizado representa la aprobación técnica del lote.
- Un commit registra cambios; no equivale por sí solo a aprobación.
- No reescribir historia publicada para corregir referencias: usar aliases y registros explícitos.

## Seguridad y ambientes

- PROD contiene datos reales y no se usa para experimentar.
- DEV nunca apunta a PROD y PROD nunca apunta a DEV.
- No usar `service_role`, JWT Secret ni claves privadas en código o documentación.
- No almacenar datos reales de clientes, bases de campaña ni información patrimonial sensible en Git.
- El repositorio es público mientras no se apruebe otra decisión; todo contenido debe ser publicable.
- Toda operación destructiva o promoción requiere autorización explícita.

## Dependencias arquitectónicas

El dominio no debe depender de UI, Supabase, PostgreSQL, APIs externas ni detalles de infraestructura.

Las dependencias deben apuntar hacia adentro:

Adaptadores → Aplicación → Dominio.

Si el dominio necesita acceso externo, debe expresarlo mediante un puerto.

## Calidad

- Todo bug corregido debe considerar una prueba de regresión o caracterización.
- Toda regla de dominio nueva debe contar con pruebas de comportamiento.
- Toda promoción debe incluir validación y smoke test.
- La interfaz no debe ser la única autoridad de una regla crítica.
- Todo lote documental debe comprobar unicidad de identificadores y ausencia de duplicados canónicos.

## Aprendizaje

Durante el trabajo se enseñarán y registrarán competencias en cinco niveles:

1. Git y repositorio.
2. Colaboración y gestión.
3. Desarrollo y calidad.
4. Arquitectura y dominio.
5. Operación.

La matriz se actualiza por evidencia práctica, no sólo por exposición teórica.
