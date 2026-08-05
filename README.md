# APP LLAMADOS Legacy · CRM Patrimonial

Monorepo de transición para la PWA productiva APP LLAMADOS Legacy y el desarrollo gobernado de CRM Patrimonial Next.

## Entrada al proyecto

- Mapa: `PROJECT_MAP.md`
- Constitución: `docs/project/constitution.md`
- Arquitectura: `docs/architecture/crm-patrimonial.md`
- Modelo del Dominio: `docs/domain/README.md`
- Roadmap: `docs/project/backlog-roadmap.md`
- Autoridad documental: `docs/governance/document-authority.md`

GitHub contiene el conocimiento propio, código y pruebas. Drive se reserva para datos reales, fuentes externas, material corporativo y respaldos; no mantiene copias de estos documentos.

## Productos ejecutables

### APP LLAMADOS Legacy

La raíz del repositorio continúa siendo la fuente publicada de Legacy mientras no se apruebe otro mecanismo.

URL productiva esperada:

https://guilledpn.github.io/KNwS7F_2a2LZ7MS/

### CRM Patrimonial Next

La primera shell independiente vive en:

```text
apps/crm-patrimonial/
```

En Windows puede abrirse ejecutando:

```text
apps\crm-patrimonial\start-next.cmd
```

La shell usa datos ficticios, no se conecta a Legacy y todavía no implementa `next_v03`. La guía completa está en `docs/operations/next-environment-bootstrap.md`.

## Backend

Legacy continúa usando sus proyectos Supabase DEV y PROD.

Next tendrá proyectos Supabase completamente distintos para LOCAL, DEV, STAGING y PROD. La configuración local está versionada; los proyectos remotos aún no han sido creados y no se reutilizan endpoints Legacy.

El repositorio es público y no contiene datos de contactos, bases de campaña, documentación reservada ni credenciales privadas.

## Publicación Legacy

GitHub Pages debe continuar configurado así mientras Legacy permanezca operativo:

- Source: Deploy from a branch
- Branch: main
- Folder: /root
