package com.example.renamery

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "jp.toyocraft.renamery/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // GeneratedPluginRegistrant is called automatically by FlutterActivity in recent versions.
        // If we call it manually, it might cause crashes due to double-registration.

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUrl") {
                val url = call.argument<String>("url")
                if (url != null) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        // Use context from activity to start the new intent
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not launch URL: ${e.localizedMessage}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
