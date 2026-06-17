# back/services/fcm_service.py
"""خدمة FCM لإرسال الإشعارات الذكية عبر Firebase Cloud Messaging"""

import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime

import requests
from sqlalchemy.orm import Session

import models

logger = logging.getLogger(__name__)

# ════════════════════════════════════════════
# 🔧 الإعدادات من Firebase Console
# ════════════════════════════════════════════
# للحصول على Server Key:
#   1. اذهب إلى Firebase Console → Project Settings → Cloud Messaging
#   2. تحت Web Push certificates، ستجد "Server key" (أو "Cloud Messaging API (Legacy)")
#   3. انسخها وضعها في ملف .env كـ FCM_SERVER_KEY
#
# ملاحظة: الطريقة الأحدث تستخدم OAuth 2.0 مع Service Account JSON
# لكن الطريقة الأسهل هي استخدام Server Key
# ════════════════════════════════════════════

FCM_SERVER_KEY = None  # سيتم تحميله من .env
FCM_API_URL = "https://fcm.googleapis.com/fcm/send"

# Headers ثابتة لإرسال FCM
def _get_headers() -> Dict[str, str]:
    """إرجاع headers المطلوبة لإرسال FCM"""
    global FCM_SERVER_KEY
    
    if FCM_SERVER_KEY is None:
        import os
        from dotenv import load_dotenv
        load_dotenv()
        FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")
    
    return {
        "Authorization": f"key={FCM_SERVER_KEY}",
        "Content-Type": "application/json",
    }


def send_notification(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
    click_action: str = "FLUTTER_NOTIFICATION_CLICK",
) -> bool:
    """إرسال إشعار FCM لجهاز واحد
    
    Args:
        token: FCM token الخاص بالجهاز
        title: عنوان الإشعار
        body: نص الإشعار
        data: بيانات إضافية (تُرسل كـ data payload)
        click_action: الإجراء عند النقر على الإشعار
    
    Returns:
        bool: نجاح أو فشل الإرسال
    """
    if not FCM_SERVER_KEY:
        logger.warning("⚠️ FCM_SERVER_KEY غير مضبوط في .env")
        return False
    
    if not token:
        logger.warning("⚠️ FCM token فارغ")
        return False
    
    payload: Dict[str, Any] = {
        "to": token,
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
            "click_action": click_action,
        },
        "data": data or {},
        "priority": "high",
    }
    
    try:
        response = requests.post(
            FCM_API_URL,
            json=payload,
            headers=_get_headers(),
            timeout=10,
        )
        
        result = response.json()
        
        if response.status_code == 200:
            if result.get("success") == 1:
                logger.info(
                    f"✅ FCM أُرسل بنجاح: {title} | message_id: {result.get('message_id')}"
                )
                return True
            elif result.get("failure") == 1:
                error = result.get("results", [{}])[0].get("error", "unknown")
                logger.error(f"❌ فشل إرسال FCM: {error}")
                
                # إذا كان الـ token غير صالح، نحذفه
                if error in ("InvalidRegistration", "NotRegistered", "MismatchSenderId"):
                    _handle_invalid_token(token)
                return False
        else:
            logger.error(
                f"❌ FCM خطأ HTTP {response.status_code}: {response.text}"
            )
            return False
    
    except requests.exceptions.Timeout:
        logger.error("❌ FCM انتهت المهلة")
        return False
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ FCM خطأ في الاتصال: {e}")
        return False
    except json.JSONDecodeError as e:
        logger.error(f"❌ FCM خطأ في تحليل الرد: {e}")
        return False


