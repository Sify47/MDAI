# Flow Chart للتطبيق التنبؤي الوقائي

## 📋 Flow Chart شامل للتطبيق

```mermaid
flowchart TD
    Start[بدء التطبيق] --> Login[تسجيل الدخول]
    Login --> MainMenu[القائمة الرئيسية]
    
    MainMenu --> HealthData[إدخال البيانات الصحية]
    MainMenu --> Dashboard[لوحة التحكم التنبؤية]
    MainMenu --> Reports[التقارير]
    MainMenu --> Settings[الإعدادات]
    
    HealthData --> NutritionData[بيانات التغذية]
    HealthData --> BloodSugar[قياسات السكر]
    HealthData --> Activity[النشاط البدني]
    HealthData --> MedicalHistory[التاريخ الطبي]
    
    NutritionData --> SaveNutrition[حفظ بيانات التغذية]
    BloodSugar --> SaveBloodSugar[حفظ قياسات السكر]
    Activity --> SaveActivity[حفظ النشاط]
    MedicalHistory --> SaveHistory[حفظ التاريخ]
    
    SaveNutrition --> UpdateDB[تحديث قاعدة البيانات]
    SaveBloodSugar --> UpdateDB
    SaveActivity --> UpdateDB
    SaveHistory --> UpdateDB
    
    UpdateDB --> TriggerAnalysis[تشغيل التحليل التلقائي]
    
    Dashboard --> LoadDashboard[تحميل لوحة التحكم]
    LoadDashboard --> APIRequest[طلب بيانات من API]
    APIRequest --> BackendProcess[معالجة في الباك إند]
    
    BackendProcess --> GetUserData[جلب بيانات المستخدم]
    GetUserData --> AnalyzeRisks[تحليل المخاطر]
    
    AnalyzeRisks --> DiabetesAnalysis[تحليل السكري]
    AnalyzeRisks --> ObesityAnalysis[تحليل السمنة]
    AnalyzeRisks --> HeartAnalysis[تحليل القلب]
    AnalyzeRisks --> HypertensionAnalysis[تحليل الضغط]
    AnalyzeRisks --> InactivityAnalysis[تحليل النشاط]
    AnalyzeRisks --> NutritionAnalysis[تحليل التغذية]
    AnalyzeRisks --> StressAnalysis[تحليل الإجهاد]
    
    DiabetesAnalysis --> CalculateRisk[حساب مستوى الخطر]
    ObesityAnalysis --> CalculateRisk
    HeartAnalysis --> CalculateRisk
    HypertensionAnalysis --> CalculateRisk
    InactivityAnalysis --> CalculateRisk
    NutritionAnalysis --> CalculateRisk
    StressAnalysis --> CalculateRisk
    
    CalculateRisk --> GenerateRecommendations[توليد التوصيات]
    GenerateRecommendations --> CreatePlans[إنشاء خطط وقائية]
    CreatePlans --> SaveResults[حفظ النتائج]
    SaveResults --> ReturnData[إرجاع البيانات]
    
    ReturnData --> DisplayDashboard[عرض اللوحة]
    
    DisplayDashboard --> ShowStats[عرض الإحصائيات]
    DisplayDashboard --> ShowRisks[عرض المخاطر]
    DisplayDashboard --> ShowPlans[عرض الخطط]
    DisplayDashboard --> ShowCharts[عرض الرسوم البيانية]
    
    ShowStats --> UserInteraction[تفاعل المستخدم]
    ShowRisks --> UserInteraction
    ShowPlans --> UserInteraction
    ShowCharts --> UserInteraction
    
    UserInteraction --> RefreshButton[زر التحديث]
    UserInteraction --> AnalyzeButton[زر التحليل]
    UserInteraction --> PlanDetails[تفاصيل الخطة]
    UserInteraction --> RiskDetails[تفاصيل المخاطر]
    
    RefreshButton --> LoadDashboard
    AnalyzeButton --> ManualAnalysis[تحليل يدوي]
    
    ManualAnalysis --> AnalyzeRisks
    
    PlanDetails --> ViewPlan[عرض الخطة]
    ViewPlan --> UpdateProgress[تحديث التقدم]
    UpdateProgress --> SaveProgress[حفظ التقدم]
    SaveProgress --> LoadDashboard
    
    RiskDetails --> ViewRisk[عرض المخاطر]
    ViewRisk --> GetRecommendations[عرض التوصيات]
    GetRecommendations --> CreateNewPlan[إنشاء خطة جديدة]
    CreateNewPlan --> CreatePlans
    
    Reports --> GenerateReport[توليد تقرير]
    GenerateReport --> ExportReport[تصدير التقرير]
    ExportReport --> ShareReport[مشاركة التقرير]
    ShareReport --> MainMenu
    
    Settings --> Notifications[إعدادات الإشعارات]
    Settings --> Privacy[إعدادات الخصوصية]
    Settings --> Account[إعدادات الحساب]
    Settings --> Help[المساعدة]
    
    Notifications --> SaveSettings[حفظ الإعدادات]
    Privacy --> SaveSettings
    Account --> SaveSettings
    Help --> ShowHelp[عرض المساعدة]
    
    SaveSettings --> UpdateSettingsDB[تحديث إعدادات قاعدة البيانات]
    UpdateSettingsDB --> MainMenu
    
    ShowHelp --> HelpContent[محتوى المساعدة]
    HelpContent --> MainMenu
    
    TriggerAnalysis --> AnalyzeRisks
```

