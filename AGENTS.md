# AGENTS.md · Reglas de trabajo del CRM Patrimonial

- Estado: Vigente
- Último LCD aprobado: LCD-20260805-01
- Gobernanza documental: ADR-023 y ADR-026
- Última conciliación: 2026-08-05

## Propósito

Este archivo orienta a agentes y colaboradores. No reemplaza la Constitución, la Arquitectura, el Modelo del Dominio ni los Estándares de Desarrollo.

## Lectura aplicable

Antes de trabajar, confirmar el `main` vigente y consultar las fuentes necesarias para el alcance real.

La Constitución, la Arquitectura, el Modelo del Dominio, el Roadmap y los estándares forman el contexto rector, pero no deben releerse íntegramente en cada operación cuando su contenido ya es conocido y no existe indicio de cambio o conflicto.

Una operación rutinaria o excepcional consulta prioritariamente:

- el procedimiento operativo aplicable;
- el estado real del producto y ambiente;
- los contratos e invariantes afectados;
- los antecedentes directos de operaciones equivalentes;
- los defectos o contenciones que puedan solaparse.

Ampliar la lectura únicamente cuando aparezca una duda concreta de autoridad, dominio, arquitectura o gobernanza.

Las instrucciones de ChatGPT son una puerta de entrada. La autoridad vive en el repositorio.

Si falta una fuente necesaria o existe una divergencia, detener sólo el trabajo dependiente y advertirla.

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

Este flujo completo corresponde a correcciones estructurales, desarrollo de producto y cambios versionados que lo requieran. No se aplica automáticamente a una operación rutinaria o excepcional.

## Clasificación del trabajo

Antes de actuar, clasificar la tarea como:

- operación rutinaria;
- operación excepcional;
- hotfix;
- corrección estructural;
- desarrollo de producto;
- auditoría.

La clasificación gobierna el procedimiento aplicable. Las obligaciones propias de una categoría no se acumulan automáticamente con las de las demás.

Para una operación rutinaria o excepcional, el objetivo es ejecutar de manera segura y eficiente la necesidad concreta. No corresponde desarrollar la solución definitiva, corregir toda causa estructural relacionada ni aplicar el flujo completo de desarrollo, salvo que no exista una vía temporal con seguridad suficiente.

Una operación rutinaria o excepcional que no modifique artefactos canónicos, contratos ni comportamiento permanente no requiere por defecto LCD, ADR, rama, Pull Request ni auditoría independiente. Requiere preflight, autorización del ambiente, mecanismo mínimo, recuperación proporcional, ejecución controlada, verificación y registro del resultado.

No convertir una mejora estructural separable en precondición del objetivo inmediato. Si el alcance cambia de categoría, detener sólo la expansión, reclasificarla y obtener la trazabilidad o autorización correspondiente.

La documentación y la gobernanza protegen el resultado operativo; no sustituyen el resultado operativo.

## Antes de actuar

1. identificar el objetivo inmediato;
2. clasificar la tarea;
3. identificar invariantes, riesgos y ambientes realmente afectados;
4. comprobar si existe una vía vigente que sirva para el caso;
5. elegir el procedimiento más pequeño que produzca un resultado seguro y verificable;
6. ejecutar los controles propios de la categoría;
7. dejar trazabilidad proporcional.

Sólo las correcciones estructurales y el desarrollo de producto deben tratar necesariamente la causa persistente, diseñar una solución durable y recorrer el flujo completo de ingeniería.

En una operación excepcional puede resolverse temporalmente el efecto operativo sin corregir todavía la causa estructural, siempre que ésta quede identificada y la operación no se presente como solución permanente.

En una emergencia productiva se puede restaurar primero la continuidad mediante el cambio seguro más pequeño. La documentación y el cierre siguen siendo obligatorios.

## Evidencia e incertidumbre

No asumir archivos, funciones, tablas, contratos, dependencias o ambientes no comprobados.

