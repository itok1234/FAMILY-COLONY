# FAMILY COLONY — Cloud Multiplayer Member Beta Gate

Status: implementation contract, not a completion claim. The repository contains a Supabase matchmaking Edge Function and private world-server registry. After member-session verification, the mobile client now requests matchmaking, validates the returned access contract, server UUID, requested world ID, and canonical member ID, then emits `matchmaking_ready` or `matchmaking_failed`. The response is not yet connected to a gameplay transport. No dedicated authoritative game-server deployment or healthy server endpoint is confirmed.

## Non-negotiable member access decision

- Every eligible active, linked FAMILY COLONY member enters without a paid ticket, entrance ticket, coin charge, or separate purchase.
- The experimental `fc_world_join_tickets` table and one-time join-ticket mechanism have been removed.
- A member's existing Supabase access token is the authentication credential. It is not an entrance ticket and must never be sold, charged, or exposed as a UI gate.
- The matchmaking endpoint selects a healthy server from the private registry and returns its endpoint. The authoritative game server must validate the same existing Supabase access token with Supabase Auth before accepting the connection.
- An active member session grants entry; roles do not create a paid or ticket-based access tier. Privileged moderation or developer actions remain separately authorized.

## Current implementation snapshot

### Present in repository
- `fc-world-session` verifies the Supabase access token, resolves the linked active member row, and returns canonical member identity and world-entry permission.
- `fc-world-matchmaking` verifies the bearer token, checks active member status, selects a ready server with a fresh heartbeat and available capacity, and returns the server endpoint plus canonical member profile.
- Migration `202611250001_cloud_world_ticketing.sql` creates the private `fc_world_servers` registry and explicitly drops the experimental `fc_world_join_tickets` table.
- The registry is service-role-only under RLS; clients cannot read or write it directly.
- Godot currently has LAN ENet host/client, room-scoped presence, chat, and remote-avatar foundations.

### Not yet implemented or verified
- Automated Godot project validation, Android debug package validation, and embedded Godot Android emulator launch smoke test passed for source commit `5aa386f720d7d9889bc63f803813899fce0b480e`. This proves the app can launch the embedded world and exercise the invalid-credential HTTP rejection path; it does not prove a real member login or a successful matchmaking/server connection.
- `WorldSessionClient` calls `fc-world-matchmaking` after a member session is verified, using the same short-lived Supabase access token and publishable key. It checks the `member_session`/`supabase_access_token` contract, server UUID, requested world ID, endpoint bounds, and returned member ID before emitting `matchmaking_ready`; failures emit `matchmaking_failed`.
- The client treats matchmaking as best-effort and does not block already verified local world entry if no cloud server is registered. It does not yet connect to the returned endpoint; transport integration and authoritative server deployment remain pending.
- No dedicated authoritative Godot headless server deployment, public endpoint, heartbeat publisher, or server-side Supabase token validation is confirmed.
- Existing LAN peer IDs are not canonical member identities and must not be presented as production cloud presence.
- No successful two-device, different-network cloud multiplayer test has passed.
- No real-member end-to-end test on a physical Android device has passed.

## Target connection flow — no entrance ticket

1. The existing Android app authenticates the member through Supabase Auth.
2. The app opens the embedded Godot world with the short-lived access token and publishable key only.
3. Godot calls `fc-world-session` and receives the canonical active member profile and `can_enter_world` permission.
4. Godot calls `fc-world-matchmaking` with the same bearer access token and a requested world ID.
5. Matchmaking selects a healthy, non-full server from `fc_world_servers` and returns its endpoint. It does not issue or require a separate entrance ticket.
6. Godot connects to the selected authoritative server using a mobile-NAT-compatible transport. The server validates the existing Supabase access token with Supabase Auth before accepting the connection.
7. The server assigns the verified member to a room and authoritative avatar entity. Client-supplied member IDs, display names, and roles are ignored.
8. Server snapshots are replicated to clients in the same room. Clients send input intents, not authoritative transforms.
9. On logout, token revocation, kick, or session expiry, the server removes the peer and clears transient room state.

