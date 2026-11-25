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

## Spatial room chat presentation (2026-11-25)
- Replaced the RoomChatHUD CanvasLayer, PanelContainer, VBoxContainer, LineEdit and flat Buttons with a camera-mounted spatial 3D board.
- The 3D chat panel renders recent room messages with Label3D and provides a touch-selectable 3D QWERTY keypad, space, delete, send and close controls. Message send still uses the existing room transport and validation; it is not upgraded to cross-network cloud chat.
- Chat input is suspended while the hub is open and restored after entering the world.
- First validation caught missing signal callback methods after the HUD rewrite; the handlers have been restored in commit `fea7ac5507a9ce88e9b98a57eb5205480623c3b4`. Latest Godot validation is running.

## Developer PIN session handoff (2026-11-25)
- Connected the 3D hub's developer_authenticated signal to WorldSessionClient.
- The PIN response is checked for the expected Developer identity, then its short-lived access token is independently verified by the existing fc-world-session authorization endpoint before the 3D Developer Center opens.
- The Developer Center is a spatial 3D dashboard with entry points for member management, world settings, mini-game management, server monitoring, reports and app configuration. These controls are currently navigation hooks only; privileged CRUD/server operations still need their dedicated backend integration.
- If server verification fails, the user receives a 3D status message and no Developer Center is unlocked.

## Spatial audio settings migration (2026-11-25)
- Replaced the Godot world's remaining audio settings CanvasLayer, HSlider, Button, PanelContainer, VBoxContainer and Label controls with a camera-mounted 3D settings board built from MeshInstance3D, Area3D and Label3D.
- Added 3D hub actions for Audio & Volume and Studio Credits; the hub emits a settings action signal and world_controller routes it to the audio settings node.
- Audio mute and master volume remain persisted in the existing user://family_colony_settings.cfg file. Volume is selected through eleven spatial 3D controls (0–100%).
- Studio credits are displayed as Label3D inside the same spatial board.
- This removes the flat audio settings UI from the Godot world settings feature, but does not imply that the legacy WebView/HTML launcher and all remaining 2D app surfaces have been migrated.
- Latest source commits: 20ea1f4 (hub actions), 2ecb52a (world routing), 17945a2 (spatial audio settings). Godot import/startup, Android debug, embedded Android smoke and signed-release workflows were triggered for the latest source. Results must be checked before marking this slice validated.


## Parallel 3D mini-game implementation slice (2026-11-25)
- Game Center selection now routes all five entries into the Godot mini-game manager: Honey Hunt, Guess Who, Royal Bomb, Royal Murder Mystery and Royal Dice.
- Honey Hunt retains its existing 3D collection arena and spatial score/exit HUD.
- Added initial playable local 3D loops for Guess Who (clue reveal, answer selection, score and question timer), Royal Bomb (draw/defuse/survival loop with simulated opponents), Royal Murder Mystery (three clue-and-suspect cases), and Royal Dice (five rounds, dice rolls, card selection and bot scoring).
- New game controls, labels, result feedback and exit actions are camera-mounted spatial 3D objects using ray-pickable Area3D surfaces; no CanvasLayer or flat Control HUD is used by these new loops.
- This is a first integrated gameplay slice, not feature-complete parity with every legacy HTML game rule. Royal Bomb opponents and Royal Dice/Murder opponents are local simulations; there is no cross-device multiplayer, server-authoritative result validation, member rewards, admin question CRUD sync, or cloud persistence in these new 3D loops yet.
- Godot parse/startup, Android build, embedded smoke and signed-release workflows were triggered for validation. Do not treat an APK as ready until the latest workflows pass and physical-device play checks are completed.

## Spatial graphics and multiplayer status UI (2026-11-25)
- Replaced the Godot graphics-quality OptionButton/CanvasLayer overlay with a camera-mounted spatial 3D selector (Auto, Hemat, Seimbang, Tinggi). Selection still persists to the existing local settings file and updates render scale, MSAA, world density and effects.
- Replaced the LAN multiplayer status CanvasLayer/Label HUD with a camera-mounted Label3D status readout. The transport remains LAN ENet; this visual conversion does not make it cloud multiplayer.
- Refined the procedural avatar with layered hair/clothing details and a short randomized blink animation. It remains a procedural placeholder, not an imported production skeletal character model.
- Godot parse/startup validation for commit `22fb2389735b22efc331962cf09538884e5dc39f` passed. Android debug/release and embedded smoke workflows for that commit were still running at the time of this update. The subsequent multiplayer status UI commit requires its own validation.
- Remaining flat 2D interfaces outside this slice, WebView launcher/login and legacy HTML features are still not fully migrated.

## Royal arena visual differentiation and remaining HUD migration (2026-11-25)
- Replaced the LAN multiplayer connection status flat HUD with a spatial Label3D attached to the player camera. The underlying ENet implementation remains LAN-only.
- Replaced the four royal mini-game shared arena's generic presentation with per-game accent themes (Guess Who cyan, Royal Bomb red, Murder Mystery violet, Royal Dice green), a 3D title crest and four decorative beacon plinths.
- The arena work changes presentation only; it does not claim cross-device multiplayer, authoritative game rules or cloud result persistence.
- Godot parse/startup validation passed for commit `0f7211d38ee0ac1176ec2ab201f83d0243b018d6`. The newer per-arena theme commit requires its own validation, and Android build/smoke runs for the immediately preceding commit were still in progress at the time of this note.

## Validation correction — royal arena decoration placement (2026-11-25)
- The first per-arena decoration edit placed its crest/beacon block in the wrong function scope; Godot parse validation correctly rejected it in run `45525328832`.
- Corrected the block placement in commit `d0b0e6e7affee29958a91b91a197f67d94e88504`; a fresh Godot parse/startup, Android debug, embedded smoke and signed-release workflow set has been triggered and must pass before this arena slice is considered validated.

## Credential boundary hardening (2026-11-25)
- Removed the Developer refresh token from the Godot signal contract and from the 3D hub's parsed response values. Only the short-lived access token and public publishable key are handed to the world-session verifier; refresh credentials remain in the Android host authentication layer.
- This reduces exposure of long-lived credentials inside the game scene graph and makes the native host the sole refresh-token owner. It does not replace server-side authorization or device security testing.


## Member profile and settings 3D completion slice (2026-11-25)
- Added a spatial 3D member profile card with a procedural avatar preview and verified account identity fields (display name, username, role and status). The card is explicitly read-only; account edits are not falsely presented as saved because no profile-write API has been integrated.
- Added direct spatial 3D quality preset controls (Auto, Hemat, Seimbang, Tinggi) to the hub settings panel. Selection routes to QualityManager, updates runtime rendering and persists the preset locally.
- Updated the spatial audio/credits panel to reparent to the currently active camera when opened. This lets it open from the hub camera rather than remaining attached to the inactive gameplay camera.
- These changes complete a useful profile/settings presentation slice, not the full application migration. Cross-network chat, production avatar assets, cloud-authoritative multiplayer, Developer Center CRUD, full mini-game parity, and physical device tests remain outstanding.
