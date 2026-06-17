# backend/routers/medications.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import extract, or_
from typing import List
import json
from datetime import datetime, date, timedelta
from pydantic import BaseModel

from database import get_db
import models
import schemas
from routers.auth import get_current_user  # ✅ استيراد دالة جلب المستخدم الحالي
from core.cache_config import cache_result, invalidate_cache

router = APIRouter(prefix="/medications", tags=["medications"])


# ============================================
# Pydantic Models
# ============================================
class DoseTaken(BaseModel):
    medication_id: int
    taken_time: datetime


# ============================================
# ============================================
# ✅ 1. APIs الأدوية العامة (Medicine Database)
# ============================================
# ============================================


# GET /medications/all-medicines - جلب كل الأدوية من قاعدة البيانات العامة
# جلب كل الأدوية من قاعدة البيانات العامة
@router.get("/all-medicines")
@cache_result(ttl=7200, key_prefix="medicines_all")  # ✅ ساعتين
def get_all_medicines(db: Session = Depends(get_db)):
    """جلب كل الأدوية من قاعدة البيانات العامة"""
    medicines = db.query(models.Medicine).all()
    return [med.to_dict() for med in medicines]


# GET /medications/search-medicines - البحث عن أدوية في قاعدة البيانات العامة
# البحث عن أدوية
@router.get("/search-medicines")
@cache_result(ttl=3600, key_prefix="medicines_search")  # ✅ ساعة
def search_medicines(q: str, db: Session = Depends(get_db)):
    """البحث عن أدوية في قاعدة البيانات العامة"""
    print(f"🔍 البحث عن أدوية: {q}")

    medicines = (
        db.query(models.Medicine)
        .filter(
            or_(
                models.Medicine.name_ar.contains(q),
                models.Medicine.name_en.contains(q),
                models.Medicine.generic_name.contains(q),
            )
        )
        .limit(10)
        .all()
    )

    return [med.to_dict() for med in medicines]


# GET /medications/get-medicine/{id} - جلب دواء محدد من قاعدة البيانات العامة
@router.get("/get-medicine/{id}")
def get_medicine(id: int, db: Session = Depends(get_db)):
    """جلب دواء محدد من قاعدة البيانات العامة"""
    medicine = db.query(models.Medicine).filter(models.Medicine.id == id).first()
    if not medicine:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")
    return medicine.to_dict()


# ============================================
# ============================================
# ✅ 2. APIs الأدوية الخاصة بالمستخدم (User Medications)
# ============================================
# ============================================


