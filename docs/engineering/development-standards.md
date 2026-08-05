# Estándares de Desarrollo y Calidad del CRM Patrimonial

- Estado: Aprobado y evolutivo
- LCD de creación: LCD-20260804-02
- Última actualización: 2026-08-05 · LCD-20260805-01
- Issues relacionados: #56, #57, #61, #65 y #84

## 1. Propósito y alcance

Este documento define las reglas canónicas de implementación, revisión y validación para APP LLAMADOS Legacy y CRM Patrimonial Next.

Aplica plenamente a cambios en código, SQL versionado, migraciones, pruebas, configuración, automatizaciones, herramientas e infraestructura. Para operaciones rutinarias o excepcionales sobre datos, aplica la vía operativa abreviada y sólo los controles relacionados con sus riesgos reales.

No define conocimiento del negocio y no puede contradecir la Constitución, la Arquitectura ni el Modelo del Dominio.

`AGENTS.md` orienta el trabajo. Este documento contiene el estándar técnico completo.

## 2. Principio rector

Todo trabajo debe ser el mínimo trabajo completo y correcto dentro del alcance explícitamente aprobado.

Completo no significa resolver todos los problemas relacionados. Significa:

- alcanzar el objetivo autorizado;
- preservar contratos, invariantes y comportamiento fuera del alcance;
- aplicar validación proporcional al riesgo y a la categoría;
- dejar la trazabilidad necesaria;
- declarar limitaciones reales;
- no introducir deuda técnica silenciosa.

La documentación y la gobernanza protegen el resultado operativo; no sustituyen el resultado operativo.

## 3. Clasificación y selección del procedimiento

Antes de actuar, clasificar el trabajo según su objetivo inmediato:

| Categoría | Objetivo | Procedimiento normal |
|---|---|---|
| Operación rutinaria | Ejecutar un procedimiento vigente y conocido | Preflight, autorización, ejecución, verificación y registro |
| Operación excepcional | Resolver una necesidad concreta cuando la vía vigente no existe, falla o no es segura para el caso | Mecanismo temporal mínimo, recuperación, autorización, ejecución, verificación y retiro o archivo |
| Hotfix | Restaurar continuidad ante una incidencia urgente actual | Contención mínima, rollback, smoke test y regularización posterior |
| Corrección estructural | Eliminar la causa persistente de un defecto | Issue, diseño, implementación, regresión, PR y promoción aplicable |
| Desarrollo de producto | Crear o ampliar una capacidad del producto | Descubrimiento, diseño, implementación, pruebas, PR y promoción |
| Auditoría | Evaluar un candidato o estado congelado | Revisión independiente y de sólo lectura; hallazgos y veredicto |

La clasificación gobierna el procedimiento. Las obligaciones propias de una categoría no se acumulan automáticamente con las de las demás.

No se aplican a una operación rutinaria o excepcional los requisitos propios de corrección estructural o desarrollo de producto salvo que un riesgo concreto los haga necesarios.

Si durante el trabajo cambia la categoría, detener sólo la expansión de alcance, reclasificarla y obtener la trazabilidad o autorización correspondiente.

### 3.1 Operación excepcional

La ausencia, insuficiencia o defecto de una solución canónica no obliga por sí mismo a desarrollar inmediatamente su reemplazo definitivo.

Una operación excepcional es válida cuando:

- identifica la necesidad inmediata y sus límites;
- preserva invariantes críticos;
- tiene preflight, autorización, verificación y recuperación proporcionales;
- no se presenta como fuente de verdad ni como implementación canónica;
- evita contratos, APIs, esquemas o infraestructura durables salvo alcance separado;
- declara la mejora estructural pendiente sin convertirla automáticamente en precondición;
- retira, archiva o regulariza sus artefactos temporales al finalizar.

Una mejora estructural sólo es requisito previo cuando no existe una vía temporal con seguridad suficiente.

Una operación excepcional temporal no constituye implementación paralela ni deuda técnica silenciosa cuando su propósito, límites, recuperación, trazabilidad y condición de retiro están declarados.

### 3.2 Vía operativa abreviada

Las operaciones rutinarias y excepcionales utilizan, salvo riesgo concreto que exija más controles:

Objetivo → preflight → mecanismo mínimo → recuperación → autorización → ejecución → verificación → registro.

No requieren por defecto:

- investigación estructural completa;
- desarrollo de una capacidad reutilizable;
- LCD o ADR;
- modificación del Roadmap;
- múltiples ambientes de promoción;
- auditoría independiente;
- rama o Pull Request cuando no cambian artefactos versionados;
- pruebas no relacionadas con los invariantes afectados.

Un control adicional sólo se incorpora cuando protege un riesgo concreto y declarado. No debe agregarse por analogía con otra categoría.

