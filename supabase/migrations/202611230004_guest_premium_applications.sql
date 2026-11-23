-- Guest Premium: server-verifiable guest sessions and membership applications.
alter table public.fc_guest_visits
  add column if not exists token_hash text unique;

create table if not exists public.fc_guest_membership_applications (
  id uuid primary key default gen_random_uuid(),
  guest_visit_id uuid not null references public.fc_guest_visits(id) on delete restrict,
  applicant_name text not null check (length(trim(applicant_name)) between 2 and 60),
  contact text,
  reason text not null check (length(trim(reason)) between 10 and 500),
  recommender_member_id text not null references public.fc_members(member_id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','reviewing','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by text,
  review_note text
);
create index if not exists fc_guest_applications_status_created_idx
  on public.fc_guest_membership_applications(status, created_at desc);
create index if not exists fc_guest_applications_recommender_idx
  on public.fc_guest_membership_applications(recommender_member_id);

alter table public.fc_guest_membership_applications enable row level security;
revoke all on public.fc_guest_membership_applications from anon, authenticated;
comment on column public.fc_guest_visits.token_hash is 'SHA-256 hash of the opaque guest session token; raw token is returned once at guest login.';
comment on table public.fc_guest_membership_applications is 'Guest Premium membership applications. Read/write is server-only; approval must be performed by authorized management workflow.';
