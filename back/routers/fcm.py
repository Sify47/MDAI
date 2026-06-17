# backend/routers/fcm.py
"""Router for FCM (Firebase Cloud Messaging) token management."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db
import models
from routers.auth import get_current_user
from services.fcm_service import update_fcm_token

router = APIRouter(prefix="/api/fcm", tags=["fcm"])


# ============================================
# Pydantic Models
# ============================================
class FCMTokenRequest(BaseModel):
    fcm_token: str


# ============================================
# ✅ 1. Register / Update FCM Token
# ============================================
@router.post("/register-token", status_code=200)
def register_fcm_token(
    token_data: FCMTokenRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """تسجيل أو تحديث FCM token للمستخدم الحالي"""
    if not token_data.fcm_token or len(token_data.fcm_token) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="FCM token is invalid or too short",
        )

    success = update_fcm_token(db, current_user.id, token_data.fcm_token)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update FCM token",
        )

    return {"message": "FCM token registered successfully", "user_id": current_user.id}


# ============================================
# ✅ 2. Get Current User's FCM Token Status
# ============================================
@router.get("/token-status")
def get_fcm_token_status(
    current_user: models.User = Depends(get_current_user),
):
    """التحقق من حالة FCM token للمستخدم الحالي"""
    has_token = bool(current_user.fcm_token)
    return {
        "has_token": has_token,
        "token_preview": current_user.fcm_token[:20] + "..." if has_token else None,
    }


# ============================================
# ✅ 3. Delete FCM Token (logout)
# ============================================
@router.delete("/token")
def delete_fcm_token(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """حذف FCM token عند تسجيل الخروج"""
    current_user.fcm_token = None
    db.commit()
    return {"message": "FCM token deleted successfully"}