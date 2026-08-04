# LCD-20260804-04 · Refuerzo de estándares de ingeniería

- Estado: Aprobado
- Fecha: 2026-08-04
- Issue: #61
- Pull Request: #62
- ADR: No corresponde

## Motivo

Los Estándares de Desarrollo ya prohibían deuda técnica silenciosa, exigían validaciones proporcionales y establecían controles generales para Supabase, Git y Legacy. Sin embargo, cuatro áreas podían generar retrabajo o decisiones inseguras:

1. RLS, permisos, vistas y funciones privilegiadas no estaban especificados con suficiente precisión;
2. faltaba una regla completa para gestionar incertidumbre sin inventar contratos o dependencias;
3. la estructura física transitoria podía confundirse con la estructura objetivo;
4. no se distinguía entre commits lógicos y ruido de intentos o descripciones de PR excesivas.

## Decisión

Actualizar `docs/engineering/development-standards.md` y `AGENTS.md` con reglas que:

- exijan RLS y políticas explícitas para tablas en esquemas expuestos;
- separen RLS, `GRANT` y exposición mediante Data API;
- protejan vistas y funciones privilegiadas;
- obliguen a buscar evidencia antes de asumir;
- detengan sólo el trabajo dependiente cuando falte contexto;
- clasifiquen archivos por responsabilidad real antes de moverlos o modificarlos;
- mantengan commits lógicos y consoliden ruido antes del merge;
- exijan PR completos pero directos.

## Salvaguardas de expedición

Estas reglas no deben convertirse en burocracia automática.

- No se detiene trabajo independiente por una incertidumbre localizada.
- No se pregunta al usuario si la evidencia puede obtenerse del repositorio.
- No se exige squash de commits que faciliten revisión, rollback o trazabilidad.
- No se vuelve bloqueante un quality gate sin validar compatibilidad.
- No se presume que la estructura objetivo ya está implementada.
- Los fixes productivos pequeños conservan su vía de emergencia y rollback.

## Fundamento Supabase

La documentación vigente de Supabase distingue:

- permisos `GRANT`, que determinan si un rol puede acceder al objeto;
- RLS, que determina qué filas puede ver o modificar;
- exposición mediante Data API, cuya configuración y valores predeterminados pueden variar;
- vistas `security_invoker`, que respetan RLS de las tablas subyacentes;
- funciones `security definer`, que requieren `search_path`, permisos y justificación explícita.

El estándar no depende de un valor predeterminado de la plataforma: exige comprobar el estado real del proyecto.

## Impacto

- Constitución: sin cambios.
- Arquitectura: sin cambios.
- Modelo del Dominio: sin cambios.
- Backlog y Roadmap: sin cambios.
- Código de aplicación y SQL: sin cambios.
- Supabase, LOCAL, DEV, STAGING y PROD: sin cambios.
- Contratos de runtime: sin cambios.

## Resultado esperado

Reducir:

- permisos inseguros;
- soluciones basadas en supuestos;
- cambios sobre archivos o artefactos equivocados;
- commits y PR con ruido;
- correcciones posteriores por contexto no verificado.

No se promete eliminar todos los errores. El beneficio esperado proviene de prevenir errores repetibles sin bloquear el avance seguro.
