# backend/routers/ai_analytics.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime, timedelta, date
import numpy as np
from pydantic import BaseModel

from database import get_db
import models
import schemas
from services.ai_service import AIService

router = APIRouter(prefix="/api/ai", tags=["ai_analytics"])


# ============================================
# Pydantic models for symptom cause analysis
# ============================================
class SymptomCauseRequest(BaseModel):
    symptom_name: str
    severity: str = "متوسط"
    occurred_at: str = ""


class FactorScoreResponse(BaseModel):
    factor_id: str
    factor_name: str
    score: float
    weight: float
    weighted_score: float
    evidence: List[str]
    icon: Optional[str] = None


class SymptomCauseResponse(BaseModel):
    success: bool
    symptom_name: str
    severity: str
    analyzed_at: str
    factors: List[FactorScoreResponse]
    top_causes: List[str]
    recommendations: List[str]
    summary: str
    has_sufficient_data: bool


# ============================================
# ✅ توصية شرب الماء (محسنة)
# ============================================
@router.get("/water-recommendation/{user_id}")
def get_water_recommendation(user_id: int, db: Session = Depends(get_db)):
    """
    حساب كمية الماء الموصى بها للمستخدم بناءً على:
    - الوزن
    - النشاط البدني
    - الأمراض المزمنة
    """

    # جلب بيانات المستخدم
    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )

    if not user_nutrition:
        return {"success": False, "message": "بيانات المستخدم غير موجودة"}

    # ✅ حساب كمية الماء الأساسية (33 مل لكل كجم)
    base_water = user_nutrition.weight * 0.033

    # ✅ تعديل حسب النشاط البدني
    activity_multipliers = {"قليل": 1.0, "متوسط": 1.1, "عالي": 1.2, "مكثف": 1.3}
    activity_multiplier = activity_multipliers.get(user_nutrition.activity_level, 1.0)

    # ✅ تعديل حسب الأمراض المزمنة
    disease_multiplier = 1.0
    disease_reasons = []

    # تحويل الأمراض من JSON string إلى list إذا لزم الأمر
    diseases = user_nutrition.diseases
    if isinstance(diseases, str):
        import json

        try:
            diseases = json.loads(diseases)
        except:
            diseases = []

    for disease in diseases:
        if disease == "السكري":
            disease_multiplier *= 1.15
            disease_reasons.append("مرض السكري يزيد احتياج الماء")
        elif disease == "ضغط الدم":
            disease_multiplier *= 1.1
            disease_reasons.append("ارتفاع ضغط الدم يحتاج ترطيب إضافي")
        elif disease == "القلب":
            disease_multiplier *= 1.05
            disease_reasons.append("مرضى القلب بحاجة لترطيب معتدل")
        elif disease == "الكلى":
            disease_multiplier *= 1.2
            disease_reasons.append("أمراض الكلى تحتاج عناية خاصة بشرب الماء")
        elif disease == "الأنيميا":
            disease_multiplier *= 1.1
            disease_reasons.append("الأنيميا قد تسبب تعباً وجفافاً")

    # ✅ الحساب النهائي
    recommended_water = base_water * activity_multiplier * disease_multiplier

    # ✅ تحديد النطاق المنطقي (بين 1.5 و 4 لتر)
    recommended_water = max(1.5, min(recommended_water, 4.0))

    # ✅ تحديث الهدف اليومي في جدول water_settings (مع التحقق من الوجود)
    water_settings = (
        db.query(models.WaterSettings)
        .filter(models.WaterSettings.user_id == user_id)
        .first()
    )

    if water_settings:
        # ✅ تحديث السجل الموجود
        water_settings.daily_goal = round(recommended_water, 1)
        print(
            f"✅ [Water] تم تحديث إعدادات الماء للمستخدم {user_id}: {round(recommended_water, 1)} لتر"
        )
    else:
        # ✅ إنشاء سجل جديد
        water_settings = models.WaterSettings(
            user_id=user_id, daily_goal=round(recommended_water, 1)
        )
        db.add(water_settings)
        print(
            f"✅ [Water] تم إنشاء إعدادات الماء للمستخدم {user_id}: {round(recommended_water, 1)} لتر"
        )

    try:
        db.commit()
    except Exception as e:
        print(f"⚠️ [Water] خطأ في حفظ الإعدادات: {e}")
        db.rollback()
        # محاولة تحديث مباشر باستخدام SQL إذا فشل
        try:
            from sqlalchemy import update

            stmt = (
                update(models.WaterSettings)
                .where(models.WaterSettings.user_id == user_id)
                .values(daily_goal=round(recommended_water, 1))
            )
            db.execute(stmt)
            db.commit()
            print(f"✅ [Water] تم التحديث باستخدام SQL للمستخدم {user_id}")
        except Exception as e2:
            print(f"❌ [Water] فشل التحديث أيضاً: {e2}")

    # ✅ رسالة توضيحية للمستخدم
    reason_text = ""
    if disease_reasons:
        reason_text = " | ".join(disease_reasons[:2])

    return {
        "success": True,
        "recommended_water": round(recommended_water, 1),
        "base_water": round(base_water, 1),
        "activity_factor": activity_multiplier,
        "disease_factor": round(disease_multiplier, 2),
        "reason": reason_text if reason_text else "محسوب حسب وزنك ومستوى نشاطك",
        "activity_level": user_nutrition.activity_level,
        "diseases": diseases,
    }


