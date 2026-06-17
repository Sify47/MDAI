-- SQL Schema for New VITA Features
-- This file contains the SQL statements to create the new tables for the VITA transformation features

-- --------------------------------------------------------
--
-- Table structure for table `behavioral_nudges`
--

CREATE TABLE IF NOT EXISTS `behavioral_nudges` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `title` varchar(200) NOT NULL,
    `message` text NOT NULL,
    `nudge_type` enum(
        'motivational',
        'educational',
        'reminder',
        'warning',
        'encouragement',
        'celebration',
        'habit_building',
        'health_insight'
    ) NOT NULL,
    `priority` enum(
        'low',
        'medium',
        'high',
        'critical'
    ) NOT NULL,
    `context` enum(
        'morning_routine',
        'evening_routine',
        'activity_tracking',
        'hydration',
        'nutrition',
        'medication',
        'daily_quiz',
        'general'
    ) NOT NULL,
    `status` enum(
        'pending',
        'delivered',
        'action_taken',
        'dismissed',
        'expired'
    ) DEFAULT 'pending',
    `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
    `delivered_at` datetime DEFAULT NULL,
    `action_taken_at` datetime DEFAULT NULL,
    `dismissed_at` datetime DEFAULT NULL,
    `expires_at` datetime DEFAULT NULL,
    `created_at` datetime DEFAULT current_timestamp(),
    `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `user_id` (`user_id`),
    KEY `idx_nudge_status` (`status`),
    KEY `idx_nudge_priority` (`priority`),
    KEY `idx_nudge_context` (`context`),
    CONSTRAINT `behavioral_nudges_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `behavioral_patterns`
--

CREATE TABLE IF NOT EXISTS `behavioral_patterns` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `pattern_type` varchar(100) NOT NULL,
    `description` text NOT NULL,
    `frequency` int(11) NOT NULL,
    `severity` enum('low', 'medium', 'high') NOT NULL,
    `start_date` date NOT NULL,
    `end_date` date DEFAULT NULL,
    `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
    `created_at` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `user_id` (`user_id`),
    KEY `idx_pattern_type` (`pattern_type`),
    KEY `idx_pattern_severity` (`severity`),
    CONSTRAINT `behavioral_patterns_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `health_risks`
--

CREATE TABLE IF NOT EXISTS `health_risks` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `risk_type` varchar(100) NOT NULL,
    `risk_level` enum(
        'low',
        'medium',
        'high',
        'critical'
    ) NOT NULL,
    `probability` float NOT NULL,
    `confidence` float NOT NULL,
    `factors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`factors`)),
    `timeframe` enum(
        'immediate',
        'short_term',
        'medium_term',
        'long_term'
    ) NOT NULL,
    `description` text NOT NULL,
    `recommendations` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`recommendations`)),
    `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
    `created_at` datetime DEFAULT current_timestamp(),
    `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `user_id` (`user_id`),
    KEY `idx_risk_type` (`risk_type`),
    KEY `idx_risk_level` (`risk_level`),
    KEY `idx_risk_timeframe` (`timeframe`),
    CONSTRAINT `health_risks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `prevention_plans`
--

CREATE TABLE IF NOT EXISTS `prevention_plans` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `risk_id` int(11) NOT NULL,
    `plan_name` varchar(200) NOT NULL,
    `description` text NOT NULL,
    `actions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`actions`)),
    `timeline_days` int(11) NOT NULL,
    `priority` enum(
        'low',
        'medium',
        'high',
        'critical'
    ) DEFAULT 'medium',
    `progress_percentage` float DEFAULT 0,
    `status` enum(
        'not_started',
        'in_progress',
        'completed',
        'paused',
        'cancelled'
    ) DEFAULT 'not_started',
    `start_date` date DEFAULT NULL,
    `target_completion_date` date DEFAULT NULL,
    `actual_completion_date` date DEFAULT NULL,
    `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
    `created_at` datetime DEFAULT current_timestamp(),
    `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `user_id` (`user_id`),
    KEY `risk_id` (`risk_id`),
    KEY `idx_plan_status` (`status`),
    KEY `idx_plan_priority` (`priority`),
    CONSTRAINT `prevention_plans_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `prevention_plans_ibfk_2` FOREIGN KEY (`risk_id`) REFERENCES `health_risks` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `daily_quiz_sessions`
-- Note: This is separate from the existing monthly quiz system
--

CREATE TABLE IF NOT EXISTS `daily_quiz_sessions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `quiz_type` enum('morning', 'evening') NOT NULL,
    `session_date` date NOT NULL,
    `mood_score` int(11) DEFAULT NULL COMMENT '1-5',
    `energy_level` int(11) DEFAULT NULL COMMENT '1-5',
    `sleep_quality` int(11) DEFAULT NULL COMMENT '1-5',
    `stress_level` int(11) DEFAULT NULL COMMENT '1-5',
    `hydration_status` int(11) DEFAULT NULL COMMENT '1-5',
    `physical_activity` int(11) DEFAULT NULL COMMENT '1-5',
    `nutrition_quality` int(11) DEFAULT NULL COMMENT '1-5',
    `medication_adherence` int(11) DEFAULT NULL COMMENT '1-5',
    `notes` text DEFAULT NULL,
    `total_score` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_daily_quiz` (
        `user_id`,
        `quiz_type`,
        `session_date`
    ),
    KEY `user_id` (`user_id`),
    KEY `idx_quiz_type_date` (`quiz_type`, `session_date`),
    CONSTRAINT `daily_quiz_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `daily_quiz_questions`
