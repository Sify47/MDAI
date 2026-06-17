# backend/routers/weight.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from typing import List, Optional
from datetime import datetime, date, timedelta
from pydantic import BaseModel
from decimal import Decimal

from database import get_db
import models
from routers.auth import get_current_user

router = APIRouter(prefix="/api/weight", tags=["weight"])


# ============================================
# Pydantic Models
# ============================================


class WeightLogCreate(BaseModel):
    weight: float
    date: str  # YYYY-MM-DD
    notes: Optional[str] = None


class WeightLogResponse(BaseModel):
    id: int
    weight: float
    date: str
    notes: Optional[str] = None
    created_at: datetime


class WeightProgressResponse(BaseModel):
    success: bool
    need_more_data: bool
    is_loss: bool
    change_kg: float
    start_weight: float
    end_weight: float
    start_date: str
    end_date: str
    message: str
    weight_history: List[dict]


class WeightStatsResponse(BaseModel):
    success: bool
    current_weight: float
    previous_weight: Optional[float]
    average_weight: float
    max_weight: float
    min_weight: float
    change: float
    total_records: int


# ============================================
# Helper Functions
# ============================================


def get_user_nutrition(db: Session, user_id: int) -> models.UserNutrition:
    """جلب بيانات التغذية للمستخدم"""
    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )

    if not user_nutrition:
        raise HTTPException(
            status_code=404,
            detail="بيانات المستخدم غير موجودة. يرجى إكمال الإعداد الأولي",
        )
    return user_nutrition


# ============================================
# ✅ 1. تسجيل وزن جديد (إضافة سجل + تحديث الوزن الحالي)
# ============================================


