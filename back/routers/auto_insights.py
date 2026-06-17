# backend/routers/auto_insights.py

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, desc
from datetime import datetime, timedelta, date
from typing import Dict, List, Optional
import json
import numpy as np

from database import get_db
import models
from slowapi import Limiter
from slowapi.util import get_remote_address

router = APIRouter(prefix="/api/insights", tags=["Auto Insights"])
limiter = Limiter(key_func=get_remote_address)


@router.get("/daily/{user_id}")
@limiter.limit("30/minute")
def get_daily_insights(request: Request, user_id: int, db: Session = Depends(get_db)):
    """توليد رؤى تلقائية يومية بناءً على جميع بيانات المستخدم"""
    insights = []

    # 1. Water insight
    water_today = (
        db.query(func.sum(models.WaterIntake.amount))
        .filter(
            models.WaterIntake.user_id == user_id,
            func.date(models.WaterIntake.date_time) == func.current_date(),
        )
        .scalar()
        or 0
    )
    water_settings = (
        db.query(models.WaterSettings)
        .filter(models.WaterSettings.user_id == user_id)
        .first()
    )
    daily_goal = water_settings.daily_goal if water_settings else 2.5

    if water_today < daily_goal * 0.5:
        insights.append(
            {
                "type": "warning",
                "category": "water",
                "icon": "💧",
                "title": "شرب الماء",
                "message": f"شربت {water_today:.1f}ل فقط من أصل {daily_goal:.1f}ل. اشرب المزيد!",
                "priority": 1,
                "action": "اشرب الآن",
                "action_route": "/water",
            }
        )
    elif water_today >= daily_goal:
        insights.append(
            {
                "type": "success",
                "category": "water",
                "icon": "💧",
                "title": "شرب الماء",
                "message": f"أحسنت! حققت هدف الماء اليومي ({water_today:.1f}ل)",
                "priority": 3,
                "action": None,
                "action_route": None,
            }
        )

    # 2. Nutrition insight
    today_meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_id == user_id,
            func.date(models.Meal.date_time) == func.current_date(),
        )
        .count()
    )
    if today_meals == 0:
        insights.append(
            {
                "type": "warning",
                "category": "nutrition",
                "icon": "🍽️",
                "title": "تسجيل الوجبات",
                "message": "لم تسجل أي وجبة اليوم. تتبع طعامك يساعدك على تحقيق أهدافك",
                "priority": 1,
                "action": "سجل وجبة",
                "action_route": "/nutrition",
            }
        )
    elif today_meals < 3:
        insights.append(
            {
                "type": "info",
                "category": "nutrition",
                "icon": "🍽️",
                "title": "الوجبات",
                "message": f"سجلت {today_meals} وجبات فقط اليوم. حاول تناول 3-5 وجبات متوازنة",
                "priority": 2,
                "action": "سجل المزيد",
                "action_route": "/nutrition",
            }
        )

    # 3. Walking/Activity insight
    today_steps = (
        db.query(func.sum(models.WalkingActivity.steps))
        .filter(
            models.WalkingActivity.user_id == user_id,
            func.date(models.WalkingActivity.date) == func.current_date(),
        )
        .scalar()
        or 0
    )
    if today_steps < 3000:
        insights.append(
            {
                "type": "warning",
                "category": "activity",
                "icon": "🚶",
                "title": "النشاط البدني",
                "message": f"خطواتك اليوم ({today_steps}) قليلة. حاول المشي 30 دقيقة على الأقل",
                "priority": 1,
                "action": "ابدأ المشي",
                "action_route": "/walking",
            }
        )
    elif today_steps >= 10000:
        insights.append(
            {
                "type": "success",
                "category": "activity",
                "icon": "🏆",
                "title": "النشاط البدني",
                "message": f"ممتاز! حققت {today_steps} خطوة اليوم. استمر!",
                "priority": 3,
                "action": None,
                "action_route": None,
            }
        )

    # 4. Medication insight
    missed_doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == user_id,
            models.MedicationDose.status == "missed",
            func.date(models.MedicationDose.scheduled_time) == func.current_date(),
        )
        .count()
    )
    if missed_doses > 0:
        insights.append(
            {
                "type": "danger",
                "category": "medication",
                "icon": "💊",
                "title": "الأدوية",
                "message": f"فاتتك {missed_doses} جرعات اليوم. التزم بمواعيد أدويتك",
                "priority": 1,
                "action": "راجع الأدوية",
                "action_route": "/medications",
            }
        )

    # 5. Weight trend insight
    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )
    if user_nutrition:
        recent_weights = (
            db.query(models.WeightHistory)
            .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
            .order_by(desc(models.WeightHistory.date))
            .limit(7)
            .all()
        )
        if len(recent_weights) >= 2:
            change = recent_weights[0].weight - recent_weights[-1].weight
            days = (recent_weights[0].date - recent_weights[-1].date).days
            if days > 0:
                weekly_rate = change / days * 7
                if user_nutrition.goal == "تخسيس" and weekly_rate < -0.3:
                    insights.append(
                        {
                            "type": "success",
                            "category": "weight",
                            "icon": "📉",
                            "title": "الوزن",
                            "message": f"تقدم ممتاز! تخسر {abs(weekly_rate):.1f} كجم أسبوعياً",
                            "priority": 2,
                            "action": "عرض التفاصيل",
                            "action_route": "/weight",
                        }
                    )
                elif user_nutrition.goal == "تخسيس" and weekly_rate > 0:
                    insights.append(
                        {
                            "type": "warning",
                            "category": "weight",
                            "icon": "📈",
                            "title": "الوزن",
                            "message": f"وزنك يزيد بمعدل {weekly_rate:.1f} كجم أسبوعياً. راجع نظامك",
                            "priority": 1,
                            "action": "تحليل الوزن",
                            "action_route": "/weight",
                        }
                    )

    # 6. Quiz consistency insight
    weekly_quiz_count = (
        db.query(models.DailyQuizSession)
        .filter(
            models.DailyQuizSession.user_id == user_id,
            models.DailyQuizSession.date >= datetime.now() - timedelta(days=7),
        )
        .count()
    )
    if weekly_quiz_count < 7:
        insights.append(
            {
                "type": "info",
                "category": "quiz",
                "icon": "📝",
                "title": "الكويز اليومي",
                "message": f"أكملت {weekly_quiz_count} كويز هذا الأسبوع. الكويز اليومي يساعد في تتبع حالتك",
                "priority": 2,
                "action": "سجل الآن",
                "action_route": "/daily-quiz",
            }
        )

    # 7. Sleep insight (from daily quiz)
    recent_sessions = (
        db.query(models.DailyQuizSession)
        .filter(
            models.DailyQuizSession.user_id == user_id,
            models.DailyQuizSession.date >= datetime.now() - timedelta(days=3),
        )
        .order_by(desc(models.DailyQuizSession.date))
        .limit(3)
        .all()
    )
    if recent_sessions:
        sleep_hours = []
        for session in recent_sessions:
            if session.sleep_hours:
                sleep_hours.append(session.sleep_hours)
        if sleep_hours:
            avg_sleep = np.mean(sleep_hours)
            if avg_sleep < 6:
                insights.append(
                    {
                        "type": "warning",
                        "category": "sleep",
                        "icon": "😴",
                        "title": "النوم",
                        "message": f"معدل نومك {avg_sleep:.1f} ساعات. تحتاج 7-8 ساعات لصحة أفضل",
                        "priority": 1,
                        "action": "نصائح النوم",
                        "action_route": "/sleep-tips",
                    }
                )

    # 8. Dynamic targets insight
    today_target = (
        db.query(models.DynamicDailyTarget)
        .filter(
            models.DynamicDailyTarget.user_id == user_id,
            models.DynamicDailyTarget.date == date.today(),
        )
        .first()
    )
    if today_target:
        # Compare actual vs target for calories
        if today_target.target_calories:
            today_meals_calories = (
                db.query(func.sum(models.Meal.total_calories))
                .filter(
                    models.Meal.user_id == user_id,
                    func.date(models.Meal.date_time) == func.current_date(),
                )
                .scalar()
                or 0
            )
            if today_meals_calories > 0:
                cal_pct = (today_meals_calories / today_target.target_calories) * 100
                if cal_pct > 110:
                    insights.append({
                        "type": "warning",
                        "category": "dynamic_targets",
                        "icon": "🎯",
                        "title": "السعرات الحرارية",
                        "message": f"تجاوزت هدف السعرات ({today_meals_calories:.0f}/{today_target.target_calories:.0f}). حاول الالتزام بالهدف",
                        "priority": 1,
                        "action": "عرض الأهداف",
                        "action_route": "/dynamic-targets",
                    })
                elif cal_pct >= 85:
                    insights.append({
                        "type": "success",
                        "category": "dynamic_targets",
                        "icon": "🎯",
                        "title": "السعرات الحرارية",
                        "message": f"ملتزم بهدف السعرات ({today_meals_calories:.0f}/{today_target.target_calories:.0f})",
                        "priority": 3,
                        "action": None,
                        "action_route": None,
                    })
                elif cal_pct < 50:
                    insights.append({
                        "type": "info",
                        "category": "dynamic_targets",
                        "icon": "🎯",
                        "title": "السعرات الحرارية",
                        "message": f"لم تسجل سعرات كافية ({today_meals_calories:.0f}/{today_target.target_calories:.0f})",
                        "priority": 2,
                        "action": "سجل وجبة",
                        "action_route": "/nutrition",
                    })

        # Compare actual vs target for steps
        if today_target.target_steps:
            if today_steps > 0:
                steps_pct = (today_steps / today_target.target_steps) * 100
                if steps_pct >= 100:
                    insights.append({
                        "type": "success",
                        "category": "dynamic_targets",
                        "icon": "👣",
                        "title": "الخطوات",
                        "message": f"حققت هدف الخطوات! ({today_steps:.0f}/{today_target.target_steps:.0f})",
                        "priority": 3,
                        "action": None,
                        "action_route": None,
                    })
                elif steps_pct < 50:
                    insights.append({
                        "type": "warning",
                        "category": "dynamic_targets",
                        "icon": "👣",
                        "title": "الخطوات",
                        "message": f"متبقي {today_target.target_steps - today_steps:.0f} خطوة لتحقيق هدفك",
                        "priority": 1,
                        "action": "ابدأ المشي",
                        "action_route": "/walking",
                    })

        # Compare actual vs target for water
        if today_target.target_water:
            if water_today > 0:
                water_pct = (water_today / today_target.target_water) * 100
                if water_pct >= 100:
                    insights.append({
                        "type": "success",
                        "category": "dynamic_targets",
                        "icon": "💧",
                        "title": "الماء",
                        "message": f"حققت هدف الماء! ({water_today:.1f}/{today_target.target_water:.1f}ل)",
                        "priority": 3,
                        "action": None,
                        "action_route": None,
                    })

        # Show target change info
        yesterday_target = (
            db.query(models.DynamicDailyTarget)
            .filter(
                models.DynamicDailyTarget.user_id == user_id,
                models.DynamicDailyTarget.date == date.today() - timedelta(days=1),
            )
            .first()
        )
        if yesterday_target:
            changes = []
            cal_diff = today_target.target_calories - yesterday_target.target_calories
            if abs(cal_diff) > 50:
                direction = "زيادة" if cal_diff > 0 else "تقليل"
                changes.append(f"السعرات: {direction} {abs(cal_diff):.0f}")
            steps_diff = today_target.target_steps - yesterday_target.target_steps
            if abs(steps_diff) > 500:
                direction = "زيادة" if steps_diff > 0 else "تقليل"
                changes.append(f"الخطوات: {direction} {abs(steps_diff):.0f}")
            water_diff = today_target.target_water - yesterday_target.target_water
            if abs(water_diff) > 0.2:
                direction = "زيادة" if water_diff > 0 else "تقليل"
                changes.append(f"الماء: {direction} {abs(water_diff):.1f}ل")

            if changes:
                insights.append({
                    "type": "info",
                    "category": "dynamic_targets",
                    "icon": "📊",
                    "title": "تغيير الأهداف اليومية",
                    "message": "تغييرات عن أمس: " + " | ".join(changes),
                    "priority": 2,
                    "action": "التفاصيل",
                    "action_route": "/dynamic-targets",
                })

    # Sort by priority
    insights.sort(key=lambda x: x["priority"])

    return {
        "success": True,
        "insights": insights[:10],
        "total": len(insights),
        "date": datetime.now().isoformat(),
    }


