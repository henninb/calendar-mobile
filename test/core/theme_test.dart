import 'package:calendar_mobile/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAppTheme', () {
    final theme = buildAppTheme();

    test('uses Material 3 with expected surface colors', () {
      expect(theme.useMaterial3, true);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.surface);
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
        AppColors.textMuted,
      );
    });

    test('configures input borders and chip theme', () {
      final enabledBorder =
          theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, AppColors.divider);
      expect(theme.chipTheme.backgroundColor, AppColors.tableHeader);
      expect(theme.chipTheme.side?.color, AppColors.divider);
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
  });
}
