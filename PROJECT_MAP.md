# PROJECT_MAP.md · Mapa del Proyecto CRM Patrimonial

Estado: pendiente de revisión  
LCD: LCD-20260713-01

## Propósito

Entregar una vista breve y actualizada del proyecto, sus productos, ambientes, documentos y dirección arquitectónica.

## Producto conceptual

CRM Patrimonial.

## Productos operativos

### APP LLAMADOS · Legacy

Aplicación productiva actual. Debe mantenerse estable mientras se corrigen bugs y se incorporan mejoras acotadas.

### CRM Patrimonial Next

Nueva generación en descubrimiento, documentación y diseño. Se construirá progresivamente sin imponer su arquitectura sobre el legacy mediante una reescritura abrupta.

## Diferencias esenciales

- **Producto:** APP LLAMADOS Legacy o CRM Patrimonial Next.
- **Ambiente:** DEV, STAGING o PROD.
- **Versión:** identificación concreta de una entrega, por ejemplo `1.6.2` o `0.1.0-alpha.1`.

Cada producto puede tener sus propios ambientes y versiones.

## Estrategia técnica aprobada

- Monorepo.
- DDD estratégico y táctico.
- Arquitectura hexagonal.
- Monolito modular.
- Strangler Fig Pattern para la transición.
- GitHub Flow con ramas breves y Pull Requests.
- Conventional Commits y Semantic Versioning.
- Docs-as-Code para ingeniería.

## Contextos de dominio candidatos

1. Identidad y Contactabilidad.
2. Adquisición y Campañas.
3. Gestión Operativa.
4. Gestión Comercial.
5. Catálogo de Productos.
6. Productos Contratados y Postventa.
7. Patrimonio e Inversiones.
8. Proyección y Analítica.

Estos contextos están pendientes de validación formal antes del diseño físico.

## Repositorios de conocimiento

### GitHub · Repositorio canónico de ingeniería

Contendrá progresivamente:

- código;
- migraciones;
- documentación canónica en Markdown;
- ADR;
- diagramas Mermaid;
- pruebas;
- Issues, Pull Requests y Releases.

### Google Drive · Repositorio de fuentes y evidencias

Mantendrá:

- manuales y folletos;
- PDFs corporativos;
- fuentes regulatorias;
- archivos de trabajo no adecuados para Git;
- evidencias y respaldos documentales.

No se mantendrán dos copias editables del mismo documento canónico.

## Estructura objetivo tentativa

```text
KNwS7F_2a2LZ7MS/
├── apps/
│   ├── app-llamados/
│   └── crm-patrimonial/
├── packages/
├── docs/
│   ├── governance/
│   ├── domain/
│   ├── architecture/
│   ├── adr/
│   ├── operations/
│   └── learning/
├── supabase/
├── tools/
└── .github/
```

Esta estructura es un destino. No se moverán archivos productivos hasta completar inventario, pruebas y plan de transición.

## Flujo de trabajo

Issue → Rama → Commits → Pull Request → Pruebas → Revisión → Merge → Release → Despliegue.

## Primer lote

LCD-20260713-01:

- establecer gobernanza del monorepo;
- crear reglas para agentes;
- crear mapa del proyecto;
- registrar ADR principales;
- crear programa de aprendizaje;
- no mover ni alterar todavía la aplicación productiva.
