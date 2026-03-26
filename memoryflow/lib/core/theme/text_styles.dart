import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gradient_themes.dart';

class TextStyles {
  static TextTheme buildTextTheme(GradientThemeData theme) {
    final base =
        (theme.isBright
                ? ThemeData.light(useMaterial3: true)
                : ThemeData.dark(useMaterial3: true))
            .textTheme;
    final serif = GoogleFonts.notoSerifScTextTheme(base);
    final sans = GoogleFonts.notoSansScTextTheme(base);

    return sans.copyWith(
      displayLarge: serif.displayLarge?.copyWith(
        fontSize: 31,
        fontWeight: FontWeight.w700,
        color: theme.textColor,
        height: 1.08,
      ),
      headlineLarge: serif.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: theme.textColor,
        height: 1.14,
      ),
      headlineMedium: serif.headlineMedium?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
      titleLarge: serif.titleLarge?.copyWith(
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
      titleMedium: sans.titleMedium?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: theme.textColor,
      ),
      bodyLarge: sans.bodyLarge?.copyWith(
        fontSize: 14.5,
        height: 1.55,
        color: theme.textColor,
      ),
      bodyMedium: sans.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.55,
        color: theme.secondaryTextColor,
      ),
      bodySmall: sans.bodySmall?.copyWith(
        fontSize: 11,
        height: 1.4,
        color: theme.secondaryTextColor,
      ),
      labelLarge: sans.labelLarge?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: sans.labelMedium?.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: theme.secondaryTextColor,
      ),
      labelSmall: sans.labelSmall?.copyWith(
        fontSize: 9.5,
        fontWeight: FontWeight.w400,
        color: theme.secondaryTextColor,
        letterSpacing: 0.6,
      ),
    );
  }
}
