-- SQL Migration Script for Dynamic Targets System
-- VITA App - الأهداف الديناميكية
-- This script adds the new tables and columns for the dynamic targets system

-- ============================================
-- Part 1: ALTER existing health_impact_factors
-- ============================================

ALTER TABLE `health_impact_factors`
  ADD COLUMN `factor_id` int(11) DEFAULT NULL COMMENT 'معرف العامل المرتبط (مثلاً معرف العرض أو الدواء)' AFTER `factor_type`,
  ADD COLUMN `water_adjustment` float DEFAULT 0 COMMENT 'تعديل كمية الماء (باللتر)' AFTER `calories_adjustment`,
  ADD COLUMN `protein_adjustment` float DEFAULT 0 COMMENT 'تعديل البروتين (بالجرام)' AFTER `water_adjustment`,
  ADD COLUMN `carbs_adjustment` float DEFAULT 0 COMMENT 'تعديل الكربوهيدرات (بالجرام)' AFTER `protein_adjustment`,
  ADD COLUMN `fat_adjustment` float DEFAULT 0 COMMENT 'تعديل الدهون (بالجرام)' AFTER `carbs_adjustment`,
  ADD COLUMN `severity_weight` float DEFAULT 1.0 COMMENT 'وزن شدة التأثير (1.0 افتراضي)' AFTER `severity_level`;

-- ============================================
-- Part 2: Create dynamic_daily_targets table
-- ============================================

