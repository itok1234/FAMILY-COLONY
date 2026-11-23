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
- Temporary capsule avatar and movement controller.
- Keyboard movement plus on-screen touch joystick scaffold.
- Procedural neighborhood blockout: central paved plaza, road layout, community-building shells, trees, street lamps and benches.
- Basic runtime graphics quality manager.

## Current art status
The neighborhood objects are procedural blockout meshes. They establish scale, navigation and composition only; they are not final photorealistic assets. The capsule is not a final avatar.

## Not yet implemented
- Production avatar models, skeletons, facial expressions, hair/clothing simulation and animation sets.
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
