# Estándares de Desarrollo y Calidad del CRM Patrimonial

- Estado: Aprobado y evolutivo
- LCD de creación: LCD-20260804-02
- Última actualización: 2026-08-04 · LCD-20260804-04
- Issues relacionados: #56, #57 y #61

## 1. Propósito y alcance

Este documento define las reglas canónicas de implementación, revisión y validación para APP LLAMADOS Legacy y CRM Patrimonial Next.

Aplica a código, SQL, migraciones, pruebas, configuración, automatizaciones, herramientas e infraestructura versionada. No define conocimiento del negocio y no puede contradecir la Constitución, la Arquitectura ni el Modelo del Dominio.

`AGENTS.md` orienta el trabajo. Este documento contiene el estándar técnico completo.

## 2. Principio rector

Todo cambio debe ser el mínimo cambio completo y correcto, no simplemente el mínimo cambio que haga desaparecer el síntoma.

Un cambio completo:

- trata la causa dentro del alcance aprobado;
- preserva contratos y comportamiento no incluidos;
- incorpora validación proporcional al riesgo;
- actualiza documentación y trazabilidad;
- no introduce deuda técnica silenciosa;
- declara limitaciones reales.

## 3. Alcance y diseño

No realizar refactorizaciones amplias como efecto secundario de un fix.

Una refactorización útil pero no imprescindible debe separarse en otro Issue o lote.

No cambiar contratos, modelos, esquemas, reglas de negocio, APIs, permisos, estados, eventos, tipos compartidos o comportamiento de Legacy sin identificar explícitamente:

- qué cambia;
- por qué;
- consumidores afectados;
- compatibilidad o migración;
- documentación y pruebas requeridas;
- ambientes involucrados.

Antes de crear una implementación, comprobar si existe una abstracción o solución canónica reutilizable.

No crear implementaciones paralelas salvo transición explícita con:

- propósito;
- fuente de verdad;
- límites;
- Issue;
- estrategia de retiro.

No duplicar la definición semántica de una regla de negocio entre componentes, hooks, servicios, adaptadores, SQL o funciones de base de datos.

Se permiten validaciones defensivas en varias fronteras cuando protegen responsabilidades diferentes, siempre que deriven de la misma regla canónica y produzcan resultados compatibles.

No crear tablas, columnas, estados, procesos, pantallas o conceptos sin una necesidad real del negocio o de la operación.

Las entidades almacenan hechos. Vistas, colas, cachés, dashboards, estadísticas, recomendaciones y proyecciones son derivados reconstruibles y no constituyen fuente de verdad.

### 3.1 Gestión de incertidumbre y evidencia

No asumir la existencia, firma, estructura o comportamiento de archivos, funciones, tablas, columnas, políticas, contratos, dependencias, ambientes o abstracciones que no hayan sido comprobados.

Ante información insuficiente, primero buscar evidencia en:

- documentos canónicos;
- estado real del repositorio;
- pruebas y migraciones;
- historial de Git e Issues;
- configuración y procedimientos del ambiente aplicable.

Si la incertidumbre persiste:

- declarar qué información falta y qué decisiones dependen de ella;
- detener únicamente el trabajo dependiente;
- no inventar ni simular la pieza desconocida;
- solicitar información sólo cuando no pueda obtenerse de las fuentes disponibles;
- continuar con las partes independientes cuando sea seguro.

Una inferencia necesaria debe identificarse como inferencia y no presentarse como hecho verificado.

La falta de contexto no autoriza a crear fallbacks, mocks, contratos o abstracciones ficticias para aparentar que el trabajo está completo.

## 4. Preservación del Legacy

APP LLAMADOS Legacy es una aplicación productiva frágil.

Todo cambio debe:

- conservar el comportamiento fuera del alcance;
- evitar reestructuraciones innecesarias;
- considerar pruebas de caracterización;
- agregar regresión para el defecto corregido;
- revisar navegación, persistencia, filtros y cálculos relacionados;
- ejecutar smoke test proporcional al riesgo;
- mantener un rollback claro.

No asumir que una mejora de arquitectura autoriza cambiar comportamiento histórico.

Una divergencia intencional debe estar documentada y aprobada.

La transición hacia Next es gradual. No reescribir Legacy como efecto secundario de incorporar arquitectura objetivo.

### 4.1 Clasificación física de productos y artefactos

Antes de mover, eliminar, reutilizar o modificar un archivo, clasificarlo con evidencia como una de estas categorías:

