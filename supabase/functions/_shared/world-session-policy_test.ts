import {
  buildWorldPermissions,
  isActiveWorldMemberStatus,
  normalizeWorldRole,
} from "./world-session-policy.ts";

Deno.test("active member statuses are accepted case-insensitively", () => {
  if (!isActiveWorldMemberStatus("Aktif")) throw new Error("Aktif should be accepted");
  if (!isActiveWorldMemberStatus("ACTIVE")) throw new Error("ACTIVE should be accepted");
});

Deno.test("inactive and missing statuses are rejected", () => {
  if (isActiveWorldMemberStatus("Nonaktif")) throw new Error("Nonaktif must be rejected");
  if (isActiveWorldMemberStatus("suspended")) throw new Error("suspended must be rejected");
  if (isActiveWorldMemberStatus(null)) throw new Error("missing status must be rejected");
});

Deno.test("Developer enters as a normal member with separate Developer Center access", () => {
  const permissions = buildWorldPermissions("Developer");
  if (!permissions) throw new Error("Developer role should be allowed");
  if (permissions.world_role !== "member") throw new Error("Developer must play as a member");
  if (!permissions.can_access_developer_center) throw new Error("Developer Center should remain Developer-only");
  if (permissions.can_manage_members || permissions.can_manage_staff) {
    throw new Error("Developer must not inherit member/staff management permissions");
  }
});

Deno.test("only Kepsuk can manage staff appointments", () => {
  const kepsuk = buildWorldPermissions("Kepsuk");
  const deputi = buildWorldPermissions("Deputi");
  const admin = buildWorldPermissions("Admin");
  if (!kepsuk?.can_manage_staff) throw new Error("Kepsuk must manage staff");
  if (deputi?.can_manage_staff || admin?.can_manage_staff) {
    throw new Error("Deputi and Admin must not manage staff appointments");
  }
  if (!deputi?.can_manage_members || !admin?.can_manage_members) {
    throw new Error("Deputi and Admin may manage members");
  }
});

Deno.test("unknown roles are rejected", () => {
  if (buildWorldPermissions("SuperAdmin") !== null) {
    throw new Error("Unknown role must not receive world permissions");
  }
  if (normalizeWorldRole(" Member ") !== "member") {
    throw new Error("Role normalization failed");
  }
});
