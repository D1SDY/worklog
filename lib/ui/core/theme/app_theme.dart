import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Assembles [ThemeData] from [AppColors] and friends.
///
/// The design is dark-first (📐 UI Component Rules). A light theme and the
/// system/light/dark toggle belong to WORLOG-007 — this story ships dark only.
abstract final class AppTheme {
  /// Inter for UI text; JetBrains Mono is applied per-widget via [numeric].
  static TextTheme textTheme() {
    return GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  /// JetBrains Mono, for every numeric value: weights, reps, stats, axis
  /// labels, prices, dates rendered as numbers.
  static TextStyle numeric([TextStyle? style]) {
    return GoogleFonts.jetBrainsMono(textStyle: style);
  }

  static ThemeData dark() {
    final TextTheme text = textTheme();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: text,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentBlue,
        surface: AppColors.bgPrimary,
        surfaceContainer: AppColors.bgSecondary,
        error: AppColors.accentRed,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.bottomNavHeight,
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        // The rules page distinguishes tabs by colour only — no Material 3
        // indicator pill.
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          return IconThemeData(
            size: AppSizes.navIcon,
            color: states.contains(WidgetState.selected)
                ? AppColors.accentBlue
                : AppColors.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          return (text.labelMedium ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.accentBlue
                : AppColors.textMuted,
          );
        }),
      ),
    );
  }
}
