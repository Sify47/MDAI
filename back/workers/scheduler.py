# backend/workers/scheduler.py

import asyncio
import logging
import subprocess
import sys
import os
from datetime import datetime, date
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session

from database import SessionLocal
import models
from services.notification_service import NotificationService
from services.dynamic_targets_service import DynamicTargetsService

logger = logging.getLogger(__name__)

# إنشاء المجدول
# ⚙️ job_defaults: coalesce=True → دمج التشغيلات الفائتة في تشغيلة واحدة
#                   misfire_grace_time=3600 → السماح بتشغيل المهام الفائتة حتى ساعة
scheduler = AsyncIOScheduler(
    job_defaults={
        'coalesce': True,
        'misfire_grace_time': 3600,  # ساعة واحدة كافية لمعظم المهام
    }
)


async def run_notification_tasks():
    """تشغيل جميع مهام الإشعارات لجميع المستخدمين"""
    logger.info("🔄 Running scheduled notification tasks...")

    db = SessionLocal()
    try:
        service = NotificationService(db)
        results = service.run_scheduled_tasks()  # بدون user_id = لجميع المستخدمين

        logger.info(f"✅ Tasks completed: {results}")
    except Exception as e:
        logger.error(f"❌ Error in notification tasks: {e}")
    finally:
        db.close()


async def run_missed_doses_check():
    """فحص الجرعات الفائتة كل ساعة"""
    logger.info("🔄 Checking missed doses...")

    db = SessionLocal()
    try:
        service = NotificationService(db)
        updated = service.update_missed_doses()

        if updated > 0:
            logger.info(f"✅ Updated {updated} missed doses")
    except Exception as e:
        logger.error(f"❌ Error checking missed doses: {e}")
    finally:
        db.close()


async def run_dynamic_targets_generation():
    """إنشاء الأهداف الديناميكية اليومية لجميع المستخدمين"""
    logger.info("🔄 Running dynamic targets generation for all users...")

    db = SessionLocal()
    try:
        service = DynamicTargetsService(db)
        results = service.run_for_all_users()

        # Send notifications for generated targets
        notification_service = NotificationService(db)
        for user_id in results.get("processed_users", []):
            target = (
                db.query(models.DynamicDailyTarget)
                .filter(
                    models.DynamicDailyTarget.user_id == user_id,
                    models.DynamicDailyTarget.date == date.today(),
                )
                .first()
            )
            if target:
                notification_service.create_dynamic_target_notification(user_id, target)

        logger.info(f"✅ Dynamic targets generated: {results}")
    except Exception as e:
        logger.error(f"❌ Error in dynamic targets generation: {e}")
    finally:
        db.close()


async def run_performance_calculation():
    """حساب أداء المستخدمين لليوم"""
    logger.info("🔄 Running daily performance calculation...")

    db = SessionLocal()
    try:
        service = DynamicTargetsService(db)
        results = service.run_for_all_users()

        # Calculate performance for all users
        active_users = db.query(models.User).filter(models.User.is_active == True).all()
        notification_service = NotificationService(db)
        performance_count = 0

        for user in active_users:
            try:
                performance = service.calculate_daily_performance(user.id, date.today())
                if performance:
                    notification_service.create_performance_summary_notification(
                        user.id, performance
                    )
                    performance_count += 1
            except Exception as e:
                logger.warning(f"⚠️ Performance calc failed for user {user.id}: {e}")

        logger.info(f"✅ Performance calculated for {performance_count} users")
    except Exception as e:
        logger.error(f"❌ Error in performance calculation: {e}")
    finally:
        db.close()


async def run_smart_reminders():
    """إرسال التذكيرات الذكية للمستخدمين النشطين"""
    logger.info("🔄 Running smart reminders...")

    db = SessionLocal()
    try:
        active_users = db.query(models.User).filter(models.User.is_active == True).all()
        notification_service = NotificationService(db)
        reminder_types = ["water_reminder", "steps_reminder", "medication_reminder"]
        total_sent = 0

        for user in active_users:
            for reminder_type in reminder_types:
                try:
                    notification = notification_service.create_smart_reminder(
                        user.id, reminder_type, {}
                    )
                    if notification:
                        total_sent += 1
                except Exception as e:
                    logger.warning(f"⚠️ Smart reminder failed for user {user.id}: {e}")

        logger.info(f"✅ Sent {total_sent} smart reminders")
    except Exception as e:
        logger.error(f"❌ Error in smart reminders: {e}")
    finally:
        db.close()


