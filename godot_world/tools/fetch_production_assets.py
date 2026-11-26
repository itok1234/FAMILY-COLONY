#!/usr/bin/env python3
"""Fetch explicitly listed GLB assets into the production intake folders.

Requires an asset_sources.json with entries containing category, filename,
url, license, source_page and attribution. Downloads are untrusted and are NOT
automatically accepted or marked visually approved. Run from repository root.
This intake is intentionally triggered for repeatable asset and import evidence.
"""
from pathlib import Path
import hashlib, json, urllib.request, sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_FILE = ROOT / "assets" / "asset_sources.json"
DESTS = {"character": ROOT / "assets" / "characters", "environment": ROOT / "assets" / "environment"}
MAX_BYTES = 80 * 1024 * 1024

def fail(msg):
    print("ERROR:", msg, file=sys.stderr)
    sys.exit(1)

def main():
    if not SOURCE_FILE.is_file():
        fail("Missing asset_sources.json. Add verified direct-download URLs and license metadata.")
    entries = json.loads(SOURCE_FILE.read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        fail("asset_sources.json must contain a non-empty list.")
    results = []
    for e in entries:
        cat, name, url = e.get("category"), e.get("filename"), e.get("url")
        if cat not in DESTS: fail(f"Unknown category: {cat}")
        if not isinstance(name, str) or Path(name).name != name or not name.lower().endswith(".glb"):
            fail(f"Unsafe/invalid filename: {name}")
        for field in ("license", "source_page", "attribution"):
            if not isinstance(e.get(field), str) or not e[field].strip():
                fail(f"{name}: missing metadata field {field}")
        if not isinstance(url, str) or not url.startswith("https://"):
            fail(f"{name}: download URL must be HTTPS")
        dest = DESTS[cat] / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists(): fail(f"Refusing to overwrite existing file: {dest}")
        req = urllib.request.Request(url, headers={"User-Agent": "FamilyColony-AssetIntake/1.0"})
        with urllib.request.urlopen(req, timeout=45) as response:
            if response.status != 200: fail(f"{name}: HTTP {response.status}")
            data = response.read(MAX_BYTES + 1)
        if len(data) > MAX_BYTES: fail(f"{name}: exceeds 80 MiB limit")
        if len(data) < 1024 or data[:4] != b"glTF": fail(f"{name}: not a valid-looking GLB")
        dest.write_bytes(data)
        results.append({"category": cat, "path": str(dest.relative_to(ROOT)), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "license": e["license"], "source_page": e["source_page"], "attribution": e["attribution"], "status": "downloaded_pending_import_and_visual_review"})
    out = ROOT / "assets" / "asset_download_receipt.json"
    out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"Downloaded {len(results)} asset(s); pending Godot import, visual QA and manifest acceptance.")
    print(out)

if __name__ == "__main__":
    main()
