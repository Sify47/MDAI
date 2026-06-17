// lib/utils/shared_prefs_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();
  factory SharedPrefsHelper() => _instance;
  SharedPrefsHelper._internal();

  static late SharedPreferences _prefs;

  // تهيئة SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // حفظ String
  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  // الحصول على String
  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // حفظ Boolean
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  // الحصول على Boolean
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // حفظ int
  static Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  // الحصول على int
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // حفظ double
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  // الحصول على double
  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // حفظ List<String>
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  // الحصول على List<String>
  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // حذف مفتاح
  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // مسح الكل
  static Future<bool> clear() async {
    return await _prefs.clear();
  }

  // ✅ الحصول على جميع المفاتيح (للت Debug)
  static Set<String> getKeys() {
    return _prefs.getKeys();
  }
}
