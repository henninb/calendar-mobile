import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const wgTunnelName = 'k8';
const _wgPackage   = 'com.wireguard.android';
// Explicit component required on Android 8+ — implicit static-receiver
// broadcasts are blocked since Oreo without a named component.
const _wgReceiver  = 'com.wireguard.android.model.TunnelManager\$IntentReceiver';
const _wgActionUp   = 'com.wireguard.android.action.SET_TUNNEL_UP';
const _wgActionDown = 'com.wireguard.android.action.SET_TUNNEL_DOWN';
const _wgChannel    = MethodChannel('wireguard_permission');

/// Toggles the WireGuard tunnel [wgTunnelName].
///
/// [goOffline] true → bring tunnel DOWN; false → bring tunnel UP.
/// Shows SnackBar feedback. No-ops silently on non-Android platforms.
Future<void> toggleWireGuardTunnel({
  required bool goOffline,
  required BuildContext context,
}) async {
  if (!Platform.isAndroid) return;

  // Request CONTROL_TUNNELS — custom dangerous permission from WireGuard.
  // Must be granted at runtime; wrap in try/catch so a MissingPluginException
  // or channel error doesn't silently kill the function.
  bool granted;
  try {
    granted = await _wgChannel.invokeMethod<bool>('request') ?? false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WireGuard permission check failed — ${e.toString().split('\n').first}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
    return;
  }

  if (!granted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permission denied — go to Android Settings → Apps → '
            'Calendar Mobile → Permissions and grant WireGuard Remote Control',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
    return;
  }

  try {
    final intent = AndroidIntent(
      action: goOffline ? _wgActionDown : _wgActionUp,
      package: _wgPackage,
      componentName: _wgReceiver,
      arguments: <String, dynamic>{'tunnel': wgTunnelName},
    );
    await intent.sendBroadcast();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            goOffline
                ? 'WireGuard: bringing tunnel "$wgTunnelName" down…'
                : 'WireGuard: bringing tunnel "$wgTunnelName" up…',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'WireGuard tunnel control failed — '
            '${e.toString().split('\n').first}',
          ),
        ),
      );
    }
  }
}
