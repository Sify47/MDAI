# backend/routers/activities.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from pydantic import BaseModel

from database import get_db
import models
import schemas
from core.cache_config import cache_result, invalidate_cache, delete_cache_pattern


router = APIRouter(prefix="/api/activities", tags=["activities"])

# ============================================
# ✅ Pydantic Models
# ============================================

class ActivityCategoryBase(BaseModel):
    name_ar: str
    name_en: str
    icon_code: str = "📋"
    color_code: str = "#2196F3"

class ActivityCategoryResponse(ActivityCategoryBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class ActivityBase(BaseModel):
    category_id: int
    title: str
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    is_completed: bool = False
    has_reminder: bool = False
    reminder_minutes: int = 15
    notes: Optional[str] = None
    # 🆕 Exercise tracking fields
    is_exercise: bool = False
    exercise_name: Optional[str] = None
    exercise_name_en: Optional[str] = None
    exercise_id: Optional[str] = None
    muscle_group: Optional[str] = None
    muscle_group_en: Optional[str] = None
    met_value: Optional[float] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    rest_seconds: Optional[int] = None
    calories_burned: Optional[int] = None
    # 🆕 Plan linking
    plan_id: Optional[int] = None
    plan_name: Optional[str] = None

class ActivityCreate(ActivityBase):
    user_id: int

class ActivityUpdate(BaseModel):
    category_id: Optional[int] = None
    title: Optional[str] = None
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    is_completed: Optional[bool] = None
    has_reminder: Optional[bool] = None
    reminder_minutes: Optional[int] = None
    notes: Optional[str] = None
    # 🆕 Exercise tracking fields
    is_exercise: Optional[bool] = None
    exercise_name: Optional[str] = None
    exercise_name_en: Optional[str] = None
    exercise_id: Optional[str] = None
    muscle_group: Optional[str] = None
    muscle_group_en: Optional[str] = None
    met_value: Optional[float] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    rest_seconds: Optional[int] = None
    calories_burned: Optional[int] = None
    # 🆕 Plan linking
    plan_id: Optional[int] = None
    plan_name: Optional[str] = None

class ActivityResponse(ActivityBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    category: Optional[ActivityCategoryResponse] = None
    exercises: List[schemas.ActivityExerciseResponse] = []
    
    class Config:
        from_attributes = True

class DailyStatsResponse(BaseModel):
    date: date
    total_activities: int
    completed_activities: int
    completion_rate: float
    work_hours: float
    study_hours: float
    exercise_minutes: int
    activities_by_category: dict

class WeeklyStatsResponse(BaseModel):
    week_start: date
    week_end: date
    total_activities: int
    completed_activities: int
    completion_rate: float
    categories: List[dict]

# ============================================
# ✅ 1. APIs الفئات (Categories)
# ============================================


# تحديث دالة جلب الفئات
@router.get("/categories", response_model=List[ActivityCategoryResponse])
@cache_result(ttl=3600, key_prefix="categories")  # ✅ ساعة كاملة
def get_activity_categories(db: Session = Depends(get_db)):
    """جلب كل فئات الأنشطة"""
    categories = db.query(models.ActivityCategory).all()
    return categories


# ============================================
# ✅ 2. APIs الأنشطة (Activities)
# ============================================


# تحديث دالة جلب الأنشطة
@router.get("/", response_model=List[ActivityResponse])
@cache_result(ttl=300, key_prefix="activities")  # ✅ 5 دقائق
def get_activities(
    user_id: int = Query(1, description="معرف المستخدم"),
    date: Optional[date] = None,
    category_id: Optional[int] = None,
    is_completed: Optional[bool] = None,
    limit: int = 50,
    skip: int = 0,
    db: Session = Depends(get_db),
):
    """جلب الأنشطة مع إمكانية التصفية"""
    query = db.query(models.Activity).filter(models.Activity.user_id == user_id)

    if date:
        start_of_day = datetime.combine(date, datetime.min.time())
        end_of_day = datetime.combine(date, datetime.max.time())
        query = query.filter(
            models.Activity.start_time.between(start_of_day, end_of_day)
        )

    if category_id:
        query = query.filter(models.Activity.category_id == category_id)

    if is_completed is not None:
        query = query.filter(models.Activity.is_completed == is_completed)

    activities = query.order_by(models.Activity.start_time).offset(skip).limit(limit).all()

    return activities


@router.get("/today", response_model=List[ActivityResponse])
def get_today_activities(
    user_id: int = Query(1, description="معرف المستخدم"),
    db: Session = Depends(get_db)
):
    """جلب أنشطة اليوم"""
    today = date.today()
    start = datetime.combine(today, datetime.min.time())
    end = datetime.combine(today, datetime.max.time())
    
    activities = db.query(models.Activity).filter(
        models.Activity.user_id == user_id,
        models.Activity.start_time.between(start, end)
    ).order_by(models.Activity.start_time).all()
    
    return activities

@router.get("/upcoming", response_model=List[ActivityResponse])
def get_upcoming_activities(
    user_id: int = Query(1, description="معرف المستخدم"),
    hours: int = 24,
    db: Session = Depends(get_db)
):
    """جلب الأنشطة القادمة خلال ساعات محددة"""
    now = datetime.now()
    end = now + timedelta(hours=hours)
    
    activities = db.query(models.Activity).filter(
        models.Activity.user_id == user_id,
        models.Activity.start_time.between(now, end),
        models.Activity.is_completed == False
    ).order_by(models.Activity.start_time).all()
    
    return activities

@router.get("/{activity_id}", response_model=ActivityResponse)
def get_activity(
    activity_id: int,
    user_id: int = Query(1, description="معرف المستخدم"),
    db: Session = Depends(get_db)
):
    """جلب نشاط محدد"""
    activity = db.query(models.Activity).filter(
        models.Activity.id == activity_id,
        models.Activity.user_id == user_id
    ).first()

    if not activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")

    return activity


# عند إنشاء نشاط جديد، نحذف الـ cache
@router.post("/", response_model=ActivityResponse, status_code=201)
@invalidate_cache(pattern="activities:*")  # ✅ حذف كل cache الأنشطة
def create_activity(activity: ActivityCreate, db: Session = Depends(get_db)):

    """إضافة نشاط جديد"""
    # التحقق من وجود الفئة
    category = db.query(models.ActivityCategory).filter(
        models.ActivityCategory.id == activity.category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="الفئة غير موجودة")

    # التحقق من صحة التواريخ
    if activity.end_time <= activity.start_time:
        raise HTTPException(
            status_code=400,
            detail="وقت النهاية يجب أن يكون بعد وقت البداية"
        )

    db_activity = models.Activity(
        user_id=activity.user_id,
        category_id=activity.category_id,
        title=activity.title,
        description=activity.description,
        start_time=activity.start_time,
        end_time=activity.end_time,
        is_completed=activity.is_completed,
        has_reminder=activity.has_reminder,
        reminder_minutes=activity.reminder_minutes,
        notes=activity.notes,
        # 🆕 Exercise tracking
        is_exercise=activity.is_exercise,
        exercise_name=activity.exercise_name,
        exercise_name_en=activity.exercise_name_en,
        exercise_id=activity.exercise_id,
        muscle_group=activity.muscle_group,
        muscle_group_en=activity.muscle_group_en,
        met_value=activity.met_value,
        sets=activity.sets,
        reps=activity.reps,
        weight_kg=activity.weight_kg,
        rest_seconds=activity.rest_seconds,
        calories_burned=activity.calories_burned,
        # 🆕 Plan linking
        plan_id=activity.plan_id,
        plan_name=activity.plan_name,
    )

    db.add(db_activity)
    db.commit()
    db.refresh(db_activity)

    return db_activity


@router.put("/{activity_id}", response_model=ActivityResponse)
@invalidate_cache(pattern="activities:*")

def update_activity(
    activity_id: int,
    activity_update: ActivityUpdate,
    user_id: int = Query(1, description="معرف المستخدم"),
    db: Session = Depends(get_db)
):
    """تحديث نشاط"""
    db_activity = db.query(models.Activity).filter(
        models.Activity.id == activity_id,
        models.Activity.user_id == user_id
    ).first()
    
    if not db_activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")
    
    # تحديث الحقول
    update_data = activity_update.dict(exclude_unset=True)
    
    # التحقق من التواريخ إذا تم تحديثها
    if 'start_time' in update_data or 'end_time' in update_data:
        start = update_data.get('start_time', db_activity.start_time)
        end = update_data.get('end_time', db_activity.end_time)
        if end <= start:
            raise HTTPException(
                status_code=400,
                detail="وقت النهاية يجب أن يكون بعد وقت البداية"
            )
    
    for field, value in update_data.items():
        setattr(db_activity, field, value)
    
    db.commit()
    db.refresh(db_activity)
    
    return db_activity

@router.patch("/{activity_id}/complete")
def complete_activity(
    activity_id: int,
    user_id: int = Query(1, description="معرف المستخدم"),
    db: Session = Depends(get_db)
):
    """تحديد نشاط كمكتمل"""
    db_activity = db.query(models.Activity).filter(
        models.Activity.id == activity_id,
        models.Activity.user_id == user_id
    ).first()
    
    if not db_activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")
    
    db_activity.is_completed = True
    db.commit()
    
    return {"message": "تم إكمال النشاط بنجاح", "activity_id": activity_id}

@router.delete("/{activity_id}")
def delete_activity(
    activity_id: int,
    user_id: int = Query(1, description="معرف المستخدم"),
    db: Session = Depends(get_db)
):
    """حذف نشاط"""
    db_activity = db.query(models.Activity).filter(
        models.Activity.id == activity_id,
        models.Activity.user_id == user_id
    ).first()
    
    if not db_activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")
    
    db.delete(db_activity)
    db.commit()
    
    return {"message": "تم حذف النشاط بنجاح", "activity_id": activity_id}


# ============================================
# ✅ 2.5 APIs تمارين النشاط (Activity Exercises)
# ============================================


@router.get("/{activity_id}/exercises", response_model=List[schemas.ActivityExerciseResponse])
def get_activity_exercises(
    activity_id: int,
    db: Session = Depends(get_db)
):
    """جلب جميع تمارين نشاط محدد"""
    activity = db.query(models.Activity).filter(models.Activity.id == activity_id).first()
    if not activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")
    
    return activity.exercises


@router.post("/{activity_id}/exercises", response_model=schemas.ActivityExerciseResponse, status_code=201)
def create_activity_exercise(
    activity_id: int,
    exercise: schemas.ActivityExerciseCreate,
    db: Session = Depends(get_db)
):
    """إضافة تمرين جديد لنشاط محدد"""
    activity = db.query(models.Activity).filter(models.Activity.id == activity_id).first()
    if not activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")
    
    # حساب أعلى order_index للإضافة بعده
    max_order = db.query(func.max(models.ActivityExercise.order_index)).filter(
        models.ActivityExercise.activity_id == activity_id
    ).scalar() or -1
    
    db_exercise = models.ActivityExercise(
        activity_id=activity_id,
        exercise_id=exercise.exercise_id,
        exercise_name_ar=exercise.exercise_name_ar,
        exercise_name_en=exercise.exercise_name_en,
        muscle_group=exercise.muscle_group,
        muscle_group_en=exercise.muscle_group_en,
        met_value=exercise.met_value,
        sets=exercise.sets,
        reps=exercise.reps,
        weight_kg=exercise.weight_kg,
        rest_seconds=exercise.rest_seconds,
        calories_burned=exercise.calories_burned,
        order_index=max_order + 1,
    )
    
    db.add(db_exercise)
    db.commit()
    db.refresh(db_exercise)
    
    return db_exercise


@router.put("/{activity_id}/exercises/bulk", response_model=List[schemas.ActivityExerciseResponse])
def bulk_replace_activity_exercises(
    activity_id: int,
    bulk: schemas.ActivityBulkExercisesCreate,
    db: Session = Depends(get_db)
):
    """استبدال جميع تمارين النشاط (حذف القديم وإضافة الجديد)"""
    activity = db.query(models.Activity).filter(models.Activity.id == activity_id).first()
    if not activity:
        raise HTTPException(status_code=404, detail="النشاط غير موجود")
    
    # حذف جميع التمارين القديمة
    db.query(models.ActivityExercise).filter(
        models.ActivityExercise.activity_id == activity_id
    ).delete()
    
    # إضافة التمارين الجديدة
    new_exercises = []
    for i, ex_data in enumerate(bulk.exercises):
        db_exercise = models.ActivityExercise(
            activity_id=activity_id,
            exercise_id=ex_data.exercise_id,
            exercise_name_ar=ex_data.exercise_name_ar,
            exercise_name_en=ex_data.exercise_name_en,
            muscle_group=ex_data.muscle_group,
            muscle_group_en=ex_data.muscle_group_en,
            met_value=ex_data.met_value,
            sets=ex_data.sets,
            reps=ex_data.reps,
            weight_kg=ex_data.weight_kg,
            rest_seconds=ex_data.rest_seconds,
            calories_burned=ex_data.calories_burned,
            order_index=i,
        )
        db.add(db_exercise)
        new_exercises.append(db_exercise)
    
    db.commit()
    
    # Refresh all new exercises
    for ex in new_exercises:
        db.refresh(ex)
    
    return new_exercises


@router.put("/{activity_id}/exercises/{exercise_id}", response_model=schemas.ActivityExerciseResponse)
def update_activity_exercise(
    activity_id: int,
    exercise_id: int,
    exercise_update: schemas.ActivityExerciseUpdate,
    db: Session = Depends(get_db)
):
    """تحديث تمرين محدد لنشاط"""
    db_exercise = db.query(models.ActivityExercise).filter(
        models.ActivityExercise.id == exercise_id,
        models.ActivityExercise.activity_id == activity_id
    ).first()
    
    if not db_exercise:
        raise HTTPException(status_code=404, detail="التمرين غير موجود")
    
    update_data = exercise_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_exercise, field, value)
    
    db.commit()
    db.refresh(db_exercise)
    
    return db_exercise


@router.delete("/{activity_id}/exercises/{exercise_id}")
def delete_activity_exercise(
    activity_id: int,
    exercise_id: int,
    db: Session = Depends(get_db)
):
    """حذف تمرين محدد من النشاط"""
    db_exercise = db.query(models.ActivityExercise).filter(
        models.ActivityExercise.id == exercise_id,
        models.ActivityExercise.activity_id == activity_id
    ).first()
    
    if not db_exercise:
        raise HTTPException(status_code=404, detail="التمرين غير موجود")
    
    db.delete(db_exercise)
    db.commit()
    
    return {"message": "تم حذف التمرين بنجاح", "exercise_id": exercise_id}


# ============================================
# ✅ 3. APIs الإحصائيات (Statistics)
# ============================================

@router.get("/stats/daily")
def get_daily_stats(
    user_id: int = Query(1, description="معرف المستخدم"),
    date: Optional[date] = None,
    db: Session = Depends(get_db)
):
    """إحصائيات يومية للأنشطة"""
    target_date = date or datetime.now().date()
    start = datetime.combine(target_date, datetime.min.time())
    end = datetime.combine(target_date, datetime.max.time())
    
    # جلب الأنشطة
    activities = db.query(models.Activity).filter(
        models.Activity.user_id == user_id,
        models.Activity.start_time.between(start, end)
    ).all()
    
    total = len(activities)
    completed = sum(1 for a in activities if a.is_completed)
    
    # تجميع حسب الفئة
    categories = {}
    for activity in activities:
        cat_name = activity.category.name_ar if activity.category else "أخرى"
        if cat_name not in categories:
            categories[cat_name] = 0
        categories[cat_name] += 1
    
    # حساب ساعات العمل والدراسة
    work_hours = 0
    study_hours = 0
    exercise_minutes = 0
    
    for activity in activities:
        duration = (activity.end_time - activity.start_time).total_seconds() / 3600
        if activity.category and activity.category.name_en == "Work":
            work_hours += duration
        elif activity.category and activity.category.name_en == "Study":
            study_hours += duration
        elif activity.category and activity.category.name_en == "Exercise":
            exercise_minutes += duration * 60

    # 🆕 Exercise-specific aggregations (Phase A10 + Multi-exercise)
    total_volume = 0.0
    total_exercise_calories = 0
    total_exercise_activities = 0
    muscle_groups = {}
    exercise_frequency = {}

    for activity in activities:
        if not activity.is_exercise:
            continue
        total_exercise_activities += 1
        # اختيار: استخدام التمارين المتعددة إن وجدت، وإلا استخدم الحقول القديمة
        if activity.exercises:
            for ex in activity.exercises:
                if ex.calories_burned:
                    total_exercise_calories += ex.calories_burned
                if ex.sets and ex.reps:
                    vol = (ex.weight_kg or 0) * (ex.sets or 0) * (ex.reps or 0)
                    total_volume += vol
                if ex.muscle_group:
                    muscle_groups[ex.muscle_group] = muscle_groups.get(ex.muscle_group, 0) + 1
                if ex.exercise_name_ar:
                    exercise_frequency[ex.exercise_name_ar] = exercise_frequency.get(ex.exercise_name_ar, 0) + 1
        else:
            # توافق مع الإصدارات القديمة (حقول مسطحة)
            if activity.calories_burned:
                total_exercise_calories += activity.calories_burned
            if activity.sets and activity.reps:
                vol = (activity.weight_kg or 0) * (activity.sets or 0) * (activity.reps or 0)
                total_volume += vol
            if activity.muscle_group:
                muscle_groups[activity.muscle_group] = muscle_groups.get(activity.muscle_group, 0) + 1
            if activity.exercise_name:
                exercise_frequency[activity.exercise_name] = exercise_frequency.get(activity.exercise_name, 0) + 1

    # Sort top exercises by frequency
    top_exercises = dict(
        sorted(exercise_frequency.items(), key=lambda x: x[1], reverse=True)[:5]
    )
    
    return {
        "date": target_date.isoformat(),
        "total_activities": total,
        "completed_activities": completed,
        "completion_rate": round((completed / total * 100) if total > 0 else 0, 2),
        "work_hours": round(work_hours, 2),
        "study_hours": round(study_hours, 2),
        "exercise_minutes": round(exercise_minutes),
        "activities_by_category": categories,
        # 🆕 Exercise aggregations
        "total_volume": round(total_volume, 2),
        "total_exercise_calories": total_exercise_calories,
        "total_exercise_activities": total_exercise_activities,
        "muscle_group_distribution": muscle_groups,
        "most_performed_exercises": top_exercises,
    }

@router.get("/stats/weekly")
def get_weekly_stats(
    user_id: int = Query(1, description="معرف المستخدم"),
    db: Session = Depends(get_db)
):
    """إحصائيات أسبوعية للأنشطة"""
    today = datetime.now().date()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)
    
    start = datetime.combine(week_start, datetime.min.time())
    end = datetime.combine(week_end, datetime.max.time())
    
    activities = db.query(models.Activity).filter(
        models.Activity.user_id == user_id,
        models.Activity.start_time.between(start, end)
    ).all()
    
    total = len(activities)
    completed = sum(1 for a in activities if a.is_completed)
    
    # إحصائيات يومية
    daily_stats = []
    for i in range(7):
        day = week_start + timedelta(days=i)
        day_start = datetime.combine(day, datetime.min.time())
        day_end = datetime.combine(day, datetime.max.time())
        
        day_activities = [a for a in activities if day_start <= a.start_time <= day_end]
        day_completed = sum(1 for a in day_activities if a.is_completed)
        
        daily_stats.append({
            "date": day.isoformat(),
            "total": len(day_activities),
            "completed": day_completed
        })
    
    # 🆕 Exercise-specific aggregations (Phase A10 + Multi-exercise)
    total_volume = 0.0
    total_exercise_calories = 0
    total_exercise_activities = 0
    muscle_groups = {}
    exercise_frequency = {}

    for activity in activities:
        if not activity.is_exercise:
            continue
        total_exercise_activities += 1
        if activity.exercises:
            for ex in activity.exercises:
                if ex.calories_burned:
                    total_exercise_calories += ex.calories_burned
                if ex.sets and ex.reps:
                    vol = (ex.weight_kg or 0) * (ex.sets or 0) * (ex.reps or 0)
                    total_volume += vol
                if ex.muscle_group:
                    muscle_groups[ex.muscle_group] = muscle_groups.get(ex.muscle_group, 0) + 1
                if ex.exercise_name_ar:
                    exercise_frequency[ex.exercise_name_ar] = exercise_frequency.get(ex.exercise_name_ar, 0) + 1
        else:
            if activity.calories_burned:
                total_exercise_calories += activity.calories_burned
            if activity.sets and activity.reps:
                vol = (activity.weight_kg or 0) * (activity.sets or 0) * (activity.reps or 0)
                total_volume += vol
            if activity.muscle_group:
                muscle_groups[activity.muscle_group] = muscle_groups.get(activity.muscle_group, 0) + 1
            if activity.exercise_name:
                exercise_frequency[activity.exercise_name] = exercise_frequency.get(activity.exercise_name, 0) + 1

    top_exercises = dict(
        sorted(exercise_frequency.items(), key=lambda x: x[1], reverse=True)[:5]
    )
    
    return {
        "week_start": week_start.isoformat(),
        "week_end": week_end.isoformat(),
        "total_activities": total,
        "completed_activities": completed,
        "completion_rate": round((completed / total * 100) if total > 0 else 0, 2),
        "daily_stats": daily_stats,
        # 🆕 Exercise aggregations
        "total_volume": round(total_volume, 2),
        "total_exercise_calories": total_exercise_calories,
        "total_exercise_activities": total_exercise_activities,
        "muscle_group_distribution": muscle_groups,
        "most_performed_exercises": top_exercises,
    }

