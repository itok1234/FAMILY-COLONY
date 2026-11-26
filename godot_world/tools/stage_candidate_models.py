#!/usr/bin/env python3
"""Stage the 10 verified GLB intake candidates using explicit source metadata.
Creates a populated manifest for runtime smoke-test mounting; does NOT mark QA approved.
"""
from pathlib import Path
import json, shutil, struct, sys
ROOT=Path(__file__).resolve().parents[1]
INTAKE=ROOT/"intake-output"
SOURCE=ROOT/"assets"/"asset_sources.json"
DEST={"character":ROOT/"assets"/"characters","environment":ROOT/"assets"/"environment"}
MANIFEST=ROOT/"assets"/"production_asset_manifest.json"

def glb_json(p):
    data=p.read_bytes()
    if len(data)<20: raise ValueError("short GLB")
    magic,version,total=struct.unpack_from("<4sII",data)
    if magic!=b"glTF" or version!=2 or total!=len(data): raise ValueError("bad GLB header")
    off=12
    while off+8<=len(data):
        n,t=struct.unpack_from("<II",data,off);off+=8
        chunk=data[off:off+n];off+=n
        if len(chunk)!=n: raise ValueError("truncated chunk")
        if t==0x4E4F4F4A: return json.loads(chunk.decode("utf-8").rstrip(" \t\r\n\0"))
    raise ValueError("missing JSON chunk")

def main():
    if not INTAKE.is_dir() or not SOURCE.is_file(): print("Missing intake or source metadata");return 1
    sources=json.loads(SOURCE.read_text(encoding="utf-8"))
    byname={e["filename"]:e for e in sources}
    manifest={"character":[],"environment":[]}
    staged=0
    for src in sorted(INTAKE.glob("*.glb")):
        e=byname.get(src.name)
        if not e: print("SKIP: source metadata not found",src.name);continue
        cat=e["category"]; doc=glb_json(src)
        if cat not in DEST or not doc.get("meshes") or not doc.get("nodes"): raise ValueError(f"invalid candidate {src.name}")
        dest=DEST[cat]/src.name;dest.parent.mkdir(parents=True,exist_ok=True)
        if dest.exists() and dest.read_bytes()!=src.read_bytes(): raise ValueError("destination conflict "+str(dest))
        if not dest.exists(): shutil.copy2(src,dest)
        manifest[cat].append({"key":src.stem,"path":"res://"+str(dest.relative_to(ROOT)).replace("\\","/"),"license":e["license"],"source":e["source_page"],"attribution":e.get("attribution",""),"visual_qa":"pending","qa_reviewer":"","qa_evidence":"","runtime_test_candidate":True})
        staged+=1
    MANIFEST.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(f"STAGED {staged} candidate(s); manifest populated; visual approval remains pending.")
    return 0
if __name__=="__main__":sys.exit(main())
