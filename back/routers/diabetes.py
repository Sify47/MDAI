# backend/routers/diabetes.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date, timedelta
from pydantic import BaseModel

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/diabetes", tags=["diabetes"])


# ============================================
# نماذج Pydantic لبيانات السكر
# ============================================


class BloodSugarMeasurementCreate(BaseModel):
    measurement_type: str  # "fasting", "before_meal", "after_meal", "random", "bedtime"
    value: float
    unit: str = "mg/dL"
    notes: Optional[str] = None
    measured_at: Optional[datetime] = None


class BloodSugarMeasurementResponse(BaseModel):
    id: int
    user_id: int
    measurement_type: str
    value: float
    unit: str
    notes: Optional[str]
    measured_at: Optional[str]
    created_at: str


class DiabetesMedicationCreate(BaseModel):
    medication_name: str
    dosage: str
    frequency: str
    time_of_day: Optional[str] = None
    notes: Optional[str] = None
    is_active: bool = True


class DiabetesMedicationResponse(BaseModel):
    id: int
    user_id: int
    medication_name: str
    dosage: str
    frequency: str
    time_of_day: Optional[str]
    notes: Optional[str]
    is_active: bool
    created_at: str
    updated_at: Optional[str]


class DiabetesSymptomCreate(BaseModel):
    symptom_type: str  # "hypoglycemia", "hyperglycemia", "other"
    symptom_name: str
    severity: str  # "mild", "moderate", "severe"
    notes: Optional[str] = None
    occurred_at: Optional[datetime] = None


class DiabetesSymptomResponse(BaseModel):
    id: int
    user_id: int
    symptom_type: str
    symptom_name: str
    severity: str
    notes: Optional[str]
    occurred_at: Optional[str]
    created_at: str


# ============================================
# نقاط النهاية لقياسات السكر
# ============================================


