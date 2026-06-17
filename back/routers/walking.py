# backend/routers/walking.py

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_  # ✅ أضف هذا السطر
from typing import List, Optional
from datetime import date, datetime, timedelta
from pydantic import BaseModel

from database import get_db
import models
from routers.auth import get_current_user

router = APIRouter(prefix="/walking", tags=["walking"])


# ============================================
# Pydantic Models
# ============================================
class WalkingActivityCreate(BaseModel):
    steps: int
    distance_km: float = 0
    duration_minutes: int = 0
    calories_burned: int = 0
    activity_type: str = "walking"
    activity_date: date
    activity_time: str = "00:00"
    notes: str = ""


class WalkingActivityUpdate(BaseModel):
    steps: int
    distance_km: float = 0
    duration_minutes: int = 0
    calories_burned: int = 0
    notes: str = ""


# ============================================
# ✅ حساب تأثير الأعراض والأدوية على المشي
# ============================================
@router.get("/calculate-impact")
def calculate_walking_impact(
    user_id: int = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حساب تأثير الأعراض والأدوية على هدف المشي"""

    # استخدام user_id من المعامل أو من التوكن
    target_user_id = user_id if user_id else current_user.id

    print(f"🔍 [Walking] حساب التأثير للمستخدم {target_user_id}")

    # التحقق من صلاحية الوصول
    if (
        current_user.id != target_user_id
        and getattr(current_user, "role", "user") != "admin"
    ):
        raise HTTPException(
            status_code=403, detail="غير مصرح بالوصول إلى بيانات مستخدم آخر"
        )

    # جلب بيانات المستخدم
    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == target_user_id)
        .first()
    )

    if not user_nutrition:
        return {
            "success": True,
            "base_goal": 8000,
            "adjusted_goal": 8000,
            "total_impact_percentage": 0,
            "impact_details": [],
            "active_symptoms_count": 0,
            "active_medications_count": 0,
            "message": "لا توجد بيانات كافية للتأثير",
        }

    # الهدف الأساسي
    base_goal = user_nutrition.daily_steps_goal or 8000

    # جلب الأعراض النشطة (آخر 7 أيام)
    seven_days_ago = datetime.now() - timedelta(days=7)
    active_symptoms = (
        db.query(models.Symptom)
        .filter(
            models.Symptom.user_id == target_user_id,
            models.Symptom.created_at >= seven_days_ago,
        )
        .all()
    )

    # جلب أدوية المستخدم النشطة
    today = date.today()
    user_medications = (
        db.query(models.Medication)
        .filter(
            models.Medication.user_id == target_user_id,
            models.Medication.start_date <= today,
            or_(  # ✅ استخدام or_ المستورد من sqlalchemy
                models.Medication.end_date >= today,
                models.Medication.end_date == None,
            ),
        )
        .all()
    )

    # حساب التأثيرات
    total_impact = 0
    impact_details = []

    # 1. تأثير الأعراض
    for symptom in active_symptoms:
        impact = _get_symptom_impact(db, symptom.name, symptom.severity)
        if impact != 0:
            total_impact += impact
            impact_details.append(
                {
                    "type": "symptom",
                    "name": symptom.name,
                    "severity": symptom.severity,
                    "impact": impact,
                }
            )

    # 2. تأثير الأدوية
    for med in user_medications:
        if med.medicine_id:
            impact = _get_medicine_impact_by_id(db, med.medicine_id)
            if impact != 0:
                medicine = (
                    db.query(models.Medicine)
                    .filter(models.Medicine.id == med.medicine_id)
                    .first()
                )
                total_impact += impact
                impact_details.append(
                    {
                        "type": "medicine",
                        "name": medicine.name_ar if medicine else "دواء",
                        "impact": impact,
                    }
                )

    # 3. تأثير الأمراض المزمنة
    if user_nutrition.diseases:
        for disease in user_nutrition.diseases:
            impact = _get_disease_impact(db, disease)
            if impact != 0:
                total_impact += impact
                impact_details.append(
                    {"type": "disease", "name": disease, "impact": impact}
                )

    # حساب الهدف المعدل
    adjusted_goal = base_goal + int(base_goal * total_impact / 100)

    # التأكد من أن الهدف ضمن الحدود المنطقية
    adjusted_goal = max(2000, min(adjusted_goal, 15000))

    return {
        "success": True,
        "base_goal": base_goal,
        "adjusted_goal": adjusted_goal,
        "total_impact_percentage": total_impact,
        "impact_details": impact_details,
        "active_symptoms_count": len(active_symptoms),
        "active_medications_count": len(user_medications),
    }


# ============================================
# دوال مساعدة
# ============================================


def _get_symptom_impact(db: Session, symptom_name: str, severity: str) -> int:
    """جلب تأثير العرض من قاعدة البيانات"""
    impact_factor = (
        db.query(models.HealthImpactFactor)
        .filter(
            models.HealthImpactFactor.factor_type == "symptom",
            models.HealthImpactFactor.factor_name == symptom_name,
            or_(
                models.HealthImpactFactor.severity_level == severity,
                models.HealthImpactFactor.severity_level == "",
            ),
        )
        .first()
    )

    return impact_factor.impact_on_steps if impact_factor else 0


def _get_medicine_impact_by_id(db: Session, medicine_id: int) -> int:
    """جلب تأثير الدواء من قاعدة البيانات باستخدام medicine_id"""
    impact_factor = (
        db.query(models.HealthImpactFactor)
        .filter(
            models.HealthImpactFactor.factor_type == "medicine",
            models.HealthImpactFactor.factor_id == medicine_id,
        )
        .first()
    )

    return impact_factor.impact_on_steps if impact_factor else 0


def _get_medicine_impact_by_name(db: Session, medicine_name: str) -> int:
    """جلب تأثير الدواء من قاعدة البيانات باستخدام الاسم"""
    impact_factor = (
        db.query(models.HealthImpactFactor)
        .filter(
            models.HealthImpactFactor.factor_type == "medicine",
            models.HealthImpactFactor.factor_name == medicine_name,
        )
        .first()
    )

    return impact_factor.impact_on_steps if impact_factor else 0


def _get_disease_impact(db: Session, disease_name: str) -> int:
    """جلب تأثير المرض من قاعدة البيانات"""
    impact_factor = (
        db.query(models.HealthImpactFactor)
        .filter(
            models.HealthImpactFactor.factor_type == "disease",
            models.HealthImpactFactor.factor_name == disease_name,
        )
        .first()
    )

    return impact_factor.impact_on_steps if impact_factor else 0


# ============================================
# GET /walking - جلب كل أنشطة المشي للمستخدم الحالي
# ============================================
@router.get("/")
def get_all_activities(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب كل أنشطة المشي للمستخدم الحالي"""
    print(f"🔍 جلب كل أنشطة المشي للمستخدم: {current_user.id}")

    activities = (
        db.query(models.WalkingActivity)
        .filter(models.WalkingActivity.user_id == current_user.id)
        .order_by(
            models.WalkingActivity.activity_date.desc(),
            models.WalkingActivity.activity_time.desc(),
        )
        .all()
    )
    return [act.to_dict() for act in activities]


# ============================================
# GET /walking/today - جلب أنشطة اليوم للمستخدم الحالي
# ============================================
@router.get("/today")
def get_today_activities(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
    date_str: Optional[str] = Query(None, description="تاريخ اليوم بصيغة YYYY-MM-DD (توقيت المستخدم المحلي)"),
):
    """جلب أنشطة اليوم للمستخدم الحالي"""
    print(f"🔍 جلب أنشطة اليوم للمستخدم: {current_user.id}")

    if date_str:
        try:
            today = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            today = date.today()
    else:
        today = date.today()
    
    activities = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == current_user.id,
            models.WalkingActivity.activity_date == today,
        )
        .order_by(models.WalkingActivity.activity_time.desc())
        .all()
    )
    return [act.to_dict() for act in activities]


