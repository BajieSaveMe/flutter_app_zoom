package com.david.zendesk;

import android.app.Activity;

import com.zendesk.service.ZendeskCallback;
import com.zendesk.util.StringUtils;

import java.util.List;

import zendesk.answerbot.AnswerBot;
import zendesk.answerbot.AnswerBotEngine;
import zendesk.chat.Chat;
import zendesk.chat.ChatConfiguration;
import zendesk.chat.ChatEngine;
import zendesk.core.UserProvider;
import zendesk.core.Zendesk;
import zendesk.messaging.MessagingActivity;
import zendesk.support.Guide;
import zendesk.support.Support;
import zendesk.support.SupportEngine;
import zendesk.support.guide.HelpCenterActivity;
import zendesk.support.request.RequestActivity;
import zendesk.support.requestlist.RequestListActivity;

public class ZendeskManager {
    private Activity activity;
    private static final String zendeskUrl = "..."; // replace with your Zendesk account details
    private static final String appId = "...";      // replace with your Zendesk account details
    private static final String clientId = "...";   // replace with your Zendesk account details
    private static final String chatAccountKey = "";

    public ZendeskManager(Activity activity) {
        this.activity = activity;
    }

    public void init() {
        Zendesk.INSTANCE.init(activity, zendeskUrl, appId, clientId);
        Support.INSTANCE.init(Zendesk.INSTANCE);
        AnswerBot.INSTANCE.init(Zendesk.INSTANCE, Guide.INSTANCE);
        Chat.INSTANCE.init(activity, chatAccountKey);
    }

    public void chatV2() {
        ChatConfiguration chatConfiguration = ChatConfiguration.builder().build();
        MessagingActivity.builder()
                .withEngines(ChatEngine.engine())
                .show(activity, chatConfiguration);
    }

    public void messaging() {
        MessagingActivity.builder()
                .withEngines(AnswerBotEngine.engine(), SupportEngine.engine(), ChatEngine.engine())
                .show(activity);
    }

    public void request() {
        RequestActivity.builder()
                .show(activity);
    }

    public void requestList() {
        RequestListActivity.builder()
                .show(activity);
    }

    public void helpCenter(String labels) {
        String[] labelsArray = null;

        if (StringUtils.hasLength(labels)) {
            labelsArray = labels.split(",");
        }

        HelpCenterActivity.builder()
                .withLabelNames(labelsArray)
                .show(activity);
    }

    public void registerPush(String devicePushToken, ZendeskCallback<String> callback) {
        Zendesk.INSTANCE.provider().pushRegistrationProvider().registerWithDeviceIdentifier(devicePushToken, callback);
    }

    public void registerPushUA(String devicePushToken, ZendeskCallback<String> callback) {
        Zendesk.INSTANCE.provider().pushRegistrationProvider().registerWithUAChannelId(devicePushToken, callback);
    }

    public void unregisterPush(ZendeskCallback<Void> callback) {
        Zendesk.INSTANCE.provider().pushRegistrationProvider().unregisterDevice(callback);
    }

    public void addUserTags(String userTags, ZendeskCallback<List<String>> callback) {
        final UserProvider userProvider = Zendesk.INSTANCE.provider().userProvider();
        userProvider.addTags(StringUtils.fromCsv(userTags), callback);
    }

    public void removeUserTags(String userTags, ZendeskCallback<List<String>> callback) {
        final UserProvider userProvider = Zendesk.INSTANCE.provider().userProvider();
        userProvider.deleteTags(StringUtils.fromCsv(userTags), callback);
    }
}