@router.get("/weekly/{user_id}")
@limiter.limit("20/minute")
def get_weekly_insights(request: Request, user_id: int, db: Session = Depends(get_db)):
    """توليد رؤى أسبوعية شاملة"""
    week_ago = datetime.now() - timedelta(days=7)
    insights = []

    # Weekly water average
    water_records = (
        db.query(
            func.date(models.WaterIntake.date_time).label("day"),
            func.sum(models.WaterIntake.amount).label("total"),
        )
        .filter(
            models.WaterIntake.user_id == user_id,
            models.WaterIntake.date_time >= week_ago,
        )
        .group_by(func.date(models.WaterIntake.date_time))
        .all()
    )
    if water_records:
        avg_daily = np.mean([r.total for r in water_records])
        water_settings = (
            db.query(models.WaterSettings)
            .filter(models.WaterSettings.user_id == user_id)
            .first()
        )
        goal = water_settings.daily_goal if water_settings else 2.5
        days_met_goal = sum(1 for r in water_records if r.total >= goal)
        insights.append(
            {
                "type": "success" if days_met_goal >= 5 else "info",
                "category": "water",
                "icon": "💧",
                "title": "تحليل الماء الأسبوعي",
                "message": f"متوسط شربك اليومي {avg_daily:.1f}ل. حققت الهدف {days_met_goal}/7 أيام",
                "priority": 2,
            }
        )

    # Weekly symptoms
    symptom_count = (
        db.query(models.Symptom)
        .filter(models.Symptom.user_id == user_id, models.Symptom.date_time >= week_ago)
        .count()
    )
    if symptom_count > 5:
        insights.append(
            {
                "type": "warning",
                "category": "symptoms",
                "icon": "🤒",
                "title": "الأعراض",
                "message": f"سجلت {symptom_count} عرض هذا الأسبوع. راقب صحتك واستشر طبيباً",
                "priority": 1,
            }
        )
    elif symptom_count == 0:
        insights.append(
            {
                "type": "success",
                "category": "symptoms",
                "icon": "✅",
                "title": "الأعراض",
                "message": "لم تسجل أي أعراض هذا الأسبوع. صحتك تبدو جيدة!",
                "priority": 3,
            }
        )

    # Weekly steps
    weekly_steps = (
        db.query(func.sum(models.WalkingActivity.steps))
        .filter(
            models.WalkingActivity.user_id == user_id,
            models.WalkingActivity.date >= week_ago,
        )
        .scalar()
        or 0
    )
    avg_daily_steps = weekly_steps / 7
    if avg_daily_steps < 5000:
        insights.append(
            {
                "type": "info",
                "category": "activity",
                "icon": "🚶",
                "title": "النشاط الأسبوعي",
                "message": f"متوسط خطواتك اليومي {avg_daily_steps:.0f}. حاول الوصول لـ 8000+ خطوة",
                "priority": 2,
            }
        )

    # Weekly medication adherence
    weekly_doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == user_id,
            models.MedicationDose.scheduled_time >= week_ago,
        )
        .all()
    )
    if weekly_doses:
        taken = sum(1 for d in weekly_doses if d.status == "taken")
        adherence = (taken / len(weekly_doses)) * 100
        if adherence < 80:
            insights.append(
                {
                    "type": "warning",
                    "category": "medication",
                    "icon": "💊",
                    "title": "الالتزام بالأدوية",
                    "message": f"نسبة التزامك بالأدوية {adherence:.0f}%. حاول تحسينها إلى 90%+",
                    "priority": 1,
                }
            )
        elif adherence >= 95:
            insights.append(
                {
                    "type": "success",
                    "category": "medication",
                    "icon": "🏅",
                    "title": "الالتزام بالأدوية",
                    "message": f"التزام ممتاز! {adherence:.0f}% من الجرعات تم تناولها",
                    "priority": 3,
                }
            )

    # Weekly nutrition summary
    weekly_meals = (
        db.query(models.Meal)
        .filter(models.Meal.user_id == user_id, models.Meal.date_time >= week_ago)
        .count()
    )
    if weekly_meals < 14:
        insights.append(
            {
                "type": "info",
                "category": "nutrition",
                "icon": "🥗",
                "title": "التغذية",
                "message": f"سجلت {weekly_meals} وجبة هذا الأسبوع. حاول تسجيل وجبتين على الأقل يومياً",
                "priority": 2,
            }
        )

    # Weekly dynamic targets performance
    weekly_targets = (
        db.query(models.DynamicDailyTarget)
        .filter(
            models.DynamicDailyTarget.user_id == user_id,
            models.DynamicDailyTarget.date >= week_ago,
        )
        .all()
    )
    if weekly_targets:
        avg_cal_target = np.mean([t.target_calories for t in weekly_targets if t.target_calories])
        avg_steps_target = np.mean([t.target_steps for t in weekly_targets if t.target_steps])
        avg_water_target = np.mean([t.target_water for t in weekly_targets if t.target_water])

        # Get weekly performance
        weekly_performance = (
            db.query(models.PerformanceHistory)
            .filter(
                models.PerformanceHistory.user_id == user_id,
                models.PerformanceHistory.date >= week_ago,
            )
            .all()
        )
        if weekly_performance:
            avg_performance = np.mean([p.overall_score for p in weekly_performance])
            trend = "تحسن" if len(weekly_performance) >= 2 and weekly_performance[-1].overall_score > weekly_performance[0].overall_score else "ثبات"
            if avg_performance >= 80:
                insights.append({
                    "type": "success",
                    "category": "dynamic_targets",
                    "icon": "📈",
                    "title": "الأهداف الديناميكية",
                    "message": f"متوسط أدائك {avg_performance:.0f}%. الأهداف تتكيف مع تقدمك! الاتجاه: {trend}",
                    "priority": 2,
                })
            elif avg_performance < 60:
                insights.append({
                    "type": "info",
                    "category": "dynamic_targets",
                    "icon": "📊",
                    "title": "الأهداف الديناميكية",
                    "message": f"متوسط أدائك {avg_performance:.0f}%. الأهداف ستتكيف لمساعدتك على التحسن",
                    "priority": 2,
                })

        # Target variability insight
        if len(weekly_targets) >= 3:
            cal_variability = np.std([t.target_calories for t in weekly_targets if t.target_calories])
            if cal_variability > 200:
                insights.append({
                    "type": "info",
                    "category": "dynamic_targets",
                    "icon": "🔄",
                    "title": "تقلب الأهداف",
                    "message": f"أهداف السعرات تتغير يومياً بناءً على حالتك الصحية وأدائك (تباين: {cal_variability:.0f} سعرة)",
                    "priority": 3,
                })

    insights.sort(key=lambda x: x["priority"])

    return {
        "success": True,
        "insights": insights[:10],
        "total": len(insights),
        "week_start": week_ago.isoformat(),
        "week_end": datetime.now().isoformat(),
    }


