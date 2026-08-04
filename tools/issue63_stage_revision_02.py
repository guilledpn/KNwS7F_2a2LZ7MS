#!/usr/bin/env python3
"""CLI del staging controlado del Issue #63."""
from __future__ import annotations

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from issue63_revision_02_model import *  # noqa: F401,F403
from issue63_revision_02_runtime import *  # noqa: F401,F403
from issue63_revision_02_runtime import _secret

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__); sub=parser.add_subparsers(dest="cmd",required=True)
    def files(p): p.add_argument("--total",type=Path,default=Path(TOTAL_SPEC.file_name)); p.add_argument("--assigned",type=Path,default=Path(ASSIGNED_SPEC.file_name))
    p=sub.add_parser("validate"); files(p); p.add_argument("--report",type=Path)
    p=sub.add_parser("prepare-runtime"); files(p); p.add_argument("--output-dir",type=Path,required=True); p.add_argument("--expires-hours",type=int,default=24)
    p=sub.add_parser("stage"); files(p); p.add_argument("--token-file",type=Path,required=True); p.add_argument("--supabase-url"); p.add_argument("--anon-key"); p.add_argument("--report",type=Path,default=Path("issue63_stage_report.json"))
    p=sub.add_parser("status"); p.add_argument("--token-file",type=Path,required=True); p.add_argument("--supabase-url"); p.add_argument("--anon-key")
    args=parser.parse_args()
    try:
        if args.cmd in ("validate","prepare-runtime","stage"):
            total,assigned,relationship=validate_inputs(args.total,args.assigned)
        if args.cmd=="validate":
            report={"issue":ISSUE,"mode":"validation_only","files":[total.public_summary(),assigned.public_summary()],"relationship":relationship,"network_used":False,"prod_modified":False,"contains_pii":False}; write_report(args.report,report); print(json.dumps(report,ensure_ascii=False,indent=2)); return 0
        if args.cmd=="prepare-runtime":
            if not 1<=args.expires_hours<=72: raise ValueError("--expires-hours debe estar entre 1 y 72")
            print(json.dumps(prepare_runtime(total,assigned,args.output_dir,args.expires_hours),ensure_ascii=False,indent=2)); return 0
        token=args.token_file.read_text(encoding="utf-8").strip()
        if len(token)<40: raise ValueError("Token temporal inválido")
        client=RpcClient(_secret(args.supabase_url,"ISSUE63_SUPABASE_URL"),_secret(args.anon_key,"ISSUE63_ANON_KEY"),token)
        if args.cmd=="status": print(json.dumps(client.status(),ensure_ascii=False,indent=2)); return 0
        before=client.status(); uploads=[stage_file(client,total),stage_file(client,assigned)]; after=client.status()
        report={"issue":ISSUE,"mode":"stage_only","remote_before":before,"uploads":uploads,"remote_after":after,"canonical_apply_executed":False,"contains_pii":False,"contains_credentials":False}; write_report(args.report,report); print(json.dumps(report,ensure_ascii=False,indent=2)); return 0
    except (ValueError,RuntimeError,FileNotFoundError,zipfile.BadZipFile) as exc:
        print(f"ERROR: {exc}",file=sys.stderr); return 1

if __name__=="__main__": raise SystemExit(main())
