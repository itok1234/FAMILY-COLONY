# FAMILY COLONY — Godot / Supabase Member Session Bridge

Status: the trusted `fc-world-session` Edge Function is implemented and deployed. The Android native token handoff and Godot session adapter remain unimplemented and must pass the release gate before the 3D world is exposed to members.

## Compatibility requirements
- Preserve the existing Email/Password and Developer login flows in the WebView application.
- Keep the application ID `com.cdl.familycolonyv5d`.
- The Godot world receives a short-lived session handoff only after the existing app has authenticated the member.
- Never put the Supabase service-role key, bootstrap secret, Developer PIN, or any privileged credential in Godot resources, Android assets, logs, or client configuration.
- Do not create a second member identity store inside Godot.

## Trusted handoff sequence
1. The existing app completes its current login flow without changing its UI or credential rules.
2. The native Android host receives a short-lived access token through a narrowly scoped in-process bridge. The refresh token remains owned by the existing authentication layer and is not exposed to general Godot scripts.
3. The host opens the Godot world and supplies the access token only to a dedicated session adapter.
4. A future server-side Edge Function validates the bearer token using Supabase Auth `getUser(token)`; it must not trust a client-supplied member ID, username, role, or status.
5. The server resolves the authenticated `auth_user_id` against `public.fc_members.auth_user_id`, verifies that the member is active, and returns the canonical member profile and a minimal permission snapshot.
6. Godot stores the minimum session data in memory for the current world session. On logout, expiry, invalidation, or account status change, the world session is closed and sensitive in-memory values are cleared.
7. Any protected mutation is re-authorized by the backend at the time of the action. A cached role/permission snapshot is for UI presentation only.

## Proposed verification contract

Request:
- HTTPS POST to a future dedicated Edge Function.
- Authorization: Bearer <short-lived Supabase access token>.
- JSON body contains only an action/version marker; it must not accept a client-selected member ID or role.

Successful response:
- `ok`
- canonical `member`: `member_id`, `name`, `username`, `role`, `status`
- minimal `permissions` flags computed on the server
- `session_expires_at` or equivalent server-derived expiry metadata

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
- The Android native bridge that obtains the current access token and passes it to Godot is not implemented yet. The Godot client session adapter, expiry/logout handling, and protected action endpoints are also pending.
- Multiplayer, room, presence, and chat still use ENet peer IDs and are not yet bound to verified FAMILY COLONY member identities. Do not expose these as production social features until the native bridge, server checks, and acceptance tests are complete.
