# backend/routers/symptoms.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from typing import List, Optional
from datetime import datetime, date, timedelta
import json

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/api/symptoms", tags=["symptoms"])

# ============================================
# ✅ 1. APIs خاصة (يجب أن تأتي قبل APIs العامة)
# ============================================


@router.get("/medicine-impact")
def get_medicine_impact(
    medicine_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب تأثير الدواء على المشي والسعرات مع التوصيات الغذائية"""
    print(f"💊 [Symptoms] جلب تأثير الدواء {medicine_id}")

    try:
        # 1. جلب الدواء
        medicine = (
            db.query(models.Medicine).filter(models.Medicine.id == medicine_id).first()
        )

        if not medicine:
            return {
                "success": False,
                "message": f"الدواء بالرقم {medicine_id} غير موجود",
                "impact_on_steps": 0,
                "calories_adjustment": 0,
                "foods_to_avoid": [],
                "foods_to_eat": [],
                "timing_instructions": "",
            }

        print(f"📦 [Symptoms] اسم الدواء: {medicine.name_ar}")

        # 2. جلب تأثير الدواء من health_impact_factors
        impact = (
            db.query(models.HealthImpactFactor)
            .filter(
                models.HealthImpactFactor.factor_type == "medicine",
                models.HealthImpactFactor.factor_name == medicine.name_ar,
            )
            .first()
        )

        # 3. جلب التوصيات الغذائية من medicine_food_recommendations
        food_rec = (
            db.query(models.MedicineFoodRecommendation)
            .filter(models.MedicineFoodRecommendation.medicine_id == medicine_id)
            .first()
        )

        # دالة مساعدة لتحويل JSON
        def parse_json_field(field):
            if field is None:
                return []
            if isinstance(field, list):
                return field
            if isinstance(field, str):
                try:
                    return json.loads(field)
                except:
                    # محاولة تنظيف النص إذا كان JSON غير صالح
                    cleaned = field.replace("'", '"')
                    try:
                        return json.loads(cleaned)
                    except:
                        return []
            return []

        result = {
            "success": True,
            "impact_on_steps": impact.impact_on_steps if impact else 0,
            "calories_adjustment": impact.calories_adjustment if impact else 0,
            "description": (
                impact.description
                if impact
                else f"لا توجد معلومات مؤثرة عن دواء {medicine.name_ar} على المشي"
            ),
            "foods_to_avoid": (
                parse_json_field(food_rec.foods_to_avoid) if food_rec else []
            ),
            "foods_to_eat": parse_json_field(food_rec.foods_to_eat) if food_rec else [],
            "drinks_to_avoid": (
                parse_json_field(food_rec.drinks_to_avoid) if food_rec else []
            ),
            "drinks_recommended": (
                parse_json_field(food_rec.drinks_recommended) if food_rec else []
            ),
            "timing_instructions": (
                food_rec.timing_instructions if food_rec else "اتبع تعليمات الطبيب"
            ),
            "general_tips": (
                food_rec.general_tips if food_rec else "تناول الدواء في مواعيده المحددة"
            ),
        }

        print(f"✅ [Symptoms] تم جلب تأثير الدواء {medicine.name_ar}")
        print(f"🍽️ [Symptoms] foods_to_avoid: {result['foods_to_avoid']}")
        print(f"🍽️ [Symptoms] foods_to_eat: {result['foods_to_eat']}")

        return result

    except Exception as e:
        print(f"🔥 [Symptoms] خطأ: {e}")
        return {
            "success": False,
            "message": str(e),
            "impact_on_steps": 0,
            "calories_adjustment": 0,
            "foods_to_avoid": [],
            "foods_to_eat": [],
            "drinks_to_avoid": [],
            "drinks_recommended": [],
            "timing_instructions": "",
            "general_tips": "",
        }


@router.get("/impact")
def get_symptom_impact(
    symptom: str,
    severity: str = "متوسط",
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب تأثير العرض على المشي والسعرات"""
    print(f"🩺 [Symptoms] جلب تأثير العرض {symptom} (شدة: {severity})")

    # تأثير افتراضي
    return {
        "success": True,
        "impact_on_steps": 0,
        "calories_adjustment": 0,
        "description": f"لا توجد معلومات مؤثرة عن العرض {symptom} على المشي",
    }


@router.get("/stats/summary")
def get_symptoms_summary(
    current_user: models.User = Depends(get_current_user),
    days: int = 30,
    db: Session = Depends(get_db),
):
    """الحصول على ملخص إحصائيات الأعراض لآخر فترة"""
    print(f"📊 [Symptoms] إحصائيات أعراض المستخدم {current_user.id} لآخر {days} يوم")

    since_date = datetime.now() - timedelta(days=days)

    total = (
        db.query(models.Symptom)
        .filter(
            models.Symptom.user_id == current_user.id,
            models.Symptom.date_time >= since_date,
        )
        .count()
    )

    severity_dist = (
        db.query(models.Symptom.severity, func.count(models.Symptom.id).label("count"))
        .filter(
            models.Symptom.user_id == current_user.id,
            models.Symptom.date_time >= since_date,
        )
        .group_by(models.Symptom.severity)
        .all()
    )

    frequent_symptoms = (
        db.query(models.Symptom.name, func.count(models.Symptom.id).label("count"))
        .filter(
            models.Symptom.user_id == current_user.id,
            models.Symptom.date_time >= since_date,
        )
        .group_by(models.Symptom.name)
        .order_by(desc("count"))
        .limit(5)
        .all()
    )

    return {
        "total_symptoms": total,
        "severity_distribution": {s[0]: s[1] for s in severity_dist},
        "most_frequent": [{"name": s[0], "count": s[1]} for s in frequent_symptoms],
        "period_days": days,
    }


@router.get("/stats/timeline")
def get_symptoms_timeline(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """توزيع الأعراض حسب الوقت من اليوم"""
    print(f"📊 [Symptoms] توزيع أعراض المستخدم {current_user.id} حسب الوقت")

    results = (
        db.query(
            func.extract("hour", models.Symptom.date_time).label("hour"),
            func.count(models.Symptom.id).label("count"),
        )
        .filter(models.Symptom.user_id == current_user.id)
        .group_by("hour")
        .order_by("hour")
        .all()
    )

    periods = {
        "الصباح (6-12)": 0,
        "الظهر (12-18)": 0,
        "المساء (18-24)": 0,
        "الليل (0-6)": 0,
    }

    for hour, count in results:
        h = int(hour)
        if 6 <= h < 12:
            periods["الصباح (6-12)"] += count
        elif 12 <= h < 18:
            periods["الظهر (12-18)"] += count
        elif 18 <= h < 24:
            periods["المساء (18-24)"] += count
        else:
            periods["الليل (0-6)"] += count

    return periods


@router.get("/{id}/food-recommendations")
def get_symptom_food_recommendations(
    id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب التوصيات الغذائية لعرض معين"""
    print(f"🍽️ [Symptoms] جلب توصيات غذائية لعرض ID: {id}")

    symptom = (
        db.query(models.Symptom)
        .filter(models.Symptom.id == id, models.Symptom.user_id == current_user.id)
        .first()
    )

    if not symptom:
        raise HTTPException(status_code=404, detail="العرض غير موجود")

    if symptom.food_recommendations:
        return {"success": True, "food_recommendations": symptom.food_recommendations}

    recommendations = get_food_recommendations(db, symptom.name, symptom.severity)
    return {"success": True, "food_recommendations": recommendations}


# ============================================
# ✅ 2. APIs العامة (تأتي بعد APIs الخاصة)
# ============================================


@router.get("/", response_model=List[schemas.SymptomResponse])
def get_symptoms(
    current_user: models.User = Depends(get_current_user),
    limit: int = 50,
    skip: int = 0,
    severity: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """جلب كل الأعراض للمستخدم الحالي"""
    print(f"🔍 [Symptoms] جلب أعراض المستخدم {current_user.id}")

    query = db.query(models.Symptom).filter(models.Symptom.user_id == current_user.id)

    if severity:
        query = query.filter(models.Symptom.severity == severity)

    if from_date:
        try:
            parsed_from = date.fromisoformat(from_date)
        except ValueError:
            # Try to parse flexible formats like 2026-5-16
            parts = from_date.split("-")
            if len(parts) == 3:
                parsed_from = date(int(parts[0]), int(parts[1]), int(parts[2]))
            else:
                parsed_from = None
        if parsed_from:
            from_datetime = datetime.combine(parsed_from, datetime.min.time())
            query = query.filter(models.Symptom.date_time >= from_datetime)

    if to_date:
        try:
            parsed_to = date.fromisoformat(to_date)
        except ValueError:
            # Try to parse flexible formats like 2026-5-16
            parts = to_date.split("-")
            if len(parts) == 3:
                parsed_to = date(int(parts[0]), int(parts[1]), int(parts[2]))
            else:
                parsed_to = None
        if parsed_to:
            to_datetime = datetime.combine(parsed_to, datetime.max.time())
            query = query.filter(models.Symptom.date_time <= to_datetime)

    symptoms = (
        query.order_by(desc(models.Symptom.date_time)).offset(skip).limit(limit).all()
    )

    print(f"✅ [Symptoms] تم جلب {len(symptoms)} عرض")
    return symptoms


@router.get("/{id}", response_model=schemas.SymptomResponse)
def get_symptom(
    id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب عرض محدد بالمعرف"""
    print(f"🔍 [Symptoms] جلب عرض ID: {id}")

    symptom = (
        db.query(models.Symptom)
        .filter(models.Symptom.id == id, models.Symptom.user_id == current_user.id)
        .first()
    )

    if not symptom:
        raise HTTPException(status_code=404, detail="العرض غير موجود")

    return symptom


@router.post("/", response_model=schemas.SymptomResponse, status_code=201)
def create_symptom(
    symptom: schemas.SymptomCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إضافة عرض جديد مع تحليل تلقائي وتوصيات غذائية"""
    print(f"📝 [Symptoms] إضافة عرض جديد للمستخدم {current_user.id}")

    # استخدام التحليل المحسن من قاعدة البيانات
    analysis_result = analyze_symptom_logic_v2(symptom.name, symptom.severity, db)
    food_recommendations = get_food_recommendations(db, symptom.name, symptom.severity)

    db_symptom = models.Symptom(
        user_id=current_user.id,
        name=symptom.name,
        icon=symptom.icon,
        severity=symptom.severity,
        date_time=symptom.date_time,
        notes=symptom.notes,
        analysis=analysis_result["analysis"],
        possible_causes=analysis_result["possible_causes"],
        suggested_actions=analysis_result["suggested_actions"],
        warning_signs=analysis_result["warning_signs"],
        food_recommendations=food_recommendations,
    )

    db.add(db_symptom)
    db.commit()
    db.refresh(db_symptom)

    print(f"✅ [Symptoms] تم إضافة عرض ID: {db_symptom.id}")
    return db_symptom


@router.put("/{id}", response_model=schemas.SymptomResponse)
def update_symptom(
    id: int,
    symptom_update: schemas.SymptomUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تحديث بيانات عرض محدد"""
    print(f"🔄 [Symptoms] تحديث عرض ID: {id}")

    db_symptom = (
        db.query(models.Symptom)
        .filter(models.Symptom.id == id, models.Symptom.user_id == current_user.id)
        .first()
    )

    if not db_symptom:
        raise HTTPException(status_code=404, detail="العرض غير موجود")

    update_data = symptom_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_symptom, field, value)

    db.commit()
    db.refresh(db_symptom)

    print(f"✅ [Symptoms] تم تحديث العرض ID: {id}")
    return db_symptom


@router.delete("/{id}")
def delete_symptom(
    id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حذف عرض محدد"""
    print(f"🗑️ [Symptoms] حذف عرض ID: {id}")

    db_symptom = (
        db.query(models.Symptom)
        .filter(models.Symptom.id == id, models.Symptom.user_id == current_user.id)
        .first()
    )

    if not db_symptom:
        raise HTTPException(status_code=404, detail="العرض غير موجود")

    db.delete(db_symptom)
    db.commit()

    return {"message": "تم حذف العرض بنجاح", "id": id}


@router.post("/analyze")
def analyze_symptom_endpoint(
    data: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تحليل عرض طبي وإرجاع النتائج مع توصيات غذائية"""
    symptom_name = data.get("name", "")
    severity = data.get("severity", "متوسط")

    print(f"🔍 [Symptoms] تحليل عرض: {symptom_name} (شدة: {severity})")

    result = analyze_symptom_logic_v2(symptom_name, severity, db)
    food_recommendations = get_food_recommendations(db, symptom_name, severity)

    return {"success": True, **result, "food_recommendations": food_recommendations}


# ============================================
# ✅ 3. دوال مساعدة
# ============================================


def get_food_recommendations(db: Session, symptom_name: str, severity: str):
    """جلب التوصيات الغذائية من قاعدة البيانات"""
    recommendation = (
        db.query(models.FoodRecommendation)
        .filter(
            models.FoodRecommendation.symptom_name == symptom_name,
            (models.FoodRecommendation.severity_level == severity)
            | (models.FoodRecommendation.severity_level == "الكل"),
        )
        .order_by(models.FoodRecommendation.severity_level == severity)
        .first()
    )

    if recommendation:
        return {
            "foods_to_eat": recommendation.foods_to_eat,
            "foods_to_avoid": recommendation.foods_to_avoid,
            "drinks_recommended": recommendation.drinks_recommended,
            "drinks_to_avoid": recommendation.drinks_to_avoid,
            "general_tips": recommendation.general_tips,
        }

    return {
        "foods_to_eat": ["خضروات طازجة", "فواكه", "بروتينات خفيفة"],
        "foods_to_avoid": ["أطعمة دسمة", "مقليات", "أطعمة مصنعة"],
        "drinks_recommended": ["ماء", "شاي أعشاب"],
        "drinks_to_avoid": ["مشروبات غازية", "قهوة بكثرة"],
        "general_tips": "تناول طعام صحي متوازن، اشرب كمية كافية من الماء",
    }


def get_symptom_type_data(db: Session, symptom_name: str):
    """جلب بيانات نوع العرض من جدول symptom_types"""

    # قائمة المرادفات للمطابقة
    symptom_mapping = {
        "إرهاق": "تعب",
        "تعب": "تعب",
        "زغللة العين": "زغللة",
        "زغللة": "زغللة",
        "ألم صدر": "ألم صدر",
        "ألم بطن": "ألم بطن",
        "ألم في المعدة": "ألم بطن",
        "ألم المفاصل": "ألم في المفاصل",
        "ألم في المفاصل": "ألم في المفاصل",
        "ألم العين": "ألم في العين",
        "ألم في العين": "ألم في العين",
        "ألم الظهر": "ألم في الظهر",
        "ألم في الظهر": "ألم في الظهر",
        "تنميل الأطراف": "تنميل",
        "تنميل": "تنميل",
        "حرارة": "حرارة",
        "حمى": "حرارة",
        "ضيق تنفس": "ضيق تنفس",
        "غثيان": "غثيان",
        "إسهال": "إسهال",
        "إمساك": "إمساك",
        "دوخة": "دوخة",
        "صداع": "صداع",
    }

    # جلب الاسم القياسي
    standard_name = symptom_mapping.get(symptom_name, symptom_name)

    symptom_type = (
        db.query(models.SymptomType)
        .filter(models.SymptomType.name_ar == standard_name)
        .first()
    )

    if not symptom_type:
        # محاولة البحث بالمطابقة الجزئية
        symptom_type = (
            db.query(models.SymptomType)
            .filter(models.SymptomType.name_ar.contains(symptom_name))
            .first()
        )

    # إذا لم نجد، جرب البحث بالاسم الإنجليزي
    if not symptom_type:
        symptom_type = (
            db.query(models.SymptomType)
            .filter(models.SymptomType.name_en.contains(symptom_name))
            .first()
        )

    return symptom_type


def analyze_symptom_logic_v2(name: str, severity: str = "متوسط", db: Session = None):
    """تحليل العرض باستخدام قاعدة البيانات أولاً، ثم الرجوع للتحليل المضمن"""

    # 1. محاولة جلب البيانات من جدول symptom_types إذا توفر db
    if db:
        symptom_type = get_symptom_type_data(db, name)
        if symptom_type:
            # دالة مساعدة لتحليل JSON
            def parse_json_field(field):
                if field is None:
                    return []
                if isinstance(field, list):
                    return field
                if isinstance(field, str):
                    try:
                        return json.loads(field)
                    except:
                        # محاولة تنظيف النص
                        cleaned = field.replace("'", '"')
                        try:
                            return json.loads(cleaned)
                        except:
                            # إذا فشل التحليل، اعتبر النص كعنصر واحد
                            return [field] if field else []
                return []

            causes = parse_json_field(symptom_type.common_causes)
            actions = parse_json_field(symptom_type.recommended_actions)
            warnings = parse_json_field(symptom_type.warning_signs)

            # التأكد من وجود بيانات كافية
            if causes and len(causes) > 0:
                # إضافة أسباب إضافية خاصة بالإرهاق والتعب
                if name in ["إرهاق", "تعب"] and len(causes) < 8:
                    extra_causes = [
                        "فقر الدم (الأنيميا)",
                        "قلة النوم أو الأرق",
                        "سوء التغذية",
                        "خمول الغدة الدرقية",
                        "الاكتئاب والضغط النفسي",
                        "نقص فيتامين د أو ب12",
                        "مرض السكري",
                        "الجفاف",
                    ]
                    # إضافة الأسباب الإضافية مع تجنب التكرار
                    for cause in extra_causes:
                        if cause not in causes:
                            causes.append(cause)

                # إضافة إجراءات إضافية خاصة بالإرهاق والتعب
                if name in ["إرهاق", "تعب"] and len(actions) < 6:
                    extra_actions = [
                        "نم 7-8 ساعات يومياً",
                        "تناول نظام غذائي متوازن غني بالحديد وفيتامين ب12",
                        "اشرب 8 أكواب ماء يومياً",
                        "مارس رياضة خفيفة كالمشي لمدة 30 دقيقة",
                        "افحص مستوى فيتامين د والحديد في الدم",
                        "راجع الطبيب لفحص الغدة الدرقية",
                    ]
                    for action in extra_actions:
                        if action not in actions:
                            actions.append(action)

                # إضافة علامات خطر إضافية
                if name in ["إرهاق", "تعب"] and len(warnings) < 5:
                    extra_warnings = [
                        "تعب شديد ومفاجئ",
                        "تعب مع فقدان وزن غير مبرر",
                        "تعب مع حرارة مرتفعة",
                        "تعب مع ضيق في التنفس",
                        "تعب استمر لأكثر من أسبوعين",
                    ]
                    for warning in extra_warnings:
                        if warning not in warnings:
                            warnings.append(warning)

                analysis_text = symptom_type.default_analysis
                if not analysis_text:
                    if name in ["إرهاق", "تعب"]:
                        analysis_text = "التعب والإرهاق المستمر قد يكون بسبب نقص الفيتامينات أو المعادن (خاصة الحديد وفيتامين ب12)، أو مشاكل في الغدة الدرقية، أو فقر الدم، أو اضطرابات النوم، أو الضغط النفسي المزمن."
                    else:
                        analysis_text = f"تحليل لـ {name}: هذا العرض يحتاج متابعة. إذا استمر أو ازداد سوءاً، استشر طبيبك."

                return {
                    "analysis": analysis_text,
                    "possible_causes": causes if causes else ["يحتاج متابعة طبية"],
                    "suggested_actions": actions if actions else ["استشر طبيبك"],
                    "warning_signs": warnings if warnings else ["إذا استمرت الأعراض"],
                }

    # 2. الرجوع للتحليل المضمن إذا لم يتم العثور على بيانات
    return analyze_symptom_logic(name, severity)


def analyze_symptom_logic(name: str, severity: str = "متوسط"):
    """تحليل العرض بناءً على اسمه وشدته (التحليل المضمن)"""

    # قاعدة بيانات التحليل الموسعة
    analysis_map = {
        "صداع": {
            "analysis": "الصداع قد يكون نتيجة للإجهاد، الجفاف، أو ارتفاع ضغط الدم.",
            "causes": [
                "الإجهاد والتعب",
                "الجفاف",
                "ارتفاع ضغط الدم",
                "الصداع النصفي",
                "إجهاد العين",
            ],
            "actions": [
                "قس ضغط الدم",
                "اشرب كمية كافية من الماء",
                "استرح في مكان هادئ ومظلم",
                "تجنب الشاشات (الهاتف - التلفاز)",
            ],
            "warnings": [
                "إذا كان مصحوباً بزغللة",
                "إذا كان مفاجئاً وشديداً",
                "إذا صاحبه تيبس في الرقبة",
            ],
        },
        "دوخة": {
            "analysis": "الدوخة قد تكون بسبب انخفاض ضغط الدم، فقر الدم، أو مشاكل في الأذن الداخلية.",
            "causes": [
                "انخفاض ضغط الدم",
                "فقر الدم (الأنيميا)",
                "التهاب الأذن الداخلية",
                "الجفاف",
                "انخفاض سكر الدم",
            ],
            "actions": [
                "اجلس أو استلقِ فوراً عند الشعور بالدوخة",
                "اشرب الماء بانتظام",
                "تناول وجبات صغيرة متكررة",
                "تجنب الوقوف المفاجئ",
            ],
            "warnings": [
                "إذا صاحبها فقدان وعي",
                "إذا كانت متكررة وشديدة",
                "إذا صاحبها ألم في الصدر",
            ],
        },
        "غثيان": {
            "analysis": "الغثيان قد يكون بسبب مشاكل في الجهاز الهضمي، الحمل، أو تناول أدوية معينة.",
            "causes": [
                "التهاب المعدة",
                "ارتجاع المريء",
                "تسمم غذائي",
                "دوار الحركة",
                "آثار جانبية لأدوية",
            ],
            "actions": [
                "تناول وجبات خفيفة وجافة",
                "اشرب سوائل باردة ببطء",
                "تجنب الأطعمة الدهنية والحارة",
                "جرب شاي الزنجبيل",
            ],
            "warnings": [
                "إذا استمر لأكثر من 48 ساعة",
                "إذا صاحبه قيء مستمر",
                "إذا كان مصحوباً بصداع شديد",
            ],
        },
        "ألم في المعدة": {
            "analysis": "ألم المعدة قد يكون بسبب عسر الهضم، التهاب المعدة، أو القولون العصبي.",
            "causes": [
                "عسر الهضم",
                "التهاب المعدة",
                "القولون العصبي",
                "قرحة المعدة",
                "تناول أطعمة مهيجة",
            ],
            "actions": [
                "تجنب الأطعمة الحارة والدسمة",
                "تناول وجبات صغيرة منتظمة",
                "اشرب شاي البابونج أو النعناع",
                "مارس تمارين الاسترخاء",
            ],
            "warnings": [
                "إذا كان الألم حاداً ومفاجئاً",
                "إذا صاحبه نزيف أو براز أسود",
                "إذا صاحبه فقدان وزن غير مبرر",
            ],
        },
        "حمى": {
            "analysis": "الحمى هي استجابة الجسم للعدوى أو الالتهاب.",
            "causes": [
                "عدوى فيروسية (نزلات برد، إنفلونزا)",
                "عدوى بكتيرية",
                "التهاب في الجسم",
                "ضربة شمس",
                "تطعيم حديث",
            ],
            "actions": [
                "قس درجة الحرارة بانتظام",
                "اشرب الكثير من السوائل",
                "خذ قسطاً من الراحة",
                "استخدم كمادات باردة",
            ],
            "warnings": [
                "إذا تجاوزت 39.5 درجة مئوية",
                "إذا استمرت لأكثر من 3 أيام",
                "إذا صاحبها تصلب في الرقبة",
            ],
        },
        "سعال": {
            "analysis": "السعال قد يكون بسبب التهاب الجهاز التنفسي، الحساسية، أو التدخين.",
            "causes": [
                "نزلات البرد والإنفلونزا",
                "التهاب الشعب الهوائية",
                "حساسية الجهاز التنفسي",
                "التدخين",
                "ارتجاع المريء",
            ],
            "actions": [
                "اشرب المشروبات الدافئة",
                "استخدم العسل لتلطيف الحلق",
                "تجنب المهيجات مثل الدخان",
                "استخدم جهاز ترطيب الهواء",
            ],
            "warnings": [
                "إذا استمر لأكثر من 3 أسابيع",
                "إذا صاحبه دم في البلغم",
                "إذا صاحبه صعوبة في التنفس",
            ],
        },
        "ألم في المفاصل": {
            "analysis": "ألم المفاصل قد يكون بسبب التهاب المفاصل، النقرس، أو الإجهاد البدني.",
            "causes": [
                "التهاب المفاصل",
                "النقرس",
                "الإجهاد البدني الزائد",
                "زيادة الوزن",
                "نقص فيتامين د",
            ],
            "actions": [
                "ضع كمادات باردة أو دافئة",
                "مارس تمارين خفيفة للمفاصل",
                "حافظ على وزن صحي",
                "تناول أطعمة غنية بالأوميغا 3",
            ],
            "warnings": [
                "إذا كان مصحوباً بتورم شديد",
                "إذا كان الألم يمنع الحركة",
                "إذا صاحبه احمرار وسخونة",
            ],
        },
        "ألم في الصدر": {
            "analysis": "ألم الصدر يحتاج اهتماماً فورياً - قد يكون بسبب مشاكل قلبية أو هضمية أو عضلية.",
            "causes": [
                "ذبحة صدرية",
                "ارتجاع المريء",
                "شد عضلي في القفص الصدري",
                "التهاب الغشاء البلوري",
                "نوبة قلق",
            ],
            "actions": [
                "توقف عن أي نشاط بدني فوراً",
                "اجلس في وضع مريح",
                "خذ نفساً عميقاً وبطيئاً",
                "اطلب المساعدة الطبية فوراً",
            ],
            "warnings": [
                "⚠️ توجه للطوارئ فوراً",
                "إذا امتد الألم للذراع أو الفك",
                "إذا صاحبه تعرق وضيق تنفس",
            ],
        },
        "ضيق تنفس": {
            "analysis": "ضيق التنفس قد يكون بسبب مشاكل رئوية، قلبية، أو حساسية.",
            "causes": [
                "الربو",
                "التهاب الشعب الهوائية",
                "حساسية",
                "مشاكل قلبية",
                "فقر الدم",
            ],
            "actions": [
                "اجلس في وضع مستقيم",
                "تنفس ببطء وعمق",
                "تجنب المهيجات",
                "استخدم البخاخات الموصوفة",
            ],
            "warnings": [
                "⚠️ إذا كان شديداً ومفاجئاً",
                "إذا صاحبه ألم في الصدر",
                "إذا تحولت الشفاه للون الأزرق",
            ],
        },
        "إسهال": {
            "analysis": "الإسهال قد يكون بسبب عدوى، تسمم غذائي، أو حساسية من أطعمة معينة.",
            "causes": [
                "عدوى بكتيرية أو فيروسية",
                "تسمم غذائي",
                "حساسية اللاكتوز",
                "متلازمة القولون العصبي",
                "تناول أطعمة ملوثة",
            ],
            "actions": [
                "اشرب الكثير من السوائل لتعويض المفقود",
                "تناول أطعمة خفيفة (أرز، موز، بطاطس)",
                "تجنب منتجات الألبان",
                "تجنب الأطعمة الدهنية والحارة",
            ],
            "warnings": [
                "إذا استمر لأكثر من 3 أيام",
                "إذا صاحبه دم في البراز",
                "إذا صاحبه جفاف شديد",
            ],
        },
        "إمساك": {
            "analysis": "الإمساك قد يكون بسبب قلة الألياف، قلة السوائل، أو قلة الحركة.",
            "causes": [
                "نقص الألياف في الطعام",
                "قلة شرب الماء",
                "قلة النشاط البدني",
                "بعض الأدوية",
                "متلازمة القولون العصبي",
            ],
            "actions": [
                "زد من تناول الخضروات والفواكه",
                "اشرب 8-10 أكواب من الماء يومياً",
                "مارس المشي بانتظام",
                "تناول البروبيوتيك",
            ],
            "warnings": [
                "إذا استمر لأكثر من أسبوعين",
                "إذا صاحبه ألم شديد",
                "إذا كان متناوباً مع إسهال",
            ],
        },
        "ألم في الظهر": {
            "analysis": "ألم الظهر قد يكون بسبب وضعية جلوس خاطئة، إجهاد عضلي، أو مشاكل في العمود الفقري.",
            "causes": [
                "وضعية جلوس خاطئة",
                "إجهاد عضلي",
                "الانزلاق الغضروفي",
                "زيادة الوزن",
                "ضعف عضلات الظهر والبطن",
            ],
            "actions": [
                "حافظ على وضعية جلوس صحيحة",
                "ضع كمادات دافئة على موضع الألم",
                "مارس تمارين تقوية الظهر",
                "تجنب حمل الأشياء الثقيلة",
            ],
            "warnings": [
                "إذا امتد الألم للساق",
                "إذا صاحبه خدر أو تنميل",
                "إذا صاحبه فقدان السيطرة على المثانة",
            ],
        },
        "تعب وإرهاق": {
            "analysis": "التعب والإرهاق المستمر قد يكون بسبب نقص الفيتامينات أو المعادن (خاصة الحديد وفيتامين ب12)، أو مشاكل في الغدة الدرقية، أو فقر الدم، أو اضطرابات النوم، أو الضغط النفسي المزمن.",
            "causes": [
                "فقر الدم (الأنيميا)",
                "قلة النوم أو الأرق",
                "سوء التغذية",
                "خمول الغدة الدرقية",
                "الاكتئاب والضغط النفسي",
                "نقص فيتامين د أو ب12",
                "مرض السكري",
                "الجفاف",
            ],
            "actions": [
                "نم 7-8 ساعات يومياً",
                "تناول نظام غذائي متوازن غني بالحديد وفيتامين ب12",
                "اشرب 8 أكواب ماء يومياً",
                "مارس رياضة خفيفة كالمشي لمدة 30 دقيقة",
                "افحص مستوى فيتامين د والحديد في الدم",
                "راجع الطبيب لفحص الغدة الدرقية",
            ],
            "warnings": [
                "تعب شديد ومفاجئ",
                "تعب مع فقدان وزن غير مبرر",
                "تعب مع حرارة مرتفعة",
                "تعب مع ضيق في التنفس",
                "تعب استمر لأكثر من أسبوعين",
            ],
        },
        "ألم في العين": {
            "analysis": "ألم العين قد يكون بسبب إجهاد العين، جفاف العين، أو التهاب.",
            "causes": [
                "إجهاد العين من الشاشات",
                "جفاف العين",
                "التهاب الملتحمة",
                "ارتفاع ضغط العين",
                "حساسية",
            ],
            "actions": [
                "خذ استراحات من الشاشات كل 20 دقيقة",
                "استخدم قطرات مرطبة للعين",
                "تجنب فرك العين",
                "استخدم إضاءة مناسبة",
            ],
            "warnings": [
                "إذا صاحبه فقدان مفاجئ للرؤية",
                "إذا صاحبه ألم شديد",
                "إذا صاحبه رؤية هالات حول الأضواء",
            ],
        },
        "أرق": {
            "analysis": "الأرق قد يكون بسبب التوتر، القلق، الكافيين، أو اضطرابات النوم.",
            "causes": [
                "التوتر والقلق",
                "تناول الكافيين",
                "اضطرابات النوم (انقطاع التنفس)",
                "استخدام الأجهزة قبل النوم",
                "ألم مزمن",
            ],
            "actions": [
                "حدد موعداً ثابتاً للنوم",
                "تجنب الكافيين مساءً",
                "أغلق الأجهزة قبل النوم بساعة",
                "مارس تمارين الاسترخاء",
            ],
            "warnings": [
                "إذا استمر لأكثر من شهر",
                "إذا أثر على الأداء اليومي",
                "إذا صاحبه اكتئاب",
            ],
        },
        "حكة جلدية": {
            "analysis": "الحكة الجلدية قد تكون بسبب حساسية، جفاف الجلد، أو أمراض جلدية.",
            "causes": [
                "حساسية جلدية",
                "جفاف الجلد",
                "الإكزيما",
                "لدغات الحشرات",
                "أمراض الكبد",
            ],
            "actions": [
                "رطب الجلد بانتظام",
                "تجنب المواد المهيجة",
                "استخدم كريمات مضادة للحكة",
                "استحم بماء فاتر",
            ],
            "warnings": [
                "إذا صاحبها طفح جلدي منتشر",
                "إذا استمرت لأكثر من أسبوعين",
                "إذا صاحبها اصفرار الجلد",
            ],
        },
        "تنميل": {
            "analysis": "التنميل قد يكون بسبب الضغط على الأعصاب، نقص فيتامين ب12، أو مشاكل في الدورة الدموية.",
            "causes": [
                "الضغط على الأعصاب",
                "نقص فيتامين ب12",
                "مرض السكري",
                "اعتلال الأعصاب المحيطية",
                "مشاكل الدورة الدموية",
            ],
            "actions": [
                "غير وضعية جسمك بانتظام",
                "مارس تمارين التمدد",
                "افحص مستويات السكر",
                "تناول أطعمة غنية بفيتامين ب12",
            ],
            "warnings": [
                "إذا كان مستمراً في جانب واحد",
                "إذا صاحبه ضعف عضلي",
                "إذا بدأ فجأة",
            ],
        },
        "انتفاخ": {
            "analysis": "الانتفاخ قد يكون بسبب الغازات، عسر الهضم، أو حساسية الطعام.",
            "causes": [
                "تراكم الغازات",
                "عسر الهضم",
                "حساسية اللاكتوز",
                "تناول الطعام بسرعة",
                "متلازمة القولون العصبي",
            ],
            "actions": [
                "تناول الطعام ببطء",
                "تجنب المشروبات الغازية",
                "امضغ الطعام جيداً",
                "جرب شاي النعناع أو الكمون",
            ],
            "warnings": [
                "إذا كان مصحوباً بألم شديد",
                "إذا استمر لأكثر من أسبوع",
                "إذا صاحبه فقدان وزن",
            ],
        },
        "زغللة": {
            "analysis": "زغللة العين قد تكون بسبب إجهاد العين، ارتفاع ضغط الدم، أو الصداع النصفي.",
            "causes": [
                "إجهاد العين من الشاشات",
                "ارتفاع ضغط الدم",
                "الصداع النصفي",
                "مشاكل في الشبكية",
                "انخفاض سكر الدم",
            ],
            "actions": [
                "خذ استراحة من الشاشات",
                "قس ضغط الدم",
                "افحص مستوى السكر",
                "استشر طبيب العيون",
            ],
            "warnings": [
                "إذا كانت مفاجئة",
                "إذا كانت مع صداع شديد",
                "إذا كانت مع ضعف في الرؤية",
            ],
        },
    }

    # قاموس المرادفات - يربط أسماء الأعراض الشائعة من التطبيق بمفاتيح التحليل
    alias_map = {
        "تعب": "تعب وإرهاق",
        "إرهاق": "تعب وإرهاق",
        "ألم صدر": "ألم في الصدر",
        "ألم بطن": "ألم في المعدة",
        "حرارة": "حمى",
        "تنميل الأطراف": "تنميل",
        "زغللة العين": "زغللة",
        "ألم المفاصل": "ألم في المفاصل",
        "ألم العين": "ألم في العين",
        "ألم الظهر": "ألم في الظهر",
    }

    # 1. محاولة المطابقة التامة أولاً
    result = analysis_map.get(name)

    # 2. إذا لم يجد، جرب المرادفات
    if result is None:
        alias_key = alias_map.get(name)
        if alias_key:
            result = analysis_map.get(alias_key)

    # 3. إذا لم يجد، جرب المطابقة الجزئية (احتواء)
    if result is None:
        for key, value in analysis_map.items():
            if name in key or key in name:
                result = value
                break

    # 4. القيمة الافتراضية إذا لم يجد شيئاً
    if result is None:
        result = {
            "analysis": f"هذا العرض ({name}) يحتاج متابعة. إذا استمر، استشر طبيبك.",
            "causes": [
                "قد يكون مرتبطاً بنمط حياتك اليومي",
                "قد يكون بسبب نقص غذائي",
                "قد يكون عرضاً لحالة صحية كامنة",
            ],
            "actions": [
                "سجل الأعراض ومواعيد حدوثها",
                "حافظ على نظام غذائي صحي",
                "اشرب كمية كافية من الماء",
                "استشر طبيبك لمتابعة الحالة",
            ],
            "warnings": [
                "إذا ازدادت شدة الأعراض",
                "إذا ظهرت أعراض جديدة",
                "إذا استمرت الحالة لأكثر من 3 أيام",
            ],
        }

    if severity == "شديد":
        result["analysis"] = "🚨 " + result["analysis"]
        result["warnings"].insert(0, "هذا عرض شديد - قد يحتاج تدخلاً طبياً")

    return {
        "analysis": result["analysis"],
        "possible_causes": result["causes"],
        "suggested_actions": result["actions"],
        "warning_signs": result["warnings"],
    }


def get_medicine_id_by_name(db: Session, medicine_name: str):
    """جلب ID الدواء من اسمه"""
    medicine = (
        db.query(models.Medicine)
        .filter(models.Medicine.name_ar == medicine_name)
        .first()
    )
    return medicine.id if medicine else None
