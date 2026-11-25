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
- Five taps within a 3.5-second interval reveal a spatial 3D developer-login hologram.
- The five-tap gesture only reveals the login entry; it does not authenticate or grant Developer privileges.
- The hologram now includes a 3D keypad, six-position masked PIN display, delete/submit controls and an HTTPS request to the existing fc-member-auth function. It validates the returned Developer identity before emitting a session signal.
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
## Native hub routing and current validation (2026-11-25)
- After the existing member session is verified by fc-world-session, WorldActivity now instantiates the native 3D hub inside the existing Godot world flow.
- The mobile joystick overlay is hidden while the user is in the hub and restored when the user selects the 3D world kiosk.
- The hub's destination_requested signal is connected to world_controller; the world kiosk transitions into the existing playable world.
- Profile, chat, game center and settings kiosks are currently navigation placeholders. Their feature screens and data flows are not yet migrated.
- The developer PIN keypad is a 3D visual/authentication slice. Its success signal is exposed, but Developer Center data operations and handoff into the world-session authorization service are not yet integrated.
- GitHub Actions Android smoke, debug build and signed-release workflows were triggered by the recent Godot changes. Their final outcomes must be checked before treating the build as validated.
- This work does not yet replace the WebView launcher/login, HTML member home, profile, chat, settings or HTML mini-games. The app is not yet fully 3D and no member device test has been completed for this slice.

## Spatial control migration (2026-11-25)
- Removed the flat MobileHUD/MoveJoystick Control node from the main world scene.
- Added camera-mounted 3D joystick ring/knob and 3D sprint orb with touch-drag input; the player controller now consumes movement/sprint state from this spatial control node.
- Removed the flat CanvasLayer/Button sprint control from player_controller.gd.
- Replaced the world session verification overlay and return action with a spatial 3D board and ray-pickable 3D return object.
- These controls and gates have been committed but still require the latest Godot/Android workflow results and hands-on device checks for touch alignment, camera visibility, and movement feel.
- Other existing 2D interfaces elsewhere in the app and Godot scripts are still present; the no-2D acceptance gate remains open.

## 3D interaction and Honey Hunt presentation (2026-11-25)
- Replaced the main world interaction CanvasLayer, flat action button, and radial Control menu with camera-mounted 3D action objects, Label3D prompts/results, and ray-pickable 3D action menu buttons.
- Replaced Honey Hunt's CanvasLayer score HUD and flat exit Button with a camera-mounted Label3D scoreboard and a ray-pickable 3D exit object. The exit remains active on the results screen.
- Honey Hunt's arena, collectibles, portal, score/timer logic and collision-based collection are already 3D; its visible status/exit layer is now also spatial 3D.
- The group chat HUD and other feature screens remain to be migrated. These changes are implementation progress, not a claim that the complete application is 3D.

## Validation record (2026-11-25)
- Commit `1cf54ea2ae520e7cba96cbfc0f3c305db3c5da8e`: Godot 4.4.1 editor import/parse and headless world startup smoke test passed in GitHub Actions run `45516983108`.
- Android debug APK build, signed release APK build and embedded Android emulator smoke test were still running when this record was updated; no APK from these latest changes is declared ready here.
- No physical Redmi Note 8 Pro test has been performed for the new 3D touch controls, interaction panel or Honey Hunt spatial HUD.

## Native 3D feature routing and Honey Hunt launch (2026-11-25)
- Hub kiosks now open spatial 3D feature panels rather than only changing a hint label.
- The 3D Game Center lists all five planned mini-games. Honey Hunt is connected to the existing 3D arena and starts from the 3D hub selection. Guess Who, Royal Bomb, Royal Murder Mystery and Royal Dice are visible in the menu but their gameplay has not yet been ported to Godot.
- The 3D world kiosk now presents a dedicated 3D entry action before returning control to the playable world.
- Profile, Chat and Settings panels currently communicate migration status; their data-backed feature screens are not complete.
- Commit `ba5372779bcdd32a6a950e15899c3a476735587f` passed the Godot 4.4.1 parse/startup validation workflow. The follow-up wiring commits are pending their own workflow results.
