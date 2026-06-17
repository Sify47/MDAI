# مخططات نظام التحليل التنبؤي الوقائي

## 📊 مخطط تدفق النظام الكلي

```mermaid
flowchart TD
    A[المستخدم] --> B[إدخال البيانات الصحية]
    B --> C[قاعدة البيانات]
    C --> D[وحدة التحليل التنبؤي]
    D --> E{تحليل المخاطر}
    
    E --> F[مخاطر السكري]
    E --> G[مخاطر السمنة]
    E --> H[مخاطر القلب]
    E --> I[مخاطر الضغط]
    E --> J[مخاطر قلة النشاط]
    E --> K[مخاطر سوء التغذية]
    E --> L[مخاطر الإجهاد]
    
    F --> M[تحديد مستوى الخطر]
    G --> M
    H --> M
    I --> M
    J --> M
    K --> M
    L --> M
    
    M --> N[إنشاء توصيات]
    N --> O[عرض النتائج في اللوحة]
    O --> P[إنشاء خطط وقائية]
    P --> Q[متابعة التقدم]
    Q --> R[تحديث اللوحة]
    R --> A
```

## 🏗️ مخطط بنية التطبيق (Architecture)

```mermaid
graph TB
    subgraph Frontend Flutter
        A1[لوحة التحكم Dashboard]
        A2[واجهة المستخدم UI]
        A3[خدمات API]
        A4[إدارة الحالة State]
    end
    
    subgraph Backend FastAPI
        B1[واجهات برمجة التطبيقات APIs]
        B2[منطق التحليل التنبؤي]
        B3[قواعد البيانات]
        B4[نماذج البيانات Models]
    end
    
    subgraph قاعدة البيانات PostgreSQL
        C1[بيانات المستخدمين]
        C2[القياسات الصحية]
        C3[تحليلات المخاطر]
        C4[الخطط الوقائية]
    end
    
    A1 --> A3
    A3 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> C1
    B3 --> C2
    B3 --> C3
    B3 --> C4
    C3 --> B2
    B2 --> B1
    B1 --> A3
    A3 --> A1
```

## 🔄 مخطط تدفق البيانات (Data Flow)

```mermaid
sequenceDiagram
    participant User as المستخدم
    participant UI as واجهة المستخدم
    participant API as خدمات API
    participant Backend as الباك إند
    participant DB as قاعدة البيانات
    participant Analyzer as محرك التحليل
    
    User->>UI: فتح لوحة التحكم
    UI->>API: طلب بيانات اللوحة
    API->>Backend: GET /dashboard
    Backend->>DB: جلب بيانات المستخدم
    DB-->>Backend: البيانات الصحية
    Backend->>Analyzer: تحليل المخاطر
    Analyzer-->>Backend: نتائج التحليل
    Backend->>DB: حفظ النتائج
    DB-->>Backend: تأكيد الحفظ
    Backend-->>API: بيانات اللوحة
    API-->>UI: عرض البيانات
    UI-->>User: عرض اللوحة
    
    User->>UI: نقر زر التحليل
    UI->>API: POST /analyze
    API->>Backend: بدء التحليل الشامل
    Backend->>Analyzer: تحليل جميع المخاطر
    Analyzer-->>Backend: جميع النتائج
    Backend->>DB: حفظ جميع المخاطر
    Backend->>DB: إنشاء خطط وقائية
    DB-->>Backend: تأكيد
    Backend-->>API: نتيجة التحليل
    API-->>UI: تحديث اللوحة
    UI-->>User: عرض النتائج الجديدة
```

## 🧠 مخطط منطق التحليل التنبؤي

```mermaid
flowchart LR
    subgraph Inputs [مدخلات البيانات]
        D1[بيانات التغذية]
        D2[قياسات السكر]
        D3[النشاط البدني]
        D4[التاريخ الصحي]
        D5[العوامل الديموغرافية]
    end
    
    subgraph Analysis [عمليات التحليل]
        A1[تحليل السكري]
        A2[تحليل السمنة]
        A3[تحليل القلب]
        A4[تحليل الضغط]
        A5[تحليل النشاط]
        A6[تحليل التغذية]
        A7[تحليل الإجهاد]
    end
    
    subgraph Scoring [نظام التقييم]
        S1[حساب الاحتمالية]
        S2[تحديد مستوى الخطر]
        S3[تجميع العوامل]
        S4[حساب الثقة]
    end
    
    subgraph Outputs [مخرجات النظام]
        O1[تقرير المخاطر]
        O2[التوصيات]
        O3[الخطط الوقائية]
        O4[مؤشرات التقدم]
    end
    
    Inputs --> Analysis
    Analysis --> Scoring
    Scoring --> Outputs
```

