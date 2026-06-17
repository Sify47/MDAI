# Flow Chart للصفحات والأنظمة في تطبيق Vita Health

## 📱 مخطط تدفق الصفحات الرئيسية (Navigation Flow)

```mermaid
flowchart TD
    Start[Splash Screen] --> CheckAuth{هل المستخدم مسجل؟}
    
    CheckAuth -->|لا| Onboarding[Onboarding Screen]
    CheckAuth -->|نعم| MainApp[التطبيق الرئيسي]
    
    Onboarding --> Login[Login Screen]
    Onboarding --> Register[Register Screen]
    
    Login --> InitialSetup[Initial Setup]
    Register --> InitialSetup
    
    InitialSetup --> OnboardingQuiz[Onboarding Quiz]
    OnboardingQuiz --> MainApp
    
    MainApp --> BottomNav[شريط التنقل السفلي]
    
    BottomNav --> HomeTab[الرئيسية]
    BottomNav --> ServicesTab[الخدمات]
    BottomNav --> AnalysisTab[التحليل]
    BottomNav --> ProfileTab[الملف الشخصي]
    
    HomeTab --> HomeScreen[Home Screen]
    ServicesTab --> ServicesScreen[Services Screen]
    AnalysisTab --> AIDashboard[AI Dashboard]
    ProfileTab --> ProfileScreen[Profile Screen]
```

## 🏠 نظام الصفحات الرئيسية (Home System)

```mermaid
flowchart TD
    HomeScreen[Home Screen] --> QuickActions[الإجراءات السريعة]
    
    QuickActions --> AddWeight[إضافة وزن]
    QuickActions --> AddMeal[إضافة وجبة]
    QuickActions --> AddActivity[إضافة نشاط]
    QuickActions --> AddSymptom[إضافة عرض]
    QuickActions --> AddWater[إضافة ماء]
    
    HomeScreen --> HealthStats[الإحصائيات الصحية]
    
    HealthStats --> ViewWeight[عرض الوزن]
    HealthStats --> ViewNutrition[عرض التغذية]
    HealthStats --> ViewActivity[عرض النشاط]
    HealthStats --> ViewSymptoms[عرض الأعراض]
    HealthStats --> ViewWater[عرض الماء]
    
    HomeScreen --> RecentActivity[النشاط الأخير]
    
    RecentActivity --> ViewDetails[عرض التفاصيل]
    ViewDetails --> SpecificScreen[شاشة محددة]
```

## 🛠️ نظام الخدمات (Services System)

```mermaid
flowchart TD
    ServicesScreen[Services Screen] --> ServicesGrid[شبكة الخدمات]
    
    ServicesGrid --> MedicationsService[الأدوية]
    ServicesGrid --> NutritionService[التغذية]
    ServicesGrid --> WalkingService[المشي]
    ServicesGrid --> SymptomsService[الأعراض]
    ServicesGrid --> QuizService[الاختبارات]
    ServicesGrid --> PredictiveService[التنبؤ الوقائي]
    ServicesGrid --> ChatService[المساعد الذكي]
    ServicesGrid --> CommunityService[المجتمع]
    
    MedicationsService --> MedicationsDashboard[Dashboard]
    MedicationsDashboard --> AddMedication[إضافة دواء]
    MedicationsDashboard --> MedicationDetails[تفاصيل الدواء]
    MedicationsDashboard --> MedicationStats[إحصائيات الأدوية]
    
    NutritionService --> NutritionDashboard[Dashboard]
    NutritionDashboard --> AddMeal[إضافة وجبة]
    NutritionDashboard --> MealHistory[سجل الوجبات]
    NutritionDashboard --> MealSuggestions[اقتراحات وجبات]
    NutritionDashboard --> NutritionAnalysis[تحليل التغذية]
    
    WalkingService --> WalkingDashboard[Dashboard]
    WalkingDashboard --> AddWalking[إضافة نشاط مشي]
    WalkingDashboard --> WalkingStats[إحصائيات المشي]
    WalkingDashboard --> WalkingChallenges[تحديات المشي]
    WalkingDashboard --> WalkingSimulation[محاكاة المشي]
    
    SymptomsService --> SymptomsDashboard[Dashboard]
    SymptomsDashboard --> AddSymptom[إضافة عرض]
    SymptomsDashboard --> SymptomHistory[سجل الأعراض]
    SymptomsDashboard --> SymptomAnalysis[تحليل الأعراض]
    
    QuizService --> DailyQuizDashboard[Dashboard]
    DailyQuizDashboard --> DailyQuiz[اختبار يومي]
    DailyQuizDashboard --> QuizResults[نتائج الاختبار]
    DailyQuizDashboard --> QuizAnalysis[تحليل الاختبار]
    
    PredictiveService --> PredictiveDashboard[Dashboard]
    PredictiveDashboard --> RiskAnalysis[تحليل المخاطر]
    PredictiveDashboard --> PreventionPlans[الخطط الوقائية]
    
    ChatService --> ChatMain[المساعد الذكي]
    ChatMain --> ChatHistory[سجل المحادثات]
    ChatMain --> FAQ[الأسئلة الشائعة]
    
    CommunityService --> CommunityMain[المجتمع]
    CommunityMain --> GroupsScreen[المجموعات]
    CommunityMain --> CreatePost[إنشاء منشور]
    CommunityMain --> SavedPosts[المشاركات المحفوظة]
```

