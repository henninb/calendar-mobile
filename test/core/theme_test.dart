import 'package:calendar_mobile/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group('AppText', () {
    test('heading style uses emphasized title treatment', () {
      expect(AppText.heading.fontSize, 16);
      expect(AppText.heading.fontWeight, FontWeight.w700);
      expect(AppText.heading.color, isNull);
    });

    test('label style uses muted uppercase-friendly treatment', () {
      expect(AppText.label.fontSize, 11);
      expect(AppText.label.fontWeight, FontWeight.w600);
      expect(AppText.label.letterSpacing, 0.8);
      expect(AppText.label.color, isNull);
    });

    test('mono style uses monospace family', () {
      expect(AppText.mono.fontFamily, 'monospace');
      expect(AppText.mono.fontSize, 12);
      expect(AppText.mono.color, isNull);
    });
  });

  group('buildAppTheme', () {
    final theme = buildAppTheme();

    test('uses Material 3 with expected surface colors', () {
      expect(theme.useMaterial3, true);
      expect(theme.scaffoldBackgroundColor, AppColors.light.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.light.surface);
    });

    test('configures app bar styling', () {
      expect(theme.appBarTheme.backgroundColor, AppColors.darkSurface);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 16);
    });

    test('configures bottom navigation styling', () {
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        AppColors.darkSurface,
      );
      expect(theme.bottomNavigationBarTheme.selectedItemColor, Colors.white);
      expect(
        theme.bottomNavigationBarTheme.unselectedItemColor,
        AppColors.light.textMuted,
      );
    });

    test('configures input borders and chip theme', () {
      final enabledBorder =
          theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, AppColors.light.divider);
      expect(theme.chipTheme.backgroundColor, AppColors.light.tableHeader);
      expect(theme.chipTheme.side?.color, AppColors.light.divider);
    });

    test('configures snackbar and floating action button colors', () {
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        AppColors.primary,
      );
      expect(theme.snackBarTheme.backgroundColor, AppColors.darkSurface);
      expect(
        theme.snackBarTheme.contentTextStyle?.color,
        Colors.white,
      );
    });

    test('configures card and divider themes', () {
      expect(theme.cardTheme.color, AppColors.light.surface);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.light.divider);
      expect(theme.dividerTheme.color, AppColors.light.divider);
      expect(theme.dividerTheme.thickness, 0.5);
    });
  });

  group('buildDarkAppTheme', () {
    final theme = buildDarkAppTheme();

    test('uses dark brightness with correct surface colors', () {
      expect(theme.useMaterial3, true);
      expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('configures app bar styling', () {
      expect(theme.appBarTheme.backgroundColor, AppColors.darkSurface);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 16);
    });

    test('configures bottom navigation with dark text muted color', () {
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        AppColors.darkSurface,
      );
      expect(theme.bottomNavigationBarTheme.selectedItemColor, Colors.white);
      expect(
        theme.bottomNavigationBarTheme.unselectedItemColor,
        AppColors.dark.textMuted,
      );
    });

    test('configures card theme with dark surface and divider', () {
      expect(theme.cardTheme.color, AppColors.dark.surface);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.dark.divider);
      expect(theme.dividerTheme.color, AppColors.dark.divider);
    });

    test('configures input borders and chip theme for dark mode', () {
      final enabledBorder =
          theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, AppColors.dark.divider);
      expect(theme.chipTheme.backgroundColor, AppColors.dark.tableHeader);
    });

    test('configures snackbar and FAB colors', () {
      expect(theme.floatingActionButtonTheme.backgroundColor, AppColors.primary);
      expect(theme.snackBarTheme.backgroundColor, AppColors.darkSurface);
    });
  });

  group('AppColors.copyWith', () {
    test('replaces a single color and leaves others unchanged', () {
      const replaced = Color(0xFF112233);
      final copy = AppColors.light.copyWith(background: replaced);
      expect(copy.background, replaced);
      expect(copy.surface, AppColors.light.surface);
      expect(copy.textPrimary, AppColors.light.textPrimary);
    });

    test('replaces multiple colors independently', () {
      const bg = Color(0xFFAABBCC);
      const fg = Color(0xFF001122);
      final copy = AppColors.light.copyWith(background: bg, textPrimary: fg);
      expect(copy.background, bg);
      expect(copy.textPrimary, fg);
      expect(copy.surface, AppColors.light.surface);
    });

    test('with no args preserves all colors', () {
      final copy = AppColors.light.copyWith();
      expect(copy.background, AppColors.light.background);
      expect(copy.overdueBg, AppColors.light.overdueBg);
      expect(copy.pendingFg, AppColors.light.pendingFg);
    });

    test('can override every status color field', () {
      const c = Color(0xFFFF0000);
      final copy = AppColors.dark.copyWith(
        surface: c,
        divider: c,
        dividerLight: c,
        tableHeader: c,
        textSecondary: c,
        textMuted: c,
        textLight: c,
        overdueBg: c,
        overdueFg: c,
        completedBg: c,
        completedFg: c,
        skippedBg: c,
        skippedFg: c,
        warningBg: c,
        warningFg: c,
        offlineBanner: c,
        offlineFg: c,
        pendingBanner: c,
        pendingFg: c,
        pendingBorder: c,
        btnGrayBg: c,
        btnGrayFg: c,
        upcomingBg: c,
        upcomingFg: c,
      );
      expect(copy.surface, c);
      expect(copy.upcomingFg, c);
      expect(copy.background, AppColors.dark.background);
    });
  });

  group('AppColors.lerp', () {
    test('at t=0 returns colors equal to this', () {
      final result = AppColors.light.lerp(AppColors.dark, 0.0);
      expect(result.background, AppColors.light.background);
      expect(result.textPrimary, AppColors.light.textPrimary);
    });

    test('at t=1 returns colors equal to other', () {
      final result = AppColors.light.lerp(AppColors.dark, 1.0);
      expect(result.background, AppColors.dark.background);
      expect(result.textPrimary, AppColors.dark.textPrimary);
    });

    test('at t=0.5 interpolates all fields', () {
      final result = AppColors.light.lerp(AppColors.dark, 0.5);
      expect(
        result.background,
        Color.lerp(AppColors.light.background, AppColors.dark.background, 0.5),
      );
      expect(
        result.overdueBg,
        Color.lerp(AppColors.light.overdueBg, AppColors.dark.overdueBg, 0.5),
      );
      expect(
        result.pendingFg,
        Color.lerp(AppColors.light.pendingFg, AppColors.dark.pendingFg, 0.5),
      );
    });

    test('lerping dark to light at t=0.5 gives same midpoint', () {
      final fwd = AppColors.light.lerp(AppColors.dark, 0.5);
      final rev = AppColors.dark.lerp(AppColors.light, 0.5);
      expect(fwd.background, rev.background);
    });
  });

  group('AppColors.of', () {
    testWidgets('retrieves AppColors extension from nearest Theme', (tester) async {
      AppColors? retrieved;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) {
              retrieved = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.background, AppColors.light.background);
    });

    testWidgets('retrieves dark AppColors when dark theme is active', (tester) async {
      AppColors? retrieved;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDarkAppTheme(),
          home: Builder(
            builder: (context) {
              retrieved = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.background, AppColors.dark.background);
    });
  });
}
