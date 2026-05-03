import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_mobile/providers/providers.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) _store.remove(key); else _store[key] = value;
  }

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => _store[key];

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => _store.remove(key);
}

ProviderContainer _makeContainer(SharedPreferences prefs) => ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        apiKeyInitialValueProvider.overrideWithValue(''),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForcedOfflineNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = _makeContainer(prefs);
    });

    tearDown(() => container.dispose());

    test('starts as false by default', () {
      expect(container.read(forcedOfflineProvider), false);
    });

    test('toggle() flips false → true', () {
      container.read(forcedOfflineProvider.notifier).toggle();
      expect(container.read(forcedOfflineProvider), true);
    });

    test('toggle() twice restores to false', () {
      container.read(forcedOfflineProvider.notifier).toggle();
      container.read(forcedOfflineProvider.notifier).toggle();
      expect(container.read(forcedOfflineProvider), false);
    });

    test('loads persisted true from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'forced_offline': true});
      final prefs = await SharedPreferences.getInstance();
      final c = _makeContainer(prefs);
      addTearDown(c.dispose);
      expect(c.read(forcedOfflineProvider), true);
    });
  });

  group('TaskSearchVisibleNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = _makeContainer(prefs);
    });

    tearDown(() => container.dispose());

    test('starts as false', () {
      expect(container.read(taskSearchVisibleProvider), false);
    });

    test('toggle() sets true', () {
      container.read(taskSearchVisibleProvider.notifier).toggle();
      expect(container.read(taskSearchVisibleProvider), true);
    });

    test('toggle() twice returns to false', () {
      container.read(taskSearchVisibleProvider.notifier).toggle();
      container.read(taskSearchVisibleProvider.notifier).toggle();
      expect(container.read(taskSearchVisibleProvider), false);
    });

    test('hide() sets false after toggle', () {
      container.read(taskSearchVisibleProvider.notifier).toggle();
      container.read(taskSearchVisibleProvider.notifier).hide();
      expect(container.read(taskSearchVisibleProvider), false);
    });

    test('hide() is idempotent when already false', () {
      container.read(taskSearchVisibleProvider.notifier).hide();
      expect(container.read(taskSearchVisibleProvider), false);
    });
  });

  group('BaseUrlNotifier.set return value', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = _makeContainer(prefs);
    });

    tearDown(() => container.dispose());

    test('returns true for valid https URL', () {
      final ok = container.read(baseUrlProvider.notifier).set('https://api.example.com');
      expect(ok, true);
    });

    test('returns false for http URL', () {
      final ok = container.read(baseUrlProvider.notifier).set('http://api.example.com');
      expect(ok, false);
    });

    test('returns false for empty string', () {
      final ok = container.read(baseUrlProvider.notifier).set('');
      expect(ok, false);
    });

    test('returns false for bare hostname', () {
      final ok = container.read(baseUrlProvider.notifier).set('example.com');
      expect(ok, false);
    });

    test('returns false for ftp scheme', () {
      final ok = container.read(baseUrlProvider.notifier).set('ftp://files.example.com');
      expect(ok, false);
    });

    test('trims leading and trailing whitespace', () {
      container.read(baseUrlProvider.notifier).set('  https://trimmed.example.com  ');
      expect(container.read(baseUrlProvider), 'https://trimmed.example.com');
    });
  });
}