@router.get("/summary/{user_id}")
@limiter.limit("20/minute")
def get_health_summary(request: Request, user_id: int, db: Session = Depends(get_db)):
    """ملخص صحي شامل مع توصيات ذكية"""
    week_ago = datetime.now() - timedelta(days=7)

    # Collect all metrics
    water_total = (
        db.query(func.sum(models.WaterIntake.amount))
        .filter(
            models.WaterIntake.user_id == user_id,
            models.WaterIntake.date_time >= week_ago,
        )
        .scalar()
        or 0
    )

    steps_total = (
        db.query(func.sum(models.WalkingActivity.steps))
        .filter(
            models.WalkingActivity.user_id == user_id,
            models.WalkingActivity.date >= week_ago,
        )
        .scalar()
        or 0
    )

    symptoms_count = (
        db.query(models.Symptom)
        .filter(models.Symptom.user_id == user_id, models.Symptom.date_time >= week_ago)
        .count()
    )

    meals_count = (
        db.query(models.Meal)
        .filter(models.Meal.user_id == user_id, models.Meal.date_time >= week_ago)
        .count()
    )

    quiz_count = (
        db.query(models.DailyQuizSession)
        .filter(
            models.DailyQuizSession.user_id == user_id,
            models.DailyQuizSession.date >= week_ago,
        )
        .count()
    )

    # Calculate scores
    water_score = min(100, (water_total / (2.5 * 7)) * 100)
    activity_score = min(100, (steps_total / (8000 * 7)) * 100)
    nutrition_score = min(100, (meals_count / 21) * 100)
    quiz_score = min(100, (quiz_count / 14) * 100)
    symptom_score = max(0, 100 - (symptoms_count * 10))

    overall = (
        water_score * 0.2
        + activity_score * 0.25
        + nutrition_score * 0.25
        + quiz_score * 0.1
        + symptom_score * 0.2
    )

    # Generate recommendations
    recommendations = []
    if water_score < 60:
        recommendations.append("💧 اشرب كمية أكبر من الماء يومياً")
    if activity_score < 50:
        recommendations.append("🚶 زد نشاطك البدني، حاول المشي 30 دقيقة يومياً")
    if nutrition_score < 50:
        recommendations.append("🥗 سجل وجباتك بانتظام لتحسين التغذية")
    if symptoms_count > 3:
        recommendations.append("🩺 استشر طبيباً إذا استمرت الأعراض")

    # Dynamic targets performance score
    weekly_performance = (
        db.query(models.PerformanceHistory)
        .filter(
            models.PerformanceHistory.user_id == user_id,
            models.PerformanceHistory.date >= week_ago,
        )
        .all()
    )
    if weekly_performance:
        dynamic_score = np.mean([p.overall_score for p in weekly_performance])
    else:
        dynamic_score = 0

    # Recalculate overall with dynamic targets
    overall = (
        water_score * 0.15
        + activity_score * 0.15
        + nutrition_score * 0.15
        + quiz_score * 0.1
        + symptom_score * 0.15
        + dynamic_score * 0.3  # 30% weight for dynamic targets performance
    )

    # Enhanced recommendations
    if dynamic_score < 60:
        recommendations.append("🎯 ركز على تحقيق أهدافك اليومية - الأهداف تتكيف مع أدائك")
    elif dynamic_score >= 90:
        recommendations.append("🌟 أداء ممتاز في تحقيق الأهداف! الأهداف ستزداد تحدياً تدريجياً")

    return {
        "success": True,
        "overall_score": round(overall, 1),
        "scores": {
            "water": round(water_score, 1),
            "activity": round(activity_score, 1),
            "nutrition": round(nutrition_score, 1),
            "quiz": round(quiz_score, 1),
            "symptoms": round(symptom_score, 1),
            "dynamic_targets": round(dynamic_score, 1),
        },
        "recommendations": recommendations,
        "period": "weekly",
        "date": datetime.now().isoformat(),
    }
