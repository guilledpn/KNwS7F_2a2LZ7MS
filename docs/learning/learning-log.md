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
- Los documentos se crearon en la rama, sin modificar directamente `main`.
- Cada archivo se registró mediante commits con nomenclatura Conventional Commits.
- Se abrió el Pull Request #9 como Draft.
- Se revisaron los siete commits y el diff acumulado contra `main`.
- Se comprobó que sólo se agregaban siete archivos documentales.
- Se ejecutó un review de prueba.
- Se realizó `Squash and merge` hacia `main`.
- Se sincronizó la copia local y se comprobó el commit integrado.

### Distinciones aprendidas

- Un repositorio no es lo mismo que una aplicación.
- Un producto no es lo mismo que un ambiente.
- Una rama no es un ambiente DEV.
- Un commit registra cambios, pero no los aprueba.
- Un Pull Request propone integración y permite revisar el lote.
- Un diff muestra diferencias entre estados.
- `CHANGES` vacío indica que no existen modificaciones locales pendientes.
- Draft significa que un PR todavía está en preparación.
- Ready for review significa que está listo para decisión.
- Review y merge son acciones diferentes.
- El merge incorpora el lote aprobado a `main`.
- Eliminar la rama después del merge no elimina los cambios integrados.

### Evidencia obtenida

Cadena completada:

```text
LCD-20260713-01
→ Issue #7
→ rama de trabajo
→ 7 commits
→ Pull Request #9
→ review
→ merge
→ main
```

### Dificultades observadas

- localizar la comparación de ramas en VS Code;
- diferenciar el diff de un commit del diff acumulado del Pull Request;
- reconocer qué acciones pertenecen a GitHub Desktop y cuáles a GitHub web.

### Estado

Primera práctica profesional completada con acompañamiento. Las competencias Rama, Diff, Pull Request, Review y Merge pasan a estado Guiado.

---

## 2026-07-13 · Segundo lote: inventario y transición reversible

### Contexto

Después de aprobar el monorepo, se inicia un lote documental para comprender la estructura real antes de mover archivos productivos.

### Trazabilidad

- LCD: `LCD-20260713-02`
- Issue: #10
- Rama: `docs/lcd-20260713-02-repository-inventory`

### Conceptos trabajados

- inventario técnico;
- fuente frente a artefacto;
- producto frente a ambiente;
- versión frente a despliegue;
- criticidad de archivos;
- dependencia de GitHub Pages respecto de la raíz;
- CI frente a CD;
- plan de migración reversible;
- rollback por etapas;
- pruebas de caracterización;
- estructura objetivo de monorepo.

### Hallazgos pedagógicos iniciales

- La raíz del repositorio es actualmente fuente y artefacto productivo.
- `dev/` es un artefacto generado; `src/dev/` contiene parte de sus fuentes modulares.
- Los workflows actuales pueden crear commits automáticos en `main`.
- Integrar código, crear una release y desplegar PROD son actividades que deben distinguirse.
- Una estructura futura no debe aplicarse sólo porque sea visualmente más ordenada.

### Documentos preparados

- `docs/architecture/current-repository-inventory.md`
- `docs/architecture/product-environment-deployment-matrix.md`
- `docs/architecture/target-monorepo-structure.md`
- `docs/architecture/reversible-monorepo-migration-plan.md`

### Próxima práctica

1. sincronizar y abrir la rama del segundo lote;
2. revisar los cuatro documentos;
3. distinguir hechos verificados, inferencias y pendientes;
4. validar la matriz Producto × Ambiente × Despliegue;
5. comentar o solicitar cambios en el Pull Request;
6. decidir si el plan está listo para merge.
