-- Live application announcements and maintenance control.
-- Only the service-role Edge Function can read or change this singleton.
create table if not exists public.fc_app_control (
  singleton boolean primary key default true check (singleton = true),
  announcement_active boolean not null default false,
  maintenance_mode boolean not null default false,
  title varchar(100) not null default '',
  message text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  updated_by text,
  updated_at timestamptz not null default now(),
  constraint fc_app_control_valid_window check (
    starts_at is null or ends_at is null or ends_at >= starts_at
  )
);
alter table public.fc_app_control enable row level security;
revoke all on public.fc_app_control from anon, authenticated;
grant all on public.fc_app_control to service_role;
insert into public.fc_app_control (singleton)
values (true)
on conflict (singleton) do nothing;
