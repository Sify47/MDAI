# backend/routers/chat.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from typing import List, Optional
import json
import re
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from datetime import datetime
from pydantic import BaseModel

from database import get_db
import models

router = APIRouter(prefix="/chat", tags=["chat"])

# ============================================
# تهيئة DeepSeek API مع إعدادات SSL محسنة
# ============================================
DEEPSEEK_API_KEY = "sk-532c55cdfc6647178cb139d67ace583e"
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"


# إعداد جلسة requests مع إعادة المحاولة
def create_session():
    session = requests.Session()
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session


session = create_session()


# ============================================
# Pydantic Models
# ============================================
class ChatRequest(BaseModel):
    question: str
    user_id: Optional[int] = 1


class ChatResponse(BaseModel):
    success: bool
    source: str  # 'database' أو 'deepseek' أو 'local' أو 'error'
    title: str
    content: str
    bullets: List[str] = []
    confidence: float = 1.0
    message: Optional[str] = None
    qa_id: Optional[int] = None


class FeedbackRequest(BaseModel):
    qa_id: int
    helpful: bool


# ============================================
# دوال مساعدة
# ============================================
def normalize_arabic_text(text: str) -> str:
    """تبسيط النص العربي للبحث"""
    # إزالة علامات الترقيم
    text = re.sub(r"[^\w\s]", "", text)
    # توحيد أشكال الألف
    text = re.sub("[إأآا]", "ا", text)
    text = re.sub("ى", "ي", text)
    text = re.sub("ة", "ه", text)
    return text.lower().strip()


def extract_keywords(text: str) -> List[str]:
    """استخراج الكلمات المفتاحية من النص"""
    stop_words = {
        "في",
        "من",
        "الى",
        "على",
        "عن",
        "ما",
        "هذا",
        "هذه",
        "هل",
        "كان",
        "كانت",
        "كانوا",
        "مع",
        "عند",
        "لدي",
    }
    words = text.split()
    keywords = [word for word in words if word not in stop_words and len(word) > 1]
    return keywords[:5]


# ============================================
# البحث في قاعدة البيانات
# ============================================
def search_in_database(db: Session, question: str) -> Optional[models.ChatQA]:
    """البحث عن سؤال مشابه في قاعدة البيانات"""
    normalized = normalize_arabic_text(question)
    keywords = extract_keywords(question)

    print(f"🔍 البحث عن: {normalized}")
    print(f"📌 الكلمات المفتاحية: {keywords}")

    # 1. بحث بالكلمات المفتاحية
    if keywords:
        keyword_conditions = []
        for kw in keywords:
            keyword_conditions.append(models.ChatQA.keywords.contains(kw))

        if keyword_conditions:
            results = (
                db.query(models.ChatQA)
                .filter(or_(*keyword_conditions))
                .order_by(
                    models.ChatQA.confidence.desc(), models.ChatQA.usage_count.desc()
                )
                .limit(3)
                .all()
            )

            if results:
                print(f"✅ تم العثور على {len(results)} نتيجة بالكلمات المفتاحية")
                return results[0]

    # 2. بحث في السؤال نفسه
    result = (
        db.query(models.ChatQA)
        .filter(
            or_(
                models.ChatQA.question.contains(question[:50]),
                models.ChatQA.normalized_question.contains(normalized),
            )
        )
        .order_by(models.ChatQA.confidence.desc(), models.ChatQA.usage_count.desc())
        .first()
    )

    if result:
        print(f"✅ تم العثور على نتيجة في السؤال")
        return result

    return None