## 🔬 نظام التحليل (Analysis System)

```mermaid
flowchart TD
    AIDashboard[AI Dashboard] --> AnalysisModules[وحدات التحليل]
    
    AnalysisModules --> HealthAnalysis[تحليل الصحة المتكامل]
    AnalysisModules --> WaterAnalysis[تحليل الماء]
    AnalysisModules --> UploadAnalysis[تحميل للتحليل]
    AnalysisModules --> AnalysisHistory[سجل التحليلات]
    AnalysisModules --> AnalysisResults[نتائج التحليل]
    
    HealthAnalysis --> IntegratedAnalysis[تحليل متكامل]
    IntegratedAnalysis --> GenerateReport[توليد تقرير]
    
    WaterAnalysis --> WaterDashboard[Dashboard]
    WaterDashboard --> WaterSettings[إعدادات الماء]
    WaterDashboard --> WaterStats[إحصائيات الماء]
    
    UploadAnalysis --> UploadScreen[شاشة التحميل]
    UploadScreen --> ProcessAnalysis[معالجة التحليل]
    ProcessAnalysis --> ShowResults[عرض النتائج]
    
    AnalysisHistory --> ViewPastAnalysis[عرض التحليلات السابقة]
    ViewPastAnalysis --> AnalysisDetails[تفاصيل التحليل]
    
    AnalysisResults --> ResultDetails[تفاصيل النتيجة]
    ResultDetails --> ExportReport[تصدير التقرير]
```

## 👤 نظام الملف الشخصي (Profile System)

```mermaid
flowchart TD
    ProfileScreen[Profile Screen] --> ProfileSections[أقسام الملف]
    
    ProfileSections --> PersonalInfo[المعلومات الشخصية]
    ProfileSections --> HealthData[البيانات الصحية]
    ProfileSections --> Settings[الإعدادات]
    ProfileSections --> HelpSupport[المساعدة والدعم]
    
    PersonalInfo --> EditPersonalInfo[تعديل المعلومات]
    EditPersonalInfo --> SaveChanges[حفظ التغييرات]
    
    HealthData --> ViewHealthData[عرض البيانات الصحية]
    ViewHealthData --> EditHealthData[تعديل البيانات]
    EditHealthData --> UpdateHealthData[تحديث البيانات]
    
    Settings --> ThemeSettings[إعدادات السمة]
    ThemeSettings --> ChangeTheme[تغيير السمة]
    
    Settings --> QuietHours[ساعات الهدوء]
    QuietHours --> SetQuietHours[تعيين ساعات الهدوء]
    
    Settings --> NotificationSettings[إعدادات الإشعارات]
    NotificationSettings --> ManageNotifications[إدارة الإشعارات]
    
    HelpSupport --> FAQ[الأسئلة الشائعة]
    HelpSupport --> ContactSupport[الاتصال بالدعم]
    HelpSupport --> AboutApp[حول التطبيق]
```

## 🩺 نظام الأمراض المزمنة (Chronic Diseases System)

```mermaid
flowchart TD
    DiabetesSystem[نظام السكري] --> DiabetesTracking[تتبع السكري]
    
    DiabetesTracking --> SugarDashboard[Dashboard]
    SugarDashboard --> AddSugarReading[إضافة قراءة سكر]
    SugarDashboard --> SugarHistory[سجل قراءات السكر]
    SugarDashboard --> SugarAnalysis[تحليل السكر]
    
    HypertensionSystem[نظام الضغط] --> PressureTracking[تتبع الضغط]
    
    PressureTracking --> PressureDashboard[Dashboard]
    PressureDashboard --> AddPressureReading[إضافة قراءة ضغط]
    PressureDashboard --> PressureHistory[سجل قراءات الضغط]
    PressureDashboard --> PressureAnalysis[تحليل الضغط]
    
    WeightSystem[نظام الوزن] --> WeightTracking[تتبع الوزن]
    
    WeightTracking --> WeightScreen[شاشة الوزن]
    WeightScreen --> AddWeight[إضافة وزن]
    WeightScreen --> ViewWeightHistory[عرض سجل الوزن]
    WeightScreen --> WeightAnalysis[تحليل الوزن]
```

