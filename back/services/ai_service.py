# backend/services/ai_service.py

import json
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, desc
import warnings

warnings.filterwarnings("ignore")

import models
from ml.improved_predictor import get_improved_predictor


class AIService:
    """خدمة الذكاء الاصطناعي المتقدمة"""

    # ============================================
    # ✅ 1. توقع الوزن
    # ============================================
    @staticmethod
    def predict_weight(db: Session, user_id: int, weeks_ahead: int = 4) -> Dict:
        """توقع الوزن بعد عدد محدد من الأسابيع باستخدام Improved ML Model"""

        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not user_nutrition:
            return {"success": False, "error": "بيانات المستخدم غير موجودة"}

        # جلب سجل الوزن
        weight_history = (
            db.query(models.WeightHistory)
            .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
            .order_by(models.WeightHistory.date)
            .all()
        )

        current_weight = float(user_nutrition.weight) if user_nutrition.weight is not None else 0.0
        target_weight = float(user_nutrition.target_weight) if user_nutrition.target_weight is not None else current_weight
        goal = user_nutrition.goal or "تخسيس"

        # تحويل سجل الوزن إلى format متوافق مع ImprovedWeightPredictor
        history_dicts = [
            {"weight": w.weight, "date": w.date.isoformat() if hasattr(w.date, 'isoformat') else str(w.date)}
            for w in weight_history
        ]

        # استخدام Improved ML Model
        try:
            predictor = get_improved_predictor()

            # تدريب النموذج إذا لم يتم تدريبه بعد
            if not predictor.is_trained and len(history_dicts) >= 14:
                predictor.train(history_dicts)

            # التوقع باستخدام النموذج المحسن
            result = predictor.predict(
                weight_history=history_dicts,
                weeks_ahead=weeks_ahead,
                goal=goal,
                target_weight=target_weight
            )

            if result.get("success"):
                return {
                    "success": True,
                    "current_weight": result["current_weight"],
                    "predicted_weight": result["predicted_weight"],
                    "confidence": result.get("confidence", 0.5),
                    "weeks_ahead": weeks_ahead,
                    "weekly_rate": result.get("weekly_rate", 0),
                    "target_weight": target_weight,
                    "weeks_to_target": result.get("weeks_to_target"),
                    "message": result.get("message", ""),
                    "method": result.get("method", "ensemble_ml"),
                    "models_used": result.get("models_used", []),
                    "predictions_by_week": result.get("predictions_by_week", []),
                }
        except Exception as e:
            print(f"⚠️ خطأ في Improved ML Predictor: {e}")
            # Fallback إلى الحساب البسيط

        # Fallback: الحساب البسيط (إذا فشل النموذج المحسن)
        weekly_rate = float(user_nutrition.weight_loss_rate) if user_nutrition.weight_loss_rate is not None else 0.5

        if len(weight_history) >= 3:
            weights = [w.weight for w in weight_history]
            if len(weights) >= 2:
                total_change = weights[-1] - weights[0]
                days = (weight_history[-1].date - weight_history[0].date).days
                if days > 0:
                    weekly_rate = abs(total_change / days * 7)

        if goal == "تخسيس":
            predicted_weight = current_weight - (weekly_rate * weeks_ahead)
        else:
            predicted_weight = current_weight + (weekly_rate * weeks_ahead)

        predicted_weight = max(30, min(300, predicted_weight))

        return {
            "success": True,
            "current_weight": current_weight,
            "predicted_weight": round(predicted_weight, 1),
            "confidence": 0.3,
            "weeks_ahead": weeks_ahead,
            "weekly_rate": round(weekly_rate, 2),
            "target_weight": target_weight,
            "weeks_to_target": None,
            "message": f"بناءً على معدلك الحالي، من المتوقع أن {'تخسر' if goal == 'تخسيس' else 'تزيد'} {round(weekly_rate * weeks_ahead, 1)} كجم خلال {weeks_ahead} أسابيع",
            "method": "simple_fallback",
            "models_used": [],
            "predictions_by_week": [],
        }

    # ============================================
    # ✅ 2. تحليل أنماط الأعراض
    # ============================================
    @staticmethod
    def analyze_symptom_patterns(
        db: Session, user_id: int, days_back: int = 30
    ) -> Dict:
        """تحليل أنماط الأعراض المتكررة"""

        start_date = datetime.now() - timedelta(days=days_back)

        symptoms = (
            db.query(models.Symptom)
            .filter(
                models.Symptom.user_id == user_id,
                models.Symptom.date_time >= start_date,
            )
            .all()
        )

        if not symptoms:
            return {"success": False, "message": "لا توجد أعراض مسجلة", "total": 0}

        # حساب تكرار الأعراض
        symptom_counts = {}
        severity_counts = {"خفيف": 0, "متوسط": 0, "شديد": 0}

        for symptom in symptoms:
            symptom_counts[symptom.name] = symptom_counts.get(symptom.name, 0) + 1
            severity_counts[symptom.severity] = (
                severity_counts.get(symptom.severity, 0) + 1
            )

        # أكثر الأعراض تكراراً
        most_frequent = sorted(
            symptom_counts.items(), key=lambda x: x[1], reverse=True
        )[:5]

        # تحليل الوقت
        hour_distribution = {}
        for symptom in symptoms:
            hour = symptom.date_time.hour
            hour_distribution[hour] = hour_distribution.get(hour, 0) + 1

        peak_hours = sorted(
            hour_distribution.items(), key=lambda x: x[1], reverse=True
        )[:3]

        return {
            "success": True,
            "total": len(symptoms),
            "most_frequent": [
                {"name": name, "count": count} for name, count in most_frequent
            ],
            "severity_distribution": severity_counts,
            "peak_hours": [{"hour": h, "count": c} for h, c in peak_hours],
            "message": f"تم تسجيل {len(symptoms)} عرض خلال {days_back} يوم",
        }

    # ============================================
    # ✅ 3. تحليل فعالية الدواء
    # ============================================
    @staticmethod
    def analyze_medication_effectiveness(
        db: Session, user_id: int, medication_id: int
    ) -> Dict:
        """تحليل فعالية دواء معين"""

        medication = (
            db.query(models.Medication)
            .filter(
                models.Medication.id == medication_id,
                models.Medication.user_id == user_id,
            )
            .first()
        )

        if not medication:
            return {"success": False, "error": "الدواء غير موجود"}

        # جلب الجرعات
        doses = (
            db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.medication_id == medication_id,
                models.MedicationDose.user_id == user_id,
            )
            .all()
        )

        if not doses:
            return {
                "success": False,
                "message": "لا توجد جرعات مسجلة",
                "adherence_rate": 0,
            }

        total = len(doses)
        taken = len([d for d in doses if d.status == "taken"])
        adherence_rate = (taken / total * 100) if total > 0 else 0

        # حساب الالتزام الأسبوعي
        weekly_adherence = []
        doses_by_week = {}
        for dose in doses:
            week = dose.scheduled_time.isocalendar()[1]
            if week not in doses_by_week:
                doses_by_week[week] = {"total": 0, "taken": 0}
            doses_by_week[week]["total"] += 1
            if dose.status == "taken":
                doses_by_week[week]["taken"] += 1

        for week, data in doses_by_week.items():
            rate = (data["taken"] / data["total"] * 100) if data["total"] > 0 else 0
            weekly_adherence.append(rate)

        return {
            "success": True,
            "medication_name": (
                medication.medicine.name_ar if medication.medicine else "دواء"
            ),
            "adherence_rate": round(adherence_rate, 1),
            "total_doses": total,
            "taken_doses": taken,
            "missed_doses": total - taken,
            "weekly_adherence": weekly_adherence,
            "message": f"نسبة الالتزام: {round(adherence_rate, 1)}%",
        }

    # ============================================
    # ✅ 4. نصائح غذائية مخصصة
    # ============================================
    @staticmethod
    def get_personalized_nutrition_advice(db: Session, user_id: int) -> Dict:
        """الحصول على نصائح غذائية مخصصة"""

        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not user_nutrition:
            return {"success": False, "message": "بيانات المستخدم غير موجودة"}

        tips = []

        # نصائح حسب الهدف
        if user_nutrition.goal == "تخسيس":
            tips.append("🥗 تناول وجبات صغيرة متعددة بدلاً من وجبات كبيرة")
            tips.append("💧 اشرب كوب ماء قبل كل وجبة لزيادة الإحساس بالشبع")
            tips.append("🥩 ركز على البروتين والخضروات في كل وجبة")
        elif user_nutrition.goal == "زيادة":
            tips.append("🥜 أضف مكسرات وزبدة فول سوداني لوجباتك لزيادة السعرات")
            tips.append("🍚 تناول الكربوهيدرات المعقدة مثل الأرز البني والشوفان")
            tips.append("🥑 أضف أفوكادو وزيت زيتون لأطباقك")
        else:
            tips.append("⚖️ حافظ على توازن السعرات مع احتياجات جسمك")

        # نصائح حسب الأمراض
        diseases = user_nutrition.diseases
        if isinstance(diseases, str):
            try:
                diseases = json.loads(diseases)
            except:
                diseases = []

        if "السكري" in diseases:
            tips.append("🩸 تجنب السكريات البسيطة وتناول الكربوهيدرات المعقدة")
            tips.append("📊 راقب مستوى السكر بانتظام")

        if "ضغط الدم" in diseases:
            tips.append("🧂 قلل من الملح والأطعمة المصنعة")

        if "القلب" in diseases:
            tips.append("❤️ تناول أوميغا 3 (سمك، مكسرات) وقلل الدهون المشبعة")

        # نصائح عامة
        tips.append("🏃‍♂️ مارس رياضة المشي 30 دقيقة يومياً")
        tips.append("😴 احصل على 7-8 ساعات نوم يومياً")

        return {
            "success": True,
            "tips": tips[:8],
            "goal": user_nutrition.goal,
            "message": f"نصائح مخصصة لهدفك: {user_nutrition.goal}",
        }

    # ============================================
    # ✅ 5. لوحة تحكم متكاملة
    # ============================================
    @staticmethod
    def get_ai_dashboard(db: Session, user_id: int) -> Dict:
        """لوحة تحكم متكاملة للتحليلات"""

        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        # 1. تحليل الوزن
        weight_analysis = AIService._analyze_weight_trends(db, user_id, user_nutrition)

        # 2. تحليل الأعراض
        symptom_analysis = AIService.analyze_symptom_patterns(db, user_id, 30)

        # 3. تحليل الأدوية
        medications = (
            db.query(models.Medication)
            .filter(models.Medication.user_id == user_id)
            .all()
        )

        medication_analysis = []
        for med in medications[:5]:  # آخر 5 أدوية فقط
            analysis = AIService.analyze_medication_effectiveness(db, user_id, med.id)
            if analysis.get("success"):
                medication_analysis.append(
                    {
                        "name": analysis.get("medication_name"),
                        "adherence_rate": analysis.get("adherence_rate"),
                    }
                )

        # 4. حساب درجة الصحة الإجمالية
        health_score = AIService._calculate_health_score(
            weight_analysis, symptom_analysis, medication_analysis, user_nutrition
        )

        # 5. توصيات عامة
        recommendations = AIService._generate_recommendations(
            weight_analysis, symptom_analysis, user_nutrition
        )

        return {
            "success": True,
            "overall_health_score": health_score,
            "weight_analysis": weight_analysis,
            "symptom_analysis": symptom_analysis,
            "medication_analysis": medication_analysis[:3],
            "recommendations": recommendations[:5],
            "last_updated": datetime.now().isoformat(),
        }

    # ============================================
    # ✅ دوال مساعدة
    # ============================================
    @staticmethod
    def _analyze_weight_trends(db: Session, user_id: int, user_nutrition) -> Dict:
        """تحليل اتجاهات الوزن"""

        if not user_nutrition:
            return {"status": "no_data", "message": "لا توجد بيانات كافية"}

        weight_history = (
            db.query(models.WeightHistory)
            .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
            .order_by(models.WeightHistory.date)
            .all()
        )

        current_weight = user_nutrition.weight
        target_weight = user_nutrition.target_weight or current_weight

        if len(weight_history) >= 2:
            first_weight = weight_history[0].weight
            last_weight = weight_history[-1].weight
            total_change = last_weight - first_weight
            days = (weight_history[-1].date - weight_history[0].date).days

            if days > 0:
                weekly_rate = total_change / days * 7
            else:
                weekly_rate = 0

            status = (
                "good"
                if (user_nutrition.goal == "تخسيس" and weekly_rate < 0)
                or (user_nutrition.goal == "زيادة" and weekly_rate > 0)
                else "needs_improvement"
            )

            return {
                "status": status,
                "current_weight": current_weight,
                "target_weight": target_weight,
                "weekly_rate": round(abs(weekly_rate), 2),
                "total_change": round(total_change, 2),
                "days_tracked": days,
                "message": f"تتقدم بمعدل {round(abs(weekly_rate), 2)} كجم أسبوعياً",
            }

        return {
            "status": "insufficient_data",
            "current_weight": current_weight,
            "target_weight": target_weight,
            "message": "سجل وزنك بانتظام لمتابعة التقدم",
        }

    @staticmethod
    def _calculate_health_score(
        weight_analysis: Dict,
        symptom_analysis: Dict,
        medication_analysis: List,
        user_nutrition,
    ) -> int:
        """حساب درجة الصحة الإجمالية"""

        score = 70  # درجة أساسية

        # تأثير الوزن
        if weight_analysis.get("status") == "good":
            score += 10
        elif weight_analysis.get("status") == "needs_improvement":
            score -= 5

        # تأثير الأعراض
        if symptom_analysis.get("success") and symptom_analysis.get("total", 0) > 0:
            severity = symptom_analysis.get("severity_distribution", {})
            if severity.get("شديد", 0) > 0:
                score -= 15
            elif severity.get("متوسط", 0) > 3:
                score -= 5

        # تأثير الأدوية
        if medication_analysis:
            avg_adherence = sum(
                m.get("adherence_rate", 0) for m in medication_analysis
            ) / len(medication_analysis)
            if avg_adherence >= 90:
                score += 10
            elif avg_adherence < 70:
                score -= 10

        # تأثير النشاط (من user_nutrition)
        if user_nutrition:
            activity_levels = {"قليل": -5, "متوسط": 0, "عالي": 5, "مكثف": 10}
            score += activity_levels.get(user_nutrition.activity_level, 0)

        return max(0, min(100, score))

    @staticmethod
    def _generate_recommendations(
        weight_analysis: Dict, symptom_analysis: Dict, user_nutrition
    ) -> List[str]:
        """توليد توصيات مخصصة"""

        recommendations = []

        # توصيات الوزن
        if weight_analysis.get("status") == "needs_improvement":
            if user_nutrition and user_nutrition.goal == "تخسيس":
                recommendations.append(
                    "📉 حاول تقليل 500 سعرة يومياً لخسارة 0.5 كجم أسبوعياً"
                )
            elif user_nutrition and user_nutrition.goal == "زيادة":
                recommendations.append(
                    "📈 أضف 300-500 سعرة يومياً لزيادة الوزن بشكل صحي"
                )

        # توصيات الأعراض
        if symptom_analysis.get("success") and symptom_analysis.get("total", 0) > 5:
            recommendations.append("🩺 استشر طبيباً إذا استمرت الأعراض لأكثر من أسبوع")

        # توصيات عامة
        recommendations.append("💧 اشرب 2-3 لتر ماء يومياً")
        recommendations.append("🏃‍♂️ مارس رياضة المشي 30 دقيقة يومياً")
        recommendations.append("😴 احصل على 7-8 ساعات نوم")

        return recommendations
