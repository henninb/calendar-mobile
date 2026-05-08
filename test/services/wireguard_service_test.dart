import 'dart:async' show TimeoutException;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/services/wireguard_service.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

bool get _isAndroid => Platform.isAndroid;
bool _onAndroid() => true;
bool _notAndroid() => false;

// Sets up the 'wireguard_permission' MethodChannel mock for the duration of
// a single test.  [isVpnActive] is the sequence of booleans returned by
// successive 'isVpnActive' calls; [requestResult] is returned by 'request'.
void _mockChannel({
  List<bool?>? isVpnActive,
  bool? requestResult,
  bool throwTimeout = false,
  bool throwError = false,
}) {
  int vpnCallIndex = 0;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('wireguard_permission'),
    (call) async {
      if (call.method == 'isVpnActive') {
        if (isVpnActive == null || vpnCallIndex >= isVpnActive.length) {
          return false;
        }
        return isVpnActive[vpnCallIndex++];
      }
      if (call.method == 'request') {
        if (throwTimeout) throw TimeoutException('test timeout');
        if (throwError) throw PlatformException(code: 'ERROR');
        return requestResult;
      }
      return null;
    },
  );
}

void _clearChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('wireguard_permission'),
    null,
  );
}

// Minimal widget host used by testWidgets cases.
class _Host extends StatefulWidget {
  const _Host({required this.child});
  final Widget child;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: Scaffold(body: widget.child));
}

// ── isWireGuardActive ─────────────────────────────────────────────────────────

