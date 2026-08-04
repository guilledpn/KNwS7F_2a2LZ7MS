#!/usr/bin/env python3
"""
Normalizador de bases de campañas APP LLAMADOS / CRM Patrimonial.

Entrada esperada:
    AAAAMM_TOTAL_NN.xls
    AAAAMM_ASIGNADO_NN.xls
    o cualquier .xls con --sin-fechas

El .xls descargado es una tabla HTML. El programa:
- permite seleccionar varios archivos;
- extrae únicamente el texto del nombre del contacto;
- elimina enlaces incompletos;
- en modo normal agrega la columna Fecha con formato AAAA-MM;
- en modo sin fechas acepta campañas de distintos períodos y omite Fecha;
- convierte "nan" en vacío;
- valida columnas, resultado corporativo y fecha de campaña;
- genera un .xlsx normalizado sin modificar el original.

Salida:
    AAAAMM_TOTAL_NN_NM.xlsx
    AAAAMM_ASIGNADO_NN_NM.xlsx
    NOMBRE_ORIGINAL_NM_SF.xlsx (modo sin fechas)

No requiere paquetes externos: utiliza únicamente Python estándar.
"""

from __future__ import annotations

import codecs
import csv
import html
import re
import sys
import tempfile
import unicodedata
import zipfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Callable, Iterable
from xml.sax.saxutils import escape as xml_escape

APP_TITLE = "Normalizador de bases de campañas"

INPUT_PATTERN = re.compile(
    r"^(?P<periodo>\d{6})_(?P<tipo>TOTAL|ASIGNADO)_(?P<revision>\d{2})\.xls$",
    re.IGNORECASE,
)

CANONICAL_COLUMNS = [
    "Fecha",
    "Nombre Candidato de Campaña",
    "RUT",
    "Teléfono 1",
    "Teléfono 2",
    "Teléfono 3",
    "Correo electrónico",
    "Gestionado",
    "Nombre de Campaña",
    "Descripción Campaña",
]

SOURCE_COLUMNS = CANONICAL_COLUMNS[1:]

MONTHS = {
    "enero": 1,
    "febrero": 2,
    "marzo": 3,
    "abril": 4,
    "mayo": 5,
    "junio": 6,
    "julio": 7,
    "agosto": 8,
    "septiembre": 9,
    "setiembre": 9,
    "octubre": 10,
    "noviembre": 11,
    "diciembre": 12,
}

MONTH_PATTERN = re.compile(
    r"\b(" + "|".join(MONTHS.keys()) + r")\s+(20\d{2})\b",
    re.IGNORECASE,
)

EMPTY_TOKENS = {"", "nan", "none", "null"}

HEADER_ALIASES = {
    "nombrecandidatodecampana": "Nombre Candidato de Campaña",
    "nombrecandidatocampana": "Nombre Candidato de Campaña",
    "rut": "RUT",
    "telefono1": "Teléfono 1",
    "telefono2": "Teléfono 2",
    "telefono3": "Teléfono 3",
    "correoelectronico": "Correo electrónico",
    "email": "Correo electrónico",
    "gestionado": "Gestionado",
    "nombredecampana": "Nombre de Campaña",
    "nombrecampana": "Nombre de Campaña",
    "descripcioncampana": "Descripción Campaña",
    "descripciondecampana": "Descripción Campaña",
}


class NormalizationError(Exception):
    """Error esperado de validación o normalización."""


@dataclass
class FileResult:
    source: Path
    output: Path | None = None
    rows_read: int = 0
    rows_written: int = 0
    errors: list[str] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not self.errors and self.output is not None


def strip_accents(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in normalized if not unicodedata.combining(ch))


def normalize_header(value: str) -> str:
    value = strip_accents(clean_text(value)).lower()
    return re.sub(r"[^a-z0-9]+", "", value)


def strip_embedded_tags(value: str) -> str:
    """Extrae el texto de etiquetas HTML que vienen escapadas dentro de una celda."""
    value = html.unescape(value)
    anchor = re.search(r"<a\b[^>]*>(.*?)</a>", value, flags=re.IGNORECASE | re.DOTALL)
    if anchor:
        value = anchor.group(1)
    value = re.sub(r"<[^>]+>", " ", value)
    return html.unescape(value)


