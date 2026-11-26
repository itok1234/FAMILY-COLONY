#!/usr/bin/env python3
"""Fail-closed production asset gate. Bootstrap assets are never release assets.

A production asset must be present, listed in the explicit acceptance manifest,
and not named bootstrap_*. Manifest approval does not replace visual QA.
"""
from pathlib import Path
import json
import sys

root = Path(__file__).resolve().parents[1]
manifest_path = root / "assets" / "production_asset_manifest.json"
folders = {"character": root / "assets" / "characters", "environment": root / "assets" / "environment"}
valid = {".glb", ".gltf"}
errors = []

if not manifest_path.exists():
    errors.append("MISSING production acceptance manifest: assets/production_asset_manifest.json")
    approved = {}
else:
    try:
        approved = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(approved, dict):
            raise ValueError("manifest must be a JSON object")
    except Exception as exc:
        errors.append(f"INVALID production acceptance manifest: {exc}")
        approved = {}

for label, folder in folders.items():
    candidates = sorted(p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in valid and not p.name.lower().startswith("bootstrap_")) if folder.exists() else []
    accepted = approved.get(label, [])
    if not isinstance(accepted, list) or not accepted:
        errors.append(f"NO explicitly accepted production {label} assets in manifest")
        accepted = []
    accepted_paths = set()
    for item in accepted:
        if not isinstance(item, str):
            errors.append(f"INVALID manifest entry for {label}: {item!r}")
            continue
        p = (root / item).resolve()
        try:
            p.relative_to(root.resolve())
        except ValueError:
            errors.append(f"MANIFEST PATH OUTSIDE PROJECT: {item}")
            continue
        if p.suffix.lower() not in valid or p.name.lower().startswith("bootstrap_"):
            errors.append(f"NOT A PRODUCTION MODEL: {item}")
            continue
        accepted_paths.add(p)
        if not p.is_file():
            errors.append(f"APPROVED ASSET MISSING: {item}")
    for p in candidates:
        if p.resolve() not in accepted_paths:
            print("UNAPPROVED production candidate:", p.relative_to(root))
    if accepted_paths:
        print(f"ACCEPTED {label}: {len(accepted_paths)} manifest-listed model(s)")

if errors:
    print("PRODUCTION ASSET GATE: BLOCKED")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("PRODUCTION ASSET GATE: PASS (manifest acceptance only; visual QA/license checks still required)")
