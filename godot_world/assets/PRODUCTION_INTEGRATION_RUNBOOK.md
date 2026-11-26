# Production asset integration runbook (single finalization pass)

This is the execution checklist for the already locked finalization scope. Do not restart Avatar, World, Lobby or minigame implementation.

## 1. Asset source and selection
- Prefer permissively licensed downloadable GLB/glTF models with documented source and license.
- Character: rigged humanoid with skeletal skin, usable animation clips, proportion/style compatible with FAMILY COLONY; avoid voxel/blocky and placeholder models.
- World: modular plaza/architecture, vegetation, furnishings, terrain and environment props; ensure mobile-friendly texture and polygon budgets.
- Review license/attribution before committing; do not accept asset packs with unclear terms.

## 2. Repository intake
- Character files go into `godot_world/assets/characters/`.
- Environment files go into `godot_world/assets/environment/`.
- Keep glTF external textures/buffers beside the glTF with relative paths; GLB preferred.
- Never overwrite the bootstrap fixtures.
- Populate `production_asset_manifest.json` with relative path, license, source, reviewer and evidence path. Set `visual_qa` to approved only after actual review.

## 3. Integrate into existing scenes
- Replace the placeholder character instance in the existing avatar/world flow, preserving controller, collision, cosmetic hooks, camera and UI connections.
- Replace blockout environment elements in the existing world builder/hub scene, preserving interaction IDs, portals, room access and minigame entry.
- Use collision proxies, LOD/instancing, compressed textures and sensible mobile draw-call limits.
- Do not create parallel demo scenes or bypass the existing flow.

## 4. Validate
- Run `python godot_world/tools/asset_intake_audit.py` from repository root.
- Import and open the project with Godot 4.4.1; resolve missing textures/resources, script errors and warnings.
- Capture actual Godot review evidence: character close-up/full-body, rig animation, plaza wide and close views, landscape mobile interaction.
- Record evidence paths in manifest; evidence must be real screenshots/video, not generated mockups.
- Runtime review on Android is required before release; automated headless tests alone do not certify visuals.

## 5. Final release
- Only after accepted asset intake, scene integration, runtime evidence and regression CI succeed, release packaging may proceed.
- The release gate is intentionally fail-closed while either production asset category is empty or unapproved.
