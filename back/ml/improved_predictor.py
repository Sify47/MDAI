# backend/ml/improved_predictor.py

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import joblib
import os
import json
import warnings
warnings.filterwarnings("ignore")

from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler, RobustScaler
from sklearn.model_selection import train_test_split, TimeSeriesSplit
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

try:
    import xgboost as xgb
    HAS_XGBOOST = True
except ImportError:
    HAS_XGBOOST = False
    print("⚠️ XGBoost not installed, falling back to sklearn models")


class ImprovedWeightPredictor:
    """نموذج ML محسّن لتوقع الوزن مع XGBoost و ensemble learning"""

    def __init__(self):
        self.models = {}  # Multiple models for ensemble
        self.scaler = RobustScaler()  # More robust to outliers
        self.is_trained = False
        self.model_path = "models/improved_weight_predictor.pkl"
        self.scaler_path = "models/improved_weight_scaler.pkl"
        self.feature_importance = {}

    def prepare_features(self, weight_history: List[Dict]) -> np.ndarray:
        """تحويل البيانات إلى features متقدمة"""
        features = []

        for i in range(len(weight_history) - 1):
            window = weight_history[max(0, i - 13):i + 1]  # 2-week window

            if len(window) >= 3:
                weights = [w['weight'] for w in window]
                dates = [datetime.fromisoformat(w['date']) if isinstance(w['date'], str) else w['date'] for w in window]

                # Basic stats
                mean_weight = np.mean(weights)
                std_weight = np.std(weights)
                min_weight = np.min(weights)
                max_weight = np.max(weights)
                weight_range = max_weight - min_weight

                # Trend features
                if len(weights) >= 2:
                    x = np.arange(len(weights))
                    slope, intercept = np.polyfit(x, weights, 1)
                    # R-squared of linear fit (trend strength)
                    y_pred = slope * x + intercept
                    ss_res = np.sum((weights - y_pred) ** 2)
                    ss_tot = np.sum((weights - np.mean(weights)) ** 2)
                    r2_trend = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
                else:
                    slope, r2_trend = 0, 0

                # Recent changes
                last_change_1 = weights[-1] - weights[-2] if len(weights) >= 2 else 0
                last_change_3 = weights[-1] - weights[-4] if len(weights) >= 4 else last_change_1
                last_change_7 = weights[-1] - weights[-8] if len(weights) >= 8 else last_change_3

                # Rate of change
                if len(dates) >= 2:
                    days_diff = (dates[-1] - dates[0]).days
                    daily_rate = (weights[-1] - weights[0]) / max(days_diff, 1)
                    weekly_rate = daily_rate * 7
                else:
                    days_diff = 1
                    weekly_rate = 0

                # Volatility (standard deviation of changes)
                if len(weights) >= 3:
                    changes = np.diff(weights)
                    volatility = np.std(changes)
                else:
                    volatility = 0

                # Momentum (recent trend vs long-term trend)
                if len(weights) >= 7:
                    recent_slope = np.polyfit(np.arange(min(7, len(weights))), weights[-min(7, len(weights)):], 1)[0]
                    momentum = recent_slope - slope
                else:
                    momentum = 0

                # Moving averages
                ma_3 = np.mean(weights[-3:]) if len(weights) >= 3 else weights[-1]
                ma_7 = np.mean(weights[-7:]) if len(weights) >= 7 else weights[-1]

                # Distance from moving averages
                dist_ma3 = weights[-1] - ma_3
                dist_ma7 = weights[-1] - ma_7

                features.append([
                    weights[-1],           # آخر وزن
                    mean_weight,           # متوسط الوزن
                    std_weight,            # الانحراف المعياري
                    min_weight,            # أقل وزن
                    max_weight,            # أعلى وزن
                    weight_range,          # المدى
                    slope,                 # الاتجاه
                    r2_trend,              # قوة الاتجاه
                    last_change_1,         # آخر تغيير (يوم)
                    last_change_3,         # آخر تغيير (3 أيام)
                    last_change_7,         # آخر تغيير (7 أيام)
                    weekly_rate,           # المعدل الأسبوعي
                    volatility,            # التقلب
                    momentum,              # الزخم
                    ma_3,                  # المتوسط المتحرك 3
                    ma_7,                  # المتوسط المتحرك 7
                    dist_ma3,              # المسافة من MA3
                    dist_ma7,              # المسافة من MA7
                    len(weights),          # عدد القراءات
                    days_diff,             # عدد الأيام
                ])

        return np.array(features) if features else np.array([])

    def train(self, weight_history: List[Dict]) -> bool:
        """تدريب ensemble من النماذج"""
        if len(weight_history) < 14:
            print("⚠️ بيانات غير كافية للتدريب (تحتاج 14 سجل على الأقل)")
            return False

        X = self.prepare_features(weight_history)
        if len(X) == 0:
            return False

        # Target: weight 7 days ahead
        y = []
        for i in range(len(weight_history) - 7):
            if i + 7 < len(weight_history):
                y.append(weight_history[i + 7]['weight'])

        min_len = min(len(X), len(y))
        X = X[:min_len]
        y = np.array(y[:min_len])

        if len(X) < 10:
            return False

        # Scale features
        X_scaled = self.scaler.fit_transform(X)

        # Train multiple models for ensemble
        models_to_train = {}

        # 1. Random Forest
        models_to_train['rf'] = RandomForestRegressor(
            n_estimators=200,
            max_depth=12,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1
        )

        # 2. Gradient Boosting
        models_to_train['gb'] = GradientBoostingRegressor(
            n_estimators=150,
            max_depth=5,
            learning_rate=0.05,
            random_state=42
        )

        # 3. XGBoost (if available)
        if HAS_XGBOOST:
            models_to_train['xgb'] = xgb.XGBRegressor(
                n_estimators=200,
                max_depth=6,
                learning_rate=0.05,
                subsample=0.8,
                colsample_bytree=0.8,
                random_state=42,
                verbosity=0
            )

        # 4. Linear Regression (baseline)
        models_to_train['lr'] = LinearRegression()

        # Train and evaluate each model
        scores = {}
        for name, model in models_to_train.items():
            # Time series cross-validation
            tscv = TimeSeriesSplit(n_splits=min(3, len(X_scaled) // 10))
            cv_scores = []

            for train_idx, val_idx in tscv.split(X_scaled):
                X_train, X_val = X_scaled[train_idx], X_scaled[val_idx]
                y_train, y_val = y[train_idx], y[val_idx]

                model.fit(X_train, y_train)
                y_pred = model.predict(X_val)
                cv_scores.append(r2_score(y_val, y_pred))

            scores[name] = np.mean(cv_scores) if cv_scores else 0
            print(f"   {name}: CV R² = {scores[name]:.3f}")

            # Retrain on full data
            model.fit(X_scaled, y)

        self.models = models_to_train
        self.is_trained = True

        # Feature importance (from RF)
        if 'rf' in self.models:
            self.feature_importance = {
                f'feature_{i}': imp
                for i, imp in enumerate(self.models['rf'].feature_importances_)
            }

        # Save models
        self._save_models()

        print(f"✅ Ensemble trained with {len(models_to_train)} models")
        print(f"   Best model: {max(scores, key=scores.get)} (R² = {max(scores.values()):.3f})")

        return True

    def predict(self, weight_history: List[Dict], weeks_ahead: int = 4,
                goal: str = "تخسيس", target_weight: Optional[float] = None) -> Dict:
        """توقع الوزن باستخدام ensemble learning"""
        if len(weight_history) < 3:
            return {
                "success": False,
                "message": "لا توجد بيانات كافية للتوقع (تحتاج 3 سجلات على الأقل)",
                "predicted_weight": weight_history[-1]['weight'] if weight_history else 0,
                "confidence": 0,
                "method": "insufficient_data"
            }

        current_weight = weight_history[-1]['weight']

        if not self.is_trained or len(weight_history) < 14:
            return self._simple_predict(weight_history, weeks_ahead, goal)

        # Ensemble prediction
        predictions = []
        temp_history = weight_history.copy()

        for week in range(weeks_ahead):
            X = self.prepare_features(temp_history)
            if len(X) == 0:
                break

            X_scaled = self.scaler.transform(X[-1:])

            # Ensemble: weighted average of all models
            week_preds = []
            weights = {
                'rf': 0.30,
                'gb': 0.25,
                'xgb': 0.30 if HAS_XGBOOST else 0.0,
                'lr': 0.15 if HAS_XGBOOST else 0.25,
            }

            for name, model in self.models.items():
                pred = model.predict(X_scaled)[0]
                w = weights.get(name, 0.25)
                week_preds.append(pred * w)

            next_weight = sum(week_preds) / sum(weights.values())

            predictions.append(next_weight)

            # Add prediction to history for next iteration
            last_date = weight_history[-1]['date']
            if isinstance(last_date, str):
                last_date = datetime.fromisoformat(last_date)
            next_date = (last_date + timedelta(days=7)).isoformat()

            temp_history.append({
                'weight': next_weight,
                'date': next_date
            })

        predicted_weight = predictions[-1] if predictions else current_weight

        # Calculate confidence based on data quality
        n = len(weight_history)
        confidence = min(0.95, 0.4 + (n / 50) * 0.5)

        # Adjust for goal
        weekly_rate = (predicted_weight - current_weight) / max(weeks_ahead, 1)

        if goal == "زيادة" and weekly_rate < 0:
            predicted_weight = current_weight + 0.3 * weeks_ahead
            confidence = max(0.3, confidence - 0.2)
            message = "⚠️ تاريخك يشير لخسارة وزن. لتحقيق هدف الزيادة، زد سعراتك اليومية 300-500 سعرة"
        elif goal == "تخسيس" and weekly_rate > 0:
            predicted_weight = current_weight - 0.3 * weeks_ahead
            confidence = max(0.3, confidence - 0.2)
            message = "⚠️ تاريخك يشير لزيادة وزن. لتحقيق هدف التخسيس، قلل سعراتك اليومية 300-500 سعرة"
        else:
            direction = "📈 زيادة" if predicted_weight > current_weight else "📉 نقصان" if predicted_weight < current_weight else "⚖️ ثبات"
            change = abs(predicted_weight - current_weight)
            message = f"{direction} متوقع: {predicted_weight:.1f} كجم (تغير {change:.1f} كجم في {weeks_ahead} أسابيع)"

        # Time to reach target
        weeks_to_target = None
        if target_weight and abs(weekly_rate) > 0.01:
            weeks_to_target = abs((target_weight - current_weight) / weekly_rate)

        return {
            "success": True,
            "current_weight": current_weight,
            "predicted_weight": round(predicted_weight, 1),
            "confidence": round(confidence, 2),
            "weeks_ahead": weeks_ahead,
            "weekly_rate": round(abs(weekly_rate), 2),
            "target_weight": target_weight,
            "weeks_to_target": round(weeks_to_target, 1) if weeks_to_target else None,
            "message": message,
            "method": "ensemble_ml",
            "models_used": list(self.models.keys()),
            "predictions_by_week": [round(p, 1) for p in predictions] if predictions else []
        }

    def _simple_predict(self, weight_history: List[Dict], weeks_ahead: int = 4,
                        goal: str = "تخسيس") -> Dict:
        """طريقة بسيطة للتوقع (بدون ML)"""
        current_weight = weight_history[-1]['weight']

        if len(weight_history) < 2:
            return {
                "success": True,
                "current_weight": current_weight,
                "predicted_weight": current_weight,
                "confidence": 0.3,
                "message": "لا توجد بيانات كافية للتوقع الدقيق",
                "method": "simple"
            }

        # Calculate weighted average weekly change (more weight to recent)
        changes = []
        weights_list = []
        for i in range(len(weight_history) - 1):
            d1 = weight_history[i]['date']
            d2 = weight_history[i + 1]['date']
            if isinstance(d1, str): d1 = datetime.fromisoformat(d1)
            if isinstance(d2, str): d2 = datetime.fromisoformat(d2)
            days_diff = (d2 - d1).days
            weekly_change = (weight_history[i + 1]['weight'] - weight_history[i]['weight']) * (7 / max(days_diff, 1))
            changes.append(weekly_change)
            weights_list.append(1 + i * 0.2)  # More weight to recent

        if changes:
            avg_weekly_change = np.average(changes, weights=weights_list)
        else:
            avg_weekly_change = 0

        # Adjust for goal
        if goal == "زيادة":
            avg_weekly_change = max(avg_weekly_change, 0.1)
        elif goal == "تخسيس":
            avg_weekly_change = min(avg_weekly_change, -0.1)

        predicted_weight = current_weight + (avg_weekly_change * weeks_ahead)
        predicted_weight = max(30.0, min(predicted_weight, 200.0))

        confidence = min(0.6, 0.3 + (len(weight_history) / 30))

        return {
            "success": True,
            "current_weight": current_weight,
            "predicted_weight": round(predicted_weight, 1),
            "confidence": round(confidence, 2),
            "weeks_ahead": weeks_ahead,
            "weekly_rate": round(abs(avg_weekly_change), 2),
            "message": "تقدير مبني على متوسط التغيرات السابقة (بيانات غير كافية للنموذج المتقدم)",
            "method": "simple_weighted"
        }

    def _save_models(self):
        """حفظ النماذج"""
        try:
            os.makedirs("models", exist_ok=True)
            save_data = {
                'models': self.models,
                'scaler': self.scaler,
                'feature_importance': self.feature_importance,
                'is_trained': self.is_trained
            }
            joblib.dump(save_data, self.model_path)
            print(f"✅ تم حفظ {len(self.models)} نموذج")
        except Exception as e:
            print(f"⚠️ خطأ في حفظ النماذج: {e}")

    def load_models(self) -> bool:
        """تحميل النماذج المحفوظة"""
        try:
            if os.path.exists(self.model_path):
                save_data = joblib.load(self.model_path)
                self.models = save_data['models']
                self.scaler = save_data['scaler']
                self.feature_importance = save_data['feature_importance']
                self.is_trained = save_data['is_trained']
                print(f"✅ تم تحميل {len(self.models)} نموذج")
                return True
        except Exception as e:
            print(f"⚠️ خطأ في تحميل النماذج: {e}")
        return False


# Singleton
_improved_predictor = None


def get_improved_predictor() -> ImprovedWeightPredictor:
    global _improved_predictor
    if _improved_predictor is None:
        _improved_predictor = ImprovedWeightPredictor()
        _improved_predictor.load_models()
    return _improved_predictor