-- Note: Questions for morning and evening daily quizzes (separate from monthly quiz)
--

CREATE TABLE IF NOT EXISTS `daily_quiz_questions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `question_text` varchar(500) NOT NULL,
    `question_type` enum('morning', 'evening', 'both') NOT NULL DEFAULT 'both',
    `category` enum(
        'mood',
        'energy',
        'sleep',
        'stress',
        'hydration',
        'activity',
        'nutrition',
        'medication',
        'general'
    ) NOT NULL,
    `default_order` int(11) DEFAULT 0,
    `is_active` tinyint(1) DEFAULT 1,
    `created_at` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `idx_question_type` (`question_type`),
    KEY `idx_category` (`category`),
    KEY `idx_is_active` (`is_active`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `daily_quiz_options`
-- Note: Answer options for daily quiz questions
--

CREATE TABLE IF NOT EXISTS `daily_quiz_options` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `question_id` int(11) NOT NULL,
    `option_text` varchar(200) NOT NULL,
    `score_value` int(11) DEFAULT 0 COMMENT 'Score for this option (1-5 scale)',
    `order` int(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `question_id` (`question_id`),
    CONSTRAINT `daily_quiz_options_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `daily_quiz_questions` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `daily_quiz_answers`
-- Note: User answers for daily quiz sessions
--

