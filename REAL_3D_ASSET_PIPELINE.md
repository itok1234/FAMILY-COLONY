# FAMILY COLONY — Real 3D Production Gate

**Locked target:** a genuine, integrated 3D Android game—not a 2D demo, primitive-mesh blockout, or decorative 3D overlay.

## Existing foundation (not release art)
The current procedural scripts `environment_builder.gd` and `avatar_visual.gd` are explicitly blockout/procedural implementations. Keep useful gameplay, movement, login, and scene logic where possible, but do not treat those meshes as final art or repeatedly decorate them as a substitute for replacement.

## Art asset pipeline
- Author/retrieve actual model assets in Blender or another 3D authoring tool; export as glTF 2.0 (.glb) for Godot import.
- Environments: modular authored architecture, readable silhouette, layered materials, texture maps, lighting, collision, LOD or mobile-appropriate mesh budgets.
- Avatar: consistent base proportions and identity, proper skeleton/skin weights, five-finger hands, two antennae, transparent wings, customizable clothing/hair/cosmetics, and authored animation clips (idle, walk, run, social actions).
- World and interiors: scene-authored assets with walkable spaces, collision, props, interaction points, and coherent lighting—not closed facade boxes or text labels standing in for rooms.
- Minigames (Guess Who, Royal Bomb, Royal Murder Mystery, Royal Dice): real 3D spaces and in-world interactive objects, integrated into the shared world/session flow.
- Preserve login and existing working systems; migration should replace presentation assets and only alter gameplay systems where required for proper integration.

## Acceptance gates before sharing an APK
1. No procedural blockout meshes presented as final art in core player-facing scenes.
2. Inspect actual running Android scene captures of avatar, plaza, buildings/interiors, and minigame scenes; code/build success alone is not proof of visual quality.
3. Verify movement, camera, interaction, orientation transitions, chat, audio settings, and session behavior on-device or through a documented smoke test.
4. Record visual evidence and test results with the build. If evidence or required assets are absent, label it an internal prototype—not a release candidate—and do not ask the user to test it as the finished product.
5. APK size is not a quality gate; visual evidence and integrated assets are.

## Work sequencing
Replace core environment and avatar art foundations first; then integrate room/interior and minigame art; then perform performance, Android smoke, and visual acceptance checks. Decorative additions to the old blockout do not count as completion.