@router.post("/measurements", response_model=BloodSugarMeasurementResponse)
def create_blood_sugar_measurement(
    measurement: BloodSugarMeasurementCreate,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """إنشاء قياس جديد للسكر"""
    db_measurement = models.BloodSugarMeasurement(
        user_id=user_id,
        measurement_type=measurement.measurement_type,
        value=measurement.value,
        unit=measurement.unit,
        notes=measurement.notes,
        measured_at=measurement.measured_at or datetime.utcnow(),
    )

    db.add(db_measurement)
    db.commit()
    db.refresh(db_measurement)

    return db_measurement.to_dict()


@router.get("/measurements", response_model=List[BloodSugarMeasurementResponse])
def get_blood_sugar_measurements(
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    measurement_type: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """الحصول على جميع قياسات السكر للمستخدم"""
    query = db.query(models.BloodSugarMeasurement).filter(
        models.BloodSugarMeasurement.user_id == user_id
    )

    if start_date:
        query = query.filter(models.BloodSugarMeasurement.measured_at >= start_date)
    if end_date:
        query = query.filter(models.BloodSugarMeasurement.measured_at <= end_date)
    if measurement_type:
        query = query.filter(
            models.BloodSugarMeasurement.measurement_type == measurement_type
        )

    measurements = query.order_by(models.BloodSugarMeasurement.measured_at.desc()).all()
    return [m.to_dict() for m in measurements]


@router.get(
    "/measurements/{measurement_id}", response_model=BloodSugarMeasurementResponse
)
def get_blood_sugar_measurement(
    measurement_id: int,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """الحصول على قياس سكر محدد"""
    measurement = (
        db.query(models.BloodSugarMeasurement)
        .filter(
            models.BloodSugarMeasurement.id == measurement_id,
            models.BloodSugarMeasurement.user_id == user_id,
        )
        .first()
    )

    if not measurement:
        raise HTTPException(status_code=404, detail="القياس غير موجود")

    return measurement.to_dict()


@router.delete("/measurements/{measurement_id}")
def delete_blood_sugar_measurement(
    measurement_id: int,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """حذف قياس سكر"""
    measurement = (
        db.query(models.BloodSugarMeasurement)
        .filter(
            models.BloodSugarMeasurement.id == measurement_id,
            models.BloodSugarMeasurement.user_id == user_id,
        )
        .first()
    )

    if not measurement:
        raise HTTPException(status_code=404, detail="القياس غير موجود")

    db.delete(measurement)
    db.commit()

    return {"message": "تم حذف القياس بنجاح"}


# ============================================
# نقاط النهاية للأدوية
# ============================================


@router.post("/medications", response_model=DiabetesMedicationResponse)
def create_diabetes_medication(
    medication: DiabetesMedicationCreate,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """إنشاء دواء جديد للسكري"""
    db_medication = models.DiabetesMedication(
        user_id=user_id,
        medication_name=medication.medication_name,
        dosage=medication.dosage,
        frequency=medication.frequency,
        time_of_day=medication.time_of_day,
        notes=medication.notes,
        is_active=medication.is_active,
    )

    db.add(db_medication)
    db.commit()
    db.refresh(db_medication)

    return db_medication.to_dict()


@router.get("/medications", response_model=List[DiabetesMedicationResponse])
def get_diabetes_medications(
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    """الحصول على جميع أدوية السكري للمستخدم"""
    query = db.query(models.DiabetesMedication).filter(
        models.DiabetesMedication.user_id == user_id
    )

    if active_only:
        query = query.filter(models.DiabetesMedication.is_active == True)

    medications = query.order_by(models.DiabetesMedication.created_at.desc()).all()
    return [m.to_dict() for m in medications]


@router.put("/medications/{medication_id}", response_model=DiabetesMedicationResponse)
def update_diabetes_medication(
    medication_id: int,
    medication_update: DiabetesMedicationCreate,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """تحديث دواء السكري"""
    medication = (
        db.query(models.DiabetesMedication)
        .filter(
            models.DiabetesMedication.id == medication_id,
            models.DiabetesMedication.user_id == user_id,
        )
        .first()
    )

    if not medication:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")

    # تحديث الحقول
    medication.medication_name = medication_update.medication_name
    medication.dosage = medication_update.dosage
    medication.frequency = medication_update.frequency
    medication.time_of_day = medication_update.time_of_day
    medication.notes = medication_update.notes
    medication.is_active = medication_update.is_active
    medication.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(medication)

    return medication.to_dict()


@router.delete("/medications/{medication_id}")
def delete_diabetes_medication(
    medication_id: int,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """حذف دواء السكري"""
    medication = (
        db.query(models.DiabetesMedication)
        .filter(
            models.DiabetesMedication.id == medication_id,
            models.DiabetesMedication.user_id == user_id,
        )
        .first()
    )

    if not medication:
        raise HTTPException(status_code=404, detail="الدواء غير موجود")

    db.delete(medication)
    db.commit()

    return {"message": "تم حذف الدواء بنجاح"}


# ============================================
# نقاط النهاية للأعراض
# ============================================


@router.post("/symptoms", response_model=DiabetesSymptomResponse)
def create_diabetes_symptom(
    symptom: DiabetesSymptomCreate,
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    db: Session = Depends(get_db),
):
    """إنشاء عرض جديد للسكري"""
    db_symptom = models.DiabetesSymptom(
        user_id=user_id,
        symptom_type=symptom.symptom_type,
        symptom_name=symptom.symptom_name,
        severity=symptom.severity,
        notes=symptom.notes,
        occurred_at=symptom.occurred_at or datetime.utcnow(),
    )

    db.add(db_symptom)
    db.commit()
    db.refresh(db_symptom)

    return db_symptom.to_dict()


@router.get("/symptoms", response_model=List[DiabetesSymptomResponse])
def get_diabetes_symptoms(
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    symptom_type: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """الحصول على جميع أعراض السكري للمستخدم"""
    query = db.query(models.DiabetesSymptom).filter(
        models.DiabetesSymptom.user_id == user_id
    )

    if start_date:
        query = query.filter(models.DiabetesSymptom.occurred_at >= start_date)
    if end_date:
        query = query.filter(models.DiabetesSymptom.occurred_at <= end_date)
    if symptom_type:
        query = query.filter(models.DiabetesSymptom.symptom_type == symptom_type)

    symptoms = query.order_by(models.DiabetesSymptom.occurred_at.desc()).all()
    return [s.to_dict() for s in symptoms]


# ============================================
# نقاط النهاية للتحليل
# ============================================


@router.get("/analysis")
def get_diabetes_analysis(
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    days: int = 30,
    db: Session = Depends(get_db),
):
    """الحصول على تحليل شامل لبيانات السكري"""
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)

    # الحصول على القياسات
    measurements = (
        db.query(models.BloodSugarMeasurement)
        .filter(
            models.BloodSugarMeasurement.user_id == user_id,
            models.BloodSugarMeasurement.measured_at >= start_date,
            models.BloodSugarMeasurement.measured_at <= end_date,
        )
        .all()
    )

    # الحصول على الأدوية النشطة
    medications = (
        db.query(models.DiabetesMedication)
        .filter(
            models.DiabetesMedication.user_id == user_id,
            models.DiabetesMedication.is_active == True,
        )
        .all()
    )

    # الحصول على الأعراض
    symptoms = (
        db.query(models.DiabetesSymptom)
        .filter(
            models.DiabetesSymptom.user_id == user_id,
            models.DiabetesSymptom.occurred_at >= start_date,
            models.DiabetesSymptom.occurred_at <= end_date,
        )
        .all()
    )

    # تحليل القياسات
    measurement_analysis = {}
    if measurements:
        values = [m.value for m in measurements]
        measurement_analysis = {
            "total_measurements": len(measurements),
            "average_value": sum(values) / len(values),
            "min_value": min(values),
            "max_value": max(values),
            "measurements_by_type": {},
        }

        # تجميع حسب النوع
        for m in measurements:
            if m.measurement_type not in measurement_analysis["measurements_by_type"]:
                measurement_analysis["measurements_by_type"][m.measurement_type] = []
            measurement_analysis["measurements_by_type"][m.measurement_type].append(
                m.value
            )

    # تحليل الأعراض
    symptom_analysis = {}
    if symptoms:
        symptom_analysis = {
            "total_symptoms": len(symptoms),
            "symptoms_by_type": {},
            "symptoms_by_severity": {},
        }

        for s in symptoms:
            # تجميع حسب النوع
            if s.symptom_type not in symptom_analysis["symptoms_by_type"]:
                symptom_analysis["symptoms_by_type"][s.symptom_type] = 0
            symptom_analysis["symptoms_by_type"][s.symptom_type] += 1

            # تجميع حسب الشدة
            if s.severity not in symptom_analysis["symptoms_by_severity"]:
                symptom_analysis["symptoms_by_severity"][s.severity] = 0
            symptom_analysis["symptoms_by_severity"][s.severity] += 1

    return {
        "period": {
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "days": days,
        },
        "measurements": measurement_analysis,
        "medications": [m.to_dict() for m in medications],
        "symptoms": symptom_analysis,
        "summary": {
            "has_diabetes_data": len(measurements) > 0 or len(symptoms) > 0,
            "total_data_points": len(measurements) + len(symptoms),
            "active_medications": len(medications),
        },
    }


@router.get("/trends")
def get_blood_sugar_trends(
    user_id: int = 1,  # TODO: استبدل بمصادقة حقيقية
    days: int = 7,
    db: Session = Depends(get_db),
):
    """الحصول على اتجاهات السكر خلال فترة محددة"""
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)

    measurements = (
        db.query(models.BloodSugarMeasurement)
        .filter(
            models.BloodSugarMeasurement.user_id == user_id,
            models.BloodSugarMeasurement.measured_at >= start_date,
            models.BloodSugarMeasurement.measured_at <= end_date,
        )
        .order_by(models.BloodSugarMeasurement.measured_at)
        .all()
    )

    # تجميع البيانات حسب اليوم
    daily_data = {}
    for m in measurements:
        day = m.measured_at.date().isoformat()
        if day not in daily_data:
            daily_data[day] = {
                "date": day,
                "measurements": [],
                "average": 0,
                "count": 0,
            }

        daily_data[day]["measurements"].append(
            {
                "value": m.value,
                "type": m.measurement_type,
                "time": m.measured_at.time().isoformat() if m.measured_at else None,
            }
        )
        daily_data[day]["count"] += 1

    # حساب المتوسط لكل يوم
    for day in daily_data:
        values = [m["value"] for m in daily_data[day]["measurements"]]
        daily_data[day]["average"] = sum(values) / len(values) if values else 0

    return {
        "period": {
            "start_date": start_date.date().isoformat(),
            "end_date": end_date.date().isoformat(),
            "days": days,
        },
        "daily_trends": list(daily_data.values()),
        "total_measurements": len(measurements),
    }