CREATE TABLE IF NOT EXISTS `daily_quiz_answers` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `session_id` int(11) NOT NULL,
    `question_id` int(11) NOT NULL,
    `selected_option_id` int(11) NOT NULL,
    `score` int(11) DEFAULT NULL,
    `created_at` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_session_question` (`session_id`, `question_id`),
    KEY `session_id` (`session_id`),
    KEY `question_id` (`question_id`),
    KEY `selected_option_id` (`selected_option_id`),
    CONSTRAINT `daily_quiz_answers_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `daily_quiz_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `daily_quiz_answers_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `daily_quiz_questions` (`id`),
    CONSTRAINT `daily_quiz_answers_ibfk_3` FOREIGN KEY (`selected_option_id`) REFERENCES `daily_quiz_options` (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `community_posts`
--

CREATE TABLE IF NOT EXISTS `community_posts` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `title` varchar(200) DEFAULT NULL,
    `content` text NOT NULL,
    `post_type` enum(
        'question',
        'experience',
        'tip',
        'achievement',
        'support'
    ) NOT NULL,
    `condition_tags` varchar(500) DEFAULT NULL COMMENT 'JSON array of conditions like ["diabetes", "hypertension"]',
    `privacy` enum(
        'public',
        'followers_only',
        'private'
    ) DEFAULT 'public',
    `like_count` int(11) DEFAULT 0,
    `comment_count` int(11) DEFAULT 0,
    `share_count` int(11) DEFAULT 0,
    `is_pinned` tinyint(1) DEFAULT 0,
    `is_edited` tinyint(1) DEFAULT 0,
    `edited_at` datetime DEFAULT NULL,
    `created_at` datetime DEFAULT current_timestamp(),
    `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `user_id` (`user_id`),
    KEY `idx_post_type` (`post_type`),
    KEY `idx_created_at` (`created_at`),
    CONSTRAINT `community_posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `community_comments`
--

CREATE TABLE IF NOT EXISTS `community_comments` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `post_id` int(11) NOT NULL,
    `user_id` int(11) NOT NULL,
    `content` text NOT NULL,
    `like_count` int(11) DEFAULT 0,
    `is_edited` tinyint(1) DEFAULT 0,
    `edited_at` datetime DEFAULT NULL,
    `created_at` datetime DEFAULT current_timestamp(),
    `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `post_id` (`post_id`),
    KEY `user_id` (`user_id`),
    CONSTRAINT `community_comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `community_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Table structure for table `community_likes`
--

CREATE TABLE IF NOT EXISTS `community_likes` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `post_id` int(11) DEFAULT NULL,
    `comment_id` int(11) DEFAULT NULL,
    `user_id` int(11) NOT NULL,
    `created_at` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_like` (
        `post_id`,
        `comment_id`,
        `user_id`
    ),
    KEY `post_id` (`post_id`),
    KEY `comment_id` (`comment_id`),
    KEY `user_id` (`user_id`),
    CONSTRAINT `community_likes_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `community_likes_ibfk_2` FOREIGN KEY (`comment_id`) REFERENCES `community_comments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `community_likes_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
--
-- Indexes for the new tables (to be added to existing index section)
--

-- ALTER TABLE `behavioral_nudges`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `user_id` (`user_id`),
--   ADD KEY `idx_nudge_status` (`status`),
--   ADD KEY `idx_nudge_priority` (`priority`),
--   ADD KEY `idx_nudge_context` (`context`);

-- ALTER TABLE `behavioral_patterns`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `user_id` (`user_id`),
--   ADD KEY `idx_pattern_type` (`pattern_type`),
--   ADD KEY `idx_pattern_severity` (`severity`);

-- ALTER TABLE `health_risks`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `user_id` (`user_id`),
--   ADD KEY `idx_risk_type` (`risk_type`),
--   ADD KEY `idx_risk_level` (`risk_level`),
--   ADD KEY `idx_risk_timeframe` (`timeframe`);

-- ALTER TABLE `prevention_plans`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `user_id` (`user_id`),
--   ADD KEY `risk_id` (`risk_id`),
--   ADD KEY `idx_plan_status` (`status`),
--   ADD KEY `idx_plan_priority` (`priority`);

-- ALTER TABLE `daily_quiz_sessions`
--   ADD PRIMARY KEY (`id`),
--   ADD UNIQUE KEY `unique_daily_quiz` (`user_id`, `quiz_type`, `session_date`),
--   ADD KEY `user_id` (`user_id`),
--   ADD KEY `idx_quiz_type_date` (`quiz_type`, `session_date`);

-- ALTER TABLE `daily_quiz_questions`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `idx_question_type` (`question_type`),
--   ADD KEY `idx_category` (`category`),
--   ADD KEY `idx_is_active` (`is_active`);

-- ALTER TABLE `daily_quiz_options`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `question_id` (`question_id`);

-- ALTER TABLE `daily_quiz_answers`
--   ADD PRIMARY KEY (`id`),
--   ADD UNIQUE KEY `unique_session_question` (`session_id`, `question_id`),
--   ADD KEY `session_id` (`session_id`),
--   ADD KEY `question_id` (`question_id`),
--   ADD KEY `selected_option_id` (`selected_option_id`);

-- ALTER TABLE `community_posts`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `user_id` (`user_id`),
--   ADD KEY `idx_post_type` (`post_type`),
--   ADD KEY `idx_created_at` (`created_at`);

-- ALTER TABLE `community_comments`
--   ADD PRIMARY KEY (`id`),
--   ADD KEY `post_id` (`post_id`),
--   ADD KEY `user_id` (`user_id`);

-- ALTER TABLE `community_likes`
--   ADD PRIMARY KEY (`id`),
--   ADD UNIQUE KEY `unique_like` (`post_id`, `comment_id`, `user_id`),
--   ADD KEY `post_id` (`post_id`),
--   ADD KEY `comment_id` (`comment_id`),
--   ADD KEY `user_id` (`user_id`);

-- --------------------------------------------------------
--
-- Foreign key constraints (to be added to existing constraints section)
--

-- ALTER TABLE `behavioral_nudges`
--   ADD CONSTRAINT `behavioral_nudges_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `behavioral_patterns`
--   ADD CONSTRAINT `behavioral_patterns_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `health_risks`
--   ADD CONSTRAINT `health_risks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `prevention_plans`
--   ADD CONSTRAINT `prevention_plans_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `prevention_plans_ibfk_2` FOREIGN KEY (`risk_id`) REFERENCES `health_risks` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `daily_quiz_sessions`
--   ADD CONSTRAINT `daily_quiz_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `daily_quiz_options`
--   ADD CONSTRAINT `daily_quiz_options_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `daily_quiz_questions` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `daily_quiz_answers`
--   ADD CONSTRAINT `daily_quiz_answers_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `daily_quiz_sessions` (`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `daily_quiz_answers_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `daily_quiz_questions` (`id`),
--   ADD CONSTRAINT `daily_quiz_answers_ibfk_3` FOREIGN KEY (`selected_option_id`) REFERENCES `daily_quiz_options` (`id`);

-- ALTER TABLE `community_posts`
--   ADD CONSTRAINT `community_posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `community_comments`
--   ADD CONSTRAINT `community_comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `community_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- ALTER TABLE `community_likes`
--   ADD CONSTRAINT `community_likes_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `community_likes_ibfk_2` FOREIGN KEY (`comment_id`) REFERENCES `community_comments` (`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `community_likes_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- --------------------------------------------------------
--
-- Notes for database administrator:
-- 1. Run this SQL script in your MySQL/MariaDB database
-- 2. The script uses IF NOT EXISTS to avoid errors if tables already exist
-- 3. All tables reference the existing `users` table
-- 4. JSON fields use CHECK constraints for MySQL 8.0+ (remove if using older version)
-- 5. The diabetes tables (blood_sugar_measurements, diabetes_medications, diabetes_symptoms) already exist in the database
-- 6. The daily quiz system is completely separate from the existing monthly quiz system
-- 7. Daily quiz tables include: daily_quiz_sessions, daily_quiz_questions, daily_quiz_options, daily_quiz_answers
--