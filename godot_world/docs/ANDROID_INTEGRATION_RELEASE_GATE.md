# FAMILY COLONY — Android Integration & Release Gate

Status: readiness checklist only. No Android APK/AAB was built, installed, or device-tested as part of this milestone.

## Preserve the current application
- Keep application ID `com.cdl.familycolonyv5d`.
- Keep the existing Android WebView application, working Email/Password login, Developer login, current assets, and Supabase integration intact.
- Do not replace the current app with a standalone Godot demo.
- Do not change authentication while integrating the world engine.
- Developer Center remains Developer-only; Developer may still enter the world as a normal member.

## Integration sequence
1. Export a minimal Godot Android library/module from the isolated Godot project only after the project parses and runs in the editor.
2. Create a reversible Android integration branch and preserve a known-good build of the current application.
3. Add an explicit navigation bridge from the existing app to the Godot world and a reliable return-to-app path.
4. Pass a short-lived, verified Supabase session token through a secure native bridge. Never place service-role keys or long-lived secrets in the client.
5. Validate the token server-side before mapping it to a FAMILY COLONY member ID, role, profile, privacy settings, and permissions.
6. Test Android back navigation, pause/resume, network loss, logout, session expiry, audio focus, and memory cleanup.
7. Profile low-, mid-, and high-range Android devices; test heat, battery, frame pacing, memory, and graphics fallback.
8. Produce signed APK/AAB only after regression tests confirm the existing login and application flows remain unchanged.

## Release blockers
- Godot editor/headless project validation.
- Authenticated Supabase bridge and server-side authorization.
- Real device profiling and performance thresholds.
- Full regression of existing app screens and member/admin/developer permissions.
- Privacy, chat moderation, account blocking/reporting, and data retention policies.
- Store signing, versioning, privacy disclosures, and Play Console review.

## Visual quality gate
Ultra-realistic 3D remains the approved art target. The current procedural avatar and neighborhood are blockout assets, not the finished visual standard. Ultra/High/Balanced/Performance profiles may change rendering quality only and must never unlock or hide gameplay features.

## Do not release as a demo substitute
The Godot world must be integrated as one part of the existing FAMILY COLONY application. A separate test export may be used internally, but it must not be presented as the completed full app or replace the agreed product scope.
