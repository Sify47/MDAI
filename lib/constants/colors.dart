import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية (أزرق + أخضر - هوية التطبيق)
  static const Color primary = Color(0xFF1565C0); // أزرق داكن Material
  static const Color primaryContainer = Color(0xFFD1E4FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001D36);

  static const Color secondary = Color(0xFF00897B); // أخضر مزرق (Teal)
  static const Color secondaryContainer = Color(0xFFB2DFDB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00201E);

  static const Color tertiary = Color(0xFF2E7D32); // أخضر غامق
  static const Color tertiaryContainer = Color(0xFFC8E6C9);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF002106);

  // ألوان الحالات
  static const Color success = Color(0xFF43A047); // أخضر
  static const Color warning = Color(0xFFFFC107); // أصفر
  static const Color danger = Color(0xFFF44336); // أحمر
  static const Color info = Color(0xFF00BCD4); // تركواز

  // ألوان المؤشرات
  static const Color calories = Color(0xFFFF9800); // برتقالي
  static const Color walking = Color(0xFF1565C0); // أزرق
  static const Color medications = Color(0xFF00897B); // أخضر مزرق
  static const Color symptoms = Color(0xFFFF6B6B); // أحمر فاتح
  static const Color nutrition = Color(0xFF43A047); // أخضر

  // ألوان المغذيات (ماكروز)
  static const Color protein = Color(0xFFE53935); // أحمر - بروتين
  static const Color carbs = Color(0xFFFB8C00); // برتقالي - كربوهيدرات
  static const Color fat = Color(0xFF42A5F5); // أزرق - دهون

  // ألوان الخلفية
  static const Color background = Color(0xFFF5F9FF); // خلفية فاتحة مائلة للأزرق
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE3EDF7);
  static const Color cardBackground = Colors.white;

  // ألوان النصوص - Light
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textHint = Color(0xFF79747E);
  static const Color textDisabled = Color(0xFFC4C7C5);

  // ألوان الحدود
  static const Color border = Color(0xFFCAC4D0);
  static const Color divider = Color(0xFFE6E1E5);
  static const Color outline = Color(0xFF79747E);

  // ألوان الحالات
  static const Color takenBg = Color(0xFFE8F5E9); // أخضر فاتح
  static const Color pendingBg = Color(0xFFFFF3E0); // أصفر فاتح
  static const Color missedBg = Color(0xFFFFEBEE); // أحمر فاتح

  // ألوان الشات (محسنة)
  static const Color userMessage = Color(0xFF006C4F); // أخضر داكن
  static const Color userMessageContainer = Color(0xFF8BF0D2);
  static const Color botMessage = Color(0xFF1565C0); // أزرق
  static const Color botMessageContainer = Color(0xFFE3F2FD);
  static const Color botAccent = Color(0xFFE3F2FD); // لمسات البوت

  // ألوان إضافية للدردشة
  static const Color chatBackground = Color(0xFFF5F5F5);
  static const Color chatInputBackground = Color(0xFFFFFFFF);
  static const Color chatBorder = Color(0xFFE0E0E0);

  // ألوان الظلال والتأثيرات
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x66000000);

  // ---- Dark Mode Colors ----
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkCardBackground = Color(0xFF252525);
  static const Color darkScaffold = Color(0xFF121212);

  static const Color darkTextPrimary = Color(0xFFE6E1E5);
  static const Color darkTextSecondary = Color(0xFFCAC4D0);
  static const Color darkTextHint = Color(0xFF938F99);
  static const Color darkTextDisabled = Color(0xFF6A666E);

  static const Color darkBorder = Color(0xFF4A4458);
  static const Color darkDivider = Color(0xFF3A3545);
  static const Color darkOutline = Color(0xFF938F99);

  static const Color darkPrimaryContainer = Color(0xFF004A77);
  static const Color darkSecondaryContainer = Color(0xFF004D40);
  static const Color darkTertiaryContainer = Color(0xFF00391C);

  // ألوان الحالات - Dark
  static const Color darkTakenBg = Color(0xFF1B3A1B);
  static const Color darkPendingBg = Color(0xFF3D2E0E);
  static const Color darkMissedBg = Color(0xFF3E1717);

  // ألوان الشات - Dark
  static const Color darkUserMessage = Color(0xFF00A86B);
  static const Color darkUserMessageContainer = Color(0xFF004D40);
  static const Color darkBotMessage = Color(0xFF64B5F6);
  static const Color darkBotMessageContainer = Color(0xFF002D5A);
  static const Color darkChatBackground = Color(0xFF1A1A2E);
  static const Color darkChatInputBackground = Color(0xFF2C2C2C);
  static const Color darkChatBorder = Color(0xFF3A3A3A);
}

