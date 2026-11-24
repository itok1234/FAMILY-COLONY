# FAMILY COLONY — Full 3D Migration Baseline

## Product decision
The shipping experience must contain no 2D application screens. All member-facing spaces and feature presentation are to be rendered as 3D environments, 3D objects, 3D kiosks, or 3D in-world interfaces. A flat accessibility overlay is not accepted as a final substitute for a 3D feature surface.

## Existing architecture verified on feature/direct-3d-entry
- Android launcher currently opens MainActivity/WebView.
- Web content in app/src/main/assets/index.html currently contains login/home navigation/profile/settings/chat and HTML mini-game interfaces.
- WorldActivity launches the embedded Godot project separately.
- Godot's configured main scene is scenes/world.tscn.
- The current world includes a procedural blockout avatar and a world-session bridge.
- Multiplayer transport is currently LAN ENet; cloud matchmaking is not proof of a deployed authoritative game server.

## Migration order
1. Establish a Godot-native 3D hub and navigation shell without breaking the existing authentication handoff.
2. Port login/session state and member profile data to native Godot screens presented as spatial 3D stations.
3. Port profile/avatar customization, settings, audio and member inventory into 3D feature spaces.
4. Port chat, room discovery, invites and presence into 3D social spaces while retaining backend authorization.
5. Rebuild every mini game as its own 3D scene with 3D gameplay objects, interactions, animation and feedback.
6. Integrate all scenes under one Godot application flow; remove WebView as the member-facing application root only after feature parity and regression tests.
7. Build Android release candidates and test on physical Android devices, network conditions and member accounts. iOS requires a separate export/signing/test pipeline.

## First implementation slice
- Added scenes/main_hub_3d.tscn and scripts/main_hub_3d.gd.
- The scene provides a 3D hub with 3D feature kiosks for profile, chat, games, settings and world.
- It is an isolated migration slice, not yet wired as the launcher scene. This is deliberate: switching the launcher before login/session and all feature routes are ported would break existing access.

## Acceptance gate
Do not label the product fully 3D until:
- No member-facing HTML/CSS 2D screen or 2D mini-game remains in the final application.
- Every listed feature has a functional Godot 3D scene.
- Login, session refresh, authorization, data persistence, chat and room behavior pass regression tests.
- Android build and device tests pass; iOS support is separately verified.
