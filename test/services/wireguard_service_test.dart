import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/services/wireguard_service.dart';

void main() {
  group('isWireGuardActive (non-Android)', () {
    test('returns false immediately on non-Android platforms', () async {
      if (Platform.isAndroid) return;

      final result = await isWireGuardActive();
      expect(result, isFalse);
    });
  });

  group('toggleWireGuardTunnel (non-Android)', () {
    testWidgets(
      'returns true without calling WireGuard on non-Android platforms — goOffline: true',
      (tester) async {
        if (Platform.isAndroid) return;

        await tester.pumpWidget(
          const _TestApp(child: _ToggleButton(goOffline: true)),
        );
        await tester.tap(find.byType(_ToggleButton));
        await tester.pump();

        expect(_ToggleButton.lastResult, isTrue);
      },
    );

    testWidgets(
      'returns true without calling WireGuard on non-Android platforms — goOffline: false',
      (tester) async {
        if (Platform.isAndroid) return;

        await tester.pumpWidget(
          const _TestApp(child: _ToggleButton(goOffline: false)),
        );
        await tester.tap(find.byType(_ToggleButton));
        await tester.pump();

        expect(_ToggleButton.lastResult, isTrue);
      },
    );
  });

  group('wgTunnelName', () {
    test('constant is the expected tunnel name', () {
      expect(wgTunnelName, 'k8');
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: Scaffold(body: child));
}

class _ToggleButton extends StatefulWidget {
  const _ToggleButton({required this.goOffline});
  final bool goOffline;

  static bool? lastResult;

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        _ToggleButton.lastResult = await toggleWireGuardTunnel(
          goOffline: widget.goOffline,
          context: context,
        );
      },
      child: const Text('Toggle'),
    );
  }
}
