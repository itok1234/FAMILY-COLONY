# 3D Art Asset Inventory and Import Gate
Branch: feature/direct-3d-entry
Audit snapshot: 2026-11-25
Repository tree scan found **0** imported image/model asset files with extensions .glb, .gltf, .png, .jpg, .jpeg, .webp, .fbx, .obj, or .blend in the audited branch. This is a repository-tree audit, not an exhaustive runtime inspection.

## Priority asset production/integration backlog
- P0: cohesive, rigged humanoid avatar (base body, skin/hair/clothing material variants, idle/walk/run/sit/emotes), import as glTF 2.0; test Android skeleton/animation.
- P0: reference-matched hub/lobby architectural kit, entrance, modular facade, door/window/roof/trim, floor paving and physically based material textures.
- P0: outdoor world kit: landscaped tree variants, bushes, flower beds, path stones, lamps, benches, fountain details, road markings.
- P1: community interior furnishing kit: modular sofa, chairs, tables, wall panels, lighting and floor/wall materials.
- P1: royal citadel/landmark kit, crest and banners.
- P1: interactive props and readable signage.
- P2: cosmetics, emotes, room furnishings and minigame environment kits.

## Integration standards
- Preferred model format: glTF 2.0 (.glb), verified import in Godot version used by CI.
- Textures: PBR base-color, normal, roughness, metallic only where physically appropriate; mobile texture-size/memory budget enforced.
- Meshes: clean scale/orientation, LOD or sensible detail budgets; collision meshes separate/simplified.
- Keep decorative meshes out of physics; collisions use simple shapes or dedicated low-poly collision geometry.
- Materials/lighting and final camera framing must be compared against user's visual reference in actual Android screenshots.
- Maintain naming and folder conventions under res://assets/; never silently substitute procedural placeholders for missing production assets.
- Placeholder status must be visible in QA reports; no release approval until P0 asset gaps and visual review are resolved.

## Acceptance status
This inventory records work to do and the asset audit finding. It is not a claim that these assets exist, have been imported, or tested.
