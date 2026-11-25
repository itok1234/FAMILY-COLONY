# FAMILY COLONY — LOCKED VISUAL / GRAPHICS SPECIFICATION
Status: LOCKED TARGET / acceptance criteria, not proof of implemented visuals.
Reference: User-provided 3D reference image in project conversation. Before visual QA, retrieve/use that reference image as comparison; do not substitute a generic style.

## Non-negotiable
- Match the user's supplied reference image for overall composition, proportions, visual density, architectural style, materials, lighting, palette, camera perspective, avatar presentation, and UI treatment. The reference image is the acceptance baseline.
- Do not downgrade the world to cubes, primitive-only placeholder structures, mannequin/blockout avatars, flat UI masquerading as 3D, or a bare demo scene.
- The APK should present a coherent, polished, immersive 3D world with authored/imported asset-quality buildings, landscaping, street/plaza furniture, surface materials, lighting/shadows, ambient detail, and full humanoid avatars with animation.
- All screens must share the locked art direction: sign-in, registration (only for unregistered applicants), home hub, 3D world, rooms, avatar/profile, minigames, and Developer Center.
- Existing approved members must enter the member login flow, never be forced into registration. Applicants/unknown users may access a separate registration/application path.
- After successful member login, show the home hub first; 3D exploration is an accessible feature from the hub, not an automatic post-login world teleport.
- Android portrait and landscape must be checked, touch controls positioned and legible, interface overlays safe from camera/controls, performance and thermal constraints respected.

## Visual acceptance checklist (must be evidenced before APK is called final)
1. Compare actual Android screenshot(s) against the supplied reference; record differences and resolve them.
2. Lobby composition, building scale, material quality, lighting, foliage, paths, and furniture are no longer blockout assets.
3. Avatar model is full, coherent humanoid, correctly proportioned, animated, visually integrated; no mannequin fallback.
4. Camera, controls, UI and typography are clear and usable on target Android devices in portrait and landscape.
5. Hub, world transition, room interactions, chat, profile/avatar, and Developer Center are tested; no dead controls or placeholder destinations presented as completed.
6. Android release build, installation and startup tested; capture screenshots/video of key journeys and document remaining limitations.
7. If any checklist item is not met, label build as prototype/preview and do not represent it as production-complete.

## Release gate
Do not ask the user to install/upload a build as a final 3D release until the visual acceptance evidence and Android runtime QA are complete. This specification locks expectations; it does not itself implement assets or establish that QA has passed.
