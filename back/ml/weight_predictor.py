# backend/ml/weight_predictor.py

import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from datetime import datetime, timedelta
import joblib
import os
from typing import List, Dict, Tuple

class WeightPredictor:
    """نموذج ML لتوقع الوزن بناءً على البيانات التاريخية"""
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.is_trained = False
        self.model_path = "models/weight_predictor.pkl"
        self.scaler_path = "models/weight_scaler.pkl"
        
    def prepare_features(self, weight_history: List[Dict]) -> np.ndarray:
        """
        تحويل البيانات إلى features مناسبة للنموذج
        """
        features = []
        
        for i in range(len(weight_history) - 1):
            # خذ آخر 7 أيام كـ features
            window = weight_history[max(0, i-6):i+1]
            
            if len(window) >= 3:
                weights = [w['weight'] for w in window]
                dates = [datetime.fromisoformat(w['date']) for w in window]
                
                # حساب الاتجاه (trend) باستخدام الانحدار الخطي البسيط
                if len(weights) >= 2:
                    x = np.arange(len(weights))
                    slope = np.polyfit(x, weights, 1)[0]
                else:
                    slope = 0
                
                # المتوسط والانحراف المعياري
                mean_weight = np.mean(weights)
                std_weight = np.std(weights)
                
                # الفرق بين آخر وزنين
                last_change = weights[-1] - weights[-2] if len(weights) >= 2 else 0
                
                # إجمالي التغير
                total_change = weights[-1] - weights[0] if len(weights) >= 2 else 0
                
                # الوقت بين القراءات
                if len(dates) >= 2:
                    days_diff = (dates[-1] - dates[0]).days
                else:
                    days_diff = 1
                
                features.append([
                    weights[-1],           # آخر وزن
                    mean_weight,           # متوسط الوزن
                    std_weight,            # الانحراف المعياري
                    slope,                 # الاتجاه (ميل الخط)
                    last_change,           # آخر تغيير
                    total_change,          # التغيير الكلي
                    days_diff,             # عدد الأيام
                    len(weights)           # عدد القراءات
                ])
        
        return np.array(features) if features else np.array([])
    
    def train(self, weight_history: List[Dict]):
        """
        تدريب النموذج على البيانات التاريخية
        """
        if len(weight_history) < 10:
            print("⚠️ بيانات غير كافية للتدريب (تحتاج 10 سجلات على الأقل)")
            return False
        
        # تجهيز البيانات
        X = self.prepare_features(weight_history)
        
        if len(X) == 0:
            return False
        
        # الهدف: الوزن بعد أسبوع
        y = []
        for i in range(len(weight_history) - 7):
            if i + 7 < len(weight_history):
                y.append(weight_history[i + 7]['weight'])
        
        # التأكد من تطابق الأطوال
        min_len = min(len(X), len(y))
        X = X[:min_len]
        y = np.array(y[:min_len])
        
        if len(X) < 5:
            return False
        
        # تقسيم البيانات
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # تطبيع البيانات
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # استخدام Random Forest (أفضل من الانحدار الخطي للتغيرات غير الخطية)
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            random_state=42,
            n_jobs=-1
        )
        
        self.model.fit(X_train_scaled, y_train)
        
        # تقييم النموذج
        train_score = self.model.score(X_train_scaled, y_train)
        test_score = self.model.score(X_test_scaled, y_test)
        
        print(f"✅ تم تدريب النموذج")
        print(f"   دقة التدريب: {train_score:.2f}")
        print(f"   دقة الاختبار: {test_score:.2f}")
        
        self.is_trained = True
        
        # حفظ النموذج
        self._save_model()
        
        return True
    
    def predict(self, weight_history: List[Dict], weeks_ahead: int = 4, goal: str = "تخسيس") -> Dict:
        """
        توقع الوزن باستخدام النموذج المدرب
        """
        if len(weight_history) < 5:
            return {
                "success": False,
                "message": "لا توجد بيانات كافية للتوقع (تحتاج 5 سجلات على الأقل)",
                "predicted_weight": weight_history[-1]['weight'] if weight_history else 0,
                "confidence": 0
            }
        
        current_weight = weight_history[-1]['weight']
        
        # إذا لم يكن النموذج مدرباً، استخدم طريقة بسيطة
        if not self.is_trained or len(weight_history) < 10:
            return self._simple_predict(weight_history, weeks_ahead, goal)
        
        # توقع الأسبوع القادم
        predictions = []
        temp_history = weight_history.copy()
        
        for week in range(weeks_ahead):
            # تجهيز features لآخر 7 أيام
            X = self.prepare_features(temp_history)
            
            if len(X) == 0:
                break
            
            # توقع الأسبوع القادم
            X_scaled = self.scaler.transform(X[-1:])
            next_weight = self.model.predict(X_scaled)[0]
            
            predictions.append(next_weight)
            
            # إضافة الوزن المتوقع للتاريخ للمزيد من التوقعات
            last_date = datetime.fromisoformat(temp_history[-1]['date'])
            next_date = (last_date + timedelta(days=7)).isoformat()
            
            temp_history.append({
                'weight': next_weight,
                'date': next_date
            })
        
        predicted_weight = predictions[-1] if predictions else current_weight
        
        # حساب الثقة بناءً على عدد البيانات
        confidence = min(0.95, 0.5 + (len(weight_history) / 100))
        
        # تعديل حسب الهدف
        if goal == "زيادة" and predicted_weight < current_weight:
            # إذا كان التوقع خسارة والهدف زيادة، نعطي تقدير إيجابي
            predicted_weight = current_weight + 0.3 * weeks_ahead
            confidence = 0.6
            message = "⚠️ بناءً على تاريخك، أنت في مرحلة خسارة. لتحقيق هدف الزيادة، تحتاج إلى زيادة سعراتك"
        elif goal == "تخسيس" and predicted_weight > current_weight:
            predicted_weight = current_weight - 0.3 * weeks_ahead
            confidence = 0.6
            message = "⚠️ بناءً على تاريخك، أنت في مرحلة زيادة. لتحقيق هدف التخسيس، تحتاج إلى تقليل سعراتك"
        else:
            if predicted_weight > current_weight:
                message = f"📈 بناءً على تحليل ML، من المتوقع أن يزيد وزنك إلى {predicted_weight:.1f} كجم"
            elif predicted_weight < current_weight:
                message = f"📉 بناءً على تحليل ML، من المتوقع أن ينقص وزنك إلى {predicted_weight:.1f} كجم"
            else:
                message = f"⚖️ بناءً على تحليل ML، من المتوقع أن يثبت وزنك عند {predicted_weight:.1f} كجم"
        
        return {
            "success": True,
            "current_weight": current_weight,
            "predicted_weight": predicted_weight,
            "confidence": confidence,
            "message": message,
            "method": "ml"
        }
    
    def _simple_predict(self, weight_history: List[Dict], weeks_ahead: int = 4, goal: str = "تخسيس") -> Dict:
        """
        طريقة بسيطة للتوقع (بدون ML)
        """
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
        
        # حساب متوسط التغير الأسبوعي
        changes = []
        for i in range(len(weight_history) - 1):
            days_diff = (datetime.fromisoformat(weight_history[i+1]['date']) - 
                        datetime.fromisoformat(weight_history[i]['date'])).days
            weekly_change = (weight_history[i+1]['weight'] - weight_history[i]['weight']) * (7 / max(days_diff, 1))
            changes.append(weekly_change)
        
        avg_weekly_change = np.mean(changes) if changes else 0
        
        # تعديل حسب الهدف
        if goal == "زيادة":
            avg_weekly_change = max(avg_weekly_change, 0.1)
        elif goal == "تخسيس":
            avg_weekly_change = min(avg_weekly_change, -0.1)
        
        predicted_weight = current_weight + (avg_weekly_change * weeks_ahead)
        
        # التأكد من أن الوزن المتوقع منطقي
        predicted_weight = max(30.0, min(predicted_weight, 200.0))
        
        confidence = min(0.7, 0.3 + (len(weight_history) / 50))
        
        return {
            "success": True,
            "current_weight": current_weight,
            "predicted_weight": predicted_weight,
            "confidence": confidence,
            "message": "تقدير مبني على متوسط التغيرات السابقة",
            "method": "simple"
        }
    
    def _save_model(self):
        """حفظ النموذج"""
        try:
            os.makedirs("models", exist_ok=True)
            joblib.dump(self.model, self.model_path)
            joblib.dump(self.scaler, self.scaler_path)
            print("✅ تم حفظ النموذج")
        except Exception as e:
            print(f"⚠️ خطأ في حفظ النموذج: {e}")
    
    def load_model(self):
        """تحميل النموذج المحفوظ"""
        try:
            if os.path.exists(self.model_path) and os.path.exists(self.scaler_path):
                self.model = joblib.load(self.model_path)
                self.scaler = joblib.load(self.scaler_path)
                self.is_trained = True
                print("✅ تم تحميل النموذج المحفوظ")
                return True
        except Exception as e:
            print(f"⚠️ خطأ في تحميل النموذج: {e}")
        return False


# ============================================
# Singleton instance
# ============================================
_weight_predictor = None

def get_weight_predictor() -> WeightPredictor:
    global _weight_predictor
    if _weight_predictor is None:
        _weight_predictor = WeightPredictor()
        _weight_predictor.load_model()
    return _weight_predictor