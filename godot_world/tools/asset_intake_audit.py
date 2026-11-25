#!/usr/bin/env python3
"""Fail-closed asset inventory audit. Presence is not quality or license verification."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
folders = {"character": root / "assets" / "characters", "environment": root / "assets" / "environment"}
valid = {".glb", ".gltf"}
errors = []
for label, folder in folders.items():
    files = sorted(p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in valid) if folder.exists() else []
    if not files:
        errors.append(f"MISSING {label} model(s): {folder.relative_to(root)}")
    else:
        print(f"FOUND {label}: {len(files)} model(s)")
        for f in files: print(" -", f.relative_to(root))
if errors:
    print("ASSET INVENTORY: BLOCKED")
    for e in errors: print(" -", e)
    sys.exit(1)
print("ASSET INVENTORY: PASS (presence only; import, license and visual review remain separate)")
