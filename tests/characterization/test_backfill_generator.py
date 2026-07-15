from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "generate_monthly_status_backfill.py"

spec = importlib.util.spec_from_file_location("monthly_status_backfill", SCRIPT)
if spec is None or spec.loader is None:  # pragma: no cover - defensive import guard
    raise RuntimeError(f"No se pudo cargar {SCRIPT}")
backfill = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = backfill
spec.loader.exec_module(backfill)


def inline_cell(reference: str, value: str) -> str:
    escaped = (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    return f'<c r="{reference}" t="inlineStr"><is><t>{escaped}</t></is></c>'


def write_fixture_xlsx(path: Path) -> None:
    rows = [
        ["Mes", "Nombre de Campaña", "RUT", "Gestionado", "Nombre", "Teléfono 1", "Correo electrónico"],
        ["Abril", "Campaña Abril", "12.345.678-K", "No Gestionado", "Persona Secreta", "+56911111111", "secret@example.com"],
        ["Mayo", "Campaña Mayo", "9.876.543-2", "Gestionado", "Otra Persona", "+56922222222", "other@example.com"],
    ]
    sheet_rows: list[str] = []
    for row_number, row in enumerate(rows, start=1):
        cells = []
        for column_number, value in enumerate(row, start=1):
            number = column_number
            letters = ""
            while number:
                number, remainder = divmod(number - 1, 26)
                letters = chr(65 + remainder) + letters
            cells.append(inline_cell(f"{letters}{row_number}", value))
        sheet_rows.append(f'<row r="{row_number}">{"".join(cells)}</row>')

    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr(
            "xl/workbook.xml",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            '<sheets><sheet name="Datos" sheetId="1" r:id="rId1"/></sheets></workbook>',
        )
        archive.writestr(
            "xl/_rels/workbook.xml.rels",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
            'Target="worksheets/sheet1.xml"/></Relationships>',
        )
        archive.writestr(
            "xl/worksheets/sheet1.xml",
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            f'<sheetData>{"".join(sheet_rows)}</sheetData></worksheet>',
        )


class BackfillGeneratorTests(unittest.TestCase):
    def test_xlsx_month_filter_and_minimal_sensitive_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "fuente.xlsx"
            write_fixture_xlsx(source)

            rows = backfill.extract_source(
                backfill.SourceSpec("2026-04", source),
                None,
            )
            self.assertEqual(1, len(rows))
            self.assertEqual("12345678K", rows[0].rut_norm)
            self.assertEqual("campana-abril", rows[0].campaign_key)
            self.assertEqual("No Gestionado", rows[0].estado_origen)

            sql = backfill.render_sql(rows, [backfill.SourceSpec("2026-04", source)])
            self.assertIn("12345678K", sql)
            self.assertIn("No Gestionado", sql)
            self.assertNotIn("Persona Secreta", sql)
            self.assertNotIn("+56911111111", sql)
            self.assertNotIn("secret@example.com", sql)
            self.assertIn("coincidencia exacta RUT + período + campaña", sql)

    def test_conflicting_duplicate_is_rejected(self) -> None:
        base = backfill.BackfillRow(
            rut_norm="12345678K",
            period="2026-04",
            campaign_key="campana-abril",
            estado_origen="No Gestionado",
            source_name="a.xlsx",
            source_sha256="a" * 64,
            source_row=2,
        )
        conflict = backfill.BackfillRow(
            rut_norm=base.rut_norm,
            period=base.period,
            campaign_key=base.campaign_key,
            estado_origen="Gestionado",
            source_name="b.xlsx",
            source_sha256="b" * 64,
            source_row=3,
        )
        with self.assertRaisesRegex(ValueError, "Conflicto de estado"):
            backfill.validate_rows([base, conflict])

    def test_campaign_normalization_matches_app_slug_contract(self) -> None:
        cases = {
            "Campaña Abril": "campana-abril",
            "  Oportunidades de Negocio - Abril 2026  ": "oportunidades-de-negocio-abril-2026",
            "CAMPAÑA   ÁÉÍÓÚ Ñ": "campana-aeiou-n",
            "---": "sin-campana",
            "": "sin-campana",
        }
        for raw, expected in cases.items():
            with self.subTest(raw=raw):
                self.assertEqual(expected, backfill.normalize_campaign_key(raw))


if __name__ == "__main__":
    unittest.main()
