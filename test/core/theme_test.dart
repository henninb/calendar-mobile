import 'package:calendar_mobile/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppText', () {
    test('heading style uses emphasized title treatment', () {
      expect(AppText.heading.fontSize, 16);
      expect(AppText.heading.fontWeight, FontWeight.w700);
      expect(AppText.heading.color, AppColors.textPrimary);
    });

    test('label style uses muted uppercase-friendly treatment', () {
      expect(AppText.label.fontSize, 11);
      expect(AppText.label.fontWeight, FontWeight.w600);
      expect(AppText.label.letterSpacing, 0.8);
      expect(AppText.label.color, AppColors.textMuted);
    });

    test('mono style uses monospace family', () {
      expect(AppText.mono.fontFamily, 'monospace');
      expect(AppText.mono.fontSize, 12);
      expect(AppText.mono.color, AppColors.textSecondary);
    });
  });

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

    test('configures card and divider themes', () {
      expect(theme.cardTheme.color, AppColors.surface);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.divider);
      expect(theme.dividerTheme.color, AppColors.divider);
      expect(theme.dividerTheme.thickness, 0.5);
    });
  });
}
