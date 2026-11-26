#!/usr/bin/env python3
"""Stage validated GLB intake models into production asset folders without approval.

This is a reproducible integration preparation step, NOT visual QA or production
acceptance. Skinned models are staged as character assets; non-skinned meshes are
staged as environment assets. The production manifest is intentionally unchanged.
"""
from pathlib import Path
import json, struct, shutil, sys

ROOT=Path(__file__).resolve().parents[1]
INTAKE=ROOT/"intake-output"
DEST={"character":ROOT/"assets"/"characters","environment":ROOT/"assets"/"environment"}

def glb_json(p):
    data=p.read_bytes()
    if len(data)<20: raise ValueError("short GLB")
    magic,version,total=struct.unpack_from("<4sII",data)
    if magic!=b"glTF" or version!=2 or total!=len(data): raise ValueError("bad GLB header")
    off=12
    while off+8<=len(data):
        n,t=struct.unpack_from("<II",data,off);off+=8
        chunk=data[off:off+n]
        if len(chunk)!=n: raise ValueError("truncated chunk")
        off+=n
        if t==0x4E4F534A: return json.loads(chunk.decode("utf-8").rstrip(" \t\r\n\0"))
    raise ValueError("missing JSON chunk")

def main():
    if not INTAKE.exists(): print("INTAKE directory missing");return 1
    counts={"character":0,"environment":0}; errs=[]
    for src in sorted(INTAKE.glob("*.glb")):
        try:
            doc=glb_json(src)
            if not doc.get("meshes") or not doc.get("nodes"): raise ValueError("mesh/node missing")
            cat="character" if doc.get("skins") else "environment"
            dest=DEST[cat]/src.name
            DEST[cat].mkdir(parents=True,exist_ok=True)
            if dest.exists():
                if dest.read_bytes()!=src.read_bytes(): raise ValueError("destination conflict (different file)")
            else: shutil.copy2(src,dest)
            counts[cat]+=1
            print(f"STAGED {cat}: {src.name} | meshes={len(doc.get('meshes',[]))} skins={len(doc.get('skins',[]))} animations={len(doc.get('animations',[]))}")
        except Exception as e: errs.append(f"{src.name}: {e}")
    print("Staging counts:",counts)
    print("Approval manifest intentionally unchanged; staged assets remain unapproved.")
    if errs:
        print("\n".join(errs));return 1
    return 0
if __name__=="__main__": sys.exit(main())
