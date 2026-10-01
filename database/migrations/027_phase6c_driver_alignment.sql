-- Phase 6C: align approved driver, engagement, and credential entities.
-- Preserves existing records; no document uploads or transport assignments.
USE mccollins_shipping;
SET time_zone = '+00:00';
DELIMITER $$
DROP PROCEDURE IF EXISTS phase6c_add_column$$
CREATE PROCEDURE phase6c_add_column(IN p_table VARCHAR(64),IN p_column VARCHAR(64),IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6c_add_column('drivers','identity_type',"VARCHAR(24) NULL AFTER user_id");
CALL phase6c_add_column('drivers','identity_number','VARCHAR(96) NULL AFTER identity_type');
CALL phase6c_add_column('drivers','identity_country','CHAR(2) NULL AFTER identity_number');
CALL phase6c_add_column('drivers','licence_categories','VARCHAR(191) NULL AFTER licence_country');
CALL phase6c_add_column('drivers','licence_expiry','DATE NULL AFTER licence_categories');
CALL phase6c_add_column('drivers','medical_certificate_number','VARCHAR(96) NULL AFTER licence_expiry');
CALL phase6c_add_column('drivers','medical_exam_date','DATE NULL AFTER medical_certificate_number');
CALL phase6c_add_column('drivers','medical_expiry','DATE NULL AFTER medical_exam_date');
CALL phase6c_add_column('drivers','medical_result','VARCHAR(24) NULL AFTER medical_expiry');

CALL phase6c_add_column('driver_engagements','driver_id','BIGINT UNSIGNED NULL AFTER driver_engagement_ref');
CALL phase6c_add_column('driver_engagements','carrier_company_id','BIGINT UNSIGNED NULL AFTER driver_id');
CALL phase6c_add_column('driver_engagements','carrier_user_id','BIGINT UNSIGNED NULL AFTER carrier_company_id');
CALL phase6c_add_column('driver_engagements','truck_id','BIGINT UNSIGNED NULL AFTER carrier_user_id');
CALL phase6c_add_column('driver_engagements','engagement_status',"VARCHAR(32) NOT NULL DEFAULT 'carrier_approved' AFTER truck_id");
CALL phase6c_add_column('driver_engagements','carrier_approved_by_user_id','BIGINT UNSIGNED NULL AFTER engagement_status');
CALL phase6c_add_column('driver_engagements','started_at','DATETIME(6) NULL AFTER carrier_approved_by_user_id');
CALL phase6c_add_column('driver_engagements','ended_at','DATETIME(6) NULL AFTER started_at');

CALL phase6c_add_column('user_credentials','setup_token_hash','CHAR(64) NULL AFTER password_hash');
CALL phase6c_add_column('user_credentials','setup_expires_at','DATETIME(6) NULL AFTER setup_token_hash');
CALL phase6c_add_column('user_credentials','setup_used_at','DATETIME(6) NULL AFTER setup_expires_at');
DROP PROCEDURE phase6c_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6c_add_index$$
CREATE PROCEDURE phase6c_add_index(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_columns TEXT,IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',p_name,'` (',p_columns,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6c_add_index('drivers','uq_drivers_user','`user_id`',TRUE);
CALL phase6c_add_index('drivers','uq_drivers_identity','`identity_country`,`identity_type`,`identity_number`',TRUE);
CALL phase6c_add_index('drivers','uq_drivers_licence','`licence_country`,`licence_number`',TRUE);
CALL phase6c_add_index('drivers','ix_drivers_verification','`verification_status`,`status`',FALSE);
CALL phase6c_add_index('driver_engagements','ix_driver_engagements_driver','`driver_id`,`engagement_status`,`status`',FALSE);
CALL phase6c_add_index('driver_engagements','ix_driver_engagements_company','`carrier_company_id`,`status`',FALSE);
CALL phase6c_add_index('driver_engagements','ix_driver_engagements_user','`carrier_user_id`,`status`',FALSE);
CALL phase6c_add_index('driver_engagements','ix_driver_engagements_truck','`truck_id`,`engagement_status`,`status`',FALSE);
CALL phase6c_add_index('user_credentials','uq_user_credentials_setup_token','`setup_token_hash`',TRUE);
DROP PROCEDURE phase6c_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6c_add_fk$$
CREATE PROCEDURE phase6c_add_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_column VARCHAR(64),IN p_ref_table VARCHAR(64),IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_ref_table,'` (`',p_ref,'`)');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6c_add_fk('driver_engagements','fk_driver_engagements_driver','driver_id','drivers','driver_id');
CALL phase6c_add_fk('driver_engagements','fk_driver_engagements_company','carrier_company_id','companies','company_id');
CALL phase6c_add_fk('driver_engagements','fk_driver_engagements_user','carrier_user_id','users','user_id');
CALL phase6c_add_fk('driver_engagements','fk_driver_engagements_truck','truck_id','trucks','truck_id');
CALL phase6c_add_fk('driver_engagements','fk_driver_engagements_approver','carrier_approved_by_user_id','users','user_id');
DROP PROCEDURE phase6c_add_fk;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6c_add_check$$
CREATE PROCEDURE phase6c_add_check(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_expression TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` CHECK (',p_expression,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6c_add_check('drivers','chk_drivers_identity_type',"identity_type IS NULL OR identity_type IN ('NATIONAL_ID','PASSPORT')");
CALL phase6c_add_check('drivers','chk_drivers_medical_result',"medical_result IS NULL OR medical_result IN ('FIT','UNFIT')");
CALL phase6c_add_check('driver_engagements','chk_driver_engagement_one_carrier','(carrier_company_id IS NOT NULL) <> (carrier_user_id IS NOT NULL)');
CALL phase6c_add_check('driver_engagements','chk_driver_engagement_status',"engagement_status IN ('carrier_approved','active','ended')");
DROP PROCEDURE phase6c_add_check;
SELECT 'Phase 6C driver alignment completed' AS result;
