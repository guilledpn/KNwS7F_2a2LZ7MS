# AGENTS.md · Reglas de trabajo del CRM Patrimonial

Estado: Vigente  
Último LCD aprobado: LCD-20260713-01  
Aprobación: Pull Request #9

## Propósito

Este archivo orienta a cualquier asistente de IA o colaborador que trabaje en el repositorio. No reemplaza la Constitución, la Arquitectura ni el Modelo del Dominio.

## Jerarquía documental

1. Constitución.
2. Arquitectura.
3. Modelo del Dominio.
4. Backlog y Roadmap.
5. Bitácora Arquitectónica y ADR.
6. Instrucciones operativas.

## Flujo obligatorio

Descubrir → Validar → Documentar → Diseñar → Implementar.

Antes de modificar código:

1. Comprender el problema de negocio.
2. Identificar conceptos o reglas afectados.
3. Determinar qué documentos canónicos deben cambiar.
4. Registrar la decisión cuando corresponda.
5. Diseñar el cambio.
6. Implementar y probar.

## Estrategia del producto

- El repositorio evolucionará como monorepo.
- APP LLAMADOS se mantiene como aplicación legacy operativa.
- CRM Patrimonial Next se desarrolla como nueva generación.
- La transición se realizará gradualmente mediante Strangler Fig Pattern.
- La arquitectura objetivo es DDD + arquitectura hexagonal + monolito modular.

## Reglas Git

- `main` debe permanecer estable y revisable.
- No experimentar directamente en `main`.
- Cada cambio comienza en un Issue y una rama breve.
- Usar Conventional Commits.
- Abrir Pull Request antes de fusionar.
- El merge representa la aprobación técnica del lote.
- Un commit registra cambios; no equivale a aprobación.

## Seguridad y ambientes

- PROD contiene datos reales y no se usa para experimentar.
- DEV nunca apunta a PROD.
- No usar `service_role`, JWT Secret ni claves privadas en código o documentación.
- No almacenar datos reales de clientes en Git.
- Toda operación destructiva requiere autorización explícita.

## Dependencias arquitectónicas

El dominio no debe depender de UI, Supabase, PostgreSQL, APIs externas ni detalles de infraestructura.

Las dependencias deben apuntar hacia adentro:

Adaptadores → Aplicación → Dominio.

Si el dominio necesita acceso externo, debe expresarlo mediante un puerto.

## Documentación

- La documentación canónica de ingeniería vivirá progresivamente en Markdown versionado.
- Google Drive se mantiene para fuentes externas, PDFs, manuales, evidencias y documentos no adecuados para Git.
- Cada concepto debe tener un único lugar canónico.
- No duplicar contenido entre Git y Drive.
- Los cambios semánticos relevantes se registran mediante LCD y ADR cuando corresponda.

## Calidad

- Todo bug corregido debe considerar una prueba de regresión o caracterización.
- Toda regla de dominio nueva debe contar con pruebas de comportamiento.
- Toda promoción debe incluir validación y smoke test.
- La interfaz no debe ser la única autoridad de una regla crítica.

## Aprendizaje

Durante el trabajo se enseñarán y registrarán competencias en cinco niveles:

1. Git y repositorio.
2. Colaboración y gestión.
3. Desarrollo y calidad.
4. Arquitectura y dominio.
5. Operación.

La matriz se actualiza por evidencia práctica, no sólo por exposición teórica.
