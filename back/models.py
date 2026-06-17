# backend/models.py

from sqlalchemy import (
    TIMESTAMP,
    Column,
    Integer,
    Numeric,
    String,
    Float,
    Boolean,
    Date,
    JSON,
    Table,
    Text,
    DateTime,
    ForeignKey,
    Time,
    Enum,
    UniqueConstraint,
    CheckConstraint,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base
import json
from datetime import datetime


import enum

class PropertyStatus(str, enum.Enum):
    ACTIVE = "active"
    SOLD = "sold"
    RENTED = "rented"
    EXPIRED = "expired"

class PaymentMethod(str, enum.Enum):
    CASH = "Cash"
    INSTALLMENTS = "Installments"
    BOTH = "Both"

class Property(Base):
    __tablename__ = "properties"
    
    id = Column(Integer, primary_key=True, index=True)
    link = Column(String(500), unique=True, index=True)
    title = Column(Text)
    property_type = Column(String(100), index=True)
    price = Column(Float, index=True)
    location = Column(String(255), index=True)
    state = Column(String(100), index=True)
    area = Column(Float)
    bedrooms = Column(Integer)
    bathrooms = Column(Integer)
    down_payment = Column(Float, default=0)
    payment_method = Column(Enum(PaymentMethod), default=PaymentMethod.CASH)
    price_per_m = Column(Float)
    source = Column(String(50), default="bayut")
    status = Column(Enum(PropertyStatus), default=PropertyStatus.ACTIVE)
    is_active = Column(Boolean, default=True)
    scrape_date = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    
    # مؤشرات إضافية
    buy_score = Column(Float, default=0)
    value_score = Column(Float, default=0)
    investment_score = Column(Float, default=0)
    
    # وصف إضافي
    description = Column(Text, nullable=True)
    features = Column(Text, nullable=True)  # JSON string
    
    # للمستخدمين المفضلين
    user_id = Column(Integer, nullable=True, index=True)  # optional user favorite


class AreaIntelligence(Base):
    __tablename__ = "area_intelligence"
    
    id = Column(Integer, primary_key=True, index=True)
    area_name = Column(String(255), unique=True, index=True)
    state = Column(String(100), index=True)
    
    # مؤشرات المنطقة
    near_sea = Column(Boolean, default=False)
    schools_quality = Column(Float, default=3.0)  # 1-5
    services_level = Column(Float, default=3.0)   # 1-5
    transportation = Column(Float, default=3.0)   # 1-5
    investment_potential = Column(Float, default=3.0)  # 1-5
    resale_liquidity = Column(Float, default=3.0)     # 1-5
    area_score = Column(Integer, default=70)  # 0-100
    
    category = Column(String(50))
    key_insights = Column(Text)
    
    # مؤشرات إضافية
    safety_score = Column(Float, default=3.0)  # 1-5
    nightlife_score = Column(Float, default=3.0)  # 1-5
    family_friendly = Column(Boolean, default=True)
    
    updated_at = Column(DateTime, onupdate=func.now())


class ScrapingHistory(Base):
    __tablename__ = "scraping_history"

    id = Column(Integer, primary_key=True, index=True)
    source = Column(String(50))
    properties_found = Column(Integer, default=0)
    properties_added = Column(Integer, default=0)
    properties_updated = Column(Integer, default=0)
    start_time = Column(DateTime, server_default=func.now())
    end_time = Column(DateTime)
    status = Column(Enum("success", "failed", "partial", name="scraping_status"))
    error_message = Column(Text, nullable=True)


class PricePrediction(Base):
    __tablename__ = "price_predictions"
    
    id = Column(Integer, primary_key=True, index=True)
    location = Column(String(255), index=True)
    property_type = Column(String(100))
    predicted_price = Column(Float)
    predicted_price_per_m = Column(Float)
    confidence_lower = Column(Float)
    confidence_upper = Column(Float)
    prediction_date = Column(Date, server_default=func.current_date())
    model_version = Column(String(50))
    created_at = Column(DateTime, server_default=func.now())


class UserPropertyFavorite(Base):
    __tablename__ = "user_property_favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    property_id = Column(Integer, index=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    
    # Composite unique constraint will be added in database


class PropertyAlert(Base):
    __tablename__ = "property_alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    alert_name = Column(String(100))
    
    # Alert criteria
    location = Column(String(255), nullable=True)
    min_price = Column(Float, nullable=True)
    max_price = Column(Float, nullable=True)
    min_area = Column(Float, nullable=True)
    max_area = Column(Float, nullable=True)
    bedrooms = Column(Integer, nullable=True)
    property_type = Column(String(100), nullable=True)
    
    is_active = Column(Boolean, default=True)
    last_triggered = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

###########################################################################################
class WeightHistory(Base):
    __tablename__ = "weight_history"

    id = Column(Integer, primary_key=True, index=True)
    user_nutrition_id = Column(Integer, ForeignKey("user_nutrition.id"))
    weight = Column(Float, nullable=False)
    date = Column(Date, nullable=False, default=datetime.today)
    notes = Column(String(500), nullable=True)  # ✅ تأكد من وجود هذا السطر

    created_at = Column(DateTime, default=datetime.utcnow)

    user_nutrition = relationship("UserNutrition", back_populates="weight_history")


class HealthImpactFactor(Base):
    __tablename__ = "health_impact_factors"

    id = Column(Integer, primary_key=True, index=True)
    factor_type = Column(Enum("symptom", "medicine", "disease"), nullable=False)
    factor_id = Column(Integer, nullable=True)  # ID مرجعي (medicine_id مثلاً)
    factor_name = Column(String(100), nullable=False)
    impact_on_steps = Column(Integer, nullable=False)  # نسبة مئوية
    calories_adjustment = Column(Integer, nullable=True)  # نسبة مئوية
    water_adjustment = Column(Float, default=0.0)  # نسبة مئوية لتعديل الماء
    protein_adjustment = Column(Float, default=0.0)  # نسبة مئوية لتعديل البروتين
    carbs_adjustment = Column(Float, default=0.0)  # نسبة مئوية لتعديل الكربوهيدرات
    fat_adjustment = Column(Float, default=0.0)  # نسبة مئوية لتعديل الدهون
    severity_weight = Column(Float, default=1.0)  # وزن الخطورة (0.5-2.0)
    severity_level = Column(String(20), default="الكل")
    description = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())


class MedicineFoodRecommendation(Base):
    __tablename__ = "medicine_food_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    medicine_id = Column(Integer, ForeignKey("medicines.id", ondelete="CASCADE"))
    medicine_name = Column(String(100), nullable=False)
    foods_to_avoid = Column(JSON, nullable=False)  # قائمة
    foods_to_eat = Column(JSON, nullable=False)  # قائمة
    drinks_to_avoid = Column(JSON, nullable=False)
    drinks_recommended = Column(JSON, nullable=False)
    timing_instructions = Column(Text, nullable=True)
    general_tips = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