# ============================================
# ✅ توقع الوزن
# ============================================
@router.get("/predict-weight/{user_id}")
def predict_weight(user_id: int, weeks_ahead: int = 4, db: Session = Depends(get_db)):
    """توقع الوزن بعد عدد محدد من الأسابيع"""
    return AIService.predict_weight(db, user_id, weeks_ahead)


# ============================================
# ✅ تحليل أنماط الأعراض
# ============================================
@router.get("/symptom-patterns/{user_id}")
def analyze_symptom_patterns(
    user_id: int, days_back: int = 30, db: Session = Depends(get_db)
):
    """تحليل أنماط الأعراض المتكررة"""
    return AIService.analyze_symptom_patterns(db, user_id, days_back)


# ============================================
# ✅ تحليل فعالية الدواء
# ============================================
@router.get("/medication-effectiveness/{user_id}/{medication_id}")
def analyze_medication_effectiveness(
    user_id: int, medication_id: int, db: Session = Depends(get_db)
):
    """تحليل فعالية دواء معين"""
    return AIService.analyze_medication_effectiveness(db, user_id, medication_id)


# ============================================
# ✅ نصائح غذائية مخصصة
# ============================================
@router.get("/nutrition-advice/{user_id}")
def get_nutrition_advice(user_id: int, db: Session = Depends(get_db)):
    """الحصول على نصائح غذائية مخصصة"""
    return AIService.get_personalized_nutrition_advice(db, user_id)


# ============================================
# ✅ لوحة تحكم متكاملة للتحليلات
# ============================================
@router.get("/dashboard/{user_id}")
def get_ai_dashboard(user_id: int, db: Session = Depends(get_db)):
    """لوحة تحكم متكاملة للتحليلات"""
    return AIService.get_ai_dashboard(db, user_id)


# ============================================
# ✅ تحليل أسباب الأعراض الذكي (7 أبعاد بيانات)
# ============================================
FACTOR_WEIGHTS = {
    "nutrition": 0.20,
    "medication": 0.15,
    "hydration": 0.15,
    "activity": 0.10,
    "weight": 0.10,
    "symptom_pattern": 0.15,
    "health_risk": 0.15,
}

