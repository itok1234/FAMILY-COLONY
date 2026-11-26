# FAMILY COLONY — Locked Engineering Checkpoint
Branch: `feature/direct-3d-entry`

## LOCKED (code implementation only)
- Production asset loader validates manifest entries, approved QA state, resource path/existence, PackedScene and Node3D root.
- World scene contains production environment and character mount points.
- Integrator loads selected approved asset or first approved entry when selection key is blank.
- If an accepted production character mounts, the procedural avatar fallback is hidden.
- Existing procedural fallback remains available when no approved production character is present.

## Acceptance boundary
This checkpoint locks the above code scope against rework unless a concrete defect is found. It does **not** certify final 3D visuals, imported production asset presence, rendering, rig/animation quality, Android performance, or device QA.

## Still blocking final release
- Production character and environment assets actually acquired/imported and visually reviewed.
- Manifest filled only after visual acceptance evidence.
- Godot runtime/editor validation and device QA.
- Visual quality, interaction, performance, orientation and APK acceptance.

## Next implementation focus
Asset acquisition/import and review pipeline, then runtime verification. Do not re-open the locked loader/mount work absent a specific defect.
