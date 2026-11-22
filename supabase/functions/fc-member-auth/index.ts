import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-fc-bootstrap-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const encoder = new TextEncoder();
async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return Array.from(new Uint8Array(digest), b => b.toString(16).padStart(2, "0")).join("");
}
function makeCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  return Array.from(bytes, b => b.toString(16).padStart(2, "0")).join("").toUpperCase();
}
function authEmail(username: string): string {
  const hex = Array.from(encoder.encode(username.trim().toLowerCase()))
    .map(b => b.toString(16).padStart(2, "0")).join("");
  return `fc_${hex}@members.familycolony.invalid`;
}

Deno.serve(async req => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") || "{}";
  let secretKeys: Record<string, string> = {};
  try { secretKeys = JSON.parse(secretKeysRaw); } catch { secretKeys = {}; }
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || secretKeys.default;
  if (!url || !serviceKey) return json({ error: "server_not_configured" }, 500);

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const body = await req.json();
    const action = String(body.action || "");

    if (action === "developer_password_setup") {
      const expected = (Deno.env.get("FC_BOOTSTRAP_SECRET") || "").trim();
      const supplied = (req.headers.get("x-fc-bootstrap-secret") || "").trim();
      const initialPassword = String(body.initial_password || "");
      if (!expected) return json({ error: "bootstrap_secret_not_configured" }, 503);
      if (supplied.length < 32 || supplied !== expected) return json({ error: "bootstrap_secret_mismatch" }, 403);
      if (initialPassword.length < 12) return json({ error: "initial_password_min_12" }, 400);
      const { data: member, error: memberError } = await admin.from("fc_members")
        .select("member_id,username,name,role,status,auth_user_id").eq("username", "edrick").maybeSingle();
      if (memberError || !member || member.status !== "Aktif" || member.role !== "Developer" || member.auth_user_id) {
        return json({ error: "developer_member_not_eligible" }, 409);
      }
      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email: authEmail("edrick"), password: initialPassword, email_confirm: true,
        user_metadata: { family_colony_username: "edrick", fc_must_change_password: true },
      });
      if (createError || !created.user) return json({ error: "developer_account_setup_failed" }, 409);
      const { error: linkError } = await admin.from("fc_members").update({ auth_user_id: created.user.id })
        .eq("member_id", member.member_id).is("auth_user_id", null);
      if (linkError) {
        await admin.auth.admin.deleteUser(created.user.id);
        return json({ error: "developer_account_link_failed" }, 500);
      }
      return json({ ok: true, username: "edrick", must_change_password: true });
    }

    if (action === "developer_change_password") {
      const bearer = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
      const newPassword = String(body.new_password || "");
      if (!bearer) return json({ error: "authentication_required" }, 401);
      if (newPassword.length < 12) return json({ error: "password_min_12" }, 400);
      const { data: authData, error: authError } = await admin.auth.getUser(bearer);
      if (authError || !authData.user) return json({ error: "invalid_session" }, 401);
      const { data: member } = await admin.from("fc_members").select("username,role,status,auth_user_id")
        .eq("auth_user_id", authData.user.id).maybeSingle();
      if (!member || member.username !== "edrick" || member.role !== "Developer" || member.status !== "Aktif" || member.auth_user_id !== authData.user.id) {
        return json({ error: "not_authorized" }, 403);
      }
      const { error: updateError } = await admin.auth.admin.updateUserById(authData.user.id, {
        password: newPassword,
        user_metadata: { ...authData.user.user_metadata, fc_must_change_password: false },
      });
      if (updateError) return json({ error: "password_update_failed" }, 500);
      return json({ ok: true, must_change_password: false });
    }


    if (action === "bootstrap_issue") {
      const expected = Deno.env.get("FC_BOOTSTRAP_SECRET");
      const supplied = req.headers.get("x-fc-bootstrap-secret") || "";
      if (!expected || supplied.length < 20 || supplied !== expected) {
        return json({ error: "bootstrap_not_authorized" }, 403);
      }
      const { data: existing } = await admin.from("fc_members")
        .select("member_id").not("auth_user_id", "is", null).limit(1);
      if (existing && existing.length) return json({ error: "bootstrap_already_used" }, 409);

      const { data: member, error: memberError } = await admin.from("fc_members")
        .select("member_id,username,name,role,status,auth_user_id")
        .eq("username", "dhita").maybeSingle();
      if (memberError || !member || member.status !== "Aktif" || member.role !== "Kepsuk" || member.auth_user_id) {
        return json({ error: "bootstrap_member_not_eligible" }, 409);
      }
      const code = makeCode();
      const hash = await sha256(code);
      const { error } = await admin.from("fc_member_activation_codes").upsert({
        member_id: member.member_id,
        code_hash: hash,
        expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        created_by: null,
        used_at: null,
      });
      if (error) return json({ error: "bootstrap_issue_failed" }, 500);
      return json({ ok: true, username: member.username, activation_code: code, expires_in_hours: 24 });
    }

    if (action === "login") {
      const username = String(body.username || "").trim().replace(/^@/, "").toLowerCase();
      const password = String(body.password || "");
      if (!username || !password) return json({ error: "credentials_required" }, 400);
      const publishableKeysRaw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") || "{}";
      let publishableKeys: Record<string, string> = {};
      try { publishableKeys = JSON.parse(publishableKeysRaw); } catch { publishableKeys = {}; }
      const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ||
        Deno.env.get("SUPABASE_PUBLISHABLE_KEY") || publishableKeys.default;
      if (!anonKey) return json({ error: "auth_server_not_configured" }, 500);
      const publicClient = createClient(url, anonKey, {
        auth: { autoRefreshToken: false, persistSession: false },
      });
      const { data: signedIn, error: signInError } = await publicClient.auth.signInWithPassword({
        email: authEmail(username),
        password,
      });
      if (signInError || !signedIn.user || !signedIn.session) {
        return json({ error: "invalid_credentials" }, 401);
      }
      const { data: member, error: memberError } = await admin.from("fc_members")
        .select("member_id,name,username,role,status")
        .eq("auth_user_id", signedIn.user.id).maybeSingle();
      if (memberError || !member || member.status !== "Aktif") {
        await publicClient.auth.signOut();
        return json({ error: "member_not_eligible" }, 403);
      }
      return json({
        ok: true,
        member,
        access_token: signedIn.session.access_token,
        refresh_token: signedIn.session.refresh_token,
        expires_in: signedIn.session.expires_in,
        anon_key: anonKey,
        must_change_password: member.role === "Developer" && signedIn.user.user_metadata?.fc_must_change_password === true,
      });
    }

    if (action === "issue_activation") {
      const bearer = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
      if (!bearer) return json({ error: "authentication_required" }, 401);
      const { data: authData, error: authError } = await admin.auth.getUser(bearer);
      if (authError || !authData.user) return json({ error: "invalid_session" }, 401);
      const { data: staff } = await admin.from("fc_members")
        .select("member_id,role,status")
        .eq("auth_user_id", authData.user.id).maybeSingle();
      if (!staff || staff.status !== "Aktif" || !["Kepsuk", "Deputi", "Admin"].includes(staff.role)) {
        return json({ error: "not_authorized" }, 403);
      }
      const username = String(body.username || "").trim().replace(/^@/, "").toLowerCase();
      if (!username) return json({ error: "username_required" }, 400);
      const { data: member, error: memberError } = await admin.from("fc_members")
        .select("member_id,username,name,status,auth_user_id")
        .eq("username", username).maybeSingle();
      if (memberError || !member || member.status !== "Aktif" || member.auth_user_id) {
        return json({ error: "member_not_eligible" }, 409);
      }
      const code = makeCode();
      const { error } = await admin.from("fc_member_activation_codes").upsert({
        member_id: member.member_id,
        code_hash: await sha256(code),
        expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        created_by: authData.user.id,
        used_at: null,
      });
      if (error) return json({ error: "activation_issue_failed" }, 500);
      return json({ ok: true, username, name: member.name, activation_code: code, expires_in_hours: 24 });
    }

    if (action === "activate") {
      const username = String(body.username || "").trim().replace(/^@/, "").toLowerCase();
      const code = String(body.activation_code || "").trim().toUpperCase();
      const password = String(body.password || "");
      if (!username || !/^[A-F0-9]{16}$/.test(code) || password.length < 10) {
        return json({ error: "invalid_activation_input_password_min_10" }, 400);
      }
      const { data: member, error: memberError } = await admin.from("fc_members")
        .select("member_id,username,name,status,auth_user_id")
        .eq("username", username).maybeSingle();
      if (memberError || !member || member.status !== "Aktif" || member.auth_user_id) {
        return json({ error: "member_not_eligible" }, 409);
      }

      const email = authEmail(username);
      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { family_colony_username: username },
      });
      if (createError || !created.user) return json({ error: "account_creation_failed" }, 409);

      const { data: linked, error: linkError } = await admin.rpc("fc_consume_member_activation", {
        p_username: username,
        p_code_hash: await sha256(code),
        p_auth_user_id: created.user.id,
      });
      if (linkError || !linked?.length) {
        await admin.auth.admin.deleteUser(created.user.id);
        return json({ error: "activation_code_invalid_expired_or_used" }, 409);
      }
      return json({ ok: true, username, message: "account_activated" });
    }

    return json({ error: "unknown_action" }, 400);
  } catch (_error) {
    return json({ error: "invalid_request" }, 400);
  }
});
