-- Phase 5B: align the existing load_reviews entity for approved/rejected decisions.
-- Preserves existing records and adds no new business table.
USE mccollins_shipping;
SET time_zone = '+00:00';

DELIMITER $$
DROP PROCEDURE IF EXISTS phase5b_add_column$$
CREATE PROCEDURE phase5b_add_column(IN p_column VARCHAR(64), IN p_definition TEXT)
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

CALL phase5b_add_column('decision_code', 'VARCHAR(32) NULL AFTER review_status');
CALL phase5b_add_column('decision_reason', 'TEXT NULL AFTER decision_code');
CALL phase5b_add_column('decided_by_user_id', 'BIGINT UNSIGNED NULL AFTER decision_reason');
CALL phase5b_add_column('decided_by_user_role_id', 'BIGINT UNSIGNED NULL AFTER decided_by_user_id');
CALL phase5b_add_column('decided_at', 'DATETIME(6) NULL AFTER decided_by_user_role_id');
DROP PROCEDURE phase5b_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase5b_add_fk$$
CREATE PROCEDURE phase5b_add_fk(IN p_name VARCHAR(64), IN p_column VARCHAR(64), IN p_table VARCHAR(64), IN p_ref VARCHAR(64))
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
CALL phase5b_add_fk('fk_load_reviews_decider','decided_by_user_id','users','user_id');
CALL phase5b_add_fk('fk_load_reviews_decider_role','decided_by_user_role_id','user_roles','user_role_id');
DROP PROCEDURE phase5b_add_fk;


-- If the approved status columns are ENUMs in this installation, append the approved Phase 5B values without removing existing values.
DELIMITER $$
DROP PROCEDURE IF EXISTS phase5b_extend_enum$$
CREATE PROCEDURE phase5b_extend_enum(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_value VARCHAR(32))
BEGIN
  DECLARE v_type TEXT;
  DECLARE v_nullable VARCHAR(3);
  DECLARE v_default TEXT;
  SELECT COLUMN_TYPE,IS_NULLABLE,COLUMN_DEFAULT INTO v_type,v_nullable,v_default
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column;
  IF v_type LIKE 'enum(%' AND LOCATE(CONCAT(CHAR(39),p_value,CHAR(39)),v_type)=0 THEN
    SET v_type=CONCAT(LEFT(v_type,LENGTH(v_type)-1),',',CHAR(39),REPLACE(p_value,CHAR(39),CONCAT(CHAR(39),CHAR(39))),CHAR(39),')');
    SET @ddl=CONCAT('ALTER TABLE `',REPLACE(p_table,'`','``'),'` MODIFY COLUMN `',REPLACE(p_column,'`','``'),'` ',v_type,
      IF(v_nullable='YES',' NULL',' NOT NULL'),
      IF(v_default IS NULL,'',CONCAT(' DEFAULT ',QUOTE(v_default))));
    PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;
CALL phase5b_extend_enum('loads','current_status','approved');
CALL phase5b_extend_enum('loads','current_status','rejected');
CALL phase5b_extend_enum('load_versions','status','approved');
CALL phase5b_extend_enum('load_versions','status','rejected');
CALL phase5b_extend_enum('load_reviews','review_status','approved');
CALL phase5b_extend_enum('load_reviews','review_status','rejected');
DROP PROCEDURE phase5b_extend_enum;

SELECT 'Phase 5B review decision alignment completed' AS result;
