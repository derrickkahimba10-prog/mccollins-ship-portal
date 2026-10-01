-- Phase 6B: align approved truck, inspection, and insurance entities for individual/company ownership.
-- MariaDB 10.4.32; preserves existing records and creates no new business table.
USE mccollins_shipping;
SET time_zone = '+00:00';

-- Individual carriers require nullable company ownership plus a relational user owner.
DELIMITER $$
DROP PROCEDURE IF EXISTS phase6b_drop_fk$$
CREATE PROCEDURE phase6b_drop_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64))
BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name AND CONSTRAINT_TYPE='FOREIGN KEY') THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` DROP FOREIGN KEY `',p_name,'`');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6b_drop_fk('trucks','fk_trucks_owner');
DROP PROCEDURE phase6b_drop_fk;
ALTER TABLE trucks MODIFY COLUMN owner_company_id BIGINT UNSIGNED NULL;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6b_add_column$$
CREATE PROCEDURE phase6b_add_column(IN p_table VARCHAR(64),IN p_column VARCHAR(64),IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6b_add_column('trucks','owner_user_id','BIGINT UNSIGNED NULL AFTER owner_company_id');
CALL phase6b_add_column('trucks','make_name','VARCHAR(96) NOT NULL DEFAULT \'UNKNOWN\' AFTER registration_country');
CALL phase6b_add_column('trucks','model_name','VARCHAR(96) NOT NULL DEFAULT \'UNKNOWN\' AFTER make_name');
CALL phase6b_add_column('trucks','manufacture_year','SMALLINT UNSIGNED NULL AFTER model_name');
CALL phase6b_add_column('trucks','chassis_number','VARCHAR(96) NULL AFTER manufacture_year');
CALL phase6b_add_column('trucks','engine_number','VARCHAR(96) NULL AFTER chassis_number');

CALL phase6b_add_column('inspections','truck_id','BIGINT UNSIGNED NULL AFTER inspection_ref');
CALL phase6b_add_column('inspections','inspection_number','VARCHAR(96) NULL AFTER truck_id');
CALL phase6b_add_column('inspections','inspected_on','DATE NULL AFTER inspection_number');
CALL phase6b_add_column('inspections','expires_on','DATE NULL AFTER inspected_on');
CALL phase6b_add_column('inspections','result_code','VARCHAR(24) NULL AFTER expires_on');
CALL phase6b_add_column('inspections','roadworthiness_status','VARCHAR(24) NULL AFTER result_code');

CALL phase6b_add_column('insurance_policies','policy_number','VARCHAR(96) NULL AFTER insurance_policie_ref');
CALL phase6b_add_column('insurance_policies','provider_name','VARCHAR(191) NULL AFTER policy_number');
CALL phase6b_add_column('insurance_policies','valid_from','DATE NULL AFTER provider_name');
CALL phase6b_add_column('insurance_policies','valid_to','DATE NULL AFTER valid_from');
CALL phase6b_add_column('insurance_policies','coverage_type','VARCHAR(96) NULL AFTER valid_to');

CALL phase6b_add_column('insurance_policy_links','insurance_policy_id','BIGINT UNSIGNED NULL AFTER insurance_policy_link_ref');
CALL phase6b_add_column('insurance_policy_links','truck_id','BIGINT UNSIGNED NULL AFTER insurance_policy_id');
DROP PROCEDURE phase6b_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6b_add_index$$
CREATE PROCEDURE phase6b_add_index(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_columns TEXT,IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',p_name,'` (',p_columns,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6b_add_index('trucks','uq_trucks_registration','`registration_country`,`registration_number`',TRUE);
CALL phase6b_add_index('trucks','uq_trucks_chassis','`chassis_number`',TRUE);
CALL phase6b_add_index('trucks','ix_trucks_owner_user','`owner_user_id`',FALSE);
CALL phase6b_add_index('trucks','ix_trucks_verification','`verification_status`,`status`',FALSE);
CALL phase6b_add_index('inspections','ix_inspections_truck_expiry','`truck_id`,`expires_on`',FALSE);
CALL phase6b_add_index('insurance_policies','uq_insurance_policy_number','`policy_number`',TRUE);
CALL phase6b_add_index('insurance_policy_links','ix_insurance_links_truck','`truck_id`,`status`',FALSE);
CALL phase6b_add_index('insurance_policy_links','ix_insurance_links_policy','`insurance_policy_id`',FALSE);
DROP PROCEDURE phase6b_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6b_add_fk$$
CREATE PROCEDURE phase6b_add_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_column VARCHAR(64),IN p_ref_table VARCHAR(64),IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_ref_table,'` (`',p_ref,'`)');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6b_add_fk('trucks','fk_trucks_owner','owner_company_id','companies','company_id');
CALL phase6b_add_fk('trucks','fk_trucks_owner_user','owner_user_id','users','user_id');
CALL phase6b_add_fk('inspections','fk_inspections_truck','truck_id','trucks','truck_id');
CALL phase6b_add_fk('insurance_policy_links','fk_insurance_links_policy','insurance_policy_id','insurance_policies','insurance_policie_id');
CALL phase6b_add_fk('insurance_policy_links','fk_insurance_links_truck','truck_id','trucks','truck_id');
DROP PROCEDURE phase6b_add_fk;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6b_add_check$$
CREATE PROCEDURE phase6b_add_check(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_expression TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` CHECK (',p_expression,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6b_add_check('trucks','chk_trucks_one_owner','(owner_company_id IS NOT NULL) <> (owner_user_id IS NOT NULL)');
CALL phase6b_add_check('trucks','chk_trucks_body_type',"body_type_code IN ('FLATBED','BOX','CURTAIN_SIDE','TIPPER','TANKER','REFRIGERATED','CONTAINER_CARRIER','OTHER')");
CALL phase6b_add_check('trucks','chk_trucks_capacity_unit',"capacity_unit IN ('KG','TONNE','M3')");
CALL phase6b_add_check('inspections','chk_inspections_result',"result_code IS NULL OR result_code IN ('PASS','FAIL')");
CALL phase6b_add_check('inspections','chk_inspections_roadworthiness',"roadworthiness_status IS NULL OR roadworthiness_status IN ('ROADWORTHY','NOT_ROADWORTHY')");
DROP PROCEDURE phase6b_add_check;

SELECT 'Phase 6B truck and compliance alignment completed' AS result;
