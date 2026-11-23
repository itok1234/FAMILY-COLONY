# FAMILY COLONY — Wallet, Coins & Gifts Backend Contract

Status: implementation contract only. No wallet, payment provider, database migration, or Edge Function is deployed by this document.

## Non-negotiable authority
- The server/database is the only authority for balances, item ownership, gift delivery, and transaction status.
- A client may request an operation but must never submit an authoritative balance or directly edit wallet rows.
- Never use ENet peer IDs, display names, or client profile fields as proof of account identity. The future Android-to-Godot bridge must pass a verified Supabase session.
- Keep RC Top Up and RC Reward as separate ledgers/balances. Do not silently merge or convert them.
- Do not expose cash-out or redemption until legal, payment, reserve, fraud, and operational requirements are separately approved.

## Required request shape
A gift request should contain:
- `recipient_member_id`
- `gift_item_id` OR a coin amount (exactly one gift mode per request)
- `client_request_id` (random UUID generated once and reused for retries)
- optional short note, subject to length and moderation rules

The authenticated sender ID must be derived from the verified session, never trusted from request JSON.

## Atomic server transaction
1. Verify session, account status, sender permissions, recipient eligibility, and block/privacy rules.
2. Validate gift catalog entry, availability, quantity, and current server-side price.
3. For coin gifts, lock/check the correct spendable balance and ensure sufficient funds.
4. Insert one transaction keyed by a unique idempotency constraint on sender + client_request_id.
5. Debit sender and credit recipient (or transfer item ownership) in the same database transaction.
6. Record immutable sender, recipient, item/coin type, amount, status, and server timestamp.
7. Return the existing transaction result for duplicate retries; never debit twice.
8. Notify clients only after commit.

## Minimum data model
- Wallet balances separated by currency type.
- Immutable wallet ledger with signed amount, currency, actor, related member, reason, transaction ID, and timestamp.
- Gift catalog with server-owned price, active flag, and item metadata.
- Member inventory with ownership and quantity.
- Gift transfer record with sender, recipient, item/amount, status, and idempotency key.
- Audit trail for administrative adjustments and reversals.

## Required safeguards
- Database constraints and row-level security; privileged mutations only through trusted server functions.
- Rate limits, replay protection, duplicate-request idempotency, and fraud monitoring.
- Explicit confirmation in UI before sending; display recipient and exact cost.
- A failed operation must leave both balances and inventory unchanged.
- Refund/reversal is a compensating ledger transaction, not destructive editing of history.
- Log denied and suspicious operations without exposing private financial data.

## Acceptance tests before enabling
- Concurrent sends cannot overspend the same balance.
- Replayed request IDs do not duplicate a debit or gift.
- Invalid recipient, blocked recipient, inactive item, insufficient balance, and revoked session all fail without partial writes.
- Successful transfer updates both sides and immutable history exactly once.
- Client tampering with price, sender ID, balance, or role has no effect.
- Separate RC Top Up and RC Reward balances cannot be interchanged.

## Current boundary
The Godot project currently has no wallet UI, inventory persistence, gift delivery, payment integration, or trusted Supabase session bridge. Do not represent any of these features as available until backend implementation and acceptance tests pass.