- fuente productiva de APP LLAMADOS Legacy;
- fuente modular o transitoria;
- artefacto generado;
- infraestructura compartida;
- código de CRM Patrimonial Next;
- herramienta o documentación.

La clasificación debe consultar, según corresponda:

- `docs/architecture/current-repository-inventory.md`;
- `docs/architecture/product-environment-deployment-matrix.md`;
- `docs/architecture/target-monorepo-structure.md`;
- el procedimiento de build, publicación o despliegue aplicable.

No determinar la pertenencia de un archivo únicamente por su lenguaje, framework, nombre o carpeta aparente.

La estructura objetivo no se presenta como estructura ya implementada. Mientras el inventario vigente lo indique, la raíz productiva, `src/dev/`, `dev/` y las rutas objetivo cumplen responsabilidades distintas.

Si no puede determinarse la categoría, el consumidor o el origen de generación de un archivo, no debe moverse, eliminarse ni reutilizarse hasta resolver esa incertidumbre.

## 5. Prohibición de deuda técnica silenciosa

No introducir, salvo excepción local y explícitamente justificada:

- `any`;
- `any[]`;
- `as any`;
- `Promise<any>`;
- `Record<string, any>`;
- parámetros implícitamente tipados como `any`;
- `@ts-ignore`;
- `@ts-nocheck`;
- desactivaciones amplias de ESLint;
- castings usados sólo para silenciar TypeScript;
- non-null assertions injustificadas;
- errores capturados y descartados;
- bloques `catch` vacíos;
- fallbacks que conviertan errores o datos inválidos en resultados aparentemente válidos;
- valores hardcodeados para simular comportamiento real;
- `TODO`, `FIXME`, mocks, stubs o placeholders sin Issue asociado;
- validaciones semánticas duplicadas o inconsistentes;
- funciones vacías;
- implementaciones provisionales presentadas como terminadas;
- pruebas que sólo demuestren compilación;
- eliminación, omisión o debilitamiento de pruebas para obtener un resultado exitoso.

No declarar terminado un camino que pueda ejecutarse en producción si conserva datos simulados, placeholders o ramas sin implementar.

Una excepción debe:

- limitarse a la menor superficie posible;
- explicar necesidad y riesgo;
- vincularse a un Issue;
- indicar condición de retiro cuando genere deuda;
- no convertirse en desactivación global.

## 6. TypeScript y tipos

Estas reglas aplican al TypeScript nuevo o modificado.

El código debe cumplir configuración estricta y lint con información de tipos cuando el proyecto lo soporte.

No relajar globalmente `tsconfig`, ESLint u otra configuración de calidad para integrar un cambio local.

Los tipos deben representar conceptos y contratos reales. No usar tipos amplios sólo para facilitar transporte entre capas.

Cuando transporte, persistencia, aplicación y dominio representen responsabilidades distintas, sus tipos deben distinguirse.

Un dato externo desconocido entra como `unknown`, se valida en la frontera y se convierte a un tipo explícito.

Los castings deben expresar conocimiento demostrado, no suprimir incertidumbre.

Las non-null assertions requieren una invariante verificable y cercana.

El código generado debe:

- distinguirse del mantenido manualmente;
- regenerarse mediante procedimiento reproducible;
- no editarse manualmente salvo proceso documentado.

## 7. Datos externos y validación

Distinguir entre:

- ausencia legítima;
- dato desconocido;
- dato inválido;
- error de infraestructura;
- resultado igual a cero.

No transformar silenciosamente una categoría en otra.

Toda entrada de archivo, API, formulario, variable de entorno o base externa debe validarse en su frontera.

Las validaciones deben producir errores comprensibles y trazables.

Un fallback sólo es válido cuando representa una regla explícita y segura. No debe ocultar corrupción, incompatibilidad o falta de datos.

## 8. Manejo de errores y observabilidad

Un error no debe convertirse silenciosamente en un dato válido.

Los errores recuperables deben tener conducta definida.

Los errores no recuperables deben propagarse o bloquear visiblemente la operación.

Los mensajes al usuario deben ser comprensibles sin eliminar la información técnica necesaria para diagnóstico.

Los logs no deben contener:

- PII;
- secretos;
- tokens;
- bases de campaña;
- información patrimonial sensible.

No registrar objetos completos si contienen datos reservados.

Un `catch` debe resolver, transformar con contexto o propagar. Capturar y descartar está prohibido.

## 9. SQL, migraciones y Supabase

No utilizar PROD para experimentar o descubrir una solución.