# ============================================
# إجابات محلية (بدون API)
# ============================================
def get_local_answer(question: str) -> Optional[dict]:
    """إجابات محلية للأسئلة الشائعة"""
    q = question.lower()

    # قاموس الإجابات المحلية
    answers = {
        "بنكرياس": {
            "title": "🫁 معلومات عن البنكرياس",
            "content": "البنكرياس غدة مهمة في الجسم تقع خلف المعدة.",
            "bullets": [
                "• وظائفه: إنتاج الأنسولين (لتنظيم السكر) وإنزيمات الهضم",
                "• مشاكله الشائعة: التهاب البنكرياس، السكري، أورام",
                "• أعراض مشاكله: ألم في البطن، غثيان، فقدان وزن",
                "• إذا شعرت بألم شديد في البطن، استشر طبيباً فوراً",
            ],
        },
        "سكر": {
            "title": "🍬 معلومات عن السكري",
            "content": "السكري مرض مزمن يرتفع فيه مستوى السكر في الدم.",
            "bullets": [
                "• النوع الأول: يحدث عندما لا ينتج البنكرياس أنسولين",
                "• النوع الثاني: لا يستخدم الجسم الأنسولين بشكل صحيح",
                "• الأعراض: عطش شديد، كثرة التبول، تعب",
                "• العلاج: أدوية، نظام غذائي، رياضة",
            ],
        },
        "ضغط": {
            "title": "💓 معلومات عن الضغط",
            "content": "ضغط الدم هو قوة دفع الدم ضد جدران الشرايين.",
            "bullets": [
                "• الطبيعي: أقل من 120/80",
                "• المرتفع: 130/80 أو أكثر",
                "• الأعراض: غالباً لا تظهر (القاتل الصامت)",
                "• العلاج: تقليل الملح، أدوية، رياضة",
            ],
        },
        "قولون": {
            "title": "🫄 معلومات عن القولون",
            "content": "القولون جزء من الأمعاء الغليظة في الجهاز الهضمي.",
            "bullets": [
                "• القولون العصبي: انتفاخ، غازات، ألم في البطن",
                "• الأسباب: توتر، أطعمة مهيجة، تغيرات هرمونية",
                "• العلاج: تجنب المهيجات، وجبات صغيرة، ماء",
                "• استشر طبيباً إذا استمرت الأعراض",
            ],
        },
        "حمى": {
            "title": "🌡️ معلومات عن الحمى",
            "content": "الحمى هي ارتفاع درجة حرارة الجسم فوق 38 درجة مئوية.",
            "bullets": [
                "• الأسباب: عدوى، التهاب، ضربة شمس",
                "• العلاج: خافضات الحرارة، كمادات، شرب سوائل",
                "• إذا استمرت أكثر من 3 أيام، استشر طبيباً",
            ],
        },
        "صداع": {
            "title": "🤕 معلومات عن الصداع",
            "content": "الصداع من أكثر المشاكل شيوعاً وله أسباب متعددة.",
            "bullets": [
                "• الأسباب: إجهاد، جفاف، قلة نوم، إجهاد العين",
                "• العلاج: راحة، مسكنات، كمادات باردة",
                "• إذا كان شديداً أو متكرراً، استشر طبيباً",
            ],
        },
        "كحة": {
            "title": "🤧 معلومات عن الكحة",
            "content": "الكحة طريقة الجسم لتنظيف المجاري التنفسية.",
            "bullets": [
                "• الكحة الجافة: غالباً بسبب حساسية أو تهيج",
                "• الكحة المصحوبة ببلغم: قد تكون بسبب التهاب",
                "• العلاج: سوائل دافئة، عسل، استشارة طبيب",
            ],
        },
        "بروستات": {
            "title": "🫀 معلومات عن البروستاتا",
            "content": "البروستاتا غدة صغيرة بحجم حبة الجوز تقع أسفل المثانة أمام المستقيم، وتحيط بالإحليل (القناة التي تنقل البول والمني).",
            "bullets": [
                "• وظيفتها: إنتاج السائل المنوي الذي يغذي ويحمي الحيوانات المنوية",
                "• تضخم البروستاتا الحميد: صعوبة في التبول، كثرة التبول ليلاً، ضعف تدفق البول",
                "• التهاب البروستاتا: ألم في الحوض أو أسفل الظهر، ألم أثناء التبول، حمى",
                "• سرطان البروستاتا: قد لا تظهر أعراض مبكرة، وقد يسبب صعوبة في التبول أو وجود دم في البول",
                "• الفحوصات: تحليل PSA، الفحص الإكلينيكي، الأشعة فوق الصوتية",
                "• استشر طبيب مسالك بولية إذا كنت تعاني من أي أعراض",
            ],
        },
        "انيميا": {
            "title": "🩸 أعراض الأنيميا (فقر الدم)",
            "content": "الأنيميا هي نقص في عدد أو جودة كريات الدم الحمراء التي تحمل الأكسجين للجسم.",
            "bullets": [
                "• تعب وإرهاق عام وضعف في التركيز",
                "• شحوب الجلد والأغشية المخاطية",
                "• ضيق في التنفس وتسارع ضربات القلب",
                "• دوار أو صداع خصوصاً عند الوقوف",
                "• برودة الأطراف وتساقط الشعر",
            ],
        },
    }

    # البحث عن كلمة مفتاحية في السؤال
    for key, answer in answers.items():
        if key in q:
            return {
                "success": True,
                "source": "local",
                "title": answer["title"],
                "content": answer["content"],
                "bullets": answer["bullets"],
                "confidence": 0.9,
            }

    return None


