#!/usr/bin/env python3
"""Generate an exact, auditable monthly-status backfill SQL file.

The generated artifact contains normalized RUTs and must remain local. It never
includes names, phones or email addresses and it never connects to Supabase.

Example:
    python tools/generate_monthly_status_backfill.py \
      --source 2026-04="local-data/abril.xlsx" \
      --source 2026-05="local-data/mayo.xlsx" \
      --output "local-data/lcd-20260715-01.backfill.sql"
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
import unicodedata
import zipfile
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from xml.etree import ElementTree as ET

MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"

MONTHS_ES = {
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

HEADER_ALIASES = {
    "rut": {"rut", "rut candidato", "rut cliente"},
    "status": {"gestionado", "estado", "estado origen", "estado corporativo"},
    "campaign": {"nombre de campana", "campana", "campaign name"},
    "month": {"mes", "periodo", "period"},
}


@dataclass(frozen=True)
class SourceSpec:
    period: str
    path: Path


@dataclass(frozen=True)
class BackfillRow:
    rut_norm: str
    period: str
    campaign_key: str
    estado_origen: str
    source_name: str
    source_sha256: str
    source_row: int


def strip_accents(value: str) -> str:
    return "".join(
        char
        for char in unicodedata.normalize("NFKD", value)
        if not unicodedata.combining(char)
    )


def normalize_header(value: object) -> str:
    text = strip_accents(str(value or "")).lower().strip()
    return re.sub(r"[^a-z0-9]+", " ", text).strip()


def normalize_rut(value: object) -> str:
    rut = re.sub(r"[^0-9kK]", "", str(value or "")).upper()
    if len(rut) < 2:
        raise ValueError(f"RUT vacío o inválido: {value!r}")
    return rut


def normalize_status(value: object) -> str:
    status = normalize_header(value).replace("  ", " ")
    if status == "gestionado":
        return "Gestionado"
    if status in {"no gestionado", "nogestionado"}:
        return "No Gestionado"
    raise ValueError(f"Estado corporativo inválido: {value!r}")


def normalize_campaign_key(value: object) -> str:
    """Mirror dev/index.html slug() exactly for campaign_key matching."""
    text = strip_accents(str(value or "")).lower()
    normalized = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return normalized or "sin-campana"


def validate_period(value: str) -> str:
    if not re.fullmatch(r"\d{4}-(0[1-9]|1[0-2])", value):
        raise argparse.ArgumentTypeError(f"Período inválido: {value!r}; use AAAA-MM")
    return value


def parse_source(value: str) -> SourceSpec:
    if "=" not in value:
        raise argparse.ArgumentTypeError("--source debe usar PERIODO=RUTA")
    period, raw_path = value.split("=", 1)
    return SourceSpec(validate_period(period.strip()), Path(raw_path.strip()).expanduser())


def column_index(cell_ref: str) -> int:
    letters = re.match(r"[A-Z]+", cell_ref.upper())
    if not letters:
        raise ValueError(f"Referencia de celda XLSX inválida: {cell_ref}")
    value = 0
    for char in letters.group(0):
        value = value * 26 + ord(char) - 64
    return value - 1


def shared_strings(archive: zipfile.ZipFile) -> list[str]:
    try:
        root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    except KeyError:
        return []
    result: list[str] = []
    for item in root.findall(f"{{{MAIN_NS}}}si"):
        result.append("".join(node.text or "" for node in item.iter(f"{{{MAIN_NS}}}t")))
    return result


def worksheet_path(archive: zipfile.ZipFile, requested_sheet: str | None) -> str:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    rel_targets = {
        rel.attrib["Id"]: rel.attrib["Target"]
        for rel in relationships.findall(f"{{{PKG_REL_NS}}}Relationship")
    }
    sheets = workbook.find(f"{{{MAIN_NS}}}sheets")
    if sheets is None:
        raise ValueError("El XLSX no contiene hojas")
    candidates: list[tuple[str, str]] = []
    for sheet in sheets.findall(f"{{{MAIN_NS}}}sheet"):
        name = sheet.attrib["name"]
        rel_id = sheet.attrib[f"{{{REL_NS}}}id"]
        candidates.append((name, rel_targets[rel_id]))
    if requested_sheet:
        selected = next((item for item in candidates if item[0] == requested_sheet), None)
        if selected is None:
            available = ", ".join(name for name, _ in candidates)
            raise ValueError(f"Hoja {requested_sheet!r} no encontrada. Disponibles: {available}")
    else:
        selected = candidates[0]
    target = PurePosixPath(selected[1])
    if target.is_absolute():
        return str(target).lstrip("/")
    return str(PurePosixPath("xl") / target)


def read_xlsx(path: Path, sheet_name: str | None) -> list[list[object]]:
    with zipfile.ZipFile(path) as archive:
        strings = shared_strings(archive)
        root = ET.fromstring(archive.read(worksheet_path(archive, sheet_name)))
        rows: list[list[object]] = []
        for row in root.iter(f"{{{MAIN_NS}}}row"):
            values: dict[int, object] = {}
            for cell in row.findall(f"{{{MAIN_NS}}}c"):
                index = column_index(cell.attrib.get("r", "A1"))
                cell_type = cell.attrib.get("t")
                if cell_type == "inlineStr":
                    value: object = "".join(
                        node.text or "" for node in cell.iter(f"{{{MAIN_NS}}}t")
                    )
                else:
                    value_node = cell.find(f"{{{MAIN_NS}}}v")
                    raw = "" if value_node is None else value_node.text or ""
                    if cell_type == "s" and raw:
                        value = strings[int(raw)]
                    elif cell_type == "b":
                        value = raw == "1"
                    else:
                        value = raw
                values[index] = value
            if values:
                width = max(values) + 1
                rows.append([values.get(index, "") for index in range(width)])
        return rows


def read_csv(path: Path) -> list[list[object]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        sample = handle.read(8192)
        handle.seek(0)
        try:
            dialect = csv.Sniffer().sniff(sample, delimiters=",;\t")
        except csv.Error:
            dialect = csv.excel
        return [list(row) for row in csv.reader(handle, dialect)]


def read_table(path: Path, sheet_name: str | None) -> list[list[object]]:
    suffix = path.suffix.lower()
    if suffix == ".xlsx":
        return read_xlsx(path, sheet_name)
    if suffix == ".csv":
        return read_csv(path)
    raise ValueError(f"Formato no soportado: {path.name}; use .xlsx o .csv")


def find_header(rows: list[list[object]]) -> tuple[int, dict[str, int]]:
    for row_index, row in enumerate(rows):
        normalized = [normalize_header(value) for value in row]
        found: dict[str, int] = {}
        for logical_name, aliases in HEADER_ALIASES.items():
            for index, header in enumerate(normalized):
                if header in aliases:
                    found[logical_name] = index
                    break
        if {"rut", "status", "campaign"}.issubset(found):
            return row_index, found
    raise ValueError("No se encontraron las columnas RUT, Gestionado/Estado y Nombre de Campaña")


def month_matches(value: object, period: str) -> bool:
    text = normalize_header(value)
    target_month = int(period[5:7])
    if not text:
        return True
    if text in MONTHS_ES:
        return MONTHS_ES[text] == target_month
    match = re.search(r"(?:\d{4}[-/])?(\d{1,2})$", text)
    if match:
        return int(match.group(1)) == target_month
    raise ValueError(f"No se pudo interpretar el mes {value!r} para {period}")


def cell(row: list[object], index: int) -> object:
    return row[index] if index < len(row) else ""


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_source(spec: SourceSpec, sheet_name: str | None) -> list[BackfillRow]:
    if not spec.path.is_file():
        raise FileNotFoundError(spec.path)
    rows = read_table(spec.path, sheet_name)
    header_index, columns = find_header(rows)
    digest = file_sha256(spec.path)
    extracted: list[BackfillRow] = []
    for source_row, row in enumerate(rows[header_index + 1 :], start=header_index + 2):
        if not any(str(value or "").strip() for value in row):
            continue
        if "month" in columns and not month_matches(cell(row, columns["month"]), spec.period):
            continue
        rut_raw = cell(row, columns["rut"])
        status_raw = cell(row, columns["status"])
        campaign_raw = cell(row, columns["campaign"])
        if not str(rut_raw or "").strip() and not str(status_raw or "").strip():
            continue
        extracted.append(
            BackfillRow(
                rut_norm=normalize_rut(rut_raw),
                period=spec.period,
                campaign_key=normalize_campaign_key(campaign_raw),
                estado_origen=normalize_status(status_raw),
                source_name=spec.path.name,
                source_sha256=digest,
                source_row=source_row,
            )
        )
    if not extracted:
        raise ValueError(f"{spec.path.name}: no se encontraron filas para {spec.period}")
    return extracted


def sql_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def validate_rows(rows: list[BackfillRow]) -> list[BackfillRow]:
    by_key: dict[tuple[str, str, str], BackfillRow] = {}
    for row in rows:
        key = (row.rut_norm, row.period, row.campaign_key)
        prior = by_key.get(key)
        if prior and prior.estado_origen != row.estado_origen:
            raise ValueError(
                "Conflicto de estado para "
                f"RUT={row.rut_norm}, período={row.period}, campaña={row.campaign_key}: "
                f"{prior.estado_origen} vs {row.estado_origen}"
            )
        by_key[key] = row
    return sorted(by_key.values(), key=lambda row: (row.period, row.campaign_key, row.rut_norm))


def render_sql(rows: list[BackfillRow], sources: list[SourceSpec]) -> str:
    source_manifest = [
        {
            "period": source.period,
            "file": source.path.name,
            "sha256": file_sha256(source.path),
        }
        for source in sources
    ]
    values = ",\n".join(
        "  ("
        + ", ".join(
            (
                sql_literal(row.rut_norm),
                sql_literal(row.period),
                sql_literal(row.campaign_key),
                sql_literal(row.estado_origen),
                sql_literal(row.source_name),
                sql_literal(row.source_sha256),
                str(row.source_row),
            )
        )
        + ")"
        for row in rows
    )
    managed = sum(row.estado_origen == "Gestionado" for row in rows)
    pending = sum(row.estado_origen == "No Gestionado" for row in rows)
    periods = sorted({row.period for row in rows})
    return f"""-- SENSITIVE LOCAL ARTIFACT · DO NOT COMMIT