## 🔄 Flow Chart لتحليل المخاطر (تفصيلي)

```mermaid
flowchart TD
    StartAnalysis[بدء التحليل] --> GetData[جلب البيانات]
    
    GetData --> Nutrition[بيانات التغذية]
    GetData --> BloodSugar[قياسات السكر]
    GetData --> Activity[النشاط]
    GetData --> History[التاريخ الطبي]
    
    Nutrition --> CheckBMI{هل BMI موجود؟}
    CheckBMI -->|نعم| ProcessBMI[معالجة BMI]
    CheckBMI -->|لا| SkipBMI[تخطي BMI]
    
    BloodSugar --> CheckSugar{هل توجد قياسات سكر؟}
    CheckSugar -->|نعم| ProcessSugar[معالجة السكر]
    CheckSugar -->|لا| SkipSugar[تخطي السكر]
    
    Activity --> CheckSteps{هل توجد خطوات؟}
    CheckSteps -->|نعم| ProcessSteps[معالجة الخطوات]
    CheckSteps -->|لا| SkipSteps[تخطي الخطوات]
    
    History --> CheckDiseases{هل توجد أمراض مزمنة؟}
    CheckDiseases -->|نعم| ProcessDiseases[معالجة الأمراض]
    CheckDiseases -->|لا| SkipDiseases[تخطي الأمراض]
    
    ProcessBMI --> AnalyzeObesity[تحليل السمنة]
    ProcessSugar --> AnalyzeDiabetes[تحليل السكري]
    ProcessSteps --> AnalyzeActivity[تحليل النشاط]
    ProcessDiseases --> AnalyzeChronic[تحليل الأمراض المزمنة]
    
    SkipBMI --> AnalyzeObesity
    SkipSugar --> AnalyzeDiabetes
    SkipSteps --> AnalyzeActivity
    SkipDiseases --> AnalyzeChronic
    
    AnalyzeObesity --> CalculateObesityRisk[حساب خطر السمنة]
    AnalyzeDiabetes --> CalculateDiabetesRisk[حساب خطر السكري]
    AnalyzeActivity --> CalculateActivityRisk[حساب خطر قلة النشاط]
    AnalyzeChronic --> CalculateChronicRisk[حساب خطر الأمراض المزمنة]
    
    CalculateObesityRisk --> AggregateRisks[تجميع المخاطر]
    CalculateDiabetesRisk --> AggregateRisks
    CalculateActivityRisk --> AggregateRisks
    CalculateChronicRisk --> AggregateRisks
    
    AggregateRisks --> DetermineRiskLevels[تحديد مستويات الخطر]
    
    DetermineRiskLevels --> LowRisk[خطر منخفض]
    DetermineRiskLevels --> MediumRisk[خطر متوسط]
    DetermineRiskLevels --> HighRisk[خطر مرتفع]
    DetermineRiskLevels --> CriticalRisk[خطر حرج]
    
    LowRisk --> GenerateLowRec[توليد توصيات منخفضة]
    MediumRisk --> GenerateMediumRec[توليد توصيات متوسطة]
    HighRisk --> GenerateHighRec[توليد توصيات مرتفعة]
    CriticalRisk --> GenerateCriticalRec[توليد توصيات حرجة]
    
    GenerateLowRec --> SaveAnalysis[حفظ التحليل]
    GenerateMediumRec --> SaveAnalysis
    GenerateHighRec --> SaveAnalysis
    GenerateCriticalRec --> SaveAnalysis
    
    SaveAnalysis --> CreatePreventionPlans[إنشاء خطط وقائية]
    
    CreatePreventionPlans --> CheckHighRisk{هل يوجد خطر مرتفع أو حرج؟}
    CheckHighRisk -->|نعم| CreateImmediatePlans[إنشاء خطط فورية]
    CheckHighRisk -->|لا| CreateRegularPlans[إنشاء خطط منتظمة]
    
    CreateImmediatePlans --> SetHighPriority[تعيين أولوية عالية]
    CreateRegularPlans --> SetNormalPriority[تعيين أولوية عادية]
    
    SetHighPriority --> SavePlans[حفظ الخطط]
    SetNormalPriority --> SavePlans
    
    SavePlans --> SendNotifications[إرسال إشعارات]
    SendNotifications --> EndAnalysis[نهاية التحليل]
```