def clean_text(value: object) -> str:
    if value is None:
        return ""
    text = strip_embedded_tags(str(value))
    # Corrección observada en una exportación corporativa con codificación mixta.
    text = text.replace("\u00e3\u008d", "Í")
    text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]", " ", text)
    text = (
        text.replace("\xa0", " ")
        .replace("\u200b", "")
        .replace("\ufeff", "")
    )
    text = re.sub(r"\s+", " ", text).strip()
    if text.lower() in EMPTY_TOKENS:
        return ""
    return text


def normalize_rut(value: str) -> str:
    value = clean_text(value).upper()
    value = value.replace(".", "").replace(" ", "")
    if not value:
        return ""
    if "-" not in value and len(value) >= 2:
        value = f"{value[:-1]}-{value[-1]}"
    return value


def normalize_phone(value: str) -> str:
    value = clean_text(value)
    if re.fullmatch(r"\d+\.0", value):
        return value[:-2]
    return value


def normalize_status(value: str) -> str:
    raw = clean_text(value)
    key = strip_accents(raw).lower()
    key = re.sub(r"\s+", " ", key).strip()
    if key == "gestionado":
        return "Gestionado"
    if key == "no gestionado":
        return "No Gestionado"
    raise NormalizationError(f"resultado corporativo inválido: {raw!r}")


def period_from_filename(path: Path) -> tuple[str, str, str]:
    match = INPUT_PATTERN.fullmatch(path.name)
    if not match:
        raise NormalizationError(
            "nombre inválido; debe cumplir AAAAMM_TOTAL_NN.xls "
            "o AAAAMM_ASIGNADO_NN.xls"
        )

    raw_period = match.group("periodo")
    year = int(raw_period[:4])
    month = int(raw_period[4:])

    if year < 2000 or not 1 <= month <= 12:
        raise NormalizationError(f"período inválido en el nombre: {raw_period}")

    return f"{year:04d}-{month:02d}", match.group("tipo").upper(), match.group("revision")


def output_path_for(path: Path, no_dates: bool = False) -> tuple[Path, str | None]:
    """Resuelve la salida y el período sin mantener dos normalizadores."""
    if path.suffix.lower() != ".xls":
        raise NormalizationError("el archivo de entrada debe tener extensión .xls")

    if no_dates:
        return path.with_name(f"{path.stem}_NM_SF.xlsx"), None

    period, file_type, revision = period_from_filename(path)
    output = path.with_name(
        f"{period.replace('-', '')}_{file_type}_{revision}_NM.xlsx"
    )
    return output, period


def periods_in_campaign_text(*values: str) -> set[str]:
    periods: set[str] = set()
    for value in values:
        normalized = strip_accents(clean_text(value)).lower()
        for month_name, year_text in MONTH_PATTERN.findall(normalized):
            month = MONTHS[month_name.lower()]
            periods.add(f"{int(year_text):04d}-{month:02d}")
    return periods


class CampaignHTMLParser(HTMLParser):
    """Parser incremental para tablas HTML grandes."""

    def __init__(self, on_row: Callable[[list[str], bool], None]) -> None:
        super().__init__(convert_charrefs=True)
        self.on_row = on_row
        self.in_row = False
        self.in_cell = False
        self.current_is_header = False
        self.current_cell: list[str] = []
        self.current_row: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        if tag == "tr":
            self.in_row = True
            self.current_row = []
            self.current_is_header = False
        elif self.in_row and tag in {"td", "th"}:
            self.in_cell = True
            self.current_cell = []
            if tag == "th":
                self.current_is_header = True
        elif self.in_cell and tag == "br":
            self.current_cell.append(" ")

    def handle_data(self, data: str) -> None:
        if self.in_cell:
            self.current_cell.append(data)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if self.in_cell and tag in {"td", "th"}:
            self.current_row.append("".join(self.current_cell))
            self.current_cell = []
            self.in_cell = False
        elif tag == "tr" and self.in_row:
            if self.current_row:
                self.on_row(self.current_row, self.current_is_header)
            self.current_row = []
            self.in_row = False
            self.in_cell = False


def read_html_table(
    path: Path,
    on_row: Callable[[list[str], bool], None],
) -> None:
    with path.open("rb") as source:
        beginning = source.read(4096)
        source.seek(0)

        lowered = beginning.lstrip().lower()
        if b"<table" not in lowered and b"<html" not in lowered and b"<head" not in lowered:
            raise NormalizationError(
                "el archivo no parece ser la tabla HTML descargada con extensión .xls"
            )

        parser = CampaignHTMLParser(on_row)
        decoder = codecs.getincrementaldecoder("latin-1")(errors="strict")

        while True:
            chunk = source.read(1024 * 1024)
            if not chunk:
                break
            parser.feed(decoder.decode(chunk))

        parser.feed(decoder.decode(b"", final=True))
        parser.close()


