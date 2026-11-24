# FAMILY COLONY — Android + Embedded Godot 3D

## Current verified build state

- Latest checked source commit: `013dbd79497996690a1c8f1061c674dce03c8788` on `feature/direct-3d-entry`.
- Android build validation: passed in GitHub Actions for this exact commit.
- Godot 3D project validation: passed in GitHub Actions for this exact commit.
- Embedded Godot Android emulator smoke test: passed in GitHub Actions for this exact commit.
- Signed ARM release build and APK signature/package checks: passed in GitHub Actions.
- Published artifact: `v5.0.0-rc.42` (prerelease/testing), not a final production release.
- APK assets: ARM64 and ARMv7 variants. Redmi Note 8 Pro should use ARM64.
- APK publication and emulator smoke tests do not prove installation or stable gameplay on the user's physical phone.

## Application architecture

FAMILY COLONY remains one Android application. The existing WebView app and the embedded Godot 4.4.1 world are integrated in the same Android package. The Android application ID on the RC.42 build is `com.cdl.familycolonyv5d.next`; this package is intended to coexist with the older app rather than overwrite it. Keep the old app installed until the replacement is installed and verified on the device.

The existing app handles sign-in and owns session refresh. The native bridge hands Godot only a short-lived access token and publishable key. The Godot session client calls the deployed `fc-world-session` Edge Function to verify the member. Refresh tokens and service-role credentials must never be exposed to Godot or client assets.

## Implemented 3D foundation

- Godot 4 project and embedded Android Activity.
- Procedural 3D neighborhood and royal beehive citadel blockout.
- Procedural avatar with separate body parts and basic movement-driven animation.
- Third-person camera and mobile movement controls.
- Interaction targets and local social action responses.
- Honey Hunt 3D mini-game foundation with local session score only.
- LAN multiplayer transport, room/presence foundations and remote avatar proxies.
- Graphics quality profiles and a session-verification adapter.

These are working foundations, not a finished premium 3D game. Current world, buildings and avatar visuals remain procedural low-poly/blockout assets. The mini-game does not issue wallet currency or persistent rewards. LAN multiplayer is not production multiplayer and does not yet provide full server-authoritative simulation, identity-aware presence, complete chat/room synchronization or anti-cheat protection.

## Production work still required

1. Replace procedural/blockout world art with finished authored environment, buildings, materials, lighting and effects.
2. Replace the avatar blockout with production character models, rigging, customization, facial expressions, clothing and full animation sets.
3. Finish gameplay loops, mini-games, world interactions, mobile HUD, accessibility and in-world settings.
4. Complete secure member identity, room/presence/chat synchronization and server-authoritative multiplayer.
5. Implement backend-authorized invitations, privacy/block/report controls, gifts, inventory and wallet ledger with idempotency.
6. Complete account migration and cross-device persistence verification.
7. Perform physical-device profiling and testing for installation, launch/return, orientation, pause/resume, network loss, memory, heat, battery and frame pacing.
8. Run full regression tests for existing app screens and member/admin/developer permissions before final release.

A production wallet, coin transfer, gift or payment flow must never be simulated as a real transaction. Client-side points are not spendable balances. Protected actions must be validated by trusted backend services.

## Release safety gates

- Do not remove or overwrite the user's existing FAMILY COLONY app before the replacement is confirmed installed and working.
- Do not treat a CI emulator pass as a physical-device installation pass.
- Do not hide DEMO/development warnings by deleting their labels while the underlying feature remains incomplete.
- Do not call an RC/testing APK a final release.
- Do not bypass Android or Google Play Protect warnings. A warning must be investigated through signing, package provenance and security review.
- Do not include service-role keys, signing passwords, refresh tokens or other privileged credentials in source assets or logs.

## Build and release

The repository's GitHub Actions workflows validate the Android package, Godot project and embedded Godot Android smoke test. The release workflow then builds signed ARM APK variants, verifies their signatures and required packaged Godot files, and publishes a prerelease. Final release requires all production work and physical-device acceptance tests above to pass.
