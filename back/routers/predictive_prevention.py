# backend/routers/predictive_prevention.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field
import json

from database import get_db
import models

router = APIRouter(prefix="/api/predictive-prevention", tags=["predictive-prevention"])


# ============================================
# نماذج Pydantic للتنبؤ الوقائي
# ============================================


class HealthRiskPrediction(BaseModel):
    risk_type: str
    risk_level: str  # "low", "medium", "high", "critical"
    probability: float  # 0.0 - 1.0
    confidence: float  # 0.0 - 1.0
    factors: List[str]
    timeframe: str  # "immediate", "short_term", "medium_term", "long_term"
    description: str
    recommendations: List[str]
    metadata: Optional[Dict[str, Any]] = None


class HealthRiskCreate(BaseModel):
    user_id: int
    risk_type: str
    risk_level: str
    probability: float = Field(ge=0.0, le=1.0)
    confidence: float = Field(ge=0.0, le=1.0)
    factors: List[str]
    timeframe: str
    description: str
    recommendations: List[str]
    metadata: Optional[Dict[str, Any]] = None


class HealthRiskResponse(HealthRiskCreate):
    id: int
    created_at: datetime
    updated_at: datetime


class PreventionPlanCreate(BaseModel):
    user_id: int
    risk_id: int
    plan_name: str
    description: str
    actions: List[Dict[str, Any]]
    timeline_days: int
    priority: str = "medium"
    metadata: Optional[Dict[str, Any]] = None


class PreventionPlanResponse(PreventionPlanCreate):
    id: int
    status: str
    progress_percentage: float
    created_at: datetime
    updated_at: datetime


class PlanProgressUpdate(BaseModel):
    progress_percentage: float = Field(ge=0.0, le=100.0)
    status: Optional[str] = None


# ============================================
# نقاط النهاية للتنبؤ الوقائي
# ============================================


