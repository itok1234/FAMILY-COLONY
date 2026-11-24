-- Cloud world matchmaking registry and single-use member tickets.
-- This is backend groundwork; no world server is considered available until an
-- operator registers a healthy server heartbeat with service-role credentials.

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

create table if not exists public.fc_world_join_tickets (
  ticket_hash text primary key,
  member_id text not null references public.fc_members(member_id) on delete cascade,
  server_id uuid not null references public.fc_world_servers(server_id) on delete cascade,
  world_id text not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists fc_world_join_tickets_expiry_idx
  on public.fc_world_join_tickets(expires_at)
  where consumed_at is null;

alter table public.fc_world_servers enable row level security;
alter table public.fc_world_join_tickets enable row level security;

revoke all on public.fc_world_servers, public.fc_world_join_tickets from public, anon, authenticated;
grant all on public.fc_world_servers, public.fc_world_join_tickets to service_role;

comment on table public.fc_world_servers is
  'Private registry of dedicated authoritative game servers; heartbeat writes are server-operator only.';
comment on table public.fc_world_join_tickets is
  'Hashed, short-lived, single-use tickets; raw ticket values are never stored.';
