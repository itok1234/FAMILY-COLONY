# FAMILY COLONY — Visual Target Integration (Reference Image)

## Acceptance target
The uploaded concept is the visual/feature target, not an APK screenshot. The 3D Android application should approach this integrated composition:

- Welcome/login entry: branded exterior, Login Member, Guest Mode only if guest policy/backend supports it. Registration is a separate route; never place a registration form on the existing-member login screen.
- Main hub lobby: a landscaped plaza, prominent central landmark/fountain, surrounding buildings, clear navigation and member activity.
- Avatar 3D: preview with outfit/appearance selection and persistence; male/female avatars are examples, not fixed identities.
- Community room: furnished lounge, room discovery, active social/chat controls, presence where server-backed.
- World/exploration: third-person outdoor environment, destinations/shops/arena only when implemented; mobile navigation controls and minimap as functional features.
- Persistent menu/access: Social Community, Mini Games & Events, Build Your Dream Home, Make New Friends, and more; all must link to real features or be clearly marked unavailable.
- Developer menu: protected and server-authorized; not shown as member-accessible admin features.

## Login flow constraints
1. Existing approved member opens app and sees username/password login only.
2. Authentication/permissions are server validated.
3. Successful member login enters the 3D hub, not free-roaming world automatically.
4. The World/exploration station starts exploration on explicit selection.
5. New-member application is a separate page/route and is not shown in the login panel.
6. Guest access, if enabled, must be time-limited/permission-limited and server verified.

## Current repository status
- The current Godot world controller instantiates the native 3D hub after server session verification and explicitly disables player movement until selecting World.
- Existing hub script builds procedural geometry and feature kiosk panels.
- The current web login asset had the new-member registration panel removed from the member login panel in commit 75296ff.
- The uploaded reference image is not an actual screenshot or proof of completed features.
- A visual parity release cannot be claimed until real assets, complete interactions and device screenshots/QA confirm them.

## Visual parity release gate
- [ ] 3D exterior/lobby plaza resembles reference in layout, lighting, landscaping, materials and scale.
- [ ] Central landmark and surrounding architecture are finished (not placeholder primitives).
- [ ] Avatars are recognizable, proportionate, animated and customizable.
- [ ] Lounge room has finished furnishing, lighting and responsive interaction.
- [ ] Outdoor world has distinct destinations and functional controls.
- [ ] Login and post-login flow validated on Android.
- [ ] Login member screen does not expose application form.
- [ ] Menu items all have working destinations or honest status labels.
- [ ] Developer controls inaccessible to regular members.
- [ ] Visual QA screenshots from actual Android build and performance check completed.
