-- FAMILY COLONY operational finance ledger (WPS-ready reporting foundation).
-- This ledger is separate from game Coins/Honey and never treats game currency as cash.
create extension if not exists pgcrypto;

create table if not exists public.fc_finance_accounts (
  id uuid primary key default gen_random_uuid(),
  account_code text not null unique,
  account_name text not null,
  currency_code text not null default 'IDR',
  opening_balance bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (currency_code = 'IDR')
);

insert into public.fc_finance_accounts(account_code, account_name, currency_code, opening_balance)
values ('MAIN-IDR', 'Kas Operasional FAMILY COLONY', 'IDR', 0)
on conflict (account_code) do nothing;

create table if not exists public.fc_finance_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.fc_finance_accounts(id),
  transaction_type text not null check (transaction_type in ('income','expense')),
  amount bigint not null check (amount > 0),
  category text not null check (length(trim(category)) between 2 and 80),
  description text not null check (length(trim(description)) between 2 and 500),
  reference_code text,
  idempotency_key uuid not null unique,
  actor_auth_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists fc_finance_transactions_created_idx
  on public.fc_finance_transactions(created_at desc);
create index if not exists fc_finance_transactions_account_created_idx
  on public.fc_finance_transactions(account_id, created_at desc);

create table if not exists public.fc_finance_audit (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid references public.fc_finance_transactions(id) on delete set null,
  action text not null,
  actor_auth_user_id uuid references auth.users(id) on delete set null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.fc_is_developer()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.fc_members m
    where m.auth_user_id = auth.uid()
      and m.status = 'Aktif'
      and m.role = 'Developer'
  );
$$;

create or replace function public.fc_record_finance_transaction(
  p_type text,
  p_amount bigint,
  p_category text,
  p_description text,
  p_reference_code text,
  p_idempotency_key uuid
)
returns public.fc_finance_transactions
language plpgsql security definer
set search_path = ''
as $$
declare
  v_account public.fc_finance_accounts;
  v_existing public.fc_finance_transactions;
  v_tx public.fc_finance_transactions;
begin
  if auth.uid() is null or not public.fc_is_developer() then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_type not in ('income','expense')
     or p_amount is null or p_amount <= 0
     or p_category is null or length(trim(p_category)) not between 2 and 80
     or p_description is null or length(trim(p_description)) not between 2 and 500
     or p_idempotency_key is null then
    raise exception 'invalid_finance_transaction';
  end if;

  select * into v_existing
  from public.fc_finance_transactions
  where idempotency_key = p_idempotency_key;
  if found then return v_existing; end if;

  select * into v_account
  from public.fc_finance_accounts
  where account_code = 'MAIN-IDR'
  for update;
  if not found then raise exception 'finance_account_not_found'; end if;

  insert into public.fc_finance_transactions(
    account_id, transaction_type, amount, category, description,
    reference_code, idempotency_key, actor_auth_user_id
  ) values (
    v_account.id, p_type, p_amount, trim(p_category), trim(p_description),
    nullif(trim(coalesce(p_reference_code,'')),''), p_idempotency_key, auth.uid()
  ) returning * into v_tx;

  insert into public.fc_finance_audit(transaction_id, action, actor_auth_user_id, details)
  values (v_tx.id, 'finance_transaction_created', auth.uid(),
    jsonb_build_object('type',p_type,'amount',p_amount,'category',trim(p_category)));

  update public.fc_finance_accounts
  set updated_at = now()
  where id = v_account.id;

  return v_tx;
end;
$$;

alter table public.fc_finance_accounts enable row level security;
alter table public.fc_finance_transactions enable row level security;
alter table public.fc_finance_audit enable row level security;

drop policy if exists fc_finance_accounts_developer_read on public.fc_finance_accounts;
create policy fc_finance_accounts_developer_read on public.fc_finance_accounts
for select to authenticated using (public.fc_is_developer());

drop policy if exists fc_finance_transactions_developer_read on public.fc_finance_transactions;
create policy fc_finance_transactions_developer_read on public.fc_finance_transactions
for select to authenticated using (public.fc_is_developer());

drop policy if exists fc_finance_audit_developer_read on public.fc_finance_audit;
create policy fc_finance_audit_developer_read on public.fc_finance_audit
for select to authenticated using (public.fc_is_developer());

revoke all on public.fc_finance_accounts, public.fc_finance_transactions, public.fc_finance_audit from public, anon, authenticated;
grant select on public.fc_finance_accounts, public.fc_finance_transactions, public.fc_finance_audit to authenticated;
revoke all on function public.fc_record_finance_transaction(text,bigint,text,text,text,uuid) from public, anon, authenticated;
grant execute on function public.fc_record_finance_transaction(text,bigint,text,text,text,uuid) to authenticated;
revoke all on function public.fc_is_developer() from public, anon;
grant execute on function public.fc_is_developer() to authenticated;

comment on table public.fc_finance_transactions is
  'Immutable operational cash ledger, separate from in-game Coins and Honey; WPS/Excel reporting source.';
comment on table public.fc_finance_audit is
  'Audit trail for operational finance changes.';
