# backend/routers/dynamic_targets.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime, timedelta

from database import get_db
import models
import schemas
from routers.auth import get_current_user
from services.dynamic_targets_service import DynamicTargetsService

router = APIRouter(prefix="/api/dynamic-targets", tags=["dynamic_targets"])


# ============================================
# ✅ 1. حساب وجلب الأهداف الديناميكية لليوم
# ============================================
@router.get("/today", response_model=schemas.DynamicDailyTargetResponse)
def get_dynamic_targets_today(
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حساب وجلب الأهداف الديناميكية لليوم الحالي"""
    target_user_id = user_id if user_id else current_user.id

    # التحقق من الصلاحية
    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    service = DynamicTargetsService(db)
    result = service.calculate_daily_targets(target_user_id)

    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("message", "فشل حساب الأهداف"))

    # جلب الكائن المحفوظ من قاعدة البيانات
    dynamic_target = (
        db.query(models.DynamicDailyTarget)
        .filter(
            models.DynamicDailyTarget.user_id == target_user_id,
            models.DynamicDailyTarget.date == date.today(),
        )
        .first()
    )

    if not dynamic_target:
        raise HTTPException(status_code=404, detail="لم يتم حفظ الأهداف")

    return dynamic_target


# ============================================
# ✅ 2. جلب الأهداف الديناميكية ليوم محدد
# ============================================
@router.get("/date/{target_date}", response_model=schemas.DynamicDailyTargetResponse)
def get_dynamic_targets_by_date(
    target_date: date,
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب الأهداف الديناميكية ليوم محدد"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    # البحث عن الأهداف المحفوظة
    dynamic_target = (
        db.query(models.DynamicDailyTarget)
        .filter(
            models.DynamicDailyTarget.user_id == target_user_id,
            models.DynamicDailyTarget.date == target_date,
        )
        .first()
    )

    if not dynamic_target:
        # إذا لم توجد، نحسبها الآن
        service = DynamicTargetsService(db)
        result = service.calculate_daily_targets(target_user_id, target_date)

        if not result.get("success"):
            raise HTTPException(status_code=404, detail=result.get("message", "فشل حساب الأهداف"))

        dynamic_target = (
            db.query(models.DynamicDailyTarget)
            .filter(
                models.DynamicDailyTarget.user_id == target_user_id,
                models.DynamicDailyTarget.date == target_date,
            )
            .first()
        )

    if not dynamic_target:
        raise HTTPException(status_code=404, detail="لم يتم العثور على الأهداف")

    return dynamic_target


# ============================================
# ✅ 3. تفصيل كيفية حساب الأهداف
# ============================================
@router.get("/breakdown", response_model=List[schemas.DynamicTargetBreakdownResponse])
def get_target_breakdown(
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تفصيل كيفية حساب كل هدف ديناميكي"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    service = DynamicTargetsService(db)
    result = service.calculate_daily_targets(target_user_id)

    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("message", "فشل حساب الأهداف"))

    base = result["base_values"]
    impacts = result["health_impacts"]
    perf_factor = result["performance_factor"]
    weight_factor = result["weight_trend_factor"]
    final = result["final_targets"]
    impact_details = result.get("impact_details", [])

    target_types = [
        {
            "target_type": "calories",
            "base_value": base["calories"],
            "health_impact_adjustment": base["calories"] * (1 + impacts["calories_impact_pct"] / 100),
            "health_impact_pct": impacts["calories_impact_pct"],
            "performance_adjustment": base["calories"] * (1 + impacts["calories_impact_pct"] / 100) * perf_factor,
            "performance_factor": perf_factor,
            "weight_trend_adjustment": final["target_calories"],
            "weight_trend_factor": weight_factor,
            "final_value": final["target_calories"],
            "impact_reasons": [d for d in impact_details if d.get("calories_impact", 0) != 0],
        },
        {
            "target_type": "steps",
            "base_value": base["steps"],
            "health_impact_adjustment": base["steps"] * (1 + impacts["steps_impact_pct"] / 100),
            "health_impact_pct": impacts["steps_impact_pct"],
            "performance_adjustment": base["steps"] * (1 + impacts["steps_impact_pct"] / 100) * perf_factor,
            "performance_factor": perf_factor,
            "weight_trend_adjustment": final["target_steps"],
            "weight_trend_factor": 1.0,
            "final_value": final["target_steps"],
            "impact_reasons": [d for d in impact_details if d.get("steps_impact", 0) != 0],
        },
        {
            "target_type": "water",
            "base_value": base["water"],
            "health_impact_adjustment": base["water"] * (1 + impacts["water_impact_pct"] / 100),
            "health_impact_pct": impacts["water_impact_pct"],
            "performance_adjustment": base["water"] * (1 + impacts["water_impact_pct"] / 100) * perf_factor,
            "performance_factor": perf_factor,
            "weight_trend_adjustment": final["target_water"],
            "weight_trend_factor": 1.0,
            "final_value": final["target_water"],
            "impact_reasons": [d for d in impact_details if d.get("water_impact", 0) != 0],
        },
    ]

    return target_types


# ============================================
# ✅ 4. تاريخ الأهداف الديناميكية
# ============================================
@router.get("/history", response_model=schemas.DynamicTargetHistoryResponse)
def get_dynamic_targets_history(
    days: int = 7,
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب تاريخ الأهداف الديناميكية لآخر N يوم"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    start_date = date.today() - timedelta(days=days)

    targets = (
        db.query(models.DynamicDailyTarget)
        .filter(
            models.DynamicDailyTarget.user_id == target_user_id,
            models.DynamicDailyTarget.date >= start_date,
        )
        .order_by(models.DynamicDailyTarget.date.asc())
        .all()
    )

    if not targets:
        raise HTTPException(status_code=404, detail="لا توجد أهداف ديناميكية في هذه الفترة")

    # حساب المتوسطات والاتجاهات
    avg_calories = sum(t.target_calories or 0 for t in targets) / len(targets)
    avg_steps = sum(t.target_steps or 0 for t in targets) / len(targets)
    avg_water = sum(t.target_water or 0 for t in targets) / len(targets)

    # تحديد الاتجاه (مقارنة أول 3 أيام بآخر 3 أيام)
    def get_trend(values):
        if len(values) < 6:
            return "stable"
        first_avg = sum(values[:3]) / 3
        last_avg = sum(values[-3:]) / 3
        if last_avg > first_avg * 1.02:
            return "increasing"
        elif last_avg < first_avg * 0.98:
            return "decreasing"
        return "stable"

    calories_values = [t.target_calories or 0 for t in targets]
    steps_values = [t.target_steps or 0 for t in targets]
    water_values = [t.target_water or 0 for t in targets]

    return schemas.DynamicTargetHistoryResponse(
        targets=targets,
        period_days=days,
        avg_target_calories=round(avg_calories, 1),
        avg_target_steps=round(avg_steps),
        avg_target_water=round(avg_water, 1),
        calories_trend=get_trend(calories_values),
        steps_trend=get_trend(steps_values),
        water_trend=get_trend(water_values),
    )


# ============================================
# ✅ 5. مقارنة الأهداف الديناميكية مع الثابتة
# ============================================
@router.get("/comparison", response_model=schemas.DynamicTargetComparisonResponse)
def compare_targets(
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """مقارنة الأهداف الديناميكية مع الأهداف الثابتة"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    # الأهداف الثابتة
    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == target_user_id)
        .first()
    )

    if not user_nutrition:
        raise HTTPException(status_code=404, detail="لا توجد بيانات غذائية")

    # الأهداف الديناميكية
    service = DynamicTargetsService(db)
    result = service.calculate_daily_targets(target_user_id)

    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("message", "فشل حساب الأهداف"))

    final = result["final_targets"]
    impact_details = result.get("impact_details", [])

    def calc_change_pct(dynamic_val, static_val):
        if static_val and static_val > 0:
            return round(((dynamic_val - static_val) / static_val) * 100, 1)
        return None

    return schemas.DynamicTargetComparisonResponse(
        static_calories=user_nutrition.target_calories,
        dynamic_calories=final["target_calories"],
        calories_change_pct=calc_change_pct(final["target_calories"], user_nutrition.target_calories),
        static_steps=user_nutrition.daily_steps_goal,
        dynamic_steps=final["target_steps"],
        steps_change_pct=calc_change_pct(final["target_steps"], user_nutrition.daily_steps_goal),
        static_water=user_nutrition.water_intake,
        dynamic_water=final["target_water"],
        water_change_pct=calc_change_pct(final["target_water"], user_nutrition.water_intake),
        static_protein=user_nutrition.target_protein,
        dynamic_protein=final["target_protein"],
        static_carbs=user_nutrition.target_carbs,
        dynamic_carbs=final["target_carbs"],
        static_fat=user_nutrition.target_fat,
        dynamic_fat=final["target_fat"],
        change_reasons=impact_details,
    )