@router.post("/log", status_code=201, response_model=dict)
def log_weight(
    weight_data: WeightLogCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تسجيل وزن جديد - يضيف سجل في history ويحدث الوزن الحالي"""
    print(
        f"📝 [Weight] تسجيل وزن جديد للمستخدم {current_user.id}: {weight_data.weight} كجم"
    )

    # 1. جلب بيانات التغذية للمستخدم
    user_nutrition = get_user_nutrition(db, current_user.id)

    # 2. تحويل التاريخ
    try:
        record_date = datetime.strptime(weight_data.date, "%Y-%m-%d").date()
    except:
        record_date = date.today()

    # 3. ✅ إضافة سجل جديد في weight_history
    new_record = models.WeightHistory(
        user_nutrition_id=user_nutrition.id,
        weight=weight_data.weight,
        date=record_date,
        notes=weight_data.notes,
    )
    db.add(new_record)

    # 4. ✅ تحديث الوزن الحالي في user_nutrition
    user_nutrition.weight = weight_data.weight
    user_nutrition.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(new_record)

    print(f"✅ [Weight] تم إضافة سجل جديد ID: {new_record.id}")

    return {
        "success": True,
        "message": "تم تسجيل الوزن بنجاح",
        "id": new_record.id,
        "weight": new_record.weight,
        "date": new_record.date.isoformat(),
    }


# ============================================
# ✅ 2. جلب سجل الوزن التاريخي
# ============================================


@router.get("/history", response_model=List[dict])
def get_weight_history(
    limit: int = 30,
    offset: int = 0,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب سجل الوزن التاريخي للمستخدم"""
    print(f"🔍 [Weight] جلب سجل الوزن للمستخدم {current_user.id}")

    user_nutrition = get_user_nutrition(db, current_user.id)

    history = (
        db.query(models.WeightHistory)
        .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
        .order_by(desc(models.WeightHistory.date))
        .offset(offset)
        .limit(limit)
        .all()
    )

    result = []
    for record in history:
        result.append(
            {
                "id": record.id,
                "weight": record.weight,
                "date": record.date.isoformat(),
                "notes": record.notes,
                "created_at": (
                    record.created_at.isoformat() if record.created_at else None
                ),
            }
        )

    print(f"✅ [Weight] تم جلب {len(result)} سجل")
    return result


# ============================================
# ✅ 3. جلب آخر وزن مسجل
# ============================================


@router.get("/latest")
def get_latest_weight(
    current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """جلب آخر وزن مسجل للمستخدم"""
    print(f"🔍 [Weight] جلب آخر وزن للمستخدم {current_user.id}")

    user_nutrition = get_user_nutrition(db, current_user.id)

    latest = (
        db.query(models.WeightHistory)
        .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
        .order_by(desc(models.WeightHistory.date))
        .first()
    )

    return {
        "success": True,
        "weight": latest.weight if latest else user_nutrition.weight,
        "date": latest.date.isoformat() if latest else None,
        "has_history": latest is not None,
    }


# ============================================
# ✅ 4. حساب تقدم الوزن
# ============================================


@router.get("/progress", response_model=WeightProgressResponse)
def get_weight_progress(
    period: str = "week",  # week, month, 3months
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حساب تقدم الوزن خلال فترة محددة"""
    print(f"📊 [Weight] حساب تقدم الوزن - الفترة: {period}")

    user_nutrition = get_user_nutrition(db, current_user.id)

    # تحديد نطاق التاريخ
    today = date.today()
    if period == "week":
        start = today - timedelta(days=7)
        end = today
    elif period == "month":
        start = today - timedelta(days=30)
        end = today
    elif period == "3months":
        start = today - timedelta(days=90)
        end = today
    elif period == "custom" and start_date and end_date:
        start = datetime.strptime(start_date, "%Y-%m-%d").date()
        end = datetime.strptime(end_date, "%Y-%m-%d").date()
    else:
        start = today - timedelta(days=7)
        end = today

    # جلب السجلات في النطاق
    records = (
        db.query(models.WeightHistory)
        .filter(
            models.WeightHistory.user_nutrition_id == user_nutrition.id,
            models.WeightHistory.date.between(start, end),
        )
        .order_by(models.WeightHistory.date)
        .all()
    )

    # إذا لم توجد سجلات كافية
    if len(records) < 2:
        return WeightProgressResponse(
            success=False,
            need_more_data=True,
            is_loss=False,
            change_kg=0,
            start_weight=user_nutrition.weight,
            end_weight=user_nutrition.weight,
            start_date=start.isoformat(),
            end_date=end.isoformat(),
            message="لا توجد بيانات كافية. سجل وزنك مرتين على الأقل خلال هذه الفترة",
            weight_history=[],
        )

    # حساب التقدم
    start_weight = records[0].weight
    end_weight = records[-1].weight
    change_kg = end_weight - start_weight
    is_loss = change_kg < 0

    # بناء رسالة
    if is_loss:
        message = f"✅ ممتاز! لقد خسرت {abs(change_kg):.1f} كجم خلال هذه الفترة"
    elif change_kg > 0:
        message = f"⚠️ لقد زاد وزنك {change_kg:.1f} كجم خلال هذه الفترة"
    else:
        message = "✅ وزنك مستقر خلال هذه الفترة"

    # بناء تاريخ الوزن للرسم البياني
    weight_history = []
    for record in records:
        weight_history.append(
            {"date": record.date.isoformat(), "weight": record.weight}
        )

    return WeightProgressResponse(
        success=True,
        need_more_data=False,
        is_loss=is_loss,
        change_kg=abs(change_kg),
        start_weight=start_weight,
        end_weight=end_weight,
        start_date=start.isoformat(),
        end_date=end.isoformat(),
        message=message,
        weight_history=weight_history,
    )


# ============================================
# ✅ 5. إحصائيات الوزن
# ============================================


@router.get("/stats", response_model=WeightStatsResponse)
def get_weight_stats(
    days: int = 30,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إحصائيات الوزن لآخر عدد محدد من الأيام"""
    print(f"📊 [Weight] إحصائيات الوزن لآخر {days} يوم")

    user_nutrition = get_user_nutrition(db, current_user.id)

    since_date = date.today() - timedelta(days=days)

    records = (
        db.query(models.WeightHistory)
        .filter(
            models.WeightHistory.user_nutrition_id == user_nutrition.id,
            models.WeightHistory.date >= since_date,
        )
        .order_by(models.WeightHistory.date)
        .all()
    )

    if not records:
        return WeightStatsResponse(
            success=True,
            current_weight=user_nutrition.weight,
            previous_weight=None,
            average_weight=user_nutrition.weight,
            max_weight=user_nutrition.weight,
            min_weight=user_nutrition.weight,
            change=0,
            total_records=0,
        )

    weights = [r.weight for r in records]
    previous_weight = records[-2].weight if len(records) >= 2 else None

    return WeightStatsResponse(
        success=True,
        current_weight=records[-1].weight,
        previous_weight=previous_weight,
        average_weight=sum(weights) / len(weights),
        max_weight=max(weights),
        min_weight=min(weights),
        change=records[-1].weight - records[0].weight,
        total_records=len(records),
    )


# ============================================
# ✅ 6. توقع الوزن (مع مراعاة هدف المستخدم)
# ============================================


@router.get("/predict")
def predict_weight(
    weeks_ahead: int = 4,
    goal: str = "تخسيس",  # ✅ إضافة معامل الهدف
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """توقع الوزن بعد عدد محدد من الأسابيع بناءً على التاريخ وهدف المستخدم"""
    print(f"🔮 [Weight] توقع الوزن بعد {weeks_ahead} أسابيع (الهدف: {goal})")

    user_nutrition = get_user_nutrition(db, current_user.id)

    # جلب آخر 30 يوم من سجل الوزن
    records = (
        db.query(models.WeightHistory)
        .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
        .order_by(desc(models.WeightHistory.date))
        .limit(30)
        .all()
    )

    current_weight = user_nutrition.weight

    if len(records) < 2:
        return {
            "success": True,
            "current_weight": current_weight,
            "predicted_weight": current_weight,
            "message": "لا توجد بيانات كافية للتوقع. سجل وزنك بانتظام للحصول على توقعات دقيقة.",
        }

    # حساب متوسط التغير الأسبوعي
    total_change = 0
    for i in range(len(records) - 1):
        change = records[i].weight - records[i + 1].weight
        total_change += change

    avg_weekly_change = total_change / (len(records) - 1)

    # ✅ تعديل التوقع بناءً على هدف المستخدم
    is_gain_goal = goal == "زيادة"

    if is_gain_goal:
        # ✅ هدف زيادة: نتوقع زيادة الوزن
        if avg_weekly_change < 0:
            # إذا كان التاريخ يظهر خسارة، نستخدم تقدير إيجابي صغير
            predicted_weight = current_weight + 0.3 * weeks_ahead
            message = f"⚠️ بناءً على تاريخك، أنت في مرحلة خسارة. لتحقيق هدف الزيادة، تحتاج إلى زيادة سعراتك. التقدير: {predicted_weight:.1f} كجم بعد {weeks_ahead} أسبوع"
        else:
            predicted_weight = current_weight + (avg_weekly_change * weeks_ahead)
            message = f"📈 بناءً على تاريخك، من المتوقع أن يزيد وزنك إلى {predicted_weight:.1f} كجم بعد {weeks_ahead} أسبوع"
    else:
        # ✅ هدف تخسيس: نتوقع خسارة الوزن
        if avg_weekly_change > 0:
            # إذا كان التاريخ يظهر زيادة، نستخدم تقدير سلبي صغير
            predicted_weight = current_weight - 0.3 * weeks_ahead
            message = f"⚠️ بناءً على تاريخك، أنت في مرحلة زيادة. لتحقيق هدف التخسيس، تحتاج إلى تقليل سعراتك. التقدير: {predicted_weight:.1f} كجم بعد {weeks_ahead} أسبوع"
        else:
            predicted_weight = current_weight + (avg_weekly_change * weeks_ahead)
            message = f"📉 بناءً على تاريخك، من المتوقع أن ينقص وزنك إلى {predicted_weight:.1f} كجم بعد {weeks_ahead} أسبوع"

    # التأكد من أن الوزن المتوقع منطقي (بين 30 و 200 كجم)
    predicted_weight = max(30.0, min(predicted_weight, 200.0))

    return {
        "success": True,
        "current_weight": current_weight,
        "predicted_weight": predicted_weight,
        "weekly_change_rate": abs(avg_weekly_change),
        "message": message,
    }


# ============================================
# ✅ 7. حذف سجل وزن
# ============================================


@router.delete("/{weight_id}")
def delete_weight_entry(
    weight_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حذف سجل وزن محدد"""
    print(f"🗑️ [Weight] حذف سجل وزن ID: {weight_id}")

    # البحث عن السجل
    record = (
        db.query(models.WeightHistory)
        .filter(models.WeightHistory.id == weight_id)
        .first()
    )

    if not record:
        raise HTTPException(status_code=404, detail="سجل الوزن غير موجود")

    # التحقق من ملكية السجل
    user_nutrition = get_user_nutrition(db, current_user.id)
    if record.user_nutrition_id != user_nutrition.id:
        raise HTTPException(status_code=403, detail="غير مصرح لك بحذف هذا السجل")

    db.delete(record)

    # تحديث الوزن الحالي لآخر سجل متبقي
    latest = (
        db.query(models.WeightHistory)
        .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
        .order_by(desc(models.WeightHistory.date))
        .first()
    )

    if latest:
        user_nutrition.weight = latest.weight
    else:
        # إذا لم يتبق سجلات، احتفظ بآخر وزن معروف
        pass

    db.commit()

    return {"success": True, "message": "تم حذف السجل بنجاح"}
