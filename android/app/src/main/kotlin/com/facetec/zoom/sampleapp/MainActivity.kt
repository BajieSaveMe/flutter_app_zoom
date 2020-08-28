package com.facetec.zoom.sampleapp

import com.david.facetec.FacetecPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FacetecPlugin.registerWith(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
