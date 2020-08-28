package com.david.facetec;

import android.app.Activity;
import android.widget.Toast;

import com.david.ZoomProcessors.AuthenticateProcessor;
import com.david.ZoomProcessors.EnrollmentProcessor;
import com.david.ZoomProcessors.LivenessCheckProcessor;
import com.david.ZoomProcessors.PhotoIDMatchProcessor;
import com.david.ZoomProcessors.Processor;
import com.david.ZoomProcessors.ZoomGlobalState;

public class FacetecManager {
    private Activity activity;
    public Processor latestProcessor;

    public FacetecManager(Activity activity) {
        this.activity = activity;
    }

    ///活体检测
    void livenessCheck(Processor.SessionTokenErrorCallback callback) {
        latestProcessor = new LivenessCheckProcessor(activity, callback);
    }

    ///注册用户
    void enrollUser(Processor.SessionTokenErrorCallback callback) {
        latestProcessor = new EnrollmentProcessor(activity, callback);
    }

    ///验证用户
    void authenticateUser(Processor.SessionTokenErrorCallback callback) {
        if (!ZoomGlobalState.isRandomUsernameEnrolled) {
            Toast.makeText(activity, "Please enroll first before trying authentication.", Toast.LENGTH_SHORT).show();
            return;
        }
        latestProcessor = new AuthenticateProcessor(activity, callback);
    }

    ///卡片检测
    void photoIDMatch(Processor.SessionTokenErrorCallback callback) {
        latestProcessor = new PhotoIDMatchProcessor(activity, callback);
    }
}
