# World–Lobby Integration & QA Gate

## Scope and preservation
This gate covers the already implemented World 3D, Lobby/Room source and their integration. It does not reopen or replace those implementations.

## Integration surface (source review)
- World session verification gate controls Android entry.
- Main 3D hub emits room actions and receives room snapshots/results.
- World controller connects RoomManager snapshot, local-room and result signals.
- MultiplayerManager state is surfaced to the hub.
- RoomManager maintains host-side membership, capacity checks, room lifecycle, lobby shards, snapshot sanitation and disconnect cleanup.
- Chat and presence managers have regression tests; snapshots and incoming chat are sanitized.

## Existing automated regression suite
The GitHub Actions workflow `.github/workflows/godot-validation.yml` already runs:
- Godot 4.4.1 headless project import/parse check.
- `tests/room_manager_test.gd`
- `tests/chat_manager_test.gd`
- `tests/presence_manager_test.gd`
- `tests/hub_3d_test.gd`
- `tests/avatar_3d_test.gd`
- World startup smoke test.

## QA checklist for release candidate
- [ ] CI workflow run passes on the candidate commit (not verified in this chat).
- [ ] Android native bridge/session verification and return-to-app behavior verified on-device.
- [ ] Real multiplayer transport and server-authoritative room lifecycle verified with multiple devices.
- [ ] Room creation/join/leave, full room, reconnect, lobby shard, and stale snapshot scenarios verified live.
- [ ] Room chat and online presence verified live across devices.
- [ ] 3D visuals, controls, touch interaction, orientation and performance verified on Redmi Note 8 Pro and other target devices.
- [ ] Production persistence/backend/server deployment and security rules confirmed; current RoomManager is in-memory source and does not itself prove cloud persistence.
- [ ] APK build, install, and runtime smoke tests completed before calling release QA final.

## Current result
Source-level integration and regression-test coverage are documented and retained. Release/runtime QA is **pending** until CI execution and a real installable APK/device or multiplayer environment are available. No runtime pass, APK, or production server is claimed by this document.
