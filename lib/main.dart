import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
