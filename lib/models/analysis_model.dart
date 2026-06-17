// lib/models/analysis_model.dart

import 'package:flutter/material.dart';

class AnalysisType {
  final int id;
  final String nameAr;
  final String nameEn;
  final String category;
  final String? description;
  final String? preparationInstructions;
  final String? normalRangeText;
  final String iconCode;

  AnalysisType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    this.description,
    this.preparationInstructions,
    this.normalRangeText,
    this.iconCode = '🔬',
  });

  factory AnalysisType.fromJson(Map<String, dynamic> json) {
    return AnalysisType(
      id: json['id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      category: json['category'],
      description: json['description'],
      preparationInstructions: json['preparation_instructions'],
      normalRangeText: json['normal_range_text'],
      iconCode: json['icon_code'] ?? '🔬',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'category': category,
      'description': description,
      'preparation_instructions': preparationInstructions,
      'normal_range_text': normalRangeText,
      'icon_code': iconCode,
    };
  }
}

class TestIndicator {
  final int id;
  final int analysisTypeId;
  final String nameAr;
  final String nameEn;
  final String? unit;
  final double? normalRangeMin;
  final double? normalRangeMax;
  final double? criticalLow;
  final double? criticalHigh;
  final String genderSpecific;
  final String? ageGroup;
  final int displayOrder;

  TestIndicator({
    required this.id,
    required this.analysisTypeId,
    required this.nameAr,
    required this.nameEn,
    this.unit,
    this.normalRangeMin,
    this.normalRangeMax,
    this.criticalLow,
    this.criticalHigh,
    this.genderSpecific = 'both',
    this.ageGroup,
    this.displayOrder = 0,
  });

