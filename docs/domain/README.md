# Modelo del Dominio del CRM Patrimonial

- Estado: Vigente
- Versión: 2.0
- Última actualización: 2026-08-03
- LCD: LCD-20260803-01

El Modelo del Dominio gobierna el conocimiento del negocio. Cada concepto debe tener un lugar principal y los documentos especializados deben enlazarse, no copiarse entre sí.

## Documentos

| Documento | Uso |
|---|---|
| `dictionary.md` | Lenguaje oficial y definiciones breves |
| `commercial-model.md` | Persona, campañas, relación, trabajo y desarrollo comercial |
| `operational-model.md` | Importaciones, ejecuciones, validación, idempotencia, linaje y conciliación |
| `patrimonial-model.md` | Estrategias, vehículos, portafolios, patrimonio y evolución |
| `product-model.md` | Conceptos transversales de producto y relación con fuentes externas |
| `validation-matrix-next-v03.md` | Criterios verificables antes del diseño físico de Next |

## Reglas de separación

- El Diccionario define; no desarrolla procesos completos.
- Los modelos describen reglas e invariantes; no especifican tablas ni UI.
- La Matriz convierte reglas aprobadas en criterios y escenarios verificables.
- Las ADR justifican decisiones; no reemplazan el estado vigente de los modelos.
- El Roadmap prioriza trabajo; no redefine el dominio.
- Las fuentes de productos en Drive prueban o cuestionan reglas, pero no son el modelo canónico.

## Autoridad

Todos los documentos propios del Modelo del Dominio viven únicamente en GitHub. Drive conserva las bases, fichas, manuales, PDFs y la matriz operativa de Productos Consorcio porque son fuentes corporativas, de terceros o material no apto para un repositorio público.

Si una fuente contradice el modelo, se abre un LCD para validar y documentar el cambio. No se edita una copia paralela en Drive.
