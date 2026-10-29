import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B7A2C),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF1B7A2C),
      onPrimary: Colors.white,
      secondary: const Color(0xFF14532D),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF3F3EE),
      onSecondaryContainer: const Color(0xFF14532D),
      surface: Colors.white,
      onSurface: const Color(0xFF1C1C1C),
      onSurfaceVariant: const Color(0xFF616161),
      surfaceContainerLow: const Color(0xFFF3F3EE),
      outline: const Color(0xFFDADDD7),
      outlineVariant: const Color(0xFFE8EAE5),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: colors);
    final textTheme = base.textTheme
        .apply(bodyColor: colors.onSurface, displayColor: colors.secondary)
        .copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        );
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.secondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ).merge(buttonStyle),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
        ).merge(buttonStyle),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          side: BorderSide(color: colors.outlineVariant),
        ).merge(buttonStyle),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
        ).merge(buttonStyle),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }
}
