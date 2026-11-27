#!/usr/bin/env python3
"""Fail-closed production 3D asset intake gate with lightweight glTF inspection.

This validates file structure and provenance only. It cannot certify visual quality,
scene integration, mobile performance or runtime behaviour.
"""
from pathlib import Path
import json
import struct
import sys

root = Path(__file__).resolve().parents[1]
manifest_path = root / "assets" / "production_asset_manifest.json"
folders = {"character": root / "assets" / "characters", "environment": root / "assets" / "environment"}
valid = {".glb", ".gltf"}
errors, warnings = [], []
approved = {}
if not manifest_path.exists():
    errors.append("MISSING production acceptance manifest")
else:
    try:
        approved = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(approved, dict):
            raise ValueError("manifest must be a JSON object")
    except Exception as exc:
        errors.append(f"INVALID manifest: {exc}")
        approved = {}

def read_gltf(path):
    """Read glTF JSON from .gltf or JSON chunk from binary .glb."""
    if path.suffix.lower() == ".gltf":
        return json.loads(path.read_text(encoding="utf-8"))
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("GLB header/chunks truncated")
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or total != len(data):
        raise ValueError("invalid GLB header/version/length")
    offset = 12
    while offset + 8 <= len(data):
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset + chunk_len]
        if len(chunk) != chunk_len:
            raise ValueError("truncated GLB chunk")
        offset += chunk_len
        if chunk_type == 0x4E4F534A:
            return json.loads(chunk.decode("utf-8").rstrip(" \\t\\r\\n\\0"))
    raise ValueError("GLB has no JSON chunk")

def inspect_model(path, category):
    doc = read_gltf(path)
    meshes = doc.get("meshes", [])
    nodes = doc.get("nodes", [])
    skins = doc.get("skins", [])
    animations = doc.get("animations", [])
    if not meshes:
        raise ValueError("no mesh definitions")
    if not nodes:
        raise ValueError("no scene nodes")
    # Validate referenced external resources for text glTF files.
    if path.suffix.lower() == ".gltf":
        for resource in doc.get("buffers", []) + doc.get("images", []):
            uri = resource.get("uri")
            if uri and not uri.startswith("data:"):
                dep = (path.parent / uri).resolve()
                dep.relative_to(root.resolve())
                if not dep.is_file():
                    raise ValueError(f"missing external resource: {uri}")
    if category == "character" and not skins:
        raise ValueError("character model has no skeletal skin (rig)")
    return {"meshes": len(meshes), "nodes": len(nodes), "skins": len(skins), "animations": len(animations), "materials": len(doc.get("materials", [])), "textures": len(doc.get("textures", []))}

for label, folder in folders.items():
    candidates = sorted(p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in valid and not p.name.lower().startswith("bootstrap_")) if folder.exists() else []
    accepted = approved.get(label, [])
    if not isinstance(accepted, list) or not accepted:
        errors.append(f"NO explicitly accepted production {label} assets in manifest")
        accepted = []
    accepted_paths = set()
    for record in accepted:
        if not isinstance(record, dict):
            errors.append(f"INVALID {label} record (must be object)")
            continue
        item = record.get("path")
        if not isinstance(item, str) or not item.strip():
            errors.append(f"INVALID {label} record: missing path")
            continue
        required = ("license", "source")
        for field in required:
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append(f"INCOMPLETE PROVENANCE RECORD {item}: missing {field}")
        # Structural candidate intake is distinct from visual QA; never fake approval.
        filesystem_item = item[6:] if item.startswith('res://') else item
        p = (root / filesystem_item).resolve()
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
            errors.append(f"ASSET FILE TOO SMALL: {item}")
        else:
            try:
                inventory = inspect_model(p, label)
                print(f"STRUCTURE PASS {label}: {item} | " + json.dumps(inventory))
            except Exception as exc:
                errors.append(f"STRUCTURE INVALID {item}: {exc}")
    for p in candidates:
        if p.resolve() not in accepted_paths:
            warnings.append(f"UNAPPROVED candidate: {p.relative_to(root)}")

for key in approved:
    if key not in folders:
        errors.append(f"UNKNOWN MANIFEST CATEGORY: {key}")

for warning in warnings:
    print("WARNING:", warning)
if errors:
    print("PRODUCTION ASSET CANDIDATE AUDIT: FAILED")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("PRODUCTION ASSET CANDIDATE AUDIT: PASS (structure + provenance only; visual/runtime review still required)")