def excel_column_name(index: int) -> str:
    result = ""
    while index:
        index, remainder = divmod(index - 1, 26)
        result = chr(65 + remainder) + result
    return result


def cell_xml(reference: str, value: str, style_id: int = 0) -> str:
    escaped = xml_escape(value)
    preserve = ' xml:space="preserve"' if value[:1].isspace() or value[-1:].isspace() else ""
    style = f' s="{style_id}"' if style_id else ""
    return (
        f'<c r="{reference}" t="inlineStr"{style}>'
        f'<is><t{preserve}>{escaped}</t></is></c>'
    )


def write_xlsx_from_csv(
    csv_path: Path,
    output_path: Path,
    include_date: bool = True,
) -> int:
    """Genera un XLSX mínimo y compatible usando sólo la biblioteca estándar."""
    temp_dir = Path(tempfile.mkdtemp(prefix="normalizador_xlsx_"))
    worksheet_path = temp_dir / "sheet1.xml"
    row_count = 0

    try:
        with csv_path.open("r", encoding="utf-8", newline="") as source, worksheet_path.open(
            "w", encoding="utf-8", newline=""
        ) as target:
            reader = csv.reader(source)
            target.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
            target.write(
                '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            )
            target.write(
                '<sheetViews><sheetView workbookViewId="0">'
                '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
                '</sheetView></sheetViews>'
            )
            if include_date:
                target.write(
                    '<cols>'
                    '<col min="1" max="1" width="11" customWidth="1"/>'
                    '<col min="2" max="2" width="34" customWidth="1"/>'
                    '<col min="3" max="3" width="14" customWidth="1"/>'
                    '<col min="4" max="6" width="16" customWidth="1"/>'
                    '<col min="7" max="7" width="32" customWidth="1"/>'
                    '<col min="8" max="8" width="16" customWidth="1"/>'
                    '<col min="9" max="9" width="62" customWidth="1"/>'
                    '<col min="10" max="10" width="34" customWidth="1"/>'
                    '</cols>'
                )
            else:
                target.write(
                    '<cols>'
                    '<col min="1" max="1" width="34" customWidth="1"/>'
                    '<col min="2" max="2" width="14" customWidth="1"/>'
                    '<col min="3" max="5" width="16" customWidth="1"/>'
                    '<col min="6" max="6" width="32" customWidth="1"/>'
                    '<col min="7" max="7" width="16" customWidth="1"/>'
                    '<col min="8" max="8" width="62" customWidth="1"/>'
                    '<col min="9" max="9" width="34" customWidth="1"/>'
                    '</cols>'
                )
            target.write("<sheetData>")

            for row_count, row in enumerate(reader, start=1):
                target.write(f'<row r="{row_count}">')
                style_id = 1 if row_count == 1 else 0
                for column_index, value in enumerate(row, start=1):
                    reference = f"{excel_column_name(column_index)}{row_count}"
                    target.write(cell_xml(reference, value, style_id))
                target.write("</row>")

            target.write("</sheetData>")
            if row_count:
                last_column = "J" if include_date else "I"
                target.write(f'<autoFilter ref="A1:{last_column}{row_count}"/>')
            target.write("</worksheet>")

        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>"""

        root_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>"""

        workbook = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Datos" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>"""

        workbook_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>"""

        styles = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font><sz val="11"/><name val="Calibri"/><family val="2"/></font>
    <font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/><family val="2"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF44546A"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2">
    <xf numFmtId="49" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
    <xf numFmtId="49" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyNumberFormat="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
  </cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>"""

        core = f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:dcmitype="http://purl.org/dc/dcmitype/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>Normalizador APP LLAMADOS</dc:creator>
  <cp:lastModifiedBy>Normalizador APP LLAMADOS</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified>
</cp:coreProperties>"""

        app = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
 xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Normalizador APP LLAMADOS</Application>
</Properties>"""

        output_path.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("[Content_Types].xml", content_types)
            archive.writestr("_rels/.rels", root_rels)
            archive.writestr("xl/workbook.xml", workbook)
            archive.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
            archive.writestr("xl/styles.xml", styles)
            archive.write(worksheet_path, "xl/worksheets/sheet1.xml")
            archive.writestr("docProps/core.xml", core)
            archive.writestr("docProps/app.xml", app)

        return max(row_count - 1, 0)
    finally:
        try:
            worksheet_path.unlink(missing_ok=True)
            temp_dir.rmdir()
        except OSError:
            pass


def normalize_file(
    path: Path,
    overwrite: bool = False,
    no_dates: bool = False,
) -> FileResult:
    result = FileResult(source=path)

    try:
        output, period = output_path_for(path, no_dates=no_dates)
        result.output = output

        if output.exists() and not overwrite:
            raise NormalizationError(
                f"la salida ya existe: {output.name}. "
                "Elimine o mueva esa copia antes de repetir la normalización."
            )

        header_map: dict[str, int] | None = None
        temp_csv_handle = tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            newline="",
            suffix=".csv",
            prefix="normalizador_",
            delete=False,
        )
        temp_csv_path = Path(temp_csv_handle.name)
        writer = csv.writer(temp_csv_handle, lineterminator="\n")
        output_columns = CANONICAL_COLUMNS[1:] if no_dates else CANONICAL_COLUMNS
        writer.writerow(output_columns)

        validation_errors: list[str] = []
        max_error_examples = 20

        def record_error(message: str) -> None:
            if len(validation_errors) < max_error_examples:
                validation_errors.append(message)

        def on_row(cells: list[str], is_header: bool) -> None:
            nonlocal header_map
            cells = [clean_text(cell) for cell in cells]

            if is_header and header_map is None:
                mapped: dict[str, int] = {}
                for index, cell in enumerate(cells):
                    canonical = HEADER_ALIASES.get(normalize_header(cell))
                    if canonical and canonical not in mapped:
                        mapped[canonical] = index

                missing = [column for column in SOURCE_COLUMNS if column not in mapped]
                if missing:
                    raise NormalizationError(
                        "faltan columnas obligatorias: " + ", ".join(missing)
                    )

                header_map = mapped
                return

            if header_map is None:
                return

            if not any(cells):
                return

            result.rows_read += 1
            row_number = result.rows_read + 1

            def get(column: str) -> str:
                index = header_map[column]
                return cells[index] if index < len(cells) else ""

            try:
                name = clean_text(get("Nombre Candidato de Campaña"))
                rut = normalize_rut(get("RUT"))
                phone_1 = normalize_phone(get("Teléfono 1"))
                phone_2 = normalize_phone(get("Teléfono 2"))
                phone_3 = normalize_phone(get("Teléfono 3"))
                email = clean_text(get("Correo electrónico"))
                status = normalize_status(get("Gestionado"))
                campaign_name = clean_text(get("Nombre de Campaña"))
                campaign_description = clean_text(get("Descripción Campaña"))

                if not name:
                    raise NormalizationError("nombre vacío")
                if not rut:
                    raise NormalizationError("RUT vacío")
                if not campaign_name and not campaign_description:
                    raise NormalizationError("nombre y descripción de campaña vacíos")

                if not no_dates:
                    internal_periods = periods_in_campaign_text(
                        campaign_name,
                        campaign_description,
                    )
                    if not internal_periods:
                        raise NormalizationError(
                            "no se pudo identificar mes y año en nombre o descripción de campaña"
                        )
                    if internal_periods != {period}:
                        raise NormalizationError(
                            "fecha interna "
                            + ", ".join(sorted(internal_periods))
                            + f" no coincide con {period}"
                        )

                normalized_row = [
                    name,
                    rut,
                    phone_1,
                    phone_2,
                    phone_3,
                    email,
                    status,
                    campaign_name,
                    campaign_description,
                ]
                if not no_dates:
                    normalized_row.insert(0, period or "")
                writer.writerow(normalized_row)
                result.rows_written += 1
            except NormalizationError as exc:
                record_error(f"fila {row_number}: {exc}")

        try:
            read_html_table(path, on_row)
        finally:
            temp_csv_handle.close()

        if header_map is None:
            raise NormalizationError("no se encontró una fila de encabezados")

        if result.rows_read == 0:
            raise NormalizationError("el archivo no contiene filas de datos")

        if validation_errors:
            result.errors.extend(validation_errors)
            extra = result.rows_read - result.rows_written - len(validation_errors)
            if extra > 0:
                result.errors.append(f"... y {extra} errores adicionales")
            result.output = None
            temp_csv_path.unlink(missing_ok=True)
            return result

        written = write_xlsx_from_csv(
            temp_csv_path,
            output,
            include_date=not no_dates,
        )
        temp_csv_path.unlink(missing_ok=True)

        if written != result.rows_written:
            raise NormalizationError(
                f"control interno inconsistente: {result.rows_written} filas normalizadas "
                f"y {written} filas escritas"
            )

        return result

    except (OSError, UnicodeError, zipfile.BadZipFile, NormalizationError) as exc:
        result.errors.append(str(exc))
        result.output = None
        return result


