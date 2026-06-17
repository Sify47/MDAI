-- إضافة عمود activity_type إلى جدول walking_activities
-- هذا العمود موجود في نموذج SQLAlchemy ولكنه مفقود من قاعدة البيانات

ALTER TABLE walking_activities
ADD COLUMN activity_type VARCHAR(50) NULL DEFAULT 'walking'
COMMENT 'نوع النشاط: walking, running, cycling, etc.';

-- database_schema.sql
-- قاعدة بيانات عقارات مصر - Real Estate Egypt Database

-- إنشاء قاعدة البيانات
CREATE DATABASE IF NOT EXISTS real_estate_db;

USE real_estate_db;

-- =====================================================
-- 1. جدول العقارات (Properties)
-- =====================================================
DROP TABLE IF EXISTS properties;

CREATE TABLE properties (
    id INT PRIMARY KEY AUTO_INCREMENT,
    link VARCHAR(500) UNIQUE,
    title TEXT,
    property_type VARCHAR(100),
    price DECIMAL(15,2),
    location VARCHAR(255),
    state VARCHAR(100),
    area DECIMAL(10,2),
    bedrooms INT,
    bathrooms INT,
    down_payment DECIMAL(15,2) DEFAULT 0,
    payment_method VARCHAR(50) DEFAULT 'Cash',
    price_per_m DECIMAL(12,2),
    source VARCHAR(50) DEFAULT 'bayut',
    status VARCHAR(50) DEFAULT 'active',
    is_active BOOLEAN DEFAULT TRUE,
    scrape_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    buy_score DECIMAL(5,2) DEFAULT 0,
    value_score DECIMAL(5,2) DEFAULT 0,
    investment_score DECIMAL(5,2) DEFAULT 0,
    description TEXT,
    features TEXT,
    user_id INT,

-- فهارس للبحث السريع
INDEX idx_state (state),
    INDEX idx_location (location),
    INDEX idx_price (price),
    INDEX idx_price_per_m (price_per_m),
    INDEX idx_scrape_date (scrape_date),
    INDEX idx_property_type (property_type),
    INDEX idx_bedrooms (bedrooms),
    INDEX idx_buy_score (buy_score),
    INDEX idx_is_active (is_active),
    FULLTEXT INDEX idx_title_search (title),
    FULLTEXT INDEX idx_location_search (location, state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 2. جدول ذكاء المناطق (Area Intelligence)
-- =====================================================
DROP TABLE IF EXISTS area_intelligence;

CREATE TABLE area_intelligence (
    id INT PRIMARY KEY AUTO_INCREMENT,
    area_name VARCHAR(255) UNIQUE NOT NULL,
    state VARCHAR(100),
    category VARCHAR(100),
    demand_type VARCHAR(100),
    near_sea BOOLEAN DEFAULT FALSE,
    schools_quality DECIMAL(3, 1) DEFAULT 3.0 CHECK (
        schools_quality BETWEEN 1 AND 5
    ),
    services_level DECIMAL(3, 1) DEFAULT 3.0 CHECK (
        services_level BETWEEN 1 AND 5
    ),
    transportation DECIMAL(3, 1) DEFAULT 3.0 CHECK (
        transportation BETWEEN 1 AND 5
    ),
    investment_potential DECIMAL(3, 1) DEFAULT 3.0 CHECK (
        investment_potential BETWEEN 1 AND 5
    ),
    resale_liquidity DECIMAL(3, 1) DEFAULT 3.0 CHECK (
        resale_liquidity BETWEEN 1 AND 5
    ),
    area_score INT DEFAULT 70 CHECK (area_score BETWEEN 0 AND 100),
    key_insights TEXT,
    safety_score DECIMAL(3, 1) DEFAULT 3.0 CHECK (safety_score BETWEEN 1 AND 5),
    nightlife_score DECIMAL(3, 1) DEFAULT 3.0 CHECK (
        nightlife_score BETWEEN 1 AND 5
    ),
    family_friendly BOOLEAN DEFAULT TRUE,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_area_name (area_name),
    INDEX idx_state (state),
    INDEX idx_area_score (area_score),
    INDEX idx_category (category),
    INDEX idx_investment_potential (investment_potential)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 3. جدول سجل الجمع (Scraping History)
-- =====================================================
DROP TABLE IF EXISTS scraping_history;

CREATE TABLE scraping_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    source VARCHAR(50),
    properties_found INT DEFAULT 0,
    properties_added INT DEFAULT 0,
    properties_updated INT DEFAULT 0,
    start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    end_time DATETIME,
    status VARCHAR(50),
    error_message TEXT,
    INDEX idx_start_time (start_time),
    INDEX idx_source (source),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 4. جدول توقعات الأسعار (Price Predictions)
-- =====================================================
DROP TABLE IF EXISTS price_predictions;

CREATE TABLE price_predictions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    location VARCHAR(255),
    property_type VARCHAR(100),
    predicted_price DECIMAL(15, 2),
    predicted_price_per_m DECIMAL(12, 2),
    confidence_lower DECIMAL(15, 2),
    confidence_upper DECIMAL(15, 2),
    prediction_date DATE DEFAULT(CURRENT_DATE),
    model_version VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location (location),
    INDEX idx_prediction_date (prediction_date),
    INDEX idx_property_type (property_type)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 5. جدول تفضيلات المستخدمين (User Preferences)
-- =====================================================
DROP TABLE IF EXISTS user_preferences;

CREATE TABLE user_preferences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_email VARCHAR(255),
    user_id INT,
    min_price DECIMAL(15, 2),
    max_price DECIMAL(15, 2),
    preferred_locations TEXT,
    min_area INT,
    max_area INT,
    bedrooms INT,
    property_type VARCHAR(100),
    payment_method VARCHAR(50),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_email (user_email),
    INDEX idx_user_id (user_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 6. جدول العقارات المفضلة (User Property Favorites)
-- =====================================================
DROP TABLE IF EXISTS user_property_favorites;

CREATE TABLE user_property_favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    property_id INT NOT NULL,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user_property (user_id, property_id),
    INDEX idx_user_id (user_id),
    INDEX idx_property_id (property_id),
    FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 7. جدول تنبيهات العقارات (Property Alerts)
-- =====================================================
DROP TABLE IF EXISTS property_alerts;

CREATE TABLE property_alerts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    alert_name VARCHAR(100),
    location VARCHAR(255),
    min_price DECIMAL(15, 2),
    max_price DECIMAL(15, 2),
    min_area INT,
    max_area INT,
    bedrooms INT,
    property_type VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_is_active (is_active),
    INDEX idx_location (location)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 8. جدول التحليل الزمني (Time Series Analysis)
-- =====================================================
DROP TABLE IF EXISTS price_history;

CREATE TABLE price_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    property_id INT,
    price DECIMAL(15, 2),
    price_per_m DECIMAL(12, 2),
    record_date DATE,
    INDEX idx_property_id (property_id),
    INDEX idx_record_date (record_date),
    FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- 9. جدول إحصائيات يومية (Daily Statistics)
-- =====================================================
DROP TABLE IF EXISTS daily_stats;

CREATE TABLE daily_stats (
    id INT PRIMARY KEY AUTO_INCREMENT,
    stat_date DATE UNIQUE,
    total_properties INT,
    avg_price DECIMAL(15, 2),
    avg_price_per_m DECIMAL(12, 2),
    new_properties INT,
    updated_properties INT,
    avg_buy_score DECIMAL(5, 2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_stat_date (stat_date)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =====================================================
-- إدخال بيانات ذكاء المناطق (Area Intelligence)
-- =====================================================
INSERT INTO
    area_intelligence (
        area_name,
        state,
        category,
        demand_type,
        near_sea,
        schools_quality,
        services_level,
        transportation,
        investment_potential,
        resale_liquidity,
        area_score,
        key_insights,
        safety_score,
        family_friendly
    )
VALUES (
        'Smouha',
        'Alexandria',
        'High-End',
        'Family-Residential',
        0,
        5,
        5,
        4,
        5,
        5,
        92,
        'Elite schools, club proximity, strong resale market',
        4.5,
        TRUE
    ),
    (
        'New Smouha',
        'Alexandria',
        'High-End',
        'Family-Residential',
        0,
        4,
        4,
        3,
        4,
        4,
        85,
        'Modern compounds, growing demand',
        4.0,
        TRUE
    ),
    (
        'Veranda Smouha',
        'Alexandria',
        'High-End',
        'Gated-Community',
        0,
        4,
        4,
        3,
        4,
        4,
        83,
        'Secure compound, limited supply',
        4.5,
        TRUE
    ),
    (
        'Sporting',
        'Alexandria',
        'Upper-Middle',
        'Family-Classic',
        0,
        4,
        3,
        4,
        3,
        4,
        78,
        'Classic area, stable pricing',
        4.0,
        TRUE
    ),
    (
        'Sidi Gaber',
        'Alexandria',
        'Upper-Middle',
        'Investment-Rental',
        1,
        3,
        4,
        5,
        5,
        5,
        88,
        'Transport hub, high rental yield',
        3.5,
        FALSE
    ),
    (
        'Stanley',
        'Alexandria',
        'Luxury',
        'Luxury-SeaView',
        1,
        4,
        5,
        4,
        5,
        4,
        90,
        'Iconic bridge, premium sea views',
        4.0,
        FALSE
    ),
    (
        'Glim',
        'Alexandria',
        'Upper-Middle',
        'Mixed-Use',
        1,
        3,
        3,
        4,
        3,
        3,
        74,
        'Tram access, mid-range prices',
        3.5,
        FALSE
    ),
    (
        'San Stefano',
        'Alexandria',
        'Luxury',
        'Luxury-Investment',
        1,
        5,
        5,
        4,
        5,
        5,
        95,
        'Top-tier luxury, tourism & resale',
        4.5,
        FALSE
    ),
    (
        'Roushdy',
        'Alexandria',
        'Upper-Middle',
        'Balanced-Family',
        0,
        4,
        4,
        4,
        4,
        4,
        82,
        'Balanced price-to-location ratio',
        4.0,
        TRUE
    ),
    (
        'Fleming',
        'Alexandria',
        'Upper-Middle',
        'Rental-Oriented',
        0,
        3,
        3,
        4,
        4,
        4,
        77,
        'Strong rental demand',
        3.5,
        FALSE
    ),
    (
        'Cleopatra',
        'Alexandria',
        'Upper-Middle',
        'High-Density',
        0,
        3,
        3,
        4,
        3,
        3,
        72,
        'Dense but central',
        3.0,
        FALSE
    ),
    (
        'Janaklees',
        'Alexandria',
        'Upper-Middle',
        'Family-Residential',
        0,
        3,
        3,
        4,
        3,
        3,
        73,
        'Quiet streets, family appeal',
        4.0,
        TRUE
    ),
    (
        'Montazah',
        'Alexandria',
        'Upper-Middle',
        'Leisure-Residential',
        1,
        3,
        3,
        3,
        3,
        3,
        76,
        'Green areas, touristic value',
        4.0,
        TRUE
    ),
    (
        'Maamoura',
        'Alexandria',
        'Middle',
        'Seasonal-Residential',
        1,
        3,
        2,
        2,
        3,
        2,
        68,
        'Summer-focused demand',
        3.5,
        TRUE
    ),
    (
        'Miami',
        'Alexandria',
        'Middle',
        'High-Density',
        1,
        2,
        2,
        3,
        2,
        2,
        62,
        'Affordable coastal housing',
        2.5,
        FALSE
    ),
    (
        'New Miami',
        'Alexandria',
        'Middle',
        'Affordable-Residential',
        1,
        2,
        2,
        3,
        2,
        2,
        60,
        'Lower prices, high density',
        2.5,
        FALSE
    ),
    (
        'Asafra',
        'Alexandria',
        'Middle',
        'Popular-Housing',
        1,
        2,
        2,
        3,
        2,
        2,
        61,
        'Mass-market demand',
        2.5,
        FALSE
    ),
    (
        'Mandara',
        'Alexandria',
        'Middle',
        'Popular-Housing',
        1,
        2,
        2,
        3,
        2,
        2,
        63,
        'Affordable seaside living',
        2.5,
        FALSE
    ),
    (
        'Raml Station',
        'Alexandria',
        'Commercial-Historic',
        'Commercial-Tourism',
        1,
        3,
        4,
        5,
        4,
        4,
        80,
        'Tourism & business hub',
        3.0,
        FALSE
    ),
    (
        'Manshiyya',
        'Alexandria',
        'Commercial-Historic',
        'Administrative',
        0,
        2,
        3,
        5,
        3,
        3,
        70,
        'Government & courts',
        2.5,
        FALSE
    ),
    (
        'Attarin',
        'Alexandria',
        'Commercial-Historic',
        'Traditional-Commerce',
        0,
        2,
        2,
        4,
        2,
        2,
        65,
        'Old markets & trade',
        2.0,
        FALSE
    ),
    (
        'Anfoshy',
        'Alexandria',
        'Historic',
        'Heritage-Coastal',
        1,
        2,
        2,
        3,
        2,
        2,
        67,
        'Cultural & fishing area',
        2.5,
        FALSE
    ),
    (
        'Shatby',
        'Alexandria',
        'Student-Area',
        'Student-Rental',
        1,
        3,
        3,
        4,
        4,
        4,
        79,
        'University-driven rentals',
        3.0,
        FALSE
    ),
    (
        'Azarita',
        'Alexandria',
        'Student-Area',
        'Medical-Rental',
        0,
        3,
        3,
        4,
        4,
        4,
        78,
        'Hospitals & students',
        3.0,
        FALSE
    ),
    (
        'Camp Chezar',
        'Alexandria',
        'Upper-Middle',
        'Classic-SeaSide',
        1,
        4,
        4,
        3,
        4,
        4,
        84,
        'Classic sea-facing buildings',
        3.5,
        FALSE
    ),
    (
        'Agami',
        'Alexandria',
        'Economic',
        'Seasonal-LowCost',
        1,
        1,
        1,
        2,
        2,
        1,
        50,
        'Low entry price, weak resale',
        2.0,
        FALSE
    ),
    (
        'Borg El Arab',
        'Alexandria',
        'Industrial-New',
        'Industrial-Investment',
        0,
        2,
        3,
        3,
        4,
        2,
        69,
        'Industrial employment driver',
        2.5,
        FALSE
    ),
    (
        'Borg El Arab City',
        'Alexandria',
        'Industrial-New',
        'Planned-City',
        0,
        3,
        3,
        3,
        4,
        3,
        72,
        'Future growth potential',
        3.0,
        TRUE
    ),
    (
        'Amreya',
        'Alexandria',
        'Economic',
        'Industrial-Housing',
        0,
        1,
        2,
        2,
        2,
        1,
        48,
        'Worker housing',
        1.5,
        FALSE
    ),
    (
        'King Mariout',
        'Alexandria',
        'Economic',
        'Logistics-Industrial',
        0,
        1,
        2,
        2,
        2,
        1,
        46,
        'Logistics & industrial zone',
        1.5,
        FALSE
    );

-- =====================================================
-- إضافة بيانات القاهرة والجيزة
-- =====================================================
INSERT INTO
    area_intelligence (
        area_name,
        state,
        category,
        demand_type,
        near_sea,
        schools_quality,
        services_level,
        transportation,
        investment_potential,
        resale_liquidity,
        area_score,
        key_insights,
        safety_score,
        family_friendly
    )
VALUES (
        'Maadi',
        'Cairo',
        'Upper-Middle',
        'Family-Residential',
        0,
        4.5,
        4.5,
        4,
        4,
        4.5,
        80,
        'Family area, good schools, green spaces',
        4.5,
        TRUE
    ),
    (
        'New Cairo',
        'Cairo',
        'High-End',
        'Modern-Compounds',
        0,
        5,
        5,
        3.5,
        5,
        5,
        90,
        'Modern compounds, high demand',
        4.5,
        TRUE
    ),
    (
        'Sheikh Zayed',
        'Giza',
        'High-End',
        'Luxury-Compounds',
        0,
        4.5,
        4.5,
        4,
        4.5,
        4.5,
        85,
        'Luxury compounds, international schools',
        4.5,
        TRUE
    ),
    (
        '6th October',
        'Giza',
        'Upper-Middle',
        'Established-Area',
        0,
        4,
        4,
        3.5,
        4,
        4,
        75,
        'Established area, good value',
        4.0,
        TRUE
    ),
    (
        'Palm Hills',
        'Giza',
        'High-End',
        'Gated-Community',
        0,
        5,
        5,
        4,
        4.5,
        4.5,
        88,
        'Golf course, luxury living',
        5.0,
        TRUE
    ),
    (
        'Downtown Cairo',
        'Cairo',
        'Commercial',
        'Business-Central',
        0,
        3,
        4,
        5,
        4,
        3.5,
        70,
        'Central business district',
        2.5,
        FALSE
    ),
    (
        'Heliopolis',
        'Cairo',
        'Upper-Middle',
        'Historic-Elegant',
        0,
        4.5,
        4,
        4.5,
        4,
        4.5,
        82,
        'Historic charm, wide streets',
        4.0,
        TRUE
    ),
    (
        'Nasr City',
        'Cairo',
        'Upper-Middle',
        'High-Density',
        0,
        3.5,
        4,
        4.5,
        3.5,
        4,
        72,
        'Dense residential, good services',
        3.5,
        TRUE
    );

-- =====================================================
-- إجراء مخزن لحساب Buy Score تلقائياً
-- =====================================================
DELIMITER / /

CREATE TRIGGER calculate_buy_score_before_insert
BEFORE INSERT ON properties
FOR EACH ROW
BEGIN
    DECLARE area_score_val INT DEFAULT 70;
    
    -- الحصول على Area Score من جدول ذكاء المناطق
    SELECT area_score INTO area_score_val
    FROM area_intelligence
    WHERE area_name = NEW.location OR area_name = NEW.state
    LIMIT 1;
    
    -- حساب Buy Score
    SET NEW.buy_score = (
        (CASE WHEN NEW.price_per_m < 15000 THEN 100 ELSE 0 END) * 0.30 +
        (area_score_val / 100) * 0.40 +
        (SELECT investment_potential / 5 FROM area_intelligence WHERE area_name = NEW.location LIMIT 1) * 0.30
    ) * 100;
    
    SET NEW.price_per_m = NEW.price / NEW.area;
END//

DELIMITER;

-- =====================================================
-- عرض لإحصائيات سريعة
-- =====================================================
CREATE OR REPLACE VIEW vw_property_stats AS
SELECT
    state,
    COUNT(*) as total_properties,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(AVG(price_per_m), 2) as avg_price_per_m,
    ROUND(AVG(area), 2) as avg_area,
    ROUND(AVG(buy_score), 2) as avg_buy_score,
    MIN(price) as min_price,
    MAX(price) as max_price,
    SUM(
        CASE
            WHEN payment_method = 'Installments' THEN 1
            ELSE 0
        END
    ) as installment_count,
    SUM(
        CASE
            WHEN payment_method = 'Cash' THEN 1
            ELSE 0
        END
    ) as cash_count
FROM properties
WHERE
    is_active = TRUE
GROUP BY
    state;

-- =====================================================
-- عرض لأفضل مناطق الشراء
-- =====================================================
CREATE OR REPLACE VIEW vw_best_buy_areas AS
SELECT
    a.area_name,
    a.state,
    a.area_score,
    a.investment_potential,
    a.resale_liquidity,
    a.key_insights,
    COUNT(p.id) as available_properties,
    ROUND(AVG(p.price_per_m), 2) as current_avg_price,
    ROUND(AVG(p.buy_score), 2) as avg_buy_score
FROM
    area_intelligence a
    LEFT JOIN properties p ON (
        p.location = a.area_name
        OR p.state = a.area_name
    )
    AND p.is_active = TRUE
GROUP BY
    a.area_name,
    a.state,
    a.area_score,
    a.investment_potential,
    a.resale_liquidity,
    a.key_insights
ORDER BY avg_buy_score DESC, area_score DESC;

-- =====================================================
-- فهارس إضافية لتحسين الأداء
-- =====================================================
CREATE INDEX idx_properties_location_price ON properties (location, price);

CREATE INDEX idx_properties_state_buyscore ON properties (state, buy_score);

CREATE INDEX idx_properties_scrape_date_price ON properties (scrape_date, price);

CREATE INDEX idx_area_intelligence_score ON area_intelligence (
    area_score,
    investment_potential
);

-- =====================================================
-- صلاحيات المستخدم (اختياري)
-- =====================================================
-- CREATE USER IF NOT EXISTS 'app_user'@'localhost' IDENTIFIED BY 'your_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON real_estate_db.* TO 'app_user'@'localhost';
-- FLUSH PRIVILEGES;

-- =====================================================
-- عرض جميع الجداول
-- =====================================================
SHOW TABLES;