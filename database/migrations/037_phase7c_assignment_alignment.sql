-- Phase 7C: accepted-offer assignment alignment.
USE mccollins_shipping;
SET time_zone = '+00:00';
ALTER TABLE assignments MODIFY COLUMN carrier_company_id BIGINT UNSIGNED NULL;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase7c_add_column$$
CREATE PROCEDURE phase7c_add_column(IN p_table VARCHAR(64),IN p_column VARCHAR(64),IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7c_add_column('assignments','accepted_offer_id','BIGINT UNSIGNED NULL AFTER match_id');
CALL phase7c_add_column('assignments','carrier_user_id','BIGINT UNSIGNED NULL AFTER carrier_company_id');
CALL phase7c_add_column('assignments','assignment_status',"VARCHAR(32) NOT NULL DEFAULT 'assigned' AFTER assigned_at");
CALL phase7c_add_column('assignments','assigned_by_user_id','BIGINT UNSIGNED NULL AFTER assignment_status');
CALL phase7c_add_column('assignments','assignment_note','TEXT NULL AFTER assigned_by_user_id');
DROP PROCEDURE phase7c_add_column;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase7c_add_index$$
CREATE PROCEDURE phase7c_add_index(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_columns TEXT,IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',p_name,'` (',p_columns,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7c_add_index('assignments','uq_assignments_load','`load_id`',TRUE);
CALL phase7c_add_index('assignments','uq_assignments_accepted_offer','`accepted_offer_id`',TRUE);
CALL phase7c_add_index('assignments','ix_assignments_match','`match_id`',FALSE);
CALL phase7c_add_index('assignments','ix_assignments_truck','`truck_id`',FALSE);
CALL phase7c_add_index('assignments','ix_assignments_driver','`driver_id`',FALSE);
CALL phase7c_add_index('assignments','ix_assignments_carrier_user','`carrier_user_id`',FALSE);
DROP PROCEDURE phase7c_add_index;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase7c_add_fk$$
CREATE PROCEDURE phase7c_add_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_column VARCHAR(64),IN p_ref_table VARCHAR(64),IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_ref_table,'` (`',p_ref,'`)');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7c_add_fk('assignments','fk_assignments_offer','accepted_offer_id','bids_offers','offer_id');
CALL phase7c_add_fk('assignments','fk_assignments_match','match_id','matches','match_id');
CALL phase7c_add_fk('assignments','fk_assignments_carrier_company','carrier_company_id','companies','company_id');
CALL phase7c_add_fk('assignments','fk_assignments_carrier_user','carrier_user_id','users','user_id');
CALL phase7c_add_fk('assignments','fk_assignments_truck','truck_id','trucks','truck_id');
CALL phase7c_add_fk('assignments','fk_assignments_driver','driver_id','drivers','driver_id');
CALL phase7c_add_fk('assignments','fk_assignments_assigner','assigned_by_user_id','users','user_id');
DROP PROCEDURE phase7c_add_fk;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase7c_add_check$$
CREATE PROCEDURE phase7c_add_check(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_expression TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` CHECK (',p_expression,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase7c_add_check('assignments','chk_assignments_one_carrier','(carrier_company_id IS NOT NULL) <> (carrier_user_id IS NOT NULL)');
CALL phase7c_add_check('assignments','chk_assignments_state',"assignment_status IN ('assigned','cancelled')");
DROP PROCEDURE phase7c_add_check;
SELECT 'Phase 7C assignment alignment completed' AS result;
