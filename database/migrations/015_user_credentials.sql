-- Technical authentication storage approved for Phase 2.
USE mccollins_shipping;
CREATE TABLE IF NOT EXISTS user_credentials (
  user_credential_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  failed_attempts SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  locked_until DATETIME(6) NULL,
  password_changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_user_credentials PRIMARY KEY (user_credential_id),
  CONSTRAINT uq_user_credentials_user UNIQUE (user_id),
  CONSTRAINT ck_user_credentials_failed CHECK (failed_attempts >= 0),
  CONSTRAINT fk_user_credentials_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
SELECT COUNT(*)=1 AS table_exists FROM information_schema.tables WHERE table_schema='mccollins_shipping' AND table_name='user_credentials';
