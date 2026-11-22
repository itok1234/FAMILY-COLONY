-- Family Colony real account activation foundation.
-- Preserve all existing member rows and wallet data.
create extension if not exists pgcrypto;

do $$
declare c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.fc_members'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%role%'
  loop
    execute format('alter table public.fc_members drop constraint %I', c.conname);
  end loop;
end $$;

alter table public.fc_members
  add constraint fc_members_role_check
  check (role in ('Kepsuk', 'Deputi', 'Admin', 'Member', 'Developer'));

-- The project owner is a technical Developer, not an operational access manager.
update public.fc_members
set role = 'Developer'
where lower(username) = 'edrick'
  and role <> 'Developer';

create table if not exists public.fc_member_activation_codes (
  member_id text primary key references public.fc_members(member_id) on delete cascade,
  code_hash text not null,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.fc_member_activation_codes enable row level security;
revoke all on public.fc_member_activation_codes from public, anon, authenticated;

create or replace function public.fc_consume_member_activation(
  p_username text,
  p_code_hash text,
  p_auth_user_id uuid
)
returns table(member_id text, name text, role text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.fc_members;
begin
  select m.* into v_member
  from public.fc_members m
  join public.fc_member_activation_codes c on c.member_id = m.member_id
  where lower(m.username) = lower(trim(p_username))
    and c.code_hash = p_code_hash
    and c.used_at is null
    and c.expires_at > now()
    and m.status = 'Aktif'
    and m.auth_user_id is null
  for update of m;

  if not found then
    raise exception 'activation_invalid_or_expired' using errcode = 'P0001';
  end if;

  update public.fc_members
  set auth_user_id = p_auth_user_id
  where public.fc_members.member_id = v_member.member_id;

  update public.fc_member_activation_codes
  set used_at = now()
  where public.fc_member_activation_codes.member_id = v_member.member_id
    and used_at is null;

  return query select v_member.member_id, v_member.name, v_member.role;
end;
$$;

revoke all on function public.fc_consume_member_activation(text, text, uuid) from public, anon, authenticated;
grant execute on function public.fc_consume_member_activation(text, text, uuid) to service_role;

comment on table public.fc_member_activation_codes is
  'Private one-time activation codes. Access only through the trusted Edge Function.';
