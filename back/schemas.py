# backend/schemas.py

from pydantic import BaseModel, Field, field_validator, EmailStr
from typing import List, Optional, Dict, Any
from datetime import date, datetime
import json
import re

# ============================================
# نماذج المستخدم
# ============================================


class UserBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone: Optional[str] = None
    birth_date: date
    gender: str

    @field_validator("phone")
    def validate_phone(cls, v):
        if v and not re.match(r"^01[0-9]{9}$", v):
            raise ValueError("رقم الهاتف يجب أن يكون 11 رقمًا ويبدأ بـ 01")
        return v

    @field_validator("gender")
    def validate_gender(cls, v):
        if v not in ["ذكر", "أنثى"]:
            raise ValueError('الجنس يجب أن يكون "ذكر" أو "أنثى"')
        return v


class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=50)


class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone: Optional[str] = None
    birth_date: Optional[date] = None
    gender: Optional[str] = None

    @field_validator("phone")
    def validate_phone(cls, v):
        if v and not re.match(r"^01[0-9]{9}$", v):
            raise ValueError("رقم الهاتف يجب أن يكون 11 رقمًا ويبدأ بـ 01")
        return v

    @field_validator("gender")
    def validate_gender(cls, v):
        if v and v not in ["ذكر", "أنثى"]:
            raise ValueError('الجنس يجب أن يكون "ذكر" أو "أنثى"')
        return v


class UserResponse(UserBase):
    id: int
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================
# نماذج التوكن
# ============================================


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    user: UserResponse


class TokenData(BaseModel):
    user_id: Optional[int] = None


# ============================================
# نماذج تسجيل الدخول
# ============================================


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ============================================
# نماذج تغيير كلمة المرور
# ============================================


class ChangePassword(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6, max_length=50)
    confirm_password: str

    @field_validator("confirm_password")
    def passwords_match(cls, v, values):
        if "new_password" in values and v != values["new_password"]:
            raise ValueError("كلمة المرور غير متطابقة")
        return v


# ============================================
# Weight History Schemas
# ============================================
class WeightHistoryResponse(BaseModel):
    id: int
    user_nutrition_id: int
    weight: float
    date: date
    notes: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================
# Medicine Schemas (للقراءة فقط)
# ============================================
class MedicineInfo(BaseModel):
    id: int
    name_ar: str
    name_en: Optional[str] = None
    generic_name: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    uses: List[str] = []
    side_effects: List[str] = []
    warnings: List[str] = []
    interactions: List[str] = []
    dosage_info: Optional[str] = None
    how_to_take: Optional[str] = None
    storage: Optional[str] = None
    image_url: Optional[str] = None

    class Config:
        from_attributes = True


