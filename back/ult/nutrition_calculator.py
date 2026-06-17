# backend/utils/nutrition_calculator.py

from typing import List, Dict


class NutritionCalculator:
    """حسابات التغذية والصحة"""

    @staticmethod
    def calculate_bmr(weight: float, height: float, age: int, gender: str) -> float:
        """حساب معدل الأيض الأساسي (BMR)"""
        if gender == "ذكر":
            return (10 * weight) + (6.25 * height) - (5 * age) + 5
        else:
            return (10 * weight) + (6.25 * height) - (5 * age) - 161

    @staticmethod
    def calculate_tdee(bmr: float, activity_level: str) -> float:
        """حساب إجمالي الطاقة المستهلكة (TDEE)"""
        multipliers = {"قليل": 1.2, "متوسط": 1.375, "عالي": 1.55, "مكثف": 1.725}
        return bmr * multipliers.get(activity_level, 1.2)

    @staticmethod
    def calculate_target_calories(
        tdee: float, goal: str, weight_loss_rate: str = "0.5"
    ) -> float:
        """حساب السعرات المستهدفة حسب الهدف"""
        if goal == "تخسيس":
            reduction = float(weight_loss_rate) * 1000
            return max(tdee - reduction, 1200)
        elif goal == "زيادة":
            return tdee + 300
        else:  # تثبيت
            return tdee

    @staticmethod
    def calculate_macros(
        calories: float, goal: str, diseases: List[str]
    ) -> Dict[str, float]:
        """حساب توزيع المغذيات"""
        # النسب الأساسية
        ratios = {
            "تخسيس": {"protein": 0.30, "carbs": 0.40, "fat": 0.30},
            "تثبيت": {"protein": 0.25, "carbs": 0.45, "fat": 0.30},
            "زيادة": {"protein": 0.25, "carbs": 0.50, "fat": 0.25},
        }

        protein_ratio = ratios[goal]["protein"]
        carbs_ratio = ratios[goal]["carbs"]
        fat_ratio = ratios[goal]["fat"]

        # تعديل حسب الأمراض
        if "السكري" in diseases:
            protein_ratio += 0.05
            carbs_ratio -= 0.10
            fat_ratio += 0.05

        if "ضغط الدم" in diseases:
            fat_ratio -= 0.05
            protein_ratio += 0.05

        if "الكوليسترول" in diseases:
            fat_ratio -= 0.08
            protein_ratio += 0.05
            carbs_ratio += 0.03

        if "القلب" in diseases:
            fat_ratio -= 0.10
            protein_ratio += 0.05
            carbs_ratio += 0.05

        # ضبط النسب
        total = protein_ratio + carbs_ratio + fat_ratio
        protein_ratio /= total
        carbs_ratio /= total
        fat_ratio /= total

        return {
            "protein": round((calories * protein_ratio) / 4, 1),
            "carbs": round((calories * carbs_ratio) / 4, 1),
            "fat": round((calories * fat_ratio) / 9, 1),
        }

    @staticmethod
    def calculate_water_intake(weight: float, diseases: List[str]) -> float:
        """حساب احتياج الماء اليومي"""
        water = weight * 0.033  # 33 مل لكل كجم

        if "السكري" in diseases:
            water *= 1.2

        if "ضغط الدم" in diseases:
            water *= 1.15

        return round(min(max(water, 1.5), 4.0), 1)

    @staticmethod
    def calculate_daily_steps_goal(
        weight: float, goal: str, activity_level: str
    ) -> int:
        """حساب هدف المشي اليومي"""
        base_steps = {"تخسيس": 8000, "تثبيت": 6000, "زيادة": 4000}.get(goal, 6000)

        if weight > 100:
            base_steps += 2000
        elif weight > 80:
            base_steps += 1000

        activity_multiplier = {"قليل": -1000, "عالي": 2000, "مكثف": 3000}.get(
            activity_level, 0
        )

        return max(min(base_steps + activity_multiplier, 15000), 3000)
