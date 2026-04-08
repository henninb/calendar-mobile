import 'package:flutter/material.dart';

// ── Color tokens (mirrored from index.css) ──────────────────────────────────

class AppColors {
  AppColors._();

  static const Color background   = Color(0xFFF1F5F9);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color darkSurface  = Color(0xFF1E293B); // nav / header bg
  static const Color hover        = Color(0xFF334155);
  static const Color divider      = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color tableHeader  = Color(0xFFF8FAFC);

  static const Color primary      = Color(0xFF3B82F6);
  static const Color primaryDark  = Color(0xFF2563EB);
  static const Color primaryDeep  = Color(0xFF1D4ED8);

  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textLight     = Color(0xFFCBD5E1);

  // Status
  static const Color upcomingBg   = Color(0xFFDBEAFE);
  static const Color upcomingFg   = Color(0xFF1D4ED8);
  static const Color overdueBg    = Color(0xFFFEE2E2);
  static const Color overdueFg    = Color(0xFFB91C1C);
  static const Color completedBg  = Color(0xFFDCFCE7);
  static const Color completedFg  = Color(0xFF15803D);
  static const Color skippedBg    = Color(0xFFF1F5F9);
  static const Color skippedFg    = Color(0xFF64748B);

  // Buttons
  static const Color btnGreen  = Color(0xFF22C55E);
  static const Color btnBlue   = Color(0xFF3B82F6);
  static const Color btnRed    = Color(0xFFEF4444);
  static const Color btnGrayBg = Color(0xFFE2E8F0);
  static const Color btnGrayFg = Color(0xFF475569);

  // Priority
  static const Color priorityHigh   = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow    = Color(0xFF64748B);

  // Credit cards
  static const Color ccOverdue = Color(0xFFDC2626);
  static const Color ccSoon    = Color(0xFFD97706);

  // Offline / sync
  static const Color offlineBanner = Color(0xFFFEF3C7);
  static const Color offlineFg     = Color(0xFF92400E);
  static const Color pendingBanner = Color(0xFFEFF6FF);
  static const Color pendingFg     = Color(0xFF1E40AF);
}

// ── Text styles ──────────────────────────────────────────────────────────────

class AppText {
  AppText._();

  static const TextStyle heading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    color: AppColors.textSecondary,
  );
}

// ── Theme ────────────────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: Colors.white,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: AppColors.divider, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 0.5,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: AppText.small,
      hintStyle: AppText.small.copyWith(color: AppColors.textLight),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.tableHeader,
      labelStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      side: BorderSide(color: AppColors.divider),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
