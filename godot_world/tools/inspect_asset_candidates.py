#!/usr/bin/env python3
"""Inspect downloaded intake GLBs and emit a non-approval inventory report."""
from pathlib import Path
import json, struct, sys
root=Path(__file__).resolve().parents[1]
receipt=root/"assets"/"asset_download_receipt.json"
if not receipt.exists(): sys.exit("Missing download receipt; intake step must run first.")
records=json.loads(receipt.read_text(encoding="utf-8"))
if not records: sys.exit("Receipt is empty.")
def glb_json(p):
 d=p.read_bytes()
 if len(d)<20: raise ValueError("truncated")
 magic,version,total=struct.unpack_from("<4sII",d,0)
 if magic!=b"glTF" or version!=2 or total!=len(d): raise ValueError("invalid header/length")
 off=12
 while off+8<=len(d):
  n,typ=struct.unpack_from("<II",d,off); off+=8
  chunk=d[off:off+n];off+=n
  if len(chunk)!=n: raise ValueError("truncated chunk")
  if typ==0x4E4F534A: return json.loads(chunk.decode("utf-8").rstrip("\0 \t\r\n"))
 raise ValueError("missing JSON chunk")
report=[]
for r in records:
 p=root/r["path"]
 if not p.is_file(): raise SystemExit(f"Missing candidate file: {p}")
 doc=glb_json(p)
 if not doc.get("meshes") or not doc.get("nodes"): raise SystemExit(f"No mesh/nodes: {p}")
 report.append({"path":r["path"],"bytes":p.stat().st_size,"mesh_count":len(doc["meshes"]),"node_count":len(doc["nodes"]),"skin_count":len(doc.get("skins",[])),"animation_count":len(doc.get("animations",[])),"material_count":len(doc.get("materials",[])),"texture_count":len(doc.get("textures",[])),"structural":"pass","visual_qa":"pending"})
out=root/"assets"/"asset_candidate_structure_report.json"
out.write_text(json.dumps(report,indent=2),encoding="utf-8")
print(f"GLB candidate structural inspection PASS: {len(report)} files; visual approval remains pending.")
