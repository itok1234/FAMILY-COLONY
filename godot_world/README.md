# FAMILY COLONY — 3D World Foundation

An isolated Godot 4 project for the future FAMILY COLONY World engine.

## Visual direction
- Ultra-realistic 3D target with natural avatars, materials, lighting and environments.
- Quality profiles: Performance, Balanced, High and Ultra.
- Quality settings affect rendering only, never feature access.

## Implemented foundation
- Godot 4 project using the Compatibility renderer as an Android-first baseline.
- 3D scene with procedural sky, ambient environment lighting, directional sunlight and ground collision.
- Third-person camera with right-side touch drag on Android and right-mouse orbit in editor.
- Modular procedural avatar blockout with separate torso, neck, head, hair, eye details, arms, legs and shoes.
- Animation-ready limb pivots with procedural idle bob and walk-cycle swing driven by player movement.
- CharacterBody3D collision remains separate from the visual avatar so the art can be replaced without changing movement physics.
- Hybrid keyboard + touch movement controller.
- Keyboard movement plus on-screen touch joystick scaffold.
- Procedural neighborhood blockout: central paved plaza, road layout, community-building shells, trees, street lamps and benches.
- Added a lightweight royal beehive citadel landmark with a hexagonal keep, golden crowns, honeycomb window motifs, a royal gate and garden approach; this is a recognizable first kingdom focal point, not final authored art.
- Runtime graphics quality manager with saved user preference, Balanced Android AUTO startup, and adaptive fallback to Performance after sustained low frame rates.
- Reusable world-interactable contract with configurable display name, action label and response.
- Contextual interaction controller using a camera raycast that can detect Area3D targets, keyboard E action, and an on-screen Android interaction button.
- Radial-style action selection with Use, Greet and Sit actions plus Cancel.
- Procedural avatar greeting wave and temporary sitting pose responses, driven by selected social actions.
- Sample welcome marker in the world to exercise the interaction flow and display a response message.

## Current art status
The neighborhood and royal citadel are currently procedural low-poly/blockout meshes. Android AUTO now starts at Balanced rendering quality (0.90 render scale, 2x MSAA, shadows and glow enabled) and can fall back to Performance after sustained low frame rates. This improves rendering presentation but does not replace placeholder geometry with final authored assets. The citadel gives the first zone a clear bee-kingdom identity, but it is not final photorealistic art or a finished world. The current avatar is a procedural proportion/material blockout with simple generated geometry and a basic walk cycle. It is not a final ultra-realistic character model, and has not yet been validated in the Godot editor or on a device.

## Session presence foundation milestone\n- Added a session presence registry keyed only by ENet peer IDs, with online/offline events and snapshot requests for newly connected clients.\n- This is transport-level presence only. It does not verify member IDs, profiles, roles, account status or privacy permissions; those require a trusted Supabase session bridge.\n\n## Room foundation milestone\n- Added a host-authoritative in-memory room registry for LAN sessions.\n- Supports room creation, joining, leaving back to the lobby, capacity checks, room list snapshots and local room membership notifications.\n- New clients request a room snapshot after connecting. Room state is ephemeral and is lost when the host exits; no persistent backend or production room matchmaking is connected yet.\n\n## Multiplayer foundation milestone\n- Added a LAN transport/session manager using Godot ENet with host, join and leave methods.
- Added remote avatar proxies with smoothed position/rotation interpolation and periodic movement-intensity updates relayed through the host.
- New peers receive an initial peer-ID roster request so existing connected players can be represented locally.\n- Added connection-state signals, a peer-ID roster and a small on-screen connection status label.\n- Default LAN port is 24560; the manager exposes `host_game(port)`, `join_game(address, port)`, `leave_game()` and `get_peer_roster()`.\n- This remains an early LAN prototype: position/rotation and a basic movement-intensity value are relayed by the host, but client movement is not yet server-simulated or anti-cheat validated. It does not synchronize social action events, room state, chat, member identity or permissions. It has not been runtime-tested. The roster is a basic connection-event roster, not a production presence service.\n- No public server address, account credentials or secrets are embedded. Host/join must be invoked by a future UI or trusted application bridge.\n\n## Not yet implemented
- Production-quality authored avatar models, a full skeletal rig, facial expressions, hair/clothing simulation, customization and complete animation sets.
- Authored PBR material/texture library, detailed building facades, interior room sets, vegetation and water.
- Camera smoothing, polished touch HUD, settings menu and accessibility.
- Production radial-wheel polish, object-specific animation clips, interaction permissions and server-authoritative multiplayer validation.
- Production multiplayer authority, complete peer-roster bootstrap, member presence, room instances, chat and Supabase session bridge.\n- Server-authoritative avatar transform/movement replication and anti-cheat validation.
- Android export/integration into the existing application.
- Godot editor/headless validation, device profiling, thermal testing and release validation.

