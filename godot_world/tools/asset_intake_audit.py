#!/usr/bin/env python3
"""Fail-closed production asset gate.

Only manifest entries with complete provenance and explicit visual QA acceptance
may be used for release. Bootstrap assets are excluded. This gate is not a
substitute for visual review or a runtime test.
"""
from pathlib import Path
import json
import sys

root = Path(__file__).resolve().parents[1]
manifest_path = root / "assets" / "production_asset_manifest.json"
folders = {"character": root / "assets" / "characters", "environment": root / "assets" / "environment"}
valid = {".glb", ".gltf"}
errors = []
warnings = []

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
    for record in accepted:
        if not isinstance(record, dict):
            errors.append(f"INVALID {label} manifest record (must be an object with provenance and QA fields): {record!r}")
            continue
        item = record.get("path")
        if not isinstance(item, str) or not item.strip():
            errors.append(f"INVALID {label} record: missing path")
            continue
        required = ("license", "source", "visual_qa", "qa_reviewer", "qa_evidence")
        for field in required:
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append(f"INCOMPLETE ACCEPTANCE RECORD {item}: missing {field}")
        if record.get("visual_qa") != "approved":
            errors.append(f"VISUAL QA NOT APPROVED: {item}")
        p = (root / item).resolve()
        try:
            p.relative_to(root.resolve())
            p.relative_to(folder.resolve())
        except ValueError:
            errors.append(f"ASSET PATH OUTSIDE {label} FOLDER: {item}")
            continue
        if p.suffix.lower() not in valid or p.name.lower().startswith("bootstrap_"):
            errors.append(f"NOT A PRODUCTION MODEL: {item}")
            continue
        if p in accepted_paths:
            errors.append(f"DUPLICATE MANIFEST ENTRY: {item}")
        accepted_paths.add(p)
        if not p.is_file():
            errors.append(f"APPROVED ASSET MISSING: {item}")
        elif p.stat().st_size < 1024:
            errors.append(f"ASSET FILE TOO SMALL / INVALID: {item}")
    for p in candidates:
        if p.resolve() not in accepted_paths:
            warnings.append(f"UNAPPROVED production candidate: {p.relative_to(root)}")
    if accepted_paths:
        print(f"ACCEPTED {label}: {len(accepted_paths)} QA-approved manifest model(s)")

# Fail closed on unknown manifest categories to catch typoed sections.
for key in approved:
    if key not in folders:
        errors.append(f"UNKNOWN MANIFEST CATEGORY: {key}")

if warnings:
    for warning in warnings:
        print("WARNING:", warning)
if errors:
    print("PRODUCTION ASSET GATE: BLOCKED")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("PRODUCTION ASSET GATE: PASS (explicit provenance + QA approval; runtime QA still required)")
