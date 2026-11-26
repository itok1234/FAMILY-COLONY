# Visual QA Execution Record — FAMILY COLONY
Date: 2026-11-26
Branch: feature/direct-3d-entry

## Result (honest gate)
Visual QA is **BLOCKED / NOT YET PASS**. A true rendered image review cannot be completed by the current headless structural test alone. The existing test `tests/world_render_capture.gd` instantiates the scene and prints `WORLD_RUNTIME_STRUCTURE: PASS`; it explicitly does not capture or assess pixels. No device screenshot or GPU-rendered screenshot was available for review during this run.

## Required checks for visual acceptance
- [ ] Render world scene with GPU/renderer (not headless structural-only mode).
- [ ] Capture and retain screenshot evidence for world/environment and player avatar.
- [ ] Confirm model is visible, correctly scaled, grounded, not clipping/floating, textures/materials present, lighting/shadows acceptable.
- [ ] Confirm camera framing and orientation; no black/blank render or fallback 2D screen.
- [ ] Inspect on Android device for frame stability, touch movement and orientation.
- [ ] Repeat visual checks after production candidate models are staged and mounted.

## Practical workaround path
1. Add a CI visual-capture job using Godot non-headless rendering under Xvfb/software rendering where supported, and upload screenshots as workflow artifacts.
2. If software rendering cannot render/import correctly, run capture on a GPU-backed runner or Android device; do not mark visual QA passed from headless-only logs.
3. Stage the production GLBs and populate the candidate manifest; candidate assets remain pending visual approval.
4. Review screenshots and fix defects before device APK testing.

## Status
This record does not approve production assets or mark visual QA complete. It records the blocker and the next executable path without resetting previously completed source work.
