package com.david.Processors;

import java.util.HashMap;

public abstract class Processor {
    public abstract boolean isSuccess();

    public interface SessionTokenErrorCallback {
        void onError(String method, HashMap error);

        void onSuccess(String method, HashMap message);
    }
}

