# FAMILY COLONY — Cloud Multiplayer Member Beta Gate

Status: architecture and acceptance contract only. The current Godot transport is ENet LAN host/client and is not an Internet-wide shared world. This document does not claim a cloud multiplayer service is implemented.

## Decision

Do not expose the current LAN host as the member online world. For the first controlled member Beta, use a dedicated authoritative Godot 4 headless server per world instance, with Supabase retained as the identity and persistent-data authority.

The mobile client must never be the authority for member identity, room membership, movement validation, inventory, gifts, moderation, or privileged actions.

## Target connection flow

1. The existing Android app authenticates the member through Supabase Auth.
2. The app opens Godot with the short-lived access token and publishable key only.
3. Godot calls `fc-world-session` and receives a canonical active member profile.
4. The client requests a world ticket from a trusted matchmaking Edge Function using the access token.
5. Matchmaking validates the member and returns a short-lived, single-use ticket plus the selected world endpoint.
6. The client connects to a dedicated Godot headless server using the ticket. The server validates the ticket with a trusted backend before accepting the peer.
7. The server assigns the peer to a room and authoritative avatar entity. Client-provided member IDs, display names, and roles are ignored.
8. Server snapshots are replicated to clients in the same room. Clients send input intents, not authoritative transforms.
9. On logout, token revocation, kick, or session expiry, the backend revokes the ticket/session and the server removes the peer.

## Transport and deployment constraints

- Prefer a dedicated server transport that works through common mobile NAT/firewall conditions. Validate UDP/ENet reachability on Indonesian mobile carriers and Wi-Fi before choosing the final transport; if UDP reliability is inadequate, use a WebSocket-capable transport.
- Never put service-role keys or server secrets in the APK, Godot resources, exported project, or client logs.
- Keep the first closed Beta small: target 8–16 concurrent players per room, one region, bounded world interest area, and conservative snapshot frequency.
- Use server-side rate limits, bounded packet sizes, movement speed/acceleration checks, teleport rejection, room capacity checks, and reconnect timeouts.
- Persist member identity and durable social state in Supabase; do not treat transient peer IDs as account IDs.
- Presence and chat must display the canonical member name returned by trusted server state. Room visibility and chat delivery must be server-enforced.
- Do not use Supabase Edge Functions as a per-frame movement relay. They are for ticketing, matchmaking, authorization, and durable actions—not 20 Hz game-state simulation.

## Required backend components

- Ticket/matchmaking Edge Function: verifies Supabase JWT, active member mapping, account status, world access and capacity; issues short-lived single-use ticket.
- Ticket redemption service on the dedicated game server: validates ticket signature/expiry/nonce against trusted server-side configuration and prevents replay.
- Server instance registry/heartbeat: reports healthy instances, region, room capacity and deployment version.
- Durable room lifecycle: server-created room IDs, room capacity, room close/recovery behavior and reconnect policy.
- Moderation controls: kick/ban/block/report hooks checked by the server.
- Audit trail for privileged moderation and member-affecting actions.

## Client implementation boundary

- Replace public-facing LAN host/join UX with automatic ticket-based matchmaking only after the cloud server is deployed and tested.
- Keep LAN tools internal-only; do not silently fall back to LAN when cloud connection fails.
- Use input-intent RPCs and server snapshots. The client may interpolate remote avatars but cannot decide another player's position.
- Clear room state, presence, chat and local cached identity on logout, session rejection or server disconnect.
- Do not ship peer-ID chat labels or peer-ID-only presence as production social features.

## Acceptance gates

- Valid active members can obtain and redeem a single-use ticket; guest, inactive, unlinked, expired and revoked accounts are rejected.
- Ticket replay, tampered ticket, wrong audience, expired ticket and wrong world instance are rejected.
- Two or more devices on different networks join the same room and see each other with stable canonical member names.
- Movement is server-authoritative; speed hacks, teleport packets, malformed values and room-crossing attempts are rejected.
- Chat and presence are room-scoped and use server-verified member identity.
- Disconnect/reconnect, app background/resume, token refresh, logout and account revocation are tested.
- Capacity, latency, packet loss, server restart, room drain and graceful shutdown are tested.
- Android 11/ARM64 physical-device test passes before inviting external members.

## Current blockers

- No dedicated cloud game-server deployment or public endpoint is configured in this repository.
- No matchmaking/ticket Edge Function exists.
- Current `multiplayer_manager.gd`, `room_manager.gd`, `presence_manager.gd` and `chat_manager.gd` remain LAN/peer-ID foundations.
- No successful real-member multiplayer test has been completed.
- This is therefore a required implementation milestone, not a completed feature.
