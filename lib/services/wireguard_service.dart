import 'dart:async' show TimeoutException;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

const wgTunnelName = 'k8';
const _wgActionUp = 'com.wireguard.android.action.SET_TUNNEL_UP';
const _wgActionDown = 'com.wireguard.android.action.SET_TUNNEL_DOWN';
const _wgChannel = MethodChannel('wireguard_permission');

Future<void> _openWireGuard() async {
  try {
    await _wgChannel.invokeMethod<bool>('launchApp', {
      'package': 'com.wireguard.android',
    });
  } catch (_) {
    // no-op if WireGuard is not installed
  }
}

/// Returns whether a VPN transport is currently active on this device.
/// Returns null if the check could not complete (timeout / channel error).
///
/// [isAndroid] overrides the platform check in tests.
Future<bool?> isWireGuardActive({bool Function()? isAndroid}) async {
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

/// Toggles the WireGuard tunnel identified by [tunnelName].
///
/// [goOffline] true → bring tunnel DOWN; false → bring tunnel UP.
/// [tunnelName] must match the tunnel name exactly as it appears in the
/// WireGuard app (case-sensitive). Defaults to [wgTunnelName].
/// Returns true if the tunnel reached the desired state, false on any failure.
/// Shows SnackBar feedback. No-ops silently on non-Android platforms.
///
/// Optional overrides (for testing only):
/// * [isAndroid] — replaces the `Platform.isAndroid` check.
/// * [vpnActiveCheck] — replaces the `isWireGuardActive()` pre-flight and
///   polling check. Returns null when the state is unknown.
/// * [verifyDelay] — poll interval; Duration.zero → single immediate check
///   (test mode, skips the polling loop).
/// * [broadcastFn] — replaces the native `sendTunnelBroadcast` channel call.
Future<bool> toggleWireGuardTunnel({
  required bool goOffline,
  required BuildContext context,
  String tunnelName = wgTunnelName,
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
  if (goOffline && alreadyActive == false)
    return true; // confident: already DOWN
  if (!goOffline && alreadyActive == true) return true; // confident: already UP

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
          content: Text(
            'WireGuard permission check failed — ${e.toString().split('\n').first}',
          ),
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
      await _wgChannel.invokeMethod<bool>(
        'sendTunnelBroadcast',
        <String, String>{
          'action': goOffline ? _wgActionDown : _wgActionUp,
          'tunnel': tunnelName,
        },
      );
    }

    // Poll until the tunnel reaches the desired state or the timeout expires.
    // Duration.zero skips the loop and does a single immediate check (test mode).
    bool? nowActive;
    if (verifyDelay == Duration.zero) {
      nowActive = await checkVpn();
    } else {
      final deadline = DateTime.now().add(AppConstants.wgVerifyTimeout);
      do {
        await Future.delayed(verifyDelay);
        nowActive = await checkVpn();
        if (goOffline && nowActive != true) break;
        if (!goOffline && nowActive == true) break;
      } while (DateTime.now().isBefore(deadline));
    }

    if (goOffline) {
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
      if (nowActive != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'WireGuard tunnel "$tunnelName" did not start — '
                'verify the tunnel name matches exactly in WireGuard '
                'and that "Allow remote control apps" is enabled in WireGuard Settings.',
              ),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Open WireGuard',
                onPressed: _openWireGuard,
              ),
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
                ? 'WireGuard: tunnel "$tunnelName" is down'
                : 'WireGuard: tunnel "$tunnelName" is up',
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