# ============================================
# Medication Schemas (أدوية المستخدم)
# ============================================
class MedicationBase(BaseModel):
    medicine_id: int
    times_per_day: int
    times: List[str]
    with_food: bool = True
    start_date: date
    end_date: Optional[date] = None
    notes: Optional[str] = None

    @field_validator("times", mode="before")
    @classmethod
    def validate_times(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except:
                return []
        return v


class MedicationCreate(MedicationBase):
    pass


class MedicationUpdate(MedicationBase):
    pass


class MedicationResponse(MedicationBase):
    id: int
    medicine_info: Optional[MedicineInfo] = None
    taken_today: Optional[int] = 0

    class Config:
        from_attributes = True


# ============================================
# Dose Schemas
# ============================================
class DoseBase(BaseModel):
    medication_id: int
    scheduled_time: datetime
    taken_time: Optional[datetime] = None
    status: str = "pending"


class DoseCreate(DoseBase):
    pass


class DoseResponse(DoseBase):
    id: int
    user_id: int
    medication_name: Optional[str] = None
    dose: Optional[str] = None

    class Config:
        from_attributes = True


# ============================================
# Symptom Schemas
# ============================================
class SymptomBase(BaseModel):
    name: str
    icon: str = "🤒"
    severity: str
    date_time: datetime
    notes: Optional[str] = ""
    analysis: Optional[str] = ""
    possible_causes: Optional[List[str]] = []
    suggested_actions: Optional[List[str]] = []
    warning_signs: Optional[List[str]] = []


class SymptomCreate(SymptomBase):
    user_id: int


class SymptomUpdate(BaseModel):
    name: Optional[str] = None
    icon: Optional[str] = None
    severity: Optional[str] = None
    notes: Optional[str] = None
    analysis: Optional[str] = None


class FoodRecommendationsResponse(BaseModel):
    foods_to_eat: List[str] = []
    foods_to_avoid: List[str] = []
    drinks_recommended: List[str] = []
    drinks_to_avoid: List[str] = []
    general_tips: Optional[str] = None


class SymptomResponse(SymptomBase):
    id: int
    user_id: int
    created_at: datetime
    food_recommendations: Optional[FoodRecommendationsResponse] = None

    class Config:
        from_attributes = True


# ============================================
# Food Schemas
# ============================================
class FoodBase(BaseModel):
    name: str
    name_en: Optional[str] = None
    calories: float
    protein: float = 0
    carbs: float = 0
    fat: float = 0
    fiber: float = 0
    unit: str = "100 جرام"
    category: str
    icon: str = "🍽️"
    suitable_for: List[str] = []
    is_recommended: bool = False
    glycemic_index: Optional[int] = None


class FoodResponse(FoodBase):
    id: int

    class Config:
        from_attributes = True


# ============================================
# Meal Schemas
# ============================================
class MealFoodItem(BaseModel):
    food_id: int
    quantity: float
    unit: str


class MealFoodCreate(BaseModel):
    food_id: int
    quantity: float = 1.0
    unit: str = "جرام"
    name: Optional[str] = None
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None

    class Config:
        from_attributes = True


class MealCreate(BaseModel):
    user_id: int
    type: str
    date_time: datetime
    notes: Optional[str] = None
    foods: List[MealFoodCreate]


class MealFoodResponse(BaseModel):
    food: FoodResponse
    quantity: float
    unit: str


class MealResponse(BaseModel):
    id: int
    type: str
    date_time: datetime
    notes: Optional[str]
    total_calories: float
    total_protein: float
    total_carbs: float
    total_fat: float
    foods: List[MealFoodResponse]

    class Config:
        from_attributes = True


# ============================================
# Meal Suggestion Schemas
# ============================================
class MealSuggestionBase(BaseModel):
    name: str
    description: Optional[str] = None
    type: Optional[str] = None
    goal: Optional[str] = None
    calories: Optional[int] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    suitable_for: List[str] = []
    ingredients: List[str] = []
    preparation: Optional[str] = None
    image_url: Optional[str] = None


class MealSuggestionResponse(MealSuggestionBase):
    id: int

    class Config:
        from_attributes = True


# ============================================
# User Nutrition Schemas (معدل)
# ============================================
class UserNutritionBase(BaseModel):
    weight: float
    height: float
    age: int
    gender: str
    goal: str
    activity_level: str
    weight_loss_rate: float = 0.5  # ✅ changed from str to float
    target_weight: Optional[float] = None
    diseases: List[str] = []
    initial_weight: Optional[float] = None
    target_weeks: Optional[int] = None


class UserNutritionCreate(UserNutritionBase):
    user_id: int


class UserNutritionResponse(UserNutritionBase):
    id: int
    user_id: int
    bmr: float
    tdee: float
    target_calories: float
    daily_steps_goal: int
    water_intake: float
    target_protein: Optional[float] = None
    target_carbs: Optional[float] = None
    target_fat: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Daily Summary Schema
# ============================================
class DailySummaryResponse(BaseModel):
    date: date
    total_calories: float
    total_protein: float
    total_carbs: float
    total_fat: float
    meals_count: int
    water_intake: float
    meals: List[MealResponse]


# ============================================
# Activity Statistics Schemas
# ============================================
class DailyStatsResponse(BaseModel):
    date: str
    total_activities: int
    completed_activities: int
    completion_rate: float
    work_hours: float
    study_hours: float
    exercise_minutes: int
    activities_by_category: Dict[str, int]

    class Config:
        from_attributes = True


class WeeklyStatsResponse(BaseModel):
    week_start: str
    week_end: str
    total_activities: int
    completed_activities: int
    completion_rate: float
    daily_stats: List[Dict[str, Any]]

    class Config:
        from_attributes = True


class MonthlyStatsResponse(BaseModel):
    month: str
    total_activities: int
    completed_activities: int
    completion_rate: float
    categories: Dict[str, int]

    class Config:
        from_attributes = True


# ============================================
# Analysis Type Schemas
# ============================================
class AnalysisTypeBase(BaseModel):
    name_ar: str
    name_en: str
    category: str
    description: Optional[str] = None
    preparation_instructions: Optional[str] = None
    normal_range_text: Optional[str] = None
    icon_code: Optional[str] = "🔬"


class AnalysisTypeCreate(AnalysisTypeBase):
    pass


class AnalysisTypeResponse(AnalysisTypeBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Test Indicator Schemas
# ============================================
class TestIndicatorBase(BaseModel):
    analysis_type_id: int
    name_ar: str
    name_en: str
    unit: Optional[str] = None
    normal_range_min: Optional[float] = None
    normal_range_max: Optional[float] = None
    critical_low: Optional[float] = None
    critical_high: Optional[float] = None
    gender_specific: str = "both"
    age_group: Optional[str] = None
    display_order: int = 0


class TestIndicatorCreate(TestIndicatorBase):
    pass


class TestIndicatorResponse(TestIndicatorBase):
    id: int

    class Config:
        from_attributes = True


# ============================================
# Health Tip Schemas
# ============================================
class HealthTipBase(BaseModel):
    tip_category: str
    related_analysis_type_id: Optional[int] = None
    related_indicator_id: Optional[int] = None
    condition_type: str = "always"
    severity: str = "info"
    title_ar: str
    title_en: str
    tip_text_ar: str
    tip_text_en: str
    recommendations_ar: Optional[str] = None
    recommendations_en: Optional[str] = None
    icon_code: str = "💡"
    priority: int = 0
    is_active: bool = True


class HealthTipCreate(HealthTipBase):
    pass


class HealthTipResponse(HealthTipBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================
# User Analysis History Schemas
# ============================================
class UserAnalysisHistoryBase(BaseModel):
    user_id: int
    analysis_type_id: int
    file_name: Optional[str] = None
    file_path: Optional[str] = None
    extracted_text: Optional[str] = None
    analysis_date: date
    notes: Optional[str] = None


class UserAnalysisHistoryCreate(UserAnalysisHistoryBase):
    pass


class UserAnalysisHistoryResponse(UserAnalysisHistoryBase):
    id: int
    created_at: datetime
    analysis_type: Optional[AnalysisTypeResponse] = None
    results: List["UserTestResultResponse"] = []

    class Config:
        from_attributes = True


# ============================================
# User Test Result Schemas
# ============================================
class UserTestResultBase(BaseModel):
    history_id: int
    indicator_id: int
    value: float
    unit: Optional[str] = None
    status: str
    notes: Optional[str] = None


class UserTestResultCreate(UserTestResultBase):
    pass


class TestResultEvaluate(BaseModel):
    history_id: int
    indicator_id: int
    value: float
    unit: Optional[str] = None
    notes: Optional[str] = None


class UserTestResultResponse(UserTestResultBase):
    id: int
    created_at: datetime
    indicator: Optional[TestIndicatorResponse] = None
    tips: List[HealthTipResponse] = []

    class Config:
        from_attributes = True


# ============================================
# Notification Schemas
# ============================================


class NotificationLogCreate(BaseModel):
    user_id: int
    notification_type: str
    notification_subtype: Optional[str] = None
    title: str
    body: str
    scheduled_time: datetime
    extra_data: Optional[dict] = None


class NotificationLogResponse(BaseModel):
    id: int
    user_id: int
    notification_type: str
    notification_subtype: Optional[str] = None
    title: str
    body: str
    scheduled_time: datetime
    sent_time: Optional[datetime] = None
    delivered: bool = False
    action_taken: Optional[str] = None
    action_time: Optional[datetime] = None
    extra_data: Optional[dict] = None
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationActionUpdate(BaseModel):
    action_taken: str  # taken, completed, snoozed, dismissed, ignored
    action_time: datetime


class InstantNotificationRequest(BaseModel):
    title: str
    body: str
    notification_type: str = "general"
    extra_data: Optional[dict] = None


# ============================================
# Walking Activity Schemas
# ============================================
class WalkingActivityBase(BaseModel):
    steps: int
    distance_km: float = 0
    duration_minutes: int = 0
    calories_burned: int = 0
    activity_date: date
    activity_time: str = "00:00"
    notes: str = ""


class WalkingActivityCreate(WalkingActivityBase):
    pass


class WalkingActivityResponse(WalkingActivityBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Water Schemas
# ============================================
class WaterIntakeBase(BaseModel):
    amount: float
    time: datetime
    notes: Optional[str] = None


class WaterIntakeCreate(WaterIntakeBase):
    user_id: int


class WaterIntakeResponse(WaterIntakeBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class WaterSettingsBase(BaseModel):
    daily_goal: float = 2.5
    reminder_interval: int = 60
    reminder_start: Optional[str] = "08:00"
    reminder_end: Optional[str] = "22:00"
    enable_notifications: bool = True
    cup_size: float = 0.25


class WaterSettingsResponse(WaterSettingsBase):
    id: int
    user_id: int
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Chat QA Schemas
# ============================================
class ChatQABase(BaseModel):
    question: str
    answer: str
    answer_title: Optional[str] = None
    bullets: List[str] = []
    category: str = "عام"
    keywords: List[str] = []
    confidence: float = 1.0
    source: str = "manual"
    usage_count: int = 0
    helpful_count: int = 0
    not_helpful_count: int = 0


class ChatQAResponse(ChatQABase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ChatRequest(BaseModel):
    question: str
    user_id: Optional[int] = None


class ChatResponse(BaseModel):
    success: bool
    source: str
    title: str
    content: str
    bullets: List[str] = []
    confidence: float = 1.0
    message: Optional[str] = None
    qa_id: Optional[int] = None


class FeedbackRequest(BaseModel):
    qa_id: int
    helpful: bool


class QuizOptionBase(BaseModel):
    option_text: str
    score_value: int = 0
    order: int = 0


class QuizOptionCreate(QuizOptionBase):
    pass


class QuizOptionResponse(QuizOptionBase):
    id: int

    class Config:
        from_attributes = True


class QuizQuestionBase(BaseModel):
    question_text: str
    category: str
    default_order: int = 0
    is_active: bool = True


class QuizQuestionCreate(QuizQuestionBase):
    options: List[QuizOptionCreate] = []


class QuizQuestionResponse(QuizQuestionBase):
    id: int
    options: List[QuizOptionResponse] = []

    class Config:
        from_attributes = True


class QuizAnswerSubmit(BaseModel):
    question_id: int
    selected_option_id: int


class QuizSessionSubmit(BaseModel):
    answers: List[QuizAnswerSubmit]
    is_onboarding: bool = False


class QuizSessionResponse(BaseModel):
    id: int
    session_date: datetime
    is_onboarding: bool
    total_score: int
    category_scores: Optional[Dict[str, int]] = None
    answers: List[Dict] = []

    class Config:
        from_attributes = True


class QuizComparisonResult(BaseModel):
    previous_session_id: int
    current_session_id: int
    previous_date: datetime
    current_date: datetime
    previous_total_score: int
    current_total_score: int
    score_change: int
    score_change_percentage: float
    improved_categories: List[str]
    declined_categories: List[str]
    stable_categories: List[str]
    recommendations: List[str]


# ============================================
# نماذج الكويز اليومي (Daily Quiz Models)
# ============================================


class DailyQuizStatus(BaseModel):
    date: date
    morning_completed: bool
    evening_completed: bool
    morning_completed_at: Optional[datetime] = None
    evening_completed_at: Optional[datetime] = None
    morning_score: Optional[int] = None
    evening_score: Optional[int] = None

    class Config:
        from_attributes = True


class DailyQuizSessionCreate(BaseModel):
    time_of_day: str  # "morning" or "evening"
    answers: Dict[int, int]  # question_id -> option_id
    notes: Optional[str] = None


class DailyQuizSessionResponse(BaseModel):
    id: int
    user_id: int
    session_date: datetime
    time_of_day: str
    total_score: int
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class DailyQuizQuestionResponse(BaseModel):
    id: int
    question_text: str
    category: str
    time_of_day: str  # "morning", "evening", "both"
    default_order: int
    options: List[Dict[str, Any]] = []

    class Config:
        from_attributes = True


# ============================================
# نماذج المجتمع الصحي (Community Models)
# ============================================


class CommunityPostCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=200)
    content: str = Field(..., min_length=10)
    post_type: str = Field(
        ..., pattern="^(question|experience|tip|support|achievement)$"
    )
    category: str = Field(..., min_length=2, max_length=50)
    group_id: Optional[int] = None
    is_anonymous: bool = False
    tags: Optional[List[str]] = []


class CommunityPostResponse(BaseModel):
    id: int
    user_id: int
    title: str
    content: str
    post_type: str
    category: str
    group_id: Optional[int] = None
    group_name: Optional[str] = None
    group_icon: Optional[str] = None
    is_featured: bool = False
    is_pinned: bool = False
    is_anonymous: bool = False
    likes_count: int = 0
    comments_count: int = 0
    views_count: int = 0
    created_at: datetime
    updated_at: Optional[datetime] = None
    author: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True


class CommunityCommentCreate(BaseModel):
    content: str = Field(..., min_length=1)
    parent_comment_id: Optional[int] = None  # ✅ أضف هذا الحقل


# backend/schemas.py - أضف هذه النماذج


class CommunityCommentResponse(BaseModel):
    id: int
    user_id: int
    post_id: int
    content: str
    parent_comment_id: Optional[int] = None
    likes_count: int = 0
    is_helpful: bool = False
    created_at: datetime
    updated_at: Optional[datetime] = None
    author: Optional[Dict[str, Any]] = None
    replies: List[Dict[str, Any]] = []

    class Config:
        from_attributes = True


class CommunityLikeCreate(BaseModel):
    post_id: Optional[int] = None
    comment_id: Optional[int] = None


class CommunityReactionCreate(BaseModel):
    """نموذج إنشاء تفاعل جديد"""

    reaction_type: str = Field(
        default="like", pattern="^(like|love|support|insightful|celebrate)$"
    )


class CommunityStatsResponse(BaseModel):
    total_posts: int
    total_comments: int
    total_likes: int
    featured_posts: int = 0
    user_posts_count: int = 0
    user_comments_count: int = 0
    user_likes_count: int = 0


class CommunityNotificationResponse(BaseModel):
    id: int
    type: str
    message: str
    created_at: datetime
    is_read: bool = False
    data: Optional[Dict[str, Any]] = None


class ReactionStatusResponse(BaseModel):
    has_reacted: bool
    like_id: Optional[int] = None


class ToggleReactionResponse(BaseModel):
    message: str
    likes_count: int
    has_reacted: bool


# backend/schemas.py - أضف هذه النماذج


class CommunityGroupResponse(BaseModel):
    id: int
    name: str
    description: str
    icon: Optional[str] = None
    condition_tag: str
    members_count: int
    posts_count: int
    is_joined: bool
    is_private: bool
    tags: List[str] = []
    rules: Optional[List[str]] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class CommunityGroupDetailResponse(CommunityGroupResponse):
    rules: List[str] = []
    created_at: Optional[datetime] = None


# ============================================
# نماذج الأهداف الديناميكية (Dynamic Targets)
# ============================================


class DynamicDailyTargetResponse(BaseModel):
    """نموذج استجابة الأهداف الديناميكية اليومية"""
    id: int
    user_id: int
    date: date

    # القيم الأساسية
    base_calories: Optional[float] = None
    base_steps: Optional[float] = None
    base_water: Optional[float] = None
    base_protein: Optional[float] = None
    base_carbs: Optional[float] = None
    base_fat: Optional[float] = None

    # تعديلات التأثير الصحي
    calories_impact_pct: float = 0.0
    steps_impact_pct: float = 0.0
    water_impact_pct: float = 0.0
    protein_impact_pct: float = 0.0
    carbs_impact_pct: float = 0.0
    fat_impact_pct: float = 0.0

    # عوامل التكيف
    performance_factor: float = 1.0
    weight_trend_factor: float = 1.0

    # الأهداف النهائية
    target_calories: Optional[float] = None
    target_steps: Optional[float] = None
    target_water: Optional[float] = None
    target_protein: Optional[float] = None
    target_carbs: Optional[float] = None
    target_fat: Optional[float] = None

    # تفاصيل
    impact_details: Optional[Any] = None
    performance_details: Optional[Any] = None

    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    @field_validator("impact_details", mode="before")
    @classmethod
    def parse_impact_details(cls, v):
        """تحويل سلسلة JSON إلى قائمة إذا لزم الأمر"""
        if isinstance(v, str):
            try:
                return json.loads(v)
            except (json.JSONDecodeError, TypeError):
                return []
        return v or []

    @field_validator("performance_details", mode="before")
    @classmethod
    def parse_performance_details(cls, v):
        """تحويل سلسلة JSON إلى قاموس إذا لزم الأمر"""
        if isinstance(v, str):
            try:
                return json.loads(v)
            except (json.JSONDecodeError, TypeError):
                return {}
        return v or {}

    class Config:
        from_attributes = True


class DynamicTargetBreakdownResponse(BaseModel):
    """نموذج تفصيل كيفية حساب الأهداف الديناميكية"""
    target_type: str  # "calories", "steps", "water", "protein", "carbs", "fat"
    base_value: float
    health_impact_adjustment: float  # القيمة المعدلة بالتأثير الصحي
    health_impact_pct: float  # نسبة التغيير
    performance_adjustment: float  # القيمة المعدلة بالأداء
    performance_factor: float
    weight_trend_adjustment: float  # القيمة المعدلة باتجاه الوزن
    weight_trend_factor: float
    final_value: float
    impact_reasons: List[Dict[str, Any]] = []  # أسباب التغيير


class PerformanceHistoryResponse(BaseModel):
    """نموذج استجابة سجل الأداء"""
    id: int
    user_id: int
    date: date

    calories_adherence: Optional[float] = None
    steps_adherence: Optional[float] = None
    water_adherence: Optional[float] = None
    medication_adherence: Optional[float] = None
    overall_score: Optional[float] = None

    actual_calories: Optional[float] = None
    actual_steps: Optional[float] = None
    actual_water: Optional[float] = None
    target_calories: Optional[float] = None
    target_steps: Optional[float] = None
    target_water: Optional[float] = None

    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class PerformanceSummaryResponse(BaseModel):
    """ملخص الأداء لأخر N يوم"""
    period_days: int
    avg_calories_adherence: float
    avg_steps_adherence: float
    avg_water_adherence: float
    avg_medication_adherence: float
    avg_overall_score: float
    performance_factor: float  # عامل التكيف المحسوب
    trend: str  # "improving", "stable", "declining"
    daily_records: List[PerformanceHistoryResponse] = []


class AchievementMilestoneResponse(BaseModel):
    """نموذج استجابة الإنجازات"""
    id: int
    user_id: int
    milestone_type: str
    milestone_value: Optional[float] = None
    milestone_key: str
    description: Optional[str] = None
    icon: Optional[str] = None
    points: int = 0
    achieved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AchievementStatsResponse(BaseModel):
    """إحصائيات الإنجازات"""
    total_points: int
    total_milestones: int
    milestones_by_type: Dict[str, int]
    recent_milestones: List[AchievementMilestoneResponse]
    streak_days: int = 0  # الأيام المتتالية للالتزام


class SmartNotificationResponse(BaseModel):
    """نموذج استجابة الإشعارات الذكية"""
    id: int
    user_id: int
    notification_type: str
    priority: str
    title: str
    message: str
    context: Optional[Dict[str, Any]] = None
    target_date: Optional[date] = None
    related_target_type: Optional[str] = None
    scheduled_time: Optional[datetime] = None
    sent_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    action_taken: bool = False
    impact_on_adherence: Optional[float] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class DynamicTargetComparisonResponse(BaseModel):
    """مقارنة الأهداف الديناميكية مع الأهداف الثابتة"""
    static_calories: Optional[float] = None
    dynamic_calories: Optional[float] = None
    calories_change_pct: Optional[float] = None
    static_steps: Optional[int] = None
    dynamic_steps: Optional[float] = None
    steps_change_pct: Optional[float] = None
    static_water: Optional[float] = None
    dynamic_water: Optional[float] = None
    water_change_pct: Optional[float] = None
    static_protein: Optional[float] = None
    dynamic_protein: Optional[float] = None
    static_carbs: Optional[float] = None
    dynamic_carbs: Optional[float] = None
    static_fat: Optional[float] = None
    dynamic_fat: Optional[float] = None
    change_reasons: List[Dict[str, Any]] = []


class DynamicTargetHistoryResponse(BaseModel):
    """تاريخ الأهداف الديناميكية"""
    targets: List[DynamicDailyTargetResponse]
    period_days: int
    avg_target_calories: float
    avg_target_steps: float
    avg_target_water: float
    calories_trend: str  # "increasing", "stable", "decreasing"
    steps_trend: str
    water_trend: str


# ============================================
# Rebuild models with forward references
# ============================================
UserAnalysisHistoryResponse.model_rebuild()


# ============================================
# نموذج خطط الأنشطة (Activity Plan Schemas)
# ============================================


class ActivityPlanBase(BaseModel):
    """القاعدة الأساسية لخطة النشاط"""
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    plan_type: str = Field(..., pattern="^(weekly|monthly|custom)$")
    start_date: date
    end_date: date
    is_active: bool = True


class ActivityPlanCreate(ActivityPlanBase):
    """إنشاء خطة نشاط جديدة"""
    user_id: int


class ActivityPlanUpdate(BaseModel):
    """تحديث خطة نشاط"""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    plan_type: Optional[str] = Field(None, pattern="^(weekly|monthly|custom)$")
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_active: Optional[bool] = None
    progress_percentage: Optional[float] = Field(None, ge=0.0, le=100.0)
    activity_count: Optional[int] = None
    completed_count: Optional[int] = None


class ActivityPlanResponse(ActivityPlanBase):
    """استجابة خطة النشاط"""
    id: int
    user_id: int
    progress_percentage: float
    activity_count: int
    completed_count: int
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================
# نموذج الإشعارات الذكية (Smart Reminder Schemas)
# ============================================


class SmartNotificationCreate(BaseModel):
    """إنشاء إشعار ذكي جديد"""
    user_id: int
    notification_type: str = Field(..., pattern="^(dynamic_target_update|milestone|motivation|health_alert|progress_update|weekly_report|behavior_reminder|habit_suggestion)$")
    priority: str = Field("info", pattern="^(urgent|important|info|encouragement)$")
    title: str = Field(..., min_length=1, max_length=255)
    message: str = Field(..., min_length=1)
    context: Optional[Dict[str, Any]] = None
    target_date: Optional[date] = None
    related_target_type: Optional[str] = Field(None, pattern="^(calories|steps|water|medication|all)$")
    scheduled_time: Optional[datetime] = None


class SmartNotificationUpdate(BaseModel):
    """تحديث حالة الإشعار الذكي"""
    read_at: Optional[datetime] = None
    action_taken: Optional[bool] = None


# ============================================
# ✅ Activity Exercise Schemas (Phase A - Multi-exercise)
# ============================================


class ActivityExerciseBase(BaseModel):
    """بيانات تمرين فردي مرتبط بنشاط"""
    exercise_id: Optional[str] = None
    exercise_name_ar: Optional[str] = None
    exercise_name_en: Optional[str] = None
    muscle_group: Optional[str] = None
    muscle_group_en: Optional[str] = None
    met_value: Optional[float] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    rest_seconds: Optional[int] = None
    calories_burned: Optional[int] = None
    order_index: Optional[int] = 0


class ActivityExerciseCreate(ActivityExerciseBase):
    """إنشاء تمرين نشاط جديد"""
    pass


class ActivityExerciseUpdate(BaseModel):
    """تحديث تمرين نشاط"""
    exercise_id: Optional[str] = None
    exercise_name_ar: Optional[str] = None
    exercise_name_en: Optional[str] = None
    muscle_group: Optional[str] = None
    muscle_group_en: Optional[str] = None
    met_value: Optional[float] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    rest_seconds: Optional[int] = None
    calories_burned: Optional[int] = None
    order_index: Optional[int] = None


class ActivityExerciseResponse(ActivityExerciseBase):
    """استجابة تمرين نشاط"""
    id: int
    activity_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class ActivityBulkExercisesCreate(BaseModel):
    """استبدال جميع تمارين النشاط (إرسال القائمة الكاملة)"""
    exercises: List[ActivityExerciseCreate]
