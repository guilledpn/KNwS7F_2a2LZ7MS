from __future__ import annotations

import hashlib
import json
import os
import secrets
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Sequence

from issue63_revision_02_model import *  # noqa: F401,F403

def _manifest(total: ParsedFile, assigned: ParsedFile) -> list[dict[str,object]]:
    return [{"file_name":p.spec.file_name,"load_type":p.spec.load_type,"xlsx_sha256":p.xlsx_sha256,
      "payload_sha256":p.payload_sha256,"expected_rows":len(p.payload_lines),
      "expected_distinct_ruts":p.distinct_ruts,"expected_status_counts":p.status_counts,
      "expected_campaign_counts":p.campaign_counts} for p in (total,assigned)]
def _sql_literal(value: object) -> str: return "'"+json.dumps(value,ensure_ascii=False,separators=(",",":" )).replace("'","''")+"'::jsonb"
def prepare_runtime(total: ParsedFile, assigned: ParsedFile, output: Path, hours: int) -> dict[str,object]:
    if not 1<=hours<=72: raise ValueError("La expiración del runtime debe estar entre 1 y 72 horas")
    output.mkdir(parents=True,exist_ok=True); token_path=output/".issue63_token"
    sql_path=output/"issue63_configure_runtime.sql"; manifest_path=output/"issue63_runtime_manifest.json"
    if any(p.exists() for p in (token_path,sql_path,manifest_path)): raise ValueError("El runtime ya existe; no se sobrescribe")
    token=secrets.token_urlsafe(48); token_hash=sha256_bytes(token.encode())
    expires=datetime.now(timezone.utc)+timedelta(hours=hours); manifest=_manifest(total,assigned)
    sql=("select issue63_ops.configure_operation("+",\n  ".join([
      "'"+OPERATION_KEY+"'","'"+PERIOD+"'","'"+token_hash+"'",
      "'"+expires.isoformat()+"'::timestamptz",_sql_literal(manifest),_sql_literal(PROD_PRIOR_STATE)])+");\n")
    token_path.write_text(token,encoding="utf-8"); os.chmod(token_path,0o600)
    sql_path.write_text(sql,encoding="utf-8")
    public={"issue":ISSUE,"operation_key":OPERATION_KEY,"expires_at":expires.isoformat(),
      "files":[total.public_summary(),assigned.public_summary()],"contains_pii":False,"contains_token":False}
    manifest_path.write_text(json.dumps(public,ensure_ascii=False,indent=2),encoding="utf-8")
    return public

class RpcClient:
    def __init__(self,url: str,key: str,token: str): self.url=url.rstrip("/"); self.key=key; self.token=token
    def call(self,name: str,payload: dict[str,object],timeout: int=90) -> dict[str,object]:
        req=urllib.request.Request(f"{self.url}/rest/v1/rpc/{name}",data=json.dumps(payload).encode(),method="POST",
          headers={"apikey":self.key,"Authorization":f"Bearer {self.key}","Content-Type":"application/json"})
        try:
            with urllib.request.urlopen(req,timeout=timeout) as response: data=json.loads(response.read().decode())
        except (urllib.error.HTTPError,urllib.error.URLError,TimeoutError) as exc:
            detail=getattr(exc,"read",lambda:b"")().decode(errors="replace")
            raise RuntimeError(f"RPC {name} falló: {exc}; {detail[:500]}") from exc
        if not isinstance(data,dict) or data.get("ok") is not True: raise RuntimeError(f"Respuesta RPC inválida: {data}")
        return data
    def status(self): return self.call("crm_issue63_status",{"p_token":self.token},180)
    def stage(self,p: ParsedFile,start: int,lines: Sequence[str]):
        tsv="\n".join(lines)
        return self.call("crm_issue63_stage_chunk",{"p_token":self.token,"p_file_name":p.spec.file_name,
          "p_load_type":p.spec.load_type,"p_period":PERIOD,"p_xlsx_sha256":p.xlsx_sha256,
          "p_start_order":start,"p_chunk_sha256":sha256_bytes(tsv.encode()),"p_tsv":tsv})

def _progress(status: dict[str,object],name: str) -> int:
    files=status.get("files",[])
    if isinstance(files,list):
        for item in files:
            if isinstance(item,dict) and item.get("file_name")==name: return int(item.get("contiguous_rows",0))
    return 0
def stage_file(client: RpcClient,p: ParsedFile,chunk_size: int=500) -> dict[str,object]:
    done=_progress(client.status(),p.spec.file_name); started=time.monotonic()
    while done<len(p.payload_lines):
        end=min(done+chunk_size,len(p.payload_lines)); result=client.stage(p,done+1,p.payload_lines[done:end])
        new=int(result.get("contiguous_rows",0))
        if new<=done: raise RuntimeError("El progreso remoto no avanzó")
        done=new
        if done%5000==0 or done==len(p.payload_lines): print(f"{p.spec.file_name}: {done:,}/{len(p.payload_lines):,}")
    return {"file_name":p.spec.file_name,"staged_rows":done,"elapsed_seconds":round(time.monotonic()-started,2)}

def write_report(path: Path|None,value: dict[str,object]):
    if path: path.write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding="utf-8")
def _secret(cli: str|None,env: str) -> str:
    value=cli or os.environ.get(env,"")
    if not value: raise ValueError(f"Falta {env}")
    return value