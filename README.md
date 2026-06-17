# VITA — Comprehensive Health Management Platform

**VITA** is a full-stack health management platform built with Flutter (frontend) and FastAPI (backend). It provides a rich, interactive experience for tracking medications, nutrition, symptoms, activities, water intake, weight, diabetes, and more — powered by AI-driven insights, behavioral nudges, and dynamic daily targets.

> **Project Name:** VITA (formerly Health Mate)  
> **Frontend:** Flutter 3.10+ / Dart 3.10+  
> **Backend:** Python 3.9+ / FastAPI  
> **Database:** MySQL (via SQLAlchemy ORM)  
> **AI/ML:** XGBoost, Google Generative AI, scikit-learn

---

## 📋 Table of Contents

- [🌟 Key Features](#-key-features)
- [🏗️ System Architecture](#️-system-architecture)
- [📱 Frontend (Flutter)](#-frontend-flutter)
- [⚙️ Backend (FastAPI)](#️-backend-fastapi)
- [🗄️ Database Models](#️-database-models)
- [🌐 API Endpoints](#-api-endpoints)
- [🤖 AI & Machine Learning](#-ai--machine-learning)
- [📦 Installation](#-installation)
- [🧪 Testing](#-testing)
- [📈 Performance Metrics](#-performance-metrics)
- [📁 Project Structure](#-project-structure)
- [🎯 Development Roadmap](#-development-roadmap)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 🌟 Key Features

### 🩺 Health Tracking
| Feature | Description |
|---------|-------------|
| **Medication Management** | Add, track, and log doses with smart reminders and adherence statistics |
| **Symptom Tracking** | Log symptoms with severity, AI-powered analysis, causes, and food recommendations |
| **Weight Tracking** | Record weight history with XGBoost-based predictions and trend analysis |
| **Blood Pressure & Sugar** | Dedicated dashboards for pressure and sugar readings with analysis |
| **Diabetes Management** | Track medications, symptoms, and get AI-powered insights |

### 🏃 Activity & Fitness
| Feature | Description |
|---------|-------------|
| **Walking Tracker** | Pedometer integration, step goals, distance, calories, challenges |
| **Activity Management** | Categorised activities (work, study, exercise) with completion tracking |
| **Activity Plans** | Weekly/monthly/custom plans with progress tracking |
| **Dynamic Daily Targets** | AI-adjusted daily goals for calories, steps, water, protein, carbs, fat |

### 🥗 Nutrition
| Feature | Description |
|---------|-------------|
| **Meal Logging** | Record meals with food items, quantities, and nutritional breakdown |
| **Nutrition Calculator** | BMR/TDEE calculation, macro targets based on goals |
| **Meal Suggestions** | AI-generated meal recommendations based on health conditions |
| **Water Intake** | Track daily water consumption with configurable goals and reminders |

### 🧠 AI & Smart Features
| Feature | Description |
|---------|-------------|
| **AI Chat Assistant** | Smart health Q&A with confidence scoring and feedback system |
| **Behavioral Nudges** | Context-aware motivational messages and habit suggestions |
| **Predictive Prevention** | Health risk assessment and personalised prevention plans |
| **Smart Notifications** | Priority-based reminders linked to dynamic targets and milestones |
| **Achievement System** | Gamified milestones, points, and streak tracking |

### 👥 Community
| Feature | Description |
|---------|-------------|
| **Community Posts** | Share experiences, tips, questions with reactions and comments |
| **Support Groups** | Condition-based private/public groups with member management |
| **Social Features** | Likes, saves, anonymous posting, threaded replies |

### 📊 Analytics & Insights
| Feature | Description |
|---------|-------------|
| **AI Dashboard** | Health score, ML predictions, personalised tips, nutrition analysis |
| **Water Dashboard** | Progress charts, stats, quick-add, tips |
| **Quiz System** | Onboarding and daily quizzes (morning/evening) with score tracking |
| **Data Export** | Export health data in various formats |
| **Medical Analysis** | Upload and analyse medical test results with OCR |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Frontend                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Screens  │  │  Widgets  │  │  Services / Providers│  │
│  └────┬─────┘  └────┬─────┘  └──────────┬───────────┘  │
│       │              │                   │              │
│       └──────────────┴───────────────────┘              │
│                        │ HTTP/REST                      │
└────────────────────────┼────────────────────────────────┘
                         │
┌────────────────────────┼────────────────────────────────┐
│              FastAPI Backend (Python)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Routers  │  │ Services  │  │  ML / AI Modules    │  │
│  └────┬─────┘  └────┬─────┘  └──────────┬───────────┘  │
│       │              │                   │              │
│       └──────────────┴───────────────────┘              │
│                        │ SQLAlchemy ORM                  │
└────────────────────────┼────────────────────────────────┘
                         │
                  ┌──────┴──────┐
                  │   MySQL DB  │
                  └─────────────┘
```

### Architecture Highlights

- **MVVM Pattern** on frontend with Provider for state management
- **RESTful API** design with FastAPI routers
- **Rate Limiting** via slowapi (100 req/min default)
- **CORS** enabled for cross-origin requests
- **JWT Authentication** with access/refresh tokens
- **Background Scheduler** (APScheduler) for periodic tasks
- **Caching** with configurable in-memory/Redis cache

---

## 📱 Frontend (Flutter)

### State Management
- **Provider** (`ChangeNotifier`) for theme and state management
- **HomeViewModel** with 5-minute cache and parallel data loading

### Key Packages
| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | HTTP client for API calls |
| `fl_chart` | Charts and visualisations |
| `table_calendar` | Calendar views |
| `shimmer` | Skeleton loading effects |
| `lottie` | Lottie animations |
| `animations` | Pre-built UI animations |
| `pedometer` | Step counting |
| `awesome_notifications` | Local notifications |
| `hive` | Local caching |
| `encrypt` / `crypto` | Data encryption |
| `confetti` | Achievement celebrations |
| `image_picker` / `file_picker` | File uploads |

### Screen Modules (30+ screens)

| Module | Screens |
|--------|---------|
| **Home** | Dashboard with animated stat cards, health tips, skeleton loading |
| **Auth** | Login, Register, Splash, Onboarding |
| **Medications** | Dashboard, Add/Edit, Details, Statistics |
| **Symptoms** | Dashboard, Add/Edit, History, Detail, Analysis |
| **Nutrition** | Dashboard, Add Meal, History, Suggestions, Analysis |
| **Walking** | Dashboard, Add Activity, Statistics, Challenges, Simulation |
| **Activities** | Dashboard, Add/Edit, Detail, Statistics |
| **Water** | Dashboard, Settings, Progress Charts |
| **Weight** | Tracking screen with predictions |
| **Health** | Pressure & Sugar dashboards, history, analysis |
| **Diabetes** | Tracking dashboard |
| **Chat** | Main chat, History, FAQ, Answer Details |
| **Quiz** | Onboarding Quiz, Daily Quiz, Results, Analysis |
| **Community** | Posts, Groups, Create Post, Profile, Saved |
| **Analysis** | AI Dashboard, Water Dashboard |
| **Dynamic Targets** | Dashboard, Achievements, Performance, Comparison |
| **Predictive Prevention** | Prevention dashboard |
| **Profile** | Personal Info, Health Data, Help & Support |
| **Settings** | Theme, Quiet Hours |

---

## ⚙️ Backend (FastAPI)

### Tech Stack
| Component | Technology |
|-----------|-----------|
| Framework | FastAPI |
| ORM | SQLAlchemy 2.0 |
| Validation | Pydantic v2 |
| Auth | JWT (PyJWT) + bcrypt |
| Rate Limiting | slowapi |
| Scheduler | APScheduler |
| AI/ML | XGBoost, scikit-learn, Google Generative AI |
| OCR | Tesseract + OpenCV |
| PDF | pdfplumber |
| Reports | ReportLab + Matplotlib |

### Background Jobs (APScheduler)

| Job | Schedule | Description |
|-----|----------|-------------|
| **Notification Tasks** | Every 30 min | Send pending notifications to all users |
| **Missed Doses Check** | Every hour | Detect and alert missed medication doses |
| **Dynamic Targets** | Daily at 00:05 | Generate AI-adjusted daily targets for all users |
| **Performance Calc** | Daily at 23:55 | Calculate daily user performance scores |
| **Smart Reminders** | Every 30 min | Send context-aware motivational reminders |
| **Real Estate Scraper** | Weekly (Sat 08:00) | Scrape Bayut Egypt for property data |

---

## 🗄️ Database Models

The database contains **40+ SQLAlchemy models** organised into domains:

### Health & Medical
- [`User`](back/models.py:218) — User accounts with profile data
- [`Medication`](back/models.py:732) — User medications with schedule
- [`MedicationDose`](back/models.py:785) — Dose tracking (pending/taken/missed)
- [`Symptom`](back/models.py:288) — Symptoms with severity and AI analysis
- [`WeightHistory`](back/models.py:166) — Weight records
- [`HealthImpactFactor`](back/models.py:180) — Factors affecting health targets
- [`MedicineFoodRecommendation`](back/models.py:199) — Food recommendations per medicine

### Nutrition
- [`Food`](back/models.py:415) — Food database with macros
- [`Meal`](back/models.py:457) — User meals
- [`MealFood`](back/models.py:499) — Meal-food associations
- [`MealSuggestion`](back/models.py:550) — AI meal suggestions
- [`UserNutrition`](back/models.py:347) — User nutrition profile (BMR, TDEE, goals)
- [`WaterIntake`](back/models.py:666) — Water consumption logs
- [`WaterSettings`](back/models.py:679) — Per-user water preferences

### Activity & Fitness
- [`Activity`](back/models.py:877) — User activities with categories
- [`ActivityCategory`](back/models.py:855) — Activity type categories
- [`WalkingActivity`](back/models.py:818) — Walking logs
- [`ActivityPlan`](back/models.py:1877) — Weekly/monthly/custom plans

### AI & Behavioural
- [`BehavioralNudge`](back/models.py:1131) — Motivational nudges
- [`BehavioralPattern`](back/models.py:1185) — User behaviour patterns
- [`HealthRisk`](back/models.py:1241) — Health risk assessments
- [`PreventionPlan`](back/models.py:1285) — Personalised prevention plans
- [`SmartNotification`](back/models.py:1809) — Smart priority-based notifications

### Dynamic Targets & Performance
- [`DynamicDailyTarget`](back/models.py:1632) — AI-adjusted daily goals
- [`PerformanceHistory`](back/models.py:1717) — Daily adherence scores
- [`AchievementMilestone`](back/models.py:1772) — Gamified achievements

### Community
- [`CommunityPost`](back/models.py:1412) — User posts
- [`CommunityComment`](back/models.py:1465) — Post comments (threaded)
- [`CommunityLike`](back/models.py:1527) — Likes/reactions
- [`CommunityGroup`](back/models.py:1554) — Support groups
- [`CommunityGroupMember`](back/models.py:1599) — Group membership

### Quiz & Assessment
- [`QuizQuestion`](back/models.py:958) — Onboarding quiz questions
- [`QuizOption`](back/models.py:977) — Quiz options with scores
- [`QuizSession`](back/models.py:991) — Quiz sessions
- [`UserQuizAnswer`](back/models.py:1006) — User answers
- [`DailyQuizQuestion`](back/models.py:1333) — Daily quiz questions
- [`DailyQuizSession`](back/models.py:1367) — Daily quiz sessions

### Diabetes
- [`BloodSugarMeasurement`](back/models.py:1033) — Blood sugar logs
- [`DiabetesMedication`](back/models.py:1064) — Diabetes-specific medications
- [`DiabetesSymptom`](back/models.py:1096) — Diabetes symptom tracking

### Other
- [`ChatQA`](back/models.py:916) — Q&A pairs for AI chat
- [`NotificationLog`](back/models.py:705) — Notification history
- [`Token`](back/models.py:253) — Refresh tokens
- [`LoginAttempt`](back/models.py:275) — Login attempt tracking
- [`Property`](back/models.py:42) — Real estate properties (sub-project)
- [`AreaIntelligence`](back/models.py:77) — Area market intelligence
- [`ScrapingHistory`](back/models.py:104) — Scraping job logs
- [`PricePrediction`](back/models.py:118) — Property price predictions

---

## 🌐 API Endpoints

The backend exposes **22 router modules** with 100+ endpoints. All endpoints are prefixed with their respective router paths.

### 🔐 Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login with email/password |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/change-password` | Change password |
| GET | `/auth/me` | Get current user profile |
| PUT | `/auth/me` | Update user profile |

### 💊 Medications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/medications/` | List user medications |
| POST | `/medications/` | Add new medication |
| GET | `/medications/{id}` | Get medication details |
| PUT | `/medications/{id}` | Update medication |
| DELETE | `/medications/{id}` | Delete medication |
| POST | `/medications/{id}/dose` | Log a dose |
| GET | `/medications/doses/today` | Today's doses |
| GET | `/medications/stats` | Adherence statistics |
| GET | `/medicines/search` | Search medicine database |

### 🚶 Walking
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/walking/` | List walking activities |
| POST | `/walking/` | Log walking activity |
| GET | `/walking/stats` | Walking statistics |
| GET | `/walking/goal` | Get step goal |
| PUT | `/walking/goal` | Update step goal |

### 🥗 Nutrition
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/nutrition/profile` | Get nutrition profile |
| POST | `/nutrition/profile` | Create nutrition profile |
| PUT | `/nutrition/profile` | Update nutrition profile |
| GET | `/nutrition/meals` | List meals |
| POST | `/nutrition/meals` | Add meal |
| GET | `/nutrition/meals/{id}` | Get meal details |
| DELETE | `/nutrition/meals/{id}` | Delete meal |

---

> **🌍 النسخة العربية — شرح المشروع بالكامل**

---

# 🌐 فيتا (VITA) — منصة إدارة صحية شاملة

**فيتا** هو تطبيق كامل لإدارة الصحة مبني على بنية متكاملة من Frontend (Flutter) و Backend (FastAPI) مع قاعدة بيانات MySQL وذكاء اصطناعي (AI/ML). الفكرة الأساسية هي إنشاء **مساعد صحي شخصي ذكي** يساعد المستخدم على:

- تتبع جميع جوانب صحته (أدوية، تغذية، أعراض، وزن، سكري، ضغط)
- الحصول على توصيات ونصائح ذكية مبنية على بياناته الفعلية
- التفاعل مع مجتمع داعم
- تحقيق أهدافه اليومية عبر نظام تحفيزي (Gamification)

---

## 🏗️ بنية النظام العامة (Architecture)

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Frontend                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Screens  │  │  Widgets  │  │  Services / Providers│  │
│  └────┬─────┘  └────┬─────┘  └──────────┬───────────┘  │
│       │              │                   │              │
│       └──────────────┴───────────────────┘              │
│                        │ HTTP/REST                      │
└────────────────────────┼────────────────────────────────┘
                         │
┌────────────────────────┼────────────────────────────────┐
│              FastAPI Backend (Python)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Routers  │  │ Services  │  │  ML / AI Modules    │  │
│  └────┬─────┘  └────┬─────┘  └──────────┬───────────┘  │
│       │              │                   │              │
│       └──────────────┴───────────────────┘              │
│                        │ SQLAlchemy ORM                  │
└────────────────────────┼────────────────────────────────┘
                         │
                  ┌──────┴──────┐
                  │   MySQL DB  │
                  └─────────────┘
```

### مميزات المعمارية:
- **MVVM Pattern** مع **Provider** لإدارة الحالة
- **RESTful API** بتصميم FastAPI routers
- **Rate Limiting** (100 req/min) عبر slowapi
- **JWT Authentication** مع access/refresh tokens
- **Background Scheduler** (APScheduler) للمهام الدورية
- **Caching** في الذاكرة أو Redis

---

## 🎯 الميزات الأساسية

### 🩺 1️⃣ تتبع الأدوية
- إضافة وتعديل الأدوية بمواعيدها
- تسجيل الجرعات (تأخذ/فاتت/معلقة)
- إحصائيات الالتزام (Adherence Statistics)
- تنبيهات ذكية مرتبطة بالأهداف اليومية

### 🤒 2️⃣ تتبع الأعراض
- تسجيل الأعراض مع درجة الشدة (severity)
- **تحليل بالذكاء الاصطناعي** للأسباب المحتملة
- اقتراحات أطعمة حسب الأعراض والأدوية
- تاريخ وتحليلات كاملة

### 🥗 3️⃣ التغذية
- **حاسبة غذائية**: حساب BMR و TDEE وأهداف الماكروز
- تسجيل الوجبات مع تفصيل غذائي كامل
- **اقتراحات وجبات بالـ AI** حسب الحالة الصحية
- تتبع الماكروز (بروتين، كارب، دهون، سعرات)

### 🚶 4️⃣ المشي والأنشطة
- عداد خطوات (Pedometer) متكامل
- تحديات مشي وأهداف يومية/أسبوعية
- أنشطة مصنفة (عمل، دراسة، رياضة) مع خطط أسبوعية/شهرية
- إحصائيات ورسوم بيانية

### 💧 5️⃣ المياه
- تتبع شرب المياه اليومي بهدف قابل للتعديل
- رسوم بيانية وإحصائيات
- إضافة سريعة وتذكيرات ذكية

### ⚖️ 6️⃣ الوزن
- تسجيل الوزن مع **توقعات XGBoost** (توقع الوزن المستقبلي)
- تحليل العوامل المؤثرة (النوم، الأكل، الرياضة)
- مخطط زمني للعوامل

### ❤️ 7️⃣ ضغط الدم والسكري
- **ضغط الدم**: لوحة بيانات، تحليلات، تاريخ
- **السكري**: تتبع السكر، الأدوية الخاصة، الأعراض
- **سكر الدم**: قراءات وتحليلات

---

## 🤖 الذكاء الاصطناعي (AI & ML)

أقوى جزء في التطبيق — بيدمج 3 تقنيات رئيسية:

| التقنية | الاستخدام |
|---------|-----------|
| **XGBoost** | توقع الوزن، الأهداف الديناميكية اليومية، تقييم المخاطر الصحية |
| **Google Generative AI** | المساعد الذكي (Chat)، تحليل الأعراض، اقتراحات الوجبات |
| **scikit-learn** | تحليل الأنماط السلوكية واكتشاف الأنماط |

### الأنظمة الذكية:

1. **🧠 AI Chat Assistant** — محادثة ذكية عن الصحة مع نظام تقييم للثقة (Confidence Scoring)
2. **🎯 Dynamic Daily Targets** — أهداف يومية متغيرة بالـ AI (سعرات، خطوات، مياه، بروتين، كارب، دهون) تُحسب تلقائيًا كل يوم في 00:05
3. **📊 Predictive Prevention** — تقييم المخاطر الصحية المستقبلية وخطوط وقاية مخصصة
4. **💡 Behavioral Nudges** — رسائل تحفيزية حسب السياق والسلوك
5. **🔔 Smart Notifications** — تنبيهات ذات أولوية حسب الأهداف والمواعيد

---

## 🎮 نظام التحفيز (Gamification)

```
Daily Actions → Points → Achievements & Streaks → Milestones & Rewards
```

- **النقاط**: كل نشاط صحي بيديك نقاط
- **الـ Streaks**: الالتزام اليومي المتواصل
- **الإنجازات**: Milestones عند الوصول لأهداف معينة
- **التحديات**: تحديات مشي وأهداف أسبوعية
- **Confetti Effects**: احتفالات عند تحقيق الإنجازات

---

## 👥 المجتمع (Community)

المستخدمين يقدرون يعملوا:

- **Posts**: مشاركة تجارب ونصائح وأسئلة
- **Support Groups**: مجموعات دعم عامة/خاصة حسب الحالة
- **تفاعل**: Likes، Save، Anonymous Posting، تعليقات مترابطة (Threaded Replies)

---

## 📊 لوحة التحكم الذكية (AI Dashboard)

تحتوي على 10+ كارت:

| الكارت | الوظيفة |
|--------|---------|
| **Health Score** | درجة الصحة الشاملة |
| **ML Predictions** | تنبؤات الذكاء الاصطناعي |
| **Personalized Tips** | نصائح مخصصة حسب بياناتك |
| **Nutrition Charts** | تحليل التغذية مع رسوم بيانية |
| **Symptom Analysis** | تحليل الأعراض |
| **Behavioral Nudges** | رسائل تحفيزية ذكية |
| **Dynamic Targets** | الأهداف الديناميكية |
| **Activity / Water / Diabetes** | باقي الأنشطة |

---

## 📁 هيكل المشروع

```
vita/
├── lib/                          # Flutter Frontend
│   ├── main.dart                 # نقطة البداية ← SplashScreen
│   ├── models/                   # 30+ نموذج بيانات
│   ├── screens/                  # 30+ شاشة مقسمة حسب الموديول
│   │   ├── auth/                 # تسجيل الدخول
│   │   ├── medications/          # الأدوية
│   │   ├── symptoms/             # الأعراض
│   │   ├── nutrition/            # التغذية
│   │   ├── walking/              # المشي
│   │   ├── activities/           # الأنشطة
│   │   ├── health/               # ضغط وسكر
│   │   ├── analysis/             # AI Dashboard
│   │   ├── community/            # المجتمع
│   │   ├── quiz/                 # الاختبارات
│   │   ├── chat/                 # المساعد الذكي
│   │   └── dynamic_targets/      # الأهداف الديناميكية
│   ├── services/                 # 30+ خدمة API
│   ├── providers/                # إدارة الحالة (Provider)
│   ├── widgets/                  # مكونات قابلة لإعادة الاستخدام
│   └── utils/                    # أدوات مساعدة
├── back/                         # FastAPI Backend
│   ├── models.py                 # 40+ نموذج SQLAlchemy
│   ├── routers/                  # 22 راوتر
│   ├── services/                 # منطق الأعمال
│   └── ml/                       # موديلات ML
├── android/ ios/ web/ linux/ macos/ windows/  # منصات متعددة
└── plans/                        # خطط التطوير
```

---

## ⏰ المهام الخلفية المجدولة (Background Jobs)

| المهمة | الموعد | الوصف |
|--------|--------|-------|
| **Send Notifications** | كل 30 دقيقة | إرسال الإشعارات المعلقة |
| **Missed Doses Check** | كل ساعة | اكتشاف الجرعات الفائتة |
| **Dynamic Targets** | يوميًا 00:05 | حساب الأهداف الديناميكية |
| **Performance Score** | يوميًا 23:55 | حساب أداء المستخدم اليومي |
| **Smart Reminders** | كل 30 دقيقة | رسائل تحفيزية حسب السياق |

---

## 🗄️ قاعدة البيانات (40+ Model)

### المجالات الرئيسية:
| المجال | أبرز النماذج |
|--------|-------------|
| **Health** | [`User`](back/models.py:218), [`Medication`](back/models.py:732), [`Symptom`](back/models.py:288), [`WeightHistory`](back/models.py:166) |
| **Nutrition** | [`Food`](back/models.py:415), [`Meal`](back/models.py:457), [`WaterIntake`](back/models.py:666) |
| **Activity** | [`Activity`](back/models.py:877), [`WalkingActivity`](back/models.py:818), [`ActivityPlan`](back/models.py:1877) |
| **AI** | [`BehavioralNudge`](back/models.py:1131), [`HealthRisk`](back/models.py:1241), [`DynamicDailyTarget`](back/models.py:1632) |
| **Community** | [`CommunityPost`](back/models.py:1412), [`CommunityGroup`](back/models.py:1554) |
| **Quiz** | [`QuizQuestion`](back/models.py:958), [`DailyQuizQuestion`](back/models.py:1333) |
| **Diabetes** | [`BloodSugarMeasurement`](back/models.py:1033), [`DiabetesMedication`](back/models.py:1064) |

---

## 🛠️ التقنيات المستخدمة

### Frontend (Flutter):
| الحزمة | الاستخدام |
|--------|-----------|
| [`provider`](pubspec.yaml:46) | إدارة الحالة |
| [`fl_chart`](pubspec.yaml:54) | الرسوم البيانية |
| [`table_calendar`](pubspec.yaml:53) | التقويم |
| [`pedometer`](pubspec.yaml:48) | عداد الخطوات |
| [`awesome_notifications`](pubspec.yaml:51) | الإشعارات |
| [`hive`](pubspec.yaml:59) | تخزين محلي مؤقت |
| [`shimmer`](pubspec.yaml:39) | تأثيرات التحميل |
| [`lottie`](pubspec.yaml:40) | رسوم متحركة |
| [`encrypt`/`crypto`](pubspec.yaml:57) | تشفير البيانات |
| [`confetti`](pubspec.yaml:56) | احتفالات الإنجازات |

### Backend (Python/FastAPI):
- SQLAlchemy 2.0 ORM
- JWT + bcrypt للمصادقة
- APScheduler للمهام المجدولة
- XGBoost, scikit-learn, Google Generative AI
- Tesseract + OpenCV للـ OCR
- ReportLab + Matplotlib للتقارير

---

## 🎯 خلاصة المشروع

**VITA** مش مجرد تطبيق تتبع صحي — ده **نظام متكامل** بيدمج:

1. **🩺 Health Tracking** — أدوية، أعراض، وزن، ضغط، سكري، تغذية، مياه، مشي، أنشطة
2. **🧠 AI Intelligence** — تنبؤات XGBoost، توصيات Gemini AI، تحليل سلوكي، أهداف ديناميكية
3. **🎮 Gamification** — نقاط، إنجازات، تحديات، Streaks، احتفالات
4. **👥 Community** — مشاركات، مجموعات دعم، تفاعل اجتماعي
5. **📊 Analytics** — رسوم بيانية، إحصائيات، تحليلات متقدمة، لوحة AI Dashboard
6. **⏰ Smart Notifications** — تذكيرات ذكية حسب الأولوية والسياق
7. **🔐 Security** — JWT Auth، تشفير بيانات، Rate Limiting

التطبيق فيه **30+ شاشة Flutter**، **100+ API Endpoint** على **22 Router**، **40+ Model** في قاعدة البيانات، و **6 Background Jobs** شغالة تلقائيًا لتحليل البيانات وإرسال الإشعارات والتوقعات اليومية.
