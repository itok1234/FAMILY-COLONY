# RC-3 Comprehensive 3D Repair Scope

Status: ACTIVE REPAIR TRACK — NOT A RESET; NO APK ACCEPTANCE CLAIM.

Base: feature/direct-3d-entry (locked baseline retained)
Branch: fix/rc3-comprehensive-3d-repair

## Confirmed RC-2 device findings
- Login remains visually 2D.
- Auth success bypasses Beranda and opens World.
- World lag; avatar absent.
- World load is prolonged and lacks progress/status indication.
- World layout does not fit phone fullscreen; blank/unused regions.
- Other features could not be meaningfully accepted due to flow.

## Coordinated repair objectives
1. Trace Android launcher/session/login bridge and route authenticated users to a 3D Beranda, not directly to World.
2. Implement/rework login visual presentation as an actual 3D scene (not a 2D image/overlay masquerading as 3D); retain existing authentication backend.
3. Ensure Beranda is a 3D navigable hub with visible avatar, feature navigation and explicit World entry.
4. Diagnose missing avatar via scene ownership, visibility, runtime asset mounting, animation/controller and session-profile application.
5. World presentation: fullscreen/orientation/viewport and UI adaptation, loading feedback, scene/asset load lifecycle and return route.
6. Audit rendering/asset/material/lighting complexity and target-device performance; profile/measure where tooling permits, do not assert measured FPS without device evidence.
7. Audit navigation and interactions for chat, rooms, settings/music and scoped minigames; distinguish working, placeholder and backend-blocked features.
8. Create one coordinated candidate only after build and automated/in-engine checks; user device acceptance is required for actual visual/performance acceptance.

## Guardrails
- Keep prior locked gates and build evidence intact.
- Do not reset or rebuild the project from scratch.
- Preserve authentication/backend/security behavior unless a dependency is proven to require change and is explicitly documented.
- Do not claim visual polish, real-device performance, or acceptance PASS based solely on compilation/build.
- Scope references comprehensive corrections; implementation must be evidenced by commits, tests and build results.
