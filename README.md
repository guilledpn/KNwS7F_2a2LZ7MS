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

## URL esperada

Cuando GitHub Pages esté activo, la app quedará en:

https://guilledpn.github.io/KNwS7F_2a2LZ7MS/

## Backend

La app sigue usando Supabase como backend:

- Auth
- Postgres
- RLS
- RPC

El repositorio es público y no contiene datos de contactos, bases de campaña, documentación reservada ni credenciales privadas.

## Publicación

GitHub Pages debe configurarse así:

- Source: Deploy from a branch
- Branch: main
- Folder: /root
