package com.cdl.familycolonyv5d;

import android.os.Bundle;
import java.lang.ref.WeakReference;

import org.godotengine.godot.Godot;
import org.godotengine.godot.GodotActivity;
import org.godotengine.godot.plugin.GodotPlugin;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Set;

/** Hosts the embedded FAMILY COLONY 3D world inside the existing Android application. */
public final class WorldActivity extends GodotActivity {
    public static final String EXTRA_ACCESS_TOKEN =
            "com.cdl.familycolonyv5d.extra.WORLD_ACCESS_TOKEN";
    public static final String EXTRA_API_KEY =
            "com.cdl.familycolonyv5d.extra.WORLD_API_KEY";

    private String pendingAccessToken = "";
    private String pendingApiKey = "";
    private FamilyColonyGodotPlugin activePlugin;
    private static volatile WeakReference<FamilyColonyGodotPlugin> activeBridge = new WeakReference<>(null);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Read the short-lived token before GodotActivity initializes its GodotFragment.
        String suppliedToken = getIntent() == null
                ? ""
                : getIntent().getStringExtra(EXTRA_ACCESS_TOKEN);
        String suppliedApiKey = getIntent() == null
                ? ""
                : getIntent().getStringExtra(EXTRA_API_KEY);
        pendingAccessToken = suppliedToken == null ? "" : suppliedToken.trim();
        pendingApiKey = suppliedApiKey == null ? "" : suppliedApiKey.trim();

        super.onCreate(savedInstanceState);

        // Do not leave the bearer token in the Activity's launch Intent.
        if (getIntent() != null) {
            getIntent().removeExtra(EXTRA_ACCESS_TOKEN);
            getIntent().removeExtra(EXTRA_API_KEY);
        }
    }

    @Override
    public Set<GodotPlugin> getHostPlugins(Godot godot) {
        if (pendingAccessToken.isEmpty() || pendingApiKey.isEmpty()) {
            return Collections.emptySet();
        }

        activePlugin = new FamilyColonyGodotPlugin(godot, this, pendingAccessToken, pendingApiKey);
        activeBridge = new WeakReference<>(activePlugin);
        pendingAccessToken = "";
        pendingApiKey = "";
        return Collections.singleton(activePlugin);
    }

    public static void deliverSessionCredentials(String accessToken, String apiKey) {
        FamilyColonyGodotPlugin bridge = activeBridge == null ? null : activeBridge.get();
        if (bridge != null) {
            bridge.onSessionCredentialsRefreshed(accessToken, apiKey);
        }
    }

    public static void deliverSessionRefreshFailure(boolean invalidated) {
        FamilyColonyGodotPlugin bridge = activeBridge == null ? null : activeBridge.get();
        if (bridge != null) {
            bridge.onSessionRefreshFailed(invalidated);
        }
    }

    @Override
    protected void onDestroy() {
        if (activeBridge != null && activeBridge.get() == activePlugin) {
            activeBridge = new WeakReference<>(null);
        }
        super.onDestroy();
    }

    @Override
    public List<String> getCommandLine() {
        List<String> commandLine = new ArrayList<>(super.getCommandLine());
        commandLine.add("--main-pack");
        commandLine.add("res://godot_world.zip");
        return commandLine;
    }
}