  factory TestIndicator.fromJson(Map<String, dynamic> json) {
    return TestIndicator(
      id: json['id'],
      analysisTypeId: json['analysis_type_id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      unit: json['unit'],
      normalRangeMin: json['normal_range_min']?.toDouble(),
      normalRangeMax: json['normal_range_max']?.toDouble(),
      criticalLow: json['critical_low']?.toDouble(),
      criticalHigh: json['critical_high']?.toDouble(),
      genderSpecific: json['gender_specific'] ?? 'both',
      ageGroup: json['age_group'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

class HealthTip {
  final int id;
  final String tipCategory;
  final int? relatedAnalysisTypeId;
  final int? relatedIndicatorId;
  final String conditionType;
  final String severity;
  final String titleAr;
  final String titleEn;
  final String tipTextAr;
  final String tipTextEn;
  final String? recommendationsAr;
  final String? recommendationsEn;
  final String iconCode;
  final int priority;

  HealthTip({
    required this.id,
    required this.tipCategory,
    this.relatedAnalysisTypeId,
    this.relatedIndicatorId,
    this.conditionType = 'always',
    this.severity = 'info',
    required this.titleAr,
    required this.titleEn,
    required this.tipTextAr,
    required this.tipTextEn,
    this.recommendationsAr,
    this.recommendationsEn,
    this.iconCode = '💡',
    this.priority = 0,
  });

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      id: json['id'],
      tipCategory: json['tip_category'],
      relatedAnalysisTypeId: json['related_analysis_type_id'],
      relatedIndicatorId: json['related_indicator_id'],
      conditionType: json['condition_type'] ?? 'always',
      severity: json['severity'] ?? 'info',
      titleAr: json['title_ar'],
      titleEn: json['title_en'],
      tipTextAr: json['tip_text_ar'],
      tipTextEn: json['tip_text_en'],
      recommendationsAr: json['recommendations_ar'],
      recommendationsEn: json['recommendations_en'],
      iconCode: json['icon_code'] ?? '💡',
      priority: json['priority'] ?? 0,
    );
  }
}

class UserAnalysisHistory {
  final int id;
  final int userId;
  final int analysisTypeId;
  final String? fileName;
  final String? filePath;
  final String? extractedText;
  final DateTime analysisDate;
  final String? notes;
  final DateTime createdAt;

  // علاقات
  AnalysisType? analysisType;
  List<UserTestResult>? results;

  UserAnalysisHistory({
    required this.id,
    required this.userId,
    required this.analysisTypeId,
    this.fileName,
    this.filePath,
    this.extractedText,
    required this.analysisDate,
    this.notes,
    required this.createdAt,
    this.analysisType,
    this.results,
  });

  factory UserAnalysisHistory.fromJson(Map<String, dynamic> json) {
    return UserAnalysisHistory(
      id: json['id'],
      userId: json['user_id'],
      analysisTypeId: json['analysis_type_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      extractedText: json['extracted_text'],
      analysisDate: DateTime.parse(json['analysis_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      analysisType: json['analysis_type'] != null
          ? AnalysisType.fromJson(json['analysis_type'])
          : null,
      results: json['results'] != null
          ? (json['results'] as List)
                .map((r) => UserTestResult.fromJson(r))
                .toList()
          : null,
    );
  }
}

class UserTestResult {
  final int id;
  final int historyId;
  final int indicatorId;
  final double value;
  final String? unit;
  final String status;
  final String? notes;
  final DateTime createdAt;

  // علاقات
  TestIndicator? indicator;
  List<HealthTip>? tips;

  UserTestResult({
    required this.id,
    required this.historyId,
    required this.indicatorId,
    required this.value,
    this.unit,
    required this.status,
    this.notes,
    required this.createdAt,
    this.indicator,
    this.tips,
  });

  factory UserTestResult.fromJson(Map<String, dynamic> json) {
    return UserTestResult(
      id: json['id'],
      historyId: json['history_id'],
      indicatorId: json['indicator_id'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      indicator: json['indicator'] != null
          ? TestIndicator.fromJson(json['indicator'])
          : null,
      tips: json['tips'] != null
          ? (json['tips'] as List).map((t) => HealthTip.fromJson(t)).toList()
          : null,
    );
  }

  // الحصول على لون الحالة
  Color getStatusColor() {
    switch (status) {
      case 'normal':
        return Colors.green;
      case 'low':
        return Colors.orange;
      case 'high':
        return Colors.orange;
      case 'critical_low':
        return Colors.red;
      case 'critical_high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // الحصول على نص الحالة بالعربية
  String getStatusText() {
    switch (status) {
      case 'normal':
        return 'طبيعي';
      case 'low':
        return 'منخفض';
      case 'high':
        return 'مرتفع';
      case 'critical_low':
        return 'منخفض خطير';
      case 'critical_high':
        return 'مرتفع خطير';
      default:
        return 'غير معروف';
    }
  }

  // أيقونة الحالة
  IconData getStatusIcon() {
    switch (status) {
      case 'normal':
        return Icons.check_circle;
      case 'low':
        return Icons.arrow_downward;
      case 'high':
        return Icons.arrow_upward;
      case 'critical_low':
        return Icons.warning;
      case 'critical_high':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }
}

class AnalysisResult {
  final String id;
  final DateTime date;
  final String fileName;
  final String fileType;
  final String extractedText;
  final Map<String, dynamic> analysis;
  final List<String> tips;
  final String? imagePath;
  final int? historyId; // معرف في قاعدة البيانات

  AnalysisResult({
    required this.id,
    required this.date,
    required this.fileName,
    required this.fileType,
    required this.extractedText,
    required this.analysis,
    required this.tips,
    this.imagePath,
    this.historyId,
  });

  // تحويل من UserAnalysisHistory إلى AnalysisResult
  factory AnalysisResult.fromHistory(UserAnalysisHistory history) {
    Map<String, dynamic> analysisMap = {
      'type': history.analysisType?.nameAr ?? 'تحليل',
      'patientName': '',
      'date': history.analysisDate.toIso8601String(),
      'results': {},
      'abnormal': [],
    };

    List<String> tipsList = [];

    if (history.results != null) {
      for (var result in history.results!) {
        if (result.indicator != null) {
          analysisMap['results'][result.indicator!.nameAr] = {
            'value': result.value,
            'unit': result.unit ?? result.indicator!.unit,
            'status': result.status,
            'statusText': result.getStatusText(),
            'normal':
                result.indicator!.normalRangeMin != null ||
                    result.indicator!.normalRangeMax != null
                ? '${result.indicator!.normalRangeMin ?? ''} - ${result.indicator!.normalRangeMax ?? ''}'
                : '',
          };
        }

        if (result.status != 'normal' && result.tips != null) {
          for (var tip in result.tips!) {
            tipsList.add(tip.tipTextAr);
          }
        }
      }
    }

    return AnalysisResult(
      id: history.id.toString(),
      date: history.analysisDate,
      fileName: history.fileName ?? 'تحليل طبي',
      fileType: history.fileName?.endsWith('.pdf') == true ? 'pdf' : 'image',
      extractedText: history.extractedText ?? '',
      analysis: analysisMap,
      tips: tipsList.isNotEmpty
          ? tipsList
          : ['جميع النتائج طبيعية - حافظ على نمط حياتك الصحي'],
      imagePath: history.filePath,
      historyId: history.id,
    );
  }
}
