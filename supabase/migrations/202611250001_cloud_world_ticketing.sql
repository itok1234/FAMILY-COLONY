-- Private registry for authoritative Family Colony world servers.
-- Members with an active linked account may join without a separate ticket.
-- The game server validates the member's existing Supabase access token.

create table if not exists public.fc_world_servers (
  server_id uuid primary key default gen_random_uuid(),
  world_id text not null,
  region text not null,
  endpoint text not null,
  status text not null default 'offline'
    check (status in ('ready', 'draining', 'offline')),
  current_players integer not null default 0 check (current_players >= 0),
  max_players integer not null default 16 check (max_players between 1 and 64),
  heartbeat_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(world_id)) between 1 and 64),
  check (length(trim(region)) between 1 and 32),
  check (length(trim(endpoint)) between 8 and 255)
);

create index if not exists fc_world_servers_matchmaking_idx
  on public.fc_world_servers(status, world_id, current_players, heartbeat_at desc);

-- Remove the experimental one-time join-ticket mechanism.
drop table if exists public.fc_world_join_tickets;

alter table public.fc_world_servers enable row level security;
revoke all on public.fc_world_servers from public, anon, authenticated;
grant all on public.fc_world_servers to service_role;

comment on table public.fc_world_servers is
  'Private registry of authoritative game servers. Members join with their existing authenticated account session; no join ticket is required.';