def format_summary(results: Iterable[FileResult]) -> str:
    results = list(results)
    passed = sum(result.passed for result in results)
    lines = [
        f"Archivos seleccionados: {len(results)}",
        f"Normalizados correctamente: {passed}",
        f"Con errores: {len(results) - passed}",
        "",
    ]

    for result in results:
        if result.passed:
            lines.extend(
                [
                    f"PASS · {result.source.name}",
                    f"  Filas: {result.rows_written}",
                    f"  Salida: {result.output.name if result.output else ''}",
                    "",
                ]
            )
        else:
            lines.append(f"ERROR · {result.source.name}")
            for error in result.errors:
                lines.append(f"  - {error}")
            lines.append("")

    return "\n".join(lines).rstrip()


def select_files_gui() -> tuple[list[Path], bool, bool]:
    try:
        import tkinter as tk
        from tkinter import filedialog, messagebox
    except ImportError as exc:
        raise NormalizationError(
            "Tkinter no está disponible. Ejecute el script pasando los archivos por consola."
        ) from exc

    root = tk.Tk()
    root.withdraw()
    root.update()

    selected = filedialog.askopenfilenames(
        title="Seleccione una o más bases de campañas",
        filetypes=[
            ("Bases descargadas", "*.xls"),
            ("Todos los archivos", "*.*"),
        ],
    )

    if not selected:
        root.destroy()
        return [], False, False

    no_dates = messagebox.askyesno(
        APP_TITLE,
        "¿El archivo contiene campañas de distintos meses?\n\n"
        "Sí: modo sin fechas (omite Fecha y genera _NM_SF.xlsx).\n"
        "No: modo mensual estricto.",
    )

    overwrite = False
    existing_outputs = []
    for item in selected:
        path = Path(item)
        try:
            output, _ = output_path_for(path, no_dates=no_dates)
            if output.exists():
                existing_outputs.append(output.name)
        except NormalizationError:
            continue

    if existing_outputs:
        overwrite = messagebox.askyesno(
            APP_TITLE,
            "Ya existen copias normalizadas para algunos archivos:\n\n"
            + "\n".join(existing_outputs[:10])
            + ("\n..." if len(existing_outputs) > 10 else "")
            + "\n\n¿Desea reemplazarlas?",
        )

    root.destroy()
    return [Path(item) for item in selected], overwrite, no_dates


