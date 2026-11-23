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

## Multiplayer foundation milestone\n- Added a LAN transport/session manager using Godot ENet with host, join and leave methods.\n- Added connection-state signals, a peer-ID roster and a small on-screen connection status label.\n- Default LAN port is 24560; the manager exposes `host_game(port)`, `join_game(address, port)`, `leave_game()` and `get_peer_roster()`.\n- This is transport scaffolding only: it does not yet synchronize avatar transforms, movement, animation, room state, chat, member identity or permissions. The roster is a basic connection-event roster, not a production presence service.\n- No public server address, account credentials or secrets are embedded. Host/join must be invoked by a future UI or trusted application bridge.\n\n## Not yet implemented
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
