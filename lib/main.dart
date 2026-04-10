import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const secureStorage = FlutterSecureStorage();
  final prefs = await SharedPreferences.getInstance();

  // Read the API key from secure storage, falling back to any legacy
  // plaintext value that may exist from a previous install.
  final legacyKey = prefs.getString(AppConstants.prefApiKey) ?? '';
  final secureKey = await secureStorage.read(key: AppConstants.prefApiKey);
  final initialApiKey = secureKey ?? legacyKey;

  // Migrate: if a legacy plaintext key exists but secure storage is empty,
  // promote it now and erase the plaintext copy.
  if (secureKey == null && legacyKey.isNotEmpty) {
    await secureStorage.write(key: AppConstants.prefApiKey, value: legacyKey);
    await prefs.remove(AppConstants.prefApiKey);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(secureStorage),
        apiKeyInitialValueProvider.overrideWithValue(initialApiKey),
      ],
      child: const CalendarMobileApp(),
    ),
  );
}

class CalendarMobileApp extends StatelessWidget {
  const CalendarMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainScreen(),
    );
  }
}