void main() {
  tearDown(_clearChannel);

  group('isWireGuardActive', () {
    test('returns false on non-Android without touching the channel', () async {
      // No channel mock needed — the guard short-circuits first.
      final result = await isWireGuardActive(isAndroid: _notAndroid);
      expect(result, isFalse);
    });

    test('returns true when channel reports VPN is active', () async {
      _mockChannel(isVpnActive: [true]);
      final result = await isWireGuardActive(isAndroid: _onAndroid);
      expect(result, isTrue);
    });

    test('returns false when channel reports VPN is inactive', () async {
      _mockChannel(isVpnActive: [false]);
      final result = await isWireGuardActive(isAndroid: _onAndroid);
      expect(result, isFalse);
    });

    test('returns false when channel returns null', () async {
      _mockChannel(isVpnActive: [null]);
      final result = await isWireGuardActive(isAndroid: _onAndroid);
      expect(result, isFalse);
    });

    test('returns false on any channel exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('wireguard_permission'),
        (_) async => throw PlatformException(code: 'ERR'),
      );
      final result = await isWireGuardActive(isAndroid: _onAndroid);
      expect(result, isFalse);
    });

    test('real Platform.isAndroid path is reachable (smoke)', () async {
      // Just verifies the function does not throw when no override is provided.
      final result = await isWireGuardActive();
      expect(result, isA<bool>());
    });
  });

  // ── toggleWireGuardTunnel ─────────────────────────────────────────────────

  group('toggleWireGuardTunnel — non-Android', () {
    testWidgets('returns true immediately on non-Android', (tester) async {
      await tester.pumpWidget(const _Host(child: _TriggerButton()));
      await tester.tap(find.byType(_TriggerButton));
      await tester.pump();
      expect(_TriggerButton.lastResult, isTrue);
    });
  });

  group('toggleWireGuardTunnel — Android pre-flight skips broadcast', () {
    testWidgets(
      'goOffline=true and already DOWN returns true without broadcasting',
      (tester) async {
        await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        final result = await toggleWireGuardTunnel(
          goOffline: true,
          context: context,
          isAndroid: _onAndroid,
          vpnActiveCheck: () async => false, // already DOWN
        );

        expect(result, isTrue);
      },
    );

    testWidgets(
      'goOffline=false and already UP returns true without broadcasting',
      (tester) async {
        await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        final result = await toggleWireGuardTunnel(
          goOffline: false,
          context: context,
          isAndroid: _onAndroid,
          vpnActiveCheck: () async => true, // already UP
        );

        expect(result, isTrue);
      },
    );
  });

  group('toggleWireGuardTunnel — permission failures', () {
    testWidgets('permission request timeout returns false and shows snackbar',
        (tester) async {
      await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      final result = await toggleWireGuardTunnel(
        goOffline: true,
        context: context,
        isAndroid: _onAndroid,
        vpnActiveCheck: () async => true, // was UP, need to go DOWN
        permissionRequester: () async => throw TimeoutException('test timeout'),
      );

      expect(result, isFalse);
      await tester.pump();
      expect(find.text('WireGuard permission request timed out — try again'),
          findsOneWidget);
    });

    testWidgets('permission channel error returns false and shows snackbar',
        (tester) async {
      _mockChannel(throwError: true);

      await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      final result = await toggleWireGuardTunnel(
        goOffline: true,
        context: context,
        isAndroid: _onAndroid,
        vpnActiveCheck: () async => true,
      );

      expect(result, isFalse);
      await tester.pump();
      expect(find.textContaining('WireGuard permission check failed'),
          findsOneWidget);
    });

    testWidgets('permission denied returns false and shows snackbar',
        (tester) async {
      _mockChannel(requestResult: false);

      await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
      final context = tester.element(find.byType(SizedBox));

      final result = await toggleWireGuardTunnel(
        goOffline: true,
        context: context,
        isAndroid: _onAndroid,
        vpnActiveCheck: () async => true,
      );

      expect(result, isFalse);
      await tester.pump();
      expect(find.textContaining('Permission denied'), findsOneWidget);
    });
  });

  group('toggleWireGuardTunnel — broadcast and VPN verify', () {
    testWidgets(
      'goOffline=true: broadcast fires and returns true with snackbar',
      (tester) async {
        _mockChannel(requestResult: true);

        await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        var broadcastCalled = false;
        final result = await toggleWireGuardTunnel(
          goOffline: true,
          context: context,
          isAndroid: _onAndroid,
          vpnActiveCheck: () async => true, // was UP
          broadcastFn: () async { broadcastCalled = true; },
        );

        expect(result, isTrue);
        expect(broadcastCalled, isTrue);
        await tester.pump();
        expect(find.textContaining('bringing tunnel'), findsOneWidget);
      },
    );

    testWidgets(
      'goOffline=false: VPN comes up after broadcast returns true',
      (tester) async {
        _mockChannel(requestResult: true);

        await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        // Pre-flight: VPN is DOWN; after broadcast it comes UP.
        int callCount = 0;
        final result = await toggleWireGuardTunnel(
          goOffline: false,
          context: context,
          isAndroid: _onAndroid,
          vpnActiveCheck: () async {
            callCount++;
            return callCount > 1; // first call: false (DOWN); second: true (UP)
          },
          verifyDelay: Duration.zero,
          broadcastFn: () async {},
        );

        expect(result, isTrue);
        await tester.pump();
        expect(find.textContaining('tunnel "$wgTunnelName" is up'), findsOneWidget);
      },
    );

    testWidgets(
      'goOffline=false: VPN does not come up returns false with snackbar',
      (tester) async {
        _mockChannel(requestResult: true);

        await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        final result = await toggleWireGuardTunnel(
          goOffline: false,
          context: context,
          isAndroid: _onAndroid,
          vpnActiveCheck: () async => false, // never comes up
          verifyDelay: Duration.zero,
          broadcastFn: () async {},
        );

        expect(result, isFalse);
        await tester.pump();
        expect(find.textContaining('did not start'), findsOneWidget);
      },
    );

    testWidgets(
      'broadcast throws returns false with snackbar',
      (tester) async {
        _mockChannel(requestResult: true);

        await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        final result = await toggleWireGuardTunnel(
          goOffline: true,
          context: context,
          isAndroid: _onAndroid,
          vpnActiveCheck: () async => true,
          broadcastFn: () async => throw Exception('intent failed'),
        );

        expect(result, isFalse);
        await tester.pump();
        expect(find.textContaining('tunnel control failed'), findsOneWidget);
      },
    );
  });

  group('wgTunnelName constant', () {
    test('is the expected tunnel name', () {
      expect(wgTunnelName, 'k8');
    });
  });
}

// ── minimal widget used by the non-Android smoke test ────────────────────────

class _TriggerButton extends StatefulWidget {
  const _TriggerButton();

  static bool? lastResult;

  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        _TriggerButton.lastResult = await toggleWireGuardTunnel(
          goOffline: true,
          context: context,
          isAndroid: _notAndroid,
        );
      },
      child: const Text('Toggle'),
    );
  }
}
