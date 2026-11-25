# FAMILY COLONY — Parallel Finalization Workplan

Branch: feature/direct-3d-entry

## Parallel tracks (keep previously completed feature work intact)

### Track 1 — Integration & scene consistency
- Review connections among world scene, world controller, avatar controller, room manager, presence/chat, mobile controls, mini-game manager and settings.
- Validate via Godot CI. Do not treat code review as runtime pass.

### Track 2 — Automated validation
- Trigger/review the Godot validation and Android debug build workflows on a candidate commit.
- Capture exact commit, run IDs, test outcomes and build artifact checksums.
- Any failure must be fixed at source and re-run; no pass inferred from workflow configuration.

### Track 3 — Premium authored 3D quality
- Audit character and environment authored GLB/GLTF inventory; source paths and files must be present.
- Character checklist: silhouette/proportions, face, five-finger hands, two antennae, translucent wings, hair variants, rig/animation and customization.
- Environment checklist: world composition, buildings/props/vegetation, material quality, lighting, scale, collision, mobile performance and interaction landmarks.
- Minigames: preserve all four and review distinct 3D presentation and usable interaction in their final scenes.
- Procedural primitives/blockout are not evidence of premium final art.

### Track 4 — Android candidate and device QA
- Package/identity/signature/embedded-project checks in build workflow.
- On device: install/launch, login/home/world transition, landscape consistency, movement/action, chat, music toggle, return navigation, stability/performance.
- Do not ask the user to install/test a provisional APK; only invite testing when a candidate has cleared source, asset and CI gates.

### Track 5 — Multiplayer/server
- Live test with multiple clients for host-authoritative room lifecycle, presence, chat, reconnect, capacity and shard behavior.
- Confirm persistence/security and deployment separately. In-memory manager alone is not a production backend.
- No server purchase/deployment without user approval.

## Status rules
- Mark a track complete only with evidence attached (commit, CI run, APK, device log, server test).
- Prior Avatar V3, mini-game, World and Lobby source work is preserved and not reopened as a repetitive task.
- This workplan records coordinated work but is not itself proof that tests, assets, APK or live service are complete.
