# FAMILY COLONY — 3D World Foundation

An isolated Godot 4 project for the future FAMILY COLONY World engine.

## Visual direction
- Ultra-realistic 3D target with natural avatars, materials, lighting and environments.
- Quality profiles: Performance, Balanced, High and Ultra.
- Quality settings affect rendering only, never feature access.

## Included in this foundation
- Godot project configuration using the Compatibility renderer as a broad Android starting point.
- 3D starter scene with sky, environment lighting, directional sun and ground collision.
- Third-person camera and placeholder capsule character.
- Keyboard movement for editor smoke-testing.
- Basic runtime graphics quality manager.

## Not yet implemented
- Final avatar models, skeletons, facial expressions, hair/clothing simulation.
- Detailed terrain, roads, homes, furniture, vegetation, water and PBR materials.
- Android touch joystick, camera gestures and accessibility.
- Multiplayer authority, member presence, rooms, chat and Supabase session bridge.
- Android export/integration into the existing application.
- Device profiling, thermal testing and release validation.

## Safety boundary
This project is separate from the existing Android WebView app. The existing login/authentication, package ID, and current application assets are intentionally untouched. Do not merge the engine into the release APK until the Godot project is validated on Android and a reversible integration plan is tested.
