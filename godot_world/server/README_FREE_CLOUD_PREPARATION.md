# FAMILY COLONY — No-Cost Cloud Server Preparation

Status: PREPARATION ONLY. No cloud account, VM, public IP, server process, or billable resource has been created.

## Cost decision
- The project owner has selected a zero-spend phase. Do not create paid resources, upgrade a cloud account, attach paid services, or enable automatic scaling without explicit approval.
- Preferred first evaluation: Oracle Cloud Infrastructure (OCI) Always Free Ampere A1, subject to account eligibility and capacity. OCI documents up to 2 OCPUs and 12 GB RAM in the Always Free allowance. This is a free-tier ceiling, not a promise of game-server performance.
- OCI signup commonly requires a valid credit/debit card for identity verification. A temporary authorization hold may appear. Do not proceed with signup unless the owner explicitly agrees to that verification step.
- OCI home region is selected during signup and cannot be changed later. Singapore (ap-singapore-1) is the preferred latency candidate for Indonesian members, but choose it only if OCI offers it during signup and the account can provision eligible capacity there.
- Always Free capacity may be unavailable ("out of host capacity"). Never switch to a paid shape to work around it without explicit approval.

## Current server integration facts
- Godot project: Godot 4.4.1.
- Existing game transport is LAN ENet. It is not a production cloud multiplayer transport.
- Supabase member-session verification and matchmaking request/response validation exist in the client.
- Matchmaking currently returns a registered server endpoint but the client does not yet connect gameplay transport to that endpoint.
- No authoritative dedicated server binary, public cloud endpoint, server heartbeat publisher, or real cross-network multiplayer test is confirmed.
- The client must never send a Supabase service-role key to the game server or embed it in the app.
- The dedicated server must validate the existing short-lived Supabase access token server-side before assigning a canonical member identity. No separate entrance ticket or payment gate is allowed.

## Safe preparation sequence (no cloud spending)
1. Keep server work in source control and build a reproducible Linux headless server artifact.
2. Confirm the target Linux architecture and Godot 4.4.1 server export/runtime support. OCI A1 is ARM64; do not assume an x86_64 binary will run on it.
3. Add server-side Supabase Auth token verification, canonical member mapping, room lifecycle, movement authority, and bounded packet validation.
4. Add a heartbeat publisher authenticated with a server-only secret; register only healthy servers in the private `fc_world_servers` registry.
5. Define and implement the mobile-compatible secure transport before wiring matchmaking to gameplay. Never send bearer tokens over plaintext transport.
6. Add automated local/container tests for startup, health, token rejection/acceptance, capacity, disconnect cleanup, and malicious movement.
7. Only after the owner approves a provider account and any required payment-method verification, provision an explicitly Always Free eligible VM. Re-check the OCI console's estimated cost is zero before creation.
8. Deploy, verify health/heartbeat, connect two physical devices on different networks, and monitor actual CPU/RAM/network usage before inviting members.

## Cost and safety guardrails
- No paid VM shapes, paid load balancer, paid database, paid IP add-ons, snapshots, backups, or outbound services unless separately approved.
- Set cloud budget alerts where available, but alerts are not a hard spending cap.
- Do not store cloud credentials, SSH private keys, Supabase service-role keys, or server secrets in Git.
- Do not call the service production-ready until real-member cross-network tests pass.

## Current decision
No provider account or billing instrument has been authorized. This document is a preparation runbook only; it does not mean a server has been deployed.
