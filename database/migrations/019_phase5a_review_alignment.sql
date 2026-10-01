-- Phase 5A: align the existing approved load_reviews entity for relational review workflow.
-- MariaDB 10.4.32 / utf8mb4. Import once after 017_phase4_load_alignment.sql.
USE mccollins_shipping;
SET time_zone = '+00:00';

DELIMITER $$
DROP PROCEDURE IF EXISTS phase5a_add_column$$
CREATE PROCEDURE phase5a_add_column(IN p_column VARCHAR(64), IN p_definition TEXT)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='load_reviews' AND COLUMN_NAME=p_column
  ) THEN
    SET @ddl=CONCAT('ALTER TABLE load_reviews ADD COLUMN `',REPLACE(p_column,'`','``'),'` ',p_definition);
    PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

CALL phase5a_add_column('load_review_ref', 'VARCHAR(40) NULL AFTER load_review_id');
CALL phase5a_add_column('status', "VARCHAR(24) NOT NULL DEFAULT 'active'");
CALL phase5a_add_column('created_by_user_id', 'BIGINT UNSIGNED NULL');
CALL phase5a_add_column('updated_by_user_id', 'BIGINT UNSIGNED NULL');
CALL phase5a_add_column('created_at', 'DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)');
CALL phase5a_add_column('updated_at', 'DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)');
CALL phase5a_add_column('row_version', 'BIGINT UNSIGNED NOT NULL DEFAULT 1');
CALL phase5a_add_column('load_id', 'BIGINT UNSIGNED NULL AFTER load_review_ref');
CALL phase5a_add_column('load_version_id', 'BIGINT UNSIGNED NULL AFTER load_id');
CALL phase5a_add_column('reviewer_user_id', 'BIGINT UNSIGNED NULL AFTER load_version_id');
CALL phase5a_add_column('reviewer_user_role_id', 'BIGINT UNSIGNED NULL AFTER reviewer_user_id');
CALL phase5a_add_column('review_status', "VARCHAR(32) NOT NULL DEFAULT 'under_review' AFTER reviewer_user_role_id");
CALL phase5a_add_column('clarification_request', 'TEXT NULL AFTER review_status');
CALL phase5a_add_column('clarification_response', 'TEXT NULL AFTER clarification_request');
CALL phase5a_add_column('clarification_responded_by_user_id', 'BIGINT UNSIGNED NULL AFTER clarification_response');
CALL phase5a_add_column('response_load_version_id', 'BIGINT UNSIGNED NULL AFTER clarification_responded_by_user_id');
CALL phase5a_add_column('started_at', 'DATETIME(6) NULL AFTER clarification_request');
CALL phase5a_add_column('clarification_requested_at', 'DATETIME(6) NULL AFTER started_at');
CALL phase5a_add_column('clarification_responded_at', 'DATETIME(6) NULL AFTER clarification_requested_at');
DROP PROCEDURE phase5a_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase5a_add_index$$
CREATE PROCEDURE phase5a_add_index(IN p_name VARCHAR(64), IN p_columns TEXT, IN p_unique BOOLEAN)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='load_reviews' AND INDEX_NAME=p_name
  ) THEN
    SET @ddl=CONCAT('ALTER TABLE load_reviews ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',REPLACE(p_name,'`','``'),'` (',p_columns,')');
    PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;
CALL phase5a_add_index('uq_load_reviews_version', '`load_version_id`', TRUE);
CALL phase5a_add_index('ix_load_reviews_load_status', '`load_id`,`review_status`', FALSE);
CALL phase5a_add_index('ix_load_reviews_reviewer_status', '`reviewer_user_id`,`review_status`', FALSE);
DROP PROCEDURE phase5a_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase5a_add_fk$$
CREATE PROCEDURE phase5a_add_fk(IN p_name VARCHAR(64), IN p_column VARCHAR(64), IN p_table VARCHAR(64), IN p_ref VARCHAR(64))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='load_reviews' AND CONSTRAINT_NAME=p_name
  ) THEN
    SET @ddl=CONCAT('ALTER TABLE load_reviews ADD CONSTRAINT `',REPLACE(p_name,'`','``'),'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_table,'` (`',p_ref,'`)');
    PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;
CALL phase5a_add_fk('fk_load_reviews_load','load_id','loads','load_id');
CALL phase5a_add_fk('fk_load_reviews_version','load_version_id','load_versions','load_version_id');
CALL phase5a_add_fk('fk_load_reviews_reviewer','reviewer_user_id','users','user_id');
CALL phase5a_add_fk('fk_load_reviews_reviewer_role','reviewer_user_role_id','user_roles','user_role_id');
CALL phase5a_add_fk('fk_load_reviews_response_user','clarification_responded_by_user_id','users','user_id');
CALL phase5a_add_fk('fk_load_reviews_response_version','response_load_version_id','load_versions','load_version_id');
DROP PROCEDURE phase5a_add_fk;

SELECT 'Phase 5A load review alignment completed' AS result;
