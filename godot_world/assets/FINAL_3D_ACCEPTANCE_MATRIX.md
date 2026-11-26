# Final 3D acceptance matrix

This is a release gate. Automated validation cannot substitute for visual review or physical device QA.

| Area | Automated evidence | Human/device evidence | State |
|---|---|---|---|
| Character assets | GLB parse, skeleton/skin/animation counts, import | proportions, materials, rig and animation review in Godot | BLOCKED: asset intake empty |
| Environment assets | GLB parse and resource checks | premium coherent scene, collision, scale, lighting, traversal review | BLOCKED: asset intake empty |
| Visual review/import | headless import and error scan | Godot editor/runtime captures | BLOCKED |
| Runtime QA | startup smoke and regression scripts | movement, camera, actions, chat, rooms, orientation and audio | PARTIAL |
| Android QA | build/emulator workflow if available | Redmi Note 8 Pro install, performance, heat, memory and inputs | BLOCKED: no physical evidence |

## Required device evidence
- Device/OS, build commit, date and tester
- Startup/login, world entry/exit captures
- Landscape world and orientation restoration
- Touch movement/camera/action interactions
- Chat, lobby, mini-game entry, music toggle
- FPS, stutter, memory, temperature and crash logs
- Network reconnect and background/foreground checks

Do not approve review items without evidence. Bootstrap meshes and procedural placeholders are not production premium assets.