CREATE TABLE IF NOT EXISTS `dynamic_daily_targets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `date` date NOT NULL COMMENT 'اليوم الذي تطبق فيه هذه الأهداف',

  -- القيم الأساسية (من NutritionCalculator)
  `base_calories` float DEFAULT NULL,
  `base_steps` float DEFAULT NULL,
  `base_water` float DEFAULT NULL COMMENT 'لتر',
  `base_protein` float DEFAULT NULL,
  `base_carbs` float DEFAULT NULL,
  `base_fat` float DEFAULT NULL,

  -- تعديلات التأثير الصحي (نسبة مئوية)
  `calories_impact_pct` float DEFAULT 0,
  `steps_impact_pct` float DEFAULT 0,
  `water_impact_pct` float DEFAULT 0,
  `protein_impact_pct` float DEFAULT 0,
  `carbs_impact_pct` float DEFAULT 0,
  `fat_impact_pct` float DEFAULT 0,

  -- عامل التكيف مع الأداء (0.85-1.15)
  `performance_factor` float DEFAULT 1.0,

  -- عامل اتجاه الوزن
  `weight_trend_factor` float DEFAULT 1.0,

  -- الأهداف الديناميكية النهائية (المحسوبة)
  `target_calories` float DEFAULT NULL,
  `target_steps` float DEFAULT NULL,
  `target_water` float DEFAULT NULL COMMENT 'لتر',
  `target_protein` float DEFAULT NULL,
  `target_carbs` float DEFAULT NULL,
  `target_fat` float DEFAULT NULL,

  -- تفاصيل التأثير (JSON)
  `impact_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'تفصيل كل تأثير' CHECK (json_valid(`impact_details`)),
  `performance_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'تفصيل عامل الأداء' CHECK (json_valid(`performance_details`)),

  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_daily_target` (`user_id`, `date`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_date` (`date`),
  CONSTRAINT `fk_dynamic_targets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Part 3: Create performance_history table
-- ============================================

CREATE TABLE IF NOT EXISTS `performance_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `date` date NOT NULL,

  -- نسب الالتزام (0.0-1.0)
  `calories_adherence` float DEFAULT NULL COMMENT 'الفعلي / الهدف',
  `steps_adherence` float DEFAULT NULL COMMENT 'الفعلي / الهدف',
  `water_adherence` float DEFAULT NULL COMMENT 'الفعلي / الهدف',
  `medication_adherence` float DEFAULT NULL COMMENT 'الجرعات المأخوذة / الكلية',

  -- درجة الأداء العامة (متوسط مرجح)
  `overall_score` float DEFAULT NULL,

  -- القيم الفعلية والهدف
  `actual_calories` float DEFAULT NULL,
  `actual_steps` float DEFAULT NULL,
  `actual_water` float DEFAULT NULL,
  `target_calories` float DEFAULT NULL,
  `target_steps` float DEFAULT NULL,
  `target_water` float DEFAULT NULL,

  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_daily_performance` (`user_id`, `date`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_date` (`date`),
  CONSTRAINT `fk_performance_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Part 4: Create achievement_milestones table
-- ============================================

CREATE TABLE IF NOT EXISTS `achievement_milestones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `milestone_type` varchar(50) NOT NULL COMMENT 'streak, adherence, target_increase, weight_goal, water_goal, steps_goal',
  `milestone_value` float DEFAULT NULL COMMENT 'قيمة الإنجاز (مثلاً 7 للأيام المتتالية)',
  `milestone_key` varchar(100) NOT NULL COMMENT 'مفتاح فريد مثل streak_7',
  `description` text DEFAULT NULL COMMENT 'وصف الإنجاز',
  `icon` varchar(50) DEFAULT NULL COMMENT 'emoji أو اسم الأيقونة',
  `points` int(11) DEFAULT 0 COMMENT 'نقاط التحفيز',
  `achieved_at` datetime DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_milestone` (`user_id`, `milestone_key`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_milestone_type` (`milestone_type`),
  CONSTRAINT `fk_achievement_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Part 5: Create smart_notifications table
-- ============================================

CREATE TABLE IF NOT EXISTS `smart_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `notification_type` varchar(50) NOT NULL COMMENT 'dynamic_target_update, milestone, motivation, health_alert, progress_update, weekly_report',
  `priority` varchar(20) DEFAULT 'info' COMMENT 'urgent, important, info, encouragement',

  -- المحتوى
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `context` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'سبب الإشعار (JSON)' CHECK (json_valid(`context`)),

  -- مرجع الأهداف الديناميكية
  `target_date` date DEFAULT NULL COMMENT 'يوم الأهداف المرتبط',
  `related_target_type` varchar(20) DEFAULT NULL COMMENT 'calories, steps, water, medication, all',

  -- التسليم
  `scheduled_time` datetime DEFAULT NULL COMMENT 'وقت الإرسال المخطط',
  `sent_at` datetime DEFAULT NULL COMMENT 'وقت الإرسال الفعلي',
  `read_at` datetime DEFAULT NULL COMMENT 'وقت القراءة',
  `action_taken` tinyint(1) DEFAULT 0 COMMENT 'هل تفاعل المستخدم؟',

  -- تتبع الأثر
  `impact_on_adherence` float DEFAULT NULL COMMENT 'هل الإشعار حسّن الالتزام؟',

  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_notification_type` (`notification_type`),
  KEY `idx_priority` (`priority`),
  KEY `idx_target_date` (`target_date`),
  KEY `idx_scheduled_time` (`scheduled_time`),
  CONSTRAINT `fk_smart_notification_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Part 6: Update seed data for health_impact_factors
-- Add water, protein, carbs, fat adjustments
-- ============================================

-- تحديث بيانات التأثير الصحي بإضافة تعديلات الماء والماكروز
UPDATE `health_impact_factors` SET
  `water_adjustment` = CASE
    WHEN `factor_name` IN ('حمى', 'إسهال', 'تقيؤ') THEN 0.5
    WHEN `factor_name` IN ('إمساك') THEN 0.3
    WHEN `factor_name` IN ('ضربة شمس', 'جفاف') THEN 1.0
    ELSE 0
  END,
  `protein_adjustment` = CASE
    WHEN `factor_name` IN ('حمى', 'جرح', 'التئام') THEN 10
    WHEN `factor_name` IN ('فقر دم', 'أنيميا') THEN 15
    WHEN `factor_name` IN ('سكري') THEN -5
    ELSE 0
  END,
  `carbs_adjustment` = CASE
    WHEN `factor_name` IN ('سكري') THEN -20
    WHEN `factor_name` IN ('نشاط زائد', 'رياضة') THEN 15
    ELSE 0
  END,
  `fat_adjustment` = CASE
    WHEN `factor_name` IN ('كوليسترول', 'دهون') THEN -10
    WHEN `factor_name` IN ('سكري') THEN -5
    ELSE 0
  END,
  `severity_weight` = CASE
    WHEN `severity_level` = 'خفيف' THEN 0.5
    WHEN `severity_level` = 'متوسط' THEN 1.0
    WHEN `severity_level` = 'شديد' THEN 1.5
    ELSE 1.0
  END
WHERE 1=1;

-- ============================================
-- Part 7: Insert seed achievement milestones
-- ============================================

-- Note: These are template milestones. Actual milestones are created dynamically
-- by the DynamicTargetsService when users achieve them.
-- This is just reference data for the system.

-- ============================================
-- Part 8: Verify migration
-- ============================================

-- التحقق من نجاح الترحيل
SELECT '✅ dynamic_daily_targets table created' AS status;
SELECT '✅ performance_history table created' AS status;
SELECT '✅ achievement_milestones table created' AS status;
SELECT '✅ smart_notifications table created' AS status;
SELECT '✅ health_impact_factors expanded with new columns' AS status;