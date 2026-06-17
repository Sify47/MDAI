# backend/routers/activity_plans.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/plans", tags=["activity_plans"])


# ============================================
# ✅ 1. جلب كل الخطط النشطة لمستخدم
# ============================================
@router.get("/", response_model=List[schemas.ActivityPlanResponse])
def get_plans(
    user_id: int = Query(..., description="معرف المستخدم"),
    is_active: Optional[bool] = Query(None, description="تصفية حسب الحالة"),
    db: Session = Depends(get_db),
):
    """جلب كل خطط الأنشطة لمستخدم معين"""
    print(f"\n📋 [ActivityPlans] جلب الخطط للمستخدم {user_id}")

    query = db.query(models.ActivityPlan).filter(models.ActivityPlan.user_id == user_id)

    if is_active is not None:
        query = query.filter(models.ActivityPlan.is_active == is_active)

    plans = query.order_by(models.ActivityPlan.created_at.desc()).all()
    print(f"✅ تم جلب {len(plans)} خطة")
    return plans


# ============================================
# ✅ 2. جلب خطة محددة
# ============================================
@router.get("/{plan_id}", response_model=schemas.ActivityPlanResponse)
def get_plan(
    plan_id: int,
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """جلب خطة نشاط محددة"""
    print(f"\n📋 [ActivityPlans] جلب خطة {plan_id}")

    plan = (
        db.query(models.ActivityPlan)
        .filter(
            models.ActivityPlan.id == plan_id,
            models.ActivityPlan.user_id == user_id,
        )
        .first()
    )

    if not plan:
        raise HTTPException(status_code=404, detail="الخطة غير موجودة")

    return plan


# ============================================
# ✅ 3. إنشاء خطة جديدة
# ============================================
@router.post("/", response_model=schemas.ActivityPlanResponse, status_code=201)
def create_plan(
    plan_data: schemas.ActivityPlanCreate,
    db: Session = Depends(get_db),
):
    """إنشاء خطة نشاط جديدة"""
    print(f"\n📋 [ActivityPlans] إنشاء خطة جديدة للمستخدم {plan_data.user_id}")

    # التحقق من صحة التواريخ
    if plan_data.end_date <= plan_data.start_date:
        raise HTTPException(
            status_code=400,
            detail="تاريخ النهاية يجب أن يكون بعد تاريخ البداية",
        )

    # حساب عدد الأيام لتحديد النوع تلقائياً إذا كان مخصص
    days_diff = (plan_data.end_date - plan_data.start_date).days
    if days_diff < 1:
        raise HTTPException(
            status_code=400,
            detail="يجب أن تكون مدة الخطة يوم واحد على الأقل",
        )

    plan = models.ActivityPlan(
        user_id=plan_data.user_id,
        name=plan_data.name,
        description=plan_data.description,
        plan_type=plan_data.plan_type,
        start_date=plan_data.start_date,
        end_date=plan_data.end_date,
        is_active=plan_data.is_active,
    )

    db.add(plan)
    db.commit()
    db.refresh(plan)

    print(f"✅ تم إنشاء الخطة {plan.id}")
    return plan


# ============================================
# ✅ 4. تحديث خطة
# ============================================
@router.put("/{plan_id}", response_model=schemas.ActivityPlanResponse)
def update_plan(
    plan_id: int,
    plan_data: schemas.ActivityPlanUpdate,
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """تحديث خطة نشاط موجودة"""
    print(f"\n📋 [ActivityPlans] تحديث خطة {plan_id}")

    plan = (
        db.query(models.ActivityPlan)
        .filter(
            models.ActivityPlan.id == plan_id,
            models.ActivityPlan.user_id == user_id,
        )
        .first()
    )

    if not plan:
        raise HTTPException(status_code=404, detail="الخطة غير موجودة")

    # تحديث الحقول المقدمة فقط
    update_data = plan_data.model_dump(exclude_unset=True)

    # التحقق من صحة التواريخ إذا تم تحديثها
    if "start_date" in update_data and "end_date" in update_data:
        if update_data["end_date"] <= update_data["start_date"]:
            raise HTTPException(
                status_code=400,
                detail="تاريخ النهاية يجب أن يكون بعد تاريخ البداية",
            )
    elif "start_date" in update_data and plan.end_date:
        if plan.end_date <= update_data["start_date"]:
            raise HTTPException(
                status_code=400,
                detail="تاريخ النهاية يجب أن يكون بعد تاريخ البداية",
            )
    elif "end_date" in update_data and plan.start_date:
        if update_data["end_date"] <= plan.start_date:
            raise HTTPException(
                status_code=400,
                detail="تاريخ النهاية يجب أن يكون بعد تاريخ البداية",
            )

    for key, value in update_data.items():
        setattr(plan, key, value)

    plan.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(plan)

    print(f"✅ تم تحديث الخطة {plan.id}")
    return plan


# ============================================
# ✅ 5. حذف خطة
# ============================================
@router.delete("/{plan_id}")
def delete_plan(
    plan_id: int,
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """حذف خطة نشاط"""
    print(f"\n📋 [ActivityPlans] حذف خطة {plan_id}")

    plan = (
        db.query(models.ActivityPlan)
        .filter(
            models.ActivityPlan.id == plan_id,
            models.ActivityPlan.user_id == user_id,
        )
        .first()
    )

    if not plan:
        raise HTTPException(status_code=404, detail="الخطة غير موجودة")

    db.delete(plan)
    db.commit()

    print(f"✅ تم حذف الخطة {plan_id}")
    return {"message": "تم حذف الخطة بنجاح", "id": plan_id}


# ============================================
# ✅ 6. تحديث تقدم الخطة
# ============================================
@router.patch("/{plan_id}/progress", response_model=schemas.ActivityPlanResponse)
def update_plan_progress(
    plan_id: int,
    user_id: int = Query(..., description="معرف المستخدم"),
    progress_percentage: float = Query(..., ge=0.0, le=100.0),
    activity_count: Optional[int] = Query(None, ge=0),
    completed_count: Optional[int] = Query(None, ge=0),
    db: Session = Depends(get_db),
):
    """تحديث نسبة التقدم وعدد الأنشطة المنجزة في الخطة"""
    print(f"\n📋 [ActivityPlans] تحديث تقدم الخطة {plan_id} إلى {progress_percentage}%")

    plan = (
        db.query(models.ActivityPlan)
        .filter(
            models.ActivityPlan.id == plan_id,
            models.ActivityPlan.user_id == user_id,
        )
        .first()
    )

    if not plan:
        raise HTTPException(status_code=404, detail="الخطة غير موجودة")

    plan.progress_percentage = progress_percentage
    if activity_count is not None:
        plan.activity_count = activity_count
    if completed_count is not None:
        plan.completed_count = completed_count
    plan.updated_at = datetime.utcnow()

    # إذا اكتملت الخطة بنسبة 100%، أوقفها تلقائياً
    if progress_percentage >= 100.0:
        plan.is_active = False

    db.commit()
    db.refresh(plan)

    print(f"✅ تم تحديث تقدم الخطة {plan.id}")
    return plan
