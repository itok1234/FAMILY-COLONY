#!/usr/bin/env python3
"""Download curated Gobkit CC0 GLBs using their official live manifest as URL authority.
Outputs into godot_world/assets intake folders; does not approve visual quality."""
import json, hashlib, pathlib, urllib.request, sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
CATALOG=ROOT/"assets"/"asset_candidate_catalog.json"
DEST={"character":ROOT/"assets"/"characters","environment":ROOT/"assets"/"environment"}
MAX=80*1024*1024
def get(url):
    req=urllib.request.Request(url,headers={"User-Agent":"FamilyColonyAssetIntake/1.0"})
    with urllib.request.urlopen(req,timeout=60) as r:
        if r.status!=200: raise RuntimeError(f"HTTP {r.status}: {url}")
        return r.read(MAX+1)
def main():
    catalog=json.loads(CATALOG.read_text(encoding="utf-8"))
    official=json.loads(get("https://gobkit.com/api/free"))
    approved=set(official.get("glbs",[]))
    if not approved: raise RuntimeError("Official manifest returned no GLB URLs")
    receipt=[]
    for category in ("character","environment"):
        for entry in catalog.get(category,[]):
            url=entry["url"]
            if url not in approved: raise RuntimeError(f"URL is not in official manifest: {url}")
            name=entry["filename"]
            if pathlib.Path(name).name!=name or not name.lower().endswith(".glb"): raise RuntimeError("Unsafe filename")
            dest=DEST[category]/name
            dest.parent.mkdir(parents=True,exist_ok=True)
            if dest.exists(): raise RuntimeError(f"Refusing overwrite: {dest}")
            data=get(url)
            if len(data)>MAX: raise RuntimeError(f"Over 80 MiB: {name}")
            if len(data)<1024 or data[:4]!=b"glTF": raise RuntimeError(f"Invalid GLB: {name}")
            dest.write_bytes(data)
            receipt.append({"category":category,"path":str(dest.relative_to(ROOT)),"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),"license":"CC0-1.0","source_page":entry["source_page"],"url":url,"status":"downloaded_pending_import_visual_review"})
    (ROOT/"assets"/"asset_download_receipt.json").write_text(json.dumps(receipt,indent=2),encoding="utf-8")
    print(f"Downloaded {len(receipt)} candidate GLBs. Pending Godot import and visual QA.")
if __name__=="__main__": main()
