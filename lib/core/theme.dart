import 'package:flutter/material.dart';

// ── Adaptive color palette ────────────────────────────────────────────────────

/// Theme extension that carries every color token that differs between
/// light and dark mode.  Access via [AppColors.of].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.divider,
    required this.dividerLight,
    required this.tableHeader,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textLight,
    required this.overdueBg,
    required this.overdueFg,
    required this.completedBg,
    required this.completedFg,
    required this.skippedBg,
    required this.skippedFg,
    required this.warningBg,
    required this.warningFg,
    required this.offlineBanner,
    required this.offlineFg,
    required this.pendingBanner,
    required this.pendingFg,
    required this.pendingBorder,
    required this.btnGrayBg,
    required this.btnGrayFg,
    required this.upcomingBg,
    required this.upcomingFg,
  });

  // ── Adaptive fields ────────────────────────────────────────────────────────

  final Color background;
  final Color surface;
  final Color divider;
  final Color dividerLight;
  final Color tableHeader;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textLight;
  final Color overdueBg;
  final Color overdueFg;
  final Color completedBg;
  final Color completedFg;
  final Color skippedBg;
  final Color skippedFg;
  final Color warningBg;
  final Color warningFg;
  final Color offlineBanner;
  final Color offlineFg;
  final Color pendingBanner;
  final Color pendingFg;
  final Color pendingBorder;
  final Color btnGrayBg;
  final Color btnGrayFg;
  final Color upcomingBg;
  final Color upcomingFg;

  // ── Invariant colors (same in both modes) ─────────────────────────────────

  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryDeep = Color(0xFF1D4ED8);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color hover = Color(0xFF334155);
  static const Color btnGreen = Color(0xFF22C55E);
  static const Color btnBlue = Color(0xFF3B82F6);
  static const Color btnRed = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF64748B);
  static const Color ccOverdue = Color(0xFFDC2626);
  static const Color ccSoon = Color(0xFFD97706);

  // ── Presets ────────────────────────────────────────────────────────────────

  static const AppColors light = AppColors(
    background: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    divider: Color(0xFFE2E8F0),
    dividerLight: Color(0xFFF1F5F9),
    tableHeader: Color(0xFFF8FAFC),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textLight: Color(0xFFCBD5E1),
    overdueBg: Color(0xFFFEE2E2),
    overdueFg: Color(0xFFB91C1C),
    completedBg: Color(0xFFDCFCE7),
    completedFg: Color(0xFF15803D),
    skippedBg: Color(0xFFF1F5F9),
    skippedFg: Color(0xFF64748B),
    warningBg: Color(0xFFFEF3C7),
    warningFg: Color(0xFFD97706),
    offlineBanner: Color(0xFFFEF3C7),
    offlineFg: Color(0xFF92400E),
    pendingBanner: Color(0xFFEFF6FF),
    pendingFg: Color(0xFF1E40AF),
    pendingBorder: Color(0xFFBFDBFE),
    btnGrayBg: Color(0xFFE2E8F0),
    btnGrayFg: Color(0xFF475569),
    upcomingBg: Color(0xFFDBEAFE),
    upcomingFg: Color(0xFF1D4ED8),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    divider: Color(0xFF334155),
    dividerLight: Color(0xFF1E293B),
    tableHeader: Color(0xFF1E293B),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textLight: Color(0xFF475569),
    overdueBg: Color(0x26DC2626),
    overdueFg: Color(0xFFFCA5A5),
    completedBg: Color(0x3315803D),
    completedFg: Color(0xFF86EFAC),
    skippedBg: Color(0xFF334155),
    skippedFg: Color(0xFF94A3B8),
    warningBg: Color(0x1AFBBF24),
    warningFg: Color(0xFFFDE68A),
    offlineBanner: Color(0x1AFBBF24),
    offlineFg: Color(0xFFFDE68A),
    pendingBanner: Color(0x331D4ED8),
    pendingFg: Color(0xFF93C5FD),
    pendingBorder: Color(0x661D4ED8),
    btnGrayBg: Color(0xFF334155),
    btnGrayFg: Color(0xFF94A3B8),
    upcomingBg: Color(0x331D4ED8),
    upcomingFg: Color(0xFF93C5FD),
  );

  // ── ThemeExtension API ─────────────────────────────────────────────────────

  /// Retrieves [AppColors] from the nearest [Theme].
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? divider,
    Color? dividerLight,
    Color? tableHeader,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textLight,
    Color? overdueBg,
    Color? overdueFg,
    Color? completedBg,
    Color? completedFg,
    Color? skippedBg,
    Color? skippedFg,
    Color? warningBg,
    Color? warningFg,
    Color? offlineBanner,
    Color? offlineFg,
    Color? pendingBanner,
    Color? pendingFg,
    Color? pendingBorder,
    Color? btnGrayBg,
    Color? btnGrayFg,
    Color? upcomingBg,
    Color? upcomingFg,
  }) =>
      AppColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        divider: divider ?? this.divider,
        dividerLight: dividerLight ?? this.dividerLight,
        tableHeader: tableHeader ?? this.tableHeader,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        textLight: textLight ?? this.textLight,
        overdueBg: overdueBg ?? this.overdueBg,
        overdueFg: overdueFg ?? this.overdueFg,
        completedBg: completedBg ?? this.completedBg,
        completedFg: completedFg ?? this.completedFg,
        skippedBg: skippedBg ?? this.skippedBg,
        skippedFg: skippedFg ?? this.skippedFg,
        warningBg: warningBg ?? this.warningBg,
        warningFg: warningFg ?? this.warningFg,
        offlineBanner: offlineBanner ?? this.offlineBanner,
        offlineFg: offlineFg ?? this.offlineFg,
        pendingBanner: pendingBanner ?? this.pendingBanner,
        pendingFg: pendingFg ?? this.pendingFg,
        pendingBorder: pendingBorder ?? this.pendingBorder,
        btnGrayBg: btnGrayBg ?? this.btnGrayBg,
        btnGrayFg: btnGrayFg ?? this.btnGrayFg,
        upcomingBg: upcomingBg ?? this.upcomingBg,
        upcomingFg: upcomingFg ?? this.upcomingFg,
      );

  @override
  AppColors lerp(AppColors other, double t) => AppColors(
        background: Color.lerp(background, other.background, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        divider: Color.lerp(divider, other.divider, t)!,
        dividerLight: Color.lerp(dividerLight, other.dividerLight, t)!,
        tableHeader: Color.lerp(tableHeader, other.tableHeader, t)!,
        textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
        textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
        textMuted: Color.lerp(textMuted, other.textMuted, t)!,
        textLight: Color.lerp(textLight, other.textLight, t)!,
        overdueBg: Color.lerp(overdueBg, other.overdueBg, t)!,
        overdueFg: Color.lerp(overdueFg, other.overdueFg, t)!,
        completedBg: Color.lerp(completedBg, other.completedBg, t)!,
        completedFg: Color.lerp(completedFg, other.completedFg, t)!,
        skippedBg: Color.lerp(skippedBg, other.skippedBg, t)!,
        skippedFg: Color.lerp(skippedFg, other.skippedFg, t)!,
        warningBg: Color.lerp(warningBg, other.warningBg, t)!,
        warningFg: Color.lerp(warningFg, other.warningFg, t)!,
        offlineBanner: Color.lerp(offlineBanner, other.offlineBanner, t)!,
        offlineFg: Color.lerp(offlineFg, other.offlineFg, t)!,
        pendingBanner: Color.lerp(pendingBanner, other.pendingBanner, t)!,
        pendingFg: Color.lerp(pendingFg, other.pendingFg, t)!,
        pendingBorder: Color.lerp(pendingBorder, other.pendingBorder, t)!,
        btnGrayBg: Color.lerp(btnGrayBg, other.btnGrayBg, t)!,
        btnGrayFg: Color.lerp(btnGrayFg, other.btnGrayFg, t)!,
        upcomingBg: Color.lerp(upcomingBg, other.upcomingBg, t)!,
        upcomingFg: Color.lerp(upcomingFg, other.upcomingFg, t)!,
      );
}