# ============================================
# نموذج المستخدم
# ============================================
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=True)
    birth_date = Column(DateTime, nullable=False)
    gender = Column(Enum("ذكر", "أنثى"), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    last_login = Column(DateTime, nullable=True)
    fcm_token = Column(String(500), nullable=True, index=True)

    nutrition_data = relationship(
        "UserNutrition", back_populates="user", cascade="all, delete-orphan"
    )
    meals = relationship("Meal", back_populates="user", cascade="all, delete-orphan")
    medications = relationship(
        "Medication", back_populates="user", cascade="all, delete-orphan"
    )
    symptoms = relationship(
        "Symptom", back_populates="user", cascade="all, delete-orphan"
    )
    tokens = relationship("Token", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User {self.email}>"


# ============================================
# نموذج التوكن
# ============================================
class Token(Base):
    __tablename__ = "tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    token = Column(String(500), nullable=False, index=True)
    refresh_token = Column(String(500), nullable=True, index=True)
    token_type = Column(String(20), default="bearer")
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="tokens")

    def __repr__(self):
        return f"<Token for user {self.user_id}>"


# ============================================
# نموذج محاولات تسجيل الدخول
# ============================================
class LoginAttempt(Base):
    __tablename__ = "login_attempts"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), nullable=False, index=True)
    ip_address = Column(String(45), nullable=True)
    success = Column(Boolean, default=False)
    attempted_at = Column(DateTime, server_default=func.now())


# ============================================
# نموذج أنواع الأعراض (symptom_types)
# ============================================
class SymptomType(Base):
    __tablename__ = "symptom_types"

    id = Column(Integer, primary_key=True, index=True)
    name_ar = Column(String(100), nullable=False, unique=True)
    name_en = Column(String(100), nullable=True)
    icon = Column(String(10), default="🤒")
    category = Column(String(50), nullable=True)
    default_analysis = Column(Text, nullable=True)
    common_causes = Column(JSON, nullable=True)
    recommended_actions = Column(JSON, nullable=True)
    warning_signs = Column(JSON, nullable=True)
    requires_immediate_care = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "name_ar": self.name_ar,
            "name_en": self.name_en,
            "icon": self.icon,
            "category": self.category,
            "default_analysis": self.default_analysis,
            "common_causes": self.common_causes,
            "recommended_actions": self.recommended_actions,
            "warning_signs": self.warning_signs,
            "requires_immediate_care": self.requires_immediate_care,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# ============================================
# نموذج الأعراض
# ============================================
class Symptom(Base):
    __tablename__ = "symptoms"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    icon = Column(String(10), default="🤒")
    severity = Column(Enum("خفيف", "متوسط", "شديد"), nullable=False)
    date_time = Column(DateTime, nullable=False)
    notes = Column(Text, nullable=True)
    analysis = Column(Text, nullable=True)
    possible_causes = Column(JSON, nullable=True)
    suggested_actions = Column(JSON, nullable=True)
    warning_signs = Column(JSON, nullable=True)
    food_recommendations = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="symptoms")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "icon": self.icon,
            "severity": self.severity,
            "date_time": self.date_time.isoformat() if self.date_time else None,
            "notes": self.notes,
            "analysis": self.analysis,
            "possible_causes": self.possible_causes,
            "suggested_actions": self.suggested_actions,
            "warning_signs": self.warning_signs,
            "food_recommendations": self.food_recommendations,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# ============================================
# نموذج توصيات الطعام حسب الأعراض
# ============================================
class FoodRecommendation(Base):
    __tablename__ = "food_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    symptom_name = Column(String(100), nullable=False, index=True)
    foods_to_eat = Column(JSON, nullable=False)
    foods_to_avoid = Column(JSON, nullable=False)
    drinks_recommended = Column(JSON, nullable=False)
    drinks_to_avoid = Column(JSON, nullable=False)
    general_tips = Column(Text, nullable=True)
    severity_level = Column(Enum("خفيف", "متوسط", "شديد", "الكل"), default="الكل")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# ============================================
# نموذج التغذية (معدل)
# ============================================
class UserNutrition(Base):
    __tablename__ = "user_nutrition"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    weight = Column(Float, nullable=False)
    height = Column(Float, nullable=False)
    age = Column(Integer, nullable=False)
    gender = Column(String(10), nullable=False)
    goal = Column(String(20), nullable=False)
    activity_level = Column(String(20), nullable=False)
    weight_loss_rate = Column(String(10), default="0.5")
    target_weight = Column(Float, nullable=True)
    diseases = Column(JSON, default=list)

    # ✅ الحقول الجديدة
    initial_weight = Column(Float, nullable=True)
    target_weeks = Column(Integer, nullable=True)

    bmr = Column(Float, nullable=True)
    tdee = Column(Float, nullable=True)
    target_calories = Column(Float, nullable=True)
    daily_steps_goal = Column(Integer, default=8000)
    water_intake = Column(Float, nullable=True)
    target_protein = Column(Float, nullable=True)
    target_carbs = Column(Float, nullable=True)
    target_fat = Column(Float, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    meals = relationship(
        "Meal", back_populates="user_nutrition", cascade="all, delete-orphan"
    )
    user = relationship("User", back_populates="nutrition_data")
    weight_history = relationship(
        "WeightHistory", back_populates="user_nutrition", cascade="all, delete-orphan"
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "weight": self.weight,
            "height": self.height,
            "age": self.age,
            "gender": self.gender,
            "goal": self.goal,
            "activity_level": self.activity_level,
            "weight_loss_rate": self.weight_loss_rate,
            "target_weight": self.target_weight,
            "diseases": self.diseases,
            "initial_weight": self.initial_weight,
            "target_weeks": self.target_weeks,
            "bmr": self.bmr,
            "tdee": self.tdee,
            "target_calories": self.target_calories,
            "daily_steps_goal": self.daily_steps_goal,
            "water_intake": self.water_intake,
            "target_protein": self.target_protein,
            "target_carbs": self.target_carbs,
            "target_fat": self.target_fat,
        }


# ============================================
# نموذج الأطعمة
# ============================================
class Food(Base):
    __tablename__ = "foods"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    calories = Column(Float, nullable=False)
    protein = Column(Float, default=0)
    carbs = Column(Float, default=0)
    fat = Column(Float, default=0)
    fiber = Column(Float, default=0)
    unit = Column(String(50), default="100 جرام")
    category = Column(String(50))
    icon = Column(String(10), default="🍽️")
    suitable_for = Column(JSON, default=list)
    is_recommended = Column(Boolean, default=False)
    glycemic_index = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "name_en": self.name_en,
            "calories": self.calories,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
            "fiber": self.fiber,
            "unit": self.unit,
            "category": self.category,
            "icon": self.icon,
            "suitable_for": self.suitable_for,
            "is_recommended": self.is_recommended,
            "glycemic_index": self.glycemic_index,
        }