/// ============================================================
/// Unified App Theme — All screens must use these themes
/// ============================================================
class AppTheme {
  /// Light Theme — used in light mode
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: Color(0xFFF9DEDC),
        onErrorContainer: Color(0xFF410E0B),
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
        outlineVariant: AppColors.border,
        shadow: AppColors.shadowLight,
        scrim: AppColors.shadowDark,
        inverseSurface: Color(0xFF322F35),
        onInverseSurface: Color(0xFFF5EFF7),
        inversePrimary: Color(0xFF90CAF9),
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Cairo',

      // ========== UNIFIED APP BAR ==========
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        iconTheme: IconThemeData(color: AppColors.primary, size: 24),
        actionsIconTheme: IconThemeData(
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),

      // ========== BUTTONS ==========
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.shadowMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // ========== INPUTS ==========
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ========== CARDS ==========
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: AppColors.surface,
        surfaceTintColor: AppColors.primaryContainer,
        shadowColor: AppColors.shadowLight,
      ),

      // ========== DIALOGS ==========
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),

      // ========== BOTTOM SHEET ==========
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ========== CHIPS ==========
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onPrimary,
          fontFamily: 'Cairo',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ========== BOTTOM NAVIGATION ==========
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Dark Theme — used in dark mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF90CAF9),
        onPrimary: Color(0xFF003258),
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: Color(0xFFD1E4FF),
        secondary: Color(0xFF80CBC4),
        onSecondary: Color(0xFF003731),
        secondaryContainer: AppColors.darkSecondaryContainer,
        onSecondaryContainer: Color(0xFFB2DFDB),
        tertiary: Color(0xFF81C784),
        onTertiary: Color(0xFF003911),
        tertiaryContainer: AppColors.darkTertiaryContainer,
        onTertiaryContainer: Color(0xFFC8E6C9),
        error: Color(0xFFEF9A9A),
        onError: Color(0xFF601410),
        errorContainer: Color(0xFF8C1D18),
        onErrorContainer: Color(0xFFF9DEDC),
        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceVariant: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkBorder,
        shadow: AppColors.shadowDark,
        scrim: Color(0x99000000),
        inverseSurface: Color(0xFFE6E1E5),
        onInverseSurface: Color(0xFF322F35),
        inversePrimary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.darkScaffold,
      fontFamily: 'Cairo',

      // ========== UNIFIED APP BAR (Dark) ==========
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Color(0xFF90CAF9),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        iconTheme: IconThemeData(color: Color(0xFF90CAF9), size: 24),
        actionsIconTheme: IconThemeData(
          color: AppColors.darkTextSecondary,
          size: 22,
        ),
      ),

      // ========== BUTTONS (Dark) ==========
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: const Color(0xFF003258),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // ========== INPUTS (Dark) ==========
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ========== CARDS (Dark) ==========
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: AppColors.darkCardBackground,
        surfaceTintColor: AppColors.darkPrimaryContainer,
        shadowColor: AppColors.shadowDark,
      ),

      // ========== DIALOGS (Dark) ==========
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.darkPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),

      // ========== BOTTOM SHEET (Dark) ==========
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.darkPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ========== CHIPS (Dark) ==========
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: const Color(0xFF90CAF9),
        labelStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontFamily: 'Cairo',
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF003258),
          fontFamily: 'Cairo',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ========== BOTTOM NAVIGATION (Dark) ==========
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: Color(0xFF90CAF9),
        unselectedItemColor: AppColors.darkTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Chat theme (light) — specialized for chat screens
  static ThemeData get chatTheme {
    final baseTheme = lightTheme;
    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.chatBackground,
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  /// Chat theme (dark) — specialized for chat screens
  static ThemeData get chatDarkTheme {
    final baseTheme = darkTheme;
    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.darkChatBackground,
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
