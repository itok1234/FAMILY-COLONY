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
- Basic runtime graphics quality manager.
- Reusable world-interactable contract with configurable display name, action label and response.
- Contextual interaction controller using a camera raycast that can detect Area3D targets, keyboard E action, and an on-screen Android interaction button.
- Radial-style action selection with Use, Greet and Sit actions plus Cancel.
- Procedural avatar greeting wave and temporary sitting pose responses, driven by selected social actions.
- Sample welcome marker in the world to exercise the interaction flow and display a response message.

## Current art status
The neighborhood objects are procedural blockout meshes. They establish scale, navigation and composition only; they are not final photorealistic assets. The current avatar is a procedural proportion/material blockout with simple generated geometry and a basic walk cycle. It is not a final ultra-realistic character model, and has not yet been validated in the Godot editor or on a device.

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
