package com.cdl.familycolonyv5d;

import android.content.Intent;
import android.test.InstrumentationTestCase;

/** Starts the non-exported Godot activity from inside the app process. */
public final class WorldActivitySmokeTest extends InstrumentationTestCase {
    public void testEmbeddedGodotWorldStarts() throws Exception {
        Intent intent = new Intent(getInstrumentation().getTargetContext(), WorldActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        WorldActivity activity = (WorldActivity) getInstrumentation().startActivitySync(intent);
        assertNotNull("WorldActivity must be created by the application itself", activity);
        Thread.sleep(20000);
        assertTrue("WorldActivity must remain alive after Godot initialization", !activity.isFinishing());
        activity.finish();
    }
}