## 📱 Flow Chart لتفاعل المستخدم مع اللوحة

```mermaid
flowchart TD
    OpenApp[فتح التطبيق] --> CheckAuth{هل المستخدم مسجل الدخول؟}
    
    CheckAuth -->|لا| ShowLogin[عرض شاشة تسجيل الدخول]
    CheckAuth -->|نعم| LoadUserData[تحميل بيانات المستخدم]
    
    ShowLogin --> LoginForm[نموذج تسجيل الدخول]
    LoginForm --> SubmitLogin[إرسال بيانات الدخول]
    SubmitLogin --> VerifyCredentials[التحقق من البيانات]
    
    VerifyCredentials --> Valid{هل البيانات صحيحة؟}
    Valid -->|نعم| LoadUserData
    Valid -->|لا| ShowError[عرض خطأ]
    ShowError --> LoginForm
    
    LoadUserData --> CheckFirstTime{هل أول زيارة للوحة؟}
    
    CheckFirstTime -->|نعم| ShowWelcome[عرض ترحيب]
    CheckFirstTime -->|لا| LoadDashboard[تحميل اللوحة]
    
    ShowWelcome --> GetStarted[بدء الاستخدام]
    GetStarted --> LoadDashboard
    
    LoadDashboard --> ShowLoading[عرض تحميل]
    ShowLoading --> FetchData[جلب البيانات من السيرفر]
    
    FetchData --> DataReceived{هل تم استلام البيانات؟}
    DataReceived -->|نعم| RenderDashboard[عرض اللوحة]
    DataReceived -->|لا| ShowError2[عرض خطأ في التحميل]
    
    ShowError2 --> RetryButton[زر إعادة المحاولة]
    RetryButton --> FetchData
    
    RenderDashboard --> DisplayComponents[عرض مكونات اللوحة]
    
    DisplayComponents --> StatsSection[قسم الإحصائيات]
    DisplayComponents --> RisksSection[قسم المخاطر]
    DisplayComponents --> PlansSection[قسم الخطط]
    DisplayComponents --> ChartsSection[قسم الرسوم البيانية]
    
    StatsSection --> UserClicksStat{نقر المستخدم على إحصائية}
    UserClicksStat -->|نعم| ShowStatDetails[عرض تفاصيل الإحصائية]
    UserClicksStat -->|لا| MonitorRisks[مراقبة المخاطر]
    
    ShowStatDetails --> CloseDetails[إغلاق التفاصيل]
    CloseDetails --> RenderDashboard
    
    RisksSection --> UserClicksRisk{نقر المستخدم على خطر}
    UserClicksRisk -->|نعم| ShowRiskDetails[عرض تفاصيل الخطر]
    UserClicksRisk -->|لا| MonitorPlans[مراقبة الخطط]
    
    ShowRiskDetails --> ShowRecommendations[عرض التوصيات]
    ShowRecommendations --> CreatePlanFromRisk[إنشاء خطة من الخطر]
    CreatePlanFromRisk --> CloseRiskDetails[إغلاق التفاصيل]
    CloseRiskDetails --> RenderDashboard
    
    PlansSection --> UserClicksPlan{نقر المستخدم على خطة}
    UserClicksPlan -->|نعم| ShowPlanDetails[عرض تفاصيل الخطة]
    UserClicksPlan -->|لا| MonitorCharts[مراقبة الرسوم البيانية]
    
    ShowPlanDetails --> UpdatePlanProgress[تحديث تقدم الخطة]
    UpdatePlanProgress --> SavePlanProgress[حفظ تقدم الخطة]
    SavePlanProgress --> ClosePlanDetails[إغلاق التفاصيل]
    ClosePlanDetails --> RenderDashboard
    
    ChartsSection --> UserInteractsChart{تفاعل المستخدم مع الرسم البياني}
    UserInteractsChart -->|نعم| ShowChartDetails[عرض تفاصيل الرسم]
    UserInteractsChart -->|لا| CheckButtons[التحقق من الأزرار]
    
    ShowChartDetails --> ExportChart[تصدير الرسم البياني]
    ExportChart --> CloseChartDetails[إغلاق التفاصيل]
    CloseChartDetails --> RenderDashboard
    
    CheckButtons --> RefreshButton[زر التحديث]
    CheckButtons --> AnalyzeButton[زر التحليل]
    
    RefreshButton --> LoadDashboard
    AnalyzeButton --> StartNewAnalysis[بدء تحليل جديد]
    
    StartNewAnalysis --> ShowAnalysisProgress[عرض تقدم التحليل]
    ShowAnalysisProgress --> AnalysisComplete{هل اكتمل التحليل؟}
    AnalysisComplete -->|نعم| ShowResults[عرض النتائج]
    AnalysisComplete -->|لا| ContinueAnalysis[متابعة التحليل]
    
    ContinueAnalysis --> AnalysisComplete
    ShowResults --> UpdateDashboard[تحديث اللوحة]
    UpdateDashboard --> RenderDashboard
    
    MonitorRisks --> UserClicksRisk
    MonitorPlans --> UserClicksPlan
    MonitorCharts --> UserInteractsChart
```

