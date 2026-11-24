import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info, x-fc-game-server-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Pragma": "no-cache",
    },
  });

const encoder = new TextEncoder();

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, "0")).join("");
}

function makeTicket(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return Array.from(bytes, byte => byte.toString(16).padStart(2, "0")).join("");
}

function isActive(status: unknown): boolean {
  return ["aktif", "active"].includes(String(status ?? "").trim().toLowerCase());
}

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") || "{}";
let secretKeys: Record<string, string> = {};
try { secretKeys = JSON.parse(secretKeysRaw); } catch { secretKeys = {}; }
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || secretKeys.default || "";

Deno.serve(async req => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!supabaseUrl || !serviceKey) return json({ error: "service_unavailable" }, 503);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    const parsed = await req.json();
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return json({ error: "invalid_request" }, 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const action = String(body.action || "");

  if (action === "request_ticket") {
    const authorization = req.headers.get("Authorization") || "";
    const bearer = authorization.match(/^Bearer\\s+(.+)$/i)?.[1]?.trim() || "";
    if (!bearer) return json({ error: "authentication_required" }, 401);

    const { data: authData, error: authError } = await admin.auth.getUser(bearer);
    if (authError || !authData.user) return json({ error: "invalid_or_expired_session" }, 401);

    const { data: member, error: memberError } = await admin
      .from("fc_members")
      .select("member_id,name,username,role,status,auth_user_id")
      .eq("auth_user_id", authData.user.id)
      .maybeSingle();
    if (memberError) return json({ error: "member_lookup_failed" }, 503);
    if (!member || member.auth_user_id !== authData.user.id) {
      return json({ error: "member_identity_not_linked" }, 403);
    }
    if (!isActive(member.status)) return json({ error: "member_account_inactive" }, 403);

    const requestedWorld = String(body.world_id || "colony-main").trim();
    if (!/^[a-zA-Z0-9_-]{1,64}$/.test(requestedWorld)) {
      return json({ error: "invalid_world_id" }, 400);
    }

    const now = new Date();
    const heartbeatCutoff = new Date(now.getTime() - 90_000).toISOString();
    const { data: servers, error: serverError } = await admin
      .from("fc_world_servers")
      .select("server_id,world_id,region,endpoint,current_players,max_players,heartbeat_at")
      .eq("status", "ready")
      .eq("world_id", requestedWorld)
      .gt("heartbeat_at", heartbeatCutoff)
      .order("current_players", { ascending: true })
      .limit(20);
    if (serverError) return json({ error: "world_registry_unavailable" }, 503);

    const server = (servers || []).find(item =>
      Number(item.current_players) < Number(item.max_players)
    );
    if (!server) return json({ error: "world_server_unavailable" }, 503);

    const rawTicket = makeTicket();
    const expiresAt = new Date(now.getTime() + 60_000).toISOString();
    const { error: ticketError } = await admin.from("fc_world_join_tickets").insert({
      ticket_hash: await sha256(rawTicket),
      member_id: member.member_id,
      server_id: server.server_id,
      world_id: server.world_id,
      expires_at: expiresAt,
    });
    if (ticketError) return json({ error: "ticket_issue_failed" }, 503);

    return json({
      ok: true,
      ticket: rawTicket,
      expires_in: 60,
      server: {
        server_id: server.server_id,
        world_id: server.world_id,
        region: server.region,
        endpoint: server.endpoint,
      },
      member: {
        member_id: member.member_id,
        name: member.name,
        username: member.username,
      },
    });
  }

  if (action === "redeem_ticket") {
    const configuredSecret = Deno.env.get("FC_GAME_SERVER_SECRET") || "";
    const suppliedSecret = req.headers.get("x-fc-game-server-secret") || "";
    if (configuredSecret.length < 32 || suppliedSecret.length < 32 ||
        suppliedSecret !== configuredSecret) {
      return json({ error: "game_server_authentication_failed" }, 401);
    }

    const rawTicket = String(body.ticket || "").trim().toLowerCase();
    const serverId = String(body.server_id || "").trim();
    if (!/^[a-f0-9]{64}$/.test(rawTicket) ||
        !/^[0-9a-f-]{36}$/i.test(serverId)) {
      return json({ error: "invalid_ticket_input" }, 400);
    }

    const now = new Date().toISOString();
    const { data: consumed, error: consumeError } = await admin
      .from("fc_world_join_tickets")
      .update({ consumed_at: now })
      .eq("ticket_hash", await sha256(rawTicket))
      .eq("server_id", serverId)
      .is("consumed_at", null)
      .gt("expires_at", now)
      .select("member_id,world_id,server_id")
      .maybeSingle();

    if (consumeError) return json({ error: "ticket_redemption_unavailable" }, 503);
    if (!consumed) return json({ error: "ticket_invalid_expired_or_used" }, 401);

    const { data: member, error: memberError } = await admin
      .from("fc_members")
      .select("member_id,name,username,role,status")
      .eq("member_id", consumed.member_id)
      .maybeSingle();
    if (memberError) return json({ error: "member_lookup_failed" }, 503);
    if (!member || !isActive(member.status)) return json({ error: "member_no_longer_active" }, 403);

    return json({
      ok: true,
      member,
      world_id: consumed.world_id,
      server_id: consumed.server_id,
    });
  }

  return json({ error: "unknown_action" }, 400);
});
