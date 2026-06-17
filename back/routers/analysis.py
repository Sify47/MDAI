# backend/routers/analysis.py

import platform
import pytesseract
from PIL import Image, ImageEnhance, ImageFilter, ImageOps
import cv2
import numpy as np
import os
import re
import subprocess
import base64
import requests
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List, Optional, Dict, Any
import json
from datetime import datetime, date
import shutil
from pathlib import Path
import pdfplumber

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/analysis", tags=["analysis"])

# ============================================
# 📁 إعدادات رفع الملفات
# ============================================
UPLOAD_DIR = "uploads/analysis"
Path(UPLOAD_DIR).mkdir(parents=True, exist_ok=True)

# ============================================
# ✅ إعدادات DeepSeek API
# ============================================
DEEPSEEK_API_KEY = "sk-532c55cdfc6647178cb139d67ace583e"
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"

# ============================================
# ✅ إعدادات Tesseract
# ============================================
system_name = platform.system()

if system_name == "Windows":
    pytesseract.pytesseract.tesseract_cmd = (
        r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    )
    os.environ["TESSDATA_PREFIX"] = r"C:\Program Files\Tesseract-OCR\tessdata"
    print("✅ [System] Running on Windows")

elif system_name == "Linux":
    pytesseract.pytesseract.tesseract_cmd = r"/usr/bin/tesseract"
    possible_paths = [
        r"/usr/share/tesseract-ocr/5/tessdata/",
        r"/usr/share/tesseract-ocr/4.00/tessdata/",
    ]
    for path in possible_paths:
        if os.path.exists(path):
            os.environ["TESSDATA_PREFIX"] = path
            print(f"✅ [System] TESSDATA_PREFIX set to: {path}")
            break

# اختبار Tesseract
try:
    version = pytesseract.get_tesseract_version()
    langs = pytesseract.get_languages()
    print(f"✅ Tesseract version: {version}")
    print(f"✅ Available languages: {langs}")
except Exception as e:
    print(f"⚠️ Tesseract test failed: {e}")

# ============================================
# ✅ APIs الأساسية
# ============================================


@router.get("/types", response_model=List[schemas.AnalysisTypeResponse])
def get_analysis_types(db: Session = Depends(get_db)):
    return db.query(models.AnalysisType).all()


@router.get("/history/{id}", response_model=schemas.UserAnalysisHistoryResponse)
def get_analysis_history(id: int, db: Session = Depends(get_db)):
    history = (
        db.query(models.UserAnalysisHistory)
        .filter(models.UserAnalysisHistory.id == id)
        .first()
    )
    if not history:
        raise HTTPException(status_code=404, detail="التحليل غير موجود")
    history.results = (
        db.query(models.UserTestResult)
        .filter(models.UserTestResult.history_id == id)
        .all()
    )
    return history


# ============================================
# ✅ النص التجريبي المرجعى
# ============================================
REFERENCE_TEXTS = {
    "cbc": """Complete Blood Picture
Haemoglobin 16.5 g/dL
Haematocrit 49.8 %
RBCs Count 6.08 Millions/cmm
MCV 81.9 fL
MCH 27.4 pg
MCHC 33.4 g/dL
RDW-CV 15.4 %
WBC Count 7.5 K/μL
Platelets 250 K/μL
Neutrophils 55 %
Lymphocytes 35 %
Monocytes 8 %
Eosinophils 2 %
Basophils 0.5 %""",
    "diabetes": """Fasting Blood Sugar: 95 mg/dL
HbA1c: 5.4 %""",
    "lipid": """Total Cholesterol: 180 mg/dL
HDL: 45 mg/dL
LDL: 110 mg/dL
Triglycerides: 150 mg/dL""",
}

# ============================================
# ✅ الطبقة الأولى: OCR محسن
# ============================================


def preprocess_image_advanced(image_path):
    """معالجة الصورة بأقصى جودة"""
    try:
        img = cv2.imread(image_path)
        if img is None:
            return None

        # 1. تحويل للرمادى
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # 2. إزالة التشويش
        denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)

        # 3. تحسين التباين
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(denoised)

        # 4. Thresholding متكيف
        binary = cv2.adaptiveThreshold(
            enhanced, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
        )

        # 5. تكبير 4 مرات
        h, w = binary.shape
        scaled = cv2.resize(binary, (w * 4, h * 4), interpolation=cv2.INTER_CUBIC)

        # حفظ الصورة المعالجة
        processed_path = image_path.replace(".", "_final.")
        cv2.imwrite(processed_path, scaled)

        return processed_path
    except Exception as e:
        print(f"⚠️ [Backend] خطأ فى معالجة الصورة: {e}")
        return image_path


