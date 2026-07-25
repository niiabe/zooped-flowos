package com.zooped.niiabe

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zooped/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getAbi") {
                    val abi = mapOf(
                        "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
                        "primaryAbi" to (Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown")
                    )
                    result.success(abi)
                } else {
                    result.notImplemented()
                }
            }
    }
}