## Interaction milestone boundary
The current interaction flow and social action poses are local client-side foundations only. The sample welcome marker demonstrates target selection, a radial-style action menu and local response messages; it does not yet perform account actions, transfer items/currency, change member data, synchronize other players, or authorize multiplayer actions. Those operations must be validated by trusted backend services before release.

## Safety boundary
This project is separate from the existing Android WebView app. The existing login/authentication, package ID, and current application assets remain untouched. Do not merge the engine into the release APK until the Godot project is validated on Android and a reversible integration plan is tested.

## Engine target
Godot 4.x. Compatibility renderer is the initial baseline for broad Android support. Higher-end rendering options should only be enabled after real-device GPU, frame-rate and thermal profiling.


## Room-scoped chat foundation milestone
- Added a LAN chat transport that routes messages only to peers registered in the same host-managed room.
- The host validates room membership, trims and rejects empty/oversized messages, applies a per-peer send interval, and keeps a bounded in-memory recent-message buffer.
- Messages are currently labeled with transport peer IDs (for example, "Anggota #2"), not account names. No private/global messaging, friend list, moderation workflow, report/block system, message persistence, attachment support or Supabase identity binding is implemented.
- The current chat layer exposes signals and methods for a future chat UI; it is not yet a finished chat screen and has not been runtime-tested.


## Avatar appearance preview milestone
- Added a local preview API for skin, hair, top, trousers and shoe colors, with a snapshot method for the current preview.
- This is a color-preview scaffold only: no final avatar mesh, wardrobe catalog, owned-item validation, saved profile, or backend inventory sync exists yet.

## Interactive plaza milestone
- Added interaction zones to the generated park benches so the existing target-selection/action menu can discover seating locations.
- These zones trigger local interaction feedback only. A synchronized sit animation, seat occupancy, collision reservation and multiplayer authority are still pending.

## Wallet and gift backend contract
- Added `docs/WALLET_GIFTS_BACKEND_CONTRACT.md` describing trusted-session identity, atomic balance/item transfers, idempotency, immutable ledger history, privacy checks and acceptance tests.
- This is a specification, not a deployed wallet or gift feature. No payment, coin transfer, inventory persistence or database migration has been enabled.

## Android integration and release gate
- Added `docs/ANDROID_INTEGRATION_RELEASE_GATE.md` to preserve the existing application and define the required Godot bridge, session verification, regression tests, device profiling and store-release gates.
- No APK/AAB export, Android integration, signing, installation or device test was performed in this milestone.

## First enterable interior milestone
- Added a local portal interaction script and an enterable Community Hub interior connected to the outdoor neighborhood.
- The prototype interior includes a floor, perimeter walls, lounge seating, coffee table, community counter and warm ceiling fixture.
- Players can use the existing world interaction menu to enter the hub and return outside; the same player and camera remain active.
- This is still a single-client/local prototype. Room access permissions, synchronized interior instances, persistent furniture, detailed PBR assets, full collision coverage and multiplayer portal transitions are not implemented.
- The interior and portal scripts have not yet been parsed or tested in the Godot editor or on Android hardware.

## LAN social gesture relay milestone
- Greeting-wave and sit gesture events can now be relayed reliably through the LAN host to remote avatar proxies.
- Clients request the action from the host; the host accepts only the current allowlisted gesture IDs and relays the event with the originating peer ID.
- This synchronizes the gesture event only. It does not validate FAMILY COLONY account identity, room membership, social permissions, seat ownership or anti-spam policy, and it is not a production multiplayer authority model.
- This networking change has not been runtime-tested with multiple Godot clients.

## Supabase member-session bridge implementation
- The Android app passes a short-lived access token and publishable key to the embedded Godot Activity after a signed-in non-guest session requests world entry.
- `WorldSessionClient` calls the `fc-world-session` Edge Function; the server verifies the token and resolves the canonical active member through `fc_members.auth_user_id`.
- Godot keeps player movement locked until the server returns an allowed member identity. The latest emulator smoke test confirms the credential handoff and HTTP response path only; its deliberately invalid test token receives HTTP 401. Real-member success on physical devices remains unverified.
- See `docs/GODOT_SUPABASE_MEMBER_SESSION_BRIDGE.md` for the security boundary and acceptance tests.

