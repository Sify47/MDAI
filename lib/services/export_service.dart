// lib/services/export_service.dart
// 📤 خدمة تصدير البيانات - Data Export Service

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vita/utils/prefs_helper.dart';
import '../services/base_api_service.dart';

class ExportService {
  // static const String baseUrl = 'http://65.75.201.173:8000';
  // static const String baseUrl = 'http://10.0.2.2:8000'; // للأندرويد
  static const String _pathPrefix = 'api/export';
  static int get _userId => PrefsHelper.getUserId() ?? 1;

  // ============================================
  // ✅ تصدير CSV
  // ============================================
  static Future<String?> exportCsv() async {
    print('\n📤 [ExportService] تصدير CSV');

    try {
      final response = await BaseApiService.get('/$_pathPrefix/csv/$_userId');
      print('📤 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/health_data_export.csv');
        await file.writeAsString(response.body);
        print('✅ تم تصدير CSV إلى: ${file.path}');
        return file.path;
      }
      print('❌ فشل تصدير CSV: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ خطأ في تصدير CSV: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تصدير JSON
  // ============================================
  static Future<String?> exportJson() async {
    print('\n📤 [ExportService] تصدير JSON');

    try {
      final response = await BaseApiService.get('/$_pathPrefix/json/$_userId');
      print('📤 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/health_data_export.json');
        await file.writeAsString(response.body);
        print('✅ تم تصدير JSON إلى: ${file.path}');
        return file.path;
      }
      print('❌ فشل تصدير JSON: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ خطأ في تصدير JSON: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تصدير PDF
  // ============================================
  static Future<String?> exportPdf() async {
    print('\n📤 [ExportService] تصدير PDF');

    try {
      final response = await BaseApiService.get('/$_pathPrefix/pdf/$_userId');
      print('📤 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/health_report.pdf');
        await file.writeAsBytes(response.bodyBytes);
        print('✅ تم تصدير PDF إلى: ${file.path}');
        return file.path;
      }
      print('❌ فشل تصدير PDF: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ خطأ في تصدير PDF: $e');
      return null;
    }
  }

  // ============================================
  // ✅ معلومات التصدير المتاحة
  // ============================================
  static Future<Map<String, dynamic>?> getExportInfo() async {
    print('\n📤 [ExportService] جلب معلومات التصدير');

    try {
      final jsonData = await BaseApiService.getCached(
        '/$_pathPrefix/available/$_userId',
        cacheKey: '${_pathPrefix}_available_$_userId',
        ttl: const Duration(minutes: 10),
      );
      print('✅ تم جلب معلومات التصدير');
      return jsonData;
    } catch (e) {
      print('❌ خطأ في جلب معلومات التصدير: $e');
      return null;
    }
  }

  /// مسح ذاكرة التخزين المؤقت للتصدير
  static void clearCache() {
    BaseApiService.invalidateCache(_pathPrefix);
  }
}
