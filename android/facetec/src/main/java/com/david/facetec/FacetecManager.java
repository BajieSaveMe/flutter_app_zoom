package com.david.facetec;

import android.app.Activity;
import android.util.Log;
import android.widget.Toast;

import com.david.Processors.AuthenticateProcessor;
import com.david.Processors.Config;
import com.david.Processors.EnrollmentProcessor;
import com.david.Processors.LivenessCheckProcessor;
import com.david.Processors.NetworkingHelpers;
import com.david.Processors.PhotoIDMatchProcessor;
import com.david.Processors.Processor;
import com.facetec.sdk.FaceTecSDK;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;

import static java.util.UUID.randomUUID;

public class FacetecManager {
    private Activity activity;
    public Processor latestProcessor;
    static String latestExternalDatabaseRefID = "";

    public FacetecManager(Activity activity) {
        this.activity = activity;
    }

    ///活体检测
    void livenessCheck(Processor.SessionTokenErrorCallback callback) {
        activity.runOnUiThread(() -> getSessionToken(sessionToken -> latestProcessor = new LivenessCheckProcessor(sessionToken, activity, callback)));
    }

    ///注册用户
    void enrollUser(Processor.SessionTokenErrorCallback callback) {
        activity.runOnUiThread(() -> getSessionToken(sessionToken -> {
            latestExternalDatabaseRefID = "nexosgo_user_" + randomUUID();
            latestProcessor = new EnrollmentProcessor(sessionToken, activity, callback);
        }));
    }

    ///验证用户
    void authenticateUser(Processor.SessionTokenErrorCallback callback) {
        if (latestExternalDatabaseRefID.length() == 0) {
            Toast.makeText(activity, "Please enroll first before trying authentication.", Toast.LENGTH_SHORT).show();
            return;
        }
        getSessionToken(sessionToken -> latestProcessor = new AuthenticateProcessor(sessionToken, activity, callback));
    }

    ///卡片检测
    void photoIDMatch(Processor.SessionTokenErrorCallback callback) {
        getSessionToken(sessionToken -> {
            latestExternalDatabaseRefID = "nexosgo_user_" + randomUUID();
            latestProcessor = new PhotoIDMatchProcessor(sessionToken, activity, callback);
        });
    }

    public void getSessionToken(final FacetecPlugin.SessionTokenCallback sessionTokenCallback) {
        // Do the network call and handle result
        okhttp3.Request request = new okhttp3.Request.Builder()
                .header("X-Device-Key", Config.DeviceKeyIdentifier)
                .header("User-Agent", FaceTecSDK.createFaceTecAPIUserAgentString(""))
                .url(Config.BaseURL + "/session-token")
                .get()
                .build();

        NetworkingHelpers.getApiClient().newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                e.printStackTrace();
                Log.d("FaceTecSDKSampleApp", "Exception raised while attempting HTTPS call.");

                // If this comes from HTTPS cancel call, don't set the sub code to NETWORK_ERROR.
                if (!e.getMessage().equals(NetworkingHelpers.OK_HTTP_RESPONSE_CANCELED)) {
                    handleErrorGettingServerSessionToken();
                }
            }

            @Override
            public void onResponse(Call call, okhttp3.Response response) throws IOException {
                String responseString = response.body().string();
                response.body().close();
                try {
                    JSONObject responseJSON = new JSONObject(responseString);
                    if (responseJSON.has("sessionToken")) {
                        sessionTokenCallback.onSessionTokenReceived(responseJSON.getString("sessionToken"));
                    } else {
                        handleErrorGettingServerSessionToken();
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    Log.d("FaceTecSDKSampleApp", "Exception raised while attempting to parse JSON result.");
                    handleErrorGettingServerSessionToken();
                }
            }
        });
    }

    public void handleErrorGettingServerSessionToken() {
        Toast.makeText(activity, "Session could not be started due to an unexpected issue during the network request.", Toast.LENGTH_SHORT).show();
    }

    public static String getLatestExternalDatabaseRefID() {
        return latestExternalDatabaseRefID;
    }

}