@router.post("/analyze", response_model=List[HealthRiskPrediction])
def analyze_health_risks(user_id: int, db: Session = Depends(get_db)):
    """
    تحليل المخاطر الصحية للمستخدم بناءً على بياناته
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

        predictions = []

        # 1. تحليل الأمراض المزمنة
        diseases = user_nutrition.diseases or []

        if "diabetes" in diseases:
            diabetes_risk = _analyze_diabetes_risk(user_id, db, user_nutrition)
            if diabetes_risk:
                predictions.append(diabetes_risk)

        if "hypertension" in diseases:
            hypertension_risk = _analyze_hypertension_risk(user_id, db, user_nutrition)
            if hypertension_risk:
                predictions.append(hypertension_risk)

        # 2. تحليل مخاطر السمنة
        obesity_risk = _analyze_obesity_risk(user_id, db, user_nutrition)
        if obesity_risk:
            predictions.append(obesity_risk)

        # 3. تحليل مخاطر القلب
        heart_risk = _analyze_heart_disease_risk(user_id, db, user_nutrition)
        if heart_risk:
            predictions.append(heart_risk)

        # 4. تحليل مخاطر نقص النشاط
        inactivity_risk = _analyze_inactivity_risk(user_id, db)
        if inactivity_risk:
            predictions.append(inactivity_risk)

        # 5. تحليل مخاطر سوء التغذية
        malnutrition_risk = _analyze_malnutrition_risk(user_id, db, user_nutrition)
        if malnutrition_risk:
            predictions.append(malnutrition_risk)

        # 6. تحليل مخاطر الإجهاد
        stress_risk = _analyze_stress_risk(user_id, db)
        if stress_risk:
            predictions.append(stress_risk)

        return predictions

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في تحليل المخاطر: {str(e)}")


@router.post("/risks", response_model=HealthRiskResponse)
def create_health_risk(risk_data: HealthRiskCreate, db: Session = Depends(get_db)):
    """
    حفظ تحليل المخاطر في قاعدة البيانات
    """
    try:
        risk = models.HealthRisk(
            user_id=risk_data.user_id,
            risk_type=risk_data.risk_type,
            risk_level=risk_data.risk_level,
            probability=risk_data.probability,
            confidence=risk_data.confidence,
            factors=json.dumps(risk_data.factors),
            timeframe=risk_data.timeframe,
            description=risk_data.description,
            recommendations=json.dumps(risk_data.recommendations),
            risk_metadata=(
                json.dumps(risk_data.metadata) if risk_data.metadata else None
            ),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        db.add(risk)
        db.commit()
        db.refresh(risk)

        return {
            "id": risk.id,
            "user_id": risk.user_id,
            "risk_type": risk.risk_type,
            "risk_level": risk.risk_level,
            "probability": risk.probability,
            "confidence": risk.confidence,
            "factors": json.loads(risk.factors) if risk.factors else [],
            "timeframe": risk.timeframe,
            "description": risk.description,
            "recommendations": (
                json.loads(risk.recommendations) if risk.recommendations else []
            ),
            "metadata": json.loads(risk.risk_metadata) if risk.risk_metadata else {},
            "created_at": risk.created_at,
            "updated_at": risk.updated_at,
        }

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في حفظ المخاطر: {str(e)}")


@router.get("/risks", response_model=List[HealthRiskResponse])
def get_health_risks(
    user_id: int,
    risk_type: Optional[str] = None,
    risk_level: Optional[str] = None,
    limit: Optional[int] = 10,
    db: Session = Depends(get_db),
):
    """
    جلب تحليلات المخاطر الصحية للمستخدم
    """
    try:
        query = db.query(models.HealthRisk).filter(models.HealthRisk.user_id == user_id)

        if risk_type:
            query = query.filter(models.HealthRisk.risk_type == risk_type)

        if risk_level:
            query = query.filter(models.HealthRisk.risk_level == risk_level)

        query = query.order_by(models.HealthRisk.created_at.desc())

        if limit:
            query = query.limit(limit)

        risks = query.all()

        result = []
        for risk in risks:
            result.append(
                {
                    "id": risk.id,
                    "user_id": risk.user_id,
                    "risk_type": risk.risk_type,
                    "risk_level": risk.risk_level,
                    "probability": risk.probability,
                    "confidence": risk.confidence,
                    "factors": json.loads(risk.factors) if risk.factors else [],
                    "timeframe": risk.timeframe,
                    "description": risk.description,
                    "recommendations": (
                        json.loads(risk.recommendations) if risk.recommendations else []
                    ),
                    "metadata": (
                        json.loads(risk.risk_metadata) if risk.risk_metadata else {}
                    ),
                    "created_at": risk.created_at,
                    "updated_at": risk.updated_at,
                }
            )

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب المخاطر: {str(e)}")


@router.post("/plans", response_model=PreventionPlanResponse)
def create_prevention_plan(
    plan_data: PreventionPlanCreate, db: Session = Depends(get_db)
):
    """
    إنشاء خطة وقائية بناءً على تحليل المخاطر
    """
    try:
        # التحقق من وجود المخاطر
        risk = (
            db.query(models.HealthRisk)
            .filter(
                models.HealthRisk.id == plan_data.risk_id,
                models.HealthRisk.user_id == plan_data.user_id,
            )
            .first()
        )

        if not risk:
            raise HTTPException(status_code=404, detail="المخاطر غير موجودة")

        plan = models.PreventionPlan(
            user_id=plan_data.user_id,
            risk_id=plan_data.risk_id,
            plan_name=plan_data.plan_name,
            description=plan_data.description,
            actions=json.dumps(plan_data.actions),
            timeline_days=plan_data.timeline_days,
            priority=plan_data.priority,
            status="pending",
            progress_percentage=0.0,
            plan_metadata=(
                json.dumps(plan_data.metadata) if plan_data.metadata else None
            ),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        db.add(plan)
        db.commit()
        db.refresh(plan)

        return {
            "id": plan.id,
            "user_id": plan.user_id,
            "risk_id": plan.risk_id,
            "plan_name": plan.plan_name,
            "description": plan.description,
            "actions": json.loads(plan.actions) if plan.actions else [],
            "timeline_days": plan.timeline_days,
            "priority": plan.priority,
            "status": plan.status,
            "progress_percentage": plan.progress_percentage,
            "metadata": json.loads(plan.plan_metadata) if plan.plan_metadata else {},
            "created_at": plan.created_at,
            "updated_at": plan.updated_at,
        }

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في إنشاء الخطة: {str(e)}")


@router.get("/plans", response_model=List[PreventionPlanResponse])
def get_prevention_plans(
    user_id: int,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    جلب الخطط الوقائية للمستخدم
    """
    try:
        query = db.query(models.PreventionPlan).filter(
            models.PreventionPlan.user_id == user_id
        )

        if status:
            query = query.filter(models.PreventionPlan.status == status)

        if priority:
            query = query.filter(models.PreventionPlan.priority == priority)

        query = query.order_by(models.PreventionPlan.created_at.desc())

        plans = query.all()

        result = []
        for plan in plans:
            result.append(
                {
                    "id": plan.id,
                    "user_id": plan.user_id,
                    "risk_id": plan.risk_id,
                    "plan_name": plan.plan_name,
                    "description": plan.description,
                    "actions": json.loads(plan.actions) if plan.actions else [],
                    "timeline_days": plan.timeline_days,
                    "priority": plan.priority,
                    "status": plan.status,
                    "progress_percentage": plan.progress_percentage,
                    "metadata": (
                        json.loads(plan.plan_metadata) if plan.plan_metadata else {}
                    ),
                    "created_at": plan.created_at,
                    "updated_at": plan.updated_at,
                }
            )

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب الخطط: {str(e)}")


