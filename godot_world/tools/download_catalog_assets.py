#!/usr/bin/env python3
"""Intake curated CC0 GLBs only when verified against Gobkit's live manifest."""
import json, hashlib, pathlib, urllib.request, tempfile, os
ROOT=pathlib.Path(__file__).resolve().parents[1]
CATALOG=ROOT/"assets"/"asset_candidate_catalog.json"
DEST={"character":ROOT/"assets"/"characters","environment":ROOT/"assets"/"environment"}
MAX=80*1024*1024
def get(url):
    req=urllib.request.Request(url,headers={"User-Agent":"FamilyColonyAssetIntake/1.0"})
    with urllib.request.urlopen(req,timeout=60) as r:
        if r.status!=200: raise RuntimeError(f"HTTP {r.status}: {url}")
        return r.read(MAX+1)
def urls_from_manifest(data):
    urls=set(data.get("glbs",[]))
    for pack in data.get("packs",[]):
        for model in pack.get("models",[]):
            if model.get("url"): urls.add(model["url"])
    if not urls: raise RuntimeError("Official manifest returned no GLB URLs")
    return urls
def main():
    catalog=json.loads(CATALOG.read_text(encoding="utf-8"))
    approved=urls_from_manifest(json.loads(get("https://gobkit.com/api/free")))
    receipt=[]
    for category in ("character","environment"):
        for entry in catalog.get(category,[]):
            url=entry["url"]
            if url not in approved: raise RuntimeError(f"URL not in official manifest: {url}")
            name=entry["filename"]
            if pathlib.Path(name).name!=name or not name.lower().endswith(".glb"): raise RuntimeError(f"Unsafe filename: {name}")
            dest=DEST[category]/name; dest.parent.mkdir(parents=True,exist_ok=True)
            if dest.exists():
                data=dest.read_bytes()
                if data[:4]!=b"glTF": raise RuntimeError(f"Existing file is invalid; refusing overwrite: {dest}")
                receipt.append({"category":category,"path":str(dest.relative_to(ROOT)),"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),"license":"CC0-1.0","source_page":entry["source_page"],"url":url,"status":"existing_intake_pending_import_visual_review"})
                continue
            data=get(url)
            if len(data)>MAX: raise RuntimeError(f"Over 80 MiB: {name}")
            if len(data)<1024 or data[:4]!=b"glTF": raise RuntimeError(f"Invalid GLB: {name}")
            fd,tmp=tempfile.mkstemp(prefix=name+".",suffix=".part",dir=str(dest.parent))
            try:
                with os.fdopen(fd,"wb") as out: out.write(data)
                os.replace(tmp,dest)
            finally:
                if os.path.exists(tmp): os.unlink(tmp)
            receipt.append({"category":category,"path":str(dest.relative_to(ROOT)),"bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),"license":"CC0-1.0","source_page":entry["source_page"],"url":url,"status":"downloaded_pending_import_visual_review"})
    (ROOT/"assets"/"asset_download_receipt.json").write_text(json.dumps(receipt,indent=2),encoding="utf-8")
    print(f"Intake receipt created for {len(receipt)} assets. Pending Godot import and visual QA.")
if __name__=="__main__": main()
