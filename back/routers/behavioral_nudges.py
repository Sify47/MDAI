# backend/routers/behavioral_nudges.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/behavioral-nudges", tags=["behavioral-nudges"])


# ============================================
# نماذج Pydantic للتحفيز السلوكي
# ============================================


class NudgeActionCreate(BaseModel):
    action_id: str
    label: str
    action_type: str
    parameters: Optional[dict] = None
    requires_confirmation: bool = False


class BehavioralNudgeCreate(BaseModel):
    title: str
    message: str
    nudge_type: str  # "motivational", "educational", "reminder", "warning", "encouragement", "celebration", "habit_building", "health_insight"
    priority: str  # "low", "medium", "high", "critical"
    context: str  # "morning_routine", "evening_routine", "meal_time", "medication_time", "activity_time", "water_reminder", "sleep_time", "stress_time", "idle_time", "achievement", "setback"
    scheduled_for: Optional[datetime] = None
    metadata: Optional[dict] = None
    actions: Optional[List[NudgeActionCreate]] = None


class BehavioralNudgeResponse(BaseModel):
    id: int
    user_id: int
    title: str
    message: str
    nudge_type: str
    priority: str
    context: str
    status: str
    scheduled_for: Optional[str]
    delivered_at: Optional[str]
    action_taken_at: Optional[str]
    dismissed_at: Optional[str]
    expires_at: Optional[str]
    metadata: Optional[dict]
    created_at: str
    updated_at: str
    actions: Optional[List[dict]]


class BehavioralPatternResponse(BaseModel):
    id: int
    user_id: int
    pattern_id: str
    pattern_name: str
    description: str
    confidence_score: float
    triggers: Optional[List[str]]
    insights: Optional[dict]
    detected_at: str
    created_at: str


class NudgeStatisticsResponse(BaseModel):
    total_nudges: int
    delivered_nudges: int
    action_taken_nudges: int
    nudge_type_counts: dict
    nudge_context_counts: dict
    average_response_time: float
    effectiveness_rate: float
    period_start: str
    period_end: str


# ============================================
# نقاط نهاية API
# ============================================


@router.post("/", response_model=BehavioralNudgeResponse)
def create_behavioral_nudge(
    nudge_data: BehavioralNudgeCreate, user_id: int, db: Session = Depends(get_db)
):
    """
    إنشاء تحفيز سلوكي جديد
    """
    try:
        # إنشاء التحفيز السلوكي
        db_nudge = models.BehavioralNudge(
            user_id=user_id,
            title=nudge_data.title,
            message=nudge_data.message,
            nudge_type=nudge_data.nudge_type,
            priority=nudge_data.priority,
            context=nudge_data.context,
            scheduled_for=nudge_data.scheduled_for,
            nudge_metadata=nudge_data.metadata,
            status="pending",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        db.add(db_nudge)
        db.flush()

        # إنشاء الإجراءات المرتبطة إذا كانت موجودة
        if nudge_data.actions:
            for action_data in nudge_data.actions:
                db_action = models.NudgeAction(
                    nudge_id=db_nudge.id,
                    action_id=action_data.action_id,
                    label=action_data.label,
                    action_type=action_data.action_type,
                    parameters=action_data.parameters,
                    requires_confirmation=action_data.requires_confirmation,
                    created_at=datetime.utcnow(),
                )
                db.add(db_action)

        db.commit()
        db.refresh(db_nudge)

        return db_nudge.to_dict()

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في إنشاء التحفيز: {str(e)}")


@router.get("/", response_model=List[BehavioralNudgeResponse])
def get_behavioral_nudges(
    user_id: int,
    nudge_type: Optional[str] = None,
    context: Optional[str] = None,
    priority: Optional[str] = None,
    status: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: Session = Depends(get_db),
):
    """
    جلب جميع التحفيزات السلوكية للمستخدم مع إمكانية التصفية
    """
    try:
        query = db.query(models.BehavioralNudge).filter(
            models.BehavioralNudge.user_id == user_id
        )

        if nudge_type:
            query = query.filter(models.BehavioralNudge.nudge_type == nudge_type)

        if context:
            query = query.filter(models.BehavioralNudge.context == context)

        if priority:
            query = query.filter(models.BehavioralNudge.priority == priority)

        if status:
            query = query.filter(models.BehavioralNudge.status == status)

        if start_date:
            query = query.filter(models.BehavioralNudge.created_at >= start_date)

        if end_date:
            query = query.filter(models.BehavioralNudge.created_at <= end_date)

        query = query.order_by(models.BehavioralNudge.created_at.desc())

        nudges = query.all()

        result = []
        for nudge in nudges:
            nudge_dict = nudge.to_dict()
            # جلب الإجراءات المرتبطة
            actions = (
                db.query(models.NudgeAction)
                .filter(models.NudgeAction.nudge_id == nudge.id)
                .all()
            )
            nudge_dict["actions"] = [action.to_dict() for action in actions]
            result.append(nudge_dict)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب التحفيزات: {str(e)}")


@router.get("/pending", response_model=List[BehavioralNudgeResponse])
def get_pending_nudges(user_id: int, db: Session = Depends(get_db)):
    """
    جلب التحفيزات المعلقة (غير المسلمة أو غير المنفذة)
    """
    try:
        # التحفيزات غير المسلمة (status != "delivered" و status != "action_taken")
        pending_nudges = (
            db.query(models.BehavioralNudge)
            .filter(
                models.BehavioralNudge.user_id == user_id,
                models.BehavioralNudge.status.in_(["pending", "dismissed", "expired"]),
            )
            .order_by(models.BehavioralNudge.priority.desc())
            .all()
        )

        result = []
        for nudge in pending_nudges:
            nudge_dict = nudge.to_dict()
            actions = (
                db.query(models.NudgeAction)
                .filter(models.NudgeAction.nudge_id == nudge.id)
                .all()
            )
            nudge_dict["actions"] = [action.to_dict() for action in actions]
            result.append(nudge_dict)

        return result

    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"خطأ في جلب التحفيزات المعلقة: {str(e)}"
        )