# ============================================
# GET /walking/week - جلب أنشطة آخر 7 أيام للمستخدم الحالي
# ============================================
@router.get("/week")
def get_week_activities(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
    date_str: Optional[str] = Query(None, description="تاريخ اليوم بصيغة YYYY-MM-DD (توقيت المستخدم المحلي)"),
):
    """جلب أنشطة آخر 7 أيام للمستخدم الحالي"""
    print(f"🔍 جلب أنشطة الأسبوع للمستخدم: {current_user.id}")

    if date_str:
        try:
            today = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            today = date.today()
    else:
        today = date.today()
    week_ago = today - timedelta(days=7)
    activities = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == current_user.id,
            models.WalkingActivity.activity_date >= week_ago,
        )
        .order_by(models.WalkingActivity.activity_date.desc())
        .all()
    )
    return [act.to_dict() for act in activities]


# ============================================
# GET /walking/stats - إحصائيات المشي للمستخدم الحالي
# ============================================
@router.get("/stats")
def get_walking_stats(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
    date_str: Optional[str] = Query(None, description="تاريخ اليوم بصيغة YYYY-MM-DD (توقيت المستخدم المحلي)"),
):
    """إحصائيات المشي للمستخدم الحالي"""
    print(f"🔍 جلب إحصائيات المشي للمستخدم: {current_user.id}")

    if date_str:
        try:
            today = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            today = date.today()
    else:
        today = date.today()
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)

    # كل الأنشطة للمستخدم
    all_activities = (
        db.query(models.WalkingActivity)
        .filter(models.WalkingActivity.user_id == current_user.id)
        .all()
    )

    # أنشطة اليوم
    today_activities = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == current_user.id,
            models.WalkingActivity.activity_date == today,
        )
        .all()
    )
    today_steps = sum(a.steps for a in today_activities)

    # أنشطة الأسبوع
    week_activities = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == current_user.id,
            models.WalkingActivity.activity_date >= week_ago,
        )
        .all()
    )
    week_steps = sum(a.steps for a in week_activities)

    # أنشطة الشهر
    month_activities = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == current_user.id,
            models.WalkingActivity.activity_date >= month_ago,
        )
        .all()
    )
    month_steps = sum(a.steps for a in month_activities)

    # متوسط الخطوات
    total_activities = len(all_activities)
    avg_steps = (
        (sum(a.steps for a in all_activities) / total_activities)
        if total_activities > 0
        else 0
    )

    # أفضل يوم
    steps_by_day = {}
    for act in all_activities:
        steps_by_day[act.activity_date] = (
            steps_by_day.get(act.activity_date, 0) + act.steps
        )

    best_day = (
        max(steps_by_day.items(), key=lambda x: x[1]) if steps_by_day else (None, 0)
    )

    return {
        "total_activities": total_activities,
        "total_steps": sum(a.steps for a in all_activities),
        "total_distance": sum(a.distance_km or 0 for a in all_activities),
        "total_calories": sum(a.calories_burned or 0 for a in all_activities),
        "today_steps": today_steps,
        "week_steps": week_steps,
        "month_steps": month_steps,
        "average_steps": round(avg_steps),
        "best_day": best_day[0].isoformat() if best_day[0] else None,
        "best_day_steps": best_day[1],
    }