def show_summary_gui(summary: str, success: bool) -> None:
    try:
        import tkinter as tk
        from tkinter import messagebox
    except ImportError:
        print(summary)
        return

    root = tk.Tk()
    root.withdraw()
    root.update()
    if success:
        messagebox.showinfo(APP_TITLE, summary)
    else:
        messagebox.showwarning(APP_TITLE, summary)
    root.destroy()


def main() -> int:
    overwrite = "--overwrite" in sys.argv[1:]
    no_dates = any(
        argument in {"--sin-fechas", "--no-dates"}
        for argument in sys.argv[1:]
    )
    option_names = {"--overwrite", "--sin-fechas", "--no-dates"}
    cli_paths = [
        Path(argument)
        for argument in sys.argv[1:]
        if argument not in option_names
    ]

    try:
        if cli_paths:
            paths = cli_paths
        else:
            paths, gui_overwrite, gui_no_dates = select_files_gui()
            overwrite = overwrite or gui_overwrite
            no_dates = no_dates or gui_no_dates
            if not paths:
                return 0

        results = [
            normalize_file(
                path,
                overwrite=overwrite,
                no_dates=no_dates,
            )
            for path in paths
        ]
        summary = format_summary(results)
        print(summary)

        if not cli_paths:
            show_summary_gui(summary, all(result.passed for result in results))

        return 0 if all(result.passed for result in results) else 1

    except NormalizationError as exc:
        message = f"ERROR\n\n{exc}"
        print(message, file=sys.stderr)
        if not cli_paths:
            show_summary_gui(message, False)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
