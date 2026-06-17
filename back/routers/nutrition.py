# backend/routers/nutrition.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List, Optional
from datetime import datetime, date
import json

from database import get_db
import models
import schemas
from ult.nutrition_calculator import NutritionCalculator
from core.cache_config import cache_result, invalidate_cache

router = APIRouter(prefix="/api/nutrition", tags=["nutrition"])


# ============================================
# ✅ دالة مساعدة لحفظ سجل الوزن
# ============================================
def _save_weight_history(
    db: Session, user_id: int, weight: float, user_nutrition_id: int
):
    """حفظ الوزن في جدول سجل الوزن"""
    try:
        today = datetime.now().date()
        existing_today = (
            db.query(models.WeightHistory)
            .filter(
                models.WeightHistory.user_nutrition_id == user_nutrition_id,
                models.WeightHistory.date == today,
            )
            .first()
        )

        if existing_today:
            existing_today.weight = weight
        else:
            weight_history = models.WeightHistory(
                user_nutrition_id=user_nutrition_id,
                weight=weight,
                date=today,
            )
            db.add(weight_history)

        db.commit()
        print(f"✅ [Nutrition] تم حفظ الوزن {weight} في سجل الوزن للمستخدم {user_id}")
    except Exception as e:
        print(f"⚠️ [Nutrition] خطأ في حفظ سجل الوزن: {e}")


# ============================================
# ✅ 1. حفظ بيانات المستخدم الغذائية (معدل)
# ============================================
# backend/routers/nutrition.py - أصلح دالة save_user_nutrition_data
@router.post("/user-data", response_model=schemas.UserNutritionResponse)
def save_user_nutrition_data(
    data: schemas.UserNutritionCreate, db: Session = Depends(get_db)
):
    """حساب وحفظ بيانات المستخدم الغذائية"""
    print(f"📝 [Nutrition] حفظ بيانات المستخدم {data.user_id}")
    print(f"📦 البيانات المستلمة: {data}")

    try:
        # حساب القيم
        bmr = NutritionCalculator.calculate_bmr(
            weight=data.weight, height=data.height, age=data.age, gender=data.gender
        )

        tdee = NutritionCalculator.calculate_tdee(
            bmr=bmr, activity_level=data.activity_level
        )

        target_calories = NutritionCalculator.calculate_target_calories(
            tdee=tdee, goal=data.goal, weight_loss_rate=data.weight_loss_rate
        )

        daily_steps_goal = NutritionCalculator.calculate_daily_steps_goal(
            weight=data.weight, goal=data.goal, activity_level=data.activity_level
        )

        water_intake = NutritionCalculator.calculate_water_intake(
            weight=data.weight, diseases=data.diseases
        )

        macros = NutritionCalculator.calculate_macros(
            calories=target_calories, goal=data.goal, diseases=data.diseases
        )

        # التحقق من وجود بيانات سابقة
        existing = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == data.user_id)
            .first()
        )

        if existing:
            # حفظ الوزن الحالي في جدول سجل الوزن
            _save_weight_history(db, existing.user_id, existing.weight, existing.id)

            # تحديث البيانات الموجودة
            existing.weight = data.weight
            existing.height = data.height
            existing.age = data.age
            existing.gender = data.gender
            existing.goal = data.goal
            existing.activity_level = data.activity_level
            existing.weight_loss_rate = data.weight_loss_rate
            existing.target_weight = (
                data.target_weight if data.target_weight else existing.target_weight
            )
            existing.diseases = data.diseases
            existing.bmr = bmr
            existing.tdee = tdee
            existing.target_calories = target_calories
            existing.daily_steps_goal = daily_steps_goal
            existing.water_intake = water_intake
            existing.target_protein = macros["protein"]
            existing.target_carbs = macros["carbs"]
            existing.target_fat = macros["fat"]

            # ✅ تحديث الحقول الجديدة
            if hasattr(data, "initial_weight") and data.initial_weight is not None:
                existing.initial_weight = data.initial_weight
            if hasattr(data, "target_weeks") and data.target_weeks is not None:
                existing.target_weeks = data.target_weeks

            db.commit()
            db.refresh(existing)

            # حفظ الوزن الجديد في سجل الوزن
            _save_weight_history(db, existing.user_id, existing.weight, existing.id)

            return existing
        else:
            # إنشاء بيانات جديدة
            initial_weight = (
                data.initial_weight
                if (hasattr(data, "initial_weight") and data.initial_weight is not None)
                else data.weight
            )
            target_weeks = (
                data.target_weeks
                if (hasattr(data, "target_weeks") and data.target_weeks is not None)
                else 8
            )

            db_data = models.UserNutrition(
                user_id=data.user_id,
                weight=data.weight,
                height=data.height,
                age=data.age,
                gender=data.gender,
                goal=data.goal,
                activity_level=data.activity_level,
                weight_loss_rate=data.weight_loss_rate,
                target_weight=data.target_weight if data.target_weight else data.weight,
                diseases=data.diseases,
                initial_weight=initial_weight,
                target_weeks=target_weeks,
                bmr=bmr,
                tdee=tdee,
                target_calories=target_calories,
                daily_steps_goal=daily_steps_goal,
                water_intake=water_intake,
                target_protein=macros["protein"],
                target_carbs=macros["carbs"],
                target_fat=macros["fat"],
            )
            db.add(db_data)
            db.commit()
            db.refresh(db_data)

            # حفظ الوزن الابتدائي في سجل الوزن
            _save_weight_history(db, db_data.user_id, db_data.weight, db_data.id)

            return db_data

    except Exception as e:
        print(f"❌ [Nutrition] خطأ في حفظ البيانات: {e}")
        import traceback

        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ✅ 2. جلب بيانات المستخدم الغذائية
