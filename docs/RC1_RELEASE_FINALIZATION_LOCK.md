# FAMILY COLONY — RC-1 Release Candidate Finalization Baseline

Status: **RC-1 BASELINE LOCKED (documentation scope only)**
Branch: `feature/direct-3d-entry`
Date: 2026-11-27

## Purpose
Record the release-finalization handoff without reopening prior completed or locked checkpoints, repeating their tests, or asserting unverified release readiness.

## Protected checkpoints (carry forward; do not rerun absent regression evidence)
- Godot validation PASS/LOCK (prior checkpoint)
- Android build validation PASS/LOCK (prior checkpoint)
- Embedded Android smoke validation PASS/LOCK (prior checkpoint)
- Signed release APK packaging PASS/LOCK: workflow run 45979153630, artifact 15187389947, source b53c82de499ebc4c99ff84224eb803fa4257246a; artifact SHA-256 digest reported as sha256:08701fc4ade58f3cbd93e16aefcb0709d5639b56be6755bdf5364756e863f541
- 3DSV gates G1–G5 PASS/LOCK: workflow run 45979160747, artifact 15188103614, source ae18bbd1b3fcd6d83487aadead5b8fb8c8450328
- Prior visual QA and integration locks: preserve as recorded in project continuity; no fresh evidence is claimed here.
- APK-source comparison checkpoint: APK source b53c82de... vs HEAD 9f10c45e... was previously locked on the limited finding that the two intervening commits changed only workflow/dashboard documentation, not game scenes/scripts. The APK is not claimed to have been built from HEAD.

## RC-1 documentation finalization
- Protected prior gates and locks: recorded above.
- No previous gate re-executed.
- No code, scenes, gameplay, visual QA, Android build or signing workflow changed or rerun by this documentation checkpoint.
- No APK is being declared ready for user installation or device testing by this document.

## Release readiness — explicitly not locked as PASS
Physical-device acceptance, actual release-candidate installation/acceptance, distribution sign-off, and any cloud-authoritative multiplayer deployment are not asserted as complete. These are downstream acceptance items and must be handled only when relevant, without reopening protected checkpoints.

## Stale documentation note
Older dashboard/status snapshots may conflict with the later checkpoint evidence above. Their dated, commit-scoped claims are historical snapshots and must not be used to invalidate later locked evidence. Update generated status only through its designated workflow.

## Lock rule
RC-1 documentation baseline is locked. Reopen this baseline only for new, directly relevant contradictory evidence or explicit user instruction. Continue with the next downstream step rather than repeating RC-1.
