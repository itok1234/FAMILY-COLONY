import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
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

  const authorization = req.headers.get("Authorization") || "";
  const bearer = authorization.match(/^Bearer\s+(.+)$/i)?.[1]?.trim() || "";
  if (!bearer) return json({ error: "authentication_required" }, 401);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
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

  const requestedWorld = String(body.world_id || "colony-main").trim();
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(requestedWorld)) {
    return json({ error: "invalid_world_id" }, 400);
  }

  const heartbeatCutoff = new Date(Date.now() - 90_000).toISOString();
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

  return json({
    ok: true,
    access: "member_session",
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
      role: member.role,
    },
    // The game client presents its existing Supabase access token to the
    // authoritative game server, which must validate it with Supabase Auth.
    credential: "supabase_access_token",
  });
});
