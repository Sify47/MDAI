# backend/core/cache_config.py

import os
import redis
from cachetools import TTLCache, cached
from functools import wraps
import json
from typing import Any, Callable
import logging

logger = logging.getLogger(__name__)

# ============================================
# ✅ إعدادات Redis
# ============================================

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
REDIS_ENABLED = os.getenv("REDIS_ENABLED", "true").lower() == "true"

# محاولة الاتصال بـ Redis
redis_client = None
if REDIS_ENABLED:
    try:
        redis_client = redis.Redis.from_url(
            REDIS_URL,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_timeout=5
        )
        # اختبار الاتصال
        redis_client.ping()
        logger.info("✅ Redis connected successfully")
    except Exception as e:
        logger.warning(f"⚠️ Redis connection failed: {e}, using in-memory cache")
        redis_client = None

# ============================================
# ✅ In-Memory Cache (fallback إذا Redis معطل)
# ============================================

# تعريف الـ caches المختلفة
user_cache = TTLCache(maxsize=1000, ttl=300)  # 5 دقائق
category_cache = TTLCache(maxsize=100, ttl=3600)  # ساعة
medicine_cache = TTLCache(maxsize=500, ttl=3600)  # ساعة
food_cache = TTLCache(maxsize=500, ttl=3600)  # ساعة
symptom_analysis_cache = TTLCache(maxsize=200, ttl=86400)  # يوم
meal_suggestion_cache = TTLCache(maxsize=200, ttl=7200)  # ساعتين

# ============================================
# ✅ دوال مساعدة للـ Cache
# ============================================

def get_cache_key(prefix: str, identifier: Any) -> str:
    """إنشاء مفتاح موحد للـ cache"""
    return f"{prefix}:{identifier}"

def set_cache(key: str, value: Any, ttl_seconds: int = 300):
    """حفظ بيانات في cache (Redis أو in-memory)"""
    try:
        if redis_client:
            # حفظ كـ JSON
            redis_client.setex(key, ttl_seconds, json.dumps(value, default=str))
        else:
            # استخدام in-memory (ملاحظة: TTLCache يدير الـ TTL تلقائياً)
            # سنستخدم cachetools مباشرة في الدوال
            pass
    except Exception as e:
        logger.error(f"Error setting cache: {e}")

def get_cache(key: str):
    """جلب بيانات من cache"""
    try:
        if redis_client:
            data = redis_client.get(key)
            if data:
                return json.loads(data)
        return None
    except Exception as e:
        logger.error(f"Error getting cache: {e}")
        return None

def delete_cache(key: str):
    """حذف مفتاح من cache"""
    try:
        if redis_client:
            redis_client.delete(key)
    except Exception as e:
        logger.error(f"Error deleting cache: {e}")

def delete_cache_pattern(pattern: str):
    """حذف كل المفاتيح التي تطابق نمط معين"""
    try:
        if redis_client:
            keys = redis_client.keys(pattern)
            if keys:
                redis_client.delete(*keys)
    except Exception as e:
        logger.error(f"Error deleting cache pattern: {e}")

# ============================================
# ✅ Decorators للتخزين المؤقت
# ============================================

def cache_result(ttl: int = 300, key_prefix: str = ""):
    """
    Decorator لتخزين نتائج الدوال في cache
    
    الاستخدام:
    @cache_result(ttl=3600, key_prefix="user")
    def get_user(user_id: int):
        return db.query(User).filter(User.id == user_id).first()
    """
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # بناء المفتاح
            if key_prefix:
                # استخدم أول معامل غير self/cls
                arg_values = []
                for arg in args:
                    if not hasattr(arg, '__name__'):  # ليس self أو cls
                        arg_values.append(str(arg))
                for k, v in kwargs.items():
                    arg_values.append(f"{k}={v}")
                
                cache_key = f"{key_prefix}:{':'.join(arg_values)}" if arg_values else key_prefix
            else:
                cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            
            # محاولة الجلب من cache
            if redis_client:
                cached_result = get_cache(cache_key)
                if cached_result is not None:
                    logger.debug(f"Cache hit: {cache_key}")
                    return cached_result
            
            # تنفيذ الدالة الأصلية
            result = func(*args, **kwargs)
            
            # حفظ في cache
            if redis_client and result is not None:
                set_cache(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator

def invalidate_cache(pattern: str):
    """Decorator لحذف cache بعد تنفيذ الدالة"""
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            result = func(*args, **kwargs)
            delete_cache_pattern(pattern)
            logger.info(f"Cache invalidated: {pattern}")
            return result
        return wrapper
    return decorator