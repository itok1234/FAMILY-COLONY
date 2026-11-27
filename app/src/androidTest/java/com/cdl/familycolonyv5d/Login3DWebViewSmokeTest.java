package com.cdl.familycolonyv5d;

import android.app.Activity;
import android.webkit.WebView;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

/** Runtime smoke checks for the actual landing/login WebView and its WebGL canvas. */
@RunWith(AndroidJUnit4.class)
public final class Login3DWebViewSmokeTest {
    @Test
    public void loginCanvasAndWebglContextAreAvailable() throws Exception {
        Activity activity = InstrumentationRegistry.getInstrumentation()
                .startActivitySync(new android.content.Intent(
                        InstrumentationRegistry.getInstrumentation().getTargetContext(),
                        MainActivity.class).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK));
        assertNotNull(activity);
        WebView webView = activity.findViewById(android.R.id.content) instanceof WebView
                ? (WebView) activity.findViewById(android.R.id.content) : null;
        // MainActivity installs the WebView as the activity content directly.
        if (webView == null) {
            android.view.View root = activity.findViewById(android.R.id.content);
            if (root instanceof android.view.ViewGroup && ((android.view.ViewGroup) root).getChildCount() > 0) {
                android.view.View child = ((android.view.ViewGroup) root).getChildAt(0);
                if (child instanceof WebView) webView = (WebView) child;
            }
        }
        assertNotNull("MainActivity must contain its WebView", webView);
        final WebView target = webView;

        String probe = "(function(){var c=document.getElementById('fcLogin3D');"
                + "if(!c)return 'CANVAS_MISSING';"
                + "var g=c.getContext('webgl');if(!g)return 'WEBGL_CONTEXT_MISSING';"
                + "if(c.dataset.status==='shader-error')return 'SHADER_ERROR';"
                + "if(c.dataset.status==='webgl-unavailable')return 'WEBGL_UNAVAILABLE';"
                + "return 'CANVAS_WEBGL_OK';})()";
        String result = "";
        for (int i = 0; i < 30; i++) {
            CountDownLatch latch = new CountDownLatch(1);
            AtomicReference<String> value = new AtomicReference<>();
            InstrumentationRegistry.getInstrumentation().runOnMainSync(() ->
                    target.evaluateJavascript(probe, v -> { value.set(v); latch.countDown(); }));
            if (!latch.await(2, TimeUnit.SECONDS)) throw new AssertionError("WebView probe timed out");
            result = value.get();
            if ("\\"CANVAS_WEBGL_OK\\"".equals(result)) break;
            Thread.sleep(1000);
        }
        assertEquals("Login WebGL canvas runtime probe", "\\"CANVAS_WEBGL_OK\\"", result);
        InstrumentationRegistry.getInstrumentation().runOnMainSync(activity::finish);
    }
}
