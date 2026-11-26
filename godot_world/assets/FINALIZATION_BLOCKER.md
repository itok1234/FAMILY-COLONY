# Combined finalization status — character + world + visual QA

This is one combined completion gate. Do not split into repeated audit cycles.

## Gate order
1. Acquire distributable production GLB assets (character and environment); retain license/source records.
2. Place character assets under `assets/characters/` and environment assets under `assets/environment/`.
3. Integrate the character into the actual world scene: skeletal rig, animations, cosmetics, controller, collision, mobile camera/controls.
4. Integrate the world assets into the actual world scene: modular buildings, terrain, vegetation, material/lighting, collision/navigation, mobile optimization.
5. Capture in-engine screenshots/video for review: character close-up and full body, animated poses, world wide view, close environment views, Android landscape runtime and interaction.
6. Populate `production_asset_manifest.json` with complete provenance and QA evidence, and set visual QA approved only after actual review.
7. Run the automated intake gate and the Godot/Android CI. Passing CI is technical evidence only; it cannot replace human visual review.

## Current blocker
No production asset binaries have been transferred to this repo. Candidate asset packs listed in the asset plan are not integrated or accepted. This runtime cannot download/import/render Godot assets interactively, so claiming this combined package final would be false. Keep release packaging blocked.

## No repeated work
Already implemented world/lobby, avatar systems and minigame pipeline are retained. Only asset acquisition, production integration, and visual evidence review remain in this combined package. Do not restart these subsystems.
