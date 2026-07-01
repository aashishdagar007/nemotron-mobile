import 'package:flutter/material.dart';

/// Static fields below are kept for legacy direct references,
/// but prefer using `context.colors` (AppColors.of(context)) so the
/// app responds correctly to light/dark mode.
class AppTheme {
  // Colours (dark defaults — legacy/static usage)
  static const bgDeep    = Color(0xFF07090F);
  static const bgMain    = Color(0xFF0D1117);
  static const bgSurface = Color(0xFF131A26);
  static const bgCard    = Color(0xFF1A2336);
  static const accent    = Color(0xFF00C8FF);
  static const accentDim = Color(0x1A00C8FF);
  static const think     = Color(0xFF7C3AED);
  static const thinkDim  = Color(0x1A7C3AED);
  static const textPri   = Color(0xFFF0F6FF);
  static const textSec   = Color(0xFF8B9AB5);
  static const textDim   = Color(0xFF4A5568);
  static const border    = Color(0xFF1E2D42);
  static const success   = Color(0xFF00FF88);
  static const danger    = Color(0xFFFF4757);
  static const userBubble = Color(0xFF0D1F35);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgMain,
    colorScheme: const ColorScheme.dark(
      primary:   accent,
      secondary: think,
      surface:   bgSurface,
      error:     danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDeep,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textPri, fontSize: 16, fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textSec),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgDeep,
      selectedItemColor: accent,
      unselectedItemColor: textDim,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textDim),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textPri, fontSize: 14, height: 1.6),
      bodySmall:  TextStyle(color: textSec, fontSize: 12),
    ),
    dividerColor: border,
    cardColor: bgSurface,
  );

  // ── LIGHT MODE ──────────────────────────────────────────
  static const lBgMain    = Color(0xFFF7F9FC);
  static const lBgDeep    = Color(0xFFFFFFFF);
  static const lBgSurface = Color(0xFFFFFFFF);
  static const lBgCard    = Color(0xFFEFF3F8);
  static const lTextPri   = Color(0xFF101828);
  static const lTextSec   = Color(0xFF5B6678);
  static const lTextDim   = Color(0xFF98A2B3);
  static const lBorder    = Color(0xFFE2E8F0);
  static const lUserBubble = Color(0xFFE6F6FF);

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lBgMain,
    colorScheme: const ColorScheme.light(
      primary:   accent,
      secondary: think,
      surface:   lBgSurface,
      error:     danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lBgDeep,
      elevation: 0,
      titleTextStyle: TextStyle(color: lTextPri, fontSize: 16, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: lTextSec),
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lBgDeep,
      selectedItemColor: accent,
      unselectedItemColor: lTextDim,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lBgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: lTextDim),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: lTextPri, fontSize: 14, height: 1.6),
      bodySmall:  TextStyle(color: lTextSec, fontSize: 12),
    ),
    dividerColor: lBorder,
    cardColor: lBgSurface,
  );
}

/// Resolved palette for the current brightness — use this inside widgets
/// instead of AppTheme.xxx so colors flip correctly in light mode.
class AppColors {
  final Color bgDeep, bgMain, bgSurface, bgCard;
  final Color textPri, textSec, textDim;
  final Color border, userBubble;
  final Color accent, accentDim, think, thinkDim, success, danger;

  const AppColors({
    required this.bgDeep, required this.bgMain, required this.bgSurface,
    required this.bgCard, required this.textPri, required this.textSec,
    required this.textDim, required this.border, required this.userBubble,
    required this.accent, required this.accentDim, required this.think,
    required this.thinkDim, required this.success, required this.danger,
  });

  static AppColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const AppColors(
            bgDeep: AppTheme.bgDeep, bgMain: AppTheme.bgMain, bgSurface: AppTheme.bgSurface,
            bgCard: AppTheme.bgCard, textPri: AppTheme.textPri, textSec: AppTheme.textSec,
            textDim: AppTheme.textDim, border: AppTheme.border, userBubble: AppTheme.userBubble,
            accent: AppTheme.accent, accentDim: AppTheme.accentDim, think: AppTheme.think,
            thinkDim: AppTheme.thinkDim, success: AppTheme.success, danger: AppTheme.danger,
          )
        : const AppColors(
            bgDeep: AppTheme.lBgDeep, bgMain: AppTheme.lBgMain, bgSurface: AppTheme.lBgSurface,
            bgCard: AppTheme.lBgCard, textPri: AppTheme.lTextPri, textSec: AppTheme.lTextSec,
            textDim: AppTheme.lTextDim, border: AppTheme.lBorder, userBubble: AppTheme.lUserBubble,
            accent: AppTheme.accent, accentDim: AppTheme.accentDim, think: AppTheme.think,
            thinkDim: AppTheme.thinkDim, success: AppTheme.success, danger: AppTheme.danger,
          );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => AppColors.of(this);
}
