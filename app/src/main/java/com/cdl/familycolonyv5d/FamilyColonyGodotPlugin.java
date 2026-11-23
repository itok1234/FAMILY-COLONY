package com.cdl.familycolonyv5d;

import android.app.Activity;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

/** Narrow in-process bridge between the existing app session and the embedded Godot world. */
public final class FamilyColonyGodotPlugin extends GodotPlugin {
    private static final SignalInfo SESSION_CREDENTIALS_REFRESHED =
            new SignalInfo("session_credentials_refreshed", String.class, String.class);
    private static final SignalInfo SESSION_REFRESH_FAILED =
            new SignalInfo("session_refresh_failed", Boolean.class);
    private final Activity hostActivity;
    private String pendingAccessToken;
    private String pendingApiKey;

    public FamilyColonyGodotPlugin(
            Godot godot,
            Activity hostActivity,
            String accessToken,
            String apiKey
    ) {
        super(godot);
        this.hostActivity = hostActivity;
        this.pendingAccessToken = accessToken == null ? "" : accessToken;
        this.pendingApiKey = apiKey == null ? "" : apiKey;
    }

    @Override
    public String getPluginName() {
        return "FamilyColonyBridge";
    }

    /** GDScript consumes the one-time token after the engine has registered this plugin. */
    @UsedByGodot
    public String consumeInitialAccessToken() {
        String token = pendingAccessToken;
        pendingAccessToken = "";
        return token;
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
                SESSION_CREDENTIALS_REFRESHED,
                SESSION_REFRESH_FAILED
        ));
    }

    @UsedByGodot
    public void requestSessionRefresh() {
        MainActivity.requestWorldSessionRefresh();
    }

    public void onSessionCredentialsRefreshed(String accessToken, String apiKey) {
        if (accessToken == null || accessToken.isEmpty() || apiKey == null || apiKey.isEmpty()) {
            onSessionRefreshFailed(true);
            return;
        }
        emitSignal(SESSION_CREDENTIALS_REFRESHED.getName(), accessToken, apiKey);
    }

    public void onSessionRefreshFailed(boolean invalidated) {
        emitSignal(SESSION_REFRESH_FAILED.getName(), invalidated);
    }

    /** The project publishable key is not a secret; it is sent only in the HTTP apikey header. */
    @UsedByGodot
    public String consumeInitialPublishableKey() {
        String key = pendingApiKey;
        pendingApiKey = "";
        return key;
    }

    /** Called by GDScript after logout, rejected session, or the member choosing Exit. */
    @UsedByGodot
    public void requestExitToApp() {
        runOnUiThread(() -> hostActivity.finish());
    }
}
