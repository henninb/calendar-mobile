package com.henninb.calendar_mobile

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
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
                    "isVpnActive" -> {
                        val cm = getSystemService(ConnectivityManager::class.java)
                        val active = cm.allNetworks.any { network ->
                            cm.getNetworkCapabilities(network)
                                ?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                        }
                        result.success(active)
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
                    "launchApp" -> {
                        val pkg = call.argument<String>("package") ?: ""
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(pkg)
                            if (intent != null) {
                                intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("LAUNCH_FAILED", e.message ?: "Launch failed", null)
                        }
                    }
                    "sendTunnelBroadcast" -> {
                        val tunnelName = call.argument<String>("tunnel") ?: ""
                        val action = call.argument<String>("action") ?: ""
                        try {
                            val intent = Intent(action).apply {
                                component = ComponentName(
                                    "com.wireguard.android",
                                    "com.wireguard.android.model.TunnelManager\$IntentReceiver"
                                )
                                putExtra("tunnel", tunnelName)
                            }
                            sendBroadcast(intent)
                            result.success(true)
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", e.message ?: "Permission denied", null)
                        } catch (e: Exception) {
                            result.error("BROADCAST_FAILED", e.message ?: "Broadcast failed", null)
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
