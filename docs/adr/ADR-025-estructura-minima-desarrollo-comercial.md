# ADR-025 · Estructura mínima del desarrollo comercial

- Fecha: 2026-08-02
- Estado: <span style="color:red">Borrador · pendiente de revisión</span>
- LCD: LCD-20260802-01
- Issue: #34

## Contexto

ADR-024 estableció que el esquema físico `next_v03` no puede congelarse antes de definir el modelo mínimo de desarrollo comercial.

El Modelo Comercial aprobado ya contiene Persona, Relación Comercial, Tarea y Actividad, pero todavía no fija las fronteras, cardinalidades ni ciclos de vida de:

- Caso Comercial;
- Oportunidad;
- Propuesta;
- Pipeline.

Tampoco determina hasta qué nivel una Tarea o Actividad puede vincularse opcionalmente con esos conceptos sin perder su vínculo principal con las Personas involucradas y el Asesor responsable o ejecutor.

## Decisión pendiente

Este ADR se encuentra reservado. La decisión se construirá mediante descubrimiento y validación explícita durante LCD-20260802-01.

La hipótesis estructural inicial, aún no aprobada, es:

```text
Persona
└── Relación Comercial
    └── Caso Comercial
        └── Oportunidad
            ├── Pipeline
            └── Propuestas
```

Esta representación no fija todavía cardinalidades definitivas ni afirma que todos los conceptos deban existir siempre.

## Preguntas que debe resolver el lote

1. Qué hecho del negocio da origen a un Caso Comercial.
2. Si un Caso puede existir antes de identificar una Oportunidad.
3. Qué agrupa un Caso y qué lo diferencia de una Relación Comercial.
4. Si la Oportunidad representa siempre una contratación potencial individualizable por producto.
5. Si varias Oportunidades pueden coexistir dentro de un Caso.
6. Si una Propuesta pertenece siempre a una única Oportunidad y si conserva versiones o alternativas.
7. Qué concepto recorre realmente el Pipeline.
8. Qué estados son hechos persistentes y cuáles son vistas derivadas.
9. Cómo se cierran, descartan, reemplazan o reabren Casos y Oportunidades sin borrar historia.
10. Cómo se vinculan opcionalmente Tareas y Actividades con Relación Comercial, Caso Comercial y Oportunidad.

## Límites del lote

No se decidirán todavía:

- nombres físicos de tablas o columnas;
- SQL;
- UX detallada;
- colores;
- dashboards;
- automatizaciones;
- probabilidades definitivas;
- reglas particulares de cada producto;
- cambios en APP LLAMADOS Legacy, DEV, STAGING o PROD.

## Consecuencias actuales

- `next_v03` continúa bloqueado para diseño físico definitivo.
- El Modelo Comercial y la Matriz de Validación deberán actualizarse sólo después de aprobar cada decisión estructural.
- Las hipótesis de este borrador no constituyen reglas del dominio hasta su aprobación explícita.

## Documentos asociados

- `docs/domain/commercial-model.md`;
- `docs/domain/validation-matrix-next-v03.md`;
- `docs/adr/ADR-024-limites-modelo-comercial-operacional.md`.
