-- 临客 Link · MySQL 表结构
-- 请先执行 00_create_database.sql 或确保已 USE link;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  account VARCHAR(64) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(64) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'student',
  avatar_url VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_users_account (account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS courses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(128) NOT NULL,
  category VARCHAR(64) NOT NULL,
  description TEXT NULL,
  lesson_count INT NOT NULL DEFAULT 0,
  cover_url VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS training_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  course_id INT NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'in_progress',
  progress_percent INT NOT NULL DEFAULT 0,
  duration_minutes INT NOT NULL DEFAULT 0,
  started_at DATETIME NULL,
  last_trained_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_training_user (user_id),
  INDEX idx_training_course (course_id),
  CONSTRAINT fk_training_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_training_course FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ai_feedbacks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  session_id INT NULL,
  overall_score INT NOT NULL,
  clarity_score INT NULL,
  pace_score INT NULL,
  interaction_score INT NULL,
  suggestion TEXT NULL,
  report_json TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_feedback_user (user_id),
  INDEX idx_feedback_session (session_id),
  CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_feedback_session FOREIGN KEY (session_id) REFERENCES training_sessions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS resources (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(128) NOT NULL,
  category VARCHAR(64) NULL,
  description VARCHAR(255) NULL,
  file_url VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
