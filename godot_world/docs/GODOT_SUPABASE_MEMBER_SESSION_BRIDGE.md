# FAMILY COLONY — Godot / Supabase Member Session Bridge

Status: the trusted `fc-world-session` Edge Function is deployed; the existing Android app now embeds the Godot 4.4.1 engine and has a native session handoff plus a Godot verification adapter. CI compilation, JavaScript lint, headless parsing, and role-policy tests pass. The WebView session now refreshes before world entry and on app resume. Real-device session, lifecycle, and gameplay tests remain release blockers.

## Compatibility requirements
- Preserve the existing Email/Password and Developer login flows in the WebView application.
- Keep the application ID `com.cdl.familycolonyv5d`.
- The Godot world receives a short-lived session handoff only after the existing app has authenticated the member.
- Never put the Supabase service-role key, bootstrap secret, Developer PIN, or any privileged credential in Godot resources, Android assets, logs, or client configuration.
- Do not create a second member identity store inside Godot.

## Trusted handoff sequence
1. The existing app completes its current login flow without changing its UI or credential rules.
2. The native Android host receives a short-lived access token through a narrowly scoped in-process bridge. The refresh token remains owned by the existing authentication layer and is not exposed to general Godot scripts.
3. The Android host opens `WorldActivity` and supplies the access token plus the project publishable key to the dedicated `FamilyColonyBridge` plugin. The publishable key is sent only in the `apikey` HTTP header; it is not a privileged secret.
4. `WorldSessionClient` sends HTTPS POST to `/functions/v1/fc-world-session` with `Authorization: Bearer <access token>`, `apikey: <publishable key>`, and an empty JSON object. It does not persist the access token or receive the refresh token.
5. The deployed Edge Function validates the bearer token using Supabase Auth `getUser(token)`; it does not trust a client-supplied member ID, username, role, or status.
6. The server resolves the authenticated `auth_user_id` against `public.fc_members.auth_user_id`, verifies that the member is active, and returns the canonical member profile and a minimal permission snapshot.
7. Godot stores only the minimum member profile and permission snapshot in memory. Returning to the Android app destroys the world Activity and its session adapter. Invalid or expired tokens fail closed.
8. Any protected mutation is re-authorized by the backend at the time of the action. A cached role/permission snapshot is for UI presentation only.

## Proposed verification contract

Request:
- HTTPS POST to `https://irwtnqekrwhgompulach.supabase.co/functions/v1/fc-world-session`.
- `Authorization: Bearer <short-lived Supabase access token>`.
- `apikey: <project publishable/anon key>`.
- JSON body is `{}`; it must not accept a client-selected member ID or role.

Successful response:
- `ok`
- canonical `member`: `member_id`, `name`, `username`, `role`, `status`
- minimal `permissions` flags computed on the server
- `verified_at` timestamp; token expiry remains governed by Supabase Auth

Failure behavior:
- 401 for missing, expired, or invalid token.
- 403 for missing, inactive, or ineligible member mapping.
- 5xx for verification or database service failure.
- Never silently fall back to guest or Developer privileges after a failed authenticated-member check.

## Role and permission boundary
- Developer can enter the world as a normal member; Developer Center remains separate and Developer-only.
- Kepsuk alone can appoint/deactivate Deputies and Admins.
- Deputies/Admins may manage Members only; they cannot appoint/deactivate Deputies/Admins.
- Kepsuk, Deputies and Admins may add/edit/delete Members within the agreed permission rules.
- Member deletion must be soft-delete/revocation, preserving historical transaction and audit records.
- UI visibility is not authorization. Every privileged operation must enforce the role rule on the server.

## Privacy and data minimization
- Do not send private profile fields, email addresses, phone numbers, password data, PINs, wallet balances, or transaction details to the world unless a specific approved screen requires them.
- Presence and chat display names must come from the verified member record, not ENet peer IDs or client-provided labels.
- Room access, invitation preferences, blocking/reporting, and guest restrictions must be checked by trusted backend logic.
- Never log bearer tokens, refresh tokens, authorization headers, or full authentication responses.

## Required acceptance tests before implementation is enabled
- Valid active member maps to exactly one canonical `fc_members` row.
- Altered client-supplied member ID/role has no effect on server identity resolution.
- Expired/revoked token, missing mapping, inactive member, and duplicate mapping fail closed.
- Developer can play as a regular member while Developer Center remains inaccessible to ordinary members.
- Role changes and account revocation take effect on the next protected server request.
- Logout and Android back-navigation clear the world session and return to the existing app.
- Existing WebView login, Developer login, and member-management flows pass regression tests unchanged.

## Current implementation boundary
- `fc-member-auth` remains the existing login and Developer authentication endpoint; its login behavior was not changed for this bridge.
- `fc-world-session` is deployed at `POST /functions/v1/fc-world-session`. It verifies the supplied Supabase access token with `auth.getUser`, resolves the canonical `fc_members` row using the verified `auth_user_id`, rejects missing/inactive/invalid-role accounts, and returns a minimal member profile plus UI permission hints.
- The endpoint does not accept a client-selected member ID or role. It does not return email, phone, wallet balance, or other private profile fields.
- `world_role` is always `member`, including for Developer, so Developer enters gameplay as a normal player. Developer Center visibility is a separate permission hint; protected Developer actions still require their own server-side authorization.
- `WorldActivity` and `FamilyColonyGodotPlugin` now provide a one-time in-memory handoff for the access token and publishable key. `WorldSessionClient` calls the deployed Edge Function and the Android world controller keeps movement/interactions locked until the server confirms access. This has passed CI compilation and headless script parsing but has not yet been exercised on the Redmi Note 8 Pro or another physical Android device.
- The current app code exposes the 3D entry setting to signed-in non-guest accounts. The server decides whether the linked member is active and may enter. This code path has only passed CI transport checks with deliberately invalid emulator credentials; successful real-member authentication and physical-device verification remain release blockers.
- The existing WebView refreshes the Supabase session before opening the world, when the app resumes, and periodically while active. For a long-running Godot Activity, a native callback asks the WebView to refresh its session every 10 minutes and returns only the new access token plus publishable key to Godot. The refresh token remains inside the WebView authentication layer. This callback loop is compiled in CI but still needs physical-device lifecycle/network testing.
- Protected world action endpoints remain pending.
- Multiplayer, room, presence, and chat still use ENet peer IDs and LAN host/client transport. They are not an Internet-wide shared world, do not survive host termination, and are not bound to verified FAMILY COLONY member identities. Do not expose these as production social features until a trusted cloud session/matchmaking/replication service and acceptance tests are complete.