## 🏥 Flow Chart لمسار مريض السكري

```mermaid
flowchart TD
    Patient[مريض السكري] --> EnterData[إدخال البيانات]
    
    EnterData --> BloodSugarReadings[قراءات السكر اليومية]
    EnterData --> FoodLog[سجل الطعام]
    EnterData --> ActivityLog[سجل النشاط]
    EnterData --> MedicationLog[سجل الأدوية]
    
    BloodSugarReadings --> UploadReadings[رفع القراءات]
    FoodLog --> UploadFood[رفع سجل الطعام]
    ActivityLog --> UploadActivity[رفع سجل النشاط]
    MedicationLog --> UploadMedication[رفع سجل الأدوية]
    
    UploadReadings --> SystemAnalysis[تحليل النظام]
    UploadFood --> SystemAnalysis
    UploadActivity --> SystemAnalysis
    UploadMedication --> SystemAnalysis
    
    SystemAnalysis --> CheckPatterns[التحقق من الأنماط]
    
    CheckPatterns --> HighFasting{سكر صائم مرتفع؟}
    HighFasting -->|نعم| FlagFasting[وضع علامة على الصائم المرتفع]
    HighFasting -->|لا| CheckPostMeal{سكر بعد الأكل مرتفع؟}
    
    FlagFasting --> CheckPostMeal
    
    CheckPostMeal -->|نعم| FlagPostMeal[وضع علامة على بعد الأكل المرتفع]
    CheckPostMeal -->|لا| CheckVariability{تقلبات كبيرة في السكر؟}
    
    FlagPostMeal --> CheckVariability
    
    CheckVariability -->|نعم| FlagVariability[وضع علامة على التقلبات]
    CheckVariability -->|لا| CheckTrends[التحقق من الاتجاهات]
    
    FlagVariability --> CheckTrends
    
    CheckTrends --> RisingTrend{اتجاه تصاعدي في السكر؟}
    RisingTrend -->|نعم| FlagRisingTrend[وضع علامة على الاتجاه التصاعدي]
    RisingTrend -->|لا| CheckCompliance{التزام بالعلاج؟}
    
    FlagRisingTrend --> CheckCompliance
    
    CheckCompliance --> GoodCompliance{التزام جيد؟}
    GoodCompliance -->|نعم| PositiveFeedback[تغذية راجعة إيجابية]
    GoodCompliance -->|لا| FlagNonCompliance[وضع علامة على عدم الالتزام]
    
    PositiveFeedback --> GenerateReport[توليد تقرير إيجابي]
    FlagNonCompliance --> GenerateAlert[توليد تنبيه]
    
    GenerateReport --> SendToPatient[إرسال للمريض]
    GenerateAlert --> SendAlert[إرسال التنبيه]
    
    SendToPatient --> PatientReview[مراجعة المريض]
    SendAlert --> UrgentAction[إجراء عاجل]
    
    PatientReview --> FollowRecommendations[اتباع التوصيات]
    UrgentAction --> ContactDoctor[الاتصال بالطبيب]
    
    FollowRecommendations --> ImproveHealth[تحسين الصحة]
    ContactDoctor --> AdjustTreatment[تعديل العلاج]
    
    ImproveHealth --> ReducedRisk[تقليل المخاطر]
    AdjustTreatment --> BetterControl[تحسين التحكم]
    
    ReducedRisk --> UpdateDashboard2[تحديث اللوحة]
    BetterControl --> UpdateDashboard2
    
    UpdateDashboard2 --> ShowImprovement[عرض التحسن]
    ShowImprovement --> ContinueMonitoring[متابعة المراقبة]
    
    ContinueMonitoring --> Patient
```

