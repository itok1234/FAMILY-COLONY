package com.cdl.familycolonyv5d;

import android.app.Activity;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/** Narrow in-process bridge between the existing app session and the embedded Godot world. */
public final class FamilyColonyGodotPlugin extends GodotPlugin {
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
