# backend/routers/auth.py

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import bcrypt
import jwt
import os

from database import get_db
import models
import schemas

router = APIRouter(prefix="/api/auth", tags=["authentication"])

# ============================================
# إعدادات JWT
# ============================================
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30  # ✅ 30 يوم (بدل 30 دقيقة)
REFRESH_TOKEN_EXPIRE_DAYS = 90  # ✅ 90 يوم (بدل 7 أيام)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# ============================================
# دوال مساعدة
# ============================================


def hash_password(password: str) -> str:
    """تشفير كلمة المرور"""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """التحقق من كلمة المرور"""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"), hashed_password.encode("utf-8")
    )


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """إنشاء توكن دخول"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """إنشاء refresh token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> dict:
    """فك تشفير التوكن"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="انتهت صلاحية التوكن",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="توكن غير صالح",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> models.User:
    """جلب المستخدم الحالي من التوكن"""
    payload = decode_token(token)

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="نوع التوكن غير صحيح",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="التوكن لا يحتوي على معرف المستخدم",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="المستخدم غير موجود",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="الحساب غير نشط",
        )

    return user


def log_login_attempt(db: Session, email: str, ip: str, success: bool):
    """تسجيل محاولة تسجيل الدخول"""
    attempt = models.LoginAttempt(email=email, ip_address=ip, success=success)
    db.add(attempt)
    db.commit()


# ============================================
# ✅ 1. تسجيل الدخول
# ============================================
@router.post("/login", response_model=schemas.TokenResponse)
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """تسجيل الدخول"""
    print(f"📝 [Auth] محاولة تسجيل دخول: {form_data.username}")

    # البحث عن المستخدم
    user = db.query(models.User).filter(models.User.email == form_data.username).first()

    # التحقق من كلمة المرور
    if not user or not verify_password(form_data.password, user.password_hash):
        # تسجيل محاولة فاشلة
        log_login_attempt(
            db,
            form_data.username,
            request.client.host if request.client else "unknown",
            False,
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="البريد الإلكتروني أو كلمة المرور غير صحيحة",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # التحقق من نشاط الحساب
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="الحساب غير نشط",
        )

    # إنشاء التوكنات
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # حفظ التوكن في قاعدة البيانات
    token_expires = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    db_token = models.Token(
        user_id=user.id,
        token=access_token,
        refresh_token=refresh_token,
        expires_at=token_expires,
    )
    db.add(db_token)

    # تحديث آخر تسجيل دخول
    user.last_login = datetime.utcnow()
    db.commit()

    # تسجيل محاولة ناجحة
    log_login_attempt(
        db,
        form_data.username,
        request.client.host if request.client else "unknown",
        True,
    )

    print(f"✅ [Auth] تسجيل دخول ناجح: {user.email}")

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": user,
    }


# ============================================
# ✅ 2. إنشاء حساب جديد
# ============================================
@router.post("/register", status_code=201, response_model=schemas.TokenResponse)
async def register(
    request: Request, user_data: schemas.UserCreate, db: Session = Depends(get_db)
):
    """إنشاء حساب جديد"""
    print(f"📝 [Auth] إنشاء حساب جديد: {user_data.email}")

    # التحقق من عدم وجود البريد الإلكتروني مسبقاً
    existing_user = (
        db.query(models.User).filter(models.User.email == user_data.email).first()
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="البريد الإلكتروني مستخدم بالفعل",
        )

    # تشفير كلمة المرور
    hashed_password = hash_password(user_data.password)

    # إنشاء المستخدم
    db_user = models.User(
        name=user_data.name,
        email=user_data.email,
        password_hash=hashed_password,
        phone=user_data.phone,
        birth_date=user_data.birth_date,
        gender=user_data.gender,
        is_verified=True,  # مؤقتاً، يمكن إضافة التحقق بالبريد لاحقاً
    )
    db.add(db_user)
    db.flush()  # للحصول على id المستخدم

    # إنشاء التوكنات
    access_token = create_access_token(data={"sub": str(db_user.id)})
    refresh_token = create_refresh_token(data={"sub": str(db_user.id)})

    # حفظ التوكن
    token_expires = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    db_token = models.Token(
        user_id=db_user.id,
        token=access_token,
        refresh_token=refresh_token,
        expires_at=token_expires,
    )
    db.add(db_token)

    db.commit()
    db.refresh(db_user)

    print(f"✅ [Auth] تم إنشاء حساب جديد: {db_user.email}")

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": db_user,
    }


# ============================================
# ✅ 3. تجديد التوكن
# ============================================
@router.post("/refresh", response_model=schemas.TokenResponse)
async def refresh_token(refresh_token: str, db: Session = Depends(get_db)):
    """تجديد توكن الدخول باستخدام refresh token"""
    print("📝 [Auth] محاولة تجديد التوكن")

    # فك تشفير الـ refresh token
    try:
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="نوع التوكن غير صحيح"
            )

        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="توكن غير صالح"
            )

        # البحث عن المستخدم
        user = db.query(models.User).filter(models.User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="المستخدم غير موجود أو غير نشط",
            )

        # إنشاء توكن جديد
        new_access_token = create_access_token(data={"sub": str(user.id)})
        new_refresh_token = create_refresh_token(data={"sub": str(user.id)})

        # حفظ التوكن الجديد
        token_expires = datetime.utcnow() + timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        )
        db_token = models.Token(
            user_id=user.id,
            token=new_access_token,
            refresh_token=new_refresh_token,
            expires_at=token_expires,
        )
        db.add(db_token)
        db.commit()

        return {
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer",
            "user": user,
        }

    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="توكن غير صالح"
        )


# ============================================
# ✅ 4. جلب بيانات المستخدم الحالي
# ============================================
@router.get("/me", response_model=schemas.UserResponse)
async def get_current_user_info(current_user: models.User = Depends(get_current_user)):
    """جلب بيانات المستخدم الحالي"""
    return current_user


# ============================================
# ✅ 5. تسجيل الخروج
# ============================================
@router.post("/logout")
async def logout(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """تسجيل الخروج (حذف التوكن الحالي)"""
    print(f"📝 [Auth] تسجيل خروج: {current_user.email}")

    # حذف التوكن الحالي
    db.query(models.Token).filter(models.Token.token == token).delete()
    db.commit()

    return {"message": "تم تسجيل الخروج بنجاح"}


# ============================================
# ✅ 6. تحديث بيانات المستخدم
# ============================================
@router.put("/me", response_model=schemas.UserResponse)
async def update_user_info(
    user_update: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """تحديث بيانات المستخدم"""
    print(f"📝 [Auth] تحديث بيانات المستخدم: {current_user.email}")

    for key, value in user_update.dict(exclude_unset=True).items():
        if value is not None and hasattr(current_user, key):
            setattr(current_user, key, value)

    db.commit()
    db.refresh(current_user)

    return current_user


# ============================================
# ✅ 7. تغيير كلمة المرور
# ============================================
@router.post("/change-password")
async def change_password(
    passwords: schemas.ChangePassword,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """تغيير كلمة المرور"""
    print(f"📝 [Auth] تغيير كلمة المرور: {current_user.email}")

    # التحقق من كلمة المرور الحالية
    if not verify_password(passwords.old_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="كلمة المرور الحالية غير صحيحة",
        )

    # تحديث كلمة المرور
    current_user.password_hash = hash_password(passwords.new_password)

    # حذف كل التوكنات (تسجيل الخروج من كل الأجهزة)
    db.query(models.Token).filter(models.Token.user_id == current_user.id).delete()

    db.commit()

    return {"message": "تم تغيير كلمة المرور بنجاح"}
