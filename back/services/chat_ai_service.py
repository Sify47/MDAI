# backend/services/chat_ai_service.py

import json
import re
from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy.orm import Session
import models


class ChatAIService:
    """خدمة متقدمة للمساعد الذكي"""

    # قاعدة المعرفة الموسعة
    MEDICAL_KNOWLEDGE = {
        "الأمراض": {
            "السكري": {
                "description": "مرض مزمن يرتفع فيه مستوى السكر في الدم",
                "symptoms": [
                    "عطش شديد",
                    "كثرة التبول",
                    "جوع مستمر",
                    "تعب وإرهاق",
                    "زغللة في العين",
                ],
                "risk_factors": [
                    "السمنة",
                    "قلة الحركة",
                    "تاريخ عائلي",
                    "ارتفاع الضغط",
                    "ارتفاع الكوليسترول",
                ],
                "treatment": [
                    "مراقبة السكر",
                    "نظام غذائي",
                    "رياضة",
                    "أدوية",
                    "أنسولين عند الحاجة",
                ],
                "prevention": ["الحفاظ على وزن صحي", "رياضة منتظمة", "غذاء متوازن"],
            },
            "ضغط الدم": {
                "description": "ارتفاع قوة دفع الدم ضد جدران الشرايين",
                "symptoms": ["عادة لا تظهر أعراض", "صداع شديد", "ضيق تنفس", "نزيف أنف"],
                "risk_factors": [
                    "التدخين",
                    "السمنة",
                    "قلة النشاط",
                    "الملح الزائد",
                    "الكحول",
                ],
                "treatment": [
                    "تقليل الملح",
                    "رياضة",
                    "أدوية ضغط",
                    "الإقلاع عن التدخين",
                ],
                "prevention": ["غذاء صحي", "رياضة 30 دقيقة يومياً", "فحص دوري"],
            },
        },
        "الأعراض_الشائعة": {
            "صداع": {
                "causes": ["إجهاد", "جفاف", "قلة نوم", "إجهاد عين", "ضغط دم"],
                "home_remedies": ["راحة", "كمادات باردة", "شرب ماء", "مسكنات خفيفة"],
                "warning_signs": [
                    "صداع مفاجئ شديد",
                    "مع حرارة",
                    "مع تيبس رقبة",
                    "مع زغللة",
                ],
            },
            "ألم بطن": {
                "causes": ["عسر هضم", "إمساك", "غازات", "التهاب المعدة", "قولون عصبي"],
                "home_remedies": ["ماء دافئ", "نعناع", "تجنب الدسم", "راحة"],
                "warning_signs": ["ألم شديد", "دم في البراز", "حرارة", "قيء مستمر"],
            },
        },
        "الأدوية_الشائعة": {
            "باراسيتامول": {
                "uses": ["مسكن للألم", "خافض للحرارة"],
                "dosage": "500 مجم كل 4-6 ساعات",
                "max_daily": "4000 مجم",
                "warnings": ["لا تتجاوز الجرعة", "قد يسبب تسمم كبدي"],
            },
            "إيبوبروفين": {
                "uses": ["مسكن", "مضاد التهاب", "خافض حرارة"],
                "dosage": "200-400 مجم كل 6-8 ساعات",
                "max_daily": "1200 مجم",
                "warnings": ["مع الطعام", "تجنب إن كنت تعاني من قرحة"],
            },
        },
    }

    @staticmethod
    def get_intelligent_response(
        question: str, db: Session, user_id: Optional[int] = None
    ) -> Dict:
        """الحصول على رد ذكي للمستخدم"""

        question_lower = question.lower()

        # 1. البحث في قاعدة المعرفة
        knowledge_response = ChatAIService._search_knowledge_base(question_lower)
        if knowledge_response:
            return knowledge_response

        # 2. البحث في قاعدة البيانات (الأسئلة السابقة)
        db_response = ChatAIService._search_database(db, question)
        if db_response:
            return db_response

        # 3. تحليل الأعراض (إذا كان السؤال عن أعراض)
        if any(
            word in question_lower
            for word in ["أعراض", "عندي", "أعاني", "شعور", "ألم", "حرارة"]
        ):
            symptom_response = ChatAIService._analyze_symptoms(question)
            if symptom_response:
                return symptom_response

        # 4. إذا كان السؤال عن دواء
        if any(
            word in question_lower
            for word in ["دواء", "علاج", "حبوب", "كapsule", "أقراص"]
        ):
            medication_response = ChatAIService._get_medication_info(question)
            if medication_response:
                return medication_response

        # 5. رد عام ذكي
        return ChatAIService._get_general_response(question)

    @staticmethod
    def _search_knowledge_base(question: str) -> Optional[Dict]:
        """البحث في قاعدة المعرفة"""

        # البحث عن الأمراض
        for disease, info in ChatAIService.MEDICAL_KNOWLEDGE["الأمراض"].items():
            if disease in question:
                return {
                    "success": True,
                    "source": "knowledge_base",
                    "title": f"🩺 معلومات عن {disease}",
                    "content": info["description"],
                    "bullets": [
                        f"• الأعراض: {', '.join(info['symptoms'][:4])}",
                        f"• عوامل الخطر: {', '.join(info['risk_factors'][:4])}",
                        f"• العلاج: {', '.join(info['treatment'][:4])}",
                        f"• الوقاية: {', '.join(info['prevention'][:3])}",
                    ],
                    "confidence": 0.95,
                }

        # البحث عن الأعراض
        for symptom, info in ChatAIService.MEDICAL_KNOWLEDGE["الأعراض_الشائعة"].items():
            if symptom in question:
                return {
                    "success": True,
                    "source": "knowledge_base",
                    "title": f"🤕 معلومات عن {symptom}",
                    "content": f"نصائح للتعامل مع {symptom}",
                    "bullets": [
                        f"• الأسباب المحتملة: {', '.join(info['causes'][:4])}",
                        f"• علاج منزلي: {', '.join(info['home_remedies'][:3])}",
                        f"• علامات خطورة: {', '.join(info['warning_signs'][:3])}",
                    ],
                    "confidence": 0.9,
                }

        # البحث عن الأدوية
        for med, info in ChatAIService.MEDICAL_KNOWLEDGE["الأدوية_الشائعة"].items():
            if med in question:
                return {
                    "success": True,
                    "source": "knowledge_base",
                    "title": f"💊 معلومات عن {med}",
                    "content": f"الاستخدامات: {info['uses'][0]}",
                    "bullets": [
                        f"• الجرعة: {info['dosage']}",
                        f"• الحد الأقصى اليومي: {info['max_daily']}",
                        f"• تحذيرات: {info['warnings'][0]}",
                    ],
                    "confidence": 0.95,
                }

        return None

    @staticmethod
    def _search_database(db: Session, question: str) -> Optional[Dict]:
        """البحث في قاعدة البيانات"""

        # البحث عن سؤال مشابه
        qa = (
            db.query(models.ChatQA)
            .filter(models.ChatQA.question.contains(question[:50]))
            .order_by(models.ChatQA.usage_count.desc())
            .first()
        )

        if qa:
            return {
                "success": True,
                "source": "database",
                "title": qa.answer_title or "إجابة",
                "content": qa.answer,
                "bullets": json.loads(qa.bullets) if qa.bullets else [],
                "confidence": qa.confidence,
                "qa_id": qa.id,
            }

        return None

    @staticmethod
    def _analyze_symptoms(question: str) -> Optional[Dict]:
        """تحليل الأعراض المذكورة في السؤال"""

        # قائمة الأعراض الشائعة
        common_symptoms = {
            "صداع": {"severity": "متوسط", "suggestion": "خذ قسطاً من الراحة واشرب ماء"},
            "دوخة": {"severity": "متوسط", "suggestion": "اجلس فوراً واشرب ماء"},
            "غثيان": {
                "severity": "خفيف",
                "suggestion": "تناول وجبات خفيفة وتجنب الدهون",
            },
            "حرارة": {
                "severity": "متوسط",
                "suggestion": "اشرب سوائل واستخدم خافض حرارة",
            },
            "ألم بطن": {
                "severity": "متوسط",
                "suggestion": "تجنب الأطعمة الدسمة واشرب ينسون",
            },
            "ضيق تنفس": {"severity": "شديد", "suggestion": "🚨 استشر طبيباً فوراً"},
            "ألم صدر": {"severity": "شديد", "suggestion": "🚨 اتصل بالطوارئ فوراً"},
        }

        found_symptoms = []
        for symptom, info in common_symptoms.items():
            if symptom in question:
                found_symptoms.append({"name": symptom, **info})

        if found_symptoms:
            bullets = []
            for s in found_symptoms:
                bullets.append(f"• {s['name']}: {s['suggestion']}")

            severe = any(s["severity"] == "شديد" for s in found_symptoms)

            return {
                "success": True,
                "source": "ai_analysis",
                "title": "🔍 تحليل الأعراض",
                "content": "بناءً على الأعراض التي ذكرتها:",
                "bullets": bullets,
                "confidence": 0.85,
                "metadata": {"severe": severe},
            }

        return None

    @staticmethod
    def _get_medication_info(question: str) -> Optional[Dict]:
        """الحصول على معلومات عن دواء"""

        # استخراج اسم الدواء من السؤال
        import re

        patterns = [
            r"(?:دواء|علاج|حبوب|أقراص|كapsule)\s+([\u0600-\u06FF\s]+)",
            r"([\u0600-\u06FF\s]+)\s+(?:دواء|علاج|حبوب)",
        ]

        for pattern in patterns:
            match = re.search(pattern, question)
            if match:
                med_name = match.group(1).strip()
                return {
                    "success": True,
                    "source": "ai_analysis",
                    "title": f"💊 معلومات عن {med_name}",
                    "content": f"للدواء {med_name} استخدامات متعددة حسب وصف الطبيب",
                    "bullets": [
                        "• يجب استشارة الطبيب قبل الاستخدام",
                        "• التزم بالجرعة الموصوفة",
                        "• لا تتوقف عن الدواء دون استشارة طبية",
                        "• أبلغ طبيبك عن أي آثار جانبية",
                    ],
                    "confidence": 0.8,
                }

        return None

    @staticmethod
    def _get_general_response(question: str) -> Dict:
        """رد عام ذكي"""

        # تحليل نية السؤال
        intent = ChatAIService._classify_intent(question)

        responses = {
            "greeting": {
                "title": "👋 مرحباً بك",
                "content": "أنا مساعدك الصحي الذكي. كيف يمكنني مساعدتك اليوم؟",
                "bullets": [
                    "• اسأل عن أي عرض صحي",
                    "• استفسر عن دواء معين",
                    "• تعرف على أمراض شائعة",
                    "• احصل على نصائح صحية",
                ],
            },
            "thanks": {
                "title": "🙏 عفواً",
                "content": "سعيد بمساعدتك! هل تريد استفساراً آخر؟",
                "bullets": [],
            },
            "farewell": {
                "title": "👋 إلى اللقاء",
                "content": "أتمنى لك دوام الصحة والعافية. عد في أي وقت",
                "bullets": [],
            },
            "unknown": {
                "title": "💡 كيف يمكنني مساعدتك؟",
                "content": "يمكنك سؤالي عن:",
                "bullets": [
                    "• أعراض الأمراض الشائعة",
                    "• معلومات عن الأدوية",
                    "• نصائح صحية عامة",
                    "• تفسير نتائج التحاليل",
                ],
            },
        }

        if any(word in question for word in ["مرحب", "هلا", "السلام", "صباح", "مساء"]):
            intent = "greeting"
        elif any(word in question for word in ["شكر", "جزاك", "مشكور"]):
            intent = "thanks"
        elif any(word in question for word in ["مع السلامة", "باي", "وداعا", "سلام"]):
            intent = "farewell"
        else:
            intent = "unknown"

        resp = responses.get(intent, responses["unknown"])

        return {
            "success": True,
            "source": "ai_assistant",
            "title": resp["title"],
            "content": resp["content"],
            "bullets": resp["bullets"],
            "confidence": 0.7,
        }

    @staticmethod
    def _classify_intent(question: str) -> str:
        """تصنيف نية السؤال"""

        if any(word in question for word in ["أعراض", "أعاني", "شعور", "ألم"]):
            return "symptoms"
        elif any(word in question for word in ["دواء", "علاج", "حبوب"]):
            return "medication"
        elif any(word in question for word in ["مرض", "حالة", "مرض"]):
            return "disease"
        elif any(word in question for word in ["نصيحة", "طريقة", "كيف"]):
            return "advice"
        else:
            return "general"
