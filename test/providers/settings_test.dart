import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_mobile/providers/providers.dart';

// Minimal in-memory secure storage fake — no platform channels needed in tests.
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    _store.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BaseUrlNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
          apiKeyInitialValueProvider.overrideWithValue(''),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('rejects http:// URLs', () {
      container.read(baseUrlProvider.notifier).set('http://insecure.example.com');
      // State must not change — http is rejected
      expect(container.read(baseUrlProvider), isNot('http://insecure.example.com'));
    });

    test('rejects empty string — prior valid URL is preserved', () {
      container.read(baseUrlProvider.notifier).set('https://baseline.example.com');
      container.read(baseUrlProvider.notifier).set('');
      expect(container.read(baseUrlProvider), 'https://baseline.example.com');
    });

    test('rejects bare hostname without scheme — prior valid URL is preserved', () {
      container.read(baseUrlProvider.notifier).set('https://baseline.example.com');
      container.read(baseUrlProvider.notifier).set('example.com');
      expect(container.read(baseUrlProvider), 'https://baseline.example.com');
    });

    test('accepts https:// URL and persists it', () {
      const url = 'https://api.example.com';
      container.read(baseUrlProvider.notifier).set(url);
      expect(container.read(baseUrlProvider), url);
    });

    test('successive valid sets update state', () {
      container.read(baseUrlProvider.notifier).set('https://first.example.com');
      container.read(baseUrlProvider.notifier).set('https://second.example.com');
      expect(container.read(baseUrlProvider), 'https://second.example.com');
    });
  });

  group('ApiKeyNotifier', () {
    test('initialises from the eagerly-loaded value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
          apiKeyInitialValueProvider.overrideWithValue('pre-loaded-key'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(apiKeyProvider), 'pre-loaded-key');
    });

    test('set() updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = _FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(storage),
          apiKeyInitialValueProvider.overrideWithValue(''),
        ],
      );
      addTearDown(container.dispose);

      await container.read(apiKeyProvider.notifier).set('new-key');
      expect(container.read(apiKeyProvider), 'new-key');
    });
  });
}