-- Generated by tools/generate_monthly_status_backfill.py
-- LCD: LCD-20260715-01
-- Rows: {len(rows)} · Gestionado: {managed} · No Gestionado: {pending}
-- Periods: {', '.join(periods)}
-- Sources: {json.dumps(source_manifest, ensure_ascii=False, sort_keys=True)}
-- This script updates only estado_origen through exact RUT + period + campaign matching.

begin;
set local statement_timeout = '5min';

create temporary table _monthly_status_backfill (
  rut_norm text not null,
  period text not null,
  campaign_key text not null,
  estado_origen text not null check (estado_origen in ('Gestionado','No Gestionado')),
  source_name text not null,
  source_sha256 text not null,
  source_row integer not null,
  primary key (rut_norm,period,campaign_key)
) on commit drop;

insert into _monthly_status_backfill(
  rut_norm,period,campaign_key,estado_origen,source_name,source_sha256,source_row
) values
{values};

do $preflight$
declare
  v_source integer;
  v_exact integer;
  v_ambiguous integer;
begin
  select count(*) into v_source from _monthly_status_backfill;

  select count(*) into v_ambiguous
  from (
    select b.rut_norm,b.period,b.campaign_key,count(*) as matches
    from _monthly_status_backfill b
    join public.contacts ct on ct.rut_norm=b.rut_norm
    join public.campaigns c on c.period=b.period and c.campaign_key=b.campaign_key
    join public.contact_month_state cms
      on cms.contact_id=ct.contact_id
     and cms.campaign_id=c.campaign_id
     and cms.period=b.period
    group by b.rut_norm,b.period,b.campaign_key
    having count(*) <> 1
  ) x;

  if v_ambiguous <> 0 then
    raise exception 'BACKFILL_ABORTED: existen % claves con más de una coincidencia exacta',v_ambiguous;
  end if;

  select count(*) into v_exact
  from _monthly_status_backfill b
  where exists (
    select 1
    from public.contacts ct
    join public.campaigns c on c.period=b.period and c.campaign_key=b.campaign_key
    join public.contact_month_state cms
      on cms.contact_id=ct.contact_id
     and cms.campaign_id=c.campaign_id
     and cms.period=b.period
    where ct.rut_norm=b.rut_norm
  );

  if v_exact <> v_source then
    raise exception
      'BACKFILL_ABORTED: sólo % de % filas tienen coincidencia exacta RUT + período + campaña',
      v_exact,v_source;
  end if;
