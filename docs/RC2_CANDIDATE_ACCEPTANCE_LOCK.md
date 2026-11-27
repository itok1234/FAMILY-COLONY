# FAMILY COLONY — RC-2 Candidate Acceptance

Status: **RC-2 ACCEPTANCE BLOCKED — EVIDENCE/BUILD ACTION UNAVAILABLE**
Branch: `feature/direct-3d-entry`
Date: 2026-11-27

## Scope
RC-2 is the single candidate APK acceptance stage after the RC-1 baseline. It does not reopen prior locked gates.

## Preserved locks
- RC-1 documentation baseline: LOCK
- Godot validation, Android build validation, embedded smoke, signed packaging, 3DSV G1–G5, prior Visual QA/integration, and scoped source comparison: preserved as prior locks.

## Acceptance finding
- Previously signed APK evidence remains tied to source commit `b53c82de499ebc4c99ff84224eb803fa4257246a`, artifact `15187389947`, workflow run `45979153630`.
- The scoped source comparison previously recorded that the candidate was not built from HEAD; it must not be represented as an exact-HEAD candidate.
- RC-2 requires a candidate tied to the selected source and acceptance evidence. No supported workflow-dispatch/action invocation was available in this execution environment to start the exact-source build, and no new exact-source APK or device acceptance evidence was obtained.
- Therefore RC-2 is **not PASS** and must not be marked release-ready. This finding does not invalidate or rerun earlier locked checkpoints.

## Lock rule
This RC-2 evaluation is locked as a truthful BLOCKED finding, not a product acceptance pass. Reopen only when the concrete blocker is addressed: initiate the signed-release workflow for the selected source commit and obtain its artifact plus required acceptance evidence. No automatic RC-3 is created; this is the only remaining RC acceptance stage in the current plan.
