#!/usr/bin/env python3
"""Contrato y validación local de los XLSX del Issue #63.

Este módulo no abre conexiones remotas ni modifica Supabase. Los archivos reales
permanecen fuera de Git y sólo se transforman en un payload TSV normalizado.
"""
from __future__ import annotations

import hashlib
import re
import unicodedata
import zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

ISSUE = 63
OPERATION_KEY = "issue63-202608-revision-02"
PERIOD = "2026-08"
NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
HEADERS = [
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
EMPTY_TOKENS = {"", "nan", "none", "null", "undefined"}


@dataclass(frozen=True)
class FileSpec:
    file_name: str
    load_type: str
    expected_rows: int
    expected_distinct_ruts: int
    expected_xlsx_sha256: str
    expected_payload_sha256: str
    expected_status_counts: dict[str, int]
    expected_campaign_counts: dict[str, int]


TOTAL_SPEC = FileSpec(
    file_name="202608_TOTAL_02_NM.xlsx",
    load_type="mensual",
    expected_rows=84_912,
    expected_distinct_ruts=84_912,
    expected_xlsx_sha256="116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd",
    expected_payload_sha256="81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef",
    expected_status_counts={"Gestionado": 2_448, "No Gestionado": 82_464},
    expected_campaign_counts={
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-ciclo-de-vida-proteccion": 11_999,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-profesionales": 13_416,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-propension-integral": 56_367,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-joven": 2_243,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-senior": 887,
    },
)

ASSIGNED_SPEC = FileSpec(
    file_name="202608_ASIGNADO_02_NM.xlsx",
    load_type="asignado",
    expected_rows=198,
    expected_distinct_ruts=198,
    expected_xlsx_sha256="43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019",
    expected_payload_sha256="201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76",
    expected_status_counts={"No Gestionado": 198},
    expected_campaign_counts={
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-ciclo-de-vida-proteccion": 34,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-profesionales": 15,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-propension-integral": 145,
        "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-joven": 4,
    },
)

PROD_PRIOR_STATE: dict[str, object] = {
    "active_period": "2026-08",
    "period_cms_rows": 28_186,
    "period_all_cms_rows": 28_186,
    "period_distinct_contacts": 28_186,
    "period_assigned_rows": 54,
    "period_campaigns": 4,
    "public_staging_rows": 0,
    "total_existing_pairs": 28_186,
    "total_added_pairs": 56_726,
    "total_removed_pairs": 0,
    "status_no_gestionado_to_gestionado": 2_260,
    "assigned_added": 145,
    "assigned_removed": 1,
    "assigned_common": 53,
    "containment_event_id": 7_960,
    "containment_snapshot_id": "ISSUE43-PROD-2026-08-V1",
    "containment_rows": 286,
}


@dataclass(frozen=True)
class ParsedFile:
    spec: FileSpec
    path: Path
    payload_lines: tuple[str, ...]
    xlsx_sha256: str
    payload_sha256: str
    distinct_ruts: int
    status_counts: dict[str, int]
    campaign_counts: dict[str, int]

    def public_summary(self) -> dict[str, object]:
        return {
            "file_name": self.spec.file_name,
            "load_type": self.spec.load_type,
            "rows": len(self.payload_lines),
            "distinct_ruts": self.distinct_ruts,
            "xlsx_sha256": self.xlsx_sha256,
            "payload_sha256": self.payload_sha256,
            "status_counts": dict(sorted(self.status_counts.items())),
            "campaign_counts": dict(sorted(self.campaign_counts.items())),
        }


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def clean_text(value: object) -> str:
    text = str(value or "").replace("\t", " ").replace("\r", " ").replace("\n", " ")
    text = re.sub(r"\s+", " ", text).strip()
    return "" if text.lower() in EMPTY_TOKENS else text


def normalize_rut(value: object) -> str:
    return re.sub(r"[^0-9Kk]", "", clean_text(value)).upper()


def format_rut(value: str) -> str:
    return f"{value[:-1]}-{value[-1]}"


def normalize_phone(value: object) -> str:
    text = clean_text(value).lower()
    if text in EMPTY_TOKENS:
        return ""
    digits = re.sub(r"\D", "", re.sub(r"\.0+$", "", text))
    if not digits.startswith("56") and len(digits) == 10 and digits.endswith("0"):
        digits = digits[:-1]
    if len(digits) < 8:
        return ""
    if not digits.startswith("56"):
        digits = "56" + digits
    return "+" + digits


def clean_campaign_description(value: object) -> str:
    text = re.sub(r"^\s*\d+\s*[\.\-\)\:]\s*", "", clean_text(value)).strip().lower()
    return text[:1].upper() + text[1:] if text else ""


def slug(value: object) -> str:
    text = unicodedata.normalize("NFD", clean_text(value).lower())
    text = "".join(character for character in text if unicodedata.category(character) != "Mn")
    return re.sub(r"[^a-z0-9]+", "-", text).strip("-") or "sin-campana"


def _column_index(reference: str) -> int:
    result = 0
    for character in "".join(value for value in reference if value.isalpha()).upper():
        result = result * 26 + ord(character) - 64
    return result - 1


def read_xlsx(path: Path) -> list[list[str]]:
    with zipfile.ZipFile(path) as archive:
        damaged = archive.testzip()
        if damaged:
            raise ValueError(f"XLSX corrupto: {damaged}")

        shared: list[str] = []
        if "xl/sharedStrings.xml" in archive.namelist():
            shared_root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            shared = [
                "".join(node.text or "" for node in item.iter(NS + "t"))
                for item in shared_root.findall(NS + "si")
            ]

        worksheet = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))
        rows: list[list[str]] = []
        for row in worksheet.findall(".//" + NS + "row"):
            cells: dict[int, str] = {}
            for cell in row.findall(NS + "c"):
                reference = cell.attrib.get("r", "")
                cell_type = cell.attrib.get("t")
                value_node = cell.find(NS + "v")
                if cell_type == "inlineStr":
                    value = "".join(node.text or "" for node in cell.iter(NS + "t"))
                elif value_node is None:
                    value = ""
                elif cell_type == "s":
                    value = shared[int(value_node.text or "0")]
                else:
                    value = value_node.text or ""
                cells[_column_index(reference)] = value
            rows.append([cells.get(index, "") for index in range(10)])
        return rows


