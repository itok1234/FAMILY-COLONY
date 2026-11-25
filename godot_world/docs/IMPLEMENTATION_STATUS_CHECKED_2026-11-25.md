# FAMILY COLONY — Checked Implementation Inventory (25 Nov 2026)

Branch reviewed: `feature/direct-3d-entry`. This inventory consolidates existing audit/backlog/scope docs and source inspection to avoid reopening already documented tasks. It is an inventory, not evidence of physical-device visual acceptance.

## Already present — preserve; do not redo without a verified regression
- Godot 4 project and scenes: `world.tscn`, `main_hub_3d.tscn`; Android-first Compatibility renderer.
- Procedural environment construction (plaza/roads/building shells/trees/lamps/benches/citadel/skyline/fountain details); explicitly placeholder/blockout art.
- Procedural avatar blockout, local color-preview API, basic gait/idle/blink/wave/sit behavior; no production rig or authored assets.
- Player controller, camera orbit, mobile joystick/touch controls and contextual action button/menu; prior movement smoothing changes.
- Local settings/audio controls and procedural ambient audio; settings persistence foundation.
- Community Hub interior prototype, portals, object-interaction contracts and collision refinements.
- ENet LAN host/join/leave, remote avatar proxies and LAN gesture relay foundation.
- LAN room registry and room-scoped chat UI/transport with validation and bounded in-memory history.
- Supabase member-session bridge and server-side session verification flow; automated smoke previously exercised bridge response path but not successful physical-device active-member entry.
- Existing automated scripts: avatar, hub, chat, presence, room tests; CI validation/build workflows and Android build smoke/release checks documented in audit.
- Scope/visual lock, art backlog, asset integration gate, Android release gate, cloud multiplayer beta contract and wallet/gifts backend contract are already documented. Do not recreate these planning documents.

## Verified missing / incomplete (implementation work remains)
### P0 — genuine authored 3D art
- Audit documents/tree scan found no imported authored asset packages (.glb/.gltf/.png/.jpg/.webp/.blend/.obj/.fbx) in the reviewed project tree at that snapshot.
- Replace—not merely decorate—the placeholder avatar with rigged model, authored animation set, facial/hair/clothing/cosmetic slots and compatible materials.
- Replace core plaza/buildings/fountain/landscape/landmark placeholder geometry with reference-matched authored assets and PBR materials; integrate and validate collisions/lighting/camera.
- Replace room/lobby interior furniture and structural placeholders with cohesive authored assets.

### P1 — four 3D games and functional integration
- Verify/implement complete real 3D arenas, game rules, gameplay objects, avatar/control/camera, transitions, and integrated routing for Guess Who, Royal Bomb, Royal Murder Mystery, and Royal Dice. Existing scope lock confirms the four titles; this inventory does not claim their implementations are complete.
- Verify the full login-to-hub-to-world return/orientation transition and touch usability with visual evidence.

### P1 — member onboarding/auth and multiplayer
- Member self-registration/application route is not present as complete flow; audited function action list has login/activate but no public register action. Implement trusted application/approval flow without changing existing login, and test it.
- Multiplayer currently LAN-only/in-memory; not a deployed cloud world service, not confirmed cross-network, no server-authoritative simulation/anti-cheat, and client does not yet connect to returned matchmaking endpoint.
- Chat/roster identity currently transport peer IDs, not verified member identities; room/chat persistence and production authority/moderation remain missing.

### P2 — acceptance and release
- Actual screenshots/video visual QA on Android device/emulator against supplied reference for avatar, plaza, interiors, game arenas, touch controls and login/hub/world navigation.
- Physical-device authenticated member test, profiling (FPS/memory/thermal), full regression, signing/export validation and release acceptance after P0 art gaps close.
- No server/cloud spend without user approval.

## Work-control rule
This inventory supersedes redundant status re-listing for the checked items. Completed foundation items above are not reopened unless a concrete failure is recorded. The next implementation effort should target P0 authored avatar and core environment assets; a documentation-only commit, decorative procedural mesh, or successful APK packaging is not counted as visual completion.
