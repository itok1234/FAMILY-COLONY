# FAMILY COLONY — Post-login navigation and feature hub revision

## Approved navigation
After member login and server session verification, the first screen MUST be the central 3D hub (not the explorable outdoor world itself). The hub is a menu-world where the member can choose feature stations. Selecting the WORLD station enters the outdoor 3D gameplay area. The current Godot session flow already instantiates MainHub3D on successful verification; the hub's WORLD station is the explicit transition into the player-controlled outdoor scene.

## Hub menu stations
The main hub should present these accessible spatial stations:
- Member profile / avatar / collection
- Community chat and room listing
- Royal Game Center (currently supported mini-game IDs)
- Settings (audio, graphics quality and controls)
- World / outdoor exploration
- Developer Center access point (privileged and server verified)

## Developer menu security and presentation
- Keep developer access available from the hub, separate from regular feature kiosks.
- Entry requires the existing developer PIN flow followed by server authentication; visual hiding or the PIN panel alone is not authorization.
- Privileged dashboard visibility is allowed only for server-verified role developer and username edrick, enforced both by the world controller and MainHub3D.
- Developer dashboard modules include member management, world settings, mini-game management, server monitoring, reports/activity, and app configuration.
- Dashboard actions remain placeholders/requests until their backend operations are implemented and server authorization exists. Do not present these as live management features.
- Never embed privileged service credentials in the APK.

## Guest mode
Guest mode is NOT assumed to be enabled by this revision. If later added, it must be a separate limited-access session with no member identity, private chat, developer actions, inventory or privileged operations. A guest world may be entered only through a deliberate guest-entry choice on a welcome/login screen.

## Release/QA acceptance
1. Login success -> central 3D hub.
2. Each feature kiosk opens its corresponding feature/panel and can return to hub.
3. WORLD kiosk explicitly enters outdoor gameplay; leaving gameplay returns to hub.
4. Developer access is rejected for regular accounts and accepted only after server verification of developer identity/role.
5. Developer dashboard action buttons are labeled as awaiting backend integration when not live.
6. On Android verify touch targets, camera framing, screen scaling and back navigation.

## Status
This document records the requested navigation design and existing code paths. It does not claim that every kiosk or developer operation has been fully runtime-verified or backend implemented.