# ============================================
# الاتصال بـ DeepSeek API (مع إعدادات SSL محسنة)
# ============================================
async def get_deepseek_answer(question: str) -> dict:
    """الحصول على إجابة من DeepSeek API مع إعدادات SSL محسنة"""

    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": "deepseek-chat",
        "messages": [
            {
                "role": "system",
                "content": """أنت مساعد صحي متخصص اسمه 'مساعدي الصحي'.
مهمتك الإجابة على الأسئلة الطبية بدقة وباللغة العربية.
استخدم لغة بسيطة ومفهومة.
لا تشخص أمراض جديدة.
لا تصف أدوية جديدة.
في الحالات الخطيرة، انصح بمراجعة الطبيب.

أجب بالتنسيق التالي بالضبط:
[العنوان]: عنوان مختصر للإجابة
[المحتوى]: إجابة مفصلة (2-3 جمل)
[النقاط]: اكتب كل نقطة في سطر منفصل تبدأ ب•""",
            },
            {"role": "user", "content": question},
        ],
        "temperature": 0.7,
        "max_tokens": 500,
    }

    try:
        import asyncio

        loop = asyncio.get_event_loop()

        # استخدام الجلسة مع إعدادات SSL محسنة
        response = await loop.run_in_executor(
            None,
            lambda: session.post(
                DEEPSEEK_API_URL,
                headers=headers,
                json=payload,
                timeout=30,
                verify=True,  # تأكد من التحقق من SSL
            ),
        )

        if response.status_code == 200:
            data = response.json()
            answer_text = data["choices"][0]["message"]["content"].strip()

            # تحليل النص
            lines = answer_text.split("\n")
            title = "إجابة طبية"
            content = answer_text
            bullets = []

            # محاولة استخراج العنوان والمحتوى والنقاط
            for line in lines:
                line = line.strip()
                if line.startswith("[العنوان]:"):
                    title = line.replace("[العنوان]:", "").strip()
                elif line.startswith("[المحتوى]:"):
                    content = line.replace("[المحتوى]:", "").strip()
                elif line.startswith(("•", "-", "*", "1.", "2.")):
                    bullets.append(line)

            # إذا لم نجد نقاطاً، نبحث عن أي أسطر تبدأ برموز
            if not bullets:
                for line in lines:
                    if line.strip().startswith(("•", "-", "*", "1.", "2.")):
                        bullets.append(line.strip())

            return {
                "success": True,
                "title": title,
                "content": content,
                "bullets": bullets[:10],
                "confidence": 0.95,
            }
        else:
            print(f"❌ خطأ من DeepSeek: {response.status_code}")
            if response.text:
                print(f"📄 التفاصيل: {response.text[:200]}")
            return None

    except requests.exceptions.SSLError as e:
        print(f"🔥 خطأ SSL: {e}")
        print("💡 نصيحة: جرب تحديث شهادة SSL أو استخدم VPN")
        return None
    except requests.exceptions.Timeout:
        print("🔥 مهلة الاتصال انتهت")
        return None
    except requests.exceptions.ConnectionError as e:
        print(f"🔥 خطأ في الاتصال: {e}")
        return None
    except Exception as e:
        print(f"🔥 خطأ غير متوقع: {e}")
        return None


