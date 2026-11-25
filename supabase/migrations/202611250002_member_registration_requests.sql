-- Public member-registration applications; applicants are not members until approved.
create table if not exists public.fc_member_registration_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_name text not null check (length(trim(applicant_name)) between 2 and 60),
  desired_username text not null check (desired_username ~ '^[a-z0-9_]{3,24}$'),
  contact text not null check (length(trim(contact)) between 3 and 100),
  reason text not null check (length(trim(reason)) between 10 and 500),
  status text not null default 'pending' check (status in ('pending','reviewing','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by text,
  review_note text
);
create unique index if not exists fc_member_registration_pending_username_idx
  on public.fc_member_registration_applications(lower(desired_username))
  where status in ('pending','reviewing');
create index if not exists fc_member_registration_status_created_idx
  on public.fc_member_registration_applications(status,created_at desc);
alter table public.fc_member_registration_applications enable row level security;
revoke all on public.fc_member_registration_applications from public, anon, authenticated;
comment on table public.fc_member_registration_applications is
  'Public signup requests only. Server-only; never grants member identity, role, status or world access.';