Una operación rutinaria o excepcional que no modifique conocimiento ni artefactos canónicos conserva registro operativo, no un lote documental.

## 4. Lectura y evidencia aplicables

Antes de trabajar, confirmar el `main` vigente y consultar las fuentes necesarias para el alcance real.

La Constitución, Arquitectura, Modelo del Dominio, Roadmap y estándares forman el contexto rector, pero no deben releerse íntegramente en cada operación cuando su contenido ya es conocido y no existe indicio de cambio o conflicto.

Una operación rutinaria o excepcional consulta prioritariamente:

- el procedimiento aplicable;
- el estado real del producto y ambiente;
- los contratos e invariantes afectados;
- antecedentes directos de operaciones equivalentes;
- defectos o contenciones que puedan solaparse.

Ampliar la lectura sólo ante una duda concreta de autoridad, dominio, arquitectura o gobernanza.

No asumir la existencia, firma, estructura o comportamiento de archivos, funciones, tablas, columnas, políticas, contratos, dependencias o ambientes no comprobados.

Si persiste una incertidumbre material:

- declararla;
- detener únicamente el trabajo dependiente;
- no inventar ni simular la pieza desconocida;
- continuar con partes independientes cuando sea seguro;
- solicitar información sólo cuando no pueda obtenerse de las fuentes disponibles.

Toda inferencia necesaria debe identificarse como inferencia.

## 5. Alcance y diseño

No realizar refactorizaciones amplias como efecto secundario de un fix.

Una mejora útil pero no imprescindible se separa en otro Issue o lote cuando el trabajo es versionado. En una operación excepcional se registra como pendiente sin bloquear el objetivo inmediato.

No cambiar contratos, modelos, esquemas, reglas de negocio, APIs, permisos, estados, eventos, tipos compartidos o comportamiento de Legacy sin identificar explícitamente:

- qué cambia;
- por qué;
- consumidores afectados;
- compatibilidad o migración;
- documentación y pruebas requeridas;
- ambientes involucrados.

Antes de crear una implementación durable, comprobar si existe una abstracción o solución canónica reutilizable.

No crear implementaciones paralelas permanentes salvo transición explícita con propósito, fuente de verdad, límites, Issue y estrategia de retiro.

No duplicar la definición semántica de una regla de negocio entre componentes, hooks, servicios, adaptadores, SQL o funciones de base de datos.

Se permiten validaciones defensivas en varias fronteras cuando protegen responsabilidades diferentes y derivan de la misma regla canónica.

No crear tablas, columnas, estados, procesos, pantallas o conceptos sin una necesidad real del negocio o de la operación.

Las entidades almacenan hechos. Vistas, colas, cachés, dashboards, estadísticas, recomendaciones y proyecciones son derivados reconstruibles.

## 6. Preservación del Legacy

APP LLAMADOS Legacy es una aplicación productiva frágil.

Una corrección estructural o cambio de software debe:

- conservar comportamiento fuera del alcance;
- evitar reestructuraciones innecesarias;
- considerar caracterización o regresión;
- revisar superficies relacionadas;
- ejecutar smoke test proporcional;
- mantener rollback claro.

Una operación sobre datos debe:

- identificar el conjunto exacto;
- preservar historia e invariantes;
- evitar escrituras concurrentes no previstas;
- disponer de recuperación proporcional;
- conciliar antes y después;
- ejecutar el smoke test correspondiente a la superficie realmente afectada.

Una operación sobre datos no hereda automáticamente todas las pruebas de un cambio de software.

No asumir que una mejora de arquitectura autoriza cambiar comportamiento histórico. No reescribir Legacy como efecto secundario de incorporar arquitectura objetivo.

### 6.1 Clasificación física de artefactos

Antes de mover, eliminar, reutilizar o modificar un archivo, clasificarlo con evidencia como:

- fuente productiva de Legacy;
- fuente modular o transitoria;
- artefacto generado;
- infraestructura compartida;
- código de Next;
- herramienta o documentación.

Consultar sólo el inventario, matriz de despliegue, estructura objetivo o procedimiento de build necesario para resolver la clasificación.

No determinar la pertenencia por lenguaje, framework, nombre o carpeta aparente. Una ruta objetivo no se presume implementada.

## 7. Prohibición de deuda técnica silenciosa

No introducir, salvo excepción local y explícitamente justificada:

