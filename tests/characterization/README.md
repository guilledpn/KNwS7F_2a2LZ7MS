# Pruebas de caracterización del Legacy

- Fecha: 2026-07-14
- Estado: Pendiente de revisión
- LCD: LCD-20260714-02
- Issue: #16

## Propósito

Proteger contratos técnicos observados de APP LLAMADOS antes de reorganizar el repositorio.

Estas pruebas no sustituyen pruebas funcionales completas ni certifican que el comportamiento actual sea correcto. Algunas describen explícitamente bugs conocidos para impedir que cambien de forma silenciosa.

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

### `test_eligibility_policy_divergence.py`

Registra que existen dos políticas distintas:

- política canónica mensual;
- política owner-aware observada en `get_contacts_v2` de DEV.

La prueba debe pasar mientras la divergencia sea un bug conocido y explícito. Cuando el Issue #12 unifique la implementación, esta prueba deberá cambiar: el objetivo futuro será demostrar que sólo existe la política canónica.

### `fixtures/eligibility-policy-cases.json`

Contiene casos ficticios sin datos personales.

## Interpretación de resultados

| Resultado | Significado |
|---|---|
| PASS | El contrato caracterizado continúa igual. |
| FAIL | Cambió un contrato o falta un archivo; revisar antes de continuar. |
| BLOQUEADO | Falta Python, Node.js u otra precondición. No equivale a PASS. |

## Regla de mantenimiento

Una prueba de caracterización puede modificarse únicamente cuando:

1. el cambio de comportamiento fue deliberado;
2. existe Issue y decisión documentada;
3. se explica por qué cambia la expectativa;
4. el nuevo comportamiento fue validado;
5. existe rollback.