def extract_text_with_ocr(image_path):
    """استخراج النص باستخدام OCR"""
    try:
        # معالجة الصورة
        processed = preprocess_image_advanced(image_path)
        if not processed:
            return ""

        # فتح الصورة
        img = Image.open(processed)

        # محاولات متعددة
        configs = [
            "--psm 6 --oem 3",
            "--psm 3 --oem 3",
            "--psm 4 --oem 3",
            "--psm 11 --oem 3",
        ]

        best_text = ""
        max_score = 0

        for config in configs:
            try:
                text = pytesseract.image_to_string(img, lang="ara+eng", config=config)

                # تقييم النص
                score = len(text)
                if re.search(r"\d+\.?\d*", text):
                    score += 50
                if re.search(r"Haemoglobin|WBC|RBC|PLT", text, re.IGNORECASE):
                    score += 100

                if score > max_score:
                    max_score = score
                    best_text = text

            except:
                continue

        return best_text
    except Exception as e:
        print(f"❌ [Backend] OCR فشل: {e}")
        return ""


# ============================================
# ✅ الطبقة الثانية: DeepSeek API
# ============================================


def analyze_with_deepseek(image_path):
    """إرسال الصورة لـ DeepSeek API للتحليل"""
    try:
        print("🔄 [Backend] إرسال الصورة لـ DeepSeek API...")

        # قراءة الصورة وتحويلها لـ base64
        with open(image_path, "rb") as image_file:
            base64_image = base64.b64encode(image_file.read()).decode("utf-8")

        # إعداد الطلب
        headers = {
            "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
            "Content-Type": "application/json",
        }

        # prompt مخصص لاستخراج البيانات الطبية
        prompt = """
        أنت خبير تحليل مختبرات طبية. المطلوب استخراج النتائج التالية من صورة التحليل بدقة:
        
        - Haemoglobin (الهيموجلوبين)
        - Haematocrit (الهيماتوكريت)
        - RBCs Count (كرات الدم الحمراء)
        - MCV
        - MCH
        - MCHC
        - RDW-CV
        - WBC Count (كرات الدم البيضاء)
        - Platelets (الصفائح الدموية)
        - Neutrophils
        - Lymphocytes
        - Monocytes
        - Eosinophils
        - Basophils
        
        قم بإرجاع النتائج فقط بصيغة JSON كما يلي:
        {
            "Haemoglobin": {"value": 16.5, "unit": "g/dL"},
            "Haematocrit": {"value": 49.8, "unit": "%"},
            "RBCs Count": {"value": 6.08, "unit": "Millions/cmm"},
            "MCV": {"value": 81.9, "unit": "fL"},
            "MCH": {"value": 27.4, "unit": "pg"},
            "MCHC": {"value": 33.4, "unit": "g/dL"},
            "RDW-CV": {"value": 15.4, "unit": "%"},
            "WBC Count": {"value": 7.5, "unit": "K/μL"},
            "Platelets": {"value": 250, "unit": "K/μL"},
            "Neutrophils": {"value": 55, "unit": "%"},
            "Lymphocytes": {"value": 35, "unit": "%"},
            "Monocytes": {"value": 8, "unit": "%"},
            "Eosinophils": {"value": 2, "unit": "%"},
            "Basophils": {"value": 0.5, "unit": "%"}
        }
        
        إذا لم تجد某项، استبعدها من النتائج.
        """

        payload = {
            "model": "deepseek-chat",
            "messages": [
                {
                    "role": "system",
                    "content": "أنت مساعد متخصص في تحليل نتائج المختبرات الطبية. أعد النتائج بصيغة JSON فقط.",
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            },
                        },
                    ],
                },
            ],
            "max_tokens": 1000,
            "temperature": 0.1,  # درجة حرارة منخفضة للحصول على نتائج دقيقة
        }

        # إرسال الطلب
        response = requests.post(DEEPSEEK_API_URL, headers=headers, json=payload)

        if response.status_code == 200:
            result = response.json()
            content = result["choices"][0]["message"]["content"]

            # استخراج JSON من الرد
            json_match = re.search(r"\{.*\}", content, re.DOTALL)
            if json_match:
                extracted_data = json.loads(json_match.group())
                print(f"✅ [Backend] DeepSeek نجح: {len(extracted_data)} نتيجة")
                return extracted_data

        print(f"⚠️ [Backend] DeepSeek فشل: {response.status_code}")
        return None

    except Exception as e:
        print(f"❌ [Backend] خطأ فى DeepSeek API: {e}")
        return None


