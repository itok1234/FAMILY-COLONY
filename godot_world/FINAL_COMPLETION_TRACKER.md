# FAMILY COLONY — Final Completion Tracker

Branch: `feature/direct-3d-entry`

This tracker locks completed, evidenced work to prevent unnecessary reopening. Only release blockers listed below remain active.

## LOCKED — completed checkpoints (do not reopen without a regression)
- [x] Existing integration/regression work retained: World/Hub, Avatar, Room/Lobby, chat/presence and minigame scaffolding.
- [x] Asset-intake audit path resolution and structural audit separation from visual approval.
- [x] Pending production candidates do not replace fallback assets by default; candidate smoke mounting requires explicit opt-in.
- [x] Godot validation, run 45915730447, commit ec8c8a01da4db82216082ac505884754951b7c4e — PASS. Import/parse, Room/Lobby regressions, chat safety, presence, hub 3D, procedural avatar, asset-mount acceptance and world startup checks completed.
- [x] Android internal Debug APK build, run 45915730416 — PASS. Embedded Godot project pack and package/signature checks passed; artifact uploaded. Artifact size 56,588,661 bytes (~56.6 MB). This is a CI build artifact, NOT device-approved release.
- [x] Render capture workflow, run 45915730397 — PASS. World screenshot captured and uploaded. Capture job success is evidence of render capture only, not premium visual approval or production asset approval.

## ACTIVE — release blockers
- [ ] Retrieve and stage candidate GLB files into the project (artifact binary retrieval not currently available through this interface).
- [ ] Select/replace character and environment assets after direct visual review; downloaded candidates are not production approved.
- [ ] Integrate accepted models into runtime and check materials, scale, animation, camera presentation, mobile performance and visual coherence.
- [ ] Review screenshot pixels directly and confirm visual acceptance; automated capture alone does not equal aesthetic QA.
- [ ] Physical Android 11 / Redmi Note 8 Pro QA: orientation, touch/movement, interactions, chat, music/settings, return flow and performance.
- [ ] Release candidate APK only after the production-asset and visual acceptance gates pass.

## Evidence links / run IDs
- Godot validation: 45915730447
- Rendered visual capture: 45915730397 (artifact: family-colony-rendered-visual-qa)
- Android internal build: 45915730416 (artifact: FAMILY-COLONY-INTERNAL-DEBUG-ec8c8a01da4db82216082ac505884754951b7c4e)

## Limitations and policy
CI evidence cannot substitute for device QA or review of candidate asset aesthetics. Do not label the project release-final or visually approved until those gates pass. No backend/cloud purchase or deployment is authorized.
