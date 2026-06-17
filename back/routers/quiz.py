# backend/routers/quiz.py

from fastapi import APIRouter, Depends, HTTPException
from typing import Optional, List, Dict
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import date, datetime, timedelta

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/api/quiz", tags=["quiz"])


# ============================================
# ✅ 1. جلب جميع الأسئلة
# ============================================
@router.get("/questions", response_model=List[schemas.QuizQuestionResponse])
def get_all_questions(
    category: str = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب جميع أسئلة الكويز"""
    print(f"📋 [Quiz] جلب الأسئلة للمستخدم {current_user.id}")

    query = db.query(models.QuizQuestion).filter(models.QuizQuestion.is_active == True)

    if category:
        query = query.filter(models.QuizQuestion.category == category)

    questions = query.order_by(models.QuizQuestion.default_order).all()

    # جلب الخيارات لكل سؤال
    for q in questions:
        q.options = (
            db.query(models.QuizOption)
            .filter(models.QuizOption.question_id == q.id)
            .order_by(models.QuizOption.order)
            .all()
        )

    return questions


# ============================================
# ✅ 2. إرسال إجابات الكويز
# ============================================
@router.post("/submit", response_model=schemas.QuizSessionResponse)
def submit_quiz(
    quiz_data: schemas.QuizSessionSubmit,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حفظ إجابات الكويز للمستخدم"""
    print(f"📝 [Quiz] حفظ إجابات الكويز للمستخدم {current_user.id}")

    # حساب المجموع الكلي
    total_score = 0
    category_scores = {}

    # إنشاء جلسة جديدة
    session = models.QuizSession(
        user_id=current_user.id,
        is_onboarding=quiz_data.is_onboarding,
        session_date=datetime.utcnow(),
    )
    db.add(session)
    db.flush()

    # حفظ الإجابات
    for answer in quiz_data.answers:
        # جلب قيمة الخيار المختار
        option = (
            db.query(models.QuizOption)
            .filter(models.QuizOption.id == answer.selected_option_id)
            .first()
        )

        if not option:
            continue

        # جلب فئة السؤال
        question = (
            db.query(models.QuizQuestion)
            .filter(models.QuizQuestion.id == answer.question_id)
            .first()
        )

        score = option.score_value
        total_score += score

        category = question.category if question else "general"
        category_scores[category] = category_scores.get(category, 0) + score

        # حفظ الإجابة
        user_answer = models.UserQuizAnswer(
            user_id=current_user.id,
            session_id=session.id,
            question_id=answer.question_id,
            selected_option_id=answer.selected_option_id,
        )
        db.add(user_answer)

    # تحديث المجموع
    session.total_score = total_score

    db.commit()
    db.refresh(session)

    print(f"✅ [Quiz] تم حفظ الجلسة ID: {session.id}, المجموع: {total_score}")

    return {
        "id": session.id,
        "session_date": session.session_date,
        "is_onboarding": session.is_onboarding,
        "total_score": total_score,
        "category_scores": category_scores,
        "answers": [],
    }


# ============================================
# ✅ 3. جلب سجل الكويزات للمستخدم
# ============================================
@router.get("/sessions", response_model=List[schemas.QuizSessionResponse])
def get_quiz_sessions(
    current_user: models.User = Depends(get_current_user),
    limit: int = 10,
    db: Session = Depends(get_db),
):
    """جلب سجل الكويزات للمستخدم"""
    print(f"📋 [Quiz] جلب سجل الكويزات للمستخدم {current_user.id}")

    sessions = (
        db.query(models.QuizSession)
        .filter(models.QuizSession.user_id == current_user.id)
        .order_by(models.QuizSession.session_date.desc())
        .limit(limit)
        .all()
    )

    return [
        {
            "id": s.id,
            "session_date": s.session_date,
            "is_onboarding": s.is_onboarding,
            "total_score": s.total_score,
            "category_scores": {},
            "answers": [],
        }
        for s in sessions
    ]


# ============================================
# ✅ 4. جلب آخر جلسة كويز
# ============================================
@router.get("/last-session", response_model=schemas.QuizSessionResponse)
def get_last_quiz_session(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب آخر جلسة كويز للمستخدم"""
    print(f"📋 [Quiz] جلب آخر جلسة كويز للمستخدم {current_user.id}")

    session = (
        db.query(models.QuizSession)
        .filter(models.QuizSession.user_id == current_user.id)
        .order_by(models.QuizSession.session_date.desc())
        .first()
    )

    if not session:
        raise HTTPException(status_code=404, detail="لا توجد جلسات كويز")

    return {
        "id": session.id,
        "session_date": session.session_date,
        "is_onboarding": session.is_onboarding,
        "total_score": session.total_score,
        "category_scores": {},
        "answers": [],
    }


# ============================================
# ✅ 5. مقارنة بين جلسات الكويز
# ============================================
@router.get("/compare")
def compare_quiz_sessions(
    current_user: models.User = Depends(get_current_user),
    previous_session_id: int = None,
    db: Session = Depends(get_db),
):
    """مقارنة بين جلسات الكويز (الجلسة الحالية والسابقة)"""
    print(f"📊 [Quiz] مقارنة جلسات الكويز للمستخدم {current_user.id}")

    # الحصول على آخر جلستين
    sessions = (
        db.query(models.QuizSession)
        .filter(models.QuizSession.user_id == current_user.id)
        .order_by(models.QuizSession.session_date.desc())
        .limit(2)
        .all()
    )

    if len(sessions) < 2:
        return {
            "has_comparison": False,
            "message": "تحتاج إلى جلستي كويز على الأقل للمقارنة",
        }

    current_session = sessions[0]
    previous_session = sessions[1]

    # جلب الإجابات لكل جلسة
    def get_session_answers(session_id):
        answers = (
            db.query(models.UserQuizAnswer)
            .filter(models.UserQuizAnswer.session_id == session_id)
            .all()
        )

        result = {}
        for ans in answers:
            option = (
                db.query(models.QuizOption)
                .filter(models.QuizOption.id == ans.selected_option_id)
                .first()
            )
            question = (
                db.query(models.QuizQuestion)
                .filter(models.QuizQuestion.id == ans.question_id)
                .first()
            )

            if question:
                category = question.category
                if category not in result:
                    result[category] = 0
                result[category] += option.score_value if option else 0

        return result

    previous_answers = get_session_answers(previous_session.id)
    current_answers = get_session_answers(current_session.id)

    # تحديد الفئات التي تحسنت وساءت
    all_categories = set(previous_answers.keys()) | set(current_answers.keys())
    improved = []
    declined = []
    stable = []

    for category in all_categories:
        prev_score = previous_answers.get(category, 0)
        curr_score = current_answers.get(category, 0)

        if curr_score > prev_score:
            improved.append(category)
        elif curr_score < prev_score:
            declined.append(category)
        else:
            stable.append(category)

    score_change = current_session.total_score - previous_session.total_score
    score_change_percentage = (
        (score_change / previous_session.total_score) * 100
        if previous_session.total_score > 0
        else 0
    )

    # إنشاء توصيات بناءً على التحسن أو التراجع
    recommendations = []
    for category in declined:
        recommendations.append(get_recommendation_for_category(category))

    return {
        "has_comparison": True,
        "previous_session_id": previous_session.id,
        "current_session_id": current_session.id,
        "previous_date": previous_session.session_date,
        "current_date": current_session.session_date,
        "previous_total_score": previous_session.total_score,
        "current_total_score": current_session.total_score,
        "score_change": score_change,
        "score_change_percentage": score_change_percentage,
        "improved_categories": improved,
        "declined_categories": declined,
        "stable_categories": stable,
        "recommendations": recommendations,
    }


# ============================================
# ✅ 6. تحليل الكويز (نقاط القوة والضعف)
# ============================================
@router.get("/analysis")
def analyze_quiz(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تحليل آخر كويز للمستخدم"""
    print(f"📊 [Quiz] تحليل آخر كويز للمستخدم {current_user.id}")

    # الحصول على آخر جلسة
    session = (
        db.query(models.QuizSession)
        .filter(models.QuizSession.user_id == current_user.id)
        .order_by(models.QuizSession.session_date.desc())
        .first()
    )

    if not session:
        return {"has_analysis": False, "message": "لا توجد جلسات كويز للتحليل"}

    # جلب الإجابات مع التفاصيل
    answers = (
        db.query(models.UserQuizAnswer)
        .filter(models.UserQuizAnswer.session_id == session.id)
        .all()
    )

    # تحليل كل فئة
    categories_analysis = {}
    strength_areas = []
    weakness_areas = []

    for ans in answers:
        question = (
            db.query(models.QuizQuestion)
            .filter(models.QuizQuestion.id == ans.question_id)
            .first()
        )
        option = (
            db.query(models.QuizOption)
            .filter(models.QuizOption.id == ans.selected_option_id)
            .first()
        )

        if question and option:
            category = question.category
            if category not in categories_analysis:
                categories_analysis[category] = {
                    "total_score": 0,
                    "max_score": 0,
                    "question_count": 0,
                }

            categories_analysis[category]["total_score"] += option.score_value
            categories_analysis[category]["max_score"] += 3  # أقصى درجة للسؤال الواحد
            categories_analysis[category]["question_count"] += 1

    # حساب النسب وتحديد نقاط القوة والضعف
    for category, data in categories_analysis.items():
        percentage = (
            (data["total_score"] / data["max_score"]) * 100
            if data["max_score"] > 0
            else 0
        )
        data["percentage"] = round(percentage, 1)

        if percentage >= 70:
            strength_areas.append(category)
        elif percentage <= 40:
            weakness_areas.append(category)

    return {
        "has_analysis": True,
        "session_id": session.id,
        "session_date": session.session_date,
        "total_score": session.total_score,
        "categories_analysis": categories_analysis,
        "strength_areas": strength_areas,
        "weakness_areas": weakness_areas,
        "overall_rating": get_overall_rating(session.total_score, categories_analysis),
    }


def get_recommendation_for_category(category: str) -> dict:
    """إرجاع توصية مخصصة بناءً على الفئة"""
    recommendations = {
        "sleep": {
            "title": "تحسين جودة النوم",
            "message": "حاول النوم 7-8 ساعات يومياً، وتجنب الشاشات قبل النوم بساعة",
            "action": "اضبط منبه للنوم والاستيقاظ",
        },
        "nutrition": {
            "title": "تحسين التغذية",
            "message": "زد من تناول الخضروات والفواكه، واشرب 8 أكواب ماء يومياً",
            "action": "سجل وجباتك يومياً في التطبيق",
        },
        "activity": {
            "title": "زيادة النشاط البدني",
            "message": "حاول ممارسة الرياضة 30 دقيقة يومياً، وزد عدد خطواتك تدريجياً",
            "action": "استخدم وضع المحاكاة للمشي",
        },
        "mental": {
            "title": "تحسين الصحة النفسية",
            "message": "مارس تمارين التنفس العميق، وخصص وقتاً للاسترخاء",
            "action": "جرب تمارين التأمل",
        },
        "physical": {
            "title": "العناية بالأعراض الجسدية",
            "message": "تابع الأعراض وسجلها لمراقبة التحسن",
            "action": "سجل أي أعراض جديدة في التطبيق",
        },
        "habits": {
            "title": "تحسين العادات اليومية",
            "message": "قلل وقت الشاشات، وحاول النوم في وقت مبكر",
            "action": "اضبط وقت محدد لاستخدام الهاتف",
        },
        "social": {
            "title": "تعزيز العلاقات الاجتماعية",
            "message": "خصص وقتاً للتواصل مع العائلة والأصدقاء",
            "action": "شارك تقدمك مع الأصدقاء",
        },
        "medication": {
            "title": "الالتزام بالأدوية",
            "message": "استخدم التذكيرات لمواعيد الأدوية",
            "action": "فعّل إشعارات الأدوية",
        },
        "environment": {
            "title": "تحسين البيئة المحيطة",
            "message": "حسّن تهوية المنزل، وقلل مصادر التوتر",
            "action": "افتح النوافذ للتهوية يومياً",
        },
    }

    return recommendations.get(
        category,
        {
            "title": "تحسين صحتك",
            "message": "استمر في متابعة صحتك وسجل بياناتك يومياً",
            "action": "تابع تقدمك في التطبيق",
        },
    )


def get_overall_rating(total_score: int, categories_analysis: dict) -> dict:
    """تقييم عام بناءً على النتائج"""
    avg_percentage = (
        sum([d["percentage"] for d in categories_analysis.values()])
        / len(categories_analysis)
        if categories_analysis
        else 0
    )

    if avg_percentage >= 80:
        return {
            "level": "ممتاز",
            "color": "#4CAF50",
            "message": "نمط حياتك صحي جداً، استمر في الحفاظ على عاداتك الإيجابية",
        }
    elif avg_percentage >= 60:
        return {
            "level": "جيد",
            "color": "#8BC34A",
            "message": "أنت على الطريق الصحيح، هناك بعض المجالات التي يمكن تحسينها",
        }
    elif avg_percentage >= 40:
        return {
            "level": "متوسط",
            "color": "#FFC107",
            "message": "يحتاج نمط حياتك إلى بعض التحسينات، ننصحك باتباع التوصيات",
        }
    else:
        return {
            "level": "يحتاج تحسين",
            "color": "#F44336",
            "message": "نمط حياتك يحتاج إلى تحسين كبير، ننصحك ببدء تطبيق التوصيات فوراً",
        }


# ============================================
# نقاط نهاية الكويز اليومي (Daily Quiz Endpoints)
# ============================================


@router.get("/daily-questions", response_model=List[schemas.DailyQuizQuestionResponse])
# backend/routers/quiz.py

# استبدل دالة get_daily_questions بهذه النسخة المعدلة


@router.get("/daily-questions", response_model=List[schemas.DailyQuizQuestionResponse])
def get_daily_questions(
    time_of_day: Optional[str] = None,
    category: Optional[str] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب أسئلة الكويز اليومي"""
    print(f"📋 [Daily Quiz] جلب الأسئلة اليومية للمستخدم {current_user.id}")

    query = db.query(models.DailyQuizQuestion).filter(
        models.DailyQuizQuestion.is_active == True
    )

    if time_of_day:
        query = query.filter(
            models.DailyQuizQuestion.time_of_day.in_([time_of_day, "both"])
        )

    if category:
        query = query.filter(models.DailyQuizQuestion.category == category)

    questions = query.order_by(models.DailyQuizQuestion.default_order).all()

    # ✅ تحويل الأسئلة إلى قاموس مع الخيارات
    result = []
    for q in questions:
        # جلب الخيارات وتحويلها إلى قاموس
        options = (
            db.query(models.DailyQuizOption)
            .filter(models.DailyQuizOption.question_id == q.id)
            .order_by(models.DailyQuizOption.order)
            .all()
        )

        # تحويل كل سؤال إلى قاموس
        question_dict = {
            "id": q.id,
            "question_text": q.question_text,
            "category": q.category,
            "default_order": q.default_order,
            "is_active": q.is_active,
            "time_of_day": q.time_of_day,
            "options": [
                {
                    "id": opt.id,
                    "option_text": opt.option_text,
                    "score_value": opt.score_value,
                    "order": opt.order,
                }
                for opt in options
            ],
        }
        result.append(question_dict)

    return result


@router.get("/daily-status/today", response_model=schemas.DailyQuizStatus)
def get_today_quiz_status(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب حالة الكويز اليوم"""
    print(f"📋 [Daily Quiz] جلب حالة الكويز اليوم للمستخدم {current_user.id}")

    today = datetime.utcnow().date()
    
    # جلب جلسات اليوم
    sessions = (
        db.query(models.DailyQuizSession)
        .filter(
            models.DailyQuizSession.user_id == current_user.id,
            models.DailyQuizSession.session_date == today
        )
        .all()
    )

    morning_session = next((s for s in sessions if s.time_of_day == "morning"), None)
    evening_session = next((s for s in sessions if s.time_of_day == "evening"), None)

    return {
        "date": today,
        "morning_completed": morning_session is not None,
        "evening_completed": evening_session is not None,
        "morning_completed_at": morning_session.created_at if morning_session else None,
        "evening_completed_at": evening_session.created_at if evening_session else None,
        "morning_score": morning_session.total_score if morning_session else 0,
        "evening_score": evening_session.total_score if evening_session else 0,
    }


@router.get("/daily-status/weekly", response_model=List[schemas.DailyQuizStatus])
def get_weekly_quiz_status(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب حالة الكويز للأسبوع الماضي"""
    print(f"📋 [Daily Quiz] جلب حالة الكويز الأسبوعية للمستخدم {current_user.id}")

    end_date = datetime.utcnow().date()
    start_date = end_date - timedelta(days=6)  # آخر 7 أيام
    
    # جلب جميع الجلسات في الفترة
    sessions = (
        db.query(models.DailyQuizSession)
        .filter(
            models.DailyQuizSession.user_id == current_user.id,
            models.DailyQuizSession.session_date >= start_date,
            models.DailyQuizSession.session_date <= end_date
        )
        .all()
    )

    # تجميع النتائج حسب التاريخ
    results = []
    current_date = start_date
    while current_date <= end_date:
        date_sessions = [s for s in sessions if s.session_date == current_date]
        
        morning_session = next((s for s in date_sessions if s.time_of_day == "morning"), None)
        evening_session = next((s for s in date_sessions if s.time_of_day == "evening"), None)

        results.append({
            "date": current_date,
            "morning_completed": morning_session is not None,
            "evening_completed": evening_session is not None,
            "morning_completed_at": morning_session.created_at if morning_session else None,
            "evening_completed_at": evening_session.created_at if evening_session else None,
            "morning_score": morning_session.total_score if morning_session else 0,
            "evening_score": evening_session.total_score if evening_session else 0,
        })
        
        current_date += timedelta(days=1)

    return results


@router.post("/daily-sessions", response_model=schemas.DailyQuizSessionResponse, status_code=201)
def submit_daily_quiz(
    quiz_data: schemas.DailyQuizSessionCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """إرسال إجابات الكويز اليومي"""
    print(f"📝 [Daily Quiz] إرسال إجابات الكويز اليومي للمستخدم {current_user.id}")

    # حساب المجموع الكلي
    total_score = 0
    
    # إنشاء جلسة جديدة
    session = models.DailyQuizSession(
        user_id=current_user.id,
        session_date=datetime.utcnow().date(),
        time_of_day=quiz_data.time_of_day,
        notes=quiz_data.notes,
    )
    db.add(session)
    db.flush()

    # حفظ الإجابات
    for question_id, option_id in quiz_data.answers.items():
        # جلب قيمة الخيار المختار
        option = (
            db.query(models.DailyQuizOption)
            .filter(models.DailyQuizOption.id == option_id)
            .first()
        )

        if not option:
            continue

        score = option.score_value
        total_score += score

        # حفظ الإجابة
        answer = models.DailyQuizAnswer(
            user_id=current_user.id,
            session_id=session.id,
            question_id=question_id,
            selected_option_id=option_id,
        )
        db.add(answer)

    # تحديث النتيجة الكلية للجلسة
    session.total_score = total_score
    db.commit()
    db.refresh(session)

    return session


@router.get("/daily-sessions", response_model=List[schemas.DailyQuizSessionResponse])
def get_daily_sessions(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    time_of_day: Optional[str] = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """جلب جلسات الكويز اليومي"""
    print(f"📋 [Daily Quiz] جلب جلسات الكويز اليومي للمستخدم {current_user.id}")

    query = db.query(models.DailyQuizSession).filter(
        models.DailyQuizSession.user_id == current_user.id
    )

    if start_date:
        query = query.filter(models.DailyQuizSession.session_date >= start_date)
    
    if end_date:
        query = query.filter(models.DailyQuizSession.session_date <= end_date)
    
    if time_of_day:
        query = query.filter(models.DailyQuizSession.time_of_day == time_of_day)

    sessions = query.order_by(models.DailyQuizSession.session_date.desc()).all()
    return sessions
