#!/usr/bin/env python3
"""Valida unicidad y referencias mínimas de la gobernanza documental.

No usa red, secretos ni datos de clientes. Sale con código distinto de cero cuando
encuentra una colisión que debe bloquear el merge.
"""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LCD_REGISTRY = ROOT / "docs/governance/lcd-registry.md"
ADR_REGISTRY = ROOT / "docs/governance/adr-registry.md"
AUTHORITY = ROOT / "docs/governance/document-authority.md"
CATALOG = ROOT / "docs/governance/document-catalog.md"
AGENTS = ROOT / "AGENTS.md"

LCD_PATTERN = re.compile(r"^\|\s*(LCD-\d{8}-\d{2})\s*\|", re.MULTILINE)
ADR_ROW_PATTERN = re.compile(r"^\|\s*(ADR-\d{3})\s*\|", re.MULTILINE)
ADR_HEADING_PATTERN = re.compile(r"^#\s+(ADR-\d{3})\s+·", re.MULTILINE)


def read(path: Path) -> str:
    if not path.is_file():
        raise AssertionError(f"Falta archivo obligatorio: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def duplicates(values: list[str]) -> list[str]:
    counts = Counter(values)
    return sorted(value for value, count in counts.items() if count > 1)


def main() -> int:
    errors: list[str] = []

    try:
        lcd_text = read(LCD_REGISTRY)
        adr_text = read(ADR_REGISTRY)
        authority_text = read(AUTHORITY)
        catalog_text = read(CATALOG)
        agents_text = read(AGENTS)
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        return 1

    lcd_ids = LCD_PATTERN.findall(lcd_text)
    adr_ids = ADR_ROW_PATTERN.findall(adr_text)

    for duplicate in duplicates(lcd_ids):
        errors.append(f"LCD duplicado en registro: {duplicate}")
    for duplicate in duplicates(adr_ids):
        errors.append(f"ADR duplicado en registro: {duplicate}")

    if not lcd_ids:
        errors.append("El registro LCD no contiene identificadores")
    if not adr_ids:
        errors.append("El registro ADR no contiene identificadores")

    canonical_adr_files: dict[str, list[Path]] = {}
    for path in (ROOT / "docs").rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        for adr_id in ADR_HEADING_PATTERN.findall(text):
            canonical_adr_files.setdefault(adr_id, []).append(path)

    for adr_id, paths in sorted(canonical_adr_files.items()):
        if adr_id not in adr_ids:
            joined = ", ".join(str(path.relative_to(ROOT)) for path in paths)
            errors.append(f"{adr_id} tiene documento canónico pero no registro: {joined}")
        if len(paths) > 1:
            joined = ", ".join(str(path.relative_to(ROOT)) for path in paths)
            errors.append(f"{adr_id} tiene más de un documento canónico: {joined}")

    required_refs = {
        "AGENTS.md": agents_text,
        "document-authority.md": authority_text,
        "document-catalog.md": catalog_text,
    }
    for name, text in required_refs.items():
        for required in ("lcd-registry.md", "adr-registry.md"):
            if required not in text and name != "document-catalog.md":
                errors.append(f"{name} no referencia {required}")

    alias_018 = read(ROOT / "docs/adr/ADR-018-monorepo-y-transicion-legacy-next.md")
    alias_019 = read(ROOT / "docs/adr/ADR-019-docs-as-code-y-separacion-git-drive.md")
    if ADR_HEADING_PATTERN.search(alias_018):
        errors.append("El alias histórico ADR-018 se presenta como ADR canónica")
    if ADR_HEADING_PATTERN.search(alias_019):
        errors.append("El alias histórico ADR-019 se presenta como ADR canónica")
    if "ADR-021" not in alias_018:
        errors.append("El alias ADR-018 no apunta a ADR-021")
    if "ADR-022" not in alias_019:
        errors.append("El alias ADR-019 no apunta a ADR-022")

    if errors:
        print("DOCUMENT GOVERNANCE: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print("DOCUMENT GOVERNANCE: PASS")
    print(f"LCD registrados: {len(lcd_ids)}")
    print(f"ADR registrados: {len(adr_ids)}")
    print(f"ADR con archivo canónico en GitHub: {len(canonical_adr_files)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
