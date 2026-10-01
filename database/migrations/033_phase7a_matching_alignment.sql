-- Phase 7A: align approved matching entities for Operations candidate generation.
USE mccollins_shipping;
SET time_zone = '+00:00';

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7a_add_column$$
CREATE PROCEDURE phase7a_add_column(IN p_table VARCHAR(64),IN p_column VARCHAR(64),IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase7a_add_column('matches','load_version_id','BIGINT UNSIGNED NULL AFTER load_id');
CALL phase7a_add_column('matches','generated_run_ref','VARCHAR(32) NULL AFTER eligibility_assessment_id');
CALL phase7a_add_column('matches','generated_by_user_id','BIGINT UNSIGNED NULL AFTER overall_reason');
CALL phase7a_add_column('matches','generated_at','DATETIME(6) NULL AFTER generated_by_user_id');
CALL phase7a_add_column('match_factors','match_id','BIGINT UNSIGNED NULL AFTER match_factor_ref');
CALL phase7a_add_column('match_factors','factor_code','VARCHAR(48) NULL AFTER match_id');
CALL phase7a_add_column('match_factors','factor_result','VARCHAR(24) NULL AFTER factor_code');
CALL phase7a_add_column('match_factors','required_value','DECIMAL(18,3) NULL AFTER factor_result');
CALL phase7a_add_column('match_factors','actual_value','DECIMAL(18,3) NULL AFTER required_value');
CALL phase7a_add_column('match_factors','unit_code','VARCHAR(16) NULL AFTER actual_value');
CALL phase7a_add_column('match_factors','reason','VARCHAR(500) NULL AFTER unit_code');
CALL phase7a_add_column('match_factors','evaluated_at','DATETIME(6) NULL AFTER reason');
DROP PROCEDURE phase7a_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7a_add_index$$
CREATE PROCEDURE phase7a_add_index(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_columns TEXT,IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',p_name,'` (',p_columns,')');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase7a_add_index('matches','ix_matches_load_version_status','`load_version_id`,`status`,`generated_at`',FALSE);
CALL phase7a_add_index('matches','ix_matches_run','`generated_run_ref`,`status`',FALSE);
CALL phase7a_add_index('matches','ix_matches_driver','`driver_id`',FALSE);
CALL phase7a_add_index('matches','ix_matches_eligibility','`eligibility_assessment_id`',FALSE);
CALL phase7a_add_index('match_factors','ix_match_factors_match','`match_id`,`factor_code`',FALSE);
DROP PROCEDURE phase7a_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7a_add_fk$$
CREATE PROCEDURE phase7a_add_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_column VARCHAR(64),IN p_ref_table VARCHAR(64),IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_ref_table,'` (`',p_ref,'`)');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase7a_add_fk('matches','fk_matches_load_version','load_version_id','load_versions','load_version_id');
CALL phase7a_add_fk('matches','fk_matches_driver','driver_id','drivers','driver_id');
CALL phase7a_add_fk('matches','fk_matches_eligibility','eligibility_assessment_id','eligibility_assessments','eligibility_assessment_id');
CALL phase7a_add_fk('matches','fk_matches_generator','generated_by_user_id','users','user_id');
CALL phase7a_add_fk('match_factors','fk_match_factors_match','match_id','matches','match_id');
DROP PROCEDURE phase7a_add_fk;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7a_add_check$$
CREATE PROCEDURE phase7a_add_check(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_expression TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` CHECK (',p_expression,')');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;

CALL phase7a_add_check('matches','chk_matches_suitability',"suitability_status IN ('suitable','review_required','unsuitable')");
CALL phase7a_add_check('match_factors','chk_match_factors_result',"factor_result IS NULL OR factor_result IN ('pass','fail','not_evaluated')");
DROP PROCEDURE phase7a_add_check;

SELECT 'Phase 7A matching alignment completed' AS result;
