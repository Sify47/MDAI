# backend/routers/notifications.py

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta, date
from pydantic import BaseModel
import json

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


# ============================================
# نماذج Pydantic
# ============================================
class NotificationActionUpdate(BaseModel):
    action_taken: str
    action_time: datetime


class InstantNotificationRequest(BaseModel):
    title: str
    body: str
    notification_type: str = "general"
    extra_data: Optional[dict] = None


class NotificationLogCreate(BaseModel):
    user_id: int
    notification_type: str
    notification_subtype: Optional[str] = None
    title: str
    body: str
    scheduled_time: datetime
    extra_data: Optional[dict] = None


# ============================================
# ✅ 1. تسجيل إشعار جديد (من Flutter)
# ============================================
@router.post("/log", status_code=201)
def log_notification(
    notification: NotificationLogCreate, db: Session = Depends(get_db)
):
    """تسجيل إشعار في قاعدة البيانات (من Flutter)"""
    print(
        f"📝 [Backend] تسجيل إشعار: {notification.notification_type} - {notification.title}"
    )

    db_notification = models.NotificationLog(
        user_id=notification.user_id,
        notification_type=notification.notification_type,
        notification_subtype=notification.notification_subtype,
        title=notification.title,
        body=notification.body,
        scheduled_time=notification.scheduled_time,
        sent_time=None,
        delivered=False,
        extra_data=(
            json.dumps(notification.extra_data) if notification.extra_data else None
        ),
    )
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)

    print(f"✅ تم تسجيل الإشعار ID: {db_notification.id}")
    return {"success": True, "id": db_notification.id}


# ============================================
# ✅ 2. تشغيل جميع تذكيرات اليوم
# ============================================
@router.post("/run-daily-reminders")
def run_daily_reminders(
    background_tasks: BackgroundTasks,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تشغيل جميع تذكيرات اليوم للمستخدم الحالي"""
    from services.notification_service import NotificationService

    service = NotificationService(db)
    background_tasks.add_task(service.run_scheduled_tasks, current_user.id)

    return {
        "success": True,
        "message": "جاري إنشاء التذكيرات في الخلفية",
        "user_id": current_user.id,
    }


# ============================================
# ✅ 3. فحص الجرعات الفائتة
# ============================================
@router.post("/check-missed-doses")
def check_missed_doses(
    current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """فحص وتحديث الجرعات الفائتة"""
    from services.notification_service import NotificationService

    service = NotificationService(db)
    updated = service.update_missed_doses()

    return {
        "success": True,
        "missed_doses_updated": updated,
        "message": f"تم تحديث {updated} جرعة فائتة",
    }


# ============================================
# ✅ 4. إرسال إشعار فوري
# ============================================
@router.post("/send-instant")
def send_instant_notification(
    notification: InstantNotificationRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إرسال إشعار فوري للمستخدم"""
    from services.notification_service import NotificationService

    service = NotificationService(db)

    created = service.send_instant_notification(
        user_id=current_user.id,
        notification_type=notification.notification_type,
        title=notification.title,
        body=notification.body,
        extra_data=notification.extra_data,
    )

    return {
        "success": True,
        "notification_id": created.id,
        "message": "تم إرسال الإشعار",
    }


# ============================================
# ✅ 5. جلب إشعارات اليوم للمستخدم الحالي
# ============================================
@router.get("/today")
def get_today_notifications(
    current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """جلب إشعارات اليوم للمستخدم الحالي"""
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())

    notifications = (
        db.query(models.NotificationLog)
        .filter(
            models.NotificationLog.user_id == current_user.id,
            models.NotificationLog.scheduled_time.between(today_start, today_end),
        )
        .order_by(models.NotificationLog.scheduled_time)
        .all()
    )

    upcoming = [
        n
        for n in notifications
        if n.scheduled_time > datetime.now() and not n.sent_time
    ]
    sent = [n for n in notifications if n.sent_time]

    # تحويل الإشعارات إلى JSON
    upcoming_list = []
    for n in upcoming:
        upcoming_list.append(
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "notification_type": n.notification_type,
                "scheduled_time": n.scheduled_time.isoformat(),
                "extra_data": json.loads(n.extra_data) if n.extra_data else None,
            }
        )

    return {
        "success": True,
        "date": today.isoformat(),
        "upcoming_count": len(upcoming),
        "sent_count": len(sent),
        "upcoming": upcoming_list,
        "sent": [n.id for n in sent],
    }