## 📱 مخطط واجهة لوحة التحكم

```mermaid
graph TD
    subgraph Dashboard [لوحة التحكم التنبؤية]
        Header[رأس الصفحة<br/>التنبؤ الوقائي]
        
        subgraph Stats [الإحصائيات السريعة]
            S1[إجمالي المخاطر]
            S2[مخاطر عالية]
            S3[خطط نشطة]
            S4[خطط مكتملة]
        end
        
        subgraph Risks [المخاطر الحديثة]
            R1[قائمة المخاطر]
            R2[مستوى الخطر]
            R3[نسبة الاحتمال]
            R4[التوصيات]
        end
        
        subgraph Plans [الخطط النشطة]
            P1[اسم الخطة]
            P2[الأولوية]
            P3[نسبة التقدم]
            P4[الإجراءات]
        end
        
        subgraph Charts [الرسوم البيانية]
            C1[توزيع المخاطر حسب النوع]
            C2[توزيع المخاطر حسب المستوى]
        end
        
        Controls[أزرار التحكم<br/>تحديث - تحليل]
    end
    
    Header --> Stats
    Stats --> Risks
    Risks --> Plans
    Plans --> Charts
    Charts --> Controls
```

## 🗂️ مخطط هيكل الملفات

```
e:/Flutter/hospital/
├── lib/
│   ├── screens/
│   │   └── predictive_prevention/
│   │       └── predictive_prevention_dashboard.dart    # لوحة التحكم الرئيسية
│   │
│   └── services/
│       └── predictive_prevention_api.dart             # خدمات التواصل مع الباك إند
│
├── back/
│   ├── routers/
│   │   └── predictive_prevention.py                   # واجهات برمجة التطبيقات
│   │
│   ├── models.py                                      # نماذج البيانات
│   └── database.py                                    # اتصال قاعدة البيانات
│
└── plans/
    └── predictive_prevention_diagrams.md              # هذا الملف
```

## ⚙️ مخطط تدفق تحليل المخاطر (مثال: السكري)

```mermaid
flowchart TD
    Start[بدء تحليل السكري] --> GetData[جلب بيانات السكر]
    GetData --> CheckData{هل توجد بيانات؟}
    CheckData -->|لا| ReturnNull[إرجاع لا شيء]
    CheckData -->|نعم| Calculate[حساب المتوسطات]
    
    Calculate --> CheckFasting{سكر صائم > 126؟}
    CheckFasting -->|نعم| HighRisk1[خطر مرتفع]
    CheckFasting -->|لا| CheckFasting2{سكر صائم > 110؟}
    
    CheckFasting2 -->|نعم| MediumRisk1[خطر متوسط]
    CheckFasting2 -->|لا| CheckPostMeal{سكر بعد الأكل > 200؟}
    
    CheckPostMeal -->|نعم| HighRisk2[خطر مرتفع]
    CheckPostMeal -->|لا| CheckPostMeal2{سكر بعد الأكل > 140؟}
    
    CheckPostMeal2 -->|نعم| MediumRisk2[خطر متوسط]
    CheckPostMeal2 -->|لا| LowRisk[خطر منخفض]
    
    HighRisk1 --> AddFactors[إضافة عوامل إضافية]
    HighRisk2 --> AddFactors
    MediumRisk1 --> AddFactors
    MediumRisk2 --> AddFactors
    LowRisk --> AddFactors
    
    AddFactors --> CheckBMI{BMI > 30؟}
    CheckBMI -->|نعم| AddBMI[إضافة عامل السمنة]
    CheckBMI -->|لا| CheckAge{العمر > 45؟}
    
    AddBMI --> CheckAge
    CheckAge -->|نعم| AddAge[إضافة عامل العمر]
    CheckAge -->|لا| GenerateRec[توليد التوصيات]
    
    AddAge --> GenerateRec
    GenerateRec --> ReturnResult[إرجاع نتيجة التحليل]
    ReturnNull --> End[نهاية]
    ReturnResult --> End
```

