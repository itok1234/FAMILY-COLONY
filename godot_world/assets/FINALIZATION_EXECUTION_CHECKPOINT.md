# Finalization execution checkpoint

## Scope
Do not restart or re-audit locked Avatar, World, Lobby, integration, visual QA baseline, or minigame work. Continue from asset acquisition and final runtime proof.

## Immediate dependency
Acquire real GLB binaries with verifiable provenance/licensing and place them in the existing intake folders:
- characters: `godot_world/assets/characters/`
- environment: `godot_world/assets/environment/`

The existing downloader and intake audit are retained. No candidate is accepted solely because a source page describes it.

## Sequence once binaries are available
1. Run asset intake and structural audit (GLB integrity, textures, meshes, skeleton and animations).
2. Import accepted files into the existing scenes; preserve established project flow and locked scope.
3. Run Godot headless import and scene/runtime validation.
4. Capture runtime screenshots/video evidence for character and environment; assess style consistency, materials, lighting, movement, frame performance on target Android.
5. Fix only newly discovered blockers; don't reopen already locked stages as separate work.
6. Run release CI and package signed APK only when production asset and runtime evidence gates pass.

## Current honest checkpoint
- Source candidate researched: CC0 rigged GLB character pack, compatible with Godot according to its listing.
- Actual binary acquisition/import/runtime visual proof: pending; attempted download access in current environment failed.
- Production manifest remains empty until actual files pass intake and visual review.
- Release APK must not be declared ready before these gates.