end
$preflight$;

do $apply$
declare
  v_expected integer;
  v_updated integer;
begin
  select count(*) into v_expected from _monthly_status_backfill;

  update public.contact_month_state cms
     set estado_origen=b.estado_origen
    from _monthly_status_backfill b
    join public.contacts ct on ct.rut_norm=b.rut_norm
    join public.campaigns c on c.period=b.period and c.campaign_key=b.campaign_key
   where cms.contact_id=ct.contact_id
     and cms.campaign_id=c.campaign_id
     and cms.period=b.period;

  get diagnostics v_updated = row_count;
  if v_updated <> v_expected then
    raise exception 'BACKFILL_ABORTED: se actualizaron % de % filas',v_updated,v_expected;
  end if;
end
$apply$;

select public.rebuild_work_queue_for_period(public.active_period()) as rebuild_result;

select jsonb_build_object(
  'status','PASS',
  'lcd','LCD-20260715-01',
  'updated_rows',(select count(*) from _monthly_status_backfill),
  'periods',(select jsonb_agg(period order by period) from (select distinct period from _monthly_status_backfill) p),
  'gestionado',(select count(*) from _monthly_status_backfill where estado_origen='Gestionado'),
  'no_gestionado',(select count(*) from _monthly_status_backfill where estado_origen='No Gestionado'),
  'active_period',public.active_period(),
  'active_visible_queue',(select count(*) from public.work_queue where period=public.active_period() and visible)
) as backfill_evidence;

commit;
"""


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        action="append",
        required=True,
        type=parse_source,
        metavar="PERIODO=RUTA",
        help="Fuente mensual; puede repetirse. Ejemplo: 2026-04=local-data/abril.xlsx",
    )
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--sheet", help="Nombre de hoja; por defecto usa la primera")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    output: Path = args.output.expanduser()
    if output.suffixes[-2:] != [".backfill", ".sql"]:
        raise SystemExit("El archivo de salida debe terminar en .backfill.sql")

    extracted: list[BackfillRow] = []
    for source in args.source:
        extracted.extend(extract_source(source, args.sheet))
    rows = validate_rows(extracted)

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_sql(rows, args.source), encoding="utf-8", newline="\n")
    print(
        json.dumps(
            {
                "status": "PASS",
                "output": str(output),
                "rows": len(rows),
                "periods": sorted({row.period for row in rows}),
                "gestionado": sum(row.estado_origen == "Gestionado" for row in rows),
                "no_gestionado": sum(row.estado_origen == "No Gestionado" for row in rows),
                "contains_names_phones_emails": False,
                "database_accessed": False,
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
