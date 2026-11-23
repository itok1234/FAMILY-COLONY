export type WorldPermissionSnapshot = {
  can_enter_world: true;
  world_role: "member";
  can_manage_members: boolean;
  can_manage_staff: boolean;
  can_access_developer_center: boolean;
};

const ALLOWED_WORLD_ROLES = new Set([
  "kepsuk",
  "deputi",
  "admin",
  "member",
  "developer",
]);

export function normalizeWorldRole(role: unknown): string {
  return String(role ?? "").trim().toLowerCase();
}

export function isActiveWorldMemberStatus(status: unknown): boolean {
  const normalized = String(status ?? "").trim().toLowerCase();
  return normalized === "aktif" || normalized === "active";
}

export function buildWorldPermissions(
  role: unknown,
): WorldPermissionSnapshot | null {
  const normalizedRole = normalizeWorldRole(role);
  if (!ALLOWED_WORLD_ROLES.has(normalizedRole)) {
    return null;
  }

  return {
    can_enter_world: true,
    // Developer plays as an ordinary member. Developer Center is separate.
    world_role: "member",
    can_manage_members: ["kepsuk", "deputi", "admin"].includes(normalizedRole),
    can_manage_staff: normalizedRole === "kepsuk",
    can_access_developer_center: normalizedRole === "developer",
  };
}
