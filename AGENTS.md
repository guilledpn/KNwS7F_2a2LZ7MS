# AGENTS.md · Reglas de trabajo del CRM Patrimonial

- Estado: Vigente
- Último LCD aprobado: LCD-20260804-04
- Gobernanza documental: ADR-023 y ADR-026
- Última conciliación: 2026-08-04

## Propósito

Este archivo orienta a agentes y colaboradores. No reemplaza la Constitución, la Arquitectura, el Modelo del Dominio ni los Estándares de Desarrollo.

## Lectura obligatoria

Antes de trabajar, consultar desde `main`:

1. `docs/governance/document-authority.md`;
2. `docs/project/constitution.md`;
3. `docs/architecture/crm-patrimonial.md`;
4. `docs/domain/README.md`;
5. `docs/project/backlog-roadmap.md`;
6. `docs/engineering/development-standards.md` para código, SQL, pruebas o configuración;
7. los documentos especializados del alcance.

Las instrucciones de ChatGPT son una puerta de entrada. La autoridad vive en el repositorio.

Si falta una fuente obligatoria o existe una divergencia, detener sólo el trabajo dependiente y advertirla.

## Jerarquía

1. Constitución.
2. Arquitectura.
3. Modelo del Dominio.
4. Backlog y Roadmap.
5. ADR, LCD y registros.
6. Estándares, procedimientos e instrucciones.

La ubicación técnica no altera la jerarquía semántica.

## Flujo

Descubrir → Validar → Documentar → Diseñar → Implementar → Verificar → Promover.

Antes de modificar:

- comprender causa y alcance;
- identificar conceptos, contratos y ambientes;
- buscar solución canónica;
- determinar Issue, LCD, ADR y documentos;
- diseñar el mínimo cambio completo y correcto;
- implementar, probar y dejar trazabilidad.

En una emergencia productiva se puede restaurar primero la continuidad mediante el cambio seguro más pequeño. La documentación y el cierre siguen siendo obligatorios.

## Evidencia e incertidumbre

No asumir archivos, funciones, tablas, contratos, dependencias o ambientes no comprobados.

Primero buscar evidencia en documentos canónicos, repositorio, pruebas, migraciones e historial. Si persiste la incertidumbre:

- declararla;
- detener sólo el trabajo dependiente;
- no inventar ni simular la pieza desconocida;
- continuar con partes independientes cuando sea seguro;
- solicitar información sólo si no puede obtenerse de las fuentes disponibles.

Toda inferencia debe identificarse como tal.

## Autoridad documental

Gobiernan:

- `docs/governance/document-authority.md`;
- `docs/governance/lcd-registry.md`;
- `docs/governance/adr-registry.md`.

GitHub es canónico para conocimiento propio versionable, código, migraciones, pruebas y herramientas.

Drive es canónico para datos reales, PII, fuentes externas o corporativas, respaldos y evidencia no publicable.

Cada artefacto tiene una única ubicación editable canónica. Una copia operativa puede existir si identifica su fuente y no evoluciona como autoridad paralela.

No eliminar herramientas operativas antes de comprobar uso, equivalencia y reemplazo.

## Producto y arquitectura

- APP LLAMADOS Legacy permanece operativo y se protege con parches pequeños, caracterización, regresión y smoke tests.
- CRM Patrimonial Next evoluciona gradualmente mediante monorepo y Strangler Fig.
- Arquitectura objetivo: DDD, arquitectura hexagonal y monolito modular.
- Dependencias: Adaptadores → Aplicación → Dominio.
- El dominio no depende de UI, Supabase, PostgreSQL ni APIs externas.

No crear tablas, estados, procesos o pantallas que no representen conceptos reales.

Las entidades almacenan hechos. Colas, dashboards, estadísticas y proyecciones son derivados.

Antes de mover, eliminar o reutilizar archivos, clasificar con evidencia si pertenecen a Legacy, fuente transitoria, artefacto generado, infraestructura compartida o Next. Consultar el inventario actual, la matriz producto/ambiente, la estructura objetivo y el procedimiento de build aplicable. Una ruta objetivo no se presume implementada.

## Calidad

Cumplir `docs/engineering/development-standards.md`.

Reglas no negociables:

- no refactorizar ampliamente como efecto secundario de un fix;
- no cambiar contratos o comportamiento sin declarar impacto;
- no crear implementaciones paralelas sin revisar la solución canónica;
- no duplicar reglas semánticas;
- no introducir deuda técnica silenciosa;
- no ocultar errores con tipos amplios, supresiones, casts o fallbacks;
- todo bug debe considerar regresión o caracterización;
- toda regla de dominio nueva debe tener pruebas de comportamiento;
- todo control omitido se informa como `No aplica` con motivo;
- no declarar `PASS` sin evidencia.

Para Supabase, toda modificación de tablas, vistas, funciones, políticas o permisos debe revisar RLS, `GRANT`, exposición mediante Data API y acceso permitido/denegado.

## Git

- `main` permanece estable.
- No experimentar directamente en `main`.
- Cada cambio comienza en Issue y rama breve, salvo auditoría de sólo lectura.
- Usar Conventional Commits.
- Los commits deben representar unidades lógicas; consolidar ruido `WIP` o `fixup` antes del merge.
- El PR debe ser completo y directo, sin narrar cada intento ni repetir el diff.
- Abrir Pull Request antes de fusionar.
- Un commit no equivale por sí solo a aprobación.
- No reescribir historia publicada para ocultar errores.

## Seguridad y ambientes

- LOCAL/DEV: datos ficticios o sanitizados.
- STAGING: candidato validado en DEV.
- PROD: datos reales; nunca experimentar.
- Una autorización para DEV no autoriza STAGING ni PROD.
- Toda operación destructiva o promoción requiere autorización explícita.
- No usar `service_role`, secretos JWT ni claves privadas.
- No almacenar PII, bases reales ni información patrimonial sensible en Git.
- Tratar el repositorio como público.

Antes de PROD: estado estable, autorización, diff, rollback, cambio mínimo, validación, smoke test y trazabilidad.

## Control documental

Antes de crear LCD o ADR, revisar sus registros y reservar el identificador libre.

Una conversación descubre; los documentos conservan las decisiones aprobadas.

## Cierre

Informar:

- qué cambió y qué no;
- qué se validó y qué no;
- ambientes afectados;
- evidencia;
- riesgos, limitaciones y pendientes.

Verificar si cambiaron Constitución, Arquitectura, Dominio, Roadmap, ADR, LCD, registros, `PROJECT_MAP.md`, `AGENTS.md`, contratos o deuda técnica.
