import 'dart:async' show TimeoutException;
import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

const wgTunnelName = 'k8';
const _wgPackage   = 'com.wireguard.android';
// Explicit component required on Android 8+ — implicit static-receiver
// broadcasts are blocked since Oreo without a named component.
const _wgReceiver  = 'com.wireguard.android.model.TunnelManager\$IntentReceiver';
const _wgActionUp   = 'com.wireguard.android.action.SET_TUNNEL_UP';
const _wgActionDown = 'com.wireguard.android.action.SET_TUNNEL_DOWN';
const _wgChannel    = MethodChannel('wireguard_permission');

/// Returns whether a VPN transport is currently active on this device.
/// Returns null if the check could not complete (timeout / channel error).
///
/// [isAndroid] overrides the platform check in tests.
Future<bool?> isWireGuardActive({
  bool Function()? isAndroid,
}) async {
  if (!(isAndroid?.call() ?? Platform.isAndroid)) return false;
  try {
    return await _wgChannel
            .invokeMethod<bool>('isVpnActive')
            .timeout(AppConstants.wgCheckTimeout) ??
        false;
  } catch (_) {
    return null;
  }
}

/// Toggles the WireGuard tunnel [wgTunnelName].
///
/// [goOffline] true → bring tunnel DOWN; false → bring tunnel UP.
/// Returns true if the tunnel reached the desired state, false on any failure.
/// Shows SnackBar feedback. No-ops silently on non-Android platforms.
///
/// Optional overrides (for testing only):
/// * [isAndroid] — replaces the `Platform.isAndroid` check.
/// * [vpnActiveCheck] — replaces the `isWireGuardActive()` pre-flight and
///   post-broadcast check. Returns null when the state is unknown.
/// * [verifyDelay] — replaces the 2-second post-broadcast VPN-verify delay.
/// * [broadcastFn] — replaces the `AndroidIntent.sendBroadcast()` call.
Future<bool> toggleWireGuardTunnel({
  required bool goOffline,
  required BuildContext context,
  bool Function()? isAndroid,
  Future<bool?> Function()? vpnActiveCheck,
  Duration verifyDelay = AppConstants.wgVerifyDelay,
  Future<void> Function()? broadcastFn,
  Future<bool> Function()? permissionRequester,
}) async {
  if (!(isAndroid?.call() ?? Platform.isAndroid)) return true;

  // Pre-flight: skip the broadcast only when confident about the current state.
  // A null result means the check failed — proceed rather than assume desired state.
  final checkVpn = vpnActiveCheck ?? () => isWireGuardActive();
  final alreadyActive = await checkVpn();
  if (goOffline && alreadyActive == false) return true;   // confident: already DOWN
  if (!goOffline && alreadyActive == true) return true;   // confident: already UP

  bool granted;
  try {
    granted = permissionRequester != null
        ? await permissionRequester()
        : (await _wgChannel
                .invokeMethod<bool>('request')
                .timeout(AppConstants.wgRequestTimeout)) ??
            false;
  } on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WireGuard permission request timed out — try again'),
          duration: Duration(seconds: 4),
        ),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WireGuard permission check failed — ${e.toString().split('\n').first}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
    return false;
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
    return false;
  }

  try {
    if (broadcastFn != null) {
      await broadcastFn();
    } else {
      final intent = AndroidIntent(
        action: goOffline ? _wgActionDown : _wgActionUp,
        package: _wgPackage,
        componentName: _wgReceiver,
        arguments: <String, dynamic>{'tunnel': wgTunnelName},
      );
      await intent.sendBroadcast();
    }

    // Verify the tunnel reached the desired state for both UP and DOWN.
    // WireGuard may silently ignore the broadcast (no permission, app stopped,
    // or the tunnel is mid-transition).
    if (verifyDelay > Duration.zero) await Future.delayed(verifyDelay);
    final nowActive = await checkVpn();

    if (goOffline) {
      // Tunnel should be DOWN — still active means the broadcast was ignored.
      if (nowActive == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'WireGuard tunnel did not stop — open the WireGuard app and bring the tunnel down manually',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return false;
      }
    } else {
      // Tunnel should be UP — not active means the broadcast was ignored.
      if (nowActive != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'WireGuard tunnel did not start — open the WireGuard app and bring the tunnel up manually',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return false;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            goOffline
                ? 'WireGuard: tunnel "$wgTunnelName" is down'
                : 'WireGuard: tunnel "$wgTunnelName" is up',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return true;
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
    return false;
  }
}
