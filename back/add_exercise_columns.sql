-- ============================================
-- 🏋️ SQL Migration: Add Exercise Columns to activities table (Phase A10)
-- ============================================
-- Run this script against your existing database to add the new columns
-- for gym exercise tracking.
--
-- Usage:
--   mysql -u root -p healthmate < back/add_exercise_columns.sql
--   or run inside your MySQL client:
--   SOURCE back/add_exercise_columns.sql;
-- ============================================

ALTER TABLE activities
ADD COLUMN is_exercise BOOLEAN DEFAULT FALSE,
ADD COLUMN exercise_name VARCHAR(200) NULL,
ADD COLUMN exercise_name_en VARCHAR(200) NULL,
ADD COLUMN exercise_id VARCHAR(50) NULL,
ADD COLUMN muscle_group VARCHAR(100) NULL,
ADD COLUMN muscle_group_en VARCHAR(100) NULL,
ADD COLUMN met_value FLOAT NULL,
ADD COLUMN sets INT NULL,
ADD COLUMN reps INT NULL,
ADD COLUMN weight_kg FLOAT NULL,
ADD COLUMN rest_seconds INT NULL,
ADD COLUMN calories_burned INT NULL,
ADD COLUMN plan_id INT NULL,
ADD COLUMN plan_name VARCHAR(200) NULL;

-- Add foreign key for plan_id (if the activity_plans table exists)
-- Uncomment if you need the FK constraint:
-- ALTER TABLE activities
--   ADD CONSTRAINT fk_activity_plan
--   FOREIGN KEY (plan_id) REFERENCES activity_plans(id)
--   ON DELETE SET NULL;