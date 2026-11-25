# FAMILY COLONY — Production 3D Asset Integration Gate

This gate is strict: placeholder geometry and APK size do not qualify as production 3D.

## Required assets and integration targets

| Asset group | Target | Required integration/acceptance |
|---|---|---|
| Member avatar | rigged humanoid GLB, mobile-optimized | imported, rig/animations validated, locomotion/action animation hooks mapped, material/cosmetic slots documented |
| Lobby architecture | GLB modular building/structures | collision proxies, navigation clearances, lighting/material budget |
| Environment | ground, foliage, props, paths | LOD or reduced geometry where appropriate, batching/instancing, collision where traversable |
| Login visual scene | 3D scene with camera, lighting and visual staging | login controls usable, loading/failure state, no clipping or overlap |
| Community/room scenes | separate scenes or reusable modules | portals/routes work and return path verified |
| UI and cosmetic assets | textures, icons, meshes | readable on small screens, texture sizes and compression validated |

## Asset intake checklist

- Files are licensed/owned and placed in the project, not linked as external runtime dependencies.
- Prefer GLB/glTF for scene and model imports; document source, license, author and modification.
- Textures use mobile-friendly dimensions and compression; remove unused maps and materials.
- Materials are compatible with Godot mobile rendering; avoid unnecessary transparency and expensive shader features.
- Meshes have sensible polygon budgets, origin/pivot, scale, and named nodes.
- Required skeleton, skin, animation clips, and mesh names are documented.
- Collision geometry is intentionally authored or generated; visual mesh collision is not blindly used.
- Asset import succeeds on the target Godot version; no missing resources.
- Scene loads on Android and camera framing, lighting, touch controls and frame stability are inspected.

## Avatar integration gate

Do not replace the current procedural avatar unless a production asset is actually present and verified. Keep the procedural avatar as a fallback during integration. A candidate rig must pass:
1. import and instantiate;
2. skeleton and skin integrity;
3. idle, locomotion, wave, sit and stand mapping (or explicitly recorded missing clips);
4. appearance/cosmetic material slot mapping;
5. display-name placement;
6. Android rendering and touch/world interaction checks.

## Visual release evidence

The test/release gate requires emulator/device screenshots or video evidence of login, authenticated transition, lobby, avatar, controls and room navigation, plus recorded device/emulator and test account/session procedure. Headless tests, APK signing, file size and launch smoke tests are not substitutes for visual inspection or successful authenticated member login.

## Current state

No production asset package is currently present in the audited godot_world tree. This document describes intake and validation requirements; it does not claim art assets or final 3D integration exist.