# ============================================
# نموذج الوجبات
# ============================================
class Meal(Base):
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    user_nutrition_id = Column(Integer, ForeignKey("user_nutrition.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String(20), nullable=False)
    name = Column(String(100), nullable=True)
    date_time = Column(DateTime, nullable=False)
    notes = Column(Text, nullable=True)
    total_calories = Column(Float, default=0)
    total_protein = Column(Float, default=0)
    total_carbs = Column(Float, default=0)
    total_fat = Column(Float, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    user_nutrition = relationship("UserNutrition", back_populates="meals")
    foods = relationship(
        "MealFood", back_populates="meal", cascade="all, delete-orphan"
    )
    user = relationship("User", back_populates="meals")

    def to_dict(self):
        return {
            "id": self.id,
            "user_nutrition_id": self.user_nutrition_id,
            "user_id": self.user_id,
            "type": self.type,
            "name": self.name,
            "date_time": self.date_time.isoformat() if self.date_time else None,
            "notes": self.notes,
            "total_calories": self.total_calories,
            "total_protein": self.total_protein,
            "total_carbs": self.total_carbs,
            "total_fat": self.total_fat,
            "foods": [food.to_dict() for food in self.foods],
        }


# ============================================
# نموذج أطعمة الوجبات
# ============================================
class MealFood(Base):
    __tablename__ = "meal_foods"

    id = Column(Integer, primary_key=True, index=True)
    meal_id = Column(Integer, ForeignKey("meals.id"), nullable=False)
    food_id = Column(Integer, ForeignKey("foods.id"), nullable=True)
    quantity = Column(Float, default=1)
    unit = Column(String(50), nullable=True)
    custom_food_name = Column(String(200), nullable=True)
    custom_calories = Column(Float, nullable=True)
    custom_protein = Column(Float, nullable=True)
    custom_carbs = Column(Float, nullable=True)
    custom_fat = Column(Float, nullable=True)

    meal = relationship("Meal", back_populates="foods")
    food = relationship("Food")

    def to_dict(self):
        if self.food_id and self.food:
            return {
                "id": self.id,
                "meal_id": self.meal_id,
                "food_id": self.food_id,
                "name": self.food.name,
                "quantity": self.quantity,
                "unit": self.unit,
                "calories": self.food.calories * self.quantity,
                "protein": self.food.protein * self.quantity,
                "carbs": self.food.carbs * self.quantity,
                "fat": self.food.fat * self.quantity,
                "is_custom": False,
            }
        else:
            return {
                "id": self.id,
                "meal_id": self.meal_id,
                "food_id": None,
                "name": self.custom_food_name or "طعام",
                "quantity": self.quantity,
                "unit": self.unit,
                "calories": (self.custom_calories or 0) * self.quantity,
                "protein": (self.custom_protein or 0) * self.quantity,
                "carbs": (self.custom_carbs or 0) * self.quantity,
                "fat": (self.custom_fat or 0) * self.quantity,
                "is_custom": True,
            }


# ============================================
# نموذج اقتراحات الوجبات
# ============================================
class MealSuggestion(Base):
    __tablename__ = "meal_suggestions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    type = Column(String(20))
    goal = Column(String(20))
    calories = Column(Integer)
    protein = Column(Float)
    carbs = Column(Float)
    fat = Column(Float)
    suitable_for = Column(JSON, default=list)
    ingredients = Column(JSON, default=list)
    preparation = Column(Text, nullable=True)
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "type": self.type,
            "goal": self.goal,
            "calories": self.calories,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
            "suitable_for": self.suitable_for,
            "ingredients": self.ingredients,
            "preparation": self.preparation,
            "image_url": self.image_url,
        }


# ============================================
# نموذج الأدوية العامة
# ============================================
class Medicine(Base):
    __tablename__ = "medicines"

    id = Column(Integer, primary_key=True, index=True)
    name_ar = Column(String(255), index=True, nullable=False)
    name_en = Column(String(255), index=True)
    generic_name = Column(String(255))
    category = Column(String(100))
    description = Column(Text)
    uses = Column(JSON)
    side_effects = Column(JSON)
    warnings = Column(JSON)
    interactions = Column(JSON)
    dosage_info = Column(Text)
    how_to_take = Column(Text)
    storage = Column(Text)
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "name_ar": self.name_ar,
            "name_en": self.name_en,
            "generic_name": self.generic_name,
            "category": self.category,
            "description": self.description,
            # ✅ uses - تأكد من أنها list
            "uses": (
                self.uses
                if isinstance(self.uses, list)
                else (
                    json.loads(self.uses)
                    if self.uses and isinstance(self.uses, str)
                    else []
                )
            ),
            # ✅ side_effects - نفس الشيء
            "side_effects": (
                self.side_effects
                if isinstance(self.side_effects, list)
                else (
                    json.loads(self.side_effects)
                    if self.side_effects and isinstance(self.side_effects, str)
                    else []
                )
            ),
            # ✅ warnings - نفس الشيء
            "warnings": (
                self.warnings
                if isinstance(self.warnings, list)
                else (
                    json.loads(self.warnings)
                    if self.warnings and isinstance(self.warnings, str)
                    else []
                )
            ),
            # ✅ interactions - نفس الشيء
            "interactions": (
                self.interactions
                if isinstance(self.interactions, list)
                else (
                    json.loads(self.interactions)
                    if self.interactions and isinstance(self.interactions, str)
                    else []
                )
            ),
            "dosage_info": self.dosage_info,
            "how_to_take": self.how_to_take,
            "storage": self.storage,
            "image_url": self.image_url,
        }


# backend/models.py - إضافة هذه الكلاسات


class WaterIntake(Base):
    __tablename__ = "water_intake"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    time = Column(DateTime, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", backref="water_intakes")


class WaterSettings(Base):
    __tablename__ = "water_settings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    daily_goal = Column(Float, default=2.5)
    reminder_interval = Column(Integer, default=60)
    reminder_start = Column(Time, default="08:00:00")
    reminder_end = Column(Time, default="22:00:00")
    enable_notifications = Column(Boolean, default=True)
    cup_size = Column(Float, default=0.25)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", backref="water_settings")


# backend/models.py


# backend/models.py


# backend/models.py


class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notification_type = Column(
        Enum("medication", "water", "activity", "general", "summary", "quiz"), nullable=False
    )
    notification_subtype = Column(String(50), nullable=True)
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    scheduled_time = Column(DateTime, nullable=False)
    sent_time = Column(DateTime, nullable=True)
    delivered = Column(Boolean, default=False)
    action_taken = Column(
        Enum("taken", "completed", "snoozed", "dismissed", "ignored"), nullable=True
    )
    action_time = Column(DateTime, nullable=True)
    extra_data = Column(JSON, nullable=True)  # ✅ تأكد من وجود هذا السطر
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", backref="notification_logs")


# ============================================
# نموذج أدوية المستخدم
# ============================================
class Medication(Base):
    __tablename__ = "medications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    medicine_id = Column(Integer, ForeignKey("medicines.id"), nullable=True)
    times_per_day = Column(Integer, nullable=False)
    times = Column(JSON, nullable=False)
    with_food = Column(Boolean, default=True)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    medicine = relationship("Medicine")
    doses = relationship(
        "MedicationDose", back_populates="medication", cascade="all, delete-orphan"
    )
    user = relationship("User", back_populates="medications")

    def to_dict(self):
        times_value = self.times
        if isinstance(times_value, str):
            try:
                times_value = json.loads(times_value)
            except:
                times_value = []
        medicine_info = self.medicine.to_dict() if self.medicine else None
        today = datetime.now().date()
        taken_today = sum(
            1
            for dose in self.doses
            if dose.taken_time and dose.taken_time.date() == today
        )
        return {
            "id": self.id,
            "user_id": self.user_id,
            "medicine_id": self.medicine_id,
            "medicine_info": medicine_info,
            "times_per_day": self.times_per_day,
            "times": times_value,
            "with_food": self.with_food,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "notes": self.notes,
            "taken_today": taken_today,
        }


# ============================================
# نموذج جرعات الأدوية
# ============================================
class MedicationDose(Base):
    __tablename__ = "medication_doses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    medication_id = Column(Integer, ForeignKey("medications.id"), nullable=False)
    scheduled_time = Column(DateTime, nullable=False)
    taken_time = Column(DateTime, nullable=True)
    status = Column(String(20), default="pending")

    medication = relationship("Medication", back_populates="doses")

    def to_dict(self):
        medication_info = self.medication.medicine if self.medication else None
        return {
            "id": self.id,
            "user_id": self.user_id,
            "medication_id": self.medication_id,
            "medication_name": (
                medication_info.name_ar if medication_info else "دواء بدون اسم"
            ),
            "scheduled_time": (
                self.scheduled_time.isoformat() if self.scheduled_time else None
            ),
            "taken_time": self.taken_time.isoformat() if self.taken_time else None,
            "status": self.status,
            "dose": f"{medication_info.dosage_info}" if medication_info else "",
        }


# ============================================
# نموذج أنشطة المشي
# ============================================
class WalkingActivity(Base):
    __tablename__ = "walking_activities"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    steps = Column(Integer, nullable=False)
    distance_km = Column(Float, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    calories_burned = Column(Integer, nullable=True)
    activity_type = Column(String(50), nullable=True, default="walking")
    activity_date = Column(Date, nullable=False)
    activity_time = Column(Time, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "steps": self.steps,
            "distance_km": self.distance_km,
            "duration_minutes": self.duration_minutes,
            "calories_burned": self.calories_burned,
            "activity_type": self.activity_type or "walking",
            "activity_date": (
                self.activity_date.isoformat() if self.activity_date else None
            ),
            "activity_time": (
                self.activity_time.isoformat() if self.activity_time else None
            ),
            "notes": self.notes,
        }


# ============================================
# نموذج الأنشطة اليومية
# ============================================
class ActivityCategory(Base):
    __tablename__ = "activity_categories"

    id = Column(Integer, primary_key=True, index=True)
    name_ar = Column(String(50), nullable=False, unique=True)
    name_en = Column(String(50), nullable=False, unique=True)
    icon_code = Column(String(50), default="📋")
    color_code = Column(String(20), default="#2196F3")
    created_at = Column(DateTime, default=datetime.utcnow)

    activities = relationship("Activity", back_populates="category")

    def to_dict(self):
        return {
            "id": self.id,
            "name_ar": self.name_ar,
            "name_en": self.name_en,
            "icon_code": self.icon_code,
            "color_code": self.color_code,
        }


class Activity(Base):
    __tablename__ = "activities"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("activity_categories.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    is_completed = Column(Boolean, default=False)
    has_reminder = Column(Boolean, default=False)
    reminder_minutes = Column(Integer, default=15)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 🆕 Exercise tracking columns (Phase A10)
    is_exercise = Column(Boolean, default=False)
    exercise_name = Column(String(200), nullable=True)
    exercise_name_en = Column(String(200), nullable=True)
    exercise_id = Column(String(50), nullable=True)
    muscle_group = Column(String(100), nullable=True)
    muscle_group_en = Column(String(100), nullable=True)
    met_value = Column(Float, nullable=True)
    sets = Column(Integer, nullable=True)
    reps = Column(Integer, nullable=True)
    weight_kg = Column(Float, nullable=True)
    rest_seconds = Column(Integer, nullable=True)
    calories_burned = Column(Integer, nullable=True)

    # 🆕 Plan linking
    plan_id = Column(Integer, ForeignKey("activity_plans.id"), nullable=True)
    plan_name = Column(String(200), nullable=True)

    category = relationship("ActivityCategory", back_populates="activities")
    plan = relationship("ActivityPlan", back_populates="activities")

    # 🆕 Multi-exercise support (Phase A Feedback)
    exercises = relationship(
        "ActivityExercise",
        back_populates="activity",
        cascade="all, delete-orphan",
        order_by="ActivityExercise.order_index"
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "category_id": self.category_id,
            "title": self.title,
            "description": self.description,
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "is_completed": self.is_completed,
            "has_reminder": self.has_reminder,
            "reminder_minutes": self.reminder_minutes,
            "notes": self.notes,
            # 🆕 Exercise tracking
            "is_exercise": self.is_exercise,
            "exercise_name": self.exercise_name,
            "exercise_name_en": self.exercise_name_en,
            "exercise_id": self.exercise_id,
            "muscle_group": self.muscle_group,
            "muscle_group_en": self.muscle_group_en,
            "met_value": self.met_value,
            "sets": self.sets,
            "reps": self.reps,
            "weight_kg": self.weight_kg,
            "rest_seconds": self.rest_seconds,
            "calories_burned": self.calories_burned,
            # 🆕 Plan linking
            "plan_id": self.plan_id,
            "plan_name": self.plan_name,
            "category": self.category.to_dict() if self.category else None,
            # 🆕 Multi-exercise list
            "exercises": [e.to_dict() for e in self.exercises] if self.exercises else [],
        }


# ============================================
# 🏋️ نموذج تمارين النشاط المتعددة (Activity Exercise)
# ============================================
class ActivityExercise(Base):
    """تمارين متعددة مرتبطة بنشاط واحد"""
    __tablename__ = "activity_exercises"

    id = Column(Integer, primary_key=True, index=True)
    activity_id = Column(Integer, ForeignKey("activities.id", ondelete="CASCADE"), nullable=False)
    exercise_id = Column(String(50), nullable=True)
    exercise_name_ar = Column(String(200), nullable=True)
    exercise_name_en = Column(String(200), nullable=True)
    muscle_group = Column(String(100), nullable=True)
    muscle_group_en = Column(String(100), nullable=True)
    met_value = Column(Float, nullable=True)
    sets = Column(Integer, nullable=True)
    reps = Column(Integer, nullable=True)
    weight_kg = Column(Float, nullable=True)
    rest_seconds = Column(Integer, nullable=True)
    calories_burned = Column(Integer, nullable=True)
    order_index = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    activity = relationship("Activity", back_populates="exercises")

    def to_dict(self):
        return {
            "id": self.id,
            "activity_id": self.activity_id,
            "exercise_id": self.exercise_id,
            "exercise_name_ar": self.exercise_name_ar,
            "exercise_name_en": self.exercise_name_en,
            "muscle_group": self.muscle_group,
            "muscle_group_en": self.muscle_group_en,
            "met_value": self.met_value,
            "sets": self.sets,
            "reps": self.reps,
            "weight_kg": self.weight_kg,
            "rest_seconds": self.rest_seconds,
            "calories_burned": self.calories_burned,
            "order_index": self.order_index,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# ============================================
# نموذج المحادثة (Chat QA)
# ============================================
class ChatQA(Base):
    __tablename__ = "chat_qa"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(String(500), index=True, nullable=False)
    normalized_question = Column(String(500), index=True)
    answer = Column(Text, nullable=False)
    answer_title = Column(String(200))
    bullets = Column(JSON, nullable=True)
    category = Column(String(50), index=True)
    keywords = Column(JSON, nullable=True)
    confidence = Column(Float, default=1.0)
    source = Column(String(20), default="manual")
    usage_count = Column(Integer, default=0)
    helpful_count = Column(Integer, default=0)
    not_helpful_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "question": self.question,
            "normalized_question": self.normalized_question,
            "answer": self.answer,
            "answer_title": self.answer_title,
            "bullets": json.loads(self.bullets) if self.bullets else [],
            "category": self.category,
            "keywords": json.loads(self.keywords) if self.keywords else [],
            "confidence": self.confidence,
            "source": self.source,
            "usage_count": self.usage_count,
            "helpful_count": self.helpful_count,
            "not_helpful_count": self.not_helpful_count,
        }


# backend/models.py

# أضف هذه النماذج في نهاية الملف


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    question_text = Column(String(500), nullable=False)
    category = Column(
        String(50), nullable=False
    )  # sleep, nutrition, activity, mental, physical, habits, social, medication, environment
    default_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    options = relationship(
        "QuizOption", back_populates="question", cascade="all, delete-orphan"
    )
    answers = relationship("UserQuizAnswer", back_populates="question")


class QuizOption(Base):
    __tablename__ = "quiz_options"

    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("quiz_questions.id"), nullable=False)
    option_text = Column(String(200), nullable=False)
    score_value = Column(Integer, default=0)  # 0-3
    order = Column(Integer, default=0)

    # العلاقات
    question = relationship("QuizQuestion", back_populates="options")
    answers = relationship("UserQuizAnswer", back_populates="selected_option")


class QuizSession(Base):
    __tablename__ = "quiz_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_date = Column(DateTime, default=datetime.utcnow)
    is_onboarding = Column(Boolean, default=False)
    total_score = Column(Integer, default=0)
    notes = Column(Text, nullable=True)

    # العلاقات
    user = relationship("User", back_populates="quiz_sessions")
    answers = relationship("UserQuizAnswer", back_populates="session")


class UserQuizAnswer(Base):
    __tablename__ = "user_quiz_answers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_id = Column(Integer, ForeignKey("quiz_sessions.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("quiz_questions.id"), nullable=False)
    selected_option_id = Column(Integer, ForeignKey("quiz_options.id"), nullable=False)
    answered_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User", back_populates="quiz_answers")
    session = relationship("QuizSession", back_populates="answers")
    question = relationship("QuizQuestion", back_populates="answers")
    selected_option = relationship("QuizOption", back_populates="answers")


# أضف هذه العلاقات في class User
User.quiz_sessions = relationship("QuizSession", back_populates="user")
User.quiz_answers = relationship("UserQuizAnswer", back_populates="user")


# ============================================
# نماذج تتبع السكر (Diabetes Tracking Models)
# ============================================


class BloodSugarMeasurement(Base):
    __tablename__ = "blood_sugar_measurements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    measurement_type = Column(
        Enum("fasting", "before_meal", "after_meal", "random", "bedtime"),
        nullable=False,
    )
    value = Column(Float, nullable=False)  # قيمة السكر بالملجم/ديسيلتر
    unit = Column(String(10), default="mg/dL")
    notes = Column(Text, nullable=True)
    measured_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "measurement_type": self.measurement_type,
            "value": self.value,
            "unit": self.unit,
            "notes": self.notes,
            "measured_at": self.measured_at.isoformat() if self.measured_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class DiabetesMedication(Base):
    __tablename__ = "diabetes_medications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    medication_name = Column(String(100), nullable=False)
    dosage = Column(String(50), nullable=False)  # مثال: "500mg"
    frequency = Column(String(50), nullable=False)  # مثال: "مرتين يومياً"
    time_of_day = Column(String(50), nullable=True)  # مثال: "صباحاً، مساءً"
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "medication_name": self.medication_name,
            "dosage": self.dosage,
            "frequency": self.frequency,
            "time_of_day": self.time_of_day,
            "notes": self.notes,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class DiabetesSymptom(Base):
    __tablename__ = "diabetes_symptoms"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    symptom_type = Column(
        Enum("hypoglycemia", "hyperglycemia", "other"), nullable=False
    )
    symptom_name = Column(String(100), nullable=False)  # مثال: "دوخة"، "عطش شديد"
    severity = Column(Enum("mild", "moderate", "severe"), nullable=False)
    notes = Column(Text, nullable=True)
    occurred_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "symptom_type": self.symptom_type,
            "symptom_name": self.symptom_name,
            "severity": self.severity,
            "notes": self.notes,
            "occurred_at": self.occurred_at.isoformat() if self.occurred_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# ============================================
# نموذج التحفيز السلوكي الذكي
# ============================================


class BehavioralNudge(Base):
    __tablename__ = "behavioral_nudges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    nudge_type = Column(
        String(50), nullable=False
    )  # "motivational", "educational", "reminder", "warning", "encouragement", "celebration", "habit_building", "health_insight"
    priority = Column(String(20), nullable=False)  # "low", "medium", "high", "critical"
    context = Column(
        String(50), nullable=False
    )  # "morning_routine", "evening_routine", "activity_tracking", "hydration", "nutrition", "medication", "daily_quiz", "general"
    status = Column(
        String(20), default="pending"
    )  # "pending", "delivered", "action_taken", "dismissed", "expired"
    nudge_metadata = Column(JSON, nullable=True)
    delivered_at = Column(DateTime, nullable=True)
    action_taken_at = Column(DateTime, nullable=True)
    dismissed_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "title": self.title,
            "message": self.message,
            "nudge_type": self.nudge_type,
            "priority": self.priority,
            "context": self.context,
            "status": self.status,
            "metadata": self.nudge_metadata,
            "delivered_at": (
                self.delivered_at.isoformat() if self.delivered_at else None
            ),
            "action_taken_at": (
                self.action_taken_at.isoformat() if self.action_taken_at else None
            ),
            "dismissed_at": (
                self.dismissed_at.isoformat() if self.dismissed_at else None
            ),
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class BehavioralPattern(Base):
    __tablename__ = "behavioral_patterns"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    pattern_id = Column(String(100), nullable=False, unique=True)  # معرف فريد للنمط
    pattern_name = Column(String(200), nullable=False)  # اسم النمط
    pattern_type = Column(
        String(100), nullable=False
    )  # مثال: "low_activity_days", "poor_hydration", "irregular_meals"
    description = Column(Text, nullable=False)
    frequency = Column(Integer, nullable=False)  # عدد مرات تكرار النمط
    severity = Column(String(20), nullable=False)  # "low", "medium", "high"
    confidence_score = Column(
        Float, nullable=False, default=0.0
    )  # درجة الثقة 0.0 - 1.0
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)
    pattern_metadata = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        # استخراج الحقول من pattern_metadata
        metadata = self.pattern_metadata or {}
        triggers = metadata.get("triggers", [])
        insights = metadata.get("insights", {})
        detected_at = metadata.get("detected_at")

        return {
            "id": self.id,
            "user_id": self.user_id,
            "pattern_id": self.pattern_id,
            "pattern_name": self.pattern_name,
            "pattern_type": self.pattern_type,
            "description": self.description,
            "frequency": self.frequency,
            "severity": self.severity,
            "confidence_score": self.confidence_score,
            "triggers": triggers,
            "insights": insights,
            "detected_at": detected_at,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "metadata": metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# ============================================
# نماذج التنبؤ الوقائي
# ============================================


class HealthRisk(Base):
    __tablename__ = "health_risks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    risk_type = Column(
        String(100), nullable=False
    )  # "diabetes", "hypertension", "obesity", etc.
    risk_level = Column(
        String(20), nullable=False
    )  # "low", "medium", "high", "critical"
    probability = Column(Float, nullable=False)  # 0.0 - 1.0
    confidence = Column(Float, nullable=False)  # 0.0 - 1.0
    factors = Column(JSON, nullable=True)  # قائمة عوامل الخطر
    timeframe = Column(
        String(20), nullable=False
    )  # "immediate", "short_term", "medium_term", "long_term"
    description = Column(Text, nullable=False)
    recommendations = Column(JSON, nullable=True)  # قائمة التوصيات
    risk_metadata = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "risk_type": self.risk_type,
            "risk_level": self.risk_level,
            "probability": self.probability,
            "confidence": self.confidence,
            "factors": self.factors,
            "timeframe": self.timeframe,
            "description": self.description,
            "recommendations": self.recommendations,
            "metadata": self.risk_metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class PreventionPlan(Base):
    __tablename__ = "prevention_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    risk_id = Column(Integer, ForeignKey("health_risks.id"), nullable=False)
    plan_name = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    actions = Column(JSON, nullable=True)  # قائمة الإجراءات
    timeline_days = Column(Integer, nullable=False)  # المدة بالأيام
    priority = Column(
        String(20), default="medium"
    )  # "low", "medium", "high", "critical"
    status = Column(
        String(20), default="pending"
    )  # "pending", "in_progress", "completed", "cancelled"
    progress_percentage = Column(Float, default=0.0)  # 0.0 - 100.0
    plan_metadata = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    risk = relationship("HealthRisk")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "risk_id": self.risk_id,
            "plan_name": self.plan_name,
            "description": self.description,
            "actions": self.actions,
            "timeline_days": self.timeline_days,
            "priority": self.priority,
            "status": self.status,
            "progress_percentage": self.progress_percentage,
            "metadata": self.plan_metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


