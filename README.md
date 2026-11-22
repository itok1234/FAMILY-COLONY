# FAMILY COLONY V5D — Android Project V4

Android Studio wrapper project for the existing FAMILY COLONY V5D HTML application.
This is a new wrapper project prepared from the available HTML source; it is **not** a recovered or modified copy of the missing V3 Android ZIP.

## Included
- Existing V5D HTML source copied unchanged to `app/src/main/assets/index.html`.
- Android WebView launcher (Java).
- JavaScript and DOM Storage enabled for the current local/demo implementation.
- Runtime microphone permission bridge for the HTML voice-message recorder; only audio capture is allowed by the WebView permission handler.
- File chooser bridge for HTML file inputs.
- External HTTP/HTTPS navigation opens in the device browser.
- No forced global landscape orientation; activity orientation is `unspecified` so the existing responsive HTML can control its own layout.
- GitHub Actions workflow to build a debug APK using JDK 17, the runner's preinstalled Android SDK 35, AGP 8.7.3 and Gradle 8.9. SDK licenses are accepted non-interactively to avoid waiting at an `Accept? (y/N)` prompt.

## Build with GitHub Actions
1. Create or open a GitHub repository and upload the contents of this project.
2. Push to `main`/`master`, or open **Actions** and run **Build FAMILY COLONY V5D Android Debug APK** manually.
3. When the workflow succeeds, download the `family-colony-v5d-debug-apk` artifact.

## Build locally with Android Studio
Requirements: Android Studio, JDK 17, Android SDK Platform 35, Build Tools 35.0.0, Gradle 8.9.
Open this folder as a Gradle project. If Android Studio asks for a Gradle distribution, select Gradle 8.9. This package intentionally does not include a Gradle wrapper JAR; the GitHub Actions workflow provisions Gradle directly.

## Current limitations — read before production
- This is a **debug/demo wrapper**, not a production-secure application.
- The HTML app still uses localStorage and includes demo/development logic. Authentication, roles, wallet balances, transactions and game rewards are not server-authoritative.
- No Supabase backend has been configured or connected.
- Firebase strings/code in the HTML are not proof of an active backend connection.
- Microphone permission is now declared and requested at runtime for voice messages; real-device recording still needs testing. Camera capture is not enabled because the current HTML source does not request camera access.
- Orientation transitions for individual games need real-device testing.
- No APK has been built or installed on a device in this environment. Android SDK/Gradle compilation and device QA remain unverified. Do not treat the project as release-ready until CI build and device QA pass.

## Security notes
- No service-role key, API secret, signing key or private credential is included.
- `allowUniversalAccessFromFileURLs` and `allowFileAccessFromFileURLs` are disabled.
- Mixed content is blocked.
- Only HTTP/HTTPS links are handed to external browser apps.
- WebView JavaScript is enabled because the existing HTML application requires it; this increases the importance of keeping remote content and file access constrained.
- Backend enforcement, Supabase RLS, server-side validation, wallet ledger/idempotency, role separation and audit logs remain future requirements before production.