## 🔄 مخطط تدفق البيانات بين الصفحات

```mermaid
flowchart LR
    subgraph DataEntry [صفحات إدخال البيانات]
        A1[إضافة وجبة]
        A2[إضافة نشاط مشي]
        A3[إضافة عرض]
        A4[إضافة دواء]
        A5[إضافة قراءة سكر]
        A6[إضافة قراءة ضغط]
        A7[إضافة وزن]
    end
    
    subgraph Dashboards [لوحات التحكم]
        B1[لوحة التغذية]
        B2[لوحة المشي]
        B3[لوحة الأعراض]
        B4[لوحة الأدوية]
        B5[لوحة السكري]
        B6[لوحة الضغط]
        B7[لوحة الوزن]
    end
    
    subgraph Analysis [صفحات التحليل]
        C1[تحليل التغذية]
        C2[تحليل المشي]
        C3[تحليل الأعراض]
        C4[تحليل الأدوية]
        C5[تحليل السكري]
        C6[تحليل الضغط]
        C7[تحليل الوزن]
    end
    
    subgraph Database [قاعدة البيانات]
        D1[بيانات التغذية]
        D2[بيانات النشاط]
        D3[بيانات الأعراض]
        D4[بيانات الأدوية]
        D5[بيانات السكري]
        D6[بيانات الضغط]
        D7[بيانات الوزن]
    end
    
    A1 --> D1
    A2 --> D2
    A3 --> D3
    A4 --> D4
    A5 --> D5
    A6 --> D6
    A7 --> D7
    
    D1 --> B1
    D2 --> B2
    D3 --> B3
    D4 --> B4
    D5 --> B5
    D6 --> B6
    D7 --> B7
    
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C4
    B5 --> C5
    B6 --> C6
    B7 --> C7
    
    C1 --> D1
    C2 --> D2
    C3 --> D3
    C4 --> D4
    C5 --> D5
    C6 --> D6
    C7 --> D7
```

## 🎯 مخطط هيكل التطبيق الكلي

```mermaid
flowchart TD
    App[تطبيق Vita Health] --> CoreSystems[الأنظمة الأساسية]
    
    CoreSystems --> AuthSystem[نظام المصادقة]
    CoreSystems --> DataSystem[نظام البيانات]
    CoreSystems --> AnalysisSystem[نظام التحليل]
    CoreSystems --> NotificationSystem[نظام الإشعارات]
    
    AuthSystem --> Login[تسجيل الدخول]
    AuthSystem --> Register[التسجيل]
    AuthSystem --> SessionMgmt[إدارة الجلسات]
    
    DataSystem --> LocalStorage[التخزين المحلي]
    DataSystem --> CloudSync[مزامنة السحابة]
    DataSystem --> APIIntegration[تكامل API]
    
    AnalysisSystem --> PredictiveAnalysis[التحليل التنبؤي]
    AnalysisSystem --> AIAnalysis[التحليل بالذكاء الاصطناعي]
    AnalysisSystem --> StatisticalAnalysis[التحليل الإحصائي]
    
    NotificationSystem --> PushNotifications[الإشعارات الدفعية]
    NotificationSystem --> Reminders[التذكيرات]
    NotificationSystem --> Alerts[التنبيهات]
    
    App --> FeatureModules[وحدات الميزات]
    
    FeatureModules --> HealthTracking[تتبع الصحة]
    FeatureModules --> MedicationMgmt[إدارة الأدوية]
    FeatureModules --> NutritionPlanning[تخطيط التغذية]
    FeatureModules --> ActivityMonitoring[مراقبة النشاط]
    FeatureModules --> SymptomTracking[تتبع الأعراض]
    FeatureModules --> CommunitySupport[دعم المجتمع]
    
    HealthTracking --> VitalSigns[العلامات الحيوية]
    HealthTracking --> ChronicDiseases[الأمراض المزمنة]
    HealthTracking --> HealthMetrics[المقاييس الصحية]
    
    MedicationMgmt --> MedicationSchedule[جدول الأدوية]
    MedicationMgmt --> RefillReminders[تذكير التجديد]
    MedicationMgmt --> InteractionChecks[فحص التفاعلات]
    
    NutritionPlanning --> MealTracking[تتبع الوجبات]
    NutritionPlanning --> CalorieCounting[عد السعرات]
    NutritionPlanning --> NutrientAnalysis[تحليل العناصر]
    
    ActivityMonitoring --> StepCounting[عد الخطوات]
    ActivityMonitoring --> ExerciseTracking[تتبع التمارين]
    ActivityMonitoring --> ActivityGoals[أهداف النشاط]
    
    SymptomTracking --> SymptomLogging[تسجيل الأعراض]
    SymptomTracking --> PatternDetection[كشف الأنماط]
    SymptomTracking --> SeverityAssessment[تقييم الشدة]
    
    CommunitySupport --> Groups[المجموعات]
    CommunitySupport --> Discussions[المناقشات]
    CommunitySupport --> PeerSupport[الدعم من الأقران]
    
    App --> UISystem[نظام واجهة المستخدم]
    
    UISystem --> Navigation[التنقل]
    UISystem --> Themes[السمات]
    UISystem --> Animations[الحركات]
    UISystem --> ResponsiveDesign[التصميم المتجاوب]
```

