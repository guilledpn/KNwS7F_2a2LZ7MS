# Pruebas de caracterización del Legacy

- Fecha: 2026-07-15
- Estado: Pendiente de revisión
- LCD base: LCD-20260714-02
- LCD funcional actual: LCD-20260715-01
- Issues: #16 y #12

## Propósito

Proteger contratos técnicos observados de APP LLAMADOS y las decisiones de dominio ya aprobadas.

Las pruebas de caracterización no sustituyen pruebas funcionales completas. Un comportamiento conocido como incorrecto sólo puede dejar de caracterizarse cuando existe una decisión documentada, una implementación validada y rollback.

## Ejecutar la suite completa

Desde la raíz del repositorio:

```bash
python tools/run_legacy_safety_checks.py
```

Requisitos locales:

- Python 3.11 o superior;
- Node.js disponible en `PATH`;
- repositorio sincronizado;
- ninguna credencial PROD es necesaria.

El runner:

1. ejecuta los tests `unittest`;
2. valida el shell PWA productivo de forma local y no destructiva;
3. copia el repositorio a un directorio temporal;
4. construye DEV en esa copia;
5. ejecuta los validadores DEV y PROD existentes;
6. elimina automáticamente la copia temporal.

No consulta Supabase ni modifica datos.

## Ejecutar sólo los tests Python

```bash
python -m unittest discover -s tests/characterization -p "test_*.py" -v
```

## Archivos

### `test_repository_contract.py`

Protege:

- presencia de archivos productivos críticos;
- separación de endpoints DEV/PROD;
- configuración DEV;
- relación entre fuente PROD, módulos DEV y artefacto generado;
- estado mutante actual de los workflows;
- barreras básicas de `.gitignore`;
- ausencia de marcadores evidentes de secretos privados en archivos críticos.

### `test_eligibility_policy.py`

Protege ADR-020:

- asignación vigente como única excepción a la presencia activa;
- exclusión de vigentes no asignados;
- última aparición `No Gestionado` como habilitación histórica;
- última aparición `Gestionado` como exclusión preventiva;
- comportamiento conservador ante estado faltante;
- gestión propia sin efecto sobre la gestionabilidad;
- uso de una sola función canónica por consulta, rebuild y sincronización;
- ausencia de mutaciones operativas en la carga asignada;
- existencia de rollback exacto.

La antigua prueba de divergencia fue retirada deliberadamente porque el Issue #12 unifica la implementación.

### `test_backfill_generator.py`

Construye un XLSX ficticio en memoria y protege:

- lectura de `.xlsx` sin dependencias externas;
- filtrado por período;
- normalización de RUT y campaña;
- rechazo de duplicados contradictorios;
- exclusión de nombres, teléfonos y correos del SQL generado;
- preflight de coincidencia exacta.

### `fixtures/eligibility-policy-cases.json`

Contiene casos ficticios sin datos personales y las expectativas canónicas vigentes.

## Pruebas SQL DEV

La prueba integrada de base de datos está en:

```text
supabase/tests/20260715_contact_eligibility_policy.sql
```

Debe ejecutarse sólo en DEV. Usa `BEGIN`, datos ficticios y `ROLLBACK`.

## Interpretación de resultados

| Resultado | Significado |
|---|---|
| PASS | El contrato caracterizado continúa válido. |
| FAIL | Cambió un contrato o falta un archivo; revisar antes de continuar. |
| BLOQUEADO | Falta Python, Node.js u otra precondición. No equivale a PASS. |
| NO APLICA | La prueba no corresponde al alcance concreto y debe justificarse. |

## Regla de mantenimiento

Una expectativa puede modificarse únicamente cuando:

1. el cambio de comportamiento fue deliberado;
2. existe Issue, LCD y decisión documentada;
3. se explica por qué cambia la expectativa;
4. el nuevo comportamiento fue validado;
5. existe rollback;
6. la evidencia queda asociada al PR.
