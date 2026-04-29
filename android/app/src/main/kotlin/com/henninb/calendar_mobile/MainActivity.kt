package com.henninb.calendar_mobile

import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val wgPermission = "com.wireguard.android.permission.CONTROL_TUNNELS"
    private val channelName = "wireguard_permission"
    private val requestCode = 1001

    private val pendingResults = mutableListOf<MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isGranted" -> {
                        val granted = ContextCompat.checkSelfPermission(this, wgPermission) ==
                                PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    "request" -> {
                        if (ContextCompat.checkSelfPermission(this, wgPermission) ==
                                PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            pendingResults.add(result)
                            // Only launch the dialog for the first queued request;
                            // subsequent ones share the same dialog outcome.
                            if (pendingResults.size == 1) {
                                ActivityCompat.requestPermissions(this, arrayOf(wgPermission), requestCode)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Fail any in-flight permission requests so their Dart Futures
        // resolve immediately rather than hanging until the 15s timeout.
        pendingResults.forEach { it.success(false) }
        pendingResults.clear()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == this.requestCode) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            val pending = pendingResults.toList()
            pendingResults.clear()
            pending.forEach { it.success(granted) }
        }
    }
}
