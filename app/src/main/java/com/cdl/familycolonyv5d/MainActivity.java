package com.cdl.familycolonyv5d;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.provider.Settings;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import androidx.webkit.WebViewAssetLoader;
import android.webkit.PermissionRequest;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.ConsoleMessage;
import android.webkit.WebResourceError;
import android.widget.Toast;
import android.util.Log;

public class MainActivity extends Activity {
    private WebView webView;
    private WebViewAssetLoader assetLoader;
    private ValueCallback<Uri[]> filePathCallback;
    private static final int FILE_CHOOSER_REQUEST = 4107;
    private static final int MICROPHONE_PERMISSION_REQUEST = 4108;
    private static final int UNKNOWN_APP_SOURCE_REQUEST = 4109;
    private static final int APK_INSTALL_REQUEST = 4110;
    private PermissionRequest pendingWebPermissionRequest;
    private Uri selectedApkUri;
    private static final String APP_ASSET_HOST = "appassets.androidplatform.net";
    private static final String MIC_TAG = "FAMILY_COLONY_MIC";

    private final class AndroidBridge {
        @JavascriptInterface
        public void installSelectedApk() {
            runOnUiThread(() -> installSelectedApkFromWeb());
        }

        @JavascriptInterface
        public String getMicrophonePermissionStatus() {
            return MainActivity.this.getMicrophonePermissionStatus();
        }

        @JavascriptInterface
        public String getWebViewDiagnostic() {
            String pkg = getWebViewPackageVersion();
            return "sdk=" + Build.VERSION.SDK_INT + ";webView=" + pkg
                    + ";androidPermission=" + MainActivity.this.getMicrophonePermissionStatus();
        }
    }