def parse_file(path: Path, spec: FileSpec) -> ParsedFile:
    if path.name != spec.file_name:
        raise ValueError(f"Nombre inválido: {path.name}")

    xlsx_sha256 = sha256_file(path)
    if xlsx_sha256 != spec.expected_xlsx_sha256:
        raise ValueError(f"Hash XLSX inválido para {path.name}")

    rows = read_xlsx(path)
    if not rows or [clean_text(value) for value in rows[0]] != HEADERS:
        raise ValueError(f"Encabezados inválidos en {path.name}")

    payload_lines: list[str] = []
    distinct_ruts: set[str] = set()
    status_counts: dict[str, int] = {}
    campaign_counts: dict[str, int] = {}

    for source_row, row in enumerate(rows[1:], 1):
        if not any(clean_text(value) for value in row):
            continue
        period = clean_text(row[0])
        if period != PERIOD:
            raise ValueError(f"Período inválido en fila {source_row + 1}: {period}")

        rut_norm = normalize_rut(row[2])
        if not re.fullmatch(r"[0-9]+[0-9K]", rut_norm):
            raise ValueError(f"RUT inválido en fila {source_row + 1}")
        if rut_norm in distinct_ruts:
            raise ValueError(f"RUT duplicado en {path.name}")
        distinct_ruts.add(rut_norm)

        status = clean_text(row[7])
        if status not in ("Gestionado", "No Gestionado"):
            raise ValueError(f"Estado inválido en fila {source_row + 1}")

        base_campaign_name = clean_text(row[8])
        campaign_desc = clean_campaign_description(row[9])
        if not base_campaign_name or not campaign_desc:
            raise ValueError(f"Campaña incompleta en fila {source_row + 1}")
        campaign_name = f"{base_campaign_name} · {campaign_desc}"
        campaign_key = slug(campaign_name)

        fields = [
            rut_norm,
            format_rut(rut_norm),
            clean_text(row[1]),
            normalize_phone(row[3]),
            normalize_phone(row[4]),
            normalize_phone(row[5]),
            clean_text(row[6]).lower(),
            campaign_name,
            campaign_desc,
            campaign_key,
            status,
        ]
        payload_lines.append("\t".join(fields))
        status_counts[status] = status_counts.get(status, 0) + 1
        campaign_counts[campaign_key] = campaign_counts.get(campaign_key, 0) + 1

    payload_sha256 = sha256_bytes("\n".join(payload_lines).encode())
    result = ParsedFile(
        spec=spec,
        path=path,
        payload_lines=tuple(payload_lines),
        xlsx_sha256=xlsx_sha256,
        payload_sha256=payload_sha256,
        distinct_ruts=len(distinct_ruts),
        status_counts=status_counts,
        campaign_counts=campaign_counts,
    )

    if len(payload_lines) != spec.expected_rows or len(distinct_ruts) != spec.expected_distinct_ruts:
        raise ValueError(f"Conteo inválido en {path.name}")
    if result.payload_sha256 != spec.expected_payload_sha256:
        raise ValueError(f"Hash payload inválido en {path.name}")
    if status_counts != spec.expected_status_counts or campaign_counts != spec.expected_campaign_counts:
        raise ValueError(f"Distribución inválida en {path.name}")
    return result


def validate_relationship(total: ParsedFile, assigned: ParsedFile) -> dict[str, int]:
    total_by_rut = {line.split("\t", 1)[0]: line for line in total.payload_lines}
    missing = 0
    field_mismatches = 0
    for line in assigned.payload_lines:
        rut_norm = line.split("\t", 1)[0]
        if rut_norm not in total_by_rut:
            missing += 1
        elif total_by_rut[rut_norm] != line:
            field_mismatches += 1
    if missing or field_mismatches:
        raise ValueError(
            "ASIGNADO no es subconjunto exacto: "
            f"missing={missing}, field_mismatches={field_mismatches}"
        )
    return {"missing": missing, "field_mismatches": field_mismatches}


def validate_inputs(
    total_path: Path,
    assigned_path: Path,
) -> tuple[ParsedFile, ParsedFile, dict[str, int]]:
    total = parse_file(total_path, TOTAL_SPEC)
    assigned = parse_file(assigned_path, ASSIGNED_SPEC)
    return total, assigned, validate_relationship(total, assigned)