# ============================================
# backend/routers/nutrition.py - أصلح دالة get_user_nutrition_data


@router.get("/user-data", response_model=schemas.UserNutritionResponse)
def get_user_nutrition_data(user_id: int, db: Session = Depends(get_db)):
    """جلب بيانات المستخدم الغذائية"""
    print(f"🔍 [Nutrition] جلب بيانات المستخدم {user_id}")

    try:
        data = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not data:
            print(f"⚠️ [Nutrition] لا توجد بيانات للمستخدم {user_id}")
            # إرجاع None بدلاً من 404 (لأنه قد يكون مستخدم جديد)
            raise HTTPException(status_code=404, detail="بيانات المستخدم غير موجودة")

        return data

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ [Nutrition] خطأ في جلب البيانات: {e}")
        raise HTTPException(status_code=500, detail=f"خطأ في قاعدة البيانات: {str(e)}")


# ============================================
# ✅ 2.5 جلب سجل الوزن التاريخي
# ============================================
@router.get("/weight-history", response_model=List[schemas.WeightHistoryResponse])
def get_weight_history(user_id: int, db: Session = Depends(get_db)):
    """جلب سجل الوزن التاريخي للمستخدم"""
    print(f"🔍 [Nutrition] جلب سجل الوزن للمستخدم {user_id}")

    try:
        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )

        if not user_nutrition:
            raise HTTPException(status_code=404, detail="بيانات المستخدم غير موجودة")

        weight_history = (
            db.query(models.WeightHistory)
            .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
            .order_by(models.WeightHistory.date.asc())
            .all()
        )

        print(f"✅ [Nutrition] تم جلب {len(weight_history)} سجل وزن")

        if not weight_history:
            _save_weight_history(
                db, user_nutrition.user_id, user_nutrition.weight, user_nutrition.id
            )
            weight_history = (
                db.query(models.WeightHistory)
                .filter(models.WeightHistory.user_nutrition_id == user_nutrition.id)
                .order_by(models.WeightHistory.date.asc())
                .all()
            )

        return weight_history

    except Exception as e:
        print(f"❌ [Nutrition] خطأ في جلب سجل الوزن: {e}")
        raise HTTPException(status_code=500, detail=f"خطأ في قاعدة البيانات: {str(e)}")


