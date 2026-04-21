import 'package:flutter/material.dart';
import 'package:optica_sana/flutter_services/app_settings.dart';

/// Centralized color constants for semantic use across all screens.
///
/// Color roles:
///  - [label]         → field labels / section headers (soft light-blue)
///  - [displayValue]  → read-only / non-user-input data shown to the user (white)
///  - [inputValue]    → values the user actively types / edits (warm amber-yellow)
class AppColors {
  AppColors._();

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgMid = Color(0xFF152B42);

  // ── Accent / Primary ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4FC3F7); // light sky-blue
  static const Color primaryDeep = Color(0xFF0D3158); // deep navy-blue

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF152030);
  static const Color surfaceVariant = Color(0xFF1A2B3F);

  // ── Semantic text colors ───────────────────────────────────────────────────
  static const Color label = Color(0xFF90CAF9); // soft blue for labels
  static const Color displayValue = Color(
    0xFFFFFFFF,
  ); // white for read-only values
  static const Color inputValue = Color(
    0xFFFFD54F,
  ); // warm amber for user-typed values

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderDefault = Color(0xFF2A4A6A);
  static const Color borderFocused = Color(0xFF4FC3F7);
  static const Color borderDisabled = Color(0xFF1E3A52);
  static const Color tableBorder = Color(0xFF1E3E5E);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF5350);

  // ── Semantic state colors ─────────────────────────────────────────────────
  static const Color success = Color(0xFF66BB6A); // saved / confirmed
  static const Color accentTeal = Color(
    0xFF26C6DA,
  ); // section title accent (keratometry, identity)
  static const Color accentIndigo = Color(
    0xFF7986CB,
  ); // section title accent (prescription, address)
  static const Color accentOrange = Color(
    0xFFFF8A65,
  ); // section title accent (lens prescription)

  // ── Table row tints (R eye / L eye) ───────────────────────────────────────
  static const Color rowR = Color(
    0x0C4FC3F7,
  ); // faint sky-blue — right eye rows
  static const Color rowL = Color(0x0C4CAF50); // faint green    — left eye rows

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDark, bgMid],
  );

  // Richer deep-indigo → teal (was flat navy → blue)
  static const LinearGradient navHeaderGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF283593), Color(0xFF00838F)],
  );
}

class AppTheme {
  static final ThemeData themeData = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: Color(0xFF29B6F6),
      onPrimary: Color(0xFF0D1B2A),
      onSecondary: Color(0xFF0D1B2A),
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.displayValue,
      onError: Colors.white,
    ),

    // ── AppBar ───────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A1628),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.primary),
      actionsIconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),

    // ── Text ─────────────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      // Used for field labels and section headers
      labelLarge: TextStyle(
        color: AppColors.label,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      // Used for read-only display values
      bodyLarge: TextStyle(
        color: AppColors.displayValue,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(color: AppColors.displayValue, fontSize: 14),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: AppColors.primary,
      ),
      titleLarge: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: AppColors.label,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),

    // ── Input fields ─────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(
          color: AppColors.borderFocused,
          width: 2.0,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(
          color: AppColors.borderDisabled,
          width: 0.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      labelStyle: const TextStyle(
        color: AppColors.label,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: AppColors.label.withValues(alpha: 0.45)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),

    // ── Buttons ───────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF0D1B2A),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 2,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Color(0xFF0D1B2A),
      elevation: 4,
    ),

    // ── Lists ─────────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      textColor: AppColors.displayValue,
      iconColor: AppColors.primary,
      tileColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // ── Misc ──────────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDefault,
      thickness: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.borderDefault;
      }),
      checkColor: WidgetStateProperty.all(const Color(0xFF0D1B2A)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceVariant,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    iconTheme: const IconThemeData(color: AppColors.primary),
  );
}

/// Text styles that depend on user-tweakable settings (e.g. font size
/// chosen via the Settings screen).
///
/// Use [AppTextStyles.input] for free-form TEXT FIELDS outside of tables
/// (customer forms, notes, solution, examiner, etc.). Table cells should
/// keep their local `TextStyle(color: AppColors.inputValue, ...)` with a
/// fixed implicit size so layouts stay stable.
class AppTextStyles {
  AppTextStyles._();

  /// Amber "user-typed value" style, sized by [AppSettings.inputFontSize].
  static TextStyle input({FontWeight weight = FontWeight.w600}) {
    return TextStyle(
      color: AppColors.inputValue,
      fontWeight: weight,
      fontSize: AppSettings.instance.inputFontSize,
    );
  }

  /// White "read-only display value" style, sized by
  /// [AppSettings.inputFontSize] so that values the user has already entered
  /// remain easy on the eyes when viewing saved records.
  static TextStyle display({FontWeight weight = FontWeight.normal}) {
    return TextStyle(
      color: AppColors.displayValue,
      fontWeight: weight,
      fontSize: AppSettings.instance.inputFontSize,
    );
  }
}
