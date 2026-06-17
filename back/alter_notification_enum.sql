-- Fix: Add 'summary' to the notification_type ENUM in notification_logs table
-- The model Enum was missing 'summary' which is used by create_daily_summary()

ALTER TABLE notification_logs 
MODIFY COLUMN notification_type ENUM('medication', 'water', 'activity', 'general', 'summary') NOT NULL;