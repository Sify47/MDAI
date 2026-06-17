// lib/utils/prefs_helper.dart

import 'dart:convert';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/models/user_model.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static final PrefsHelper _instance = PrefsHelper._internal();
  factory PrefsHelper() => _instance;
  PrefsHelper._internal();

  static late SharedPreferences _prefs;

  // مفاتيح التخزين الأساسية
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsFirstTimeUser = 'is_first_time_user';

  // مفاتيح بيانات المستخدم
  static const String _keyUserData = 'user_data';
  static const String _keyUserId = 'user_id';
  static const String _keyUserToken = 'user_token';
  static const String _keyRefreshToken = 'refresh_token';

  // مفاتيح بيانات المستخدم الأساسية
  static const String _keyWeight = 'weight';
  static const String _keyHeight = 'height';
  static const String _keyAge = 'age';
  static const String _keyGender = 'gender';
  static const String _keyGoal = 'goal';
  static const String _keyActivityLevel = 'activity_level';
  static const String _keyWeightLossRate = 'weight_loss_rate';
  static const String _keyTargetWeight = 'target_weight';
  static const String _keyDiseases = 'diseases';
  static const String _keyTargetCalories = 'target_calories';
  static const String _keyBMR = 'bmr';
  static const String _keyTDEE = 'tdee';
  static const String _keyDailyStepsGoal = 'daily_steps_goal';

  // مفاتيح ساعات الهدوء
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String _keyQuietStartHour = 'quiet_start_hour';
  static const String _keyQuietStartMinute = 'quiet_start_minute';
  static const String _keyQuietEndHour = 'quiet_end_hour';
  static const String _keyQuietEndMinute = 'quiet_end_minute';

  // مفاتيح الإشعارات والتنظيف
  static const String _keyLastCleanupDate = 'last_cleanup_date';
  static const String _notificationPrefix = 'notif_';

  // مفاتيح البيانات اليومية
  static const String _keyTodaySteps = 'today_steps_';
  static const String _keyTodayMeals = 'today_meals_';
  static const String _keyTodaySymptoms = 'today_symptoms_';
  static const String _keyTodayWater = 'today_water_';

  // ============================================
  // ✅ التهيئة
  // ============================================
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print('✅ PrefsHelper initialized');
  }

  // ============================================
  // ✅ دوال المستخدم (User model)
  // ============================================
  static Future<void> saveUser(User user) async {
    final userJson = json.encode(user.toJson());
    await _prefs.setString(_keyUserData, userJson);
    await _prefs.setInt(_keyUserId, user.id);
    await _prefs.setString(_keyUserToken, user.token ?? '');
    await _prefs.setString(_keyRefreshToken, user.refreshToken ?? '');

    NutritionService.setUserId(user.id);
    print('✅ تم حفظ بيانات المستخدم: ${user.name}');
  }

  static Future<User?> getUser() async {
    final userJson = _prefs.getString(_keyUserData);
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = json.decode(userJson);
        return User.fromJson(userMap);
      } catch (e) {
        print('❌ خطأ في قراءة بيانات المستخدم: $e');
        return null;
      }
    }
    return null;
  }

  static String? getToken() {
    final token = _prefs.getString(_keyUserToken);
    return token;
  }

  static String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  static int? getUserId() {
    return _prefs.getInt(_keyUserId);
  }

  static Future<void> setUserId(int userId) async {
    await _prefs.setInt(_keyUserId, userId);
    print('📝 [PrefsHelper] setUserId: $userId');
  }

  static Future<void> setToken(String token) async {
    await _prefs.setString(_keyUserToken, token);
  }

  static Future<void> setRefreshToken(String token) async {
    await _prefs.setString(_keyRefreshToken, token);
  }

  static Future<void> saveUserNutritionData(UserNutritionData data) async {
    await _prefs.setString('nutrition_data', json.encode(data.toJson()));
  }

  // ============================================
  // ✅ تسجيل الخروج - مسح كل بيانات المستخدم
  // ============================================
  static Future<void> logout() async {
    print('\n🗑️ [PrefsHelper] بدء تسجيل الخروج ومسح البيانات...');

    // 1. مسح بيانات المستخدم (User model)
    await _prefs.remove(_keyUserData);
    await _prefs.remove(_keyUserToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserId);

    // 2. مسح بيانات المستخدم الأساسية
    await _prefs.remove(_keyWeight);
    await _prefs.remove(_keyHeight);
    await _prefs.remove(_keyAge);
    await _prefs.remove(_keyGender);
    await _prefs.remove(_keyGoal);
    await _prefs.remove(_keyActivityLevel);
    await _prefs.remove(_keyWeightLossRate);
    await _prefs.remove(_keyTargetWeight);
    await _prefs.remove(_keyDiseases);
    await _prefs.remove(_keyTargetCalories);
    await _prefs.remove(_keyBMR);
    await _prefs.remove(_keyTDEE);
    await _prefs.remove(_keyDailyStepsGoal);

    // 3. مسح البيانات اليومية (جميع الأيام)
    final allKeys = _prefs.getKeys();
    int deletedCount = 0;

    for (var key in allKeys) {
      // مسح بيانات الخطوات لجميع الأيام
      if (key.startsWith(_keyTodaySteps)) {
        await _prefs.remove(key);
        deletedCount++;
      }
      // مسح بيانات الوجبات لجميع الأيام
      if (key.startsWith(_keyTodayMeals)) {
        await _prefs.remove(key);
        deletedCount++;
      }
      // مسح بيانات الأعراض لجميع الأيام
      if (key.startsWith(_keyTodaySymptoms)) {
        await _prefs.remove(key);
        deletedCount++;
      }
      // مسح بيانات الماء لجميع الأيام
      if (key.startsWith(_keyTodayWater)) {
        await _prefs.remove(key);
        deletedCount++;
      }
      // مسح بيانات الإشعارات
      if (key.startsWith(_notificationPrefix)) {
        await _prefs.remove(key);
        deletedCount++;
      }
    }

    // 4. مسح بيانات الإشعارات العامة
    await _prefs.remove(_keyLastCleanupDate);

    // 5. تحديث حالة تسجيل الدخول
    await _prefs.setBool(_keyIsLoggedIn, false);

    print('✅ [PrefsHelper] تم تسجيل الخروج ومسح $deletedCount مفتاح');
    print('🗑️ [PrefsHelper] انتهى مسح البيانات');
  }

  // ============================================
  // ✅ دوال حالة التطبيق
  // ============================================
  static bool get isFirstLaunch {
    return _prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_keyIsFirstLaunch, value);
    print('📝 setFirstLaunch: $value');
  }

  static bool get isLoggedIn {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
    print('📝 setLoggedIn: $value');
  }

  static bool get isFirstTimeUser {
    return _prefs.getBool(_keyIsFirstTimeUser) ?? true;
  }

  static Future<void> setFirstTimeUser(bool value) async {
    await _prefs.setBool(_keyIsFirstTimeUser, value);
    print('📝 setFirstTimeUser: $value');
  }

  // ============================================
  // ✅ دوال ساعات الهدوء (Quiet Hours)
  // ============================================
  static Future<void> setQuietHoursEnabled(bool enabled) async {
    await _prefs.setBool(_keyQuietHoursEnabled, enabled);
    print('📝 [PrefsHelper] Quiet Hours enabled: $enabled');
  }

  static bool getQuietHoursEnabled() {
    return _prefs.getBool(_keyQuietHoursEnabled) ?? false;
  }

  static Future<void> setQuietStartTime(int hour, int minute) async {
    await _prefs.setInt(_keyQuietStartHour, hour);
    await _prefs.setInt(_keyQuietStartMinute, minute);
    print('📝 [PrefsHelper] Quiet Hours start: $hour:$minute');
  }

  static Future<void> setQuietEndTime(int hour, int minute) async {
    await _prefs.setInt(_keyQuietEndHour, hour);
    await _prefs.setInt(_keyQuietEndMinute, minute);
    print('📝 [PrefsHelper] Quiet Hours end: $hour:$minute');
  }

  static (int hour, int minute) getQuietStartTime() {
    return (
      _prefs.getInt(_keyQuietStartHour) ?? 19, // 7 مساءً (19:00)
      _prefs.getInt(_keyQuietStartMinute) ?? 0,
    );
  }

  static (int hour, int minute) getQuietEndTime() {
    return (
      _prefs.getInt(_keyQuietEndHour) ?? 7, // 7 صباحاً
      _prefs.getInt(_keyQuietEndMinute) ?? 0,
    );
  }

  static bool isInQuietHours(DateTime time) {
    if (!getQuietHoursEnabled()) return false;

    final (startHour, startMinute) = getQuietStartTime();
    final (endHour, endMinute) = getQuietEndTime();

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes <= endMinutes) {
      // نفس اليوم
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // عبر منتصف الليل
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  static DateTime adjustToSafeTime(DateTime originalTime) {
    if (!isInQuietHours(originalTime)) {
      return originalTime;
    }

    final (endHour, endMinute) = getQuietEndTime();

    DateTime adjustedTime = DateTime(
      originalTime.year,
      originalTime.month,
      originalTime.day,
      endHour,
      endMinute,
    );

    if (adjustedTime.isBefore(DateTime.now())) {
      adjustedTime = adjustedTime.add(const Duration(days: 1));
    }

    print(
      '🔄 [PrefsHelper] تم تعديل وقت الإشعار من $originalTime إلى $adjustedTime',
    );
    return adjustedTime;
  }

  // ============================================
  // ✅ دوال الإشعارات
  // ============================================
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  static Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<void> clearNotificationKeys() async {
    final keys = _prefs.getKeys();
    int deletedCount = 0;
    for (var key in keys) {
      if (key.startsWith(_notificationPrefix)) {
        await _prefs.remove(key);
        deletedCount++;
      }
    }
    print('✅ تم مسح $deletedCount مفتاح إشعارات');
  }

  static Future<void> setLastCleanupDate(DateTime date) async {
    await _prefs.setString(_keyLastCleanupDate, date.toIso8601String());
    print('✅ تم حفظ تاريخ آخر تنظيف: ${date.toIso8601String()}');
  }

  static Future<DateTime?> getLastCleanupDate() async {
    final dateStr = _prefs.getString(_keyLastCleanupDate);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // ============================================
  // ✅ حساب هدف المشي اليومي
  // ============================================
  static int _calculateDailyStepsGoal({
    required double weight,
    required String goal,
    required String activityLevel,
    required List<String> diseases,
  }) {
    int baseSteps = 5000;

    switch (goal) {
      case 'تخسيس':
        baseSteps = 8000;
        break;
      case 'تثبيت':
        baseSteps = 6000;
        break;
      case 'زيادة':
        baseSteps = 4000;
        break;
    }

    if (weight > 100) {
      baseSteps += 2000;
    } else if (weight > 80) {
      baseSteps += 1000;
    } else if (weight < 50) {
      baseSteps -= 500;
    }

    switch (activityLevel) {
      case 'قليل':
        baseSteps -= 1000;
        break;
      case 'عالي':
        baseSteps += 2000;
        break;
      case 'مكثف':
        baseSteps += 3000;
        break;
    }

    if (diseases.contains('السكري')) {
      baseSteps += 1000;
    }

    if (diseases.contains('القلب')) {
      baseSteps = (baseSteps * 0.8).round();
    }

    return baseSteps.clamp(3000, 15000);
  }

  // ============================================
  // ✅ حفظ بيانات المستخدم الأساسية
  // ============================================
  /// Reads `camelCase` key first, falls back to `snake_case` for compatibility.
  static T _val<T>(Map<String, dynamic> data, String camelKey, String snakeKey, T defaultValue) {
    return (data[camelKey] ?? data[snakeKey] ?? defaultValue) as T;
  }

  static Future<void> saveUserData(Map<String, dynamic> data) async {
    await _prefs.setDouble(_keyWeight, _val<double>(data, 'weight', 'weight', 70.0));
    await _prefs.setDouble(_keyHeight, _val<double>(data, 'height', 'height', 170.0));
    await _prefs.setInt(_keyAge, _val<int>(data, 'age', 'age', 30));
    await _prefs.setString(_keyGender, _val<String>(data, 'gender', 'gender', 'ذكر'));
    await _prefs.setString(_keyGoal, _val<String>(data, 'goal', 'goal', 'تخسيس'));
    await _prefs.setString(_keyActivityLevel, _val<String>(data, 'activityLevel', 'activity_level', 'متوسط'));
    await _prefs.setString(_keyWeightLossRate, _val<String>(data, 'weightLossRate', 'weight_loss_rate', '0.5'));
    await _prefs.setDouble(_keyTargetWeight, _val<double>(data, 'targetWeight', 'target_weight', 70.0));
    await _prefs.setStringList(
      _keyDiseases,
      List<String>.from(_val<List>(data, 'diseases', 'diseases', [])),
    );
    await _prefs.setDouble(
      _keyTargetCalories,
      _val<double>(data, 'targetCalories', 'target_calories', 2000.0),
    );
    await _prefs.setDouble(_keyBMR, _val<double>(data, 'bmr', 'bmr', 1500.0));
    await _prefs.setDouble(_keyTDEE, _val<double>(data, 'tdee', 'tdee', 2000.0));

    // Read with snake_case fallback for calculate too
    final activityLevel = _val<String>(data, 'activityLevel', 'activity_level', 'متوسط');
    final diseases = _val<List>(data, 'diseases', 'diseases', []);

    int dailyStepsGoal = _calculateDailyStepsGoal(
      weight: _val<double>(data, 'weight', 'weight', 70.0),
      goal: _val<String>(data, 'goal', 'goal', 'تخسيس'),
      activityLevel: activityLevel,
      diseases: List<String>.from(diseases),
    );

    await _prefs.setInt(_keyDailyStepsGoal, dailyStepsGoal);
    print('✅ تم حفظ بيانات المستخدم، هدف المشي: $dailyStepsGoal خطوة');
  }

  // ============================================
  // ✅ جلب بيانات المستخدم الأساسية
  // ============================================
  static Map<String, dynamic> getUserData() {
    return {
      'weight': _prefs.getDouble(_keyWeight) ?? 70.0,
      'height': _prefs.getDouble(_keyHeight) ?? 170.0,
      'age': _prefs.getInt(_keyAge) ?? 30,
      'gender': _prefs.getString(_keyGender) ?? 'ذكر',
      'goal': _prefs.getString(_keyGoal) ?? 'تخسيس',
      'activityLevel': _prefs.getString(_keyActivityLevel) ?? 'متوسط',
      'weightLossRate': _prefs.getString(_keyWeightLossRate) ?? '0.5',
      'targetWeight': _prefs.getDouble(_keyTargetWeight) ?? 70.0,
      'diseases': _prefs.getStringList(_keyDiseases) ?? [],
      'targetCalories': _prefs.getDouble(_keyTargetCalories) ?? 2000.0,
      'bmr': _prefs.getDouble(_keyBMR) ?? 1500.0,
      'tdee': _prefs.getDouble(_keyTDEE) ?? 2000.0,
      'dailyStepsGoal': _prefs.getInt(_keyDailyStepsGoal) ?? 8000,
    };
  }

  // ============================================
  // ✅ تحديث بيانات محددة
  // ============================================
  static Future<void> updateWeight(double newWeight) async {
    await _prefs.setDouble(_keyWeight, newWeight);
    final data = getUserData();
    int newGoal = _calculateDailyStepsGoal(
      weight: newWeight,
      goal: data['goal'],
      activityLevel: data['activityLevel'],
      diseases: data['diseases'],
    );
    await _prefs.setInt(_keyDailyStepsGoal, newGoal);
    print('✅ تم تحديث الوزن إلى $newWeight كجم، هدف المشي الجديد: $newGoal');
  }

  static Future<void> updateGoal(String newGoal) async {
    await _prefs.setString(_keyGoal, newGoal);
    final data = getUserData();
    int newGoalValue = _calculateDailyStepsGoal(
      weight: data['weight'],
      goal: newGoal,
      activityLevel: data['activityLevel'],
      diseases: data['diseases'],
    );
    await _prefs.setInt(_keyDailyStepsGoal, newGoalValue);
    print('✅ تم تحديث الهدف إلى $newGoal، هدف المشي الجديد: $newGoalValue');
  }

  // ============================================
  // ✅ البيانات اليومية
  // ============================================
  static String _getTodayKey() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  // الخطوات
  static Future<void> saveTodaySteps(int steps) async {
    String key = '$_keyTodaySteps${_getTodayKey()}';
    await _prefs.setInt(key, steps);
  }

  static int getTodaySteps() {
    String key = '$_keyTodaySteps${_getTodayKey()}';
    return _prefs.getInt(key) ?? 0;
  }

  // الوجبات
  static Future<void> saveTodayMeals(List<Map<String, dynamic>> meals) async {
    String key = '$_keyTodayMeals${_getTodayKey()}';
    String mealsJson = json.encode(meals);
    await _prefs.setString(key, mealsJson);
  }

  static List<Map<String, dynamic>> getTodayMeals() {
    String key = '$_keyTodayMeals${_getTodayKey()}';
    String? data = _prefs.getString(key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ خطأ في قراءة الوجبات: $e');
      return [];
    }
  }

  // الأعراض
  static Future<void> saveTodaySymptoms(
    List<Map<String, dynamic>> symptoms,
  ) async {
    String key = '$_keyTodaySymptoms${_getTodayKey()}';
    String symptomsJson = json.encode(symptoms);
    await _prefs.setString(key, symptomsJson);
  }

  static List<Map<String, dynamic>> getTodaySymptoms() {
    String key = '$_keyTodaySymptoms${_getTodayKey()}';
    String? data = _prefs.getString(key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ خطأ في قراءة الأعراض: $e');
      return [];
    }
  }

  // الماء
  static Future<void> addWaterIntake(double amount) async {
    String key = '$_keyTodayWater${_getTodayKey()}';
    double current = _prefs.getDouble(key) ?? 0.0;
    await _prefs.setDouble(key, current + amount);
  }

  static double getTodayWater() {
    String key = '$_keyTodayWater${_getTodayKey()}';
    return _prefs.getDouble(key) ?? 0.0;
  }

  static Future<void> resetTodayWater() async {
    String key = '$_keyTodayWater${_getTodayKey()}';
    await _prefs.remove(key);
  }

  // ============================================
  // ✅ مسح كل البيانات
  // ============================================
  static Future<void> clearAll() async {
    await _prefs.clear();
    print('📝 clearAll: تم مسح كل البيانات');
  }

  // ============================================
  // ✅ عرض كل القيم (للت Debug)
  // ============================================
  static void printAllPrefs() {
    print('\n📊 ==== PrefsHelper Debug ====');
    print('isFirstLaunch: $isFirstLaunch');
    print('isLoggedIn: $isLoggedIn');
    print('isFirstTimeUser: $isFirstTimeUser');

    print('\n👤 بيانات المستخدم (User model):');
    final userId = getUserId();
    final token = getToken();
    print('   user_id: $userId');
    print(
      '   token: ${token != null ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'null'}',
    );

    final data = getUserData();
    print('\n📊 بيانات المستخدم الأساسية:');
    data.forEach((key, value) {
      print('   $key: $value');
    });

    print('\n📅 بيانات اليوم:');
    print('   steps: ${getTodaySteps()}');
    print('   water: ${getTodayWater()}L');
    print('   meals: ${getTodayMeals().length} وجبات');
    print('   symptoms: ${getTodaySymptoms().length} أعراض');

    print('\n🔔 بيانات الإشعارات:');
    print('   lastCleanupDate: ${getLastCleanupDate()}');
    print('📊 ==========================\n');
  }
}
