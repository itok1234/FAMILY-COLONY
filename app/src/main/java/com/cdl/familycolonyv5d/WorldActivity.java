package com.cdl.familycolonyv5d;

import android.os.Bundle;

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

        FamilyColonyGodotPlugin bridge =
                new FamilyColonyGodotPlugin(godot, this, pendingAccessToken, pendingApiKey);
        pendingAccessToken = "";
        pendingApiKey = "";
        return Collections.singleton(bridge);
    }

    @Override
    public List<String> getCommandLine() {
        return new ArrayList<>(Arrays.asList("--main-pack", "godot_world.zip"));
    }
}
