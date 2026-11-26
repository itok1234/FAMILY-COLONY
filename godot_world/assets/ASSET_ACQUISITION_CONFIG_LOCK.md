# Asset Acquisition Configuration Lock

Date: 2026-11-26
Branch: feature/direct-3d-entry
Commit: 692b0a321231c0d449423914157de59a86c0cf44

## Locked
- Added `assets/asset_sources.json` with 10 explicitly listed candidate downloads from Gobkit and CC0-1.0 metadata.
- Candidates: 5 human character GLBs and 5 animal/environment companion GLBs.
- Acquisition script remains fail-closed: downloads are pending import, structural inspection, scene integration, and visual review.
- This lock applies to source-list/configuration only. It does NOT claim downloaded assets, approved production scenery, visual review, or physical-device QA.

## Remaining evidence-gated release blockers
- CI or a working download execution must fetch and verify the binary files and produce hashes/receipt.
- Godot import and scene integration.
- Actual rendered visual review, style/performance checks and manifest approval.
- Physical Redmi Note 8 Pro QA.
