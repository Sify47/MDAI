-- ============================================
-- 🏋️ SQL Migration: Create activity_exercises table for multi-exercise support
-- ============================================
-- This table allows an activity to have MULTIPLE exercises (instead of the
-- old flat-column approach that limited to one exercise per activity).
--
-- Existing activities with flat exercise columns remain backward compatible.
-- New exercises will be stored in this normalized table.
--
-- Usage:
--   mysql -u root -p healthmate < back/add_activity_exercises_table.sql
--   or run inside your MySQL client:
--   SOURCE back/add_activity_exercises_table.sql;
-- ============================================

CREATE TABLE IF NOT EXISTS activity_exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    activity_id INT NOT NULL,
    exercise_id VARCHAR(50) NULL,
    exercise_name_ar VARCHAR(200) NULL,
    exercise_name_en VARCHAR(200) NULL,
    muscle_group VARCHAR(100) NULL,
    muscle_group_en VARCHAR(100) NULL,
    met_value FLOAT NULL,
    sets INT NULL,
    reps INT NULL,
    weight_kg FLOAT NULL,
    rest_seconds INT NULL,
    calories_burned INT NULL,
    order_index INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE,
    INDEX idx_activity_exercises_activity (activity_id)
);