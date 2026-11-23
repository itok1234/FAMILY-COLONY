# FAMILY COLONY — Android Integration & Release Gate

Status: the existing Android application compiles with the Godot 4.4.1 Android engine embedded as an internal Activity. CI verifies WebView JavaScript syntax, Android compilation/signature, and the Godot world pack inside the same APK. The Supabase world-session policy tests pass and the Edge Function is deployed. No physical-device installation or end-to-end world session test has passed yet.

## Preserve the current application
- Keep application ID `com.cdl.familycolonyv5d`.
- Keep the existing Android WebView application, working Email/Password login, Developer login, current assets, and Supabase integration intact.
- Do not replace the current app with a standalone Godot demo or a second application.
- Do not change existing authentication rules.
- Developer Center remains Developer-only; Developer may still enter the world as a normal member.
- Google Play is not part of the distribution plan. Final distribution is a signed APK through direct download.

## Implemented integration foundation
- Godot 4.4.1 Android library is included in the existing Android Gradle app.
- `WorldActivity` hosts Godot within the same installed application; package ID remains unchanged.
- Gradle packages the existing `godot_world` project into `godot_world.zip` and includes it as the engine main pack.
- `FamilyColonyGodotPlugin` provides a one-time in-memory handoff for the existing app's access token and publishable key. Refresh tokens and service-role keys are not passed to Godot.
- The deployed `fc-world-session` Edge Function verifies the bearer token with Supabase Auth, resolves the canonical active member row, and returns a minimal profile/permission snapshot.
- `WorldSessionClient` sends the access token and publishable key to the Edge Function. Android gameplay remains locked until the server confirms access.
- The existing app's 3D entry is restricted to Developer during internal validation; ordinary members continue using the rest of the app.
- The WebView app refreshes Supabase sessions before entering the world, on returning to the app, and while the WebView is active. A native callback also requests a WebView refresh every 10 minutes while Godot is open; only the renewed access token and publishable key are handed back to Godot. The refresh token stays in the existing WebView authentication layer. Physical-device and network interruption tests remain release blockers.

## Remaining integration and release sequence
1. Install the internal build on the Redmi Note 8 Pro and verify launch/return, orientation, pause/resume, network loss, invalid/expired session, and memory cleanup.
2. Verify the session endpoint with a real Developer account and a normal active member account; confirm inactive and unlinked accounts fail closed.
3. Complete the approved 3D world visuals, avatar customization, mobile controls, radial/full interaction UI, and world area content. Current procedural neighborhood/avatar assets remain blockout quality.
4. Bind presence, rooms, chat, and remote avatars to verified member identities rather than ENet peer IDs alone.
5. Implement server-authorized interaction invitations, privacy settings, gifts, coin balances, transaction history, and anti-duplicate protection.
6. Complete account migration and cross-device persistence tests.
7. Profile low-, mid-, and high-range Android devices; test heat, battery, frame pacing, memory, and graphics fallback.
8. Run regression tests for all existing app screens and member/admin/developer permissions.
9. Only after all release gates pass, build and sign the final APK and publish it as a direct GitHub download.

## Release blockers
- Physical Android device test of the embedded Godot engine and secure session handoff.
- Final visual assets and full gameplay implementation.
- Server-authorized multiplayer identity, chat, interaction, invitation, gift, and wallet operations.
- Account migration, privacy, moderation, blocking/reporting, and data retention tests.
- Full regression of existing app screens and member/admin/developer permissions.
- Signed final APK verification, versioning, installation/upgrade test, and direct-download release validation.

## Visual quality gate
Ultra-realistic 3D remains the approved art target. The current procedural avatar and neighborhood are blockout assets, not the finished visual standard. Ultra/High/Balanced/Performance profiles may change rendering quality only and must never unlock or hide gameplay features.

## Do not release as a demo substitute
The Godot world must be integrated as one part of the existing FAMILY COLONY application. Internal validation builds are not final releases and must not be presented as the completed full app.
