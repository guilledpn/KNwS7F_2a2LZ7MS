#!/usr/bin/env python3
"""Valida y carga sólo a staging los XLSX del Issue #63.

No ejecuta la aplicación canónica, rollback ni cleanup. No incluye credenciales.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import secrets
import sys
import time
import unicodedata
import urllib.error
import urllib.request
import zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Sequence

ISSUE = 63
OPERATION_KEY = "issue63-202608-revision-02"
PERIOD = "2026-08"
NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
HEADERS = ["Fecha", "Nombre Candidato de Campaña", "RUT", "Teléfono 1", "Teléfono 2", "Teléfono 3", "Correo electrónico", "Gestionado", "Nombre de Campaña", "Descripción Campaña"]
EMPTY_TOKENS = {"", "nan", "none", "null", "undefined"}

@dataclass(frozen=True)
class FileSpec:
    file_name: str; load_type: str; expected_rows: int; expected_distinct_ruts: int
    expected_xlsx_sha256: str; expected_payload_sha256: str
    expected_status_counts: dict[str, int]; expected_campaign_counts: dict[str, int]

TOTAL_SPEC = FileSpec(
    "202608_TOTAL_02_NM.xlsx", "mensual", 84912, 84912,
    "116747cccbbf6e53385ee33e60af28d82dfa6b9201dcce6dfa2ecc611e2e9cdd",
    "81937bbf332fa38aef9d35ce112b7589a5cc5b6ed2083dd94cd05b8b8a42e6ef",
    {"Gestionado":2448,"No Gestionado":82464},
    {
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-ciclo-de-vida-proteccion":11999,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-profesionales":13416,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-propension-integral":56367,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-joven":2243,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-senior":887,
    },
)
ASSIGNED_SPEC = FileSpec(
    "202608_ASIGNADO_02_NM.xlsx", "asignado", 198, 198,
    "43ee1a00187cdef2f43d0b73f813ccd88146ab6d727e833726c37f44632c7019",
    "201fe3e8b7fc559ba9410be3fa5fc1071ec04294a5fa484307a05cff9da17e76",
    {"No Gestionado":198},
    {
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-ciclo-de-vida-proteccion":34,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-profesionales":15,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-propension-integral":145,
      "campanas-de-asesoria-con-conversion-fuerza-de-ventas-agosto-2026-segmento-joven":4,
    },
)
PROD_PRIOR_STATE = {
 "active_period":"2026-08","period_cms_rows":28186,"period_all_cms_rows":28186,
 "period_distinct_contacts":28186,"period_assigned_rows":54,"period_campaigns":4,
 "public_staging_rows":0,"total_existing_pairs":28186,"total_added_pairs":56726,
 "total_removed_pairs":0,"status_no_gestionado_to_gestionado":2260,
 "assigned_added":145,"assigned_removed":1,"assigned_common":53,
 "containment_event_id":7960,"containment_snapshot_id":"ISSUE43-PROD-2026-08-V1",
 "containment_rows":286,
}

@dataclass(frozen=True)
class ParsedFile:
    spec: FileSpec; path: Path; payload_lines: tuple[str,...]; xlsx_sha256: str
    payload_sha256: str; distinct_ruts: int; status_counts: dict[str,int]
    campaign_counts: dict[str,int]
    def public_summary(self) -> dict[str,object]:
        return {"file_name":self.spec.file_name,"load_type":self.spec.load_type,
          "rows":len(self.payload_lines),"distinct_ruts":self.distinct_ruts,
          "xlsx_sha256":self.xlsx_sha256,"payload_sha256":self.payload_sha256,
          "status_counts":dict(sorted(self.status_counts.items())),
          "campaign_counts":dict(sorted(self.campaign_counts.items()))}

def sha256_bytes(value: bytes) -> str: return hashlib.sha256(value).hexdigest()
def sha256_file(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""): h.update(chunk)
    return h.hexdigest()
def clean_text(value: object) -> str:
    text=str(value or "").replace("\t"," ").replace("\r"," ").replace("\n"," ")
    text=re.sub(r"\s+"," ",text).strip()
    return "" if text.lower() in EMPTY_TOKENS else text
def normalize_rut(value: object) -> str: return re.sub(r"[^0-9Kk]","",clean_text(value)).upper()
def format_rut(value: str) -> str: return f"{value[:-1]}-{value[-1]}"
def normalize_phone(value: object) -> str:
    text=clean_text(value).lower()
    if text in EMPTY_TOKENS: return ""
    digits=re.sub(r"\D","",re.sub(r"\.0+$","",text))
    if not digits.startswith("56") and len(digits)==10 and digits.endswith("0"): digits=digits[:-1]
    if len(digits)<8: return ""
    if not digits.startswith("56"): digits="56"+digits
    return "+"+digits
def clean_campaign_description(value: object) -> str:
    text=re.sub(r"^\s*\d+\s*[\.\-\)\:]\s*","",clean_text(value)).strip().lower()
    return text[:1].upper()+text[1:] if text else ""
def slug(value: object) -> str:
    text=unicodedata.normalize("NFD",clean_text(value).lower())
    text="".join(c for c in text if unicodedata.category(c)!="Mn")
    return re.sub(r"[^a-z0-9]+","-",text).strip("-") or "sin-campana"
def _col(ref: str) -> int:
    n=0
    for c in "".join(x for x in ref if x.isalpha()).upper(): n=n*26+ord(c)-64
    return n-1

def read_xlsx(path: Path) -> list[list[str]]:
    with zipfile.ZipFile(path) as z:
        bad=z.testzip()
        if bad: raise ValueError(f"XLSX corrupto: {bad}")
        shared=[]
        if "xl/sharedStrings.xml" in z.namelist():
            root=ET.fromstring(z.read("xl/sharedStrings.xml"))
            shared=["".join(n.text or "" for n in item.iter(NS+"t")) for item in root.findall(NS+"si")]
        root=ET.fromstring(z.read("xl/worksheets/sheet1.xml")); rows=[]
        for row in root.findall(".//"+NS+"row"):
            cells={}
            for cell in row.findall(NS+"c"):
                ref=cell.attrib.get("r",""); typ=cell.attrib.get("t"); node=cell.find(NS+"v")
                if typ=="inlineStr": value="".join(n.text or "" for n in cell.iter(NS+"t"))
                elif node is None: value=""
                elif typ=="s": value=shared[int(node.text or "0")]
                else: value=node.text or ""
                cells[_col(ref)]=value
            rows.append([cells.get(i,"") for i in range(10)])
        return rows

def parse_file(path: Path, spec: FileSpec) -> ParsedFile:
    if path.name!=spec.file_name: raise ValueError(f"Nombre inválido: {path.name}")
    xhash=sha256_file(path)
    if xhash!=spec.expected_xlsx_sha256: raise ValueError(f"Hash XLSX inválido para {path.name}")
    rows=read_xlsx(path)
    if [clean_text(x) for x in rows[0]]!=HEADERS: raise ValueError(f"Encabezados inválidos en {path.name}")
    lines=[]; ruts=set(); statuses={}; campaigns={}
    for source_row,row in enumerate(rows[1:],1):
        if not any(clean_text(v) for v in row): continue
        period=clean_text(row[0])
        if period!=PERIOD: raise ValueError(f"Período inválido en fila {source_row+1}: {period}")
        rut=normalize_rut(row[2])
        if not re.fullmatch(r"[0-9]+[0-9K]",rut): raise ValueError(f"RUT inválido en fila {source_row+1}")
        if rut in ruts: raise ValueError(f"RUT duplicado en {path.name}")
        ruts.add(rut)
        status=clean_text(row[7])
        if status not in ("Gestionado","No Gestionado"): raise ValueError(f"Estado inválido en fila {source_row+1}")
        cname=clean_text(row[8]); cdesc=clean_campaign_description(row[9])
        if not cname or not cdesc: raise ValueError(f"Campaña incompleta en fila {source_row+1}")
        campaign_name=f"{cname} · {cdesc}"
        ckey=slug(campaign_name)
        fields=[rut,format_rut(rut),clean_text(row[1]),normalize_phone(row[3]),normalize_phone(row[4]),
          normalize_phone(row[5]),clean_text(row[6]).lower(),campaign_name,cdesc,ckey,status]
        lines.append("\t".join(fields)); statuses[status]=statuses.get(status,0)+1
        campaigns[ckey]=campaigns.get(ckey,0)+1
    payload="\n".join(lines).encode()
    result=ParsedFile(spec,path,tuple(lines),xhash,sha256_bytes(payload),len(ruts),statuses,campaigns)
    if len(lines)!=spec.expected_rows or len(ruts)!=spec.expected_distinct_ruts: raise ValueError(f"Conteo inválido en {path.name}")
    if result.payload_sha256!=spec.expected_payload_sha256: raise ValueError(f"Hash payload inválido en {path.name}")
    if statuses!=spec.expected_status_counts or campaigns!=spec.expected_campaign_counts: raise ValueError(f"Distribución inválida en {path.name}")
    return result

def validate_relationship(total: ParsedFile, assigned: ParsedFile) -> dict[str,int]:
    total_by_rut={line.split("\t",1)[0]:line for line in total.payload_lines}
    missing=0; mismatches=0
    for line in assigned.payload_lines:
        rut=line.split("\t",1)[0]
        if rut not in total_by_rut: missing+=1
        elif total_by_rut[rut]!=line: mismatches+=1
    if missing or mismatches: raise ValueError(f"ASIGNADO no es subconjunto exacto: missing={missing}, mismatches={mismatches}")
    return {"missing":missing,"field_mismatches":mismatches}

def validate_inputs(total_path: Path, assigned_path: Path):
    total=parse_file(total_path,TOTAL_SPEC); assigned=parse_file(assigned_path,ASSIGNED_SPEC)
    return total,assigned,validate_relationship(total,assigned)
