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

## Developer access — 3D implementation slice (2026-11-25)
- Added a 3D bee emblem to the isolated Godot hub.
- Five taps within a 2.2-second interval reveal a spatial 3D developer-login hologram.
- The five-tap gesture only reveals the login entry; it does not authenticate or grant Developer privileges.
- Developer authentication, server-side role verification, credential form and successful-login navigation remain to be integrated.
- The existing WebView launcher and 2D member UI are still present; this is not yet a complete 3D conversion.
- The new scene/script still requires Godot import, runtime and Android device validation.
## Existing developer authentication contract verified
- The current legacy bee-logo gesture opens the developer PIN panel after five taps within 3.5 seconds. The Godot 3D bee gesture now matches this timing.
- Existing developer login uses a six-digit PIN sent to the fc-member-auth backend function with action developer_pin_login.
- Backend response must include ok, access_token and member; the app session is populated from the returned member and tokens.
- PIN setup uses the existing bootstrap-secret flow; never copy the bootstrap secret or PIN into the Godot source or APK.
- The 3D migration must port this backend request/session contract and role checks. The new 3D hologram currently does not perform login.
## Hub presentation refinement
- Replaced the hub's flat CanvasLayer/PanelContainer HUD with a spatial Node3D information board using MeshInstance3D and Label3D.
- The 3D hub script no longer instantiates CanvasLayer, PanelContainer, VBoxContainer or flat Label controls; hub labels and kiosk surfaces are rendered in 3D.
- This only certifies the isolated hub presentation layer. The legacy HTML/CSS app is still present and must not be considered migrated.
- A Godot editor/headless import and Android runtime test is still required before marking this slice verified.