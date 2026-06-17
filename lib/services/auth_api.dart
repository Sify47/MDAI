// lib/services/auth_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/prefs_helper.dart';
import '../services/base_api_service.dart';

class AuthService {
  static const String _pathPrefix = 'api/auth';

  // ============================================
  // ✅ 1. تسجيل الدخول (يستخدم form-urlencoded - خاص)
  // ============================================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('\n🟡 [AuthService] تسجيل الدخول');
    print('📧 البريد: $email');

    try {
      final url = BaseApiService.getFullUrl('$_pathPrefix/login');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // حفظ التوكنات
        await PrefsHelper.setToken(data['access_token']);
        await PrefsHelper.setRefreshToken(data['refresh_token']);
        await PrefsHelper.setLoggedIn(true);

        return {
          'success': true,
          'message': 'تم تسجيل الدخول بنجاح',
          'data': data,
        };
      } else {
        String errorMessage = 'فشل في تسجيل الدخول';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }

  // ============================================
  // ✅ 2. إنشاء حساب جديد
  // ============================================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required DateTime birthDate,
    required String gender,
  }) async {
    print('\n🟡 [AuthService] إنشاء حساب جديد');
    print('📧 البريد: $email');

    try {
      final birthDateStr =
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';

      final response = await BaseApiService.post(
        '$_pathPrefix/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone.isEmpty ? null : phone,
          'birth_date': birthDateStr,
          'gender': gender,
        },
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        // حفظ التوكنات
        await PrefsHelper.setToken(data['access_token']);
        await PrefsHelper.setRefreshToken(data['refresh_token']);
        await PrefsHelper.setLoggedIn(true);

        return {
          'success': true,
          'message': 'تم إنشاء الحساب بنجاح',
          'data': data,
        };
      } else {
        String errorMessage = 'فشل في إنشاء الحساب';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }

  // ============================================
  // ✅ 3. تسجيل الخروج (محسن)
  // ============================================
  static Future<Map<String, dynamic>> logout() async {
    print('\n🟡 [AuthService] تسجيل الخروج');

    try {
      await BaseApiService.post('$_pathPrefix/logout');

      // ✅ مسح جميع البيانات المحلية بغض النظر عن استجابة السيرفر
      await PrefsHelper.logout();

      print('✅ [AuthService] تم تسجيل الخروج بنجاح من السيرفر والمحلي');
      return {'success': true, 'message': 'تم تسجيل الخروج بنجاح'};
    } catch (e) {
      print('❌ [AuthService] خطأ في الاتصال: $e');
      // ✅ حتى لو فشل الاتصال بالسيرفر، امسح البيانات محلياً
      await PrefsHelper.logout();
      return {'success': true, 'message': 'تم تسجيل الخروج محلياً'};
    }
  }

  // ============================================
  // ✅ 4. الحصول على المستخدم الحالي
  // ============================================
  static Future<Map<String, dynamic>> getCurrentUser() async {
    print('\n🟡 [AuthService] جلب المستخدم الحالي');

    try {
      final response = await BaseApiService.get('$_pathPrefix/me');
      final data = json.decode(response.body);
      return {'success': true, 'data': data};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }

  // ============================================
  // ✅ 5. تحديث التوكن
  // ============================================
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    print('\n🟡 [AuthService] تحديث التوكن');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/refresh',
        body: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // حفظ التوكن الجديد
        await PrefsHelper.setToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await PrefsHelper.setRefreshToken(data['refresh_token']);
        }

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'فشل في تحديث التوكن'};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }
}