// ── Text styles (color-free; theme drives default text color) ─────────────────

/// Base text styles.  Colors are intentionally absent so that [DefaultTextStyle]
/// (driven by the active [ThemeData]) supplies the appropriate light/dark color.
/// Use `AppColors.of(context).textMuted` etc. when a specific semantic color is
/// required beyond the default.
abstract final class AppText {

  static const TextStyle heading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(fontSize: 14);

  static const TextStyle small = TextStyle(fontSize: 12);

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
  );
}

// ── Themes ────────────────────────────────────────────────────────────────────

/// Light [ThemeData] wired with [AppColors.light].
ThemeData buildAppTheme() => _build(
      brightness: Brightness.light,
      scheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1E293B),
        surfaceContainerHighest: Color(0xFFF1F5F9),
      ),
      colors: AppColors.light,
    );

/// Dark [ThemeData] wired with [AppColors.dark].
ThemeData buildDarkAppTheme() => _build(
      brightness: Brightness.dark,
      scheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: Color(0xFF1E293B),
        onSurface: Color(0xFFE2E8F0),
        surfaceContainerHighest: Color(0xFF0F172A),
      ),
      colors: AppColors.dark,
    );

ThemeData _build({
  required Brightness brightness,
  required ColorScheme scheme,
  required AppColors colors,
}) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    extensions: [colors],
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
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: Colors.white,
      unselectedItemColor: colors.textMuted,
      selectedLabelStyle:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: colors.divider, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: colors.divider,
      thickness: 0.5,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: colors.textMuted,
      ),
      hintStyle: TextStyle(
        fontSize: 12,
        color: isDark ? colors.textLight : colors.textLight,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.tableHeader,
      labelStyle: TextStyle(fontSize: 12, color: colors.textSecondary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      side: BorderSide(color: colors.divider),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
