-- Family Colony secure database foundation. No legacy member data is imported here.
create extension if not exists pgcrypto;

create table if not exists public.fc_members (
 id uuid primary key default gen_random_uuid(),
 auth_user_id uuid unique references auth.users(id) on delete set null,
 legacy_member_id text unique,
 username text,
 display_name text not null,
 role text not null default 'Member' check (role in ('Member','Admin','Deputi','Kepsuk','Developer')),
 status text not null default 'pending' check (status in ('pending','approved','suspended')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index if not exists fc_members_username_lower_uq on public.fc_members(lower(username)) where username is not null and username <> '';

create table if not exists public.fc_wallets (
 member_id uuid primary key references public.fc_members(id) on delete cascade,
 balance bigint not null default 0 check (balance >= 0),
 updated_at timestamptz not null default now()
);
create table if not exists public.fc_wallet_transactions (
 id uuid primary key default gen_random_uuid(),
 member_id uuid not null references public.fc_members(id) on delete cascade,
 amount bigint not null check (amount <> 0),
 balance_after bigint not null check (balance_after >= 0),
 reason text not null,
 idempotency_key uuid not null unique,
 actor_auth_user_id uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now()
);
create index if not exists fc_wallet_transactions_member_created_idx on public.fc_wallet_transactions(member_id,created_at desc);

create or replace function public.fc_is_staff()
returns boolean language sql stable security definer set search_path=public
as $$
 select exists(select 1 from public.fc_members m where m.auth_user_id=auth.uid() and m.status='approved' and m.role in ('Admin','Deputi','Kepsuk','Developer'));
$$;

create or replace function public.fc_create_wallet_for_member()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 insert into public.fc_wallets(member_id,balance) values(new.id,0) on conflict(member_id) do nothing;
 return new;
end;
$$;
drop trigger if exists fc_members_create_wallet on public.fc_members;
create trigger fc_members_create_wallet after insert on public.fc_members for each row execute function public.fc_create_wallet_for_member();

create or replace function public.fc_admin_adjust_wallet(p_member_id uuid,p_amount bigint,p_reason text,p_idempotency_key uuid)
returns public.fc_wallet_transactions language plpgsql security definer set search_path=public
as $$
declare v_balance bigint; v_existing public.fc_wallet_transactions; v_result public.fc_wallet_transactions;
begin
 if auth.uid() is null or not public.fc_is_staff() then raise exception 'not_authorized' using errcode='42501'; end if;
 if p_amount=0 or p_reason is null or length(trim(p_reason))<2 or p_idempotency_key is null then raise exception 'invalid_transaction'; end if;
 select * into v_existing from public.fc_wallet_transactions where idempotency_key=p_idempotency_key;
 if found then return v_existing; end if;
 select balance into v_balance from public.fc_wallets where member_id=p_member_id for update;
 if not found then raise exception 'wallet_not_found'; end if;
 if v_balance+p_amount<0 then raise exception 'insufficient_balance'; end if;
 update public.fc_wallets set balance=balance+p_amount,updated_at=now() where member_id=p_member_id returning balance into v_balance;
 insert into public.fc_wallet_transactions(member_id,amount,balance_after,reason,idempotency_key,actor_auth_user_id)
 values(p_member_id,p_amount,v_balance,trim(p_reason),p_idempotency_key,auth.uid()) returning * into v_result;
 return v_result;
end;
$$;

alter table public.fc_members enable row level security;
alter table public.fc_wallets enable row level security;
alter table public.fc_wallet_transactions enable row level security;

drop policy if exists fc_members_read_self_or_staff on public.fc_members;
create policy fc_members_read_self_or_staff on public.fc_members for select to authenticated using(auth_user_id=auth.uid() or public.fc_is_staff());
drop policy if exists fc_wallets_read_self_or_staff on public.fc_wallets;
create policy fc_wallets_read_self_or_staff on public.fc_wallets for select to authenticated using(
 exists(select 1 from public.fc_members m where m.id=fc_wallets.member_id and m.auth_user_id=auth.uid()) or public.fc_is_staff()
);
drop policy if exists fc_transactions_read_self_or_staff on public.fc_wallet_transactions;
create policy fc_transactions_read_self_or_staff on public.fc_wallet_transactions for select to authenticated using(
 exists(select 1 from public.fc_members m where m.id=fc_wallet_transactions.member_id and m.auth_user_id=auth.uid()) or public.fc_is_staff()
);

revoke all on public.fc_members,public.fc_wallets,public.fc_wallet_transactions from anon,authenticated;
grant select on public.fc_members,public.fc_wallets,public.fc_wallet_transactions to authenticated;
revoke all on function public.fc_admin_adjust_wallet(uuid,bigint,text,uuid) from public,anon;
grant execute on function public.fc_admin_adjust_wallet(uuid,bigint,text,uuid) to authenticated;
revoke all on function public.fc_is_staff() from public,anon;
grant execute on function public.fc_is_staff() to authenticated;

comment on table public.fc_members is 'Authenticated Family Colony member identity and approved role mapping.';
comment on table public.fc_wallets is 'Server-controlled wallet balances; client access is read-only.';
comment on table public.fc_wallet_transactions is 'Wallet ledger; writes only through trusted RPC.';
