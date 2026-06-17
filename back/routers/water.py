# backend/routers/water.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta, date
from pydantic import BaseModel

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/water", tags=["water"])


# ============================================
# نماذج Pydantic
# ============================================
class WaterIntakeCreate(BaseModel):
    amount: float
    time: datetime
    notes: Optional[str] = None


class WaterIntakeResponse(BaseModel):
    id: int
    amount: float
    time: datetime
    notes: Optional[str]
    created_at: datetime


class WaterSettingsUpdate(BaseModel):
    daily_goal: Optional[float] = None
    reminder_interval: Optional[int] = None
    reminder_start: Optional[str] = None
    reminder_end: Optional[str] = None
    enable_notifications: Optional[bool] = None
    cup_size: Optional[float] = None




# ============================================
# ✅ 1. تسجيل شرب ماء
# ============================================
@router.post("/log", response_model=WaterIntakeResponse)
def log_water(intake: WaterIntakeCreate, user_id: int, db: Session = Depends(get_db)):
    """تسجيل شرب كمية ماء"""

    db_intake = models.WaterIntake(
        user_id=user_id, amount=intake.amount, time=intake.time, notes=intake.notes
    )
    db.add(db_intake)
    db.commit()
    db.refresh(db_intake)

    # ✅ تحديث إجمالي الماء اليومي في جدول user_nutrition
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())

    total_water = (
        db.query(models.WaterIntake)
        .filter(
            models.WaterIntake.user_id == user_id,
            models.WaterIntake.time.between(today_start, today_end),
        )
        .with_entities(func.sum(models.WaterIntake.amount))
        .scalar()
        or 0
    )

    # تحديث user_nutrition
    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )
    if user_nutrition:
        user_nutrition.water_intake = total_water
        db.commit()

    return db_intake


# ============================================
# ✅ 2. جلب سجل الماء اليومي
# ============================================
@router.get("/today/{user_id}")
def get_today_water(user_id: int, db: Session = Depends(get_db)):
    """جلب سجل شرب الماء لليوم"""

    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())

    intakes = (
        db.query(models.WaterIntake)
        .filter(
            models.WaterIntake.user_id == user_id,
            models.WaterIntake.time.between(today_start, today_end),
        )
        .order_by(models.WaterIntake.time)
        .all()
    )

    total = sum(i.amount for i in intakes)

    # جلب الهدف اليومي
    settings = (
        db.query(models.WaterSettings)
        .filter(models.WaterSettings.user_id == user_id)
        .first()
    )
    daily_goal = settings.daily_goal if settings else 2.5

    # حساب الساعات المتبقية للتذكير
    now = datetime.now()
    remaining_hours = 0
    if settings and settings.reminder_end:
        end_time = datetime.combine(today, settings.reminder_end)
        if now < end_time:
            remaining_hours = (end_time - now).seconds // 3600

    return {
        "date": today.isoformat(),
        "total": total,
        "daily_goal": daily_goal,
        "progress_percentage": min(100, (total / daily_goal) * 100),
        "remaining_goal": max(0, daily_goal - total),
        "intakes": intakes,
        "next_reminder_in_hours": remaining_hours,
        "cup_size": settings.cup_size if settings else 0.25,
    }


# ============================================
# ✅ 3. جلب إحصائيات الماء (أسبوعي - شهري - سنوي)
# ============================================
@router.get("/stats/{user_id}")
def get_water_stats(
    user_id: int,
    period: str = "week",  # week, month, year
    db: Session = Depends(get_db),
):
    """جلب إحصائيات شرب الماء"""

    now = datetime.now()

    if period == "week":
        start_date = now - timedelta(days=7)
        format = "%a"  # يوم الأسبوع
    elif period == "month":
        start_date = now - timedelta(days=30)
        format = "%d/%m"
    else:  # year
        start_date = now - timedelta(days=365)
        format = "%b"  # شهر

    stats = (
        db.query(
            func.date(models.WaterIntake.time).label("date"),
            func.sum(models.WaterIntake.amount).label("total"),
        )
        .filter(
            models.WaterIntake.user_id == user_id, models.WaterIntake.time >= start_date
        )
        .group_by(func.date(models.WaterIntake.time))
        .all()
    )

    # جلب الهدف اليومي
    settings = (
        db.query(models.WaterSettings)
        .filter(models.WaterSettings.user_id == user_id)
        .first()
    )
    daily_goal = settings.daily_goal if settings else 2.5

    # حساب أفضل يوم
    best_day = max(stats, key=lambda x: x.total) if stats else None

    # حساب متوسط الأيام الأخيرة
    last_7_days = [s for s in stats if s.date >= (now - timedelta(days=7)).date()]
    avg_last_7_days = sum(s.total for s in last_7_days) / 7 if last_7_days else 0

    return {
        "period": period,
        "daily_goal": daily_goal,
        "stats": [
            {"date": s.date.strftime(format), "total": s.total, "goal": daily_goal}
            for s in stats
        ],
        "best_day": {
            "date": best_day.date.isoformat() if best_day else None,
            "total": best_day.total if best_day else 0,
        },
        "average_last_7_days": round(avg_last_7_days, 1),
        "total_days_with_water": len(stats),
    }


# ============================================
# ✅ 4. إعدادات تذكير الماء
# ============================================
@router.put("/settings/{user_id}")
def update_water_settings(
    user_id: int, settings: WaterSettingsUpdate, db: Session = Depends(get_db)
):
    """تحديث إعدادات شرب الماء"""

    db_settings = (
        db.query(models.WaterSettings)
        .filter(models.WaterSettings.user_id == user_id)
        .first()
    )

    if not db_settings:
        db_settings = models.WaterSettings(user_id=user_id)
        db.add(db_settings)

    if settings.daily_goal is not None:
        db_settings.daily_goal = settings.daily_goal
    if settings.reminder_interval is not None:
        db_settings.reminder_interval = settings.reminder_interval
    if settings.reminder_start is not None:
        db_settings.reminder_start = datetime.strptime(
            settings.reminder_start, "%H:%M"
        ).time()
    if settings.reminder_end is not None:
        db_settings.reminder_end = datetime.strptime(
            settings.reminder_end, "%H:%M"
        ).time()
    if settings.enable_notifications is not None:
        db_settings.enable_notifications = settings.enable_notifications
    if settings.cup_size is not None:
        db_settings.cup_size = settings.cup_size

    db.commit()

    return {"success": True, "message": "تم تحديث الإعدادات"}


# ============================================
# ✅ 5. حذف تسجيل ماء
# ============================================
@router.delete("/{intake_id}")
def delete_water_intake(intake_id: int, db: Session = Depends(get_db)):
    """حذف تسجيل شرب ماء"""

    intake = (
        db.query(models.WaterIntake).filter(models.WaterIntake.id == intake_id).first()
    )

    if not intake:
        raise HTTPException(status_code=404, detail="التسجيل غير موجود")

    db.delete(intake)
    db.commit()

    return {"success": True, "message": "تم حذف التسجيل"}