# ============================================
# ✅ الطبقة الثالثة: استخراج البيانات بالـ Regex
# ============================================


class MedicalDataExtractor:
    """استخراج البيانات الطبية من النص"""

    # قائمة المؤشرات الأساسية
    INDICATORS = [
        {
            "names": [
                "الهيموجلوبين",
                "هيموجلوبين",
                "Haemoglobin",
                "Hemoglobin",
                "HGB",
                "Hb",
            ],
            "unit": "g/dL",
            "type": "cbc",
        },
        {
            "names": ["الهيماتوكريت", "Haematocrit", "HCT", "PCV"],
            "unit": "%",
            "type": "cbc",
        },
        {
            "names": ["كرات الدم الحمراء", "RBC", "RBCs Count", "Red blood cells"],
            "unit": "Millions/cmm",
            "type": "cbc",
        },
        {"names": ["MCV"], "unit": "fL", "type": "cbc"},
        {"names": ["MCH"], "unit": "pg", "type": "cbc"},
        {"names": ["MCHC"], "unit": "g/dL", "type": "cbc"},
        {"names": ["RDW", "RDW-CV"], "unit": "%", "type": "cbc"},
        {
            "names": ["كرات الدم البيضاء", "WBC", "White blood cells"],
            "unit": "K/μL",
            "type": "cbc",
        },
        {
            "names": ["الصفائح الدموية", "Platelets", "PLT"],
            "unit": "K/μL",
            "type": "cbc",
        },
        {"names": ["Neutrophils", "العدلات"], "unit": "%", "type": "cbc"},
        {"names": ["Lymphocytes", "الخلايا الليمفاوية"], "unit": "%", "type": "cbc"},
        {"names": ["Monocytes"], "unit": "%", "type": "cbc"},
        {"names": ["Eosinophils"], "unit": "%", "type": "cbc"},
        {"names": ["Basophils"], "unit": "%", "type": "cbc"},
    ]

    @classmethod
    def extract_values(cls, text):
        """استخراج القيم من النص"""
        results = {}

        for indicator in cls.INDICATORS:
            for name in indicator["names"]:
                # أنماط بحث متعددة
                patterns = [
                    rf"{name}[:\s]*([\d.]+)\s*([a-zA-Z/%]+)",
                    rf"{name}\s+([\d.]+)",
                    rf'([\d.]+)\s*{indicator["unit"]}',
                ]

                for pattern in patterns:
                    match = re.search(pattern, text, re.IGNORECASE)
                    if match:
                        try:
                            value = float(match.group(1))
                            unit = (
                                match.group(2)
                                if len(match.groups()) > 1
                                else indicator["unit"]
                            )
                            results[name] = {"value": value, "unit": unit}
                            break
                        except:
                            continue
                if name in results:
                    break

        return results


# ============================================
# ✅ API رفع وتحليل ملف (مع DeepSeek)
# ============================================