## Transport and deployment constraints

- Validate UDP/ENet reachability on Indonesian mobile carriers and Wi-Fi before choosing the final transport. If UDP reliability is inadequate, use a WebSocket-capable transport.
- Never put service-role keys or server secrets in the APK, Godot resources, exported project, or client logs.
- Keep the first closed Beta small: target 8–16 concurrent players per room, one region, bounded world interest area, and conservative snapshot frequency.
- Use server-side rate limits, bounded packet sizes, movement speed/acceleration checks, teleport rejection, room capacity checks, and reconnect timeouts.
- Persist member identity and durable social state in Supabase; do not treat transient peer IDs as account IDs.
- Presence and chat must display canonical member names returned by trusted server state. Room visibility and chat delivery must be server-enforced.
- Do not use Supabase Edge Functions as a per-frame movement relay. They are for matchmaking, authorization, and durable actions—not 20 Hz game-state simulation.

## Required backend and server components

- Private server registry: implemented as a database migration; server registration and heartbeat publisher still need implementation and deployment.
- Matchmaking Edge Function: implemented in repository; deployment/configuration and client integration must be verified end to end.
- Dedicated authoritative Godot server: deploy a headless server process with trusted configuration and server-side Supabase token validation.
- Durable room lifecycle: server-created room IDs, room capacity, room close/recovery behavior, and reconnect policy.
- Moderation controls: kick/ban/block/report hooks checked by the server.
- Audit trail for privileged moderation and member-affecting actions.

## Seven parallel completion lanes

1. **Auth and member access:** preserve existing login; verify active linked member access; reject guest, inactive, unlinked, expired, and revoked sessions; no entrance ticket or payment gate.
2. **3D art and avatar:** replace procedural blockout-only character/environment art with licensed, authored, Godot-importable GLB/GLTF assets; verify rigs, materials, animation, scale, mobile draw calls, and visual quality.
3. **World client integration:** consume matchmaking endpoint, handle loading/retry/disconnect, and remove public-facing LAN host/join controls from the member path.
4. **Cloud multiplayer:** deploy authoritative headless server, heartbeat, server token validation, room assignment, authoritative movement, and remote avatar replication.
5. **Social systems:** bind chat, presence, invitations, and interactions to verified member IDs; enforce room boundaries, block/report/moderation, and logout cleanup.
6. **Android quality and release:** test real devices across low/mid/high tiers, thermal and memory behavior, pause/resume, network loss, upgrade path, signed APK and AAB build checks.
7. **iOS readiness:** prepare a separate iOS export/signing pipeline and validate supported devices, provisioning, and TestFlight. iOS cannot be declared ready from Android CI.

Work may proceed in parallel, but cross-lane integration and acceptance tests are still mandatory before release.

## Acceptance gates

- Active linked members enter with their existing account session and no separate entrance ticket or payment.
- Guest, inactive, unlinked, expired, and revoked accounts are rejected.
- Matchmaking rejects invalid world IDs, missing servers, stale heartbeats, and full servers without leaking private registry data.
- Two or more physical devices on different networks join the same room and see each other with stable canonical member names.
- The server validates Supabase identity and is authoritative for movement, room membership, and social actions.
- Speed hacks, teleport packets, malformed values, replayed/expired credentials, and room-crossing attempts are rejected.
- Chat and presence are room-scoped and use server-verified member identity.
- Disconnect/reconnect, app background/resume, token refresh, logout, and account revocation are tested.
- Capacity, latency, packet loss, server restart, room drain, and graceful shutdown are tested.
- Physical Android device testing passes before inviting external members.
- iOS is separately built and tested; Android success does not imply iOS readiness.

## Release rule

Do not label an internal APK, LAN prototype, or successful compilation as the final member Beta. Final release requires authored 3D assets, a working cloud server path, real-member authentication, cross-network multiplayer, physical-device regression, and signed distribution artifacts to pass together.