# ============================================
# نماذج الكويز اليومي (Daily Quiz Models)
# ============================================


class DailyQuizQuestion(Base):
    __tablename__ = "daily_quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    question_text = Column(String(500), nullable=False)
    category = Column(
        String(50), nullable=False
    )  # sleep, nutrition, activity, mental, mood, habits
    time_of_day = Column(Enum("morning", "evening", "both"), nullable=False)
    default_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    options = relationship(
        "DailyQuizOption", back_populates="question", cascade="all, delete-orphan"
    )
    answers = relationship("DailyQuizAnswer", back_populates="question")


class DailyQuizOption(Base):
    __tablename__ = "daily_quiz_options"

    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("daily_quiz_questions.id"), nullable=False)
    option_text = Column(String(200), nullable=False)
    score_value = Column(Integer, default=0)  # 1-5
    order = Column(Integer, default=0)

    # العلاقات
    question = relationship("DailyQuizQuestion", back_populates="options")
    answers = relationship("DailyQuizAnswer", back_populates="selected_option")


class DailyQuizSession(Base):
    __tablename__ = "daily_quiz_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_date = Column(Date, default=datetime.utcnow().date)
    time_of_day = Column(String(20), nullable=False)  # "morning", "evening"
    total_score = Column(Integer, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    answers = relationship("DailyQuizAnswer", back_populates="session")


class DailyQuizAnswer(Base):
    __tablename__ = "daily_quiz_answers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_id = Column(Integer, ForeignKey("daily_quiz_sessions.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("daily_quiz_questions.id"), nullable=False)
    selected_option_id = Column(
        Integer, ForeignKey("daily_quiz_options.id"), nullable=False
    )
    answered_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    session = relationship("DailyQuizSession", back_populates="answers")
    question = relationship("DailyQuizQuestion", back_populates="answers")
    selected_option = relationship("DailyQuizOption", back_populates="answers")