Primero buscar evidencia en las fuentes directamente relacionadas con el alcance. Si persiste la incertidumbre:

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

Antes de mover, eliminar o reutilizar archivos, clasificar con evidencia si pertenecen a Legacy, fuente transitoria, artefacto generado, infraestructura compartida o Next. Consultar sólo el inventario, matriz o procedimiento necesario para resolver esa clasificación. Una ruta objetivo no se presume implementada.

## Calidad

Cumplir `docs/engineering/development-standards.md` cuando la tarea modifique código, SQL, pruebas, configuración, automatizaciones, herramientas o infraestructura versionada.

Reglas no negociables:

- no refactorizar ampliamente como efecto secundario de un fix;
- no cambiar contratos o comportamiento sin declarar impacto;
- no crear implementaciones paralelas sin revisar la solución canónica;
- no duplicar reglas semánticas;
- no introducir deuda técnica silenciosa;
- no ocultar errores con tipos amplios, supresiones, casts o fallbacks;
- todo bug estructural debe considerar regresión o caracterización;
- toda regla de dominio nueva debe tener pruebas de comportamiento;
- ejecutar los controles definidos por la categoría y el riesgo;
- no declarar `PASS` sin evidencia.

Los controles propios de otras categorías quedan excluidos y no requieren justificación individual. Un control esperado dentro de la categoría seleccionada que se omita debe informarse como `No aplica` con motivo.

Para Supabase, toda modificación permanente de tablas, vistas, funciones, políticas o permisos debe revisar RLS, `GRANT`, exposición mediante Data API y acceso permitido/denegado.

## Git

- `main` permanece estable.
- No experimentar directamente en `main`.
- Todo cambio en artefactos canónicos, código, SQL versionado, contratos, configuración o comportamiento permanente comienza en Issue y rama breve, salvo auditoría de sólo lectura.
- Una operación rutinaria o excepcional que sólo ejecute datos mediante un procedimiento vigente o un artefacto temporal no requiere por defecto rama o Pull Request. Debe conservar registro suficiente de origen, autorización, ejecución, resultado y recuperación.
- Si durante la operación se crea o modifica un artefacto que deba permanecer en el repositorio, esa parte se separa y sigue el flujo de Issue, rama y Pull Request.
- Usar Conventional Commits.
- Los commits deben representar unidades lógicas; consolidar ruido `WIP` o `fixup` antes del merge.
- El PR debe ser completo y directo, sin narrar cada intento ni repetir el diff.
- Un commit no equivale por sí solo a aprobación.
- No reescribir historia publicada para ocultar errores.

## Seguridad y ambientes

- LOCAL/DEV: datos ficticios o sanitizados.
- STAGING: candidato validado en DEV cuando la categoría lo requiera.
- PROD: datos reales; nunca experimentar.
- Una autorización para DEV no autoriza STAGING ni PROD.
- Toda operación destructiva o promoción requiere autorización explícita.
- No usar `service_role`, secretos JWT ni claves privadas.
- No almacenar PII, bases reales ni información patrimonial sensible en Git.
- Tratar el repositorio como público.

Antes de PROD: estado estable, autorización, alcance exacto, recuperación, cambio mínimo, validación y trazabilidad. El smoke test debe corresponder a la superficie realmente afectada.

## Control documental

Toda modificación del conocimiento canónico pertenece a un LCD. Antes de crear LCD o ADR, revisar sus registros y reservar el identificador libre.

Una operación que no modifica conocimiento canónico no genera un LCD sólo por requerir trazabilidad operativa.

Una conversación descubre; los documentos conservan las decisiones aprobadas.

## Cierre

Informar de forma proporcional:

- qué cambió y qué no;
- qué se validó y qué no;
- ambientes afectados;
- evidencia;
- riesgos, limitaciones y pendientes.

Verificar si cambiaron Constitución, Arquitectura, Dominio, Roadmap, ADR, LCD, registros, `PROJECT_MAP.md`, `AGENTS.md`, contratos o deuda técnica.