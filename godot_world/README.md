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

## Current art status
The neighborhood objects are procedural blockout meshes. They establish scale, navigation and composition only; they are not final photorealistic assets. The current avatar is a procedural proportion/material blockout with simple generated geometry and a basic walk cycle. It is not a final ultra-realistic character model, and has not yet been validated in the Godot editor or on a device.

## Not yet implemented
- Production-quality authored avatar models, a full skeletal rig, facial expressions, hair/clothing simulation, customization and complete animation sets.
- Authored PBR material/texture library, detailed building facades, interior room sets, vegetation and water.
- Camera smoothing, polished touch HUD, settings menu and accessibility.
- Object interaction system and animation state machine.
- Multiplayer authority, member presence, room instances, chat and Supabase session bridge.
- Android export/integration into the existing application.
- Godot editor/headless validation, device profiling, thermal testing and release validation.

## Safety boundary
This project is separate from the existing Android WebView app. The existing login/authentication, package ID, and current application assets remain untouched. Do not merge the engine into the release APK until the Godot project is validated on Android and a reversible integration plan is tested.

## Engine target
Godot 4.x. Compatibility renderer is the initial baseline for broad Android support. Higher-end rendering options should only be enabled after real-device GPU, frame-rate and thermal profiling.