def send_notification_to_user(
    db: Session,
    user_id: int,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> bool:
    """إرسال إشعار FCM لمستخدم معين (يبحث عن توكنه في قاعدة البيانات)
    
    Args:
        db: جلسة قاعدة البيانات
        user_id: معرف المستخدم
        title: عنوان الإشعار
        body: نص الإشعار
        data: بيانات إضافية (اختياري)
    
    Returns:
        bool: نجاح أو فشل
    """
    # البحث عن المستخدم
    user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if not user:
        logger.warning(f"⚠️ المستخدم {user_id} غير موجود")
        return False
    
    if not user.fcm_token:
        logger.info(
            f"ℹ️ المستخدم {user_id} ليس لديه FCM token (لم يسجل الدخول للتطبيق بعد)"
        )
        return False
    
    logger.info(f"📨 إرسال FCM للمستخدم {user_id}: {title}")
    
    # إرسال الإشعار
    success = send_notification(
        token=user.fcm_token,
        title=title,
        body=body,
        data=data,
    )
    
    if success:
        logger.info(f"✅ تم إرسال FCM للمستخدم {user_id}")
    else:
        logger.error(f"❌ فشل إرسال FCM للمستخدم {user_id}")
    
    return success


def send_notification_to_multi(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> Dict[str, int]:
    """إرسال إشعار FCM لعدة أجهزة (الحد الأقصى 1000 لكل دفعة)
    
    Args:
        tokens: قائمة FCM tokens
        title: عنوان الإشعار
        body: نص الإشعار
        data: بيانات إضافية (اختياري)
    
    Returns:
        dict: إحصائيات الإرسال {success, failure, invalid_tokens}
    """
    if not FCM_SERVER_KEY:
        logger.warning("⚠️ FCM_SERVER_KEY غير مضبوط في .env")
        return {"success": 0, "failure": 0, "invalid_tokens": 0}
    
    if not tokens:
        return {"success": 0, "failure": 0, "invalid_tokens": 0}
    
    payload: Dict[str, Any] = {
        "registration_ids": tokens,
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
        },
        "data": data or {},
        "priority": "high",
    }
    
    try:
        response = requests.post(
            FCM_API_URL,
            json=payload,
            headers=_get_headers(),
            timeout=15,
        )
        
        result = response.json()
        
        if response.status_code == 200:
            stats = {
                "success": result.get("success", 0),
                "failure": result.get("failure", 0),
                "invalid_tokens": 0,
            }
            
            # معالجة الـ results لكل token
            results_list = result.get("results", [])
            for i, res in enumerate(results_list):
                error = res.get("error")
                if error in ("InvalidRegistration", "NotRegistered", "InvalidToken"):
                    stats["invalid_tokens"] += 1
                    _handle_invalid_token(tokens[i])
            
            logger.info(
                f"✅ FCM متعدد: نجاح {stats['success']} فشل {stats['failure']} "
                f"غير صالح {stats['invalid_tokens']}"
            )
            return stats
        else:
            logger.error(f"❌ FCM متعدد خطأ HTTP {response.status_code}: {response.text}")
            return {"success": 0, "failure": len(tokens), "invalid_tokens": 0}
    
    except Exception as e:
        logger.error(f"❌ FCM متعدد خطأ: {e}")
        return {"success": 0, "failure": len(tokens), "invalid_tokens": 0}


def _handle_invalid_token(token: str):
    """معالجة token غير صالح - سيتم حذفه في المرة القادمة"""
    logger.warning(f"⚠️ FCM token غير صالح: {token[:50]}...")
    
    try:
        from database import SessionLocal
        db = SessionLocal()
        try:
            user = db.query(models.User).filter(models.User.fcm_token == token).first()
            if user:
                logger.info(f"🗑️ حذف FCM token غير صالح للمستخدم {user.id}")
                user.fcm_token = None
                db.commit()
        finally:
            db.close()
    except Exception as e:
        logger.error(f"❌ خطأ في معالجة token غير صالح: {e}")


def update_fcm_token(
    db: Session, user_id: int, fcm_token: str
) -> bool:
    """تحديث FCM token للمستخدم
    
    Args:
        db: جلسة قاعدة البيانات
        user_id: معرف المستخدم
        fcm_token: الـ FCM token الجديد
    
    Returns:
        bool: نجاح أو فشل
    """
    try:
        user = db.query(models.User).filter(models.User.id == user_id).first()
        if not user:
            logger.warning(f"⚠️ المستخدم {user_id} غير موجود لتحديث FCM token")
            return False
        
        old_token = user.fcm_token
        
        # إذا كان نفس الـ token، لا حاجة للتحديث
        if old_token == fcm_token:
            return True
        
        user.fcm_token = fcm_token
        db.commit()
        
        logger.info(
            f"✅ تم تحديث FCM token للمستخدم {user_id}"
            f" ({'تحديث' if old_token else 'تسجيل جديد'})"
        )
        return True
    
    except Exception as e:
        db.rollback()
        logger.error(f"❌ خطأ في تحديث FCM token: {e}")
        return False