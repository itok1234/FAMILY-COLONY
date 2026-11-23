-- Live maintenance and announcement control for FAMILY COLONY APK.
-- All reads/writes go through the fc-member-auth Edge Function using service role.
create table if not exists public.fc_app_control (
  singleton boolean primary key default true check (singleton = true),
  announcement_active boolean not null default false,
  maintenance_mode boolean not null default false,
  title text not null default '',
  message text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  updated_by text references public.fc_members(member_id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint fc_app_control_title_length check (char_length(title) <= 100),
  constraint fc_app_control_message_length check (char_length(message) <= 2000)
);

insert into public.fc_app_control(singleton, announcement_active, maintenance_mode, title, message)
values (true, false, false, '', '')
on conflict (singleton) do nothing;

alter table public.fc_app_control enable row level security;
revoke all on public.fc_app_control from public, anon, authenticated;
grant all on public.fc_app_control to service_role;

comment on table public.fc_app_control is
  'Single live control record for FAMILY COLONY announcements and maintenance; accessed only by trusted Edge Function.';
