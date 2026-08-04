from pathlib import Path
import importlib.util
import sys
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "normalize_campaign_bases.py"


def load_module():
    spec = importlib.util.spec_from_file_location("normalize_campaign_bases", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


HTML = """<html><body><table>
<tr>
  <th>Nombre Candidato de Campaña</th><th>RUT</th>
  <th>Teléfono 1</th><th>Teléfono 2</th><th>Teléfono 3</th>
  <th>Correo electrónico</th><th>Gestionado</th>
  <th>Nombre de Campaña</th><th>Descripción Campaña</th>
</tr>
<tr>
  <td>Persona Uno</td><td>12.345.678-5</td>
  <td>1</td><td></td><td></td><td></td><td>No Gestionado</td>
  <td>Campaña julio 2026</td><td>Primera</td>
</tr>
<tr>
  <td>Persona Dos</td><td>9.876.543-K</td>
  <td>2</td><td></td><td></td><td></td><td>Gestionado</td>
  <td>Campaña agosto 2026</td><td>Segunda</td>
</tr>
</table></body></html>"""


class NormalizeCampaignBasesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module = load_module()

    def test_mixed_period_mode_uses_one_canonical_tool(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "campanas_mezcladas.xls"
            source.write_text(HTML, encoding="latin-1")

            result = self.module.normalize_file(source, no_dates=True)

            self.assertTrue(result.passed, result.errors)
            self.assertEqual(result.rows_written, 2)
            self.assertEqual(result.output.name, "campanas_mezcladas_NM_SF.xlsx")

            with zipfile.ZipFile(result.output) as archive:
                sheet = archive.read("xl/worksheets/sheet1.xml").decode("utf-8")
            self.assertNotIn(">Fecha<", sheet)
            self.assertIn(">Nombre Candidato de Campaña<", sheet)
            self.assertIn('autoFilter ref="A1:I3"', sheet)

    def test_strict_mode_rejects_mixed_campaign_periods(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "202608_TOTAL_01.xls"
            source.write_text(HTML, encoding="latin-1")

            result = self.module.normalize_file(source)

            self.assertFalse(result.passed)
            self.assertTrue(
                any("no coincide con 2026-08" in error for error in result.errors),
                result.errors,
            )


if __name__ == "__main__":
    unittest.main()