# ============================================
# حفظ سؤال جديد في قاعدة البيانات
# ============================================
def save_question_to_db(db: Session, question: str, answer_data: dict, source: str):
    """حفظ سؤال وإجابته في قاعدة البيانات"""
    normalized = normalize_arabic_text(question)
    keywords = extract_keywords(question)

    # التحقق من عدم التكرار
    existing = (
        db.query(models.ChatQA)
        .filter(models.ChatQA.normalized_question == normalized)
        .first()
    )

    if existing:
        # زيادة عدد الاستخدامات
        existing.usage_count += 1
        db.commit()
        return existing

    # ✅ تنظيف النقاط قبل حفظها
    bullets_data = answer_data.get("bullets", [])
    if isinstance(bullets_data, list):
        # تنظيف كل نقطة
        cleaned_bullets = []
        for b in bullets_data:
            if isinstance(b, str):
                # إزالة الأحرف غير الصالحة لـ JSON
                b = b.encode("utf-8", "ignore").decode("utf-8")
                cleaned_bullets.append(b)
        bullets_json = json.dumps(cleaned_bullets, ensure_ascii=False)
    else:
        bullets_json = json.dumps([], ensure_ascii=False)

    # إنشاء سجل جديد
    qa = models.ChatQA(
        question=question[:500],
        normalized_question=normalized,
        answer=answer_data.get("content", "")[:2000],
        answer_title=answer_data.get("title", "")[:200],
        bullets=bullets_json,
        category="عام",
        keywords=json.dumps(keywords, ensure_ascii=False),
        confidence=answer_data.get("confidence", 0.7),
        source=source,
        usage_count=1,
    )
    db.add(qa)
    db.commit()
    db.refresh(qa)
    return qa


def safe_json_loads(data: str) -> list:
    """تحميل JSON بأمان مع معالجة الأخطاء"""
    if not data:
        return []
    try:
        result = json.loads(data)
        if isinstance(result, list):
            return result
        return []
    except (json.JSONDecodeError, TypeError):
        # إذا لم يكن JSON صالحاً، حاول استخراج النقاط
        bullets = []
        lines = str(data).split("\n")
        for line in lines:
            line = line.strip()
            if line and line.startswith(("•", "-", "*", "·")):
                bullets.append(line)
            elif line:
                bullets.append(f"• {line}")
        return bullets[:10]  # حد أقصى 10 نقاط


# ============================================
# API الرئيسي للشات (مع إجابات محلية)
# ============================================
# backend/routers/chat.py - أصلح دالة ask_question


