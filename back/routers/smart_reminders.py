# backend/routers/smart_reminders.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, func, desc
from typing import List, Optional
from datetime import date, datetime, timedelta
import random

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/smart-reminders", tags=["smart_reminders"])


# ============================================
# ✅ 1. جلب الإشعارات الذكية لمستخدم
# ============================================
@router.get("/", response_model=List[schemas.SmartNotificationResponse])
def get_smart_notifications(
    user_id: int = Query(..., description="معرف المستخدم"),
    notification_type: Optional[str] = Query(None, description="تصفية حسب النوع"),
    priority: Optional[str] = Query(None, description="تصفية حسب الأولوية"),
    unread_only: Optional[bool] = Query(False, description="الإشعارات غير المقروءة فقط"),
    limit: Optional[int] = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """جلب الإشعارات الذكية لمستخدم مع إمكانية التصفية"""
    print(f"\n🔔 [SmartReminders] جلب إشعارات المستخدم {user_id}")

    query = db.query(models.SmartNotification).filter(
        models.SmartNotification.user_id == user_id
    )

    if notification_type:
        query = query.filter(
            models.SmartNotification.notification_type == notification_type
        )
    if priority:
        query = query.filter(models.SmartNotification.priority == priority)
    if unread_only:
        query = query.filter(models.SmartNotification.read_at.is_(None))

    notifications = (
        query.order_by(desc(models.SmartNotification.created_at))
        .limit(limit)
        .all()
    )

    print(f"✅ تم جلب {len(notifications)} إشعار")
    return notifications


# ============================================
# ✅ 2. إنشاء إشعار ذكي
# ============================================
@router.post("/", response_model=schemas.SmartNotificationResponse, status_code=201)
def create_smart_notification(
    notification_data: schemas.SmartNotificationCreate,
    db: Session = Depends(get_db),
):
    """إنشاء إشعار ذكي جديد"""
    print(
        f"\n🔔 [SmartReminders] إنشاء إشعار: {notification_data.title[:50]}..."
    )

    notification = models.SmartNotification(
        user_id=notification_data.user_id,
        notification_type=notification_data.notification_type,
        priority=notification_data.priority,
        title=notification_data.title,
        message=notification_data.message,
        context=notification_data.context,
        target_date=notification_data.target_date,
        related_target_type=notification_data.related_target_type,
        scheduled_time=notification_data.scheduled_time,
        sent_at=datetime.utcnow(),
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    print(f"✅ تم إنشاء الإشعار {notification.id}")
    return notification


# ============================================
# ✅ 3. تحديث حالة الإشعار (قراءة/تفاعل)
# ============================================
@router.patch("/{notification_id}", response_model=schemas.SmartNotificationResponse)
def update_notification_status(
    notification_id: int,
    update_data: schemas.SmartNotificationUpdate,
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """تحديث حالة الإشعار (قراءة أو تفاعل)"""
    print(f"\n🔔 [SmartReminders] تحديث إشعار {notification_id}")

    notification = (
        db.query(models.SmartNotification)
        .filter(
            models.SmartNotification.id == notification_id,
            models.SmartNotification.user_id == user_id,
        )
        .first()
    )

    if not notification:
        raise HTTPException(status_code=404, detail="الإشعار غير موجود")

    update_fields = update_data.model_dump(exclude_unset=True)
    for key, value in update_fields.items():
        setattr(notification, key, value)

    db.commit()
    db.refresh(notification)

    print(f"✅ تم تحديث الإشعار {notification_id}")
    return notification


# ============================================
# ✅ 4. حذف إشعار
# ============================================
@router.delete("/{notification_id}")
def delete_notification(
    notification_id: int,
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """حذف إشعار ذكي"""
    print(f"\n🔔 [SmartReminders] حذف إشعار {notification_id}")

    notification = (
        db.query(models.SmartNotification)
        .filter(
            models.SmartNotification.id == notification_id,
            models.SmartNotification.user_id == user_id,
        )
        .first()
    )

    if not notification:
        raise HTTPException(status_code=404, detail="الإشعار غير موجود")

    db.delete(notification)
    db.commit()

    print(f"✅ تم حذف الإشعار {notification_id}")
    return {"message": "تم حذف الإشعار", "id": notification_id}


# ============================================
# ✅ 5. جلب عدد الإشعارات غير المقروءة
# ============================================
@router.get("/unread-count")
def get_unread_count(
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """جلب عدد الإشعارات غير المقروءة"""
    count = (
        db.query(func.count(models.SmartNotification.id))
        .filter(
            models.SmartNotification.user_id == user_id,
            models.SmartNotification.read_at.is_(None),
        )
        .scalar()
    )

    return {"user_id": user_id, "unread_count": count or 0}


# ============================================
# ✅ 6. إنشاء إشعارات ذكية تلقائياً بناءً على سلوك المستخدم
# ============================================
@router.post("/generate", response_model=List[schemas.SmartNotificationResponse])
def generate_smart_reminders(
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """تحليل سلوك المستخدم وإنشاء إشعارات ذكية مناسبة"""
    print(f"\n🧠 [SmartReminders] تحليل سلوك المستخدم {user_id} لتوليد إشعارات ذكية")

    today = date.today()
    now = datetime.utcnow()
    generated = []

    # --- التحليل 1: تذكير بالمشي إذا لم يقم بأي نشاط اليوم ---
    today_walking = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == user_id,
            func.date(models.WalkingActivity.activity_date) == today,
        )
        .count()
    )

    if today_walking == 0:
        existing = (
            db.query(models.SmartNotification)
            .filter(
                models.SmartNotification.user_id == user_id,
                models.SmartNotification.notification_type == "behavior_reminder",
                models.SmartNotification.related_target_type == "steps",
                func.date(models.SmartNotification.created_at) == today,
            )
            .first()
        )

        if not existing:
            hour = now.hour
            if hour < 12:
                messages = [
                    "صباح الخير! 🌅 لا تنسَ المشي اليوم لتحسين نشاطك الدوري",
                    "يوم جديد مليء بالطاقة! 🚶 ابدأه بخطواتك الأولى",
                    "الصباح الباكر أفضل وقت للمشي، جرب 15 دقيقة فقط! ☀️",
                ]
            elif hour < 17:
                messages = [
                    "لم تمشِ بعد اليوم! 🚶 خذ استراحة قصيرة وتمشّ",
                    "نشاطك البدني يحتاج بعض الاهتمام 🏃 10 دقائق مشي كافية",
                    "هل تعلم؟ المشي المنتظم يحسن المزاج والتركيز 🧠",
                ]
            else:
                messages = [
                    "مساء الخير! 🌆 لا يزال لديك وقت للمشي اليوم",
                    "المشي المسائي يساعد على الاسترخاء بعد يوم طويل 🌙",
                    "حتى 5 دقائق مشي قبل النوم تفيد صحتك 🌟",
                ]

            notification = models.SmartNotification(
                user_id=user_id,
                notification_type="behavior_reminder",
                priority="info",
                title="تذكير بالمشي 🚶",
                message=random.choice(messages),
                context={
                    "trigger": "no_walking_today",
                    "today_walking_count": 0,
                    "suggestion": "حاول المشي لمدة 10-15 دقيقة",
                },
                target_date=today,
                related_target_type="steps",
                sent_at=now,
            )
            db.add(notification)
            db.flush()
            generated.append(notification)

    # --- التحليل 2: تذكير بشرب الماء ---
    today_water = (
        db.query(models.WaterIntake)
        .filter(
            models.WaterIntake.user_id == user_id,
            func.date(models.WaterIntake.created_at) == today,
        )
        .count()
    )

    if today_water < 3:
        existing = (
            db.query(models.SmartNotification)
            .filter(
                models.SmartNotification.user_id == user_id,
                models.SmartNotification.notification_type == "behavior_reminder",
                models.SmartNotification.related_target_type == "water",
                func.date(models.SmartNotification.created_at) == today,
            )
            .first()
        )

        if not existing:
            water_messages = [
                "تذكير بشرب الماء! 💧 حافظ على ترطيب جسمك",
                "الماء ضروري لصحتك 🚰 اشرب كوباً الآن",
                "هل شربت كمية كافية من الماء اليوم؟ 💧 جرب كوباً الآن",
            ]
            notification = models.SmartNotification(
                user_id=user_id,
                notification_type="behavior_reminder",
                priority="info",
                title="تذكير بالماء 💧",
                message=random.choice(water_messages),
                context={
                    "trigger": "low_water_intake",
                    "today_water_count": today_water,
                    "suggestion": "اشرب 6-8 أكواب ماء يومياً",
                },
                target_date=today,
                related_target_type="water",
                sent_at=now,
            )
            db.add(notification)
            db.flush()
            generated.append(notification)

    # --- التحليل 3: تذكير بالوجبات إذا لم يسجل وجبات اليوم ---
    today_meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_id == user_id,
            func.date(models.Meal.created_at) == today,
        )
        .count()
    )

    if today_meals == 0 and now.hour >= 10:
        existing = (
            db.query(models.SmartNotification)
            .filter(
                models.SmartNotification.user_id == user_id,
                models.SmartNotification.notification_type == "behavior_reminder",
                models.SmartNotification.related_target_type == "all",
                func.date(models.SmartNotification.created_at) == today,
                models.SmartNotification.message.like("%وجبة%"),
            )
            .first()
        )

        if not existing:
            meal_messages = [
                "لم تسجل أي وجبة اليوم! 🍽️ تتبع طعامك يساعدك على تحقيق أهدافك",
                "تذكير بتسجيل الوجبات 📝 تتبع التغذية مهم لنجاح خطتك",
                "هل تناولت طعامك اليوم؟ 🥗 سجل وجباتك لمتابعة السعرات",
            ]
            notification = models.SmartNotification(
                user_id=user_id,
                notification_type="behavior_reminder",
                priority="info",
                title="تذكير بالوجبات 🍽️",
                message=random.choice(meal_messages),
                context={
                    "trigger": "no_meals_today",
                    "today_meal_count": 0,
                    "suggestion": "سجل وجباتك لمتابعة التغذية",
                },
                target_date=today,
                related_target_type="all",
                sent_at=now,
            )
            db.add(notification)
            db.flush()
            generated.append(notification)

    # --- التحليل 4: تذكير بالأدوية ---
    today_doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == user_id,
            func.date(models.MedicationDose.created_at) == today,
        )
        .count()
    )

    active_medications = (
        db.query(models.Medication)
        .filter(
            models.Medication.user_id == user_id,
            models.Medication.is_active == True,
        )
        .count()
    )

    if active_medications > 0 and today_doses == 0 and now.hour >= 8:
        existing = (
            db.query(models.SmartNotification)
            .filter(
                models.SmartNotification.user_id == user_id,
                models.SmartNotification.notification_type == "behavior_reminder",
                models.SmartNotification.related_target_type == "medication",
                func.date(models.SmartNotification.created_at) == today,
            )
            .first()
        )

        if not existing:
            notification = models.SmartNotification(
                user_id=user_id,
                notification_type="behavior_reminder",
                priority="important",
                title="تذكير بالأدوية 💊",
                message=f"لديك {active_medications} أدوية نشطة، لم تسجل أي جرعة اليوم!",
                context={
                    "trigger": "no_medication_doses",
                    "active_medications": active_medications,
                    "today_doses": 0,
                    "suggestion": "تذكر تناول أدويتك في الوقت المحدد",
                },
                target_date=today,
                related_target_type="medication",
                sent_at=now,
            )
            db.add(notification)
            db.flush()
            generated.append(notification)

    # --- التحليل 5: رسالة تحفيزية أسبوعية ---
    if now.weekday() == 6:
        existing_weekly = (
            db.query(models.SmartNotification)
            .filter(
                models.SmartNotification.user_id == user_id,
                models.SmartNotification.notification_type == "motivation",
                func.date(models.SmartNotification.created_at) == today,
            )
            .first()
        )

        if not existing_weekly:
            week_ago = today - timedelta(days=7)
            week_steps = (
                db.query(func.sum(models.WalkingActivity.steps))
                .filter(
                    models.WalkingActivity.user_id == user_id,
                    func.date(models.WalkingActivity.activity_date) >= week_ago,
                    func.date(models.WalkingActivity.activity_date) <= today,
                )
                .scalar()
            ) or 0

            motivational_messages = [
                f"أسبوع رائع! 🎉 مشيت {week_steps} خطوة هذا الأسبوع، استمر!",
                "كل خطوة صغيرة تقربك من هدفك الكبير 🌟 حافظ على التقدم",
                "أنت تبني عادات صحية يوماً بعد يوم 💪 استمر ولا تستسلم",
                "التغيير الحقيقي يبدأ بخطوة واحدة، وأنت تفعلها كل يوم 🚀",
            ]

            notification = models.SmartNotification(
                user_id=user_id,
                notification_type="motivation",
                priority="encouragement",
                title="رسالة تحفيزية 🌟",
                message=random.choice(motivational_messages),
                context={
                    "trigger": "weekly_motivation",
                    "week_steps": week_steps,
                    "week_start": week_ago.isoformat(),
                },
                target_date=today,
                related_target_type="all",
                sent_at=now,
            )
            db.add(notification)
            db.flush()
            generated.append(notification)

    if generated:
        db.commit()
        for n in generated:
            db.refresh(n)

    print(f"✅ تم توليد {len(generated)} إشعار ذكي")
    return generated


