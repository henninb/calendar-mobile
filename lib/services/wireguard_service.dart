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
///
/// [isAndroid] overrides the platform check in tests.
Future<bool> isWireGuardActive({
  bool Function()? isAndroid,
}) async {
  if (!(isAndroid?.call() ?? Platform.isAndroid)) return false;
  try {
    return await _wgChannel
            .invokeMethod<bool>('isVpnActive')
            .timeout(AppConstants.wgCheckTimeout) ??
        false;
  } catch (_) {
    return false;
  }
}

/// Toggles the WireGuard tunnel [wgTunnelName].
///
/// [goOffline] true → bring tunnel DOWN; false → bring tunnel UP.
/// Returns true if the broadcast was dispatched, false on any failure.
/// Shows SnackBar feedback. No-ops silently on non-Android platforms.
///
/// Optional overrides (for testing only):
/// * [isAndroid] — replaces the `Platform.isAndroid` check.
/// * [vpnActiveCheck] — replaces the `isWireGuardActive()` pre-flight and
///   post-broadcast check.
/// * [verifyDelay] — replaces the 2-second post-broadcast VPN-verify delay.
/// * [broadcastFn] — replaces the `AndroidIntent.sendBroadcast()` call.
Future<bool> toggleWireGuardTunnel({
  required bool goOffline,
  required BuildContext context,
  bool Function()? isAndroid,
  Future<bool> Function()? vpnActiveCheck,
  Duration verifyDelay = AppConstants.wgVerifyDelay,
  Future<void> Function()? broadcastFn,
  Future<bool> Function()? permissionRequester,
}) async {
  if (!(isAndroid?.call() ?? Platform.isAndroid)) return true;

  // Pre-flight: skip the broadcast if the tunnel is already in the desired state.
  final checkVpn = vpnActiveCheck ?? () => isWireGuardActive();
  final alreadyActive = await checkVpn();
  if (goOffline && !alreadyActive) return true;   // want DOWN, already DOWN
  if (!goOffline && alreadyActive) return true;   // want UP, already UP

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

    // For the UP case, verify the VPN actually came up — WireGuard may be
    // stopped and unable to process the broadcast (e.g. no VPN permission
    // accepted yet). Give it 2 seconds before declaring failure.
    if (!goOffline) {
      if (verifyDelay > Duration.zero) await Future.delayed(verifyDelay);
      final nowActive = await checkVpn();
      if (!nowActive) {
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
                ? 'WireGuard: bringing tunnel "$wgTunnelName" down…'
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
