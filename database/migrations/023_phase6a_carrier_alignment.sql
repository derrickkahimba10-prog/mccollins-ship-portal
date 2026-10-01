-- Phase 6A: align the approved truck_owner_profiles entity for individual/company carrier onboarding.
-- Existing records are preserved; no approved business table is replaced.
USE mccollins_shipping;
SET time_zone = '+00:00';

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6a_add_column$$
CREATE PROCEDURE phase6a_add_column(IN p_column VARCHAR(64), IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='truck_owner_profiles' AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE truck_owner_profiles ADD COLUMN `',REPLACE(p_column,'`','``'),'` ',p_definition);
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6a_add_column('owner_type', "VARCHAR(24) NOT NULL DEFAULT 'individual' AFTER truck_owner_profile_ref");
CALL phase6a_add_column('user_id', 'BIGINT UNSIGNED NULL AFTER owner_type');
CALL phase6a_add_column('company_id', 'BIGINT UNSIGNED NULL AFTER user_id');
CALL phase6a_add_column('tin_number', 'VARCHAR(96) NULL AFTER company_id');
CALL phase6a_add_column('business_license_number', 'VARCHAR(96) NULL AFTER tin_number');
CALL phase6a_add_column('business_license_expiry', 'DATE NULL AFTER business_license_number');
CALL phase6a_add_column('insurance_provider', 'VARCHAR(191) NULL AFTER business_license_expiry');
CALL phase6a_add_column('insurance_policy_number', 'VARCHAR(96) NULL AFTER insurance_provider');
CALL phase6a_add_column('insurance_expiry', 'DATE NULL AFTER insurance_policy_number');
CALL phase6a_add_column('verification_status', "VARCHAR(24) NOT NULL DEFAULT 'pending' AFTER insurance_expiry");
DROP PROCEDURE phase6a_add_column;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6a_add_index$$
CREATE PROCEDURE phase6a_add_index(IN p_name VARCHAR(64), IN p_columns TEXT, IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='truck_owner_profiles' AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE truck_owner_profiles ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',REPLACE(p_name,'`','``'),'` (',p_columns,')');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6a_add_index('uq_truck_owner_profiles_user','`user_id`',TRUE);
CALL phase6a_add_index('uq_truck_owner_profiles_company','`company_id`',TRUE);
CALL phase6a_add_index('ix_truck_owner_profiles_verification','`verification_status`,`status`',FALSE);
DROP PROCEDURE phase6a_add_index;

DELIMITER $$
DROP PROCEDURE IF EXISTS phase6a_add_fk$$
CREATE PROCEDURE phase6a_add_fk(IN p_name VARCHAR(64), IN p_column VARCHAR(64), IN p_table VARCHAR(64), IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='truck_owner_profiles' AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE truck_owner_profiles ADD CONSTRAINT `',REPLACE(p_name,'`','``'),'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_table,'` (`',p_ref,'`)');
  PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6a_add_fk('fk_truck_owner_profiles_user','user_id','users','user_id');
CALL phase6a_add_fk('fk_truck_owner_profiles_company','company_id','companies','company_id');
DROP PROCEDURE phase6a_add_fk;

SELECT 'Phase 6A carrier profile alignment completed' AS result;