- `any`, `any[]`, `as any`, `Promise<any>` o `Record<string, any>`;
- parámetros implícitamente tipados como `any`;
- `@ts-ignore`, `@ts-nocheck` o desactivaciones amplias de ESLint;
- castings usados sólo para silenciar TypeScript;
- non-null assertions injustificadas;
- errores capturados y descartados o bloques `catch` vacíos;
- fallbacks que conviertan errores o datos inválidos en resultados válidos;
- valores hardcodeados para simular comportamiento real;
- `TODO`, `FIXME`, mocks, stubs o placeholders sin Issue asociado cuando deban permanecer;
- validaciones semánticas duplicadas o inconsistentes;
- funciones vacías;
- implementaciones provisionales presentadas como terminadas;
- pruebas que sólo demuestren compilación;
- debilitamiento de pruebas para obtener un resultado exitoso.

No declarar terminado un camino productivo con datos simulados, placeholders o ramas sin implementar.

Una excepción técnica durable debe limitar superficie, explicar necesidad y riesgo, vincular Issue e indicar condición de retiro.

## 8. TypeScript, datos externos y errores

Estas reglas aplican al TypeScript nuevo o modificado.

- cumplir configuración estricta y lint con información de tipos cuando el proyecto lo soporte;
- no relajar globalmente `tsconfig`, ESLint u otra configuración por un cambio local;
- representar conceptos y contratos reales con tipos explícitos;
- recibir datos externos como `unknown`, validarlos en la frontera y convertirlos;
- usar castings sólo cuando expresen conocimiento demostrado;
- justificar non-null assertions mediante una invariante cercana;
- distinguir código generado y regenerarlo mediante procedimiento reproducible.

Distinguir entre ausencia legítima, dato desconocido, dato inválido, error de infraestructura y resultado igual a cero.

Toda entrada de archivo, API, formulario, variable de entorno o base externa debe validarse en su frontera.

Un error no debe convertirse silenciosamente en dato válido. Un `catch` debe resolver, transformar con contexto o propagar.

Los logs no deben contener PII, secretos, tokens, bases de campaña ni información patrimonial sensible.

## 9. SQL, migraciones y Supabase

No utilizar PROD para experimentar o descubrir una solución.

Toda migración durable debe ser:

- versionada;
- reproducible;
- validada primero fuera de PROD;
- compatible con el estado real previo;
- idempotente cuando pueda repetirse;
- transaccional cuando sea posible;
- acompañada de rollback o recuperación explícita.

Una operación SQL excepcional temporal no se presenta como migración canónica. Debe tener alcance, guardas, recuperación, autorización y retiro definidos.

No usar `service_role`, secretos JWT, claves privadas ni credenciales privilegiadas. Aplicar mínimo privilegio.

No otorgar permisos a `anon`, `authenticated`, `PUBLIC` u otros roles amplios sin decisión explícita y verificación.

Los `GRANT` y la exposición mediante Data API son distintos de RLS. Toda modificación durable de tablas, vistas, funciones, políticas o permisos debe comprobar:

- RLS y políticas `USING`/`WITH CHECK`;
- `GRANT` y `REVOKE`;
- exposición mediante Data API;
- acceso permitido y denegado;
- advisors o controles de seguridad disponibles.

Toda tabla en un esquema expuesto debe tener RLS y permisos limitados. Una tabla sin RLS sólo puede justificarse fuera de esquemas expuestos y sin acceso de roles públicos.

Las vistas expuestas que deban respetar RLS usan `security_invoker = true` o se ubican fuera del esquema expuesto.

Una función `security definer` requiere necesidad explícita, `search_path` seguro, objetos calificados, permisos restringidos y autorización interna cuando opere en contexto de usuario.

No ocultar errores SQL devolviendo ceros, colecciones vacías o valores por defecto interpretables como datos reales.

Toda carga masiva debe seleccionar, según categoría y riesgo, los controles aplicables entre:

- validación previa;
- staging cuando aporte seguridad real;
- hash u origen;
- conteos antes y después;
- conciliación;
- idempotencia;
- protección de hechos históricos;
- recuperación verificable.

Una operación excepcional no requiere convertir cada control en infraestructura durable, API nueva o migración separada.

Una carga corporativa nunca debe convertirse silenciosamente en actividad interna del asesor.

DEV nunca apunta a PROD y PROD nunca apunta a DEV.

## 10. Dependencias

Antes de incorporar una dependencia, comprobar si la plataforma, biblioteca estándar o una dependencia existente resuelve la necesidad.

Toda dependencia nueva debe justificar necesidad, alcance, mantenimiento, seguridad, impacto en build y alternativa descartada.

No incorporar una biblioteca para evitar una validación pequeña o duplicar una capacidad existente.

## 11. Pruebas y validación

La categoría selecciona los controles aplicables. No se parte de una lista universal que deba justificarse elemento por elemento.

Entre los controles posibles se encuentran:

- validación documental;
- typecheck y lint;
- pruebas unitarias, integración, caracterización, regresión o contratos;
- validación de migraciones;
- build;
- smoke test;
- revisión visual;
- comprobaciones de seguridad y permisos;
- dry-run, conteos, conciliación, idempotencia y recuperación para operaciones de datos.