Toda migración debe ser:

- versionada;
- reproducible;
- validada primero fuera de PROD;
- compatible con el estado real previo;
- idempotente cuando pueda repetirse;
- transaccional cuando sea posible;
- acompañada de rollback o estrategia explícita de recuperación.

No usar `service_role`, secretos JWT, claves privadas ni credenciales privilegiadas.

Aplicar mínimo privilegio.

No otorgar permisos a `anon`, `authenticated`, `PUBLIC` u otros roles amplios sin decisión explícita y verificación.

Los `GRANT` y la exposición mediante Data API son una capa distinta de RLS. No asumir que una tabla está expuesta o protegida sólo por estar en un esquema determinado: comprobar la configuración real y los permisos explícitos.

Toda tabla ubicada en un esquema expuesto por la Data API debe:

- tener RLS habilitado;
- contar con políticas explícitas acordes con el modelo de acceso;
- limitar sus `GRANT` a las operaciones y roles necesarios;
- probar el acceso permitido y denegado con identidades representativas.

Una tabla sin RLS sólo puede justificarse fuera de los esquemas expuestos, sin acceso de `anon` ni `authenticated`, y con uso interno explícito. Preferir RLS como defensa adicional cuando sea viable.

Toda vista expuesta que deba respetar las políticas de sus tablas subyacentes debe utilizar `security_invoker = true`. Si esto no corresponde o no está disponible, la vista debe ubicarse en un esquema no expuesto o revocar acceso a roles públicos.

Las funciones usan `security invoker` por defecto. Una función `security definer` requiere:

- necesidad explícita y documentada;
- `search_path` seguro, preferentemente vacío;
- referencias a objetos con esquema calificado;
- ubicación y permisos de ejecución restringidos;
- revisión de que no convierta una falla de autorización en bypass de RLS;
- comprobación de identidad y autorización dentro de la función cuando opere en contexto de usuario.

No confiar en los permisos de ejecución predeterminados de PostgreSQL. Revisar y revocar `EXECUTE` de `PUBLIC`, `anon` o `authenticated` cuando no corresponda, y concederlo sólo a los roles autorizados.

Toda migración que cree o modifique tablas, vistas, funciones, políticas o permisos debe verificar:

- RLS;
- políticas `USING` y `WITH CHECK` cuando apliquen;
- `GRANT` y `REVOKE`;
- exposición mediante Data API;
- comportamiento para roles autorizados y no autorizados;
- advisors o controles de seguridad disponibles.

No ocultar errores SQL devolviendo ceros, colecciones vacías o valores por defecto interpretables como datos reales.

Toda carga o migración masiva debe considerar:

- validación previa;
- staging cuando corresponda;
- hash u origen;
- conteos antes y después;
- conciliación;
- idempotencia;
- protección de hechos históricos;
- recuperación verificable.

Una carga corporativa nunca debe convertirse silenciosamente en actividad interna del asesor.

DEV nunca apunta a PROD y PROD nunca apunta a DEV.

## 10. Dependencias

Antes de incorporar una dependencia, comprobar si la plataforma, biblioteca estándar o una dependencia existente resuelve la necesidad.

Toda dependencia nueva debe justificar:

- necesidad;
- alcance;
- mantenimiento;
- seguridad;
- impacto en build y despliegue;
- alternativa descartada.

No incorporar una biblioteca para evitar una validación pequeña o duplicar una capacidad existente.

Actualizar una dependencia como efecto secundario requiere justificar compatibilidad y riesgo.

## 11. Pruebas y validación

La validación depende del impacto real.

Todo cambio debe ejecutar los controles aplicables entre:

- validación documental;
- typecheck;
- lint;
- pruebas unitarias;
- pruebas de integración;
- pruebas de caracterización;
- pruebas de regresión;
- pruebas de contratos;
- validación de migraciones;
- build de producción;
- smoke test;
- revisión visual;
- comprobaciones de seguridad y permisos.

Para TypeScript, cuando existan:

- typecheck;
- lint;
- pruebas unitarias afectadas;
- integración aplicable;
- build de producción.

Para Legacy:

- caracterización;
- safety checks;
- regresión;
- smoke test proporcional.

Para SQL:

- validación en ambiente no productivo;
- comparación mediante consultas independientes;
- conteos y conciliación;
- revisión de RLS, políticas, permisos y exposición;
- pruebas de acceso permitido y denegado;
- rollback o recuperación.

Para UI:

- flujo funcional afectado;
- viewport representativo móvil;
- viewport representativo de escritorio;
- estados vacío, carga, error y éxito cuando apliquen;
- accesibilidad básica.

Un control no aplicable debe registrarse como `No aplica` con motivo concreto.

No afirmar `PASS` sin evidencia identificable.

Un build exitoso no demuestra comportamiento correcto.

Una regresión debe fallar por la causa correcta antes del fix cuando sea viable y pasar después.

Las pruebas deben validar comportamiento observable, contratos e invariantes, no sólo detalles internos.

No afirmar revisión visual de la aplicación real cuando sólo se inspeccionó un artefacto aislado, una captura o un viewport simulado.

## 12. Producción y rollback

Antes de modificar PROD:

1. verificar el último estado estable;
2. confirmar autorización explícita;
3. revisar el diff exacto;
4. preparar rollback;
5. aplicar el mínimo cambio;
6. validar;
7. ejecutar smoke test;
8. dejar trazabilidad.

Una autorización para DEV no autoriza STAGING ni PROD.

Una autorización para promover un cambio no autoriza otros cambios descubiertos durante el proceso.

La continuidad operativa prevalece sobre una mejora funcional.

No eliminar o reemplazar una herramienta operativa sólo por existir una fuente canónica. Primero comprobar:

- uso real;
- equivalencia;
- forma de acceso;
- actualización;
- reemplazo;
- recuperación.

## 13. Git, PR y evidencia

`main` debe permanecer estable.

Cada cambio comienza en Issue y rama breve, salvo auditoría de sólo lectura.

Usar Conventional Commits.

Los commits deben ser intencionales y corresponder a unidades lógicas del cambio.

No crear commits separados para cada intento, error tipográfico o ajuste mecánico. Los commits `WIP`, `fixup` o equivalentes deben consolidarse antes del merge, ya sea reorganizando la rama o mediante squash merge.

No fusionar cambios no relacionados en un mismo commit únicamente para reducir la cantidad de commits. Las divisiones que faciliten revisión, rollback o trazabilidad pueden conservarse.

El Pull Request debe indicar:

- objetivo;
- causa;
- alcance;
- contratos o documentos afectados;
- ambientes modificados;
- pruebas y resultados;
- riesgos;
- rollback;
- limitaciones;
- Issue, LCD y ADR relacionados.

La descripción del PR debe ser completa pero directa. Debe evitar:

- repetir el diff archivo por archivo sin aportar contexto;
- narrar cada llamada de herramienta o intento intermedio;
- incluir logs completos cuando basta una referencia o extracto relevante;
- repetir información idéntica en varias secciones;
- afirmar validaciones sin evidencia.

La concisión no autoriza omitir impacto, pruebas, ambientes, riesgos, rollback o limitaciones.

No reescribir historia publicada para ocultar errores.

Un commit registra cambios, pero no constituye aprobación por sí solo.

El diff debe revisarse para detectar:

- archivos accidentales;
- secretos;
- PII;
- cambios fuera de alcance;
- pruebas eliminadas;
- configuraciones relajadas;
- artefactos generados no intencionales.

## 14. Excepciones

Una excepción técnica no puede aprobarse implícitamente.

Debe registrar:

- regla exceptuada;
- motivo;
- superficie;
- riesgo;
- mitigación;
- Issue;
- responsable o condición de revisión;
- criterio de retiro.

Las excepciones permanentes requieren una decisión explícita y no pueden esconderse en una configuración global.

## 15. Criterio de finalización

Un cambio sólo puede declararse terminado cuando:

- se trató la causa dentro del alcance;
- los contratos afectados están identificados;
- las pruebas aplicables pasan;
- la documentación necesaria está actualizada;
- no se introdujo deuda silenciosa;
- las excepciones están registradas;
- no existen archivos accidentales;
- el diff fue revisado;
- los ambientes afectados están declarados;
- las limitaciones restantes poseen Issue;
- el resultado real coincide con lo informado.

El cierre debe distinguir:

- qué se modificó;
- qué no;
- qué se validó;
- qué no pudo validarse;
- ambientes afectados;
- evidencia;
- riesgos y pendientes.

## 16. Cumplimiento automático

Las reglas automatizables deben trasladarse gradualmente a configuración, pruebas y CI.

Secuencia preferida:

Regla canónica → configuración técnica → check reproducible → evidencia en PR.

Issue #56 gobierna la adopción gradual de quality gates. Ningún control debe hacerse bloqueante antes de comprobar compatibilidad con el estado real del repositorio.