@router.get("/stats/monthly")
def get_monthly_stats(
    user_id: int = Query(1, description="معرف المستخدم"),
    year: int = Query(datetime.now().year),
    month: int = Query(datetime.now().month),
    db: Session = Depends(get_db)
):
    """إحصائيات شهرية للأنشطة"""
    month_start = datetime(year, month, 1)
    if month == 12:
        month_end = datetime(year + 1, 1, 1) - timedelta(seconds=1)
    else:
        month_end = datetime(year, month + 1, 1) - timedelta(seconds=1)
    
    activities = db.query(models.Activity).filter(
        models.Activity.user_id == user_id,
        models.Activity.start_time.between(month_start, month_end)
    ).all()
    
    total = len(activities)
    completed = sum(1 for a in activities if a.is_completed)
    
    # تجميع حسب الفئة
    categories = {}
    for activity in activities:
        cat_name = activity.category.name_ar if activity.category else "أخرى"
        if cat_name not in categories:
            categories[cat_name] = 0
        categories[cat_name] += 1

    # 🆕 Exercise-specific aggregations (Phase A10 + Multi-exercise)
    total_volume = 0.0
    total_exercise_calories = 0
    total_exercise_activities = 0
    muscle_groups = {}
    exercise_frequency = {}

    for activity in activities:
        if not activity.is_exercise:
            continue
        total_exercise_activities += 1
        if activity.exercises:
            for ex in activity.exercises:
                if ex.calories_burned:
                    total_exercise_calories += ex.calories_burned
                if ex.sets and ex.reps:
                    vol = (ex.weight_kg or 0) * (ex.sets or 0) * (ex.reps or 0)
                    total_volume += vol
                if ex.muscle_group:
                    muscle_groups[ex.muscle_group] = muscle_groups.get(ex.muscle_group, 0) + 1
                if ex.exercise_name_ar:
                    exercise_frequency[ex.exercise_name_ar] = exercise_frequency.get(ex.exercise_name_ar, 0) + 1
        else:
            if activity.calories_burned:
                total_exercise_calories += activity.calories_burned
            if activity.sets and activity.reps:
                vol = (activity.weight_kg or 0) * (activity.sets or 0) * (activity.reps or 0)
                total_volume += vol
            if activity.muscle_group:
                muscle_groups[activity.muscle_group] = muscle_groups.get(activity.muscle_group, 0) + 1
            if activity.exercise_name:
                exercise_frequency[activity.exercise_name] = exercise_frequency.get(activity.exercise_name, 0) + 1

    top_exercises = dict(
        sorted(exercise_frequency.items(), key=lambda x: x[1], reverse=True)[:5]
    )
    
    return {
        "month": f"{year}-{month:02d}",
        "total_activities": total,
        "completed_activities": completed,
        "completion_rate": round((completed / total * 100) if total > 0 else 0, 2),
        "categories": categories,
        # 🆕 Exercise aggregations
        "total_volume": round(total_volume, 2),
        "total_exercise_calories": total_exercise_calories,
        "total_exercise_activities": total_exercise_activities,
        "muscle_group_distribution": muscle_groups,
        "most_performed_exercises": top_exercises,
    }
