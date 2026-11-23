package com.cdl.familycolonyv5d;

import android.app.Activity;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Collections;
import java.util.Set;

/** Narrow in-process bridge between the existing app session and the embedded Godot world. */
public final class FamilyColonyGodotPlugin extends GodotPlugin {
    private static final SignalInfo ACCESS_TOKEN_RECEIVED =
            new SignalInfo("access_token_received", String.class);

    private final Activity hostActivity;
    private String pendingAccessToken;

    public FamilyColonyGodotPlugin(
            Godot godot,
            Activity hostActivity,
            String accessToken
    ) {
        super(godot);
        this.hostActivity = hostActivity;
        this.pendingAccessToken = accessToken == null ? "" : accessToken;
    }

    @Override
    public String getPluginName() {
        return "FamilyColonyBridge";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(ACCESS_TOKEN_RECEIVED);
    }

    @Override
    public void onGodotMainLoopStarted() {
        super.onGodotMainLoopStarted();
        String token = pendingAccessToken;
        pendingAccessToken = "";
        if (!token.isEmpty()) {
            emitSignal(ACCESS_TOKEN_RECEIVED.getName(), token);
        }
    }

    /** Called by GDScript after logout, rejected session, or the member choosing Exit. */
    @UsedByGodot
    public void requestExitToApp() {
        runOnUiThread(() -> hostActivity.finish());
    }
}
