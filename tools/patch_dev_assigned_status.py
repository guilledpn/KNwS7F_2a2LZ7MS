#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / 'dev' / 'index.html'


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: se esperaba 1 coincidencia y se encontraron {count}')
    return text.replace(old, new, 1)


def main() -> None:
    html = INDEX.read_text(encoding='utf-8')

    html = replace_once(
        html,
        "const STATE={\n  agenda:{label:'Agenda',color:'var(--success)',bg:'var(--success-container)'},",
        "const STATE={\n  gestionado:{label:'Gestionado',color:'var(--primary)',bg:'var(--primary-container)'},\n  agenda:{label:'Agenda',color:'var(--success)',bg:'var(--success-container)'},",
        'estado neutral Gestionado',
    )
    html = replace_once(
        html,
        "const LABEL_BY_KEY={agenda:'Agenda',no_agenda:'No agenda',volver:'Volver a llamar',no_contactado:'No contactado',invalido:'Contacto Inválido',pendiente:'Pendiente'};",
        "const LABEL_BY_KEY={gestionado:'Gestionado',agenda:'Agenda',no_agenda:'No agenda',volver:'Volver a llamar',no_contactado:'No contactado',invalido:'Contacto Inválido',pendiente:'Pendiente'};",
        'mapeo Gestionado',
    )
    html = replace_once(
        html,
        "{key:'estado',title:'Estado de gestión',opts:[['agenda','Agenda'],['no_agenda','No agenda'],['volver','Volver a llamar'],['no_contactado','No contactado'],['invalido','Inválido'],['pendiente','Pendiente']],dot:k=>(STATE[k]||{}).color},",
        "{key:'estado',title:'Estado de gestión',opts:[['gestionado','Gestionado'],['agenda','Agenda'],['no_agenda','No agenda'],['volver','Volver a llamar'],['no_contactado','No contactado'],['invalido','Inválido'],['pendiente','Pendiente']],dot:k=>(STATE[k]||{}).color},",
        'filtro Gestionado',
    )
    html = replace_once(
        html,
        "Object.entries(STATE).filter(([k])=>k!=='pendiente').map",
        "Object.entries(STATE).filter(([k])=>k!=='pendiente'&&k!=='gestionado').map",
        'estado neutral no editable',
    )

    INDEX.write_text(html, encoding='utf-8')


if __name__ == '__main__':
    main()
