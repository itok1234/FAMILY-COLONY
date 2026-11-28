# Beranda 3D Master Benchmark — Acceptance

This isolated preview harness instantiates the production hub script without login or backend dependencies.

## Automated acceptance (CI)
- Scene loads and active camera exists.
- Elevated overview camera framing and FOV remain within structural bounds.
- Central beacon, rings, plaza inlays, shrubs, lamps and information board exist.
- Five feature stations exist and are ray-pickable.
- Idle startup does not emit a navigation destination.
- Godot parse/import, startup and Android emulator smoke tests pass.

These checks are structural and do **not** prove visual quality, real touch navigation, device performance, or orientation transitions.

## Required real-device acceptance before visual LOCK
1. Capture Beranda in landscape at target Android device resolution.
2. Confirm landmark, radial plaza, feature kiosks and garden are visible, readable and not clipped.
3. Reject primitive-only/blockout appearance; review actual screenshots against intended premium 3D art quality.
4. Tap each station and verify touch hit areas, panel entry, return path, and no unintended auto-entry.
5. Enable World from Beranda; confirm landscape orientation persists, World loads, and returning restores Beranda without severe lag or orientation glitch.
6. Run a 10-minute device session; note frame rate, overheating, memory pressure, stutters and touch responsiveness.
7. Save device capture and test notes; only then LOCK visual acceptance.

## Current limitation
The existing hub script still describes its artwork as procedural blockout geometry. CI can validate scene structure and runtime but cannot approve the visual-art gate or physical-device navigation/performance gate without reviewed device evidence.
