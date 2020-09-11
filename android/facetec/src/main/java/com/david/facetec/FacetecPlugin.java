package com.david.facetec;

import android.app.Activity;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.david.ZoomProcessors.Processor;
import com.david.ZoomProcessors.ThemeHelpers;
import com.david.ZoomProcessors.ZoomGlobalState;
import com.facetec.zoom.sdk.ZoomSDK;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FacetecPlugin implements MethodChannel.MethodCallHandler {

    private final static String TAG = "FacetecPlugin";
    private final Activity activity;
    private FacetecManager facetecManager;
    public Processor latestProcessor;
    private boolean isInit = false;
    private MethodChannel.Result result;

    public FacetecPlugin(Activity activity) {
        this.activity = activity;
        Log.v(TAG, "========init called!");
        ZoomSDK.initialize(
                activity,
                ZoomGlobalState.DeviceLicenseKeyIdentifier,
                ZoomGlobalState.PublicFaceMapEncryptionKey,
                new ZoomSDK.InitializeCallback() {
                    @Override
                    public void onCompletion(final boolean successful) {
                        if (successful) {
                            isInit = true;
                            ThemeHelpers.setAppTheme("Pseudo-Fullscreen");
                            Log.e(TAG, "===============init success");
                        } else {
                            Log.e(TAG, "===============init fail");
                        }
                    }
                }
        );
    }

    public static void registerWith(Activity activity, BinaryMessenger messenger) {
        MethodChannel channel = new MethodChannel(messenger, "facetec_plugin");
        FacetecPlugin instance = new FacetecPlugin(activity);
        channel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        this.result = result;
        switch (call.method) {
            case "livenessCheck":
                if (isInit)
                    getFacetecManager().livenessCheck(sessionTokenErrorCallback);
                else Toast.makeText(activity, "init error", Toast.LENGTH_SHORT).show();
                break;
            case "enrollUser":
                if (isInit)
                    getFacetecManager().enrollUser(sessionTokenErrorCallback);
                else Toast.makeText(activity, "init error", Toast.LENGTH_SHORT).show();
                break;
            case "authenticateUser":
                if (isInit)
                    getFacetecManager().authenticateUser(sessionTokenErrorCallback);
                else Toast.makeText(activity, "init error", Toast.LENGTH_SHORT).show();
                break;
            case "photoIDMatch":
                if (isInit)
                    getFacetecManager().photoIDMatch(sessionTokenErrorCallback);
                else Toast.makeText(activity, "init error", Toast.LENGTH_SHORT).show();
                break;
            default:
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        result.notImplemented();
                    }
                });

        }
    }

    private FacetecManager getFacetecManager() {
        if (facetecManager == null) {
            if (activity != null && !activity.isFinishing()) {
                facetecManager = new FacetecManager(activity);
            }
        }
        return facetecManager;
    }

    // Handle error retrieving the Session Token from the server
    Processor.SessionTokenErrorCallback sessionTokenErrorCallback = new Processor.SessionTokenErrorCallback() {
        @Override
        public void onError() {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    result.error("-1", "error", null);
                }
            });
        }

        @Override
        public <T> void onSuccess(T t) {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    result.success(t);
                }
            });
        }
    };
}