async def run_real_estate_scraper():
    """تشغيل سكريبر العقارات من Bayut وإرسالها للـ API"""
    logger.info("🏠 Running Real Estate scraper...")

    # المسار لمجلد Real-Estate-main
    scraper_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Real-Estate-main"
    )
    scraper_script = os.path.join(scraper_dir, "scrape_data.py")

    if not os.path.exists(scraper_script):
        logger.error(f"❌ Scraper script not found at {scraper_script}")
        return

    try:
        # تشغيل السكريبر في عملية منفصلة
        result = subprocess.run(
            [sys.executable, scraper_script],
            cwd=scraper_dir,
            capture_output=True,
            text=True,
            timeout=600,  # 10 دقائق كحد أقصى
        )

        # تسجيل الإخراج
        for line in result.stdout.splitlines():
            logger.info(f"🏠 {line}")

        if result.returncode == 0:
            logger.info("✅ Real Estate scraper completed successfully")
        else:
            logger.error(f"❌ Real Estate scraper failed with code {result.returncode}")
            for line in result.stderr.splitlines():
                logger.error(f"🏠 {line}")

    except subprocess.TimeoutExpired:
        logger.error("❌ Real Estate scraper timed out after 10 minutes")
    except Exception as e:
        logger.error(f"❌ Real Estate scraper error: {e}")


def _should_run_on_startup(job_id: str) -> bool:
    """تحديد إذا كانت المهمة تحتاج للتشغيل فور بدء التشغيل"""
    now = datetime.now()
    current_hour = now.hour

    # مهام يومية: تشغل فقط إذا فات وقتها لليوم
    startup_checks = {
        "daily_notifications": current_hour >= 6,
        "dynamic_targets_generation": current_hour >= 6 and current_hour < 21,
        "daily_performance": current_hour >= 21,
        "real_estate_scraper": current_hour >= 8,
    }
    return startup_checks.get(job_id, False)


async def _run_startup_catchup():
    """تشغيل المهام اليومية الفائتة عند بدء التشغيل"""
    now = datetime.now()
    current_hour = now.hour
    logger.info(f"🚀 Startup catch-up check (hour={current_hour})")

    if current_hour >= 6:
        logger.info("🚀 Running missed daily notifications...")
        await run_notification_tasks()
        logger.info("🚀 Running missed dynamic targets generation...")
        await run_dynamic_targets_generation()

    if current_hour >= 8:
        logger.info("🚀 Running missed real estate scraper...")
        await run_real_estate_scraper()

    if current_hour >= 21:
        logger.info("🚀 Running missed daily performance calculation...")
        await run_performance_calculation()

    # تشغيل المهام الساعية فوراً (Missed doses, Smart reminders)
    logger.info("🚀 Running missed missed-doses check...")
    await run_missed_doses_check()

    # التذكيرات الذكية: تشغل إذا فاتت الـ 9ص, 12م, 3ع, 6م
    reminder_hours = [9, 12, 15, 18]
    last_missed_hour = max((h for h in reminder_hours if h <= current_hour), default=None)
    if last_missed_hour is not None:
        logger.info(f"🚀 Running missed smart reminders (missed {last_missed_hour}:00)...")
        await run_smart_reminders()

    logger.info("✅ Startup catch-up completed")


def setup_scheduler():
    """إعداد وتشغيل المجدول"""

    # تشغيل مهام الإشعارات كل يوم في الساعة 6 صباحاً
    scheduler.add_job(
        run_notification_tasks,
        trigger=CronTrigger(hour=6, minute=0),
        id="daily_notifications",
        name="Daily Notifications",
        replace_existing=True,
    )

    # إنشاء الأهداف الديناميكية كل يوم في الساعة 6:30 صباحاً (بعد الإشعارات)
    scheduler.add_job(
        run_dynamic_targets_generation,
        trigger=CronTrigger(hour=6, minute=30),
        id="dynamic_targets_generation",
        name="Dynamic Targets Generation",
        replace_existing=True,
    )

    # حساب الأداء اليومي كل يوم في الساعة 9 مساءً
    scheduler.add_job(
        run_performance_calculation,
        trigger=CronTrigger(hour=21, minute=0),
        id="daily_performance",
        name="Daily Performance Calculation",
        replace_existing=True,
    )

    # التذكيرات الذكية كل 3 ساعات (9ص، 12م، 3ع، 6م)
    scheduler.add_job(
        run_smart_reminders,
        trigger=CronTrigger(hour="9,12,15,18", minute=0),
        id="smart_reminders",
        name="Smart Reminders",
        replace_existing=True,
    )

    # فحص الجرعات الفائتة كل ساعة
    scheduler.add_job(
        run_missed_doses_check,
        trigger=CronTrigger(minute=0),  # كل ساعة عند الدقيقة 0
        id="missed_doses_check",
        name="Missed Doses Check",
        replace_existing=True,
    )

    # تشغيل سكريبر العقارات كل يوم في الساعة 8 صباحاً
    scheduler.add_job(
        run_real_estate_scraper,
        trigger=CronTrigger(hour=8, minute=0),
        id="real_estate_scraper",
        name="Real Estate Scraper (Bayut)",
        replace_existing=True,
    )

    scheduler.start()
    logger.info("✅ Scheduler started successfully")

    # تشغيل المهام الفائتة عند بدء التشغيل
    asyncio.create_task(_run_startup_catchup())

    return scheduler