FACTOR_META = {
    "nutrition": {"name": "التغذية", "icon": "🍽️"},
    "medication": {"name": "الأدوية", "icon": "💊"},
    "hydration": {"name": "شرب الماء", "icon": "💧"},
    "activity": {"name": "النشاط البدني", "icon": "🚶"},
    "weight": {"name": "الوزن", "icon": "⚖️"},
    "symptom_pattern": {"name": "نمط الأعراض", "icon": "📊"},
    "health_risk": {"name": "المخاطر الصحية", "icon": "🩺"},
}

MAX_SCORE = 1.0


@router.post("/symptom-cause-analysis", response_model=SymptomCauseResponse)
def symptom_cause_analysis(
    user_id: int,
    request: SymptomCauseRequest,
    db: Session = Depends(get_db),
):
    """
    تحليل الأسباب المحتملة لظهور عرض صحي بناءً على 7 أبعاد بيانات:
    - التغذية (الوجبات، السعرات)
    - الأدوية (الأدوية الحالية، الآثار الجانبية)
    - شرب الماء (الكمية المتناولة vs الهدف)
    - النشاط البدني (المشي، الخطوات)
    - الوزن (التغيرات)
    - نمط الأعراض (التكرار)
    - المخاطر الصحية (الأمراض المزمنة)
    """
    try:
        occurred_dt = (
            datetime.fromisoformat(request.occurred_at)
            if request.occurred_at
            else datetime.utcnow()
        )
        occurred_date = occurred_dt.date()

        # Query all data sources in parallel via sequential queries
        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        # --- Score each factor ---
        factors = []

        # 1. Nutrition factor
        nutrition_result = _score_nutrition(db, user_id, user_nutrition, occurred_date)
        factors.append(nutrition_result)

        # 2. Medication factor
        medication_result = _score_medication(db, user_id, request.symptom_name)
        factors.append(medication_result)

        # 3. Hydration factor
        hydration_result = _score_hydration(db, user_id, occurred_date)
        factors.append(hydration_result)

        # 4. Activity factor
        activity_result = _score_activity(db, user_id, occurred_date)
        factors.append(activity_result)

        # 5. Weight factor
        weight_result = _score_weight(db, user_id, user_nutrition)
        factors.append(weight_result)

        # 6. Symptom pattern factor
        pattern_result = _score_symptom_pattern(
            db, user_id, request.symptom_name, occurred_date
        )
        factors.append(pattern_result)

        # 7. Health risk factor
        health_result = _score_health_risk(db, user_id, user_nutrition)
        factors.append(health_result)

        # Rank and build response
        ranked = sorted(factors, key=lambda f: f["weighted_score"], reverse=True)

        has_data = any(f["score"] > 0.0 for f in factors)
        top_causes = [f["factor_name"] for f in ranked[:3] if f["weighted_score"] > 0.15]
        if not top_causes:
            top_causes = ["قد لا يكون هناك سبب واضح، راقب الأعراض"]

        summary = _generate_summary(ranked, request.symptom_name)
        recommendations = _generate_recommendations(ranked, request.symptom_name)

        response_factors = [
            FactorScoreResponse(
                factor_id=f["factor_id"],
                factor_name=f["factor_name"],
                score=round(f["score"], 2),
                weight=f["weight"],
                weighted_score=round(f["weighted_score"], 3),
                evidence=f["evidence"],
                icon=f.get("icon"),
            )
            for f in factors
        ]

        return SymptomCauseResponse(
            success=True,
            symptom_name=request.symptom_name,
            severity=request.severity,
            analyzed_at=datetime.utcnow().isoformat(),
            factors=response_factors,
            top_causes=top_causes,
            recommendations=recommendations,
            summary=summary,
            has_sufficient_data=has_data and user_nutrition is not None,
        )

    except Exception as e:
        print(f"❌ [SymptomCause] خطأ في التحليل: {e}")
        raise HTTPException(status_code=500, detail=f"فشل تحليل أسباب العرض: {str(e)}")