## 📊 مخطط تدفق المستخدم النموذجي

```mermaid
journey
    title رحلة المستخدم النموذجية في تطبيق Vita Health
    section التسجيل والإعداد
      تثبيت التطبيق: 5: المستخدم
      التسجيل وإنشاء حساب: 5: المستخدم
      إكمال الإعداد الأولي: 5: المستخدم
      إجراء اختبار التعريف: 5: المستخدم
    section الاستخدام اليومي
      تسجيل الدخول: 5: المستخدم
      مراجعة الصفحة الرئيسية: 5: المستخدم
      إدخال البيانات الصحية: 5: المستخدم
      مراجعة الإشعارات: 5: المستخدم
    section المتابعة والتحليل
      مراجعة لوحات التحكم: 5: المستخدم
      إجراء التحليلات: 5: المستخدم
      مراجعة التقارير: 5: المستخدم
      تعديل الأهداف: 5: المستخدم
    section التفاعل المجتمعي
      المشاركة في المجتمع: 5: المستخدم
      استخدام المساعد الذكي: 5: المستخدم
      مشاركة النتائج: 5: المستخدم
```

## 🖼️ كيفية تحويل المخططات إلى صور

لتحويل مخططات Mermaid هذه إلى صور، يمكنك استخدام الأدوات التالية:

### 1. **أدوات عبر الإنترنت:**
- [Mermaid Live Editor](https://mermaid.live/)
- [Mermaid CLI](https://github.com/mermaid-js/mermaid-cli)
- [Mermaid to PNG Converters](https://github.com/mermaid-js/mermaid#generating-diagrams-from-the-command-line)

### 2. **خطوات التحويل:**
1. انسخ كود Mermaid من أي مخطط أعلاه
2. الصقه في محرر Mermaid Live Editor
3. اضغط على زر "Export" أو "Download"
4. اختر تنسيق الصورة (PNG، SVG، PDF)

### 3. **أمثلة على الأكواد:**
```mermaid
graph TD
    A[بداية] --> B[عملية]
    B --> C[نتيجة]
    C --> D[نهاية]
```

## 📁 ملخص هيكل الصفحات

| النظام | الصفحات الرئيسية | الوظيفة |
|--------|------------------|---------|
| **المصادقة** | Splash، Login، Register، Onboarding | إدارة حسابات المستخدمين |
| **الرئيسية** | Home Screen، Quick Actions | نظرة عامة على الصحة |
| **التغذية** | Nutrition Dashboard، Add Meal، Analysis | تتبع وتحليل التغذية |
| **النشاط** | Walking Dashboard، Add Activity، Statistics | تتبع النشاط البدني |
| **الأعراض** | Symptoms Dashboard، Add Symptom، Analysis | تتبع وتحليل الأعراض |
| **الأدوية** | Medications Dashboard، Add Medication، Stats | إدارة الأدوية |
| **السكري** | Sugar Dashboard، Add Reading، Analysis | تتبع وتحليل السكري |
| **الضغط** | Pressure Dashboard، Add Reading، Analysis | تتبع وتحليل الضغط |
| **الاختبارات** | Quiz Dashboard، Daily Quiz، Results | اختبارات صحية يومية |
| **التنبؤ** | Predictive Dashboard، Risk Analysis | تحليل المخاطر الصحية |
| **المساعد الذكي** | Chat Main، History، FAQ | مساعدة ذكية للصحة |
| **المجتمع** | Community Main، Groups، Posts | دعم مجتمعي |
| **التحليل** | AI Dashboard، Health Analysis، Water Analysis | تحليلات متقدمة |
| **الملف الشخصي** | Profile، Settings، Help | إدارة الحساب والإعدادات |

هذه المخططات توضح هيكل التطبيق الكامل وتدفق الصفحات بين الأنظمة المختلفة.