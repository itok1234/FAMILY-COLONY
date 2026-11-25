# Production asset intake plan (blocked on binary asset transfer)

This is a source-selection plan, not a declaration that models are integrated.

## Avatar candidates
- Quaternius Universal Base Characters (CC0) / rigged GLB candidate.
- Alternate compatibility candidate: Gobkit CC0 rigged GLB character pack.
- Acceptance: compare silhouette and proportions against locked FAMILY COLONY avatar; reject blocky/voxel-like styles; test cosmetic customization and rig/animation compatibility. These packs are candidates, not final art approvals.

## Environment candidate
- CC0 low-poly city kit in glTF/GLB: modular buildings, roads and vegetation.
- Curate individual modules; compare against reference style and plaza scale; mobile collision proxies and LOD/instancing required.

## Prerequisite
Binary models must be downloaded, license/provenance reviewed and committed under `godot_world/assets/characters/` and `godot_world/assets/environment/`.

The current execution environment has no network access for downloading binary assets and cannot render/import them in Godot. This plan does not bypass that prerequisite. Visual release gates remain blocked until import and device visual review evidence exists.