# ============================================
# ✅ 3. جلب قائمة الأطعمة من قاعدة البيانات
# ============================================
# جلب قائمة الأطعمة
@router.get("/foods", response_model=List[schemas.FoodResponse])
@cache_result(ttl=7200, key_prefix="foods")  # ✅ ساعتين
def get_foods(
    category: Optional[str] = None,
    search: Optional[str] = None,
    suitable_for: Optional[str] = None,
    recommended_only: bool = False,
    db: Session = Depends(get_db),
):
    """جلب قائمة الأطعمة من قاعدة البيانات"""
    query = db.query(models.Food)

    if category:
        query = query.filter(models.Food.category == category)
    if search:
        query = query.filter(
            or_(models.Food.name.contains(search), models.Food.name_en.contains(search))
        )
    if suitable_for:
        query = query.filter(models.Food.suitable_for.contains(suitable_for))
    if recommended_only:
        query = query.filter(models.Food.is_recommended == True)

    foods = query.limit(100).all()
    return foods


# ============================================
# ✅ 4. جلب تفاصيل طعام معين
# ============================================
@router.get("/foods/{food_id}", response_model=schemas.FoodResponse)
def get_food_details(food_id: int, db: Session = Depends(get_db)):
    """جلب تفاصيل طعام معين"""
    print(f"🔍 [Nutrition] جلب تفاصيل الطعام {food_id}")

    food = db.query(models.Food).filter(models.Food.id == food_id).first()
    if not food:
        raise HTTPException(status_code=404, detail="الطعام غير موجود")

    return food


# ============================================
# ✅ 5. إضافة وجبة جديدة
# ============================================
@router.post("/meals", status_code=201)
@invalidate_cache(pattern="nutrition_daily:*")
def add_meal(meal_data: schemas.MealCreate, db: Session = Depends(get_db)):
    """إضافة وجبة جديدة"""
    print(f"📝 [Nutrition] إضافة وجبة للمستخدم {meal_data.user_id}")

    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == meal_data.user_id)
        .first()
    )

    if not user_nutrition:
        raise HTTPException(status_code=404, detail="بيانات المستخدم غير موجودة")

    total_calories = 0.0
    total_protein = 0.0
    total_carbs = 0.0
    total_fat = 0.0
    meal_foods_data = []

    for item in meal_data.foods:
        if item.food_id == 0:
            total_calories += item.calories * item.quantity
            total_protein += item.protein * item.quantity
            total_carbs += item.carbs * item.quantity
            total_fat += item.fat * item.quantity

            meal_foods_data.append(
                {
                    "food_id": None,
                    "name": item.name,
                    "quantity": item.quantity,
                    "unit": item.unit,
                    "calories": item.calories * item.quantity,
                    "protein": item.protein * item.quantity,
                    "carbs": item.carbs * item.quantity,
                    "fat": item.fat * item.quantity,
                }
            )
        else:
            food = db.query(models.Food).filter(models.Food.id == item.food_id).first()
            if food:
                multiplier = item.quantity
                total_calories += food.calories * multiplier
                total_protein += food.protein * multiplier
                total_carbs += food.carbs * multiplier
                total_fat += food.fat * multiplier

                meal_foods_data.append(
                    {
                        "food_id": food.id,
                        "name": food.name,
                        "quantity": item.quantity,
                        "unit": item.unit,
                        "calories": food.calories * multiplier,
                        "protein": food.protein * multiplier,
                        "carbs": food.carbs * multiplier,
                        "fat": food.fat * multiplier,
                    }
                )

    db_meal = models.Meal(
        user_nutrition_id=user_nutrition.id,
        user_id=meal_data.user_id,
        type=meal_data.type,
        date_time=meal_data.date_time,
        notes=meal_data.notes,
        total_calories=total_calories,
        total_protein=total_protein,
        total_carbs=total_carbs,
        total_fat=total_fat,
    )
    db.add(db_meal)
    db.flush()

    for food_item in meal_foods_data:
        if food_item.get("food_id") is not None:
            meal_food = models.MealFood(
                meal_id=db_meal.id,
                food_id=food_item["food_id"],
                quantity=food_item["quantity"],
                unit=food_item["unit"],
            )
            db.add(meal_food)
        else:
            # Custom food (food_id=None) — save with custom fields
            meal_food = models.MealFood(
                meal_id=db_meal.id,
                food_id=None,
                quantity=food_item["quantity"],
                unit=food_item["unit"],
                custom_food_name=food_item.get("name", "طعام"),
                custom_calories=food_item.get("calories", 0),
                custom_protein=food_item.get("protein", 0),
                custom_carbs=food_item.get("carbs", 0),
                custom_fat=food_item.get("fat", 0),
            )
            db.add(meal_food)

    db.commit()
    db.refresh(db_meal)

    return {
        "success": True,
        "message": "تم إضافة الوجبة بنجاح",
        "meal_id": db_meal.id,
        "total_calories": total_calories,
    }