    private String getMicrophonePermissionStatus() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return "NOT_REQUIRED";
        return checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                ? "GRANTED" : "DENIED";
    }

    private String getWebViewPackageVersion() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "API_BELOW_26";
        try {
            android.content.pm.PackageInfo info = WebView.getCurrentWebViewPackage();
            return info == null ? "UNKNOWN" : info.packageName + "/" + info.versionName;
        } catch (RuntimeException e) {
            return "ERROR:" + e.getClass().getSimpleName();
        }
    }

    private boolean isTrustedAssetOrigin(Uri origin) {
        return origin != null && "https".equalsIgnoreCase(origin.getScheme())
                && APP_ASSET_HOST.equalsIgnoreCase(origin.getHost())
                && (origin.getPort() == -1 || origin.getPort() == 443);
    }

    private void denyPendingWebPermission(String reason) {
        PermissionRequest request = pendingWebPermissionRequest;
        pendingWebPermissionRequest = null;
        if (request != null) {
            try { request.deny(); } catch (IllegalStateException ignored) { }
        }
        Log.w(MIC_TAG, "Pending WebView request denied: " + reason);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(android.graphics.Color.rgb(7, 16, 30));
        getWindow().setNavigationBarColor(android.graphics.Color.rgb(7, 16, 30));

        assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        webView = new WebView(this);
        setContentView(webView);
        // The WebView only serves the bundled local HTML. External HTTP(S) links
        // are opened outside the WebView, keeping this narrow bridge off websites.
        webView.addJavascriptInterface(new AndroidBridge(), "FCAndroid");

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public android.webkit.WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                return assetLoader.shouldInterceptRequest(request.getUrl());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                String scheme = uri.getScheme() == null ? "" : uri.getScheme();
                if ("file".equalsIgnoreCase(scheme) || "about".equalsIgnoreCase(scheme)) {
                    return false;
                }
                if ("https".equalsIgnoreCase(scheme) || "http".equalsIgnoreCase(scheme)) {
                    Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                    try {
                        startActivity(intent);
                    } catch (ActivityNotFoundException ignored) {
                        Toast.makeText(MainActivity.this, "Tidak ada aplikasi untuk membuka tautan ini", Toast.LENGTH_SHORT).show();
                    }
                    return true;
                }
                return true;
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(PermissionRequest request) {
                runOnUiThread(() -> handleWebPermissionRequest(request));
            }

            @Override
            public void onPermissionRequestCanceled(PermissionRequest request) {
                if (pendingWebPermissionRequest == request) pendingWebPermissionRequest = null;
                Log.w(MIC_TAG, "WebView permission request canceled by WebView");
            }

            @Override
            public boolean onConsoleMessage(ConsoleMessage message) {
                String text = message.message();
                if (text != null && (text.contains("FAMILY_COLONY_MIC") || text.toLowerCase().contains("media"))) {
                    Log.i(MIC_TAG, "JS console " + message.messageLevel() + " "
                            + message.sourceId() + ":" + message.lineNumber() + " " + text);
                }
                return super.onConsoleMessage(message);
            }

            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = callback;
                selectedApkUri = null;

                // Return a document URI to the WebView. Selecting an APK for upload
                // must never launch Android Package Installer automatically.
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                String[] accepted = params != null ? params.getAcceptTypes() : null;
                java.util.ArrayList<String> mimeTypes = new java.util.ArrayList<>();
                if (accepted != null) {
                    for (String type : accepted) {
                        if (type == null || type.trim().isEmpty()) continue;
                        for (String part : type.split(",")) {
                            String value = part.trim();
                            if (value.startsWith(".")) continue;
                            if (value.matches("[A-Za-z0-9._+-]+/[A-Za-z0-9._+-]+") || value.endsWith("/*")) {
                                if (!mimeTypes.contains(value)) mimeTypes.add(value);
                            }
                        }
                    }
                }
                if (mimeTypes.isEmpty()) {
                    intent.setType("*/*");
                } else if (mimeTypes.size() == 1) {
                    intent.setType(mimeTypes.get(0));
                } else {
                    intent.setType("*/*");
                    intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toArray(new String[0]));
                }
                if (params != null && params.getMode() == FileChooserParams.MODE_OPEN_MULTIPLE) {
                    intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
                }
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
                try {
                    startActivityForResult(Intent.createChooser(intent, "Pilih file untuk diunggah"), FILE_CHOOSER_REQUEST);
                } catch (ActivityNotFoundException | SecurityException e) {
                    filePathCallback.onReceiveValue(null);
                    filePathCallback = null;
                    Toast.makeText(MainActivity.this, "Pengelola file tidak tersedia", Toast.LENGTH_SHORT).show();
                    return false;
                }
                return true;
            }
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request != null && request.isForMainFrame() && error != null) {
                    Log.e(MIC_TAG, "Main-frame load error code=" + error.getErrorCode()
                            + " description=" + error.getDescription());
                }
            }
        });

        if (savedInstanceState != null) {
            webView.restoreState(savedInstanceState);
        } else {
            webView.loadUrl("https://" + APP_ASSET_HOST + "/assets/index.html");
        }
    }

    private void handleWebPermissionRequest(PermissionRequest request) {
        if (request == null) return;
        Uri origin = request.getOrigin();
        String[] resources = request.getResources();
        boolean asksForAudio = false;
        if (resources != null) {
            for (String resource : resources) {
                if (PermissionRequest.RESOURCE_AUDIO_CAPTURE.equals(resource)) asksForAudio = true;
            }
        }
        String webViewVersion = getWebViewPackageVersion();
        Log.i(MIC_TAG, "Web permission origin=" + origin + " resources="
                + java.util.Arrays.toString(resources) + " androidPermission="
                + getMicrophonePermissionStatus() + " webView=" + webViewVersion);
        if (!isTrustedAssetOrigin(origin) || !asksForAudio) {
            Log.w(MIC_TAG, "Denied WebView request: untrusted origin or missing audio capture resource");
            request.deny();
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                && checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            if (pendingWebPermissionRequest != null) {
                Log.w(MIC_TAG, "Denied second audio request while Android permission dialog is pending");
                request.deny();
                return;
            }
            pendingWebPermissionRequest = request;
            Log.i(MIC_TAG, "Requesting Android runtime RECORD_AUDIO permission");
            requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, MICROPHONE_PERMISSION_REQUEST);
            return;
        }
        try {
            request.grant(new String[]{PermissionRequest.RESOURCE_AUDIO_CAPTURE});
            Log.i(MIC_TAG, "Granted RESOURCE_AUDIO_CAPTURE to trusted app origin");
        } catch (IllegalStateException e) {
            Log.e(MIC_TAG, "WebView permission request became invalid before grant", e);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == MICROPHONE_PERMISSION_REQUEST) {
            PermissionRequest request = pendingWebPermissionRequest;
            pendingWebPermissionRequest = null;
            String status = getMicrophonePermissionStatus();
            Log.i(MIC_TAG, "Android runtime permission result=" + status);
            if (request == null) {
                Log.w(MIC_TAG, "No pending WebView request remains after Android permission result");
                return;
            }
            if (status.equals("GRANTED")) {
                try {
                    request.grant(new String[]{PermissionRequest.RESOURCE_AUDIO_CAPTURE});
                    Log.i(MIC_TAG, "Granted pending WebView RESOURCE_AUDIO_CAPTURE");
                } catch (IllegalStateException e) {
                    Log.e(MIC_TAG, "Pending WebView request expired before grant", e);
                }
            } else {
                try { request.deny(); } catch (IllegalStateException ignored) { }
                Log.w(MIC_TAG, "Denied pending WebView audio request; Android permission=" + status);
                Toast.makeText(this, "Izin mikrofon diperlukan untuk merekam pesan suara.", Toast.LENGTH_SHORT).show();
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST && filePathCallback != null) {
            Uri[] results = WebChromeClient.FileChooserParams.parseResult(resultCode, data);
            if (results != null) {
                for (Uri uri : results) {
                    if (uri == null) continue;
                    try {
                        getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    } catch (SecurityException | IllegalArgumentException ignored) {
                        // Some document providers grant a temporary read permission only.
                    }
                    if (selectedApkUri == null && isApkDocument(uri)) {
                        selectedApkUri = uri;
                    }
                }
            } else {
                selectedApkUri = null;
            }
            filePathCallback.onReceiveValue(results);
            filePathCallback = null;
            return;
        }

        if (requestCode == UNKNOWN_APP_SOURCE_REQUEST) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                    && getPackageManager().canRequestPackageInstalls()) {
                Toast.makeText(this, "Izin pemasangan tersedia. Kembali ke APK Manager lalu tekan INSTAL APK.", Toast.LENGTH_LONG).show();
            } else {
                Toast.makeText(this, "Izin instalasi dari FAMILY COLONY belum diaktifkan.", Toast.LENGTH_LONG).show();
            }
            return;
        }

        if (requestCode == APK_INSTALL_REQUEST) {
            if (resultCode == RESULT_OK) {
                Toast.makeText(this, "Android melaporkan pemasangan selesai.", Toast.LENGTH_LONG).show();
            } else if (resultCode == RESULT_CANCELED) {
                Toast.makeText(this, "Pemasangan dibatalkan atau belum selesai.", Toast.LENGTH_LONG).show();
            }
        }
    }

    private String getDocumentDisplayName(Uri uri) {
        if (uri == null) return "";
        try (Cursor cursor = getContentResolver().query(
                uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) {
                int index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if (index >= 0) {
                    String name = cursor.getString(index);
                    return name == null ? "" : name;
                }
            }
        } catch (Exception ignored) {
            // A provider may not expose display-name metadata.
        }
        return "";
    }

    private boolean isApkDocument(Uri uri) {
        if (uri == null || !"content".equalsIgnoreCase(uri.getScheme())) return false;
        String name = getDocumentDisplayName(uri).toLowerCase(java.util.Locale.ROOT);
        String mime = getContentResolver().getType(uri);
        return name.endsWith(".apk")
                || "application/vnd.android.package-archive".equalsIgnoreCase(mime);
    }

    private void installSelectedApkFromWeb() {
        Uri apkUri = selectedApkUri;
        if (!isApkDocument(apkUri)) {
            Toast.makeText(this, "Pilih file APK terlebih dahulu melalui APK Manager.", Toast.LENGTH_LONG).show();
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && !getPackageManager().canRequestPackageInstalls()) {
            Intent settingsIntent = new Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:" + getPackageName()));
            try {
                startActivityForResult(settingsIntent, UNKNOWN_APP_SOURCE_REQUEST);
            } catch (ActivityNotFoundException | SecurityException e) {
                Toast.makeText(this, "Pengaturan izin instalasi tidak dapat dibuka.", Toast.LENGTH_LONG).show();
            }
            return;
        }

        try {
            Intent installIntent = new Intent(Intent.ACTION_INSTALL_PACKAGE);
            installIntent.setDataAndType(apkUri, "application/vnd.android.package-archive");
            installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            installIntent.setClipData(ClipData.newRawUri("APK package", apkUri));
            installIntent.putExtra(Intent.EXTRA_RETURN_RESULT, true);
            startActivityForResult(installIntent, APK_INSTALL_REQUEST);
        } catch (ActivityNotFoundException | SecurityException e) {
            Toast.makeText(this, "Android tidak dapat membuka pemasang paket untuk file ini.", Toast.LENGTH_LONG).show();
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        if (webView != null) webView.saveState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        if (filePathCallback != null) {
            filePathCallback.onReceiveValue(null);
            filePathCallback = null;
        }
        denyPendingWebPermission("activity destroyed");
        if (webView != null) {
            webView.stopLoading();
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
