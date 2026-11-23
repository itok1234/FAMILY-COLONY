-- Secure Developer PIN authentication for FAMILY COLONY.
create extension if not exists pgcrypto with schema extensions;
create table if not exists public.fc_developer_credentials (
  singleton boolean primary key default true check (singleton),
  pin_hash text,
  failed_attempts integer not null default 0 check (failed_attempts >= 0),
  locked_until timestamptz,
  updated_at timestamptz not null default now()
);
insert into public.fc_developer_credentials(singleton) values (true)
on conflict (singleton) do nothing;

create or replace function public.fc_initialize_developer_pin(p_pin text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_changed integer;
begin
  if p_pin !~ '^[0-9]{6}$' then return false; end if;
  update public.fc_developer_credentials
    set pin_hash = extensions.crypt(p_pin, extensions.gen_salt('bf', 10)),
        failed_attempts = 0, locked_until = null, updated_at = now()
    where singleton = true and pin_hash is null;
  get diagnostics v_changed = row_count;
  return v_changed = 1;
end;
$$;

create or replace function public.fc_verify_developer_pin(p_pin text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v public.fc_developer_credentials;
begin
  if p_pin !~ '^[0-9]{6}$' then return false; end if;
  select * into v from public.fc_developer_credentials where singleton = true for update;
  if not found or v.pin_hash is null then return false; end if;
  if v.locked_until is not null and v.locked_until > now() then return false; end if;
  if public.crypt(p_pin, v.pin_hash) = v.pin_hash then
    update public.fc_developer_credentials set failed_attempts=0, locked_until=null, updated_at=now() where singleton=true;
    return true;
  end if;
  update public.fc_developer_credentials
    set failed_attempts = failed_attempts + 1,
        locked_until = case when failed_attempts + 1 >= 5 then now() + interval '15 minutes' else null end,
        updated_at = now()
    where singleton = true;
  return false;
end;
$$;

alter table public.fc_developer_credentials enable row level security;
revoke all on public.fc_developer_credentials from public, anon, authenticated;
revoke all on function public.fc_initialize_developer_pin(text) from public, anon, authenticated;
revoke all on function public.fc_verify_developer_pin(text) from public, anon, authenticated;
grant execute on function public.fc_initialize_developer_pin(text) to service_role;
grant execute on function public.fc_verify_developer_pin(text) to service_role;
