#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / 'dev' / 'index.html'


def fail(message: str) -> None:
    raise SystemExit(f'Estado asignados DEV inválido: {message}')


def main() -> None:
    html = INDEX.read_text(encoding='utf-8')
    checks = {
        'estado Gestionado definido': "gestionado:{label:'Gestionado'" in html,
        'mapeo Gestionado definido': "gestionado:'Gestionado'" in html,
        'filtro Gestionado disponible': "['gestionado','Gestionado']" in html,
        'Gestionado no editable manualmente': "k!=='pendiente'&&k!=='gestionado'" in html,
        'Pendiente sigue definido': "pendiente:{label:'Pendiente'" in html,
    }
    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        fail(', '.join(failed))
    print('PASS: estado importado Gestionado representado sin volverlo seleccionable manualmente')


if __name__ == '__main__':
    main()
