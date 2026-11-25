# FAMILY COLONY — 3D Asset Integration Sprint Gate

Date: 2026-11-25
Branch: feature/direct-3d-entry

## Sprint objective
Replace the existing procedural placeholder silhouettes with actual locally-imported 3D production assets while preserving the authenticated entry flow and existing feature routing. This sprint is not satisfied by adding more procedural decorations.

## Current source audit
- The authenticated member path instantiates MainHub3D after server verification and permissions check.
- The hub has Profile, Chat/Rooms, Royal Game Center, Settings, World and protected Developer Center routes.
- The World station explicitly switches from hub to exploration.
- Developer Center identity checks are enforced in hub and controller; module operations still report backend integration pending.
- Existing environment/avatar geometry remains procedural and not verified to the reference fidelity on device.

## Production asset acceptance targets
1. **Plaza and architecture:** import GLB/glTF assets for a coherent plaza, centerpiece fountain, facade/buildings, paths, vegetation and furnishing. All assets locally packaged; no runtime downloads required.
2. **Avatar:** rigged humanoid with facial/head/body silhouette, separate clothing/cosmetic slots, animation clips (idle, walk, run, turn, wave, sit/stand). Validate animation transitions.
3. **Room:** finished interior asset set, furniture with collision and interaction anchors, lighting and room layout.
4. **World:** spatially coherent streets/landmarks and traversable surfaces; collision mesh simplified separately from render mesh.
5. **Android budget:** texture atlases where appropriate; avoid unnecessary high-poly props; use mobile-compatible materials and compressed textures; use LOD or distance visibility for costly objects; no excessive realtime shadow casters.
6. **Interface:** 3D hub feature panels must remain legible on portrait and landscape touch screens, and hit targets must be touch-safe.

## Required QA evidence
Capture actual device/emulator screenshots and recordings for:
- verified member login -> 3D hub
- profile/avatar panel
- chat and room listing
- game center
- settings
- hub -> world -> return flow
- Developer Center authentication and denial path
- controls, frame rate and memory/performance observation

## Release rule
Do not mark the sprint complete or publish an install request without production assets, successful Android build, and evidence from the QA list. CI compilation alone is not visual QA.
