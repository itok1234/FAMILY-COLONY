# Beranda 3D Master Benchmark

This isolated preview harness instantiates the existing production hub scene script without login, account-session or backend dependencies.

## Preview entry point
- Scene: `scenes/hub_benchmark_preview.tscn`
- Harness script: `scripts/hub_benchmark_preview.gd`

## Acceptance gates (do not mark visual lock based on headless tests)
1. Scene loads and camera is active.
2. Landscape composition: central landmark readable; plaza edge and stations not clipped.
3. Visual hierarchy: beacon, plaza rings, stations and surrounding garden read as one designed space (not primitive-only blockout).
4. Android device validation at target device resolution and frame-rate stability.
5. Touch hit areas work, no unintended auto-entry into World.
6. User evidence (device capture) reviewed before LOCK.

Headless checks are structural only. Physical Android and human visual acceptance remain mandatory.