# ============================================
# ✅ 6. سجل الأداء اليومي
# ============================================
@router.get("/performance/today", response_model=dict)
def get_today_performance(
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حساب أداء اليوم ومقارنته بالأهداف الديناميكية"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    service = DynamicTargetsService(db)
    result = service.calculate_daily_performance(target_user_id)

    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("message", "فشل حساب الأداء"))

    return result


# ============================================
# ✅ 7. ملخص الأداء لآخر N يوم (يجب أن يكون قبل /performance/{performance_date})
# ============================================
@router.get("/performance/summary", response_model=schemas.PerformanceSummaryResponse)
def get_performance_summary(
    days: int = 7,
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """ملخص الأداء لآخر N يوم"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    start_date = date.today() - timedelta(days=days)

    records = (
        db.query(models.PerformanceHistory)
        .filter(
            models.PerformanceHistory.user_id == target_user_id,
            models.PerformanceHistory.date >= start_date,
        )
        .order_by(models.PerformanceHistory.date.desc())
        .all()
    )

    if not records:
        raise HTTPException(status_code=404, detail="لا توجد سجلات أداء في هذه الفترة")

    # حساب المتوسطات
    def avg(values):
        vals = [v for v in values if v is not None]
        return sum(vals) / len(vals) if vals else 0

    avg_cal = avg([r.calories_adherence for r in records])
    avg_steps = avg([r.steps_adherence for r in records])
    avg_water = avg([r.water_adherence for r in records])
    avg_med = avg([r.medication_adherence for r in records])
    avg_score = avg([r.overall_score for r in records])

    # حساب عامل التكيف
    service = DynamicTargetsService(db)
    perf_factor = service._calculate_performance_factor(target_user_id, days)

    # تحديد الاتجاه
    scores = [r.overall_score for r in records if r.overall_score is not None]
    if len(scores) >= 4:
        recent = sum(scores[:2]) / 2
        older = sum(scores[-2:]) / 2
        if recent > older + 0.05:
            trend = "improving"
        elif recent < older - 0.05:
            trend = "declining"
        else:
            trend = "stable"
    else:
        trend = "stable"

    return schemas.PerformanceSummaryResponse(
        period_days=days,
        avg_calories_adherence=round(avg_cal, 2),
        avg_steps_adherence=round(avg_steps, 2),
        avg_water_adherence=round(avg_water, 2),
        avg_medication_adherence=round(avg_med, 2),
        avg_overall_score=round(avg_score, 2),
        performance_factor=round(perf_factor, 2),
        trend=trend,
        daily_records=records,
    )


# ============================================
# ✅ 8. سجل الأداء لتاريخ محدد
# ============================================
@router.get("/performance/{performance_date}", response_model=schemas.PerformanceHistoryResponse)
def get_performance_by_date(
    performance_date: date,
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب سجل الأداء ليوم محدد"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    performance = (
        db.query(models.PerformanceHistory)
        .filter(
            models.PerformanceHistory.user_id == target_user_id,
            models.PerformanceHistory.date == performance_date,
        )
        .first()
    )

    if not performance:
        # حساب الأداء إذا لم يكن موجوداً
        service = DynamicTargetsService(db)
        service.calculate_daily_performance(target_user_id, performance_date)

        performance = (
            db.query(models.PerformanceHistory)
            .filter(
                models.PerformanceHistory.user_id == target_user_id,
                models.PerformanceHistory.date == performance_date,
            )
            .first()
        )

    if not performance:
        raise HTTPException(status_code=404, detail="لا يوجد سجل أداء لهذا اليوم")

    return performance


# ============================================
# ✅ 9. الإنجازات
# ============================================
@router.get("/achievements", response_model=schemas.AchievementStatsResponse)
def get_achievements(
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب إنجازات المستخدم"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    milestones = (
        db.query(models.AchievementMilestone)
        .filter(models.AchievementMilestone.user_id == target_user_id)
        .order_by(models.AchievementMilestone.achieved_at.desc())
        .all()
    )

    total_points = sum(m.points for m in milestones)

    # تصنيف حسب النوع
    by_type = {}
    for m in milestones:
        by_type[m.milestone_type] = by_type.get(m.milestone_type, 0) + 1

    # حساب الأيام المتتالية
    service = DynamicTargetsService(db)
    streak = service._calculate_streak(target_user_id)

    return schemas.AchievementStatsResponse(
        total_points=total_points,
        total_milestones=len(milestones),
        milestones_by_type=by_type,
        recent_milestones=milestones[:10],
        streak_days=streak,
    )


# ============================================
# ✅ 10. إعادة حساب الأهداف (للمسؤول)
# ============================================
@router.post("/recalculate")
def recalculate_targets(
    user_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إعادة حساب الأهداف الديناميكية (للمسؤول أو المستخدم)"""
    target_user_id = user_id if user_id else current_user.id

    if current_user.id != target_user_id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح بالوصول")

    service = DynamicTargetsService(db)
    result = service.calculate_daily_targets(target_user_id)

    return result


# ============================================
# ✅ 11. تشغيل لجميع المستخدمين (للمسؤول)
# ============================================
@router.post("/run-all")
def run_for_all_users(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تشغيل حساب الأهداف لجميع المستخدمين (للمسؤول فقط)"""
    if getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="غير مصرح - هذه الخاصية للمسؤول فقط")

    service = DynamicTargetsService(db)
    results = service.run_for_all_users()

    return {"success": True, "results": results}