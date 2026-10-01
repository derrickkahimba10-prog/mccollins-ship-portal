-- Phase 6D: align approved subscription, eligibility, and availability entities.
USE mccollins_shipping;
SET time_zone = '+00:00';
ALTER TABLE subscriptions MODIFY COLUMN company_id BIGINT UNSIGNED NULL, MODIFY COLUMN trial_start_at DATETIME(6) NULL, MODIFY COLUMN trial_end_at DATETIME(6) NULL;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_add_column$$
CREATE PROCEDURE phase6d_add_column(IN p_table VARCHAR(64),IN p_column VARCHAR(64),IN p_definition TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD COLUMN `',p_column,'` ',p_definition);PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6d_add_column('subscription_plan_versions','subscription_plan_id','BIGINT UNSIGNED NULL AFTER subscription_plan_version_ref');
CALL phase6d_add_column('subscription_plan_versions','version_no','INT UNSIGNED NULL AFTER subscription_plan_id');
CALL phase6d_add_column('subscription_plan_versions','plan_code','VARCHAR(32) NULL AFTER version_no');
CALL phase6d_add_column('subscription_plan_versions','plan_name','VARCHAR(96) NULL AFTER plan_code');
CALL phase6d_add_column('subscription_plan_versions','max_trucks','INT UNSIGNED NULL AFTER plan_name');
CALL phase6d_add_column('subscription_plan_versions','max_drivers','INT UNSIGNED NULL AFTER max_trucks');
CALL phase6d_add_column('subscription_plan_versions','effective_from','DATETIME(6) NULL AFTER max_drivers');
CALL phase6d_add_column('subscription_plan_versions','effective_to','DATETIME(6) NULL AFTER effective_from');
CALL phase6d_add_column('subscriptions','owner_user_id','BIGINT UNSIGNED NULL AFTER company_id');
CALL phase6d_add_column('subscriptions','requested_by_user_id','BIGINT UNSIGNED NULL AFTER verification_case_id');
CALL phase6d_add_column('subscriptions','reviewed_by_user_id','BIGINT UNSIGNED NULL AFTER requested_by_user_id');
CALL phase6d_add_column('subscriptions','requested_at','DATETIME(6) NULL AFTER reviewed_by_user_id');
CALL phase6d_add_column('subscriptions','start_at','DATETIME(6) NULL AFTER requested_at');
CALL phase6d_add_column('subscriptions','end_at','DATETIME(6) NULL AFTER start_at');
CALL phase6d_add_column('subscriptions','subscription_state',"VARCHAR(32) NOT NULL DEFAULT 'requested' AFTER end_at");
CALL phase6d_add_column('subscriptions','activation_note','TEXT NULL AFTER subscription_state');
CALL phase6d_add_column('subscription_status_history','subscription_id','BIGINT UNSIGNED NULL AFTER subscription_status_history_ref');
CALL phase6d_add_column('subscription_status_history','previous_state','VARCHAR(32) NULL AFTER subscription_id');
CALL phase6d_add_column('subscription_status_history','new_state','VARCHAR(32) NULL AFTER previous_state');
CALL phase6d_add_column('subscription_status_history','actor_user_id','BIGINT UNSIGNED NULL AFTER new_state');
CALL phase6d_add_column('subscription_status_history','reason','VARCHAR(500) NULL AFTER actor_user_id');
CALL phase6d_add_column('subscription_status_history','occurred_at','DATETIME(6) NULL AFTER reason');
CALL phase6d_add_column('eligibility_assessments','carrier_company_id','BIGINT UNSIGNED NULL AFTER eligibility_assessment_ref');
CALL phase6d_add_column('eligibility_assessments','carrier_user_id','BIGINT UNSIGNED NULL AFTER carrier_company_id');
CALL phase6d_add_column('eligibility_assessments','subscription_id','BIGINT UNSIGNED NULL AFTER carrier_user_id');
CALL phase6d_add_column('eligibility_assessments','truck_id','BIGINT UNSIGNED NULL AFTER subscription_id');
CALL phase6d_add_column('eligibility_assessments','driver_id','BIGINT UNSIGNED NULL AFTER truck_id');
CALL phase6d_add_column('eligibility_assessments','assessment_result','VARCHAR(24) NULL AFTER driver_id');
CALL phase6d_add_column('eligibility_assessments','reason_codes_json','JSON NULL AFTER assessment_result');
CALL phase6d_add_column('eligibility_assessments','assessed_at','DATETIME(6) NULL AFTER reason_codes_json');
CALL phase6d_add_column('resource_availability','truck_id','BIGINT UNSIGNED NULL AFTER resource_availability_ref');
CALL phase6d_add_column('resource_availability','driver_id','BIGINT UNSIGNED NULL AFTER truck_id');
CALL phase6d_add_column('resource_availability','eligibility_assessment_id','BIGINT UNSIGNED NULL AFTER driver_id');
CALL phase6d_add_column('resource_availability','availability_status',"VARCHAR(24) NOT NULL DEFAULT 'unavailable' AFTER eligibility_assessment_id");
CALL phase6d_add_column('resource_availability','available_from','DATETIME(6) NULL AFTER availability_status');
CALL phase6d_add_column('resource_availability','unavailable_at','DATETIME(6) NULL AFTER available_from');
CALL phase6d_add_column('resource_availability','reason','VARCHAR(500) NULL AFTER unavailable_at');
DROP PROCEDURE phase6d_add_column;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_add_index$$
CREATE PROCEDURE phase6d_add_index(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_columns TEXT,IN p_unique BOOLEAN)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD ',IF(p_unique,'UNIQUE ',''),'INDEX `',p_name,'` (',p_columns,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6d_add_index('subscription_plan_versions','uq_plan_versions_code_version','`plan_code`,`version_no`',TRUE);
CALL phase6d_add_index('subscriptions','ix_subscriptions_owner_user','`owner_user_id`,`subscription_state`',FALSE);
CALL phase6d_add_index('subscriptions','ix_subscriptions_company_state','`company_id`,`subscription_state`',FALSE);
CALL phase6d_add_index('subscription_status_history','ix_subscription_history_subscription','`subscription_id`,`occurred_at`',FALSE);
CALL phase6d_add_index('eligibility_assessments','ix_eligibility_truck_assessed','`truck_id`,`assessed_at`',FALSE);
CALL phase6d_add_index('eligibility_assessments','ix_eligibility_carrier_company','`carrier_company_id`,`assessed_at`',FALSE);
CALL phase6d_add_index('eligibility_assessments','ix_eligibility_carrier_user','`carrier_user_id`,`assessed_at`',FALSE);
CALL phase6d_add_index('resource_availability','uq_resource_availability_truck','`truck_id`',TRUE);
DROP PROCEDURE phase6d_add_index;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_add_fk$$
CREATE PROCEDURE phase6d_add_fk(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_column VARCHAR(64),IN p_ref_table VARCHAR(64),IN p_ref VARCHAR(64))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` FOREIGN KEY (`',p_column,'`) REFERENCES `',p_ref_table,'` (`',p_ref,'`)');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6d_add_fk('subscription_plan_versions','fk_plan_versions_plan','subscription_plan_id','subscription_plans','subscription_plan_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_company','company_id','companies','company_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_company_type','company_type_id','company_types','company_type_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_plan_version','plan_version_id','subscription_plan_versions','subscription_plan_version_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_verification_case','verification_case_id','verification_cases','verification_case_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_owner_user','owner_user_id','users','user_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_requester','requested_by_user_id','users','user_id');
CALL phase6d_add_fk('subscriptions','fk_subscriptions_reviewer','reviewed_by_user_id','users','user_id');
CALL phase6d_add_fk('subscription_status_history','fk_subscription_history_subscription','subscription_id','subscriptions','subscription_id');
CALL phase6d_add_fk('subscription_status_history','fk_subscription_history_actor','actor_user_id','users','user_id');
CALL phase6d_add_fk('eligibility_assessments','fk_eligibility_company','carrier_company_id','companies','company_id');
CALL phase6d_add_fk('eligibility_assessments','fk_eligibility_user','carrier_user_id','users','user_id');
CALL phase6d_add_fk('eligibility_assessments','fk_eligibility_subscription','subscription_id','subscriptions','subscription_id');
CALL phase6d_add_fk('eligibility_assessments','fk_eligibility_truck','truck_id','trucks','truck_id');
CALL phase6d_add_fk('eligibility_assessments','fk_eligibility_driver','driver_id','drivers','driver_id');
CALL phase6d_add_fk('resource_availability','fk_availability_truck','truck_id','trucks','truck_id');
CALL phase6d_add_fk('resource_availability','fk_availability_driver','driver_id','drivers','driver_id');
CALL phase6d_add_fk('resource_availability','fk_availability_assessment','eligibility_assessment_id','eligibility_assessments','eligibility_assessment_id');
DROP PROCEDURE phase6d_add_fk;
DELIMITER $$
DROP PROCEDURE IF EXISTS phase6d_add_check$$
CREATE PROCEDURE phase6d_add_check(IN p_table VARCHAR(64),IN p_name VARCHAR(64),IN p_expression TEXT)
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND CONSTRAINT_NAME=p_name) THEN
  SET @ddl=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',p_name,'` CHECK (',p_expression,')');PREPARE stmt FROM @ddl;EXECUTE stmt;DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL phase6d_add_check('subscriptions','chk_subscriptions_one_owner','(company_id IS NOT NULL) <> (owner_user_id IS NOT NULL)');
CALL phase6d_add_check('subscriptions','chk_subscriptions_state',"subscription_state IN ('requested','active','expired','cancelled')");
CALL phase6d_add_check('eligibility_assessments','chk_eligibility_one_carrier','(carrier_company_id IS NOT NULL) <> (carrier_user_id IS NOT NULL)');
CALL phase6d_add_check('eligibility_assessments','chk_eligibility_result',"assessment_result IS NULL OR assessment_result IN ('eligible','ineligible')");
CALL phase6d_add_check('resource_availability','chk_resource_availability_state',"availability_status IN ('available','unavailable')");
DROP PROCEDURE phase6d_add_check;
SELECT 'Phase 6D subscription and eligibility alignment completed' AS result;
