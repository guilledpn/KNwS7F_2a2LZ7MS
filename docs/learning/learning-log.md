# Bitácora de aprendizaje

## 2026-07-13 · Inicio del método profesional de trabajo

### Contexto

Se aprobó evolucionar el repositorio hacia un monorepo que mantenga APP LLAMADOS Legacy y permita construir CRM Patrimonial Next mediante DDD, arquitectura hexagonal y monolito modular.

### Conceptos introducidos

- monorepo;
- GitHub Flow;
- Issue;
- rama de trabajo;
- Conventional Commits;
- Pull Request;
- Docs-as-Code;
- ADR;
- Strangler Fig Pattern;
- matriz de competencias;
- aprendizaje basado en evidencias.

### Primera práctica real

- Se creó el Issue #7 para representar el trabajo.
- Se creó la rama `docs/lcd-20260713-01-monorepo-governance` desde `main`.
- Los documentos del lote se están creando en la rama, sin modificar directamente `main`.
- Cada archivo se registra mediante commits con nomenclatura Conventional Commits.

### Distinciones importantes

- Un repositorio no es lo mismo que una aplicación.
- Un producto no es lo mismo que un ambiente.
- Una rama no es un ambiente DEV.
- Un commit registra cambios, pero no los aprueba.
- Un Pull Request propone integración y permite revisar el lote.
- El merge incorpora el lote aprobado a `main`.

### Estado de aprendizaje

El flujo completo todavía no está demostrado, porque falta revisar el Pull Request y decidir su aprobación o correcciones.

### Próxima práctica

Abrir y revisar el Pull Request del LCD-20260713-01, inspeccionando:

1. el propósito del Issue;
2. los commits de la rama;
3. el diff de cada archivo;
4. los criterios de aceptación;
5. la diferencia entre comentar, aprobar y hacer merge.
