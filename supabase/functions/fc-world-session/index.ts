import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildWorldPermissions,
  isActiveWorldMemberStatus,
} from "../_shared/world-session-policy.ts";

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authorization = req.headers.get("Authorization") || "";
  const bearerMatch = authorization.match(/^Bearer\s+(.+)$/i);
  const accessToken = bearerMatch?.[1]?.trim() || "";
  if (!accessToken) {
    return json({ error: "authentication_required" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
  const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") || "{}";
  let secretKeys: Record<string, string> = {};
  try {
    secretKeys = JSON.parse(secretKeysRaw);
  } catch {
    secretKeys = {};
  }
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || secretKeys.default || "";

  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "world_session_service_unavailable" }, 503);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    // Verify the access token with Supabase Auth. Never trust member IDs,
    // usernames, or roles supplied by the Android/Godot client.
    const { data: authData, error: authError } = await admin.auth.getUser(accessToken);
    if (authError || !authData.user) {
      return json({ error: "invalid_or_expired_session" }, 401);
    }

    const { data: member, error: memberError } = await admin
      .from("fc_members")
      .select("member_id,name,username,role,status,auth_user_id")
      .eq("auth_user_id", authData.user.id)
      .maybeSingle();

    if (memberError) {
      // Do not leak database details or return a partial identity.
      return json({ error: "member_identity_lookup_failed" }, 503);
    }
    if (!member || member.auth_user_id !== authData.user.id) {
      return json({ error: "member_identity_not_linked" }, 403);
    }

    if (!isActiveWorldMemberStatus(member.status)) {
      return json({ error: "member_account_inactive" }, 403);
    }

    // Developer may enter the world as an ordinary player. The separate
    // Developer Center flag is only a UI hint; every privileged action must
    // still be checked by its own trusted backend endpoint.
    const permissions = buildWorldPermissions(member.role);
    if (!permissions) {
      return json({ error: "member_role_invalid" }, 403);
    }

    return json({
      ok: true,
      member: {
        member_id: member.member_id,
        name: member.name,
        username: member.username,
        role: member.role,
        status: member.status,
      },
      permissions,
      verified_at: new Date().toISOString(),
    });
  } catch {
    return json({ error: "world_session_verification_failed" }, 500);
  }
});
