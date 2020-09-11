package com.david.ZoomProcessors;

public abstract class Processor {
    public abstract boolean isSuccess();

    public interface SessionTokenErrorCallback {
        void onError();
        <T> void onSuccess(T t);
    }
}

