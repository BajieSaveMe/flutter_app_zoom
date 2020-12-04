package com.david.zendesk;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.zendesk.service.ErrorResponse;
import com.zendesk.service.ZendeskCallback;

import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ZendeskPlugin implements MethodChannel.MethodCallHandler {
    private final static String TAG = "ZendeskPlugin";
    private final Activity activity;
    private ZendeskManager zendeskManager;
    private boolean isInit = false;
    private MethodChannel.Result result;
    public static MethodChannel flutterChannel;

    public ZendeskPlugin(Activity activity) {
        this.activity = activity;
    }

    public static void registerWith(Activity activity, BinaryMessenger messenger) {
        flutterChannel = new MethodChannel(messenger, "com.nexosxt.plugin/zendesk");
        ZendeskPlugin instance = new ZendeskPlugin(activity);
        flutterChannel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        this.result = result;
        switch (call.method) {
            case "init":
                getZendeskManager().init();
                break;
            case "chat":
                getZendeskManager().chatV2();
                break;
            case "messaging":
                getZendeskManager().messaging();
                break;
            case "request":
                getZendeskManager().request();
                break;
            case "requestList":
                getZendeskManager().requestList();
                break;
            case "helpCenter":
                getZendeskManager().helpCenter(call.arguments.toString());
            case "addUserTags":
                getZendeskManager().addUserTags(call.arguments.toString(), new ZendeskCallback<List<String>>() {
                    @Override
                    public void onSuccess(List<String> strings) {

                    }

                    @Override
                    public void onError(ErrorResponse errorResponse) {

                    }
                });
                break;
            case "removeUserTags":
                getZendeskManager().removeUserTags(call.arguments.toString(), new ZendeskCallback<List<String>>() {
                    @Override
                    public void onSuccess(List<String> strings) {

                    }

                    @Override
                    public void onError(ErrorResponse errorResponse) {

                    }
                });
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

    private ZendeskManager getZendeskManager() {
        if (zendeskManager == null) {
            if (activity != null && !activity.isFinishing()) {
                zendeskManager = new ZendeskManager(activity);
            }
        }
        return zendeskManager;
    }
}