## 🔧 Flow Chart لإنشاء خطة وقائية

```mermaid
flowchart TD
    StartCreatePlan[بدء إنشاء خطة] --> SelectRisk[اختيار الخطر المستهدف]
    
    SelectRisk --> DiabetesRisk[خطر السكري]
    SelectRisk --> ObesityRisk[خطر السمنة]
    SelectRisk --> HeartRisk[خطر القلب]
    SelectRisk --> OtherRisk[خطر آخر]
    
    DiabetesRisk --> AnalyzeDiabetesNeeds[تحليل احتياجات السكري]
    ObesityRisk --> AnalyzeObesityNeeds[تحليل احتياجات السمنة]
    HeartRisk --> AnalyzeHeartNeeds[تحليل احتياجات القلب]
    OtherRisk --> AnalyzeOtherNeeds[تحليل احتياجات أخرى]
    
    AnalyzeDiabetesNeeds --> SetDiabetesGoals[تعيين أهداف السكري]
    AnalyzeObesityNeeds --> SetObesityGoals[تعيين أهداف السمنة]
    AnalyzeHeartNeeds --> SetHeartGoals[تعيين أهداف القلب]
    AnalyzeOtherNeeds --> SetOtherGoals[تعيين أهداف أخرى]
    
    SetDiabetesGoals --> CreateDiabetesActions[إنشاء إجراءات السكري]
    SetObesityGoals --> CreateObesityActions[إنشاء إجراءات السمنة]
    SetHeartGoals --> CreateHeartActions[إنشاء إجراءات القلب]
    SetOtherGoals --> CreateOtherActions[إنشاء إجراءات أخرى]
    
    CreateDiabetesActions --> SetDiabetesTimeline[تعيين جدول زمني]
    CreateObesityActions --> SetObesityTimeline[تعيين جدول زمني]
    CreateHeartActions --> SetHeartTimeline[تعيين جدول زمني]
    Create