def _score_nutrition(
    db: Session,
    user_id: int,
    user_nutrition: Optional[models.UserNutrition],
    occurred_date: date,
) -> dict:
    """تقييم عامل التغذية - الوجبات والسعرات"""
    factor_id = "nutrition"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    if not user_nutrition:
        return {
            "factor_id": factor_id,
            "factor_name": factor_name,
            "score": 0.0,
            "weight": FACTOR_WEIGHTS[factor_id],
            "weighted_score": 0.0,
            "evidence": ["لا توجد بيانات تغذية"],
            "icon": FACTOR_META[factor_id]["icon"],
        }

    # Query meals around the symptom date (last 3 days)
    start_date = occurred_date - timedelta(days=3)
    meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_id == user_id,
            models.Meal.date_time >= datetime.combine(start_date, datetime.min.time()),
            models.Meal.date_time <= datetime.combine(occurred_date, datetime.max.time()),
        )
        .all()
    )

    if not meals:
        evidence.append("لا توجد وجبات مسجلة في آخر 3 أيام")
    else:
        checks += 1
        # Check if meals have adequate calories
        avg_calories = sum(m.total_calories or 0 for m in meals) / len(meals)
        target = user_nutrition.target_calories or 2000

        if avg_calories < target * 0.5:
            score += 0.8
            evidence.append(f"معدل السعرات منخفض جداً ({avg_calories:.0f}/اليوم)")
        elif avg_calories < target * 0.8:
            score += 0.5
            evidence.append(f"معدل السعرات أقل من الموصى به ({avg_calories:.0f}/{target:.0f})")
        elif avg_calories > target * 1.5:
            score += 0.4
            evidence.append(f"معدل السعرات مرتفع ({avg_calories:.0f}/{target:.0f})")
        else:
            score += 0.1
            evidence.append("معدل السعرات مناسب")

        # Check macro balance
        for meal in meals:
            if meal.total_protein and meal.total_carbs and meal.total_fat:
                total = meal.total_protein + meal.total_carbs + meal.total_fat
                if total > 0:
                    protein_pct = (meal.total_protein / total) * 100
                    if protein_pct < 10:
                        checks += 1
                        score += 0.3
                        evidence.append(
                            f"نسبة البروتين منخفضة في {meal.type or 'وجبة'}"
                        )
                        break

    # Check skipped meals
    meal_types = {m.type for m in meals if m.type}
    expected = {"فطور", "غداء", "عشاء"}
    skipped = expected - meal_types
    if skipped:
        checks += 1
        score += 0.3 * len(skipped)
        evidence.append(f"وجبات مفقودة: {', '.join(skipped)}")

    final_score = min(score / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["بيانات التغذية طبيعية"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _score_medication(
    db: Session, user_id: int, symptom_name: str
) -> dict:
    """تقييم عامل الأدوية - الآثار الجانبية"""
    factor_id = "medication"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    medications = (
        db.query(models.Medication)
        .filter(
            models.Medication.user_id == user_id,
            models.Medication.end_date == None,
        )
        .all()
    )

    if not medications:
        return {
            "factor_id": factor_id,
            "factor_name": factor_name,
            "score": 0.0,
            "weight": FACTOR_WEIGHTS[factor_id],
            "weighted_score": 0.0,
            "evidence": ["لا توجد أدوية نشطة"],
            "icon": FACTOR_META[factor_id]["icon"],
        }

    evidence.append(f"{len(medications)} أدوية نشطة")
    symptom_lower = symptom_name.lower()

    for med in medications:
        medicine = med.medicine
        if not medicine:
            continue

        # Check side effects for symptom match
        side_effects = medicine.side_effects
        if isinstance(side_effects, str):
            try:
                import json
                side_effects = json.loads(side_effects)
            except:
                side_effects = []
        if not isinstance(side_effects, list):
            side_effects = []

        for effect in side_effects:
            checks += 1
            if isinstance(effect, str) and symptom_lower in effect.lower():
                score += 0.7
                evidence.append(
                    f"الآثار الجانبية لـ {medicine.name_ar}: {effect}"
                )

        # Check medication category
        category = (medicine.category or "").lower()
        relevant_categories = {
            "سكري": ["دوخة", "تعب", "غثيان"],
            "ضغط": ["دوخة", "صداع", "تعب"],
            "قلب": ["تعب", "دوخة", "ضيق تنفس"],
            "مضاد": ["غثيان", "إسهال", "حساسية"],
        }
        for cat_key, symptoms in relevant_categories.items():
            if cat_key in category:
                for sym in symptoms:
                    checks += 1
                    if symptom_lower in sym or sym in symptom_lower:
                        score += 0.4
                        evidence.append(
                            f"فئة {medicine.category} قد تسبب {sym}"
                        )
                        break

    final_score = min(score / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["لا توجد آثار جانبية واضحة"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _score_hydration(
    db: Session, user_id: int, occurred_date: date
) -> dict:
    """تقييم عامل شرب الماء"""
    factor_id = "hydration"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    # Get water goal
    water_settings = (
        db.query(models.WaterSettings)
        .filter(models.WaterSettings.user_id == user_id)
        .first()
    )
    daily_goal = water_settings.daily_goal if water_settings else 2.0

    # Get water intake for the day
    day_start = datetime.combine(occurred_date, datetime.min.time())
    day_end = datetime.combine(occurred_date, datetime.max.time())

    water_intakes = (
        db.query(models.WaterIntake)
        .filter(
            models.WaterIntake.user_id == user_id,
            models.WaterIntake.time >= day_start,
            models.WaterIntake.time <= day_end,
        )
        .all()
    )

    total_intake = sum(w.amount for w in water_intakes)
    intake_liters = total_intake / 1000.0 if total_intake < 50 else total_intake

    if not water_intakes:
        checks += 1
        score += 0.6
        evidence.append("لا يوجد تسجيل لشرب الماء اليوم")
    else:
        checks += 1
        if intake_liters < daily_goal * 0.5:
            score += 0.8
            evidence.append(
                f"شرب الماء منخفض جداً ({intake_liters:.1f}لتر من {daily_goal:.1f}لتر)"
            )
        elif intake_liters < daily_goal * 0.8:
            score += 0.5
            evidence.append(
                f"شرب الماء أقل من الهدف ({intake_liters:.1f}لتر من {daily_goal:.1f}لتر)"
            )
        else:
            score += 0.1
            evidence.append("مستوى شرب الماء مناسب")

        # Check consistency - intakes per time of day
        if len(water_intakes) < 3 and intake_liters < daily_goal:
            checks += 1
            score += 0.3
            evidence.append("توزيع شرب الماء غير منتظم خلال اليوم")

    final_score = min(score / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["مستوى الترطيب طبيعي"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _score_activity(
    db: Session, user_id: int, occurred_date: date
) -> dict:
    """تقييم عامل النشاط البدني"""
    factor_id = "activity"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    # Get walking activities for last 7 days
    start_date = occurred_date - timedelta(days=7)
    activities = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == user_id,
            models.WalkingActivity.activity_date >= start_date,
            models.WalkingActivity.activity_date <= occurred_date,
        )
        .all()
    )

    if not activities:
        return {
            "factor_id": factor_id,
            "factor_name": factor_name,
            "score": 0.3,
            "weight": FACTOR_WEIGHTS[factor_id],
            "weighted_score": 0.3 * FACTOR_WEIGHTS[factor_id],
            "evidence": ["لا توجد أنشطة بدنية مسجلة"],
            "icon": FACTOR_META[factor_id]["icon"],
        }

    evidence.append(f"{len(activities)} أيام نشاط مسجلة")
    total_steps = sum(a.steps for a in activities if a.steps)
    avg_steps = total_steps / len(activities)

    if avg_steps < 2000:
        checks += 1
        score += 0.8
        evidence.append(f"نشاط بدني منخفض جداً (متوسط {avg_steps:.0f} خطوة/يوم)")
    elif avg_steps < 5000:
        checks += 1
        score += 0.5
        evidence.append(f"نشاط بدني أقل من الموصى به ({avg_steps:.0f} خطوة/يوم)")
    else:
        checks += 1
        score += 0.1
        evidence.append(f"مستوى النشاط مناسب ({avg_steps:.0f} خطوة/يوم)")

    # Check recent activity on symptom day
    day_activity = [
        a for a in activities if a.activity_date == occurred_date
    ]
    if not day_activity:
        checks += 1
        score += 0.3
        evidence.append("لا يوجد نشاط في يوم ظهور العرض")

    final_score = min(score / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["مستوى النشاط طبيعي"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _score_weight(
    db: Session,
    user_id: int,
    user_nutrition: Optional[models.UserNutrition],
) -> dict:
    """تقييم عامل الوزن - التغيرات الأخيرة"""
    factor_id = "weight"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    if not user_nutrition:
        return {
            "factor_id": factor_id,
            "factor_name": factor_name,
            "score": 0.0,
            "weight": FACTOR_WEIGHTS[factor_id],
            "weighted_score": 0.0,
            "evidence": ["لا توجد بيانات وزن"],
            "icon": FACTOR_META[factor_id]["icon"],
        }

    # Get weight history for last 30 days
    thirty_days_ago = date.today() - timedelta(days=30)
    weight_records = (
        db.query(models.WeightHistory)
        .filter(
            models.WeightHistory.user_nutrition_id == user_nutrition.id,
            models.WeightHistory.date >= thirty_days_ago,
        )
        .order_by(models.WeightHistory.date.desc())
        .all()
    )

    if not weight_records or len(weight_records) < 2:
        checks += 1
        score += 0.2
        evidence.append("بيانات الوزن غير كافية للتحليل")
    else:
        current = weight_records[0].weight
        previous = weight_records[-1].weight
        change_30d = current - previous
        change_pct = (abs(change_30d) / previous) * 100 if previous > 0 else 0

        checks += 1
        if change_pct > 5:
            score += 0.7
            direction = "زيادة" if change_30d > 0 else "نقص"
            evidence.append(
                f"تغير وزن ملحوظ آخر 30 يوم: {direction} {abs(change_30d):.1f} كجم ({change_pct:.1f}%)"
            )
        elif change_pct > 2:
            score += 0.4
            direction = "زيادة" if change_30d > 0 else "نقص"
            evidence.append(
                f"تغير وزن معتدل: {direction} {abs(change_30d):.1f} كجم"
            )
        else:
            score += 0.1
            evidence.append("الوزن مستقر نسبياً")

    # Check BMI
    height_m = (user_nutrition.height or 170) / 100.0
    weight_kg = user_nutrition.weight or 70
    bmi = weight_kg / (height_m * height_m)

    if bmi > 30:
        checks += 1
        score += 0.5
        evidence.append(f"مؤشر كتلة الجسم مرتفع ({bmi:.1f}) - سمنة")
    elif bmi > 25:
        checks += 1
        score += 0.3
        evidence.append(f"مؤشر كتلة الجسم مرتفع قليلاً ({bmi:.1f})")
    elif bmi < 18.5:
        checks += 1
        score += 0.4
        evidence.append(f"مؤشر كتلة الجسم منخفض ({bmi:.1f}) - نحافة")

    final_score = min(score / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["مؤشرات الوزن طبيعية"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _score_symptom_pattern(
    db: Session, user_id: int, symptom_name: str, occurred_date: date
) -> dict:
    """تقييم نمط الأعراض - التكرار والتاريخ"""
    factor_id = "symptom_pattern"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    # Get symptom history for last 30 days
    thirty_days_ago = occurred_date - timedelta(days=30)
    past_symptoms = (
        db.query(models.Symptom)
        .filter(
            models.Symptom.user_id == user_id,
            models.Symptom.date_time >= datetime.combine(thirty_days_ago, datetime.min.time()),
            models.Symptom.date_time <= datetime.combine(occurred_date, datetime.max.time()),
        )
        .order_by(models.Symptom.date_time.desc())
        .all()
    )

    if not past_symptoms:
        return {
            "factor_id": factor_id,
            "factor_name": factor_name,
            "score": 0.1,
            "weight": FACTOR_WEIGHTS[factor_id],
            "weighted_score": 0.1 * FACTOR_WEIGHTS[factor_id],
            "evidence": ["لا توجد أعراض سابقة مسجلة"],
            "icon": FACTOR_META[factor_id]["icon"],
        }

    evidence.append(f"{len(past_symptoms)} أعراض مسجلة آخر 30 يوم")

    # Check if this symptom is recurrent
    same_symptoms = [
        s for s in past_symptoms
        if s.name and (symptom_name.lower() in s.name.lower() or s.name.lower() in symptom_name.lower())
    ]

    if len(same_symptoms) > 5:
        checks += 1
        score += 0.9
        evidence.append(
            f"عرض متكرر جداً ({len(same_symptoms)} مرة آخر 30 يوم)"
        )
    elif len(same_symptoms) > 2:
        checks += 1
        score += 0.6
        evidence.append(
            f"عرض متكرر ({len(same_symptoms)} مرات آخر 30 يوم)"
        )
    elif len(same_symptoms) > 1:
        checks += 1
        score += 0.3
        evidence.append(f"ظهور سابق للعرض ({len(same_symptoms)} مرات)")

    # Check severity progression
    severities = [s.severity for s in same_symptoms if s.severity]
    if severities:
        severity_order = {"خفيف": 1, "متوسط": 2, "شديد": 3}
        numeric = [severity_order.get(s, 2) for s in severities]
        if len(numeric) >= 2 and numeric[-1] > numeric[0]:
            checks += 1
            score += 0.5
            evidence.append("تطور في شدة العرض (يزداد سوءاً)")
        elif len(numeric) >= 2 and numeric[-1] < numeric[0]:
            checks += 1
            score -= 0.2
            evidence.append("تحسن في شدة العرض")

    # Check symptom clustering (multiple different symptoms recently)
    unique_names = set(s.name for s in past_symptoms if s.name)
    if len(unique_names) >= 5:
        checks += 1
        score += 0.4
        evidence.append(f"تعدد الأعراض ({len(unique_names)} أعراض مختلفة)")
    elif len(unique_names) >= 3:
        checks += 1
        score += 0.2
        evidence.append(f"وجود {len(unique_names)} أعراض مختلفة")

    final_score = min(max(score, 0.0) / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["نمط الأعراض طبيعي"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _score_health_risk(
    db: Session,
    user_id: int,
    user_nutrition: Optional[models.UserNutrition],
) -> dict:
    """تقييم المخاطر الصحية - الأمراض المزمنة"""
    factor_id = "health_risk"
    factor_name = FACTOR_META[factor_id]["name"]
    evidence = []
    score = 0.0
    checks = 0

    if not user_nutrition:
        return {
            "factor_id": factor_id,
            "factor_name": factor_name,
            "score": 0.0,
            "weight": FACTOR_WEIGHTS[factor_id],
            "weighted_score": 0.0,
            "evidence": ["لا توجد بيانات صحية"],
            "icon": FACTOR_META[factor_id]["icon"],
        }

    diseases = user_nutrition.diseases
    if isinstance(diseases, str):
        try:
            import json
            diseases = json.loads(diseases)
        except:
            diseases = []
    if not isinstance(diseases, list):
        diseases = []

    if not diseases:
        checks += 1
        score += 0.1
        evidence.append("لا توجد أمراض مزمنة مسجلة")
    else:
        evidence.append(f"الأمراض المزمنة: {', '.join(diseases)}")
        disease_risk_map = {
            "السكري": 0.7,
            "ضغط الدم": 0.6,
            "القلب": 0.7,
            "السمنة": 0.5,
            "الأنيميا": 0.5,
            "الكلى": 0.6,
            "الربو": 0.4,
            "الغدة الدرقية": 0.5,
        }
        for disease in diseases:
            checks += 1
            if disease in disease_risk_map:
                score += disease_risk_map[disease]
                evidence.append(f"{disease} قد يسبب أعراضاً متنوعة")

    # Check age risk factor
    age = user_nutrition.age or 30
    if age > 60:
        checks += 1
        score += 0.3
        evidence.append("عامل السن (أكبر من 60 سنة) يزيد الاحتمالات")
    elif age > 45:
        checks += 1
        score += 0.1

    # Check smoking/other risk indicators
    goal = (user_nutrition.goal or "").lower()
    if "صح" in goal or "weight" in goal.lower():
        # Health-focused goal is positive
        pass

    final_score = min(score / max(checks, 1), MAX_SCORE)
    return {
        "factor_id": factor_id,
        "factor_name": factor_name,
        "score": final_score,
        "weight": FACTOR_WEIGHTS[factor_id],
        "weighted_score": final_score * FACTOR_WEIGHTS[factor_id],
        "evidence": evidence if evidence else ["لا توجد مخاطر صحية واضحة"],
        "icon": FACTOR_META[factor_id]["icon"],
    }


def _generate_summary(
    ranked: list, symptom_name: str
) -> str:
    """توليد ملخص التحليل"""
    high_factors = [f for f in ranked if f["weighted_score"] > 0.3]
    moderate_factors = [
        f for f in ranked if 0.15 < f["weighted_score"] <= 0.3
    ]

    if not high_factors and not moderate_factors:
        return f"لا توجد عوامل واضحة قد تكون سبباً مباشراً لـ {symptom_name}. يُنصح بمراقبة الأعراض."

    lines = []
    if high_factors:
        names = "، ".join(f["factor_name"] for f in high_factors)
        lines.append(f"العوامل الأكثر احتمالاً: {names}.")

    if moderate_factors:
        names = "، ".join(f["factor_name"] for f in moderate_factors)
        lines.append(f"عوامل إضافية: {names}.")

    lines.append(
        f"يُنصح بمراجعة هذه العوامل لتحديد السبب المحتمل لـ {symptom_name}."
    )
    return " ".join(lines)


def _generate_recommendations(
    ranked: list, symptom_name: str
) -> list:
    """توليد توصيات مخصصة"""
    recommendations = []

    for factor in ranked:
        fid = factor["factor_id"]
        if factor["weighted_score"] <= 0.15:
            continue

        if fid == "nutrition":
            recommendations.append(
                "تناول وجبات متوازنة تحتوي على البروتين والخضروات"
            )
            recommendations.append(
                "تجنب تخطي الوجبات، خاصة الفطور"
            )
        elif fid == "medication":
            recommendations.append(
                "استشر طبيبك حول الآثار الجانبية للأدوية الحالية"
            )
        elif fid == "hydration":
            recommendations.append(
                "اشرب كمية كافية من الماء (2-3 لتر يومياً)"
            )
            recommendations.append(
                "وزع شرب الماء على فترات منتظمة خلال اليوم"
            )
        elif fid == "activity":
            recommendations.append(
                "زد مستوى النشاط البدني تدريجياً (مشي 30 دقيقة يومياً)"
            )
        elif fid == "weight":
            recommendations.append(
                "تابع وزنك بانتظام وحافظ على نمط حياة صحي"
            )
        elif fid == "symptom_pattern":
            recommendations.append(
                "سجل الأعراض في مذكرتك اليومية لمراقبة الأنماط"
            )
        elif fid == "health_risk":
            recommendations.append(
                "تابع حالتك الصحية مع طبيب مختص بانتظام"
            )

    if not recommendations:
        recommendations.append(
            f"إذا استمر {symptom_name}، يُنصح باستشارة الطبيب"
        )

    return recommendations[:5]
