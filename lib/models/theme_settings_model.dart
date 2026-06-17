// lib/models/theme_settings_model.dart

class ThemeSettings {
  final bool isDarkMode;
  final String primaryColor;
  final String fontSize;
  final bool isCompactMode;
  final String language; // ✅ إضافة اللغة

  ThemeSettings({
    required this.isDarkMode,
    required this.primaryColor,
    required this.fontSize,
    required this.isCompactMode,
    this.language = 'ar', // ✅ اللغة الافتراضية عربي
  });

  factory ThemeSettings.defaultSettings() {
    return ThemeSettings(
      isDarkMode: false,
      primaryColor: 'أزرق',
      fontSize: 'متوسط',
      isCompactMode: false,
      language: 'ar',
    );
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      primaryColor: json['primaryColor'] ?? 'أزرق',
      fontSize: json['fontSize'] ?? 'متوسط',
      isCompactMode: json['isCompactMode'] ?? false,
      language: json['language'] ?? 'ar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'primaryColor': primaryColor,
      'fontSize': fontSize,
      'isCompactMode': isCompactMode,
      'language': language,
    };
  }
}
