import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:calendar_mobile/providers/providers.dart';
import 'package:calendar_mobile/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late ProviderContainer container;
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() async {
    mockConnectivity = MockConnectivity();
    connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    
    when(() => mockConnectivity.onConnectivityChanged).thenAnswer((_) => connectivityController.stream);
    when(() => mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        connectivityInstanceProvider.overrideWithValue(mockConnectivity),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    connectivityController.close();
  });

  test('initial state is based on checkConnectivity', () async {
    // Wait for _init to complete
    await Future.delayed(const Duration(milliseconds: 50));
    expect(container.read(isOnlineProvider), isTrue);
  });

  test('state updates when connectivity changes', () async {
    container.read(isOnlineProvider); // trigger _init() so it subscribes before stream emits
    await Future.delayed(const Duration(milliseconds: 50));

    connectivityController.add([ConnectivityResult.none]);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(container.read(isOnlineProvider), isFalse);

    connectivityController.add([ConnectivityResult.mobile]);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(container.read(isOnlineProvider), isTrue);
  });

  test('state is False when forcedOffline is True', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    container.read(forcedOfflineProvider.notifier).toggle(); // set to true
    expect(container.read(isOnlineProvider), isFalse);

    connectivityController.add([ConnectivityResult.wifi]);
    await Future.delayed(const Duration(milliseconds: 50));
    // Still false because forcedOffline is true
    expect(container.read(isOnlineProvider), isFalse);
  });
}