# أضف هذه العلاقات في class User
User.daily_quiz_sessions = relationship("DailyQuizSession", back_populates="user")
User.daily_quiz_answers = relationship("DailyQuizAnswer", back_populates="user")


# ============================================
# نماذج المجتمع الصحي (Community Models)
# ============================================


class CommunityPost(Base):
    __tablename__ = "community_posts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    group_id = Column(Integer, ForeignKey("community_groups.id"), nullable=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    post_type = Column(String(50), nullable=False)
    category = Column(
        String(50), nullable=False
    )  # diabetes, nutrition, exercise, mental_health, general
    is_featured = Column(Boolean, default=False)
    is_anonymous = Column(Boolean, default=False)
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    group = relationship("CommunityGroup")
    comments = relationship(
        "CommunityComment", back_populates="post", cascade="all, delete-orphan"
    )
    likes = relationship(
        "CommunityLike", back_populates="post", cascade="all, delete-orphan"
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "group_id": self.group_id,
            "title": self.title,
            "content": self.content,
            "post_type": self.post_type,
            "category": self.category,
            "is_featured": self.is_featured,
            "is_anonymous": self.is_anonymous,
            "likes_count": self.likes_count,
            "comments_count": self.comments_count,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "user_name": self.user.name if self.user else None,
            "group_name": self.group.name if self.group else None,
            "group_icon": self.group.icon if self.group else None,
        }


