# FAMILY COLONY — Four Mini-Game Consolidated Audit & Work Gate
Date: 2026-11-25
Branch: feature/direct-3d-entry
Scope is frozen by FINAL_SCOPE_AND_VISUAL_LOCK_2026-11-25.md.

## Locked mini-games (exactly four)
1. Guess Who
2. Royal Bomb
3. Royal Murder Mystery
4. Royal Dice

Honey Hunt is a separate feature/legacy mini-game implementation and is NOT a fifth approved game in this scope. Its existing code must not be used to expand the approved count.

## Findings from source review
- The file `godot_world/scripts/honey_hunt_minigame.gd` includes implementation entry points for all four Royal games (Guess Who, Royal Bomb, Royal Murder Mystery, Royal Dice), a shared spatial 3D result/control panel and themed arena code.
- The four games currently appear to be local/single-session logic with simulated bot outcomes, not validated multiplayer gameplay. Do not claim online multiplayer is complete.
- Shared presentation uses generated spatial primitives (meshes, labels, area hit targets). This is real 3D code, but source alone does not prove reference-grade art, full arena richness, physical device usability, or parity with the concept image.
- Existing automated tests listed in the Godot tree cover avatar, chat, hub, presence, and room manager; no dedicated four-mini-game QA test file was found in this inventory.

## Consolidated completion order (do not reopen repeatedly)
1. Review the current shared mini-game arena/presentation and keep game logic intact unless a documented defect is found.
2. Improve shared 3D arena art treatment and mobile readability first, then game-specific elements and feedback for each of the four.
3. Ensure entry/exit, player reset, HUD layout and result actions are consistent and tested for all four games.
4. Add focused automated checks for start, action/result, timer/round progression where relevant, exit/return and safe state cleanup.
5. Single final QA pass on Android/emulator: visual evidence, touch interactions, performance, and regression. Physical device QA limitations are clearly disclosed.

## Release/visual acceptance (all four)
- Distinct, recognizable 3D arena environments rather than a shared generic panel alone.
- 3D objects, game feedback and avatar/camera involvement where gameplay warrants it; HUD may be 2D/overlay.
- Touch-friendly controls and readable UI on mobile.
- Game mechanics progress and end states are coherent; exit/return restores world/player state.
- Visual comparison against supplied concept direction; automated tests alone do not approve visual fidelity.

This audit defines work and boundaries only; it does not assert these criteria are already complete.