@router.put("/{nudge_id}/deliver")
def mark_nudge_as_delivered(nudge_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    تحديث حالة التحفيز إلى "تم التسليم"
    """
    try:
        nudge = (
            db.query(models.BehavioralNudge)
            .filter(
                models.BehavioralNudge.id == nudge_id,
                models.BehavioralNudge.user_id == user_id,
            )
            .first()
        )

        if not nudge:
            raise HTTPException(status_code=404, detail="التحفيز غير موجود")

        nudge.status = "delivered"
        nudge.delivered_at = datetime.utcnow()
        nudge.updated_at = datetime.utcnow()
        db.commit()

        return {"success": True, "message": "تم تحديث حالة التحفيز"}

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500, detail=f"خطأ في تحديث حالة التحفيز: {str(e)}"
        )


@router.put("/{nudge_id}/action-taken")
def mark_nudge_action_taken(
    nudge_id: int,
    action_id: Optional[str] = None,
    user_id: int = None,
    db: Session = Depends(get_db),
):
    """
    تحديث حالة التحفيز إلى "تم اتخاذ الإجراء"
    """
    try:
        nudge = (
            db.query(models.BehavioralNudge)
            .filter(models.BehavioralNudge.id == nudge_id)
            .first()
        )

        if not nudge:
            raise HTTPException(status_code=404, detail="التحفيز غير موجود")

        if user_id and nudge.user_id != user_id:
            raise HTTPException(
                status_code=403, detail="غير مصرح بالوصول إلى هذا التحفيز"
            )

        nudge.status = "action_taken"
        nudge.action_taken_at = datetime.utcnow()
        nudge.updated_at = datetime.utcnow()

        # تحديث الإجراء المحدد إذا تم توفيره
        if action_id:
            action = (
                db.query(models.NudgeAction)
                .filter(
                    models.NudgeAction.nudge_id == nudge_id,
                    models.NudgeAction.action_id == action_id,
                )
                .first()
            )

            if action:
                # يمكننا تحديث حالة الإجراء هنا إذا أردنا
                pass

        db.commit()

        return {"success": True, "message": "تم تسجيل اتخاذ الإجراء"}

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في تسجيل الإجراء: {str(e)}")


@router.get("/patterns", response_model=List[BehavioralPatternResponse])
def get_behavioral_patterns(
    user_id: int,
    pattern_id: Optional[str] = None,
    min_confidence: Optional[float] = 0.5,
    limit: int = 10,
    db: Session = Depends(get_db),
):
    """
    جلب الأنماط السلوكية المكتشفة للمستخدم
    """
    try:
        query = db.query(models.BehavioralPattern).filter(
            models.BehavioralPattern.user_id == user_id,
            models.BehavioralPattern.confidence_score >= min_confidence,
        )

        if pattern_id:
            query = query.filter(models.BehavioralPattern.pattern_id == pattern_id)

        query = query.order_by(models.BehavioralPattern.confidence_score.desc())
        query = query.limit(limit)

        patterns = query.all()

        return [pattern.to_dict() for pattern in patterns]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب الأنماط: {str(e)}")


@router.post("/patterns")
def create_behavioral_pattern(
    user_id: int,
    pattern_id: str,
    pattern_name: str,
    description: str,
    confidence_score: float,
    triggers: Optional[List[str]] = None,
    insights: Optional[dict] = None,
    db: Session = Depends(get_db),
):
    """
    إنشاء نمط سلوكي مكتشف جديد
    """
    try:
        # التحقق من وجود النمط مسبقاً
        existing_pattern = (
            db.query(models.BehavioralPattern)
            .filter(
                models.BehavioralPattern.user_id == user_id,
                models.BehavioralPattern.pattern_id == pattern_id,
            )
            .first()
        )

        if existing_pattern:
            # تحديث النمط الموجود
            existing_pattern.pattern_name = pattern_name
            existing_pattern.description = description
            existing_pattern.confidence_score = confidence_score
            existing_pattern.pattern_metadata = {
                "triggers": triggers,
                "insights": insights,
                "detected_at": datetime.utcnow().isoformat()
            }
        else:
            # إنشاء نمط جديد
            pattern = models.BehavioralPattern(
                user_id=user_id,
                pattern_id=pattern_id,
                pattern_name=pattern_name,
                pattern_type="custom",  # نوع افتراضي
                description=description,
                frequency=1,  # تردد افتراضي
                severity="medium",  # شدة افتراضية
                confidence_score=confidence_score,
                start_date=datetime.utcnow().date(),
                pattern_metadata={
                    "triggers": triggers,
                    "insights": insights,
                    "detected_at": datetime.utcnow().isoformat()
                },
                created_at=datetime.utcnow(),
            )
            db.add(pattern)

        db.commit()

        return {"success": True, "message": "تم حفظ النمط السلوكي"}

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في حفظ النمط: {str(e)}")


@router.get("/statistics", response_model=NudgeStatisticsResponse)
def get_nudge_statistics(
    user_id: int, period_days: int = 30, db: Session = Depends(get_db)
):
    """
    جلب إحصائيات التحفيز السلوكي للمستخدم
    """
    try:
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=period_days)

        # جلب جميع التحفيزات في الفترة الزمنية
        nudges = (
            db.query(models.BehavioralNudge)
            .filter(
                models.BehavioralNudge.user_id == user_id,
                models.BehavioralNudge.created_at >= start_date,
                models.BehavioralNudge.created_at <= end_date,
            )
            .all()
        )

        total_nudges = len(nudges)
        delivered_nudges = sum(1 for nudge in nudges if nudge.status == "delivered")
        action_taken_nudges = sum(1 for nudge in nudges if nudge.status == "action_taken")

        # حساب التوزيع حسب النوع
        nudge_type_counts = {}
        for nudge in nudges:
            nudge_type_counts[nudge.nudge_type] = (
                nudge_type_counts.get(nudge.nudge_type, 0) + 1
            )

        # حساب التوزيع حسب السياق
        nudge_context_counts = {}
        for nudge in nudges:
            nudge_context_counts[nudge.context] = (
                nudge_context_counts.get(nudge.context, 0) + 1
            )

        # حساب متوسط وقت الاستجابة (بالدقائق)
        response_times = []
        for nudge in nudges:
            if nudge.status == "action_taken" and nudge.action_taken_at and nudge.created_at:
                response_time = (
                    nudge.action_taken_at - nudge.created_at
                ).total_seconds() / 60
                response_times.append(response_time)

        average_response_time = (
            sum(response_times) / len(response_times) if response_times else 0
        )

        # حساب نسبة الفعالية
        effectiveness_rate = (
            (action_taken_nudges / delivered_nudges * 100)
            if delivered_nudges > 0
            else 0
        )

        return NudgeStatisticsResponse(
            total_nudges=total_nudges,
            delivered_nudges=delivered_nudges,
            action_taken_nudges=action_taken_nudges,
            nudge_type_counts=nudge_type_counts,
            nudge_context_counts=nudge_context_counts,
            average_response_time=average_response_time,
            effectiveness_rate=effectiveness_rate,
            period_start=start_date.isoformat(),
            period_end=end_date.isoformat(),
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب الإحصائيات: {str(e)}")


@router.post("/generate")
def generate_behavioral_nudges(user_id: int, db: Session = Depends(get_db)):
    """
    توليد تحفيزات سلوكية ذكية بناءً على بيانات المستخدم
    """
    try:
        # جلب بيانات المستخدم
        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not user_nutrition:
            raise HTTPException(status_code=404, detail="بيانات التغذية غير موجودة")

        nudges = []

        # 1. تحليل الأمراض المزمنة
        diseases = user_nutrition.diseases or []

        if "diabetes" in diseases:
            # تحفيزات خاصة بمرضى السكري
            nudges.append(
                {
                    "title": "تتبع مستوى السكر",
                    "message": "هل تذكرت قياس مستوى السكر في الدم اليوم؟ المتابعة المنتظمة تساعد في التحكم في المرض.",
                    "nudge_type": "reminder",
                    "priority": "high",
                    "context": "morning_routine",
                    "metadata": {"disease": "diabetes", "importance": "high"},
                }
            )

        if "hypertension" in diseases:
            # تحفيزات خاصة بمرضى ضغط الدم
            nudges.append(
                {
                    "title": "مراقبة ضغط الدم",
                    "message": "تذكر قياس ضغط الدم اليومي. المتابعة المنتظمة تقلل من مخاطر المضاعفات.",
                    "nudge_type": "reminder",
                    "priority": "medium",
                    "context": "evening_routine",
                    "metadata": {"disease": "hypertension", "importance": "medium"},
                }
            )

        # 2. تحليل بيانات النشاط اليومي
        today = datetime.utcnow().date()
        walking_activities = (
            db.query(models.WalkingActivity)
            .filter(
                models.WalkingActivity.user_id == user_id,
                models.WalkingActivity.activity_date == today,
            )
            .all()
        )

        if walking_activities:
            total_steps = sum(activity.steps for activity in walking_activities)
            if total_steps < 5000:
                nudges.append(
                    {
                        "title": "تحفيز المشي",
                        "message": f"لقد مشيت {total_steps} خطوة اليوم. حاول الوصول إلى 5000 خطوة لتحسين صحتك.",
                        "nudge_type": "encouragement",
                        "priority": "medium",
                        "context": "activity_tracking",
                        "metadata": {"steps": total_steps, "target": 5000},
                    }
                )
        else:
            nudges.append(
                {
                    "title": "ابدأ نشاطك اليومي",
                    "message": "لم تسجل أي نشاط مشي اليوم. حاول المشي لمدة 10 دقائق لتحسين صحتك.",
                    "nudge_type": "motivational",
                    "priority": "medium",
                    "context": "activity_tracking",
                    "metadata": {"activity": "walking", "target_minutes": 10},
                }
            )

        # 3. تحليل بيانات المياه
        water_intake = (
            db.query(models.WaterIntake)
            .filter(
                models.WaterIntake.user_id == user_id, models.WaterIntake.date == today
            )
            .first()
        )

        if water_intake:
            if water_intake.amount_ml < 2000:
                nudges.append(
                    {
                        "title": "شرب الماء",
                        "message": f"لقد شربت {water_intake.amount_ml} مل من الماء اليوم. حاول الوصول إلى 2000 مل للحفاظ على ترطيب جسمك.",
                        "nudge_type": "reminder",
                        "priority": "medium",
                        "context": "hydration",
                        "metadata": {
                            "current_ml": water_intake.amount_ml,
                            "target_ml": 2000,
                        },
                    }
                )
        else:
            nudges.append(
                {
                    "title": "ترطيب الجسم",
                    "message": "لم تسجل أي استهلاك للماء اليوم. حاول شرب كوب من الماء الآن.",
                    "nudge_type": "reminder",
                    "priority": "medium",
                    "context": "hydration",
                    "metadata": {"action": "drink_water"},
                }
            )

        # 4. تحليل بيانات الوجبات
        meals_today = (
            db.query(models.Meal)
            .filter(
                models.Meal.user_id == user_id,
                models.Meal.created_at >= datetime.combine(today, datetime.min.time()),
            )
            .count()
        )

        if meals_today < 3:
            nudges.append(
                {
                    "title": "التغذية المتوازنة",
                    "message": f"لقد سجلت {meals_today} وجبة اليوم. حاول تناول 3 وجبات متوازنة لتحسين صحتك.",
                    "nudge_type": "educational",
                    "priority": "low",
                    "context": "nutrition",
                    "metadata": {"meals_count": meals_today, "target_meals": 3},
                }
            )

        # 5. تحليل بيانات الأدوية
        medications = (
            db.query(models.Medication)
            .filter(
                models.Medication.user_id == user_id,
                models.Medication.is_active == True,
            )
            .all()
        )

        for medication in medications:
            # تحقق من الجرعات اليومية
            doses_today = (
                db.query(models.MedicationDose)
                .filter(
                    models.MedicationDose.medication_id == medication.id,
                    models.MedicationDose.taken_at
                    >= datetime.combine(today, datetime.min.time()),
                )
                .count()
            )

            if doses_today < len(medication.times or []):
                nudges.append(
                    {
                        "title": "تذكير بالأدوية",
                        "message": f"تذكر تناول دواء {medication.medicine_name}.",
                        "nudge_type": "reminder",
                        "priority": "high",
                        "context": "medication",
                        "metadata": {
                            "medication_id": medication.id,
                            "medicine_name": medication.medicine_name,
                        },
                    }
                )

        # 6. تحليل بيانات الكويز اليومي
        daily_quiz_sessions = (
            db.query(models.QuizSession)
            .filter(
                models.QuizSession.user_id == user_id,
                models.QuizSession.created_at
                >= datetime.combine(today, datetime.min.time()),
            )
            .count()
        )

        if daily_quiz_sessions == 0:
            nudges.append(
                {
                    "title": "الكويز اليومي",
                    "message": "لم تقم بإكمال الكويز اليومي. حاول إكماله لتحليل سلوكياتك الصحية.",
                    "nudge_type": "educational",
                    "priority": "low",
                    "context": "daily_quiz",
                    "metadata": {"quiz_type": "daily"},
                }
            )

        # حفظ التحفيزات في قاعدة البيانات
        saved_nudges = []
        for nudge_data in nudges:
            nudge = models.BehavioralNudge(
                user_id=user_id,
                title=nudge_data["title"],
                message=nudge_data["message"],
                nudge_type=nudge_data["nudge_type"],
                priority=nudge_data["priority"],
                context=nudge_data["context"],
                nudge_metadata=nudge_data.get("metadata", {}),
                status="pending",
                created_at=datetime.utcnow(),
            )
            db.add(nudge)
            db.flush()

            saved_nudges.append(
                {
                    "id": nudge.id,
                    "title": nudge.title,
                    "message": nudge.message,
                    "nudge_type": nudge.nudge_type,
                    "priority": nudge.priority,
                    "context": nudge.context,
                    "metadata": nudge.nudge_metadata,
                    "status": nudge.status,
                    "created_at": nudge.created_at,
                }
            )

        db.commit()

        return {
            "success": True,
            "message": f"تم توليد {len(saved_nudges)} تحفيز سلوكي",
            "nudges": saved_nudges,
        }

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في توليد التحفيزات: {str(e)}")
