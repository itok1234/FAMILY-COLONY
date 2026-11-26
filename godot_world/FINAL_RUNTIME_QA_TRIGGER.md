# Locked finalization QA trigger

This checkpoint triggers the existing Godot validation and Android emulator smoke workflows for the locked finalization tasks only:

1. Godot runtime integration-path validation.
2. Runtime QA and regression smoke checks.

Production GLB asset recovery is intentionally deferred; bootstrap assets in CI are technical test fixtures and are not production visual acceptance. No 2D demo is accepted as final.
