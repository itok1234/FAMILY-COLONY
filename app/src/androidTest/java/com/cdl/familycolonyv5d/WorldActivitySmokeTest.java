package com.cdl.familycolonyv5d;

import android.content.Intent;
import android.app.Instrumentation;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertFalse;

/** Starts the non-exported Godot activity from inside the application process. */
@RunWith(AndroidJUnit4.class)
public final class WorldActivitySmokeTest {
    @Test
    public void embeddedGodotWorldStarts() throws Exception {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        Intent intent = new Intent(instrumentation.getTargetContext(), WorldActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        WorldActivity activity = (WorldActivity) instrumentation.startActivitySync(intent);
        assertNotNull("WorldActivity must be created by the application itself", activity);

        Thread.sleep(20000);
        assertFalse("WorldActivity must remain alive after Godot initialization", activity.isFinishing());
        instrumentation.runOnMainSync(activity::finish);
    }
}
