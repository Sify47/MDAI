# backend/main.py

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from database import engine, Base
import models
from routers import (
    medications,
    walking,
    chat,
    analysis,
    symptoms,
    nutrition,
    activities,
    auth,
    water,
    notifications,
    weight,
    quiz,
    diabetes,
    behavioral_nudges,
    predictive_prevention,
    community,
    dynamic_targets,
    activity_plans,
    smart_reminders,
    real,
    fcm,
)
from routers.ai_analytics import router as ai_router
from routers.auto_insights import router as auto_insights_router
from routers.data_export import router as data_export_router

# Rate Limiting
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])

app = FastAPI(title="Health Mate API")

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ تسجيل جميع الروترات
app.include_router(auth.router)
app.include_router(medications.router)
app.include_router(walking.router)
app.include_router(chat.router)
app.include_router(analysis.router)
app.include_router(symptoms.router)
app.include_router(nutrition.router)
app.include_router(activities.router)
app.include_router(water.router)
app.include_router(ai_router)
app.include_router(notifications.router)
app.include_router(weight.router)
app.include_router(quiz.router)
app.include_router(diabetes.router)
app.include_router(behavioral_nudges.router)
app.include_router(predictive_prevention.router)
app.include_router(community.router)
app.include_router(auto_insights_router)  # ✅ الرؤى التلقائية
app.include_router(data_export_router)  # ✅ تصدير البيانات
app.include_router(dynamic_targets.router)  # ✅ الأهداف الديناميكية
app.include_router(activity_plans.router)  # ✅ خطط الأنشطة
app.include_router(smart_reminders.router)  # ✅ التذكيرات الذكية
app.include_router(fcm.router)  # ✅ Firebase Cloud Messaging
app.include_router(real.router)  # ✅ بيانات حقيقية
# إنشاء جداول قاعدة البيانات
Base.metadata.create_all(bind=engine)

# تشغيل المجدول (Scheduler) عند بدء التشغيل
from workers.scheduler import setup_scheduler


@app.on_event("startup")
async def start_scheduler():
    """تشغيل المجدول عند بدء تشغيل السيرفر"""
    try:
        setup_scheduler()
    except Exception as e:
        print(f"⚠️ Scheduler startup error: {e}")


# ✅端点 اختبار
@app.get("/")
@limiter.limit("30/minute")
def root(request: Request):
    return {"message": "Health Mate API is running"}


@app.get("/test")
@limiter.limit("30/minute")
def test(request: Request):
    return {"message": "API is working!"}