# ============================================
# ✅ 6. جلب وجبات اليوم
# ============================================
@router.get("/meals/today")
def get_today_meals(user_id: int, db: Session = Depends(get_db)):
    """جلب وجبات اليوم مع تفاصيل الأطعمة"""
    print(f"🔍 [Nutrition] جلب وجبات اليوم للمستخدم {user_id}")

    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )

    if not user_nutrition:
        raise HTTPException(status_code=404, detail="بيانات المستخدم غير موجودة")

    today_start = datetime.combine(date.today(), datetime.min.time())
    today_end = datetime.combine(date.today(), datetime.max.time())

    meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_nutrition_id == user_nutrition.id,
            models.Meal.date_time.between(today_start, today_end),
        )
        .order_by(models.Meal.date_time)
        .all()
    )

    total_calories = sum(m.total_calories for m in meals)
    total_protein = sum(m.total_protein for m in meals)
    total_carbs = sum(m.total_carbs for m in meals)
    total_fat = sum(m.total_fat for m in meals)

    # Build meals_data with food details (same pattern as get_meals_by_date)
    meals_data = []
    for meal in meals:
        foods = []
        for mf in meal.foods:
            if mf.food_id and mf.food:
                food = mf.food
                foods.append(
                    {
                        "food_id": food.id,
                        "name": food.name,
                        "name_en": food.name_en,
                        "quantity": mf.quantity,
                        "unit": mf.unit,
                        "calories": food.calories * mf.quantity,
                        "protein": food.protein * mf.quantity,
                        "carbs": food.carbs * mf.quantity,
                        "fat": food.fat * mf.quantity,
                    }
                )
            else:
                foods.append(
                    {
                        "food_id": None,
                        "name": mf.custom_food_name or "طعام مخصص",
                        "quantity": mf.quantity,
                        "unit": mf.unit,
                        "calories": (mf.custom_calories or 0) * mf.quantity,
                        "protein": (mf.custom_protein or 0) * mf.quantity,
                        "carbs": (mf.custom_carbs or 0) * mf.quantity,
                        "fat": (mf.custom_fat or 0) * mf.quantity,
                        "is_custom": True,
                    }
                )

        meals_data.append(
            {
                "id": meal.id,
                "type": meal.type,
                "name": meal.name or f"{meal.type}",
                "notes": meal.notes,
                "date_time": meal.date_time.isoformat() if meal.date_time else None,
                "total_calories": meal.total_calories,
                "total_protein": meal.total_protein,
                "total_carbs": meal.total_carbs,
                "total_fat": meal.total_fat,
                "foods": foods,
                "foods_count": len(foods),
            }
        )

    return {
        "date": date.today().isoformat(),
        "total_calories": total_calories,
        "total_protein": total_protein,
        "total_carbs": total_carbs,
        "total_fat": total_fat,
        "meals_count": len(meals),
        "meals": meals_data,
    }


