# backend/services/notification_service.py

import asyncio
from datetime import datetime, timedelta, date
from decimal import Decimal
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
import json
import logging

from database import get_db
import models
from services.fcm_service import send_notification_to_user

logger = logging.getLogger(__name__)


def _to_float(value: Any, default: float = 0.0) -> float:
    """Convert a value (Decimal, float, int, None) to Python float safely.
    Prevents 'unsupported operand types for -: float and decimal.Decimal' errors."""
    if value is None:
        return default
    if isinstance(value, Decimal):
        return float(value)
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


class NotificationService:
    """خدمة متكاملة لإدارة الإشعارات"""

    def __init__(self, db: Session):
        self.db = db

    # ============================================
    # ✅ 1. إنشاء إشعارات الأدوية
    # ============================================
    def create_medication_reminders(self, user_id: int) -> int:
        """إنشاء تذكيرات للأدوية لليوم"""
        today = date.today()
        now = datetime.now()

        medications = (
            self.db.query(models.Medication)
            .filter(
                models.Medication.user_id == user_id,
                models.Medication.start_date <= today,
                or_(
                    models.Medication.end_date >= today,
                    models.Medication.end_date == None,
                ),
            )
            .all()
        )

        reminders_created = 0

        for med in medications:
            times = json.loads(med.times)

            for time_str in times:
                hour, minute = map(int, time_str.split(":"))
                scheduled_time = datetime.combine(today, datetime.min.time()).replace(
                    hour=hour, minute=minute
                )

                if scheduled_time > now:
                    existing = (
                        self.db.query(models.NotificationLog)
                        .filter(
                            models.NotificationLog.user_id == user_id,
                            models.NotificationLog.notification_type == "medication",
                            models.NotificationLog.scheduled_time == scheduled_time,
                            models.NotificationLog.extra_data.contains(f'"{med.id}"'),
                        )
                        .first()
                    )

                    if not existing:
                        notification = models.NotificationLog(
                            user_id=user_id,
                            notification_type="medication",
                            notification_subtype="reminder",
                            title=f"💊 تذكير بدواء: {med.medicine.name_ar if med.medicine else 'دواء'}",
                            body=f"حان وقت تناول {med.medicine.name_ar if med.medicine else 'الدواء'} - {med.times_per_day} مرة يومياً",
                            scheduled_time=scheduled_time,
                            extra_data=json.dumps(
                                {
                                    "medication_id": med.id,
                                    "medicine_name": (
                                        med.medicine.name_ar if med.medicine else "دواء"
                                    ),
                                    "times_per_day": med.times_per_day,
                                    "with_food": med.with_food,
                                }
                            ),
                        )
                        self.db.add(notification)
                        reminders_created += 1

        self.db.commit()
        logger.info(
            f"✅ Created {reminders_created} medication reminders for user {user_id}"
        )
        return reminders_created

    # ============================================
    # ✅ 2. إنشاء إشعارات شرب الماء
    # ============================================
    def create_water_reminders(self, user_id: int) -> int:
        """إنشاء تذكيرات لشرب الماء بناءً على إعدادات المستخدم"""
        today = date.today()
        now = datetime.now()

        settings = (
            self.db.query(models.WaterSettings)
            .filter(models.WaterSettings.user_id == user_id)
            .first()
        )

        if not settings or not settings.enable_notifications:
            return 0

        daily_goal = _to_float(settings.daily_goal, 2.5)
        cup_size = _to_float(settings.cup_size, 0.25)
        cups_needed = int(daily_goal / cup_size)

        start_time = (
            settings.reminder_start or datetime.strptime("08:00", "%H:%M").time()
        )
        end_time = settings.reminder_end or datetime.strptime("22:00", "%H:%M").time()

        start_hour = start_time.hour
        end_hour = end_time.hour
        total_hours = end_hour - start_hour

        if total_hours <= 0 or cups_needed <= 0:
            return 0

        interval_hours = total_hours / cups_needed
        reminders_created = 0

        for i in range(cups_needed):
            hour = start_hour + int(i * interval_hours)
            minute = int((i * interval_hours % 1) * 60)

            if hour >= end_hour:
                break

            scheduled_time = datetime.combine(today, datetime.min.time()).replace(
                hour=hour, minute=minute
            )

            if scheduled_time > now:
                existing = (
                    self.db.query(models.NotificationLog)
                    .filter(
                        models.NotificationLog.user_id == user_id,
                        models.NotificationLog.notification_type == "water",
                        models.NotificationLog.scheduled_time == scheduled_time,
                    )
                    .first()
                )

                if not existing:
                    notification = models.NotificationLog(
                        user_id=user_id,
                        notification_type="water",
                        notification_subtype="reminder",
                        title="💧 تذكير بشرب الماء",
                        body=f"حان وقت شرب كوب ماء ({cup_size} لتر) - باقي اليوم {daily_goal - (i+1)*cup_size:.1f} لتر",
                        scheduled_time=scheduled_time,
                        extra_data=json.dumps(
                            {
                                "cup_number": i + 1,
                                "cups_remaining": cups_needed - i - 1,
                                "daily_goal": daily_goal,
                                "cup_size": cup_size,
                            }
                        ),
                    )
                    self.db.add(notification)
                    reminders_created += 1

        self.db.commit()
        logger.info(
            f"✅ Created {reminders_created} water reminders for user {user_id}"
        )
        return reminders_created

    # ============================================
    # ✅ 3. إنشاء ملخص يومي
    # ============================================
    def create_daily_summary(self, user_id: int) -> Optional[models.NotificationLog]:
        """إنشاء ملخص يومي للنشاطات"""
        today = date.today()
        yesterday = today - timedelta(days=1)

        yesterday_start = datetime.combine(yesterday, datetime.min.time())
        yesterday_end = datetime.combine(yesterday, datetime.max.time())

        walking_steps = _to_float(
            self.db.query(func.sum(models.WalkingActivity.steps))
            .filter(
                models.WalkingActivity.user_id == user_id,
                models.WalkingActivity.activity_date == yesterday,
            )
            .scalar(),
            0,
        )

        user_nutrition = (
            self.db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        meals = (
            self.db.query(models.Meal)
            .filter(
                (
                    models.Meal.user_nutrition_id == user_nutrition.id
                    if user_nutrition
                    else None
                ),
                models.Meal.date_time.between(yesterday_start, yesterday_end),
            )
            .all()
            if user_nutrition
            else []
        )

        calories_consumed = sum(_to_float(m.total_calories) for m in meals)

        water_intake = _to_float(
            self.db.query(func.sum(models.WaterIntake.amount))
            .filter(
                models.WaterIntake.user_id == user_id,
                models.WaterIntake.time.between(yesterday_start, yesterday_end),
            )
            .scalar(),
            0,
        )

        water_goal = _to_float(
            self.db.query(models.WaterSettings.daily_goal)
            .filter(models.WaterSettings.user_id == user_id)
            .scalar(),
            2.5,
        )

        new_symptoms = (
            self.db.query(models.Symptom)
            .filter(
                models.Symptom.user_id == user_id,
                models.Symptom.date_time.between(yesterday_start, yesterday_end),
            )
            .count()
        )

        taken_doses = (
            self.db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.user_id == user_id,
                models.MedicationDose.taken_time.between(
                    yesterday_start, yesterday_end
                ),
            )
            .count()
        )

        total_doses = (
            self.db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.user_id == user_id,
                models.MedicationDose.scheduled_time.between(
                    yesterday_start, yesterday_end
                ),
            )
            .count()
        )

        adherence = (taken_doses / total_doses * 100) if total_doses > 0 else 0

        notification = models.NotificationLog(
            user_id=user_id,
            notification_type="summary",
            notification_subtype="daily",
            title="📊 تقرير يومي - ملخص أمس",
            body=f"الخطوات: {walking_steps:,} | السعرات: {calories_consumed:.0f} | الماء: {water_intake:.1f}/{water_goal:.1f} لتر | الالتزام بالأدوية: {adherence:.0f}%",
            scheduled_time=datetime.now(),
            extra_data=json.dumps(
                {
                    "date": yesterday.isoformat(),
                    "steps": walking_steps,
                    "calories": calories_consumed,
                    "water": water_intake,
                    "water_goal": water_goal,
                    "new_symptoms": new_symptoms,
                    "medication_adherence": adherence,
                    "meals_count": len(meals),
                }
            ),
        )
        self.db.add(notification)
        self.db.commit()

        return notification

    # ============================================
    # ✅ 4. تحديث حالة الجرعات الفائتة
    # ============================================
    def update_missed_doses(self) -> int:
        """تحديث الجرعات الفائتة وإنشاء إشعارات لها"""
        now = datetime.now()
        one_hour_ago = now - timedelta(hours=1)

        missed_doses = (
            self.db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.status == "pending",
                models.MedicationDose.scheduled_time <= one_hour_ago,
            )
            .all()
        )

        updated = 0

        for dose in missed_doses:
            dose.status = "missed"
            updated += 1

            notification = models.NotificationLog(
                user_id=dose.user_id,
                notification_type="medication",
                notification_subtype="missed",
                title="⚠️ جرعة دواء فائتة",
                body=f"فاتتك جرعة دواء كان موعدها في {dose.scheduled_time.strftime('%H:%M')}",
                scheduled_time=now,
                extra_data=json.dumps(
                    {
                        "dose_id": dose.id,
                        "medication_id": dose.medication_id,
                        "scheduled_time": dose.scheduled_time.isoformat(),
                    }
                ),
            )
            self.db.add(notification)

        self.db.commit()

        if updated > 0:
            logger.info(f"✅ Updated {updated} missed doses and created notifications")

        return updated

    # ============================================
    # ✅ 5. إرسال إشعارات فورية
    # ============================================
    def send_instant_notification(
        self,
        user_id: int,
        notification_type: str,
        title: str,
        body: str,
        extra_data: Dict = None,
    ) -> models.NotificationLog:
        """إرسال إشعار فوري"""
        notification = models.NotificationLog(
            user_id=user_id,
            notification_type=notification_type,
            notification_subtype="instant",
            title=title,
            body=body,
            scheduled_time=datetime.now(),
            sent_time=datetime.now(),
            delivered=True,
            extra_data=json.dumps(extra_data) if extra_data else None,
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)

        logger.info(f"📨 Sent instant notification to user {user_id}: {title}")
        return notification

    # ============================================
    # ✅ 6. إشعارات الأهداف الديناميكية
    # ============================================
    def create_dynamic_target_notification(
        self, user_id: int, target: models.DynamicDailyTarget
    ) -> Optional[models.NotificationLog]:
        """إنشاء إشعار بتغيير الأهداف الديناميكية لليوم"""
        today = date.today()

        # Check if already sent today
        existing = (
            self.db.query(models.NotificationLog)
            .filter(
                models.NotificationLog.user_id == user_id,
                models.NotificationLog.notification_type == "dynamic_target",
                models.NotificationLog.notification_subtype == "daily_targets",
                models.NotificationLog.created_at
                >= datetime.now() - timedelta(hours=6),
            )
            .first()
        )
        if existing:
            return None

        # Compare with yesterday's targets to show change
        yesterday_target = (
            self.db.query(models.DynamicDailyTarget)
            .filter(
                models.DynamicDailyTarget.user_id == user_id,
                models.DynamicDailyTarget.date == today - timedelta(days=1),
            )
            .first()
        )

        changes = []
        if yesterday_target:
            cal_change = _to_float(target.target_calories) - _to_float(
                yesterday_target.target_calories
            )
            if abs(cal_change) > 50:
                direction = "زيادة" if cal_change > 0 else "تقليل"
                changes.append(f"{direction} {abs(cal_change):.0f} سعرة حرارية")

            steps_change = _to_float(target.target_steps) - _to_float(
                yesterday_target.target_steps
            )
            if abs(steps_change) > 500:
                direction = "زيادة" if steps_change > 0 else "تقليل"
                changes.append(f"{direction} {abs(steps_change):.0f} خطوة")

            water_change = _to_float(target.target_water) - _to_float(
                yesterday_target.target_water
            )
            if abs(water_change) > 0.2:
                direction = "زيادة" if water_change > 0 else "تقليل"
                changes.append(f"{direction} {abs(water_change):.1f} لتر ماء")

        body_parts = [
            f"🎯 السعرات: {_to_float(target.target_calories):.0f}",
            f"👣 الخطوات: {_to_float(target.target_steps):.0f}",
            f"💧 الماء: {_to_float(target.target_water):.1f} لتر",
        ]
        if target.target_protein:
            body_parts.append(f"🥩 البروتين: {_to_float(target.target_protein):.0f}جم")
        if target.target_carbs:
            body_parts.append(
                f"🍚 الكربوهيدرات: {_to_float(target.target_carbs):.0f}جم"
            )
        if target.target_fat:
            body_parts.append(f"🧈 الدهون: {_to_float(target.target_fat):.0f}جم")

        body = " | ".join(body_parts)

        if changes:
            title = "📊 أهدافك اليوم - تغييرات ملحوظة!"
            body = f"تغييرات عن أمس: {', '.join(changes)}\n{body}"
        else:
            title = "🎯 أهدافك اليومية"

        notification = models.NotificationLog(
            user_id=user_id,
            notification_type="dynamic_target",
            notification_subtype="daily_targets",
            title=title,
            body=body,
            scheduled_time=datetime.now(),
            extra_data=json.dumps(
                {
                    "target_calories": _to_float(target.target_calories),
                    "target_steps": _to_float(target.target_steps),
                    "target_water": _to_float(target.target_water),
                    "target_protein": _to_float(target.target_protein),
                    "target_carbs": _to_float(target.target_carbs),
                    "target_fat": _to_float(target.target_fat),
                    "performance_factor": _to_float(target.performance_factor),
                    "health_impact_percent": _to_float(target.health_impact_percent),
                    "weight_trend_factor": _to_float(target.weight_trend_factor),
                    "date": target.date.isoformat(),
                }
            ),
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def create_milestone_celebration(
        self, user_id: int, milestone: models.AchievementMilestone
    ) -> models.NotificationLog:
        """إنشاء إشعار احتفال بتحقيق إنجاز"""
        emoji_map = {
            "streak": "🔥",
            "adherence": "💪",
            "calories": "🎯",
            "steps": "👣",
            "water": "💧",
            "medication": "💊",
        }
        emoji = emoji_map.get(milestone.milestone_type, "🏆")

        notification = models.NotificationLog(
            user_id=user_id,
            notification_type="achievement",
            notification_subtype="milestone",
            title=f"{emoji} إنجاز جديد! {milestone.title}",
            body=milestone.description,
            scheduled_time=datetime.now(),
            sent_time=datetime.now(),
            delivered=True,
            extra_data=json.dumps(
                {
                    "milestone_id": milestone.id,
                    "milestone_type": milestone.milestone_type,
                    "milestone_value": milestone.milestone_value,
                    "milestone_key": milestone.milestone_key,
                    "points": milestone.points,
                    "icon": milestone.icon,
                }
            ),
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def create_smart_reminder(
        self, user_id: int, notification_type: str, context: Dict[str, Any]
    ) -> Optional[models.NotificationLog]:
        """إنشاء تذكير ذكي بناءً على أداء المستخدم والأهداف الديناميكية"""
        today = date.today()

        # Get today's dynamic target
        target = (
            self.db.query(models.DynamicDailyTarget)
            .filter(
                models.DynamicDailyTarget.user_id == user_id,
                models.DynamicDailyTarget.date == today,
            )
            .first()
        )

        if not target:
            return None

        title = ""
        body = ""
        extra = {"target_id": target.id, "date": today.isoformat()}

        if notification_type == "calories_reminder":
            # Check meals logged today
            meals_today = (
                self.db.query(models.Meal)
                .join(models.UserNutrition)
                .filter(
                    models.UserNutrition.user_id == user_id,
                    models.Meal.date_time >= datetime.now() - timedelta(hours=12),
                )
                .count()
            )

            if meals_today == 0:
                title = "🍽️ لم تسجل وجباتك اليوم!"
                body = f"هدفك اليوم {_to_float(target.target_calories):.0f} سعرة. سجل وجباتك لمتابعة التقدم."
                extra["reminder_type"] = "no_meals_logged"
            elif meals_today < 2:
                title = "🍽️ تذكير بالوجبات"
                body = f"سجلت {meals_today} وجبات فقط. هدفك اليوم {_to_float(target.target_calories):.0f} سعرة."
                extra["reminder_type"] = "few_meals"

        elif notification_type == "water_reminder":
            # Check water intake today
            water_today = _to_float(
                self.db.query(func.sum(models.WaterIntake.amount))
                .filter(
                    models.WaterIntake.user_id == user_id,
                    models.WaterIntake.time >= datetime.now() - timedelta(hours=12),
                )
                .scalar(),
                0,
            )

            remaining = _to_float(target.target_water) - water_today
            if remaining > 0.5:
                title = "💧 تذكير بشرب الماء"
                body = f"شربت {water_today:.1f}لتر من أصل {_to_float(target.target_water):.1f}لتر. متبقي {remaining:.1f}لتر!"
                extra["reminder_type"] = "water_remaining"
                extra["water_remaining"] = remaining

        elif notification_type == "steps_reminder":
            # Check steps today
            steps_today = _to_float(
                self.db.query(func.sum(models.WalkingActivity.steps))
                .filter(
                    models.WalkingActivity.user_id == user_id,
                    models.WalkingActivity.activity_date == today,
                )
                .scalar(),
                0,
            )

            remaining = _to_float(target.target_steps) - steps_today
            if remaining > 1000:
                title = "👣 تذكير بالمشي"
                body = f"مشيت {steps_today:.0f} خطوة من أصل {_to_float(target.target_steps):.0f}. متبقي {remaining:.0f} خطوة!"
                extra["reminder_type"] = "steps_remaining"
                extra["steps_remaining"] = remaining

        elif notification_type == "medication_reminder":
            # Check medication adherence today
            today_start = datetime.combine(today, datetime.min.time())
            today_end = datetime.combine(today, datetime.max.time())

            taken_doses = (
                self.db.query(models.MedicationDose)
                .filter(
                    models.MedicationDose.user_id == user_id,
                    models.MedicationDose.taken_time.between(today_start, today_end),
                )
                .count()
            )

            total_doses = (
                self.db.query(models.MedicationDose)
                .filter(
                    models.MedicationDose.user_id == user_id,
                    models.MedicationDose.scheduled_time.between(
                        today_start, today_end
                    ),
                )
                .count()
            )

            if total_doses > 0 and taken_doses < total_doses:
                remaining = total_doses - taken_doses
                title = "💊 تذكير بالأدوية"
                body = f"أخذت {taken_doses} من {total_doses} جرعات اليوم. متبقي {remaining} جرعات!"
                extra["reminder_type"] = "medication_remaining"
                extra["taken_doses"] = taken_doses
                extra["total_doses"] = total_doses

        if not title:
            return None

        notification = models.NotificationLog(
            user_id=user_id,
            notification_type="smart_reminder",
            notification_subtype=notification_type,
            title=title,
            body=body,
            scheduled_time=datetime.now(),
            sent_time=datetime.now(),
            delivered=True,
            extra_data=json.dumps(extra),
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)

        # 🚀 Send FCM push notification
        try:
            send_notification_to_user(
                self.db, user_id, title, body,
                data={"type": "smart_reminder", "subtype": notification_type}
            )
        except Exception as e:
            logger.warning(f"⚠️ FCM send failed for smart reminder (user {user_id}): {e}")

        return notification

    def create_performance_summary_notification(
        self, user_id: int, performance: models.PerformanceHistory
    ) -> models.NotificationLog:
        """إنشاء إشعار ملخص الأداء اليومي"""
        score = _to_float(performance.overall_score)
        if score >= 90:
            emoji = "🌟"
            message = "أداء ممتاز! استمر بنفس المستوى!"
        elif score >= 75:
            emoji = "👍"
            message = "أداء جيد جداً! حاول تحسين النقاط المتبقية."
        elif score >= 60:
            emoji = "💪"
            message = "أداء متوسط. ركز على تحسين التزامك غداً!"
        else:
            emoji = "📈"
            message = "يمكنك الأفضل! كل يوم فرصة جديدة للتحسن."

        details = []
        if performance.calories_score is not None:
            details.append(f"السعرات: {_to_float(performance.calories_score):.0f}%")
        if performance.steps_score is not None:
            details.append(f"الخطوات: {_to_float(performance.steps_score):.0f}%")
        if performance.water_score is not None:
            details.append(f"الماء: {_to_float(performance.water_score):.0f}%")
        if performance.medication_score is not None:
            details.append(f"الأدوية: {_to_float(performance.medication_score):.0f}%")

        body = f"التقييم العام: {score:.0f}%\n"
        body += " | ".join(details)
        body += f"\n{message}"

        notification = models.NotificationLog(
            user_id=user_id,
            notification_type="performance",
            notification_subtype="daily_summary",
            title=f"{emoji} ملخص أدائك اليوم",
            body=body,
            scheduled_time=datetime.now(),
            sent_time=datetime.now(),
            delivered=True,
            extra_data=json.dumps(
                {
                    "overall_score": _to_float(score),
                    "calories_score": _to_float(performance.calories_score),
                    "steps_score": _to_float(performance.steps_score),
                    "water_score": _to_float(performance.water_score),
                    "medication_score": _to_float(performance.medication_score),
                    "date": performance.date.isoformat(),
                }
            ),
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    # ============================================
    # ✅ 7. تشغيل جميع المهام المجدولة
    # ============================================
    def run_scheduled_tasks(self, user_id: int = None) -> Dict[str, int]:
        """تشغيل جميع مهام الإشعارات المجدولة"""
        results = {
            "medication_reminders": 0,
            "water_reminders": 0,
            "missed_doses_updated": 0,
            "daily_summary_created": 0,
        }

        if user_id:
            results["medication_reminders"] = self.create_medication_reminders(user_id)
            results["water_reminders"] = self.create_water_reminders(user_id)
            results["missed_doses_updated"] = self.update_missed_doses()

            last_summary = (
                self.db.query(models.NotificationLog)
                .filter(
                    models.NotificationLog.user_id == user_id,
                    models.NotificationLog.notification_type == "summary",
                    models.NotificationLog.created_at
                    >= datetime.now() - timedelta(hours=24),
                )
                .first()
            )

            if not last_summary:
                summary = self.create_daily_summary(user_id)
                if summary:
                    results["daily_summary_created"] = 1
        else:
            active_users = (
                self.db.query(models.User).filter(models.User.is_active == True).all()
            )

            for user in active_users:
                user_results = self.run_scheduled_tasks(user.id)
                for key in results:
                    results[key] += user_results[key]

        return results
