-- إضافة عمود fcm_token لجدول users
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500) NULL UNIQUE;
CREATE INDEX idx_users_fcm_token ON users(fcm_token);