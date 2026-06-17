import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../models/theme_settings_model.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal() {
    _loadSettings();
  }

  late ThemeSettings _settings;
  static const String _prefsKey = 'theme_settings';

  // Getters
  ThemeSettings get settings => _settings;

  bool get isDarkMode => _settings.isDarkMode;
  String get language => _settings.language; // ✅ إضافة اللغة

  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_prefsKey);

      if (settingsJson != null) {
        Map<String, dynamic> json = {};
        try {
          String cleanString = settingsJson
              .replaceAll('{', '')
              .replaceAll('}', '');
          List<String> pairs = cleanString.split(', ');

          for (String pair in pairs) {
            List<String> keyValue = pair.split(': ');
            if (keyValue.length == 2) {
              String key = keyValue[0];
              String value = keyValue[1];

              if (value == 'true')
                json[key] = true;
              else if (value == 'false')
                json[key] = false;
              else
                json[key] = value.replaceAll("'", "");
            }
          }
        } catch (e) {
          print('خطأ في تحويل JSON: $e');
        }

        _settings = ThemeSettings.fromJson(json);
      } else {
        _settings = ThemeSettings.defaultSettings();
      }
    } catch (e) {
      print('خطأ في تحميل الإعدادات: $e');
      _settings = ThemeSettings.defaultSettings();
    }
    notifyListeners();
  }

  // حفظ الإعدادات
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String settingsJson = _settings.toJson().toString();
      await prefs.setString(_prefsKey, settingsJson);
    } catch (e) {
      print('خطأ في حفظ الإعدادات: $e');
    }
  }

  // ✅ تحديث الإعدادات (مبسط: فقط الوضع الليلي واللغة)
  Future<void> updateSettings({bool? isDarkMode, String? language}) async {
    _settings = ThemeSettings(
      isDarkMode: isDarkMode ?? _settings.isDarkMode,
      primaryColor: _settings.primaryColor, // يبقى أزرق افتراضي
      fontSize: _settings.fontSize, // يبقى متوسط افتراضي
      isCompactMode: _settings.isCompactMode, // يبقى false افتراضي
      language: language ?? _settings.language,
    );

    await _saveSettings();
    notifyListeners();
  }

  // الحصول على اللون الأساسي (أزرق ثابت)
  Color getCurrentPrimaryColor() {
    return AppColors.primary;
  }

  // الحصول على حجم الخط (متوسط ثابت)
  double getCurrentFontSize() {
    return 14;
  }

  // الحصول على خلفية البطاقة
  Color getCardBackgroundColor() {
    return _settings.isDarkMode ? Colors.grey[900]! : Colors.white;
  }

  // الحصول على لون النص
  Color getTextColor() {
    return _settings.isDarkMode ? Colors.white : AppColors.textPrimary;
  }

  // الحصول على لون النص الثانوي
  Color getSecondaryTextColor() {
    return _settings.isDarkMode ? Colors.grey[400]! : AppColors.textSecondary;
  }

  // الحصول على لون الخلفية
  Color getBackgroundColor() {
    return _settings.isDarkMode
        ? const Color(0xFF1A1A1A)
        : AppColors.background;
  }
}
