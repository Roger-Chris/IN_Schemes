package com.inschemes.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var automaticSpeechBridge: AutomaticSpeechBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        automaticSpeechBridge = AutomaticSpeechBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        automaticSpeechBridge?.dispose()
        automaticSpeechBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