## 🔗 مخطط التكامل بين المكونات

```mermaid
graph LR
    subgraph Client [عميل Flutter]
        C1[الشاشات Screens]
        C2[الويدجات Widgets]
        C3[خدمات API]
        C4[إدارة الحالة]
    end
    
    subgraph Server [خادم FastAPI]
        S1[الروترات Routers]
        S2[الخدمات Services]
        S3[النماذج Models]
        S4[التحليل التنبؤي]
    end
    
    subgraph Data [طبقة البيانات]
        D1[PostgreSQL]
        D2[الجداول Tables]
        D3[الاستعلامات Queries]
        D4[النسخ الاحتياطي]
    end
    
    C1 --> C3
    C3 --> S1
    S1 --> S2
    S2 --> S4
    S4 --> S3
    S3 --> D2
    D2 --> D1
    D1 --> D3
    D3 --> S3
    S3 --> S4
    S4 --> S2
    S2 --> S1
    S1 --> C3
    C3 --> C4
    C4 --> C1
```

## 📈 مخطط دورة حياة الخطة الوقائية

```mermaid
stateDiagram-v2
    [*] --> Created: إنشاء الخطة
    Created --> Pending: انتظار البدء
    Pending --> InProgress: بدء التنفيذ
    InProgress --> InProgress: تحديث التقدم
    InProgress --> Completed: إكمال جميع الإجراءات
    InProgress --> Paused: إيقاف مؤقت
    Paused --> InProgress: استئناف
    Completed --> [*]: نهاية
    InProgress --> Cancelled: إلغاء
    Paused --> Cancelled: إلغاء
    Cancelled --> [*]: نهاية
    
    note right of Created
        نسبة التقدم: 0%
        الحالة: قيد الإنشاء
    end note
    
    note right of InProgress
        نسبة التقدم: 1-99%
        الحالة: قيد التنفيذ
    end note
    
    note right of Completed
        نسبة التقدم: 100%
        الحالة: مكتمل
    end note
```

---

## 📋 ملخص المخططات

### 1. **مخطط تدفق النظام الكلي**
يظهر المسار الكامل من إدخال البيانات إلى عرض النتائج.

### 2. **مخطط بنية التطبيق**
يوضح العلاقة بين Frontend (Flutter)، Backend (FastAPI)، وقاعدة البيانات.

### 3. **مخطط تدفق البيانات**
يظهر تسلسل الأحداث عند تفاعل المستخدم مع النظام.

### 4. **مخطط منطق التحليل**
يشرح كيفية تحويل البيانات المدخلة إلى نتائج تنبؤية.

### 5. **مخطط واجهة لوحة التحكم**
يصور تخطيط واجهة المستخدم وعناصرها.

### 6. **مخطط هيكل الملفات**
يظهر تنظيم الكود في المشروع.

### 7. **مخطط تحليل المخاطر (مثال السكري)**
يشرح بالتفصيل خوارزمية تحليل أحد أنواع المخاطر.

### 8. **مخطط التكامل بين المكونات**
يوضح كيفية اتصال جميع أجزاء النظام.

### 9. **مخطط دورة حياة الخطة**
يظهر الحالات المختلفة للخطة الوقائية من الإنشاء إلى الإكمال.

---

## 🎯 الاستخدام العملي للمخططات

1. **لفهم النظام**: استخدم المخططات لفهم كيفية عمل النظام ككل
2. **للتطوير**: استخدم مخطط التدفق لإضافة ميزات جديدة
3. **لتصحيح الأخطاء**: استخدم مخطط تدفق البيانات لتتبع المشاكل
4. **للعرض**: استخدم مخطط الواجهة لتصميم تحسينات UI
5. **للتوثيق**: استخدم مخطط الهيكل لفهم تنظيم الكود

هذه المخططات تساعد المطورين والمستخدمين على فهم النظام التنبؤي بشكل مرئي وواضح.