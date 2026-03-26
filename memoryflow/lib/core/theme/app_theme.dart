import 'package:flutter/material.dart';

import 'gradient_themes.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData buildTheme(GradientThemeData theme) {
    final textTheme = TextStyles.buildTextTheme(theme);
    final brightness = theme.isBright ? Brightness.light : Brightness.dark;
    final colorScheme = theme.isBright
        ? ColorScheme.light(
            primary: theme.accentColor,
            secondary: theme.glowColor,
            surface: Colors.white.withValues(alpha: 0.45),
            onPrimary: Colors.white,
            onSurface: theme.textColor,
          )
        : ColorScheme.dark(
            primary: theme.accentColor,
            secondary: theme.glowColor,
            surface: Colors.white.withValues(alpha: 0.08),
            onPrimary: theme.shadowColor,
            onSurface: theme.textColor,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: colorScheme,
      textTheme: textTheme,
      dividerColor: Colors.white.withValues(alpha: theme.isBright ? 0.22 : 0.1),
      iconTheme: IconThemeData(color: theme.textColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.isBright
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.7),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: theme.textColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: theme.secondaryTextColor,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: theme.isBright ? 0.24 : 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: theme.isBright ? 0.3 : 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: theme.isBright ? 0.3 : 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: theme.accentColor.withValues(alpha: 0.7),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.accentColor,
        selectionColor: theme.accentColor.withValues(alpha: 0.28),
        selectionHandleColor: theme.accentColor,
      ),
    );
  }
}
