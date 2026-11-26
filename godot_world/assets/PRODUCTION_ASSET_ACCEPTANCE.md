# Production 3D asset acceptance (release blocker)

This repository currently has no accepted premium character/environment asset binaries. Procedural bootstrap GLBs are pipeline fixtures only and must never be treated as final art.

## Required manifest record
Each entry in `production_asset_manifest.json` must be an object with:
- `path`: repository-relative path inside the matching `characters/` or `environment/` directory.
- `license`: license name and terms permitting the intended distribution.
- `source`: origin URL or source package identifier.
- `visual_qa`: set to `approved` only after all visual checks below.
- `qa_reviewer`: reviewer identity/role.
- `qa_evidence`: path or identifier for review evidence (screenshots/video/report).

## Visual review checklist (must be performed in Godot, not inferred from file existence)
- Character: silhouette/proportions, facial detail, rig and skinning, wings/hair/clothing/accessories, materials, texture quality.
- Environment: scale, composition, lighting, collision/navigation, material/texture consistency, scene integration.
- Runtime: Android target performance, interaction, animations, camera, transitions, orientation.
- No placeholder geometry, debug objects, flat mock screens, or unreviewed procedural blockout in release scenes.
- Confirm license and attribution requirements; retain evidence.

## Gate behavior
`asset_intake_audit.py` validates the file, category folder, manifest fields, explicit visual QA status and minimum file size. Passing the script does **not** certify appearance, performance, or runtime quality; runtime review and release QA remain mandatory.

## Current state
Manifest entries are empty. Production release packaging must remain blocked until actual asset binaries are acquired, integrated, and reviewed. Do not ask the user to install a prototype APK as visual QA.
