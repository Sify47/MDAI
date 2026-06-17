# backend/services/dynamic_targets_service.py

import json
import logging
from datetime import datetime, date, timedelta
from typing import List, Dict, Any, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
import numpy as np

from database import get_db
import models
from ult.nutrition_calculator import NutritionCalculator

logger = logging.getLogger(__name__)


class DynamicTargetsService:
    """خدمة الأهداف الديناميكية - تحسب الأهداف اليومية بناءً على:
    1. القيم الأساسية (من NutritionCalculator)
    2. تأثير الأعراض والأدوية والأمراض (من HealthImpactFactor)
    3. عامل التكيف مع الأداء (آخر 7-14 يوم)
    4. عامل اتجاه الوزن (من ML Predictor)
    """

    def __init__(self, db: Session):
        self.db = db
        self.calculator = NutritionCalculator()

    # ============================================
    # ✅ 1. حساب الأهداف الديناميكية لليوم
    # ============================================
    def calculate_daily_targets(self, user_id: int, target_date: Optional[date] = None) -> Dict[str, Any]:
        """حساب الأهداف الديناميكية ليوم معين (أو اليوم الحالي)"""
        if target_date is None:
            target_date = date.today()

        logger.info(f"📊 [DynamicTargets] Calculating targets for user {user_id} on {target_date}")

        # 1. جلب القيم الأساسية من UserNutrition
        user_nutrition = (
            self.db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not user_nutrition:
            logger.warning(f"⚠️ [DynamicTargets] No nutrition data for user {user_id}")
            return self._empty_response(user_id, target_date, "لا توجد بيانات غذائية للمستخدم")

        # 2. حساب القيم الأساسية (static)
        base_values = self._calculate_base_values(user_nutrition)

        # 3. حساب تأثير الأعراض والأدوية والأمراض
        health_impacts = self._calculate_health_impacts(user_id, user_nutrition)

        # 4. حساب عامل التكيف مع الأداء
        performance_factor = self._calculate_performance_factor(user_id)

        # 5. حساب عامل اتجاه الوزن
        weight_trend_factor = self._calculate_weight_trend_factor(user_id)

        # 6. حساب الأهداف النهائية
        final_targets = self._apply_all_factors(
            base_values, health_impacts, performance_factor, weight_trend_factor
        )

        # 7. حفظ الأهداف في قاعدة البيانات
        dynamic_target = self._save_dynamic_target(
            user_id, target_date, base_values, health_impacts,
            performance_factor, weight_trend_factor, final_targets
        )

        logger.info(
            f"✅ [DynamicTargets] Targets for user {user_id}: "
            f"calories={final_targets['target_calories']:.0f}, "
            f"steps={final_targets['target_steps']:.0f}, "
            f"water={final_targets['target_water']:.1f}L"
        )

        return {
            "success": True,
            "user_id": user_id,
            "date": target_date.isoformat(),
            "base_values": base_values,
            "health_impacts": health_impacts,
            "performance_factor": performance_factor,
            "weight_trend_factor": weight_trend_factor,
            "final_targets": final_targets,
            "impact_details": health_impacts.get("impact_details", []),
            "performance_details": self._get_performance_details(user_id),
        }

    # ============================================
    # ✅ 2. حساب القيم الأساسية
    # ============================================
    def _calculate_base_values(self, user_nutrition: models.UserNutrition) -> Dict[str, float]:
        """حساب القيم الأساسية باستخدام NutritionCalculator"""
        weight = user_nutrition.weight
        height = user_nutrition.height
        age = user_nutrition.age
        gender = user_nutrition.gender
        goal = user_nutrition.goal
        activity_level = user_nutrition.activity_level
        diseases = user_nutrition.diseases or []
        weight_loss_rate = user_nutrition.weight_loss_rate or "0.5"

        bmr = self.calculator.calculate_bmr(weight, height, age, gender)
        tdee = self.calculator.calculate_tdee(bmr, activity_level)
        target_calories = self.calculator.calculate_target_calories(tdee, goal, weight_loss_rate)
        macros = self.calculator.calculate_macros(target_calories, goal, diseases)
        water_intake = self.calculator.calculate_water_intake(weight, diseases)
        daily_steps = self.calculator.calculate_daily_steps_goal(weight, goal, activity_level)

        return {
            "bmr": round(bmr, 1),
            "tdee": round(tdee, 1),
            "calories": round(target_calories, 1),
            "steps": daily_steps,
            "water": water_intake,
            "protein": macros.get("protein", 0),
            "carbs": macros.get("carbs", 0),
            "fat": macros.get("fat", 0),
        }

    # ============================================
    # ✅ 3. حساب تأثير العوامل الصحية
    # ============================================
    def _calculate_health_impacts(self, user_id: int, user_nutrition: models.UserNutrition) -> Dict[str, Any]:
        """حساب تأثير الأعراض والأدوية والأمراض على الأهداف"""
        total_calories_impact = 0.0
        total_steps_impact = 0.0
        total_water_impact = 0.0
        total_protein_impact = 0.0
        total_carbs_impact = 0.0
        total_fat_impact = 0.0
        impact_details = []

        # 1. تأثير الأعراض النشطة (آخر 7 أيام)
        seven_days_ago = datetime.now() - timedelta(days=7)
        active_symptoms = (
            self.db.query(models.Symptom)
            .filter(
                models.Symptom.user_id == user_id,
                models.Symptom.created_at >= seven_days_ago,
            )
            .all()
        )

        for symptom in active_symptoms:
            impact = self._get_impact_factor(
                self.db, "symptom", symptom.name, severity=symptom.severity
            )
            if impact:
                severity_weight = impact.severity_weight or 1.0
                total_steps_impact += (impact.impact_on_steps or 0) * severity_weight
                total_calories_impact += (impact.calories_adjustment or 0) * severity_weight
                total_water_impact += (impact.water_adjustment or 0) * severity_weight
                total_protein_impact += (impact.protein_adjustment or 0) * severity_weight
                total_carbs_impact += (impact.carbs_adjustment or 0) * severity_weight
                total_fat_impact += (impact.fat_adjustment or 0) * severity_weight

                impact_details.append({
                    "type": "symptom",
                    "name": symptom.name,
                    "severity": symptom.severity,
                    "severity_weight": severity_weight,
                    "steps_impact": impact.impact_on_steps or 0,
                    "calories_impact": impact.calories_adjustment or 0,
                    "water_impact": impact.water_adjustment or 0,
                })

        # 2. تأثير الأدوية النشطة
        today = date.today()
        user_medications = (
            self.db.query(models.Medication)
            .filter(
                models.Medication.user_id == user_id,
                models.Medication.start_date <= today,
                or_(
                    models.Medication.end_date >= today,
                    models.Medication.end_date == None,
                ),
            )
            .all()
        )

        for med in user_medications:
            if med.medicine_id:
                impact = self._get_impact_factor(
                    self.db, "medicine", factor_id=med.medicine_id
                )
            else:
                impact = None

            if impact:
                severity_weight = impact.severity_weight or 1.0
                total_steps_impact += (impact.impact_on_steps or 0) * severity_weight
                total_calories_impact += (impact.calories_adjustment or 0) * severity_weight
                total_water_impact += (impact.water_adjustment or 0) * severity_weight

                medicine_name = (
                    self.db.query(models.Medicine.name_ar)
                    .filter(models.Medicine.id == med.medicine_id)
                    .scalar()
                ) if med.medicine_id else "دواء"

                impact_details.append({
                    "type": "medicine",
                    "name": medicine_name or "دواء",
                    "steps_impact": impact.impact_on_steps or 0,
                    "calories_impact": impact.calories_adjustment or 0,
                    "water_impact": impact.water_adjustment or 0,
                })

        # 3. تأثير الأمراض المزمنة
        if user_nutrition.diseases:
            for disease in user_nutrition.diseases:
                impact = self._get_impact_factor(self.db, "disease", disease)
                if impact:
                    severity_weight = impact.severity_weight or 1.0
                    total_steps_impact += (impact.impact_on_steps or 0) * severity_weight
                    total_calories_impact += (impact.calories_adjustment or 0) * severity_weight
                    total_water_impact += (impact.water_adjustment or 0) * severity_weight

                    impact_details.append({
                        "type": "disease",
                        "name": disease,
                        "steps_impact": impact.impact_on_steps or 0,
                        "calories_impact": impact.calories_adjustment or 0,
                        "water_impact": impact.water_adjustment or 0,
                    })

        return {
            "calories_impact_pct": round(total_calories_impact, 1),
            "steps_impact_pct": round(total_steps_impact, 1),
            "water_impact_pct": round(total_water_impact, 1),
            "protein_impact_pct": round(total_protein_impact, 1),
            "carbs_impact_pct": round(total_carbs_impact, 1),
            "fat_impact_pct": round(total_fat_impact, 1),
            "impact_details": impact_details,
            "active_symptoms_count": len(active_symptoms),
            "active_medications_count": len(user_medications),
        }

    # ============================================
    # ✅ 4. حساب عامل التكيف مع الأداء
    # ============================================
    def _calculate_performance_factor(self, user_id: int, days: int = 7) -> float:
        """حساب عامل التكيف بناءً على أداء آخر N يوم"""
        performance_records = (
            self.db.query(models.PerformanceHistory)
            .filter(
                models.PerformanceHistory.user_id == user_id,
            )
            .order_by(models.PerformanceHistory.date.desc())
            .limit(days)
            .all()
        )

        if not performance_records:
            return 1.0  # لا يوجد تاريخ → لا تعديل

        avg_score = np.mean([p.overall_score for p in performance_records if p.overall_score is not None])

        if len(performance_records) < 3:
            return 1.0  # بيانات قليلة جداً

        # خريطة الالتزام → عامل التكيف
        # الالتزام < 50% → نخفض الأهداف (0.85) - المستخدم يكافح
        # الالتزام 50-70% → نخفض قليلاً (0.90)
        # الالتزام 70-85% → نحافظ على الأهداف (1.0)
        # الالتزام 85-95% → نزيد قليلاً (1.05) - المستخدم متميز
        # الالتزام > 95% → نزيد أكثر (1.10) - تحدٍ أكبر

        if avg_score < 0.5:
            return 0.85
        elif avg_score < 0.7:
            return 0.90
        elif avg_score < 0.85:
            return 1.0
        elif avg_score < 0.95:
            return 1.05
        else:
            return 1.10

    # ============================================
    # ✅ 5. حساب عامل اتجاه الوزن
    # ============================================
    def _calculate_weight_trend_factor(self, user_id: int) -> float:
        """حساب عامل تعديل بناءً على اتجاه الوزن المتوقع"""
        try:
            from services.ai_service import AIService

            # استخدام ML predictor لتوقع اتجاه الوزن
            prediction = AIService.predict_weight(self.db, user_id, weeks_ahead=4)

            if prediction and "predictions" in prediction and len(prediction["predictions"]) > 0:
                current_weight = prediction.get("current_weight", 0)
                predicted_weight = prediction["predictions"][-1].get("predicted_weight", 0)

                if current_weight and current_weight > 0:
                    weight_change_ratio = predicted_weight / current_weight

                    # إذا الوزن ينقص بسرعة → نخفض السعرات قليلاً
                    # إذا الوزن يزيد → نزيد السعرات قليلاً
                    if weight_change_ratio < 0.95:  # نقصان سريع
                        return 0.95
                    elif weight_change_ratio < 0.98:  # نقصان معتدل
                        return 0.98
                    elif weight_change_ratio < 1.02:  # ثبات
                        return 1.0
                    elif weight_change_ratio < 1.05:  # زيادة معتدلة
                        return 1.02
                    else:  # زيادة سريعة
                        return 1.05
        except Exception as e:
            logger.warning(f"⚠️ [DynamicTargets] Weight prediction failed: {e}")

        return 1.0  # لا يمكن التوقع → لا تعديل

    # ============================================
    # ✅ 6. تطبيق جميع العوامل على القيم الأساسية
    # ============================================
    def _apply_all_factors(
        self,
        base_values: Dict[str, float],
        health_impacts: Dict[str, Any],
        performance_factor: float,
        weight_trend_factor: float,
    ) -> Dict[str, float]:
        """تطبيق جميع عوامل التعديل على القيم الأساسية"""
        # الصيغة: الهدف النهائي = القيمة الأساسية × (1 + مجموع التأثيرات/100) × عامل الأداء × عامل الوزن

        calories_impact = health_impacts.get("calories_impact_pct", 0)
        steps_impact = health_impacts.get("steps_impact_pct", 0)
        water_impact = health_impacts.get("water_impact_pct", 0)
        protein_impact = health_impacts.get("protein_impact_pct", 0)
        carbs_impact = health_impacts.get("carbs_impact_pct", 0)
        fat_impact = health_impacts.get("fat_impact_pct", 0)

        target_calories = base_values["calories"] * (1 + calories_impact / 100) * performance_factor * weight_trend_factor
        target_steps = base_values["steps"] * (1 + steps_impact / 100) * performance_factor
        target_water = base_values["water"] * (1 + water_impact / 100) * performance_factor
        target_protein = base_values["protein"] * (1 + protein_impact / 100) * performance_factor
        target_carbs = base_values["carbs"] * (1 + carbs_impact / 100) * performance_factor
        target_fat = base_values["fat"] * (1 + fat_impact / 100) * performance_factor

        # ضمان الحدود المنطقية
        target_calories = max(800, min(target_calories, 5000))
        target_steps = max(1000, min(target_steps, 20000))
        target_water = max(0.5, min(target_water, 5.0))
        target_protein = max(20, min(target_protein, 300))
        target_carbs = max(20, min(target_carbs, 500))
        target_fat = max(10, min(target_fat, 200))

        return {
            "target_calories": round(target_calories, 1),
            "target_steps": round(target_steps),
            "target_water": round(target_water, 1),
            "target_protein": round(target_protein, 1),
            "target_carbs": round(target_carbs, 1),
            "target_fat": round(target_fat, 1),
        }

    # ============================================
    # ✅ 7. حفظ الأهداف الديناميكية في قاعدة البيانات
    # ============================================
    def _save_dynamic_target(
        self,
        user_id: int,
        target_date: date,
        base_values: Dict[str, float],
        health_impacts: Dict[str, Any],
        performance_factor: float,
        weight_trend_factor: float,
        final_targets: Dict[str, float],
    ) -> models.DynamicDailyTarget:
        """حفظ أو تحديث الأهداف الديناميكية في قاعدة البيانات"""
        existing = (
            self.db.query(models.DynamicDailyTarget)
            .filter(
                models.DynamicDailyTarget.user_id == user_id,
                models.DynamicDailyTarget.date == target_date,
            )
            .first()
        )

        if existing:
            # تحديث الأهداف الموجودة
            existing.base_calories = base_values["calories"]
            existing.base_steps = base_values["steps"]
            existing.base_water = base_values["water"]
            existing.base_protein = base_values["protein"]
            existing.base_carbs = base_values["carbs"]
            existing.base_fat = base_values["fat"]

            existing.calories_impact_pct = health_impacts["calories_impact_pct"]
            existing.steps_impact_pct = health_impacts["steps_impact_pct"]
            existing.water_impact_pct = health_impacts["water_impact_pct"]
            existing.protein_impact_pct = health_impacts["protein_impact_pct"]
            existing.carbs_impact_pct = health_impacts["carbs_impact_pct"]
            existing.fat_impact_pct = health_impacts["fat_impact_pct"]

            existing.performance_factor = performance_factor
            existing.weight_trend_factor = weight_trend_factor

            existing.target_calories = final_targets["target_calories"]
            existing.target_steps = final_targets["target_steps"]
            existing.target_water = final_targets["target_water"]
            existing.target_protein = final_targets["target_protein"]
            existing.target_carbs = final_targets["target_carbs"]
            existing.target_fat = final_targets["target_fat"]

            existing.impact_details = json.dumps(health_impacts.get("impact_details", []))
            existing.updated_at = datetime.utcnow()

            self.db.commit()
            logger.info(f"✅ [DynamicTargets] Updated existing target for user {user_id} on {target_date}")
            return existing
        else:
            # إنشاء أهداف جديدة
            new_target = models.DynamicDailyTarget(
                user_id=user_id,
                date=target_date,
                base_calories=base_values["calories"],
                base_steps=base_values["steps"],
                base_water=base_values["water"],
                base_protein=base_values["protein"],
                base_carbs=base_values["carbs"],
                base_fat=base_values["fat"],
                calories_impact_pct=health_impacts["calories_impact_pct"],
                steps_impact_pct=health_impacts["steps_impact_pct"],
                water_impact_pct=health_impacts["water_impact_pct"],
                protein_impact_pct=health_impacts["protein_impact_pct"],
                carbs_impact_pct=health_impacts["carbs_impact_pct"],
                fat_impact_pct=health_impacts["fat_impact_pct"],
                performance_factor=performance_factor,
                weight_trend_factor=weight_trend_factor,
                target_calories=final_targets["target_calories"],
                target_steps=final_targets["target_steps"],
                target_water=final_targets["target_water"],
                target_protein=final_targets["target_protein"],
                target_carbs=final_targets["target_carbs"],
                target_fat=final_targets["target_fat"],
                impact_details=json.dumps(health_impacts.get("impact_details", [])),
            )
            self.db.add(new_target)
            self.db.commit()
            self.db.refresh(new_target)
            logger.info(f"✅ [DynamicTargets] Created new target for user {user_id} on {target_date}")
            return new_target

    # ============================================
    # ✅ 8. حساب أداء اليوم وحفظه
    # ============================================
    def calculate_daily_performance(self, user_id: int, performance_date: Optional[date] = None) -> Dict[str, Any]:
        """حساب أداء المستخدم لليوم ومقارنته بالأهداف الديناميكية"""
        if performance_date is None:
            performance_date = date.today()

        logger.info(f"📊 [DynamicTargets] Calculating performance for user {user_id} on {performance_date}")

        # 1. جلب الأهداف الديناميكية لهذا اليوم
        dynamic_target = (
            self.db.query(models.DynamicDailyTarget)
            .filter(
                models.DynamicDailyTarget.user_id == user_id,
                models.DynamicDailyTarget.date == performance_date,
            )
            .first()
        )

        if not dynamic_target:
            logger.warning(f"⚠️ [DynamicTargets] No dynamic targets for {performance_date}")
            return {"success": False, "message": "لا توجد أهداف ديناميكية لهذا اليوم"}

        # 2. حساب القيم الفعلية
        actual_calories = self._get_actual_calories(user_id, performance_date)
        actual_steps = self._get_actual_steps(user_id, performance_date)
        actual_water = self._get_actual_water(user_id, performance_date)
        medication_adherence = self._get_medication_adherence(user_id, performance_date)

        # 3. حساب نسب الالتزام
        calories_adherence = min(actual_calories / dynamic_target.target_calories, 1.5) if dynamic_target.target_calories else 0
        steps_adherence = min(float(actual_steps) / dynamic_target.target_steps, 1.5) if dynamic_target.target_steps else 0
        water_adherence = min(actual_water / dynamic_target.target_water, 1.5) if dynamic_target.target_water else 0

        # 4. حساب الدرجة الكلية (متوسط مرجح)
        weights = {"calories": 0.25, "steps": 0.25, "water": 0.25, "medication": 0.25}
        overall_score = (
            min(calories_adherence, 1.0) * weights["calories"]
            + min(steps_adherence, 1.0) * weights["steps"]
            + min(water_adherence, 1.0) * weights["water"]
            + medication_adherence * weights["medication"]
        )

        # 5. حفظ الأداء
        self._save_performance(
            user_id, performance_date,
            calories_adherence, steps_adherence, water_adherence, medication_adherence,
            overall_score,
            actual_calories, actual_steps, actual_water,
            dynamic_target.target_calories, dynamic_target.target_steps, dynamic_target.target_water,
        )

        # 6. التحقق من الإنجازات
        self._check_milestones(user_id, overall_score)

        return {
            "success": True,
            "user_id": user_id,
            "date": performance_date.isoformat(),
            "actual": {
                "calories": actual_calories,
                "steps": actual_steps,
                "water": actual_water,
            },
            "targets": {
                "calories": dynamic_target.target_calories,
                "steps": dynamic_target.target_steps,
                "water": dynamic_target.target_water,
            },
            "adherence": {
                "calories": round(calories_adherence, 2),
                "steps": round(steps_adherence, 2),
                "water": round(water_adherence, 2),
                "medication": round(medication_adherence, 2),
            },
            "overall_score": round(overall_score, 2),
        }

    # ============================================
    # ✅ دوال مساعدة لجلب القيم الفعلية
    # ============================================
    def _get_actual_calories(self, user_id: int, target_date: date) -> float:
        """جلب السعرات الفعلية المستهلكة في يوم معين"""
        day_start = datetime.combine(target_date, datetime.min.time())
        day_end = datetime.combine(target_date, datetime.max.time())

        user_nutrition = (
            self.db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not user_nutrition:
            return 0

        meals = (
            self.db.query(models.Meal)
            .filter(
                models.Meal.user_nutrition_id == user_nutrition.id,
                models.Meal.date_time.between(day_start, day_end),
            )
            .all()
        )

        return sum(m.total_calories for m in meals if m.total_calories)

    def _get_actual_steps(self, user_id: int, target_date: date) -> int:
        """جلب الخطوات الفعلية في يوم معين"""
        total_steps = (
            self.db.query(func.sum(models.WalkingActivity.steps))
            .filter(
                models.WalkingActivity.user_id == user_id,
                models.WalkingActivity.activity_date == target_date,
            )
            .scalar()
        )
        return total_steps or 0

    def _get_actual_water(self, user_id: int, target_date: date) -> float:
        """جلب كمية الماء الفعلية في يوم معين"""
        day_start = datetime.combine(target_date, datetime.min.time())
        day_end = datetime.combine(target_date, datetime.max.time())

        total_water = (
            self.db.query(func.sum(models.WaterIntake.amount))
            .filter(
                models.WaterIntake.user_id == user_id,
                models.WaterIntake.time.between(day_start, day_end),
            )
            .scalar()
        )
        return total_water or 0

    def _get_medication_adherence(self, user_id: int, target_date: date) -> float:
        """حساب الالتزام بالأدوية في يوم معين"""
        day_start = datetime.combine(target_date, datetime.min.time())
        day_end = datetime.combine(target_date, datetime.max.time())

        taken_doses = (
            self.db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.user_id == user_id,
                models.MedicationDose.taken_time.between(day_start, day_end),
            )
            .count()
        )

        total_doses = (
            self.db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.user_id == user_id,
                models.MedicationDose.scheduled_time.between(day_start, day_end),
            )
            .count()
        )

        return (taken_doses / total_doses) if total_doses > 0 else 0

    # ============================================
    # ✅ حفظ سجل الأداء
    # ============================================
    def _save_performance(
        self, user_id: int, target_date: date,
        calories_adherence: float, steps_adherence: float,
        water_adherence: float, medication_adherence: float,
        overall_score: float,
        actual_calories: float, actual_steps: int, actual_water: float,
        target_calories: float, target_steps: float, target_water: float,
    ):
        """حفظ أو تحديث سجل الأداء"""
        existing = (
            self.db.query(models.PerformanceHistory)
            .filter(
                models.PerformanceHistory.user_id == user_id,
                models.PerformanceHistory.date == target_date,
            )
            .first()
        )

        if existing:
            existing.calories_adherence = round(calories_adherence, 2)
            existing.steps_adherence = round(steps_adherence, 2)
            existing.water_adherence = round(water_adherence, 2)
            existing.medication_adherence = round(medication_adherence, 2)
            existing.overall_score = round(overall_score, 2)
            existing.actual_calories = actual_calories
            existing.actual_steps = actual_steps
            existing.actual_water = actual_water
            existing.target_calories = target_calories
            existing.target_steps = target_steps
            existing.target_water = target_water
        else:
            performance = models.PerformanceHistory(
                user_id=user_id,
                date=target_date,
                calories_adherence=round(calories_adherence, 2),
                steps_adherence=round(steps_adherence, 2),
                water_adherence=round(water_adherence, 2),
                medication_adherence=round(medication_adherence, 2),
                overall_score=round(overall_score, 2),
                actual_calories=actual_calories,
                actual_steps=actual_steps,
                actual_water=actual_water,
                target_calories=target_calories,
                target_steps=target_steps,
                target_water=target_water,
            )
            self.db.add(performance)

        self.db.commit()

    # ============================================
    # ✅ التحقق من الإنجازات
    # ============================================
    def _check_milestones(self, user_id: int, overall_score: float):
        """التحقق من تحقيق إنجازات جديدة"""
        # 1. التحقق من سلسلة الالتزام
        streak = self._calculate_streak(user_id)

        streak_milestones = {
            3: {"key": "streak_3", "desc": "3 أيام التزام متتالية! 👏", "points": 10},
            7: {"key": "streak_7", "desc": "أسبوع كامل من الالتزام! 🔥", "points": 50},
            14: {"key": "streak_14", "desc": "14 يوم بطل! 💪", "points": 100},
            21: {"key": "streak_21", "desc": "21 يوم - عادة صحية! 🌟", "points": 200},
            30: {"key": "streak_30", "desc": "شهر كامل من الالتزام! 🏆", "points": 500},
        }

        for days, milestone in streak_milestones.items():
            if streak >= days:
                self._create_milestone_if_not_exists(
                    user_id, milestone["key"], "streak", days,
                    milestone["desc"], "🔥", milestone["points"]
                )

        # 2. التحقق من التميز في الأداء
        if overall_score >= 0.9:
            self._create_milestone_if_not_exists(
                user_id, "adherence_90", "adherence", 90,
                "التزام 90%! أداء ممتاز! ⭐", "⭐", 30
            )

        if overall_score >= 0.95:
            self._create_milestone_if_not_exists(
                user_id, "adherence_95", "adherence", 95,
                "التزام 95%! أنت في القمة! 👑", "👑", 100
            )

    def _calculate_streak(self, user_id: int) -> int:
        """حساب عدد الأيام المتتالية للالتزام"""
        records = (
            self.db.query(models.PerformanceHistory)
            .filter(
                models.PerformanceHistory.user_id == user_id,
            )
            .order_by(models.PerformanceHistory.date.desc())
            .all()
        )

        streak = 0
        for record in records:
            if record.overall_score and record.overall_score >= 0.7:
                streak += 1
            else:
                break

        return streak

    def _create_milestone_if_not_exists(
        self, user_id: int, milestone_key: str,
        milestone_type: str, milestone_value: float,
        description: str, icon: str, points: int
    ):
        """إنشاء إنجاز إذا لم يكن موجوداً"""
        existing = (
            self.db.query(models.AchievementMilestone)
            .filter(
                models.AchievementMilestone.user_id == user_id,
                models.AchievementMilestone.milestone_key == milestone_key,
            )
            .first()
        )

        if not existing:
            milestone = models.AchievementMilestone(
                user_id=user_id,
                milestone_type=milestone_type,
                milestone_value=milestone_value,
                milestone_key=milestone_key,
                description=description,
                icon=icon,
                points=points,
            )
            self.db.add(milestone)
            self.db.commit()
            logger.info(f"🏆 [DynamicTargets] New milestone for user {user_id}: {description}")

    # ============================================
    # ✅ دوال مساعدة عامة
    # ============================================
    def _get_impact_factor(
        self, db: Session, factor_type: str, factor_name: Optional[str] = None,
        factor_id: Optional[int] = None, severity: Optional[str] = None
    ) -> Optional[models.HealthImpactFactor]:
        """جلب عامل التأثير من قاعدة البيانات"""
        query = db.query(models.HealthImpactFactor).filter(
            models.HealthImpactFactor.factor_type == factor_type
        )

        if factor_id:
            query = query.filter(models.HealthImpactFactor.factor_id == factor_id)
        elif factor_name:
            query = query.filter(models.HealthImpactFactor.factor_name == factor_name)

        if severity:
            query = query.filter(
                or_(
                    models.HealthImpactFactor.severity_level == severity,
                    models.HealthImpactFactor.severity_level == "",
                    models.HealthImpactFactor.severity_level == "الكل",
                )
            )

        return query.first()

    def _get_performance_details(self, user_id: int) -> Dict[str, Any]:
        """جلب تفاصيل الأداء لآخر 7 أيام"""
        records = (
            self.db.query(models.PerformanceHistory)
            .filter(models.PerformanceHistory.user_id == user_id)
            .order_by(models.PerformanceHistory.date.desc())
            .limit(7)
            .all()
        )

        if not records:
            return {"has_history": False, "message": "لا يوجد سجل أداء بعد"}

        scores = [r.overall_score for r in records if r.overall_score is not None]
        avg_score = np.mean(scores) if scores else 0

        # تحديد الاتجاه
        if len(scores) >= 3:
            recent = np.mean(scores[:3])
            older = np.mean(scores[-3:])
            if recent > older + 0.05:
                trend = "improving"
            elif recent < older - 0.05:
                trend = "declining"
            else:
                trend = "stable"
        else:
            trend = "stable"

        return {
            "has_history": True,
            "records_count": len(records),
            "average_score": round(avg_score, 2),
            "trend": trend,
            "streak_days": self._calculate_streak(user_id),
        }

    def _empty_response(self, user_id: int, target_date: date, message: str) -> Dict[str, Any]:
        """استجابة فارغة عند عدم وجود بيانات"""
        return {
            "success": False,
            "user_id": user_id,
            "date": target_date.isoformat(),
            "message": message,
            "final_targets": {
                "target_calories": 0,
                "target_steps": 0,
                "target_water": 0,
                "target_protein": 0,
                "target_carbs": 0,
                "target_fat": 0,
            },
        }

    # ============================================
    # ✅ 9. تشغيل لجميع المستخدمين (للمجدول)
    # ============================================
    def run_for_all_users(self) -> Dict[str, int]:
        """تشغيل حساب الأهداف الديناميكية لجميع المستخدمين"""
        user_ids = (
            self.db.query(models.UserNutrition.user_id)
            .distinct()
            .all()
        )

        results = {"processed": 0, "failed": 0, "skipped": 0}
        today = date.today()

        for (uid,) in user_ids:
            try:
                # التحقق من وجود أهداف اليوم
                existing = (
                    self.db.query(models.DynamicDailyTarget)
                    .filter(
                        models.DynamicDailyTarget.user_id == uid,
                        models.DynamicDailyTarget.date == today,
                    )
                    .first()
                )

                if existing:
                    results["skipped"] += 1
                    continue

                self.calculate_daily_targets(uid, today)
                results["processed"] += 1
                logger.info(f"✅ [DynamicTargets] Processed user {uid}")
            except Exception as e:
                logger.error(f"❌ [DynamicTargets] Failed for user {uid}: {e}")
                results["failed"] += 1

        logger.info(f"📊 [DynamicTargets] Batch results: {results}")
        return results

    # ============================================
    # ✅ 10. حساب أداء جميع المستخدمين (للمجدول)
    # ============================================
    def run_performance_for_all_users(self) -> Dict[str, int]:
        """تشغيل حساب الأداء لجميع المستخدمين"""
        user_ids = (
            self.db.query(models.UserNutrition.user_id)
            .distinct()
            .all()
        )

        results = {"processed": 0, "failed": 0, "skipped": 0}
        today = date.today()

        for (uid,) in user_ids:
            try:
                existing = (
                    self.db.query(models.PerformanceHistory)
                    .filter(
                        models.PerformanceHistory.user_id == uid,
                        models.PerformanceHistory.date == today,
                    )
                    .first()
                )

                if existing:
                    results["skipped"] += 1
                    continue

                self.calculate_daily_performance(uid, today)
                results["processed"] += 1
            except Exception as e:
                logger.error(f"❌ [DynamicTargets] Performance failed for user {uid}: {e}")
                results["failed"] += 1

        return results