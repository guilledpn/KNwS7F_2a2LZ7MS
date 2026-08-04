# ADR-027 · Estadísticas motivacionales y proyecciones esperadas

- Estado: <span style="color:red">Pendiente de revisión</span>
- Fecha: 2026-08-04
- LCD: LCD-20260804-01
- Issue: #52

## Contexto

APP LLAMADOS mezcla hoy dos contratos métricos, tres rutas de resolución de metas y una visualización que puede presentar metas implícitas distintas. La auditoría del Issue #52 confirmó que la Meta Mensual vigente es la configurada por el Asesor en Ajustes —189 Agendamientos en agosto de 2026— y que las métricas operativas aprobadas se derivan del Resultado Diario final por Persona y fecha local.

El Asesor aprobó además usar una equivalencia estimada de 2,5 CNS por Agendamiento y $10.000 CLP por CNS para mantener un incentivo operativo visible en distintas escalas temporales.

## Decisión

<span style="color:red">Se adopta un cockpit operativo compacto con un único contrato de lectura. La Meta Mensual proviene de `crm_goals`, guardada desde Ajustes, y las métricas de actividad provienen de resultados finales por Persona y día.</span>

<span style="color:red">El cockpit puede derivar CNS y pesos esperados mediante parámetros mensuales configurables. Esos valores forman un **pulso pecuniario esperado** y deben etiquetarse siempre como estimación.</span>

<span style="color:red">El contrato expondrá ventanas inequívocas: últimos 60 minutos, hoy, semana calendario y mes calendario. La vista principal conservará como máximo cuatro señales operativas, una misión diaria explicada, el ritmo mensual y un bloque motivacional de valor esperado.</span>

## Invariantes

1. La Meta Mensual guardada en Ajustes es la única autoridad de la meta del cockpit.
2. `localStorage` sólo puede actuar como fallback offline y nunca ganar sobre una respuesta válida de Supabase.
3. Agendamientos, CNS esperados y equivalente monetario esperado se presentan como capas distintas.
4. La equivalencia operativa no crea ni modifica CNS de un Caso, Cotización, Sometimiento, Emisión o Reconocimiento.
5. Un error de carga se muestra como dato no disponible; no se reemplaza por cero.
6. La línea real del gráfico termina en hoy; una proyección futura se presenta de forma visualmente discontinua.
7. En días no hábiles no se crea una misión artificial, salvo una meta diaria explícita.
8. Toda fecha de gestión se registra en `America/Santiago` tanto en `crm_log` como en `crm_events`.

## Consecuencias

- Se crea un contrato de backend específico para el cockpit y se deja de unir contratos incompatibles en el navegador.
- `crm_goals` conserva por mes la meta y los supuestos estimativos para que el cálculo sea reproducible.
- El equivalente de una Agenda vigente es `2,5 × $10.000 = $25.000 CLP esperados`.
- La meta de 189 equivale a 472,5 CNS y $4.725.000 CLP esperados.
- El cálculo puede actualizarse inmediatamente y por ventanas temporales reales sin inventar una jornada ni una tasa por minuto.
- La proyección comercial de Next sigue siendo un desarrollo diferente y posterior.

## Alternativas descartadas

- Guardar CNS o pesos derivados como hechos de cada Agendamiento.
- Usar `localStorage` como autoridad de la meta.
- Prorratear la meta mensual en una supuesta ganancia por minuto sin conocer tiempo efectivo de trabajo.
- Reutilizar `crm_events` como denominador de métricas operativas.
- Presentar CNS esperados como CNS reconocidos o ingreso real.

## Validación requerida

- equivalencia exacta de 189 agendas → 472,5 CNS → $4.725.000;
- conteos del contrato unificado contra SQL independiente;
- ventanas última hora, hoy, semana y mes;
- meta 0, día no hábil, meta de recuperación y error de RPC;
- permisos sólo para usuario autenticado;
- misma fecha Chile en ambos registros;
- regresión completa de Legacy y smoke visual en DEV.