# ============================================
# POST /walking - إضافة نشاط مشي جديد للمستخدم الحالي
# ============================================
@router.post("/", status_code=201)
def create_activity(
    activity: WalkingActivityCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إضافة نشاط مشي جديد للمستخدم الحالي"""
    print(f"📝 إضافة نشاط مشي للمستخدم: {current_user.id}")

    time_parts = activity.activity_time.split(":")
    hour = int(time_parts[0]) if len(time_parts) > 0 else 0
    minute = int(time_parts[1]) if len(time_parts) > 1 else 0
    activity_time = datetime.strptime(f"{hour}:{minute}", "%H:%M").time()

    db_activity = models.WalkingActivity(
        user_id=current_user.id,
        steps=activity.steps,
        distance_km=activity.distance_km,
        duration_minutes=activity.duration_minutes,
        calories_burned=activity.calories_burned,
        activity_type=activity.activity_type,
        activity_date=activity.activity_date,
        activity_time=activity_time,
        notes=activity.notes,
    )
    db.add(db_activity)
    db.commit()
    db.refresh(db_activity)

    return db_activity.to_dict()


# ============================================
# PUT /walking/{id} - تحديث نشاط
# ============================================
@router.put("/{id}")
def update_activity(
    id: int,
    activity: WalkingActivityUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تحديث نشاط"""
    print(f"📝 تحديث نشاط {id} للمستخدم: {current_user.id}")

    db_activity = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.id == id,
            models.WalkingActivity.user_id == current_user.id,
        )
        .first()
    )
    if not db_activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")

    db_activity.steps = activity.steps
    db_activity.distance_km = activity.distance_km
    db_activity.duration_minutes = activity.duration_minutes
    db_activity.calories_burned = activity.calories_burned
    db_activity.notes = activity.notes

    db.commit()
    db.refresh(db_activity)

    return db_activity.to_dict()


# ============================================
# DELETE /walking/{id} - حذف نشاط
# ============================================
@router.delete("/{id}")
def delete_activity(
    id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حذف نشاط"""
    print(f"🗑️ حذف نشاط {id} للمستخدم: {current_user.id}")

    db_activity = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.id == id,
            models.WalkingActivity.user_id == current_user.id,
        )
        .first()
    )
    if not db_activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")

    db.delete(db_activity)
    db.commit()
    return {"message": "تم حذف النشاط بنجاح"}