# backend/models.py - نموذج CommunityComment بدون back_populates معقد


class CommunityComment(Base):
    __tablename__ = "community_comments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    post_id = Column(Integer, ForeignKey("community_posts.id"), nullable=False)
    parent_comment_id = Column(
        Integer, ForeignKey("community_comments.id"), nullable=True
    )
    content = Column(Text, nullable=False)
    likes_count = Column(Integer, default=0)
    is_helpful = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات - بدون back_populates مؤقتاً
    user = relationship("User")  # ✅ بدون back_populates
    post = relationship("CommunityPost", back_populates="comments")
    parent = relationship("CommunityComment", remote_side=[id], backref="replies")

    def to_dict(self):
        # جلب الردود إذا وجدت
        replies_list = []
        if hasattr(self, "replies"):
            for reply in self.replies:
                replies_list.append(
                    {
                        "id": reply.id,
                        "user_id": reply.user_id,
                        "post_id": reply.post_id,
                        "content": reply.content,
                        "parent_comment_id": reply.parent_comment_id,
                        "likes_count": reply.likes_count,
                        "is_helpful": reply.is_helpful,
                        "created_at": (
                            reply.created_at.isoformat() if reply.created_at else None
                        ),
                        "updated_at": (
                            reply.updated_at.isoformat() if reply.updated_at else None
                        ),
                        "user_name": reply.user.name if reply.user else None,
                    }
                )

        return {
            "id": self.id,
            "user_id": self.user_id,
            "post_id": self.post_id,
            "parent_comment_id": self.parent_comment_id,
            "content": self.content,
            "likes_count": self.likes_count,
            "is_helpful": self.is_helpful,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "user_name": self.user.name if self.user else None,
            "replies": replies_list,
        }