@router.post("/ask", response_model=ChatResponse)
async def ask_question(request: ChatRequest, db: Session = Depends(get_db)):
    """الإجابة على سؤال (قاعدة بيانات ← DeepSeek ← محلي)"""
    print(f"💬 سؤال: {request.question}")

    # 1. البحث في قاعدة البيانات
    db_answer = search_in_database(db, request.question)

    if db_answer:
        db_answer.usage_count += 1
        db.commit()
        print(f"✅ تم العثور على إجابة في قاعدة البيانات (ID: {db_answer.id})")

        # ✅ معالجة bullets بشكل آمن
        bullets = []
        if db_answer.bullets:
            try:
                # محاولة تحويل JSON
                bullets = json.loads(db_answer.bullets)
                # التأكد من أنها قائمة
                if not isinstance(bullets, list):
                    bullets = []
            except (json.JSONDecodeError, TypeError) as e:
                print(f"⚠️ خطأ في تحويل bullets: {e}")
                # إذا كان النص يحتوي على نقاط مفصولة بسطور
                if isinstance(db_answer.bullets, str):
                    # محاولة تقسيم النص إلى نقاط
                    lines = db_answer.bullets.split("\n")
                    for line in lines:
                        line = line.strip()
                        if line.startswith(("•", "-", "*", "·")):
                            bullets.append(line)
                        elif line and not any(
                            b.startswith(("•", "-", "*", "·")) for b in bullets
                        ):
                            # إذا لم تكن هناك نقاط، نضيف السطر الأول كنقطة
                            bullets.append(f"• {line}")
                    if not bullets and db_answer.bullets.strip():
                        bullets = [f"• {db_answer.bullets[:200]}"]

        return ChatResponse(
            success=True,
            source="database",
            title=db_answer.answer_title or "إجابة",
            content=db_answer.answer or "معلومات طبية",
            bullets=bullets,
            confidence=db_answer.confidence,
            qa_id=db_answer.id,
        )

    # 2. البحث في الإجابات المحلية أولاً (أسرع)
    print("🔍 نبحث في الإجابات المحلية...")
    local_answer = get_local_answer(request.question)

    if local_answer:
        print(f"✅ تم العثور على إجابة محلية")
        # حفظ الإجابة المحلية في قاعدة البيانات للاستخدام المستقبلي
        saved = save_question_to_db(db, request.question, local_answer, "local")
        return ChatResponse(
            success=True,
            source="local",
            title=local_answer["title"],
            content=local_answer["content"],
            bullets=local_answer["bullets"],
            confidence=local_answer["confidence"],
            qa_id=saved.id,
        )

    # 3. استخدام DeepSeek
    print("🔍 لم نجد إجابة محلية، نستخدم DeepSeek...")
    deepseek_answer = await get_deepseek_answer(request.question)

    if deepseek_answer and deepseek_answer.get("success"):
        # حفظ الإجابة في قاعدة البيانات للاستخدام المستقبلي
        saved = save_question_to_db(db, request.question, deepseek_answer, "deepseek")
        print(f"✅ تم حفظ الإجابة في قاعدة البيانات (ID: {saved.id})")

        return ChatResponse(
            success=True,
            source="deepseek",
            title=deepseek_answer["title"],
            content=deepseek_answer["content"],
            bullets=deepseek_answer.get("bullets", []),
            confidence=deepseek_answer.get("confidence", 0.95),
            qa_id=saved.id,
        )

    # 4. فشل كل شيء
    print("❌ لم نتمكن من الحصول على إجابة")
    return ChatResponse(
        success=False,
        source="error",
        title="عذراً",
        content="لم أتمكن من الإجابة على سؤالك حالياً. يرجى المحاولة لاحقاً.",
        bullets=[],
        confidence=0.0,
        message="فشل في الحصول على إجابة",
    )


# ============================================
# تسجيل تقييم المستخدم
# ============================================
@router.post("/feedback")
def submit_feedback(feedback: FeedbackRequest, db: Session = Depends(get_db)):
    """تسجيل تقييم المستخدم للإجابة"""
    qa = db.query(models.ChatQA).filter(models.ChatQA.id == feedback.qa_id).first()
    if not qa:
        raise HTTPException(status_code=404, detail="السؤال غير موجود")

    if feedback.helpful:
        qa.helpful_count += 1
    else:
        qa.not_helpful_count += 1

    db.commit()

    return {"success": True, "message": "تم تسجيل التقييم"}


# ============================================
# إضافة سؤال يدوياً (للمحتوى الطبي)
# ============================================
@router.post("/add")
def add_question(qa: dict, db: Session = Depends(get_db)):
    """إضافة سؤال وإجابة يدوياً"""
    normalized = normalize_arabic_text(qa["question"])
    keywords = extract_keywords(qa["question"])

    new_qa = models.ChatQA(
        question=qa["question"][:500],
        normalized_question=normalized,
        answer=qa["answer"][:2000],
        answer_title=qa.get("title", "")[:200],
        bullets=json.dumps(qa.get("bullets", [])),
        category=qa.get("category", "عام"),
        keywords=json.dumps(keywords),
        confidence=qa.get("confidence", 1.0),
        source="manual",
    )
    db.add(new_qa)
    db.commit()
    db.refresh(new_qa)

    return new_qa.to_dict()