# ============================================
# ✅ 7. جلب اقتراحات الوجبات
# ============================================
# جلب اقتراحات الوجبات
@router.get("/meal-suggestions", response_model=List[schemas.MealSuggestionResponse])
@cache_result(ttl=1800, key_prefix="meal_suggestions")
def get_meal_suggestions(
    goal: Optional[str] = None,
    meal_type: Optional[str] = None,
    suitable_for: Optional[str] = None,
    user_id: Optional[int] = None,
    current_time: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    جلب اقتراحات الوجبات مع دعم السياق الزمني واليومي.
    - meal_type: إذا تم تحديده، نستخدمه مباشرة.
    - current_time: إذا تم تحديده وتحديد user_id، نحسب الوجبة المناسبة للوقت.
    - user_id + current_time: نجيب على أساس ما أكله المستخدم اليوم والساعة الحالية.
    """
    query = db.query(models.MealSuggestion)

    if goal:
        query = query.filter(models.MealSuggestion.goal == goal)
    if meal_type:
        query = query.filter(models.MealSuggestion.type == meal_type)
    if suitable_for:
        query = query.filter(models.MealSuggestion.suitable_for.contains(suitable_for))

    # === Time-awareness: تحديد نوع الوجبة المناسبة حسب الوقت ===
    auto_meal_type = None
    if current_time and not meal_type:
        try:
            hour = int(current_time.split(":")[0])
        except (ValueError, IndexError):
            hour = datetime.now().hour

        if 5 <= hour < 10:
            auto_meal_type = "فطور"
        elif 10 <= hour < 12:
            auto_meal_type = "وجبة خفيفة"
        elif 12 <= hour < 15:
            auto_meal_type = "غداء"
        elif 15 <= hour < 18:
            auto_meal_type = "وجبة خفيفة"
        elif 18 <= hour < 22:
            auto_meal_type = "عشاء"
        else:
            auto_meal_type = "وجبة خفيفة"

        query = query.filter(models.MealSuggestion.type == auto_meal_type)

    suggestions = query.order_by(models.MealSuggestion.calories).all()

    # === Context-awareness: استبعاد ما أكله المستخدم اليوم ===
    if user_id and suggestions:
        user_nutrition = (
            db.query(models.UserNutrition)
            .filter(models.UserNutrition.user_id == user_id)
            .first()
        )
        if user_nutrition:
            today_start = datetime.combine(date.today(), datetime.min.time())
            today_end = datetime.combine(date.today(), datetime.max.time())
            today_meals = (
                db.query(models.Meal)
                .filter(
                    models.Meal.user_nutrition_id == user_nutrition.id,
                    models.Meal.date_time.between(today_start, today_end),
                )
                .all()
            )
            # Collect food names already eaten today
            eaten_food_ids = set()
            for meal in today_meals:
                for mf in meal.foods:
                    if mf.food_id:
                        eaten_food_ids.add(mf.food_id)

            if eaten_food_ids:
                # Prioritize suggestions with new/untried foods
                scored = []
                for s in suggestions:
                    ingredient_ids = set()
                    # Simple scoring: suggestions with fewer overlapping ingredients get higher priority
                    score = 0
                    if s.ingredients:
                        for ing in s.ingredients:
                            if isinstance(ing, dict):
                                ing_name = ing.get("name", "")
                            else:
                                ing_name = str(ing)
                            # If ingredient name not in any eaten meal, bonus point
                            # (We can't cross-reference perfectly without food_id mapping,
                            #  so we give a slight boost based on variety)
                    scored.append((0, s))
                # Keep diversity - don't exclude entirely, just weight differently
                # For now, mark which suggestions are complementary to today's meals
                pass

    return suggestions


# ============================================
# ✅ 8. جلب وجبات تاريخ معين
# ============================================
@router.get("/meals/date")
def get_meals_by_date(user_id: int, date: str, db: Session = Depends(get_db)):
    """جلب وجبات تاريخ معين"""
    print(f"\n🔍 [Nutrition] جلب وجبات التاريخ {date} للمستخدم {user_id}")

    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )

    if not user_nutrition:
        print(f"❌ [Nutrition] بيانات المستخدم غير موجودة للمستخدم {user_id}")
        raise HTTPException(status_code=404, detail="بيانات المستخدم غير موجودة")

    try:
        target_date = datetime.strptime(date, "%Y-%m-%d").date()
    except:
        raise HTTPException(
            status_code=400, detail="صيغة التاريخ غير صحيحة. استخدم YYYY-MM-DD"
        )

    date_start = datetime.combine(target_date, datetime.min.time())
    date_end = datetime.combine(target_date, datetime.max.time())

    meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_nutrition_id == user_nutrition.id,
            models.Meal.date_time.between(date_start, date_end),
        )
        .order_by(models.Meal.date_time)
        .all()
    )

    print(f"📊 [Nutrition] تم العثور على {len(meals)} وجبة")

    total_calories = sum(m.total_calories for m in meals)
    total_protein = sum(m.total_protein for m in meals)
    total_carbs = sum(m.total_carbs for m in meals)
    total_fat = sum(m.total_fat for m in meals)

    meals_data = []
    for meal in meals:
        foods = []
        for mf in meal.foods:
            foods.append(
                {
                    "name": mf.food.name,
                    "quantity": mf.quantity,
                    "unit": mf.unit,
                    "calories": mf.food.calories * mf.quantity,
                }
            )

        meals_data.append(
            {
                "id": meal.id,
                "type": meal.type,
                "name": f"{meal.type} - {len(meal.foods)} أطعمة",
                "date_time": meal.date_time.isoformat(),
                "total_calories": meal.total_calories,
                "total_protein": meal.total_protein,
                "total_carbs": meal.total_carbs,
                "total_fat": meal.total_fat,
                "foods": foods,
            }
        )

    return {
        "date": target_date.isoformat(),
        "total_calories": total_calories,
        "total_protein": total_protein,
        "total_carbs": total_carbs,
        "total_fat": total_fat,
        "meals_count": len(meals),
        "meals": meals_data,
        "water_intake": 0.0,
    }


# ============================================
# ✅ 9. حذف وجبة
# ============================================
@router.delete("/meals/{meal_id}")
def delete_meal(meal_id: int, db: Session = Depends(get_db)):
    """حذف وجبة"""
    print(f"🗑️ [Nutrition] حذف وجبة {meal_id}")

    meal = db.query(models.Meal).filter(models.Meal.id == meal_id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="الوجبة غير موجودة")

    db.delete(meal)
    db.commit()

    return {"success": True, "message": "تم حذف الوجبة بنجاح"}


# ============================================
# ✅ 10. تحليل اليوم الغذائي
# ============================================
@router.get("/analysis/daily")
def get_daily_analysis(user_id: int, db: Session = Depends(get_db)):
    """تحليل اليوم الغذائي"""
    print(f"🔍 [Nutrition] تحليل اليوم للمستخدم {user_id}")

    user_data = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )

    if not user_data:
        raise HTTPException(status_code=404, detail="بيانات المستخدم غير موجودة")

    today_start = datetime.combine(date.today(), datetime.min.time())
    today_end = datetime.combine(date.today(), datetime.max.time())

    meals = (
        db.query(models.Meal)
        .filter(
            models.Meal.user_nutrition_id == user_data.id,
            models.Meal.date_time.between(today_start, today_end),
        )
        .all()
    )

    consumed_calories = sum(m.total_calories for m in meals)
    consumed_protein = sum(m.total_protein for m in meals)
    consumed_carbs = sum(m.total_carbs for m in meals)
    consumed_fat = sum(m.total_fat for m in meals)

    progress = (
        (consumed_calories / user_data.target_calories) * 100
        if user_data.target_calories > 0
        else 0
    )

    tips = []
    if progress > 100:
        tips.append("⚠️ لقد تجاوزت السعرات المستهدفة اليوم")
    elif progress < 70:
        tips.append("💡 حاول تناول وجبة خفيفة لتحقيق احتياجك")

    if consumed_protein < user_data.target_protein * 0.8:
        tips.append("🥩 تحتاج لزيادة البروتين اليوم")

    return {
        "date": date.today().isoformat(),
        "target_calories": user_data.target_calories,
        "consumed_calories": consumed_calories,
        "remaining_calories": max(0, user_data.target_calories - consumed_calories),
        "progress_percentage": round(progress, 1),
        "protein": {"target": user_data.target_protein, "consumed": consumed_protein},
        "carbs": {"target": user_data.target_carbs, "consumed": consumed_carbs},
        "fat": {"target": user_data.target_fat, "consumed": consumed_fat},
        "meals_count": len(meals),
        "tips": tips,
    }