Para un cambio TypeScript, ejecutar typecheck, lint, pruebas afectadas e integración o build cuando correspondan.

Para una corrección estructural de Legacy, ejecutar caracterización o regresión, safety checks y smoke test proporcional.

Para SQL durable, validar fuera de PROD, comparar con consultas independientes, revisar permisos y probar rollback.

Para una operación sobre datos, probar el mecanismo y la recuperación de forma proporcional al conjunto y riesgo; no exigir pruebas de UI, build o contratos no afectados.

Los controles propios de otras categorías quedan excluidos y no requieren registro individual. Un control esperado dentro de la categoría seleccionada que se omita debe registrarse como `No aplica` con motivo concreto.

No afirmar `PASS` sin evidencia identificable. Un build exitoso no demuestra comportamiento correcto.

Las pruebas deben validar comportamiento observable, contratos e invariantes, no sólo detalles internos.

## 12. Producción y recuperación

Antes de modificar PROD:

1. verificar el último estado estable;
2. confirmar autorización explícita para la operación exacta;
3. revisar el alcance o diff aplicable;
4. preparar rollback o recuperación;
5. aplicar el mínimo cambio;
6. validar el resultado;
7. ejecutar smoke test proporcional a la superficie afectada;
8. dejar trazabilidad.

Una autorización para DEV no autoriza STAGING ni PROD. Una autorización para un cambio no autoriza otros hallazgos.

La continuidad operativa prevalece sobre una mejora funcional.

No eliminar o reemplazar una herramienta operativa sólo por existir una fuente canónica. Primero comprobar uso, equivalencia, acceso, actualización, reemplazo y recuperación.

## 13. Git, PR y evidencia

`main` debe permanecer estable.

Todo cambio en artefactos canónicos, código, SQL versionado, contratos, configuración o comportamiento permanente comienza en Issue y rama breve, salvo auditoría de sólo lectura.

Una operación rutinaria o excepcional que sólo ejecute datos mediante un procedimiento vigente o artefacto temporal no requiere por defecto rama o Pull Request. Conserva un registro operativo suficiente para reconstruir:

- origen;
- alcance;
- autorización;
- ejecución;
- resultado;
- recuperación.

Si durante una operación se crea o modifica un artefacto que deba permanecer en el repositorio, esa parte se separa y sigue Issue, rama, commit y Pull Request.

Usar Conventional Commits. Los commits deben representar unidades lógicas; consolidar `WIP` o `fixup` antes del merge.

El Pull Request debe ser directo e indicar objetivo, causa, alcance, contratos o documentos afectados, ambientes, pruebas, riesgos, recuperación, limitaciones e identificadores relacionados.

Evitar repetir el diff, narrar cada intento, incluir logs completos o afirmar validaciones sin evidencia.

Revisar el diff para detectar archivos accidentales, secretos, PII, cambios fuera de alcance, pruebas eliminadas, configuraciones relajadas y artefactos generados no intencionales.

## 14. Excepciones

Una excepción técnica durable no se aprueba implícitamente. Debe registrar regla exceptuada, motivo, superficie, riesgo, mitigación, Issue y criterio de retiro.

Una operación excepcional ya clasificada no necesita declararse además como excepción a cada regla propia de otras categorías.

## 15. Criterio de finalización

### 15.1 Cambio versionado

Puede declararse terminado cuando:

- se trató la causa dentro del alcance aprobado;
- los contratos afectados están identificados;
- pasan las pruebas seleccionadas por categoría y riesgo;
- la documentación necesaria está actualizada;
- no existe deuda silenciosa;
- el diff fue revisado;
- los ambientes y limitaciones están declarados;
- el resultado real coincide con lo informado.

### 15.2 Operación rutinaria o excepcional

Puede declararse terminada cuando:

- se alcanzó el objetivo operativo autorizado;
- los invariantes afectados fueron verificados;
- la recuperación quedó disponible o dejó de ser necesaria por cierre comprobado;
- no quedaron efectos parciales silenciosos ni residuos indebidos;
- el resultado y las incidencias fueron registrados;
- los artefactos temporales fueron retirados, archivados o regularizados.

No es requisito haber corregido la causa estructural separable.

El cierre debe distinguir, de forma proporcional, qué se modificó, qué no, qué se validó, qué no pudo validarse, ambientes, evidencia, riesgos y pendientes.

## 16. Cumplimiento automático

Las reglas automatizables deben trasladarse gradualmente a configuración, pruebas y CI.

Regla canónica → configuración técnica → check reproducible → evidencia.

Issue #56 gobierna la adopción gradual de quality gates. Ningún control debe hacerse bloqueante antes de comprobar compatibilidad con el estado real y la categoría a la que corresponde.