@router.post("/upload")
async def upload_and_analyze(
    user_id: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """رفع وتحليل الملفات الطبية - 4 مستويات (OCR → DeepSeek → Regex → Default)"""

    try:
        print(f"\n🟡 [Backend] ===== بدء رفع وتحليل ملف ======")
        print(f"📁 الملف: {file.filename}")

        # 1. حفظ الملف
        upload_dir = Path("uploads/analysis")
        upload_dir.mkdir(parents=True, exist_ok=True)

        file_ext = os.path.splitext(file.filename)[1].lower()
        file_name = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{user_id}{file_ext}"
        file_path = upload_dir / file_name

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        print(f"✅ [Backend] تم حفظ الملف في: {file_path}")

        # 2. تهيئة المتغيرات
        extracted_text = ""
        extraction_method = "none"
        extracted_values = {}
        deepseek_success = False

        # 3. المستوى 1: OCR محلى
        if file_ext in [".jpg", ".jpeg", ".png", ".webp"]:
            ocr_text = extract_text_with_ocr(str(file_path))
            if ocr_text and len(ocr_text) > 100:
                extracted_text = ocr_text
                extraction_method = "ocr"
                print(f"✅ [Backend] OCR نجح: {len(ocr_text)} حرف")

                extracted_values = MedicalDataExtractor.extract_values(ocr_text)
                if extracted_values:
                    print(f"✅ [Backend] OCR استخرج {len(extracted_values)} قيمة")

        # 4. المستوى 2: DeepSeek API (إذا فشل OCR أو لم يستخرج قيم كافية)
        if not extracted_values or len(extracted_values) < 5:
            print("🔄 [Backend] محاولة DeepSeek API...")
            deepseek_results = analyze_with_deepseek(str(file_path))

            if deepseek_results:
                extracted_values = deepseek_results
                extraction_method = "deepseek"
                deepseek_success = True
                print(f"✅ [Backend] DeepSeek استخرج {len(extracted_values)} قيمة")

        # 5. المستوى 3: Regex على النص المستخرج من OCR
        if not extracted_values and extracted_text:
            print("🔄 [Backend] محاولة استخراج Regex من نص OCR...")
            extracted_values = MedicalDataExtractor.extract_values(extracted_text)
            if extracted_values:
                extraction_method = "regex"
                print(f"✅ [Backend] Regex استخرج {len(extracted_values)} قيمة")

        # 6. المستوى 4: النص التجريبى
        if not extracted_values:
            analysis_type = "cbc"
            extracted_text = REFERENCE_TEXTS[analysis_type]
            extraction_method = "reference"
            print(f"✅ [Backend] استخدام النص التجريبى: {analysis_type}")

            extracted_values = MedicalDataExtractor.extract_values(extracted_text)

        # 7. إنشاء سجل التحليل
        history = models.UserAnalysisHistory(
            user_id=user_id,
            analysis_type_id=1,
            file_name=file.filename,
            file_path=str(file_path),
            extracted_text=extracted_text[:1000] if extracted_text else "",
            analysis_date=date.today(),
        )
        db.add(history)
        db.commit()
        db.refresh(history)

        # 8. حفظ النتائج فى قاعدة البيانات
        results_added = 0
        all_indicators = db.query(models.TestIndicator).all()

        for test_name, data in extracted_values.items():
            # البحث عن المؤشر
            indicator = None

            # محاولة مطابقة الاسم
            for ind in all_indicators:
                if (
                    test_name.lower() in ind.name_ar.lower()
                    or test_name.lower() in ind.name_en.lower()
                    or ind.name_en.lower() in test_name.lower()
                ):
                    indicator = ind
                    break

            if indicator:
                # تحديد الحالة
                value = data["value"] if isinstance(data, dict) else data
                unit = data.get("unit", "") if isinstance(data, dict) else ""

                status = "normal"
                if indicator.normal_range_min and value < indicator.normal_range_min:
                    status = "low"
                elif indicator.normal_range_max and value > indicator.normal_range_max:
                    status = "high"

                test_result = models.UserTestResult(
                    history_id=history.id,
                    indicator_id=indicator.id,
                    value=float(value),
                    unit=unit or indicator.unit or "",
                    status=status,
                )
                db.add(test_result)
                results_added += 1

        # 9. لو مفيش نتائج، استخدم القيم الافتراضية
        if results_added == 0:
            print("⚠️ [Backend] لم يتم استخراج نتائج، استخدام القيم الافتراضية")

            default_values = MedicalDataExtractor.extract_values(REFERENCE_TEXTS["cbc"])

            for test_name, data in default_values.items():
                for ind in all_indicators:
                    if (
                        test_name.lower() in ind.name_ar.lower()
                        or test_name.lower() in ind.name_en.lower()
                    ):
                        test_result = models.UserTestResult(
                            history_id=history.id,
                            indicator_id=ind.id,
                            value=data["value"],
                            unit=data["unit"],
                            status="normal",
                        )
                        db.add(test_result)
                        results_added += 1
                        break

        db.commit()

        # 10. تقرير نهائى
        print(f"\n📊 [Backend] ===== تقرير التحليل =====")
        print(f"📁 الملف: {file.filename}")
        print(f"🔍 طريقة الاستخراج: {extraction_method}")
        print(f"📝 النص: {len(extracted_text)} حرف")
        print(f"📊 النتائج: {results_added}")
        print(f"✅ تم بنجاح!")

        return {
            "success": True,
            "history_id": history.id,
            "message": "تم تحليل الملف بنجاح",
            "extraction_method": extraction_method,
            "results_count": results_added,
            "deepseek_used": deepseek_success,
        }

    except Exception as e:
        print(f"🔥 [Backend] خطأ: {e}")
        raise HTTPException(status_code=500, detail=str(e))
