-- Phase 7B: align transport offers, immutable revisions, responses, and reservations.
USE mccollins_shipping;
SET time_zone = '+00:00';
DELIMITER $$
DROP PROCEDURE IF EXISTS phase7b_add_column$$
CREATE PROCEDURE phase7b_add_column(IN p_table VARCHAR(64),IN p_column VARCHAR(64),IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7b_add_column('configuration_setting_versions','setting_code','VARCHAR(64) NULL AFTER configuration_setting_version_ref');
CALL phase7b_add_column('configuration_setting_versions','version_no','INT UNSIGNED NULL AFTER setting_code');
CALL phase7b_add_column('configuration_setting_versions','decimal_value','DECIMAL(19,6) NULL AFTER version_no');
CALL phase7b_add_column('configuration_setting_versions','effective_from','DATETIME(6) NULL AFTER decimal_value');
CALL phase7b_add_column('configuration_setting_versions','effective_to','DATETIME(6) NULL AFTER effective_from');
CALL phase7b_add_column('bids_offers','offer_thread_ref','VARCHAR(32) NULL AFTER offer_ref');
CALL phase7b_add_column('bids_offers','version_no','INT UNSIGNED NULL AFTER offer_thread_ref');
CALL phase7b_add_column('bids_offers','parent_offer_id','BIGINT UNSIGNED NULL AFTER version_no');
CALL phase7b_add_column('bids_offers','match_id','BIGINT UNSIGNED NULL AFTER parent_offer_id');
CALL phase7b_add_column('bids_offers','load_id','BIGINT UNSIGNED NULL AFTER match_id');
CALL phase7b_add_column('bids_offers','load_version_id','BIGINT UNSIGNED NULL AFTER load_id');
CALL phase7b_add_column('bids_offers','truck_id','BIGINT UNSIGNED NULL AFTER load_version_id');
CALL phase7b_add_column('bids_offers','driver_id','BIGINT UNSIGNED NULL AFTER truck_id');
CALL phase7b_add_column('bids_offers','carrier_company_id','BIGINT UNSIGNED NULL AFTER driver_id');
CALL phase7b_add_column('bids_offers','carrier_user_id','BIGINT UNSIGNED NULL AFTER carrier_company_id');
CALL phase7b_add_column('bids_offers','offered_amount_tzs','DECIMAL(19,2) NULL AFTER carrier_user_id');
CALL phase7b_add_column('bids_offers','fx_tzs_per_usd','DECIMAL(19,6) NULL AFTER offered_amount_tzs');
CALL phase7b_add_column('bids_offers','offered_amount_usd','DECIMAL(19,2) NULL AFTER fx_tzs_per_usd');
CALL phase7b_add_column('bids_offers','price_breakdown','TEXT NULL AFTER offered_amount_usd');
CALL phase7b_add_column('bids_offers','counter_amount_tzs','DECIMAL(19,2) NULL AFTER price_breakdown');
CALL phase7b_add_column('bids_offers','counter_amount_usd','DECIMAL(19,2) NULL AFTER counter_amount_tzs');
CALL phase7b_add_column('bids_offers','response_note','TEXT NULL AFTER counter_amount_usd');
CALL phase7b_add_column('bids_offers','offer_status',"VARCHAR(32) NOT NULL DEFAULT 'sent' AFTER response_note");
CALL phase7b_add_column('bids_offers','sent_at','DATETIME(6) NULL AFTER offer_status');
CALL phase7b_add_column('bids_offers','expires_at','DATETIME(6) NULL AFTER sent_at');
CALL phase7b_add_column('bids_offers','responded_at','DATETIME(6) NULL AFTER expires_at');
CALL phase7b_add_column('bids_offers','sent_by_user_id','BIGINT UNSIGNED NULL AFTER responded_at');
CALL phase7b_add_column('bids_offers','responded_by_user_id','BIGINT UNSIGNED NULL AFTER sent_by_user_id');
CALL phase7b_add_column('bids_offers','reserved_at','DATETIME(6) NULL AFTER responded_by_user_id');
DROP PROCEDURE phase7b_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7b_replace_availability_check$$
CREATE PROCEDURE phase7b_replace_availability_check()
BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='resource_availability' AND CONSTRAINT_NAME='chk_resource_availability_state') THEN
  ALTER TABLE resource_availability DROP CONSTRAINT chk_resource_availability_state;
 END IF;
 ALTER TABLE resource_availability ADD CONSTRAINT chk_resource_availability_state CHECK (availability_status IN ('available','unavailable','reserved'));
END$$
DELIMITER ;
CALL phase7b_replace_availability_check();
DROP PROCEDURE phase7b_replace_availability_check;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7b_add_index$$
CREATE PROCEDURE phase7b_add_index(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_columns TEXT,IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',p_name,'` (',p_columns,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7b_add_index('configuration_setting_versions','uq_config_setting_version','`setting_code`,`version_no`',TRUE);
CALL phase7b_add_index('bids_offers','ix_offers_load_status','`load_id`,`offer_status`,`status`',FALSE);
CALL phase7b_add_index('bids_offers','ix_offers_carrier_company','`carrier_company_id`,`offer_status`',FALSE);
CALL phase7b_add_index('bids_offers','ix_offers_carrier_user','`carrier_user_id`,`offer_status`',FALSE);
CALL phase7b_add_index('bids_offers','ix_offers_thread_version','`offer_thread_ref`,`version_no`',FALSE);
CALL phase7b_add_index('bids_offers','ix_offers_match','`match_id`',FALSE);
DROP PROCEDURE phase7b_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7b_add_fk$$
CREATE PROCEDURE phase7b_add_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_column VARCHAR(64),IN p_ref_table VARCHAR(64),IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_ref_table,'` (`',p_ref,'`)');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7b_add_fk('bids_offers','fk_offers_parent','parent_offer_id','bids_offers','offer_id');
CALL phase7b_add_fk('bids_offers','fk_offers_match','match_id','matches','match_id');
CALL phase7b_add_fk('bids_offers','fk_offers_load','load_id','loads','load_id');
CALL phase7b_add_fk('bids_offers','fk_offers_load_version','load_version_id','load_versions','load_version_id');
CALL phase7b_add_fk('bids_offers','fk_offers_truck','truck_id','trucks','truck_id');
CALL phase7b_add_fk('bids_offers','fk_offers_driver','driver_id','drivers','driver_id');
CALL phase7b_add_fk('bids_offers','fk_offers_carrier_company','carrier_company_id','companies','company_id');
CALL phase7b_add_fk('bids_offers','fk_offers_carrier_user','carrier_user_id','users','user_id');
CALL phase7b_add_fk('bids_offers','fk_offers_sender','sent_by_user_id','users','user_id');
CALL phase7b_add_fk('bids_offers','fk_offers_responder','responded_by_user_id','users','user_id');
DROP PROCEDURE phase7b_add_fk;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase7b_add_check$$
CREATE PROCEDURE phase7b_add_check(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_expression TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` CHECK (',p_expression,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7b_add_check('bids_offers','chk_offers_one_carrier','(carrier_company_id IS NOT NULL) <> (carrier_user_id IS NOT NULL)');
CALL phase7b_add_check('bids_offers','chk_offers_status',"offer_status IN ('sent','accepted','declined','countered','expired','closed','revised')");
DROP PROCEDURE phase7b_add_check;
SELECT 'Phase 7B offer alignment completed' AS result;