# ============================================
# ✅ 7. جلب تحليل السلوك والتوصيات
# ============================================
@router.get("/behavior-analysis")
def get_behavior_analysis(
    user_id: int = Query(..., description="معرف المستخدم"),
    db: Session = Depends(get_db),
):
    """تحليل سلوك المستخدم وتقديم توصيات ذكية"""
    print(f"\n📊 [SmartReminders] تحليل سلوك المستخدم {user_id}")

    today = date.today()
    week_ago = today - timedelta(days=7)

    week_steps = (
        db.query(func.sum(models.WalkingActivity.steps))
        .filter(
            models.WalkingActivity.user_id == user_id,
            func.date(models.WalkingActivity.activity_date) >= week_ago,
            func.date(models.WalkingActivity.activity_date) <= today,
        )
        .scalar()
    ) or 0

    week_walking_days = (
        db.query(func.count(func.distinct(
            func.date(models.WalkingActivity.activity_date)
        )))
        .filter(
            models.WalkingActivity.user_id == user_id,
            func.date(models.WalkingActivity.activity_date) >= week_ago,
            func.date(models.WalkingActivity.activity_date) <= today,
        )
        .scalar()
    ) or 0

    week_meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_id == user_id,
            func.date(models.Meal.created_at) >= week_ago,
            func.date(models.Meal.created_at) <= today,
        )
        .count()
    )

    week_doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == user_id,
            func.date(models.MedicationDose.created_at) >= week_ago,
            func.date(models.MedicationDose.created_at) <= today,
        )
        .count()
    )

    adherence_score = 0.0
    factors = []

    if week_walking_days >= 5:
        adherence_score += 0.3
        factors.append({"factor": "المشي", "status": "ممتاز", "score": 0.3})
    elif week_walking_days >= 3:
        adherence_score += 0.2
        factors.append({"factor": "المشي", "status": "جيد", "score": 0.2})
    else:
        factors.append({"factor": "المشي", "status": "بحاجة للتحسين", "score": 0.0})

    if week_meals >= 14:
        adherence_score += 0.35
        factors.append({"factor": "تسجيل الوجبات", "status": "ممتاز", "score": 0.35})
    elif week_meals >= 7:
        adherence_score += 0.2
        factors.append({"factor": "تسجيل الوجبات", "status": "جيد", "score": 0.2})
    else:
        factors.append({"factor": "تسجيل الوجبات", "status": "بحاجة للتحسين", "score": 0.0})

    if week_doses >= 14:
        adherence_score += 0.35
        factors.append({"factor": "الأدوية", "status": "ممتاز", "score": 0.35})
    elif week_doses >= 7:
        adherence_score += 0.2
        factors.append({"factor": "الأدوية", "status": "جيد", "score": 0.2})
    else:
        factors.append({"factor": "الأدوية", "status": "بحاجة للتحسين", "score": 0.0})

    recommendations = []
    if week_walking_days < 3:
        recommendations.append({
            "type": "walking",
            "priority": "high",
            "message": "حاول المشي 3-5 أيام في الأسبوع لتحسين نشاطك البدني",
        })
    if week_meals < 7:
        recommendations.append({
            "type": "nutrition",
            "priority": "medium",
            "message": "تسجيل الوجبات يساعدك على متابعة السعرات والعناصر الغذائية",
        })
    if week_doses < 7 and active_medications > 0:
        recommendations.append({
            "type": "medication",
            "priority": "high",
            "message": "انتظام الدواء مهم جداً لصحتك، استخدم التذكيرات",
        })

    return {
        "user_id": user_id,
        "period_days": 7,
        "adherence_score": round(adherence_score * 100, 1),
        "factors": factors,
        "statistics": {
            "total_steps": week_steps,
            "walking_days": week_walking_days,
            "total_meals": week_meals,
            "total_doses": week_doses,
        },
        "recommendations": recommendations,
    }