# GET /medications - عرض أدوية المستخدم الحالي
@router.get("/", response_model=List[schemas.MedicationResponse])
def get_medications(
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """عرض أدوية المستخدم الحالي"""
    print(f"🔍 جلب أدوية المستخدم: {current_user.id}")

    medications = (
        db.query(models.Medication)
        .filter(models.Medication.user_id == current_user.id)
        .all()
    )
    return [med.to_dict() for med in medications]


# POST /medications - إضافة دواء جديد للمستخدم الحالي
@router.post("/", response_model=schemas.MedicationResponse, status_code=201)
@invalidate_cache(pattern="medicines_search:*")  # ✅ مسح الكاش عند إضافة دواء جديد
def create_medication(
    medication: schemas.MedicationCreate,
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """إضافة دواء جديد للمستخدم الحالي"""
    print(f"📝 إضافة دواء للمستخدم: {current_user.id}")

    # ✅ التحقق من وجود الدواء في قاعدة البيانات العامة
    medicine = (
        db.query(models.Medicine)
        .filter(models.Medicine.id == medication.medicine_id)
        .first()
    )
    if not medicine:
        raise HTTPException(
            status_code=404, detail="الدواء غير موجود في قاعدة البيانات"
        )

    # تحويل الأوقات لـ JSON
    times_json = json.dumps(medication.times)

    # إنشاء الدواء مع user_id من التوكن
    db_medication = models.Medication(
        user_id=current_user.id,  # ✅ من التوكن
        medicine_id=medication.medicine_id,
        times_per_day=medication.times_per_day,
        times=times_json,
        with_food=medication.with_food,
        start_date=medication.start_date,
        end_date=medication.end_date,
        notes=medication.notes,
    )
    db.add(db_medication)
    db.commit()
    db.refresh(db_medication)

    # إنشاء الجرعات للأيام القادمة
    _create_doses_for_medication(db, db_medication, current_user.id)

    return db_medication.to_dict()


# PUT /medications/{id} - تحديث دواء
@router.put("/{id}", response_model=schemas.MedicationResponse)
def update_medication(
    id: int,
    medication: schemas.MedicationUpdate,
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """تحديث بيانات دواء"""
    print(f"📝 تحديث دواء {id} للمستخدم: {current_user.id}")

    db_medication = (
        db.query(models.Medication)
        .filter(
            models.Medication.id == id,
            models.Medication.user_id == current_user.id,  # ✅ تأكد أن الدواء للمستخدم
        )
        .first()
    )
    if not db_medication:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")

    # تحديث البيانات
    db_medication.times_per_day = medication.times_per_day
    db_medication.times = json.dumps(medication.times)
    db_medication.with_food = medication.with_food
    db_medication.start_date = medication.start_date
    db_medication.end_date = medication.end_date
    db_medication.notes = medication.notes

    db.commit()
    db.refresh(db_medication)

    return db_medication.to_dict()


# DELETE /medications/{id} - حذف دواء
@router.delete("/{id}")
def delete_medication(
    id: int,
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """حذف دواء"""
    print(f"🗑️ حذف دواء {id} للمستخدم: {current_user.id}")

    db_medication = (
        db.query(models.Medication)
        .filter(
            models.Medication.id == id,
            models.Medication.user_id == current_user.id,  # ✅ تأكد أن الدواء للمستخدم
        )
        .first()
    )
    if not db_medication:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")

    db.delete(db_medication)
    db.commit()
    return {"message": "تم حذف الدواء بنجاح"}


# ============================================
# ============================================
# ✅ 3. APIs الجرعات (Doses)
# ============================================
# ============================================


# GET /medications/doses/today - كل جرعات اليوم للمستخدم الحالي
@router.get("/doses/today")
def get_all_today_doses(
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """جلب كل جرعات اليوم للمستخدم الحالي"""
    print(f"🔍 جلب جرعات اليوم للمستخدم: {current_user.id}")

    today = date.today()
    start = datetime.combine(today, datetime.min.time())
    end = datetime.combine(today, datetime.max.time())

    doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == current_user.id,
            models.MedicationDose.scheduled_time.between(start, end),
        )
        .all()
    )

    return [dose.to_dict() for dose in doses]


# GET /medications/{id}/doses - جرعات دواء محدد
@router.get("/{id}/doses")
def get_medication_doses(
    id: int,
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """جلب جرعات دواء محدد"""
    print(f"🔍 جلب جرعات الدواء {id} للمستخدم: {current_user.id}")

    doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.medication_id == id,
            models.MedicationDose.user_id == current_user.id,
        )
        .order_by(models.MedicationDose.scheduled_time.desc())
        .all()
    )

    return [dose.to_dict() for dose in doses]


# GET /medications/{id}/doses/today - جرعات دواء محدد لليوم
@router.get("/{id}/doses/today")
def get_today_doses(
    id: int,
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """جلب جرعات دواء محدد لليوم"""
    print(f"🔍 جلب جرعات اليوم للدواء {id} للمستخدم: {current_user.id}")

    today = date.today()
    start = datetime.combine(today, datetime.min.time())
    end = datetime.combine(today, datetime.max.time())

    doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.medication_id == id,
            models.MedicationDose.user_id == current_user.id,
            models.MedicationDose.scheduled_time.between(start, end),
        )
        .all()
    )

    return [dose.to_dict() for dose in doses]


# GET /medications/doses/upcoming - الجرعات القادمة (خلال 12 ساعة)
@router.get("/doses/upcoming")
def get_upcoming_doses(
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """جلب الجرعات القادمة خلال 12 ساعة"""
    print(f"🔍 جلب الجرعات القادمة للمستخدم: {current_user.id}")

    now = datetime.now()
    end = now + timedelta(hours=12)

    doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == current_user.id,
            models.MedicationDose.scheduled_time.between(now, end),
            models.MedicationDose.taken_time.is_(None),
        )
        .order_by(models.MedicationDose.scheduled_time)
        .all()
    )

    return [dose.to_dict() for dose in doses]


# GET /medications/doses/all - جلب كل الجرعات (لكل الأوقات)
@router.get("/doses/all")
def get_all_doses(
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """جلب كل الجرعات للمستخدم الحالي (لكل الأوقات وليس اليوم فقط)"""
    print(f"🔍 جلب كل الجرعات للمستخدم: {current_user.id}")

    doses = (
        db.query(models.MedicationDose)
        .filter(models.MedicationDose.user_id == current_user.id)
        .order_by(models.MedicationDose.scheduled_time.desc())
        .all()
    )

    print(f"✅ تم جلب {len(doses)} جرعة")
    return [dose.to_dict() for dose in doses]


# POST /medications/doses/update-missed - تحديث الجرعات الفائتة
@router.post("/doses/update-missed")
def update_missed_doses(db: Session = Depends(get_db)):
    """تحديث الجرعات التي مضى على وقتها أكثر من ساعة"""
    now = datetime.now()
    one_hour_ago = now - timedelta(hours=1)

    print(f"🔍 البحث عن جرعات pending قبل {one_hour_ago}")

    missed_doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.status == "pending",
            models.MedicationDose.scheduled_time <= one_hour_ago,
        )
        .all()
    )

    print(f"📊 تم العثور على {len(missed_doses)} جرعة فائتة")

    for dose in missed_doses:
        dose.status = "missed"
        print(f"   ✅ تحديث جرعة {dose.id} من pending إلى missed")

    db.commit()

    return {
        "success": True,
        "message": f"تم تحديث {len(missed_doses)} جرعة إلى missed",
        "updated_count": len(missed_doses),
    }


# POST /medications/doses/check-all - فحص جميع الجرعات (للتشغيل الدوري)
@router.post("/doses/check-all")
def check_all_doses(db: Session = Depends(get_db)):
    """فحص جميع الجرعات وتحديث الحالات"""
    now = datetime.now()
    one_hour_ago = now - timedelta(hours=1)

    missed = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.status == "pending",
            models.MedicationDose.scheduled_time <= one_hour_ago,
        )
        .update({models.MedicationDose.status: "missed"})
    )

    upcoming = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.status == "pending",
            models.MedicationDose.scheduled_time > now,
        )
        .count()
    )

    db.commit()

    return {
        "success": True,
        "message": f"تم تحديث {missed} جرعة إلى missed",
        "upcoming_count": upcoming,
    }


# ============================================
# ============================================
# ✅ 4. APIs تسجيل تناول الجرعات
# ============================================
# ============================================


# POST /medications/{id}/take - تسجيل تناول جرعة
@router.post("/{id}/take")
def mark_dose_as_taken(
    id: int,
    dose_data: DoseTaken,
    current_user: models.User = Depends(get_current_user),  # ✅ من التوكن
    db: Session = Depends(get_db),
):
    """تسجيل تناول جرعة"""
    print(f"📝 تسجيل تناول جرعة للدواء {id} للمستخدم: {current_user.id}")

    medication = (
        db.query(models.Medication)
        .filter(
            models.Medication.id == id, models.Medication.user_id == current_user.id
        )
        .first()
    )
    if not medication:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")

    current_time = dose_data.taken_time.replace(second=0, microsecond=0)

    print(f"🔍 البحث عن جرعة للدواء {id} في وقت {current_time}")

    dose = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.medication_id == id,
            models.MedicationDose.user_id == current_user.id,
            extract("hour", models.MedicationDose.scheduled_time) == current_time.hour,
            models.MedicationDose.status == "pending",
        )
        .first()
    )

    if not dose:
        print(f"❌ لا توجد جرعة pending في هذا الوقت!")

        upcoming = (
            db.query(models.MedicationDose)
            .filter(
                models.MedicationDose.medication_id == id,
                models.MedicationDose.user_id == current_user.id,
                models.MedicationDose.status == "pending",
            )
            .order_by(models.MedicationDose.scheduled_time)
            .all()
        )

        if upcoming:
            times = [d.scheduled_time.strftime("%H:%M") for d in upcoming]
            return {
                "success": False,
                "message": f"مواعيد الجرعات القادمة: {', '.join(times)}",
                "medication": medication.to_dict(),
            }
        else:
            return {
                "success": False,
                "message": "لا توجد جرعات pending لهذا الدواء",
                "medication": medication.to_dict(),
            }

    scheduled = dose.scheduled_time
    time_diff = abs(current_time.hour - scheduled.hour)

    print(f"⏰ وقت الجرعة المجدول: {scheduled}")
    print(f"⏰ وقت الضغط: {current_time}")

    if current_time.hour != scheduled.hour:
        return {
            "success": False,
            "message": f"يمكن تسجيل الجرعة فقط في نفس ساعة موعدها ({scheduled.strftime('%H:%M')})",
            "medication": medication.to_dict(),
        }

    dose.taken_time = dose_data.taken_time
    dose.status = "taken"

    db.commit()
    db.refresh(dose)

    print(f"✅ تم تحديث الجرعة بنجاح")

    db.refresh(medication)

    return {
        "success": True,
        "message": "✅ تم تسجيل الجرعة بنجاح",
        "medication": medication.to_dict(),
    }


# ============================================
# ============================================
# ✅ 5. دالة مساعدة لإنشاء الجرعات
# ============================================
# ============================================


def _create_doses_for_medication(
    db: Session, medication: models.Medication, user_id: int  # ✅ إضافة user_id
):
    """إنشاء الجرعات للدواء"""
    times = json.loads(medication.times)

    start = max(medication.start_date, date.today())
    end = medication.end_date or date.today().replace(year=date.today().year + 1)

    current = start
    while current <= end:
        for time_str in times:
            hour, minute = map(int, time_str.split(":"))
            scheduled = datetime.combine(current, datetime.min.time()).replace(
                hour=hour, minute=minute
            )

            existing = (
                db.query(models.MedicationDose)
                .filter(
                    models.MedicationDose.medication_id == medication.id,
                    models.MedicationDose.scheduled_time == scheduled,
                )
                .first()
            )

            if not existing:
                dose = models.MedicationDose(
                    user_id=user_id,  # ✅ استخدام user_id من التوكن
                    medication_id=medication.id,
                    scheduled_time=scheduled,
                    status="pending",
                )
                db.add(dose)

        current = current + timedelta(days=1)

    db.commit()
