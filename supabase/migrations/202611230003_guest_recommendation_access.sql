-- One-time member recommendations for limited guest entry.
create table if not exists public.fc_guest_recommendation_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  created_by_auth_user_id uuid not null references auth.users(id) on delete cascade,
  created_by_member_id text not null references public.fc_members(member_id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  guest_name text,
  constraint fc_guest_recommendation_code_hash_format check (code_hash ~ '^[a-f0-9]{64}$'),
  constraint fc_guest_recommendation_expiry check (expires_at > created_at)
);
create index if not exists fc_guest_recommendation_expiry_idx
  on public.fc_guest_recommendation_codes(expires_at) where used_at is null;

create table if not exists public.fc_guest_visits (
  id uuid primary key default gen_random_uuid(),
  recommendation_code_id uuid not null unique references public.fc_guest_recommendation_codes(id) on delete restrict,
  display_name text not null check (length(trim(display_name)) between 2 and 40),
  recommender_member_id text not null references public.fc_members(member_id) on delete restrict,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  status text not null default 'active' check (status in ('active','expired','revoked'))
);
create index if not exists fc_guest_visits_expiry_idx on public.fc_guest_visits(expires_at);

alter table public.fc_guest_recommendation_codes enable row level security;
alter table public.fc_guest_visits enable row level security;
revoke all on public.fc_guest_recommendation_codes, public.fc_guest_visits from anon, authenticated;
comment on table public.fc_guest_recommendation_codes is 'Hashed one-time 24-hour guest referral codes; only trusted server actions may read or consume them.';
comment on table public.fc_guest_visits is 'Audit log of limited 12-hour guest sessions issued through an active member recommendation.';