## Avatar visual refinement milestone
- Refined the procedural head blockout with layered eye whites and pupils, eyebrows, nose, mouth, ears and side hair locks to make facial orientation and expression landmarks clearer.
- These are still primitive meshes and shared placeholder materials. This is not a photoreal character, production rig, facial animation system or final customizable avatar.
- The change is intended to improve the prototype while preserving the existing player controller and appearance preview API.

## Community Hub interaction refinement
- Added a warm OmniLight3D fixture to the interior rather than relying only on an emissive-looking decorative mesh.
- Added a discoverable lounge-sofa interaction target with a local rest response.
- Furniture collision, seat reservation, synced sitting alignment and server-authoritative occupancy remain future work.
- These changes have not yet been parsed or run in Godot Editor or tested on Android.

## Furniture collision refinement
- Added physical collision bodies to the outdoor bench seats/backs and the Community Hub sofa, coffee table and counter so the player is no longer expected to walk through these major furniture pieces.
- Collision is kept separate from the visual meshes and interaction Areas, allowing art replacement without coupling it to the interaction targets.
- This is still prototype-scale collision. Precise seat alignment, occupancy reservation, accessibility clearance and multiplayer authority are not implemented; Godot parsing and device behavior remain unverified.

## Neighborhood collision refinement
- Added static collision boundaries to generated community-building shells, in addition to the recent bench and Community Hub furniture collision.
- This prevents the player capsule from passing directly through the major building volumes during navigation.
- Building shells are still closed blockout volumes; doors/windows are visual placeholders, not enterable rooms. Dedicated building interiors and doorway openings must be authored before these structures become accessible.


## Persistent seating interaction milestone
- The local player controller now supports a seated movement lock and a deliberate stand-up action using the existing interaction input.
- The avatar sit pose remains active until the player stands; the gesture relay allowlist includes the matching stand event so connected LAN clients can return the remote avatar to its idle pose.
- This remains a prototype: seat snapping/alignment, occupancy reservation, collision-aware seat claims, room permissions and server-authoritative validation are not implemented. No Godot parser or runtime test was available for this commit.


## Target-specific interaction actions
- Interactable objects now expose an explicit allowlist of actions, and the action menu only displays actions supported by the selected target.
- Outdoor benches and the Community Hub sofa expose Sit and Greet; the welcome marker exposes Use and Greet; location portals expose Use only.
- The controller checks the allowlist again when an action is selected, preventing stale or hidden menu choices from being executed.
- This is local interaction UX validation only. It does not add server-authoritative permissions, synchronized seat occupancy, or production multiplayer security.


## Room chat user-interface milestone
- Added a compact in-world chat panel with message history, a text composer, send action, and visible transport errors.
- The panel uses the existing room-scoped LAN chat manager; the host still checks room membership, message length and send interval before relaying messages.
- The interface explicitly labels sender names as temporary connection peer IDs, not verified FAMILY COLONY account identities.
- Messages remain in-memory only. This does not add private messaging, moderation/report/block tools, account identity binding, persistent history, or production server infrastructure.


## Member Beta readiness — current blockers
- Authored GLB/GLTF avatar and environment assets are not yet present. Current visuals remain procedural blockout; visual quality settings do not change that art status.
- ENet multiplayer is LAN-only and host-authoritative in memory. There is no public cloud world server, durable matchmaking, or Internet-wide shared room service.
- Presence and chat labels are peer IDs, not canonical verified member identities.
- Real-member session verification has not yet passed on a physical Android device.
- The Android release workflow now blocks release until authored character and environment GLB/GLTF files are added. This gate prevents a procedural blockout from being packaged as finished 3D art.
- Do not distribute a member Beta until the art, cloud multiplayer, account verification, and physical-device acceptance gates are passed.


## Cloud multiplayer member Beta contract
- Added `docs/CLOUD_MULTIPLAYER_MEMBER_BETA.md` defining the dedicated authoritative world-server, existing member-session authentication, no-entrance-ticket access, matchmaking, identity, room, chat, anti-cheat and cross-network acceptance requirements.
- The Supabase `fc-world-matchmaking` Edge Function and private server registry are present. `WorldSessionClient` now requests matchmaking after successful member verification using the existing short-lived Supabase access token; it emits `matchmaking_ready` or `matchmaking_failed` and does not block local world entry when no cloud server is available.
- The client does not yet connect to the returned endpoint. No dedicated authoritative game-server deployment, heartbeat publisher, cross-network replication or successful cloud multiplayer test is confirmed. Current ENet remains LAN-only and must not be advertised as an online shared world.
- No entrance ticket or paid access gate is required for active linked members. The Supabase access token is an authentication credential, not an entrance ticket.