@router.put("/plans/{plan_id}/progress")
def update_plan_progress(
    plan_id: int,
    update_data: PlanProgressUpdate,
    db: Session = Depends(get_db),
):
    """
    تحديث تقدم الخطة الوقائية
    """
    try:
        plan = (
            db.query(models.PreventionPlan)
            .filter(models.PreventionPlan.id == plan_id)
            .first()
        )

        if not plan:
            raise HTTPException(status_code=404, detail="الخطة غير موجودة")

        plan.progress_percentage = update_data.progress_percentage

        if update_data.status:
            plan.status = update_data.status

        plan.updated_at = datetime.utcnow()

        db.commit()

        return {"success": True, "message": "تم تحديث تقدم الخطة"}

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"خطأ في تحديث الخطة: {str(e)}")


@router.get("/dashboard")
def get_prevention_dashboard(
    user_id: int,
    db: Session = Depends(get_db),
):
    """
    الحصول على لوحة تحكم الوقاية
    """
    try:
        # التحقق من وجود المستخدم
        user = db.query(models.User).filter(models.User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="المستخدم غير موجود")

        # جلب أحدث المخاطر
        recent_risks = (
            db.query(models.HealthRisk)
            .filter(models.HealthRisk.user_id == user_id)
            .order_by(models.HealthRisk.created_at.desc())
            .limit(5)
            .all()
        )

        # جلب الخطط النشطة
        active_plans = (
            db.query(models.PreventionPlan)
            .filter(
                models.PreventionPlan.user_id == user_id,
                models.PreventionPlan.status.in_(["pending", "in_progress"]),
            )
            .all()
        )

        # حساب الإحصائيات
        total_risks = (
            db.query(models.HealthRisk)
            .filter(models.HealthRisk.user_id == user_id)
            .count()
        )

        high_risk_count = (
            db.query(models.HealthRisk)
            .filter(
                models.HealthRisk.user_id == user_id,
                models.HealthRisk.risk_level == "high",
            )
            .count()
        )

        completed_plans = (
            db.query(models.PreventionPlan)
            .filter(
                models.PreventionPlan.user_id == user_id,
                models.PreventionPlan.status == "completed",
            )
            .count()
        )

        # تحليل المخاطر حسب النوع (عد يدوي لتجنب مشاكل SQLAlchemy)
        risks_by_type_raw = (
            db.query(models.HealthRisk.risk_type)
            .filter(models.HealthRisk.user_id == user_id)
            .all()
        )

        risk_by_type = {}
        for risk in risks_by_type_raw:
            risk_type = risk[0]
            risk_by_type[risk_type] = risk_by_type.get(risk_type, 0) + 1

        # تحليل المخاطر حسب المستوى (عد يدوي)
        risks_by_level_raw = (
            db.query(models.HealthRisk.risk_level)
            .filter(models.HealthRisk.user_id == user_id)
            .all()
        )

        risk_by_level = {}
        for risk in risks_by_level_raw:
            risk_level = risk[0]
            risk_by_level[risk_level] = risk_by_level.get(risk_level, 0) + 1

        return {
            "total_risks": total_risks,
            "high_risk_count": high_risk_count,
            "active_plans": len(active_plans),
            "completed_plans": completed_plans,
            "risk_by_type": risk_by_type,
            "risk_by_level": risk_by_level,
            "recent_risks": [
                {
                    "id": risk.id,
                    "risk_type": risk.risk_type,
                    "risk_level": risk.risk_level,
                    "probability": risk.probability,
                    "description": risk.description,
                    "created_at": risk.created_at,
                }
                for risk in recent_risks
            ],
            "active_plans_details": [
                {
                    "id": plan.id,
                    "plan_name": plan.plan_name,
                    "progress_percentage": plan.progress_percentage,
                    "status": plan.status,
                    "priority": plan.priority,
                }
                for plan in active_plans
            ],
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب لوحة التحكم: {str(e)}")


# ============================================
# دوال المساعدة للتحليل
# ============================================


def _analyze_diabetes_risk(
    user_id: int, db: Session, user_nutrition: models.UserNutrition
) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر السكري"""
    try:
        # جلب بيانات السكر
        blood_sugar_measurements = (
            db.query(models.BloodSugarMeasurement)
            .filter(models.BloodSugarMeasurement.user_id == user_id)
            .order_by(models.BloodSugarMeasurement.measurement_time.desc())
            .limit(10)
            .all()
        )

        if not blood_sugar_measurements:
            return None

        # حساب المتوسطات
        fasting_values = []
        post_meal_values = []

        for measurement in blood_sugar_measurements:
            if measurement.measurement_type == "fasting":
                fasting_values.append(measurement.value)
            elif measurement.measurement_type == "post_meal":
                post_meal_values.append(measurement.value)

        avg_fasting = sum(fasting_values) / len(fasting_values) if fasting_values else 0
        avg_post_meal = (
            sum(post_meal_values) / len(post_meal_values) if post_meal_values else 0
        )

        # تحديد مستوى الخطر
        risk_level = "low"
        probability = 0.3
        factors = []

        if avg_fasting > 126 or avg_post_meal > 200:
            risk_level = "high"
            probability = 0.8
            factors.append("مستويات سكر مرتفعة باستمرار")
        elif avg_fasting > 110 or avg_post_meal > 140:
            risk_level = "medium"
            probability = 0.6
            factors.append("مستويات سكر مرتفعة")
        else:
            risk_level = "low"
            probability = 0.3
            factors.append("مستويات سكر طبيعية")

        # إضافة عوامل إضافية
        if user_nutrition.bmi and user_nutrition.bmi > 30:
            factors.append("سمنة")
            probability += 0.1

        if user_nutrition.age and user_nutrition.age > 45:
            factors.append("عمر فوق 45 سنة")
            probability += 0.1

        # تحديد التوصيات
        recommendations = [
            "مراقبة مستوى السكر بانتظام",
            "اتباع نظام غذائي صحي",
            "ممارسة الرياضة بانتظام",
            "التحكم في الوزن",
        ]

        if risk_level == "high":
            recommendations.append("استشارة طبيب متخصص")

        return HealthRiskPrediction(
            risk_type="diabetes",
            risk_level=risk_level,
            probability=min(probability, 0.95),
            confidence=0.7,
            factors=factors,
            timeframe="medium_term",
            description="خطر الإصابة بمضاعفات السكري أو تفاقم الحالة",
            recommendations=recommendations,
        )

    except Exception:
        return None


def _analyze_hypertension_risk(
    user_id: int, db: Session, user_nutrition: models.UserNutrition
) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر ضغط الدم"""
    try:
        # في تطبيق حقيقي، نستخدم بيانات ضغط الدم
        # هنا نستخدم بيانات افتراضية

        risk_level = "low"
        probability = 0.3
        factors = []

        # تحليل عوامل الخطر
        if user_nutrition.bmi and user_nutrition.bmi > 25:
            factors.append("زيادة الوزن")
            probability += 0.2

        if user_nutrition.age and user_nutrition.age > 50:
            factors.append("عمر فوق 50 سنة")
            probability += 0.15

        # تحديد مستوى الخطر
        if probability > 0.6:
            risk_level = "high"
        elif probability > 0.4:
            risk_level = "medium"
        else:
            risk_level = "low"

        recommendations = [
            "مراقبة ضغط الدم بانتظام",
            "تقليل تناول الملح",
            "ممارسة الرياضة بانتظام",
            "الحفاظ على وزن صحي",
        ]

        if risk_level == "high":
            recommendations.append("استشارة طبيب متخصص")

        return HealthRiskPrediction(
            risk_type="hypertension",
            risk_level=risk_level,
            probability=probability,
            confidence=0.6,
            factors=factors,
            timeframe="long_term",
            description="خطر الإصابة بارتفاع ضغط الدم أو مضاعفاته",
            recommendations=recommendations,
        )

    except Exception:
        return None


def _analyze_obesity_risk(
    user_id: int, db: Session, user_nutrition: models.UserNutrition
) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر السمنة"""
    try:
        bmi = user_nutrition.bmi

        if not bmi:
            return None

        risk_level = "low"
        probability = 0.3
        factors = []

        if bmi >= 30:
            risk_level = "high"
            probability = 0.8
            factors.append("سمنة درجة أولى")
        elif bmi >= 25:
            risk_level = "medium"
            probability = 0.6
            factors.append("زيادة وزن")
        else:
            risk_level = "low"
            probability = 0.2
            factors.append("وزن طبيعي")

        # تحليل النشاط البدني
        today = datetime.utcnow().date()
        walking_activities = (
            db.query(models.WalkingActivity)
            .filter(
                models.WalkingActivity.user_id == user_id,
                models.WalkingActivity.activity_date == today,
            )
            .all()
        )

        if not walking_activities:
            factors.append("قلة النشاط البدني")
            probability += 0.1

        recommendations = [
            "ممارسة الرياضة بانتظام",
            "اتباع نظام غذائي متوازن",
            "مراقبة الوزن أسبوعياً",
            "تقليل السكريات والدهون",
        ]

        if risk_level == "high":
            recommendations.append("استشارة أخصائي تغذية")

        return HealthRiskPrediction(
            risk_type="obesity",
            risk_level=risk_level,
            probability=probability,
            confidence=0.8,
            factors=factors,
            timeframe="short_term",
            description="خطر الإصابة بالسمنة أو مضاعفاتها الصحية",
            recommendations=recommendations,
        )

    except Exception:
        return None


def _analyze_heart_disease_risk(
    user_id: int, db: Session, user_nutrition: models.UserNutrition
) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر أمراض القلب"""
    try:
        probability = 0.3
        factors = []

        # عوامل الخطر
        if user_nutrition.bmi and user_nutrition.bmi > 25:
            factors.append("زيادة الوزن")
            probability += 0.15

        if user_nutrition.age and user_nutrition.age > 50:
            factors.append("عمر فوق 50 سنة")
            probability += 0.15

        # تحليل الأمراض المزمنة
        diseases = user_nutrition.diseases or []
        if "diabetes" in diseases:
            factors.append("مرض السكري")
            probability += 0.2

        if "hypertension" in diseases:
            factors.append("ارتفاع ضغط الدم")
            probability += 0.2

        # تحديد مستوى الخطر
        if probability > 0.7:
            risk_level = "high"
        elif probability > 0.5:
            risk_level = "medium"
        else:
            risk_level = "low"

        recommendations = [
            "ممارسة الرياضة بانتظام",
            "اتباع نظام غذائي صحي للقلب",
            "مراقبة ضغط الدم والسكر",
            "الإقلاع عن التدخين إذا كنت مدخناً",
        ]

        if risk_level == "high":
            recommendations.append("فحص دوري للقلب")

        return HealthRiskPrediction(
            risk_type="heart_disease",
            risk_level=risk_level,
            probability=probability,
            confidence=0.6,
            factors=factors,
            timeframe="long_term",
            description="خطر الإصابة بأمراض القلب أو الجلطات",
            recommendations=recommendations,
        )

    except Exception:
        return None


def _analyze_inactivity_risk(
    user_id: int, db: Session
) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر قلة النشاط البدني"""
    try:
        today = datetime.utcnow().date()
        week_ago = today - timedelta(days=7)

        # جلب نشاط المشي للأسبوع الماضي
        walking_activities = (
            db.query(models.WalkingActivity)
            .filter(
                models.WalkingActivity.user_id == user_id,
                models.WalkingActivity.activity_date >= week_ago,
            )
            .all()
        )

        total_steps = sum(activity.steps for activity in walking_activities)
        avg_daily_steps = total_steps / 7 if walking_activities else 0

        risk_level = "low"
        probability = 0.3
        factors = []

        if avg_daily_steps < 3000:
            risk_level = "high"
            probability = 0.8
            factors.append("نشاط بدني منخفض جداً")
        elif avg_daily_steps < 5000:
            risk_level = "medium"
            probability = 0.6
            factors.append("نشاط بدني غير كاف")
        else:
            risk_level = "low"
            probability = 0.2
            factors.append("نشاط بدني مقبول")

        recommendations = [
            "زيادة النشاط البدني اليومي",
            "المشي لمدة 30 دقيقة يومياً",
            "استخدام السلالم بدلاً من المصعد",
            "ممارسة تمارين بسيطة في المنزل",
        ]

        return HealthRiskPrediction(
            risk_type="inactivity",
            risk_level=risk_level,
            probability=probability,
            confidence=0.7,
            factors=factors,
            timeframe="short_term",
            description="خطر الإصابة بمشاكل صحية بسبب قلة النشاط البدني",
            recommendations=recommendations,
        )

    except Exception:
        return None


def _analyze_malnutrition_risk(
    user_id: int, db: Session, user_nutrition: models.UserNutrition
) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر سوء التغذية"""
    try:
        # جلب الوجبات اليومية
        today = datetime.utcnow().date()
        meals_today = (
            db.query(models.Meal)
            .filter(
                models.Meal.user_id == user_id,
                models.Meal.created_at >= datetime.combine(today, datetime.min.time()),
            )
            .count()
        )

        risk_level = "low"
        probability = 0.3
        factors = []

        if meals_today < 2:
            risk_level = "high"
            probability = 0.7
            factors.append("قلة عدد الوجبات")
        elif meals_today < 3:
            risk_level = "medium"
            probability = 0.5
            factors.append("عدد وجبات غير كاف")
        else:
            risk_level = "low"
            probability = 0.2
            factors.append("عدد وجبات مقبول")

        # تحليل مؤشر كتلة الجسم
        if user_nutrition.bmi and user_nutrition.bmi < 18.5:
            factors.append("نقص الوزن")
            probability += 0.2
            risk_level = "high"

        recommendations = [
            "تناول 3 وجبات رئيسية يومياً",
            "إضافة وجبات خفيفة صحية",
            "تنوع مصادر الغذاء",
            "مراقبة الوزن بانتظام",
        ]

        if risk_level == "high":
            recommendations.append("استشارة أخصائي تغذية")

        return HealthRiskPrediction(
            risk_type="malnutrition",
            risk_level=risk_level,
            probability=probability,
            confidence=0.6,
            factors=factors,
            timeframe="short_term",
            description="خطر الإصابة بسوء التغذية أو نقص العناصر الغذائية",
            recommendations=recommendations,
        )

    except Exception:
        return None


def _analyze_stress_risk(user_id: int, db: Session) -> Optional[HealthRiskPrediction]:
    """تحليل مخاطر الإجهاد والتوتر"""
    try:
        # في تطبيق حقيقي، نستخدم بيانات الكويز اليومي
        # هنا نستخدم تحليل افتراضي

        risk_level = "medium"
        probability = 0.5
        factors = ["نمط الحياة السريع", "ضغوط العمل"]

        recommendations = [
            "ممارسة تمارين الاسترخاء",
            "تنظيم وقت العمل والراحة",
            "ممارسة الهوايات المفضلة",
            "النوم الكافي (7-8 ساعات)",
        ]

        return HealthRiskPrediction(
            risk_type="stress",
            risk_level=risk_level,
            probability=probability,
            confidence=0.5,
            factors=factors,
            timeframe="immediate",
            description="خطر الإصابة بالإجهاد المزمن أو القلق",
            recommendations=recommendations,
        )

    except Exception:
        return None