# backend/models.py - نموذج CommunityLike


class CommunityLike(Base):
    __tablename__ = "community_likes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    post_id = Column(Integer, ForeignKey("community_posts.id"), nullable=True)
    comment_id = Column(Integer, ForeignKey("community_comments.id"), nullable=True)
    reaction_type = Column(String(50), default="like")  # ✅ أضف هذا السطر
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    post = relationship("CommunityPost")
    comment = relationship("CommunityComment")
    # Constraint: يجب أن يكون هناك إما post_id أو comment_id
    __table_args__ = (
        CheckConstraint(
            "(post_id IS NOT NULL AND comment_id IS NULL) OR (post_id IS NULL AND comment_id IS NOT NULL)"
        ),
    )


# ============================================
# نموذج CommunityGroup
# ============================================


class CommunityGroup(Base):
    __tablename__ = "community_groups"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    icon = Column(String(10), default="👥")
    condition_tag = Column(
        String(50), nullable=False, index=True
    )  # diabetes, heart, nutrition, fitness, mental
    members_count = Column(Integer, default=0)
    posts_count = Column(Integer, default=0)
    is_private = Column(Boolean, default=False)
    tags = Column(JSON, default=list)  # List of tags as JSON array
    rules = Column(JSON, default=list)  # List of rules as JSON array
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    # Note: We'll need a separate table for group memberships
    # For now, we'll handle membership through a separate table or API logic

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "icon": self.icon,
            "condition_tag": self.condition_tag,
            "members_count": self.members_count,
            "posts_count": self.posts_count,
            "is_private": self.is_private,
            "tags": self.tags if self.tags else [],
            "rules": self.rules if self.rules else [],
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "is_joined": False,  # Default, will be calculated in API
        }


# ============================================
# نموذج CommunityGroupMember (لعلاقة الأعضاء بالمجموعات)
# ============================================


class CommunityGroupMember(Base):
    __tablename__ = "community_group_members"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    group_id = Column(Integer, ForeignKey("community_groups.id"), nullable=False)
    role = Column(String(20), default="member")  # member, moderator, admin
    joined_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    group = relationship("CommunityGroup")

    # Constraint: unique user-group pair
    __table_args__ = (
        UniqueConstraint("user_id", "group_id", name="unique_user_group"),
    )


# أضف هذه العلاقات في class User
User.community_posts = relationship("CommunityPost", back_populates="user")
User.community_comments = relationship("CommunityComment", back_populates="user")
User.community_likes = relationship("CommunityLike", back_populates="user")
User.community_group_members = relationship(
    "CommunityGroupMember", back_populates="user"
)


# ============================================
# نظام الأهداف الديناميكية (Dynamic Targets)
# ============================================


class DynamicDailyTarget(Base):
    """الأهداف اليومية الديناميكية - تتغير يومياً بناءً على الأعراض والأدوية والأداء"""
    __tablename__ = "dynamic_daily_targets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)  # اليوم الذي تطبق فيه هذه الأهداف

    # القيم الأساسية (من NutritionCalculator)
    base_calories = Column(Float, nullable=True)
    base_steps = Column(Float, nullable=True)
    base_water = Column(Float, nullable=True)  # لتر
    base_protein = Column(Float, nullable=True)
    base_carbs = Column(Float, nullable=True)
    base_fat = Column(Float, nullable=True)

    # تعديلات التأثير الصحي (نسبة مئوية)
    calories_impact_pct = Column(Float, default=0.0)
    steps_impact_pct = Column(Float, default=0.0)
    water_impact_pct = Column(Float, default=0.0)
    protein_impact_pct = Column(Float, default=0.0)
    carbs_impact_pct = Column(Float, default=0.0)
    fat_impact_pct = Column(Float, default=0.0)

    # عامل التكيف مع الأداء (0.85-1.15)
    performance_factor = Column(Float, default=1.0)

    # عامل اتجاه الوزن
    weight_trend_factor = Column(Float, default=1.0)

    # الأهداف الديناميكية النهائية (المحسوبة)
    target_calories = Column(Float, nullable=True)
    target_steps = Column(Float, nullable=True)
    target_water = Column(Float, nullable=True)  # لتر
    target_protein = Column(Float, nullable=True)
    target_carbs = Column(Float, nullable=True)
    target_fat = Column(Float, nullable=True)

    # تفاصيل التأثير (JSON)
    impact_details = Column(JSON, nullable=True)  # تفصيل كل تأثير
    performance_details = Column(JSON, nullable=True)  # تفصيل عامل الأداء

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    # Constraint: هدف واحد فقط لكل يوم لكل مستخدم
    __table_args__ = (
        UniqueConstraint("user_id", "date", name="unique_user_daily_target"),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "date": self.date.isoformat() if self.date else None,
            "base_calories": self.base_calories,
            "base_steps": self.base_steps,
            "base_water": self.base_water,
            "base_protein": self.base_protein,
            "base_carbs": self.base_carbs,
            "base_fat": self.base_fat,
            "calories_impact_pct": self.calories_impact_pct,
            "steps_impact_pct": self.steps_impact_pct,
            "water_impact_pct": self.water_impact_pct,
            "protein_impact_pct": self.protein_impact_pct,
            "carbs_impact_pct": self.carbs_impact_pct,
            "fat_impact_pct": self.fat_impact_pct,
            "performance_factor": self.performance_factor,
            "weight_trend_factor": self.weight_trend_factor,
            "target_calories": self.target_calories,
            "target_steps": self.target_steps,
            "target_water": self.target_water,
            "target_protein": self.target_protein,
            "target_carbs": self.target_carbs,
            "target_fat": self.target_fat,
            "impact_details": self.impact_details,
            "performance_details": self.performance_details,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class PerformanceHistory(Base):
    """سجل أداء المستخدم اليومي - يُستخدم لحساب عامل التكيف"""
    __tablename__ = "performance_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)

    # نسب الالتزام (0.0-1.0)
    calories_adherence = Column(Float, nullable=True)  # الفعلي / الهدف
    steps_adherence = Column(Float, nullable=True)  # الفعلي / الهدف
    water_adherence = Column(Float, nullable=True)  # الفعلي / الهدف
    medication_adherence = Column(Float, nullable=True)  # الجرعات المأخوذة / الكلية

    # درجة الأداء العامة (متوسط مرجح)
    overall_score = Column(Float, nullable=True)

    # تفاصيل إضافية
    actual_calories = Column(Float, nullable=True)
    actual_steps = Column(Float, nullable=True)
    actual_water = Column(Float, nullable=True)
    target_calories = Column(Float, nullable=True)
    target_steps = Column(Float, nullable=True)
    target_water = Column(Float, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    # Constraint: سجل واحد فقط لكل يوم لكل مستخدم
    __table_args__ = (
        UniqueConstraint("user_id", "date", name="unique_user_daily_performance"),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "date": self.date.isoformat() if self.date else None,
            "calories_adherence": self.calories_adherence,
            "steps_adherence": self.steps_adherence,
            "water_adherence": self.water_adherence,
            "medication_adherence": self.medication_adherence,
            "overall_score": self.overall_score,
            "actual_calories": self.actual_calories,
            "actual_steps": self.actual_steps,
            "actual_water": self.actual_water,
            "target_calories": self.target_calories,
            "target_steps": self.target_steps,
            "target_water": self.target_water,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class AchievementMilestone(Base):
    """إنجازات المستخدم - نظام التحفيز والمكافآت"""
    __tablename__ = "achievement_milestones"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    milestone_type = Column(String(50), nullable=False)  # "streak", "adherence", "target_increase", "weight_goal", "water_goal", "steps_goal"
    milestone_value = Column(Float, nullable=True)  # قيمة الإنجاز (مثلاً 7 للأيام المتتالية)
    milestone_key = Column(String(100), nullable=False)  # مفتاح فريد مثل "streak_7"
    description = Column(Text, nullable=True)  # وصف الإنجاز
    icon = Column(String(50), nullable=True)  # emoji أو اسم الأيقونة
    points = Column(Integer, default=0)  # نقاط التحفيز

    achieved_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    # Constraint: إنجاز فريد لكل نوع لكل مستخدم
    __table_args__ = (
        UniqueConstraint("user_id", "milestone_key", name="unique_user_milestone"),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "milestone_type": self.milestone_type,
            "milestone_value": self.milestone_value,
            "milestone_key": self.milestone_key,
            "description": self.description,
            "icon": self.icon,
            "points": self.points,
            "achieved_at": self.achieved_at.isoformat() if self.achieved_at else None,
        }


class SmartNotification(Base):
    """إشعارات ذكية - مرتبطة بالأهداف الديناميكية والتحفيز"""
    __tablename__ = "smart_notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notification_type = Column(
        String(50), nullable=False
    )  # "dynamic_target_update", "milestone", "motivation", "health_alert", "progress_update", "weekly_report"
    priority = Column(
        String(20), default="info"
    )  # "urgent", "important", "info", "encouragement"

    # المحتوى
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    context = Column(JSON, nullable=True)  # سبب الإشعار (JSON)

    # مرجع الأهداف الديناميكية
    target_date = Column(Date, nullable=True)  # يوم الأهداف المرتبط
    related_target_type = Column(String(20), nullable=True)  # "calories", "steps", "water", "medication", "all"

    # التسليم
    scheduled_time = Column(DateTime, nullable=True)  # وقت الإرسال المخطط
    sent_at = Column(DateTime, nullable=True)  # وقت الإرسال الفعلي
    read_at = Column(DateTime, nullable=True)  # وقت القراءة
    action_taken = Column(Boolean, default=False)  # هل تفاعل المستخدم؟

    # تتبع الأثر
    impact_on_adherence = Column(Float, nullable=True)  # هل الإشعار حسّن الالتزام؟

    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    user = relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "notification_type": self.notification_type,
            "priority": self.priority,
            "title": self.title,
            "message": self.message,
            "context": self.context,
            "target_date": self.target_date.isoformat() if self.target_date else None,
            "related_target_type": self.related_target_type,
            "scheduled_time": self.scheduled_time.isoformat() if self.scheduled_time else None,
            "sent_at": self.sent_at.isoformat() if self.sent_at else None,
            "read_at": self.read_at.isoformat() if self.read_at else None,
            "action_taken": self.action_taken,
            "impact_on_adherence": self.impact_on_adherence,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# أضف علاقات المستخدم مع النظام الديناميكى
User.dynamic_targets = relationship("DynamicDailyTarget", back_populates="user", cascade="all, delete-orphan")
User.performance_history = relationship("PerformanceHistory", back_populates="user", cascade="all, delete-orphan")
User.achievements = relationship("AchievementMilestone", back_populates="user", cascade="all, delete-orphan")
User.smart_notifications = relationship("SmartNotification", back_populates="user", cascade="all, delete-orphan")


# ============================================
# نموذج خطط الأنشطة (Activity Plan Model)
# ============================================


class ActivityPlan(Base):
    """خطط الأنشطة - خطط أسبوعية/شهرية/مخصصة للأنشطة"""
    __tablename__ = "activity_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    plan_type = Column(String(20), nullable=False)  # "weekly", "monthly", "custom"
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    progress_percentage = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    activity_count = Column(Integer, default=0)
    completed_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # العلاقات
    user = relationship("User")
    activities = relationship("Activity", back_populates="plan")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "description": self.description or "",
            "plan_type": self.plan_type,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "progress_percentage": self.progress_percentage,
            "is_active": self.is_active,
            "activity_count": self.activity_count,
            "completed_count": self.completed_count,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
