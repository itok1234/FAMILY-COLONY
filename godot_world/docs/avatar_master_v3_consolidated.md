# FAMILY COLONY — Master Avatar V3 Consolidated Specification

Status: Consolidated implementation target (runtime/build validation deferred to final APK)

## Identity and rig invariants
- Preserve the same base character identity, proportions, face, body pattern, wings and rig across customization.
- Avatar proportions: A2 proportion B.
- Hands: five fingers.
- Antennae: two.
- Wings: transparent.
- Face: oval eyes, natural mouth, custom face features (A6).
- Hair: A5 both hairstyle model and dynamic hair; distinct masc/fem options.
- Avatar option set A7.16: Option D.
- Avatar remains a consistent 3D model; do not substitute a 2D portrait, flat sprite, or placeholder box model.

## Customization dimensions
- Color, outfit/costume, accessory and cosmetic wing variants are customization layers.
- Cosmetic layers must not alter the base identity, rig proportions, or core animation compatibility.
- Existing style palette/profile persistence and profile-to-world appearance bridge are retained; integration regressions are not accepted.

## Runtime integration
- Character customization changes must persist locally and flow from profile into world avatar.
- Keep a stable rig and animation interface for locomotion, idle, interaction and emotes.
- Character controls, camera and movement remain compatible with 3D world entry/exit.
- Keep avatar creation and customization in the project’s real 3D pipeline; no demo/2D fallback presented as final.

## Quality target
- Premium polished 3D character: coherent proportions, smooth deformation, readable face, natural hair and wing motion, consistent lighting/material quality.
- Avoid rigid/stiff movement and generic placeholder visuals.
- Optimize assets and draw calls for Android performance without imposing an arbitrary APK-size ceiling; visual quality takes priority.

## Combined work checklist
- [ ] Review existing avatar customization, profile bridge, world avatar and rig assets as one integrated set.
- [ ] Consolidate base identity/rig and customization-layer rules.
- [ ] Implement and connect remaining 3D customization and animation/appearance hooks.
- [ ] Verify persistence and world application in project runtime.
- [ ] Validate visuals, interactions, performance and regressions on final Android APK (user testing intentionally deferred until real APK).

## Evidence boundary
This file records consolidated target/specification only. It does not claim that remaining implementation, runtime validation, or final APK testing has been performed.