# ============================================
# ✅ 6. تحديث استجابة المستخدم للإشعار
# ============================================
@router.put("/{notification_id}/action")
def update_notification_action(
    notification_id: int,
    action: NotificationActionUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تحديث استجابة المستخدم للإشعار"""

    notification = (
        db.query(models.NotificationLog)
        .filter(
            models.NotificationLog.id == notification_id,
            models.NotificationLog.user_id == current_user.id,
        )
        .first()
    )

    if not notification:
        raise HTTPException(status_code=404, detail="الإشعار غير موجود")

    notification.action_taken = action.action_taken
    notification.action_time = action.action_time

    db.commit()

    return {"success": True, "message": "تم تحديث الاستجابة"}


# ============================================
# ✅ 7. جلب إحصائيات الإشعارات
# ============================================
@router.get("/stats")
def get_notification_stats(
    current_user: models.User = Depends(get_current_user),
    days_back: int = 30,
    db: Session = Depends(get_db),
):
    """جلب إحصائيات الإشعارات للمستخدم الحالي"""

    start_date = datetime.now() - timedelta(days=days_back)

    total = (
        db.query(models.NotificationLog)
        .filter(
            models.NotificationLog.user_id == current_user.id,
            models.NotificationLog.created_at >= start_date,
        )
        .count()
    )

    by_type = (
        db.query(
            models.NotificationLog.notification_type,
            func.count(models.NotificationLog.id).label("count"),
        )
        .filter(
            models.NotificationLog.user_id == current_user.id,
            models.NotificationLog.created_at >= start_date,
        )
        .group_by(models.NotificationLog.notification_type)
        .all()
    )

    responded = (
        db.query(models.NotificationLog)
        .filter(
            models.NotificationLog.user_id == current_user.id,
            models.NotificationLog.created_at >= start_date,
            models.NotificationLog.action_taken.isnot(None),
        )
        .count()
    )

    response_rate = (responded / total * 100) if total > 0 else 0

    return {
        "success": True,
        "total_notifications": total,
        "responded_count": responded,
        "response_rate": round(response_rate, 1),
        "by_type": [{"type": t[0], "count": t[1]} for t in by_type],
        "period_days": days_back,
    }


# ============================================
# ✅ 8. جلب قائمة الإشعارات
# ============================================
@router.get("/list")
def get_notifications_list(
    current_user: models.User = Depends(get_current_user),
    limit: int = 50,
    offset: int = 0,
    notification_type: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """جلب قائمة الإشعارات للمستخدم"""

    query = db.query(models.NotificationLog).filter(
        models.NotificationLog.user_id == current_user.id
    )

    if notification_type:
        query = query.filter(
            models.NotificationLog.notification_type == notification_type
        )

    total = query.count()

    notifications = (
        query.order_by(models.NotificationLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    notifications_list = []
    for n in notifications:
        notifications_list.append(
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "notification_type": n.notification_type,
                "notification_subtype": n.notification_subtype,
                "scheduled_time": (
                    n.scheduled_time.isoformat() if n.scheduled_time else None
                ),
                "sent_time": n.sent_time.isoformat() if n.sent_time else None,
                "action_taken": n.action_taken,
                "action_time": n.action_time.isoformat() if n.action_time else None,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
        )

    return {
        "success": True,
        "total": total,
        "limit": limit,
        "offset": offset,
        "notifications": notifications_list,
    }


# ============================================
# ✅ 9. تنظيف الإشعارات القديمة
# ============================================
@router.delete("/cleanup")
def cleanup_old_notifications(
    current_user: models.User = Depends(get_current_user),
    days_old: int = 90,
    db: Session = Depends(get_db),
):
    """حذف الإشعارات الأقدم من عدد محدد من الأيام"""

    cutoff_date = datetime.now() - timedelta(days=days_old)

    deleted = (
        db.query(models.NotificationLog)
        .filter(
            models.NotificationLog.user_id == current_user.id,
            models.NotificationLog.created_at < cutoff_date,
        )
        .delete()
    )

    db.commit()

    return {
        "success": True,
        "deleted_count": deleted,
        "message": f"تم حذف {deleted} إشعار أقدم من {days_old} يوم",